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

        // 构建请求
        let url = URL(string: "\(settings.apiBaseURL)/v1/chat/completions")!
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
