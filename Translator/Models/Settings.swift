import Foundation
import SwiftUI
import Combine

/// 应用设置
class Settings: ObservableObject {
    static let shared = Settings()

    // MARK: - API 配置
    @Published var apiBaseURL: String {
        didSet { UserDefaults.standard.set(apiBaseURL, forKey: "apiBaseURL") }
    }
    @Published var apiKey: String {
        didSet {
            if !apiKey.isEmpty {
                KeychainService.save(apiKey, forKey: "apiKey")
            } else {
                KeychainService.delete(forKey: "apiKey")
            }
        }
    }
    @Published var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: "modelName") }
    }

    // MARK: - 翻译配置
    @Published var targetLanguage: String {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage") }
    }
    @Published var customPrompt: String {
        didSet { UserDefaults.standard.set(customPrompt, forKey: "customPrompt") }
    }

    // MARK: - 快捷键
    @Published var hotkeyString: String {
        didSet { UserDefaults.standard.set(hotkeyString, forKey: "hotkeyString") }
    }

    // MARK: - 默认值
    private let defaultBaseURL = "https://api.openai.com"
    private let defaultModel = "gpt-4o-mini"
    private let defaultTargetLanguage = "中文"
    private let defaultHotkey = "⌥Space"
    private let defaultPrompt = """
    You are a professional translator. Translate the following text to {target_language}.

    Requirements:
    - Maintain the original meaning and tone
    - Use natural, fluent language
    - Preserve formatting and special characters
    - If the text is already in the target language, respond with "无需翻译"

    Text to translate:
    {text}
    """

    init() {
        self.apiBaseURL = UserDefaults.standard.string(forKey: "apiBaseURL") ?? "https://api.openai.com"
        self.apiKey = KeychainService.load(forKey: "apiKey") ?? ""
        self.modelName = UserDefaults.standard.string(forKey: "modelName") ?? "gpt-4o-mini"
        self.targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? "中文"
        self.customPrompt = UserDefaults.standard.string(forKey: "customPrompt") ?? """
            You are a professional translator. Translate the following text to {target_language}.

            Requirements:
            - Maintain the original meaning and tone
            - Use natural, fluent language
            - Preserve formatting and special characters
            - If the text is already in the target language, respond with "无需翻译"

            Text to translate:
            {text}
            """
        self.hotkeyString = UserDefaults.standard.string(forKey: "hotkeyString") ?? "⌥Space"
    }

    /// 构建最终的 prompt
    func buildPrompt(for text: String) -> String {
        var prompt = customPrompt
        prompt = prompt.replacingOccurrences(of: "{target_language}", with: targetLanguage)
        prompt = prompt.replacingOccurrences(of: "{text}", with: text)
        return prompt
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !apiBaseURL.isEmpty && !modelName.isEmpty
    }
}
