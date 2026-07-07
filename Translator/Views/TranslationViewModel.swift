import SwiftUI
import Combine

/// 翻译视图模型
class TranslationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?

    private var currentTask: Task<Void, Never>?
    private let translationService: TranslationService

    init(translationService: TranslationService = LLMTranslationService()) {
        self.translationService = translationService
    }

    /// 触发翻译（从快捷键）
    func triggerTranslation() {
        // 优先尝试获取选中文本
        if let selectedText = AccessibilityService.getSelectedText() {
            inputText = selectedText
            translate()
            return
        }

        // 其次使用剪贴板内容
        if let clipboardText = NSPasteboard.general.string(forType: .string), !clipboardText.isEmpty {
            inputText = clipboardText
            translate()
            return
        }

        // 否则聚焦到输入框
        errorMessage = TranslationError.noTextSelected.localizedDescription
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
        isTranslating = true

        currentTask = Task {
            do {
                let stream = try await translationService.translate(
                    inputText,
                    targetLanguage: Settings.shared.targetLanguage,
                    customPrompt: nil
                )

                for try await chunk in stream {
                    if Task.isCancelled {
                        break
                    }
                    await MainActor.run {
                        outputText += chunk
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
