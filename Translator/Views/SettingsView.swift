import SwiftUI

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @State private var showingAPIKey = false

    var body: some View {
        TabView {
            apiConfigTab
                .tabItem {
                    Label("API", systemImage: "key")
                }

            translationConfigTab
                .tabItem {
                    Label("翻译", systemImage: "text.bubble")
                }

            hotkeyConfigTab
                .tabItem {
                    Label("快捷键", systemImage: "command")
                }
        }
        .frame(width: 450, height: 320)
        .padding()
    }

    // MARK: - API 配置 Tab
    private var apiConfigTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("API 配置") {
                VStack(alignment: .leading, spacing: 12) {
                    // Base URL
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base URL")
                            .font(.caption)
                        TextField("https://api.openai.com", text: $settings.apiBaseURL)
                            .textFieldStyle(.roundedBorder)
                    }

                    // API Key
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key")
                            .font(.caption)
                        HStack {
                            if showingAPIKey {
                                TextField("sk-...", text: $settings.apiKey)
                            } else {
                                SecureField("sk-...", text: $settings.apiKey)
                            }

                            Button(action: { showingAPIKey.toggle() }) {
                                Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                        }
                        .textFieldStyle(.roundedBorder)
                    }

                    // Model
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model")
                            .font(.caption)
                        TextField("gpt-4o-mini", text: $settings.modelName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - 翻译配置 Tab
    private var translationConfigTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("翻译设置") {
                VStack(alignment: .leading, spacing: 12) {
                    // 目标语言
                    VStack(alignment: .leading, spacing: 4) {
                        Text("目标语言")
                            .font(.caption)
                        TextField("中文", text: $settings.targetLanguage)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 自定义 Prompt
                    VStack(alignment: .leading, spacing: 4) {
                        Text("自定义 Prompt")
                            .font(.caption)
                        TextEditor(text: $settings.customPrompt)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        Text("可用变量: {target_language}, {text}")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - 快捷键配置 Tab
    private var hotkeyConfigTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("全局快捷键") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前快捷键: ⌥Space (Option + 空格)")
                        .font(.headline)

                    Text("提示：全局快捷键用于在任意应用中快速触发翻译。")
                        .font(.caption)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("辅助功能权限", systemImage: "accessibility")
                            .font(.headline)

                        Text("要使用「选中文字翻译」功能，需要在系统偏好设置中授予辅助功能权限。")
                            .font(.caption)

                        Button("打开系统偏好设置") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)

                        HStack {
                            Circle()
                                .fill(AccessibilityService.checkPermission() ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(AccessibilityService.checkPermission() ? "已授权" : "未授权")
                                .font(.caption)
                                .foregroundColor(AccessibilityService.checkPermission() ? .green : .red)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}
