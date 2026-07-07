import SwiftUI

/// 翻译主界面
struct TranslationView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // 目标语言选择
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("译至")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("目标语言", selection: $viewModel.targetLanguage) {
                    ForEach(Settings.availableLanguages, id: \.self) { lang in
                        Text(lang).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .menuStyle(.borderlessButton)
                .labelsHidden()

                Spacer(minLength: 0)
            }

            // 输入区域
            VStack(alignment: .leading, spacing: 8) {
                Text("原文")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $viewModel.inputText)
                    .font(.body)
                    .frame(height: 80)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.translate()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // 翻译按钮
            Button(action: viewModel.translate) {
                HStack {
                    if viewModel.isTranslating {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("翻译中...")
                    } else {
                        Image(systemName: "play.fill")
                        Text("翻译")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTranslating)
            .keyboardShortcut(.return, modifiers: .command)

            // 输出区域
            if !viewModel.outputText.isEmpty || viewModel.isTranslating {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("译文")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: viewModel.copyResult) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.outputText.isEmpty)
                    }

                    ScrollView {
                        Text(viewModel.outputText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            // 翻译指标
            if let m = viewModel.metrics, !viewModel.isTranslating {
                HStack(spacing: 6) {
                    Text("首token \(Self.formatDuration(m.firstTokenLatency))")
                    Text("·").foregroundStyle(.quaternary)
                    Text("总耗时 \(Self.formatDuration(m.totalDuration))")
                    Text("·").foregroundStyle(.quaternary)
                    Text("输入 \(m.inputTokens)")
                    Text("·").foregroundStyle(.quaternary)
                    Text("输出 \(m.outputTokens)")
                    Text("·").foregroundStyle(.quaternary)
                    Text(Self.formatRate(m.tokensPerSecond))
                    Spacer(minLength: 0)
                }
                .font(.system(size: 10))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }

            // 错误提示
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .onAppear {
            isInputFocused = true
        }
        .onChange(of: viewModel.shouldFocusInput) { _, newValue in
            if newValue {
                isInputFocused = true
                viewModel.shouldFocusInput = false
            }
        }
    }

    private static func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 1 {
            return String(format: "%.2fs", seconds)
        } else {
            return String(format: "%.1fs", seconds)
        }
    }

    private static func formatRate(_ tokensPerSecond: Double) -> String {
        if tokensPerSecond >= 10 {
            return String(format: "%.0f tok/s", tokensPerSecond)
        } else {
            return String(format: "%.1f tok/s", tokensPerSecond)
        }
    }
}
