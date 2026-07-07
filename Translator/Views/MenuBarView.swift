import SwiftUI

/// Menubar 弹窗主视图
struct MenuBarView: View {
    @EnvironmentObject var settings: Settings
    @StateObject private var viewModel = TranslationViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // 翻译主界面
            TranslationView(viewModel: viewModel)

            Divider()

            // 底部按钮栏
            HStack {
                Button(action: {
                    openWindow(id: "settings")
                }) {
                    Label("设置", systemImage: "gear")
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("按 ⌥Space 翻译")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Label("退出", systemImage: "power")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 400)
        .onAppear {
            setupHotkey()
        }
    }

    private func setupHotkey() {
        // 注册 Option+Space 作为默认快捷键
        // kVK_Space = 49
        HotkeyService.shared.register(
            keyCode: 49,
            modifiers: HotkeyModifiers.option
        ) {
            DispatchQueue.main.async {
                viewModel.triggerTranslation()
            }
        }
    }
}
