import Foundation

/// OpenAI 兼容接口的 LLM 翻译服务
class LLMTranslationService: TranslationService {
    private let settings: Settings

    init(settings: Settings = .shared) {
        self.settings = settings
    }

    func translate(_ text: String, targetLanguage: String, customPrompt: String? = nil) async throws -> AsyncThrowingStream<String, Error> {
        guard settings.isConfigured else {
            throw TranslationError.invalidAPIKey
        }

        let prompt = settings.buildPrompt(for: text)

        // 构建请求 - 智能拼接 URL，避免重复 /v1
        var baseURL = settings.apiBaseURL
        // 去掉末尾斜杠
        if baseURL.hasSuffix("/") {
            baseURL = String(baseURL.dropLast())
        }

        let endpoint: String
        if baseURL.hasSuffix("/v1") {
            // Base URL 已包含 /v1，只需拼接 /chat/completions
            endpoint = "\(baseURL)/chat/completions"
        } else {
            // Base URL 不包含 /v1，拼接完整路径
            endpoint = "\(baseURL)/v1/chat/completions"
        }

        guard let url = URL(string: endpoint) else {
            throw TranslationError.networkError("无效的 URL: \(endpoint)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": settings.modelName,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": true,
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 创建流式响应
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: TranslationError.unknown)
                        return
                    }

                    if httpResponse.statusCode == 401 {
                        continuation.finish(throwing: TranslationError.invalidAPIKey)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: TranslationError.apiError("HTTP \(httpResponse.statusCode)"))
                        return
                    }

                    // 解析 SSE 流
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            if let jsonData = data.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: TranslationError.networkError(error.localizedDescription))
                }
            }
        }
    }
}
