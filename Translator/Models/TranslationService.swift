import Foundation

/// 翻译指标
struct TranslationMetrics {
    let firstTokenLatency: TimeInterval  // 首 token 延迟（秒）
    let totalDuration: TimeInterval      // 总耗时（秒）
    let inputTokens: Int
    let outputTokens: Int

    var tokensPerSecond: Double {
        let generationTime = totalDuration - firstTokenLatency
        return generationTime > 0 ? Double(outputTokens) / generationTime : 0
    }
}

/// 翻译事件
enum TranslationEvent {
    case chunk(String)
    case completed(TranslationMetrics)
}

/// 翻译服务协议
protocol TranslationService {
    func translate(_ text: String, targetLanguage: String, customPrompt: String?) async throws -> AsyncThrowingStream<TranslationEvent, Error>
}

/// 翻译错误
enum TranslationError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case apiError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API Key 无效，请在设置中检查"
        case .networkError(let msg):
            return "网络错误：\(msg)"
        case .apiError(let msg):
            return "API 错误：\(msg)"
        case .unknown:
            return "发生未知错误"
        }
    }
}
