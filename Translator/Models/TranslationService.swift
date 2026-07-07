import Foundation

/// 翻译服务协议
protocol TranslationService {
    func translate(_ text: String, targetLanguage: String, customPrompt: String?) async throws -> AsyncThrowingStream<String, Error>
}

/// 翻译错误
enum TranslationError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case apiError(String)
    case noTextSelected
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API Key 无效，请在设置中检查"
        case .networkError(let msg):
            return "网络错误：\(msg)"
        case .apiError(let msg):
            return "API 错误：\(msg)"
        case .noTextSelected:
            return "剪贴板中没有可翻译的文本"
        case .unknown:
            return "发生未知错误"
        }
    }
}
