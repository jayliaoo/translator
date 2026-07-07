import SwiftUI

/// 翻译主界面
struct TranslationView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
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
    }
}
