import SwiftUI
import Combine

/// 翻译视图模型
class TranslationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    @Published var shouldFocusInput: Bool = false
    @Published var metrics: TranslationMetrics?
    @Published var targetLanguage: String {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage") }
    }

    private var currentTask: Task<Void, Never>?
    private let translationService: TranslationService

    init(translationService: TranslationService = LLMTranslationService()) {
        self.translationService = translationService
        self.targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? "中文"
    }

    /// 触发翻译（从快捷键）
    func triggerTranslation() {
        // 只清空输入并聚焦输入框，等待用户手动输入
        inputText = ""
        outputText = ""
        errorMessage = nil
        metrics = nil
        shouldFocusInput = true
    }

    /// 执行翻译
    func translate() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // 取消之前的任务
        currentTask?.cancel()

        outputText = ""
        errorMessage = nil
        metrics = nil
        isTranslating = true

        currentTask = Task {
            do {
                let stream = try await translationService.translate(
                    inputText,
                    targetLanguage: targetLanguage,
                    customPrompt: nil
                )

                for try await event in stream {
                    if Task.isCancelled {
                        break
                    }
                    switch event {
                    case .chunk(let text):
                        await MainActor.run {
                            outputText += text
                        }
                    case .completed(let m):
                        await MainActor.run {
                            metrics = m
                        }
                    }
                }

                await MainActor.run {
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isTranslating = false
                }
            }
        }
    }

    /// 取消翻译
    func cancel() {
        currentTask?.cancel()
        isTranslating = false
    }

    /// 复制结果
    func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
    }
}
