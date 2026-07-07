# Translator

macOS menubar 常驻翻译器，基于大模型 API 提供流式翻译。

## 功能特点

- 🎯 **纯 menubar 常驻**：轻量不占空间，点击图标即弹
- 🤖 **LLM 驱动**：支持 OpenAI 兼容接口（OpenAI、DeepSeek、通义千问等）
- ⚡ **流式输出**：实时显示翻译结果
- ⌨️ **全局快捷键**：⌥Space 一键触发翻译
- 🎨 **智能选词**：自动获取当前选中文本（需辅助功能权限）
- 🔐 **安全存储**：API key 存于 Keychain
- ⚙️ **可自定义**：支持自定义 prompt 模板

## 系统要求

- macOS 14.0+ (Sonoma)
- Xcode 15+

## 安装与构建

```bash
# 克隆项目
git clone <repo-url>
cd translator

# 首次 / 修改 project.yml 后：生成 .xcodeproj
xcodegen generate

# 命令行构建
xcodebuild -project Translator.xcodeproj -scheme Translator -configuration Debug build

# 或通过 Xcode
open Translator.xcodeproj
# ⌘R 运行
```

> `project.yml` 是项目的唯一描述文件，`.xcodeproj` 由它生成。

## 使用方法

1. 首次启动后，点击 menubar 图标
2. 点击"设置"配置 API：
   - Base URL（默认 OpenAI，可改为其他兼容接口）
   - API Key
   - Model 名称
3. 设置目标语言（默认中文）
4. 授权辅助功能权限（用于选词翻译）

### 翻译方式

- **选词翻译**：选中文字 → 按 ⌥Space → 自动翻译
- **剪贴板翻译**：复制文字 → 按 ⌥Space → 自动翻译
- **手动输入**：点击 menubar → 输入文字 → ⌘Enter 翻译

## 技术栈

- SwiftUI + Swift
- macOS 14+ MenuBarExtra
- OpenAI 兼容 API（流式 SSE）
- Keychain 安全存储
- Carbon API 全局快捷键
- Accessibility API 选词获取
- 零外部依赖

## 项目结构

```
Translator/
├── TranslatorApp.swift          # App 入口
├── Models/
│   ├── TranslationService.swift  # 翻译服务协议
│   └── Settings.swift            # 设置管理
├── Services/
│   ├── LLMTranslationService.swift  # LLM API 调用
│   ├── KeychainService.swift        # Keychain 操作
│   ├── AccessibilityService.swift   # 获取选中文本
│   └── HotkeyService.swift          # 全局快捷键管理
├── Views/
│   ├── MenuBarView.swift         # menubar 弹窗
│   ├── TranslationView.swift     # 翻译界面
│   ├── TranslationViewModel.swift # 翻译逻辑
│   └── SettingsView.swift        # 设置窗口
└── Info.plist                    # 应用配置
```

## 配置说明

### 支持的 LLM 供应商

任何兼容 OpenAI `/v1/chat/completions` 接口的服务：

- OpenAI (GPT-4o, GPT-4o-mini)
- DeepSeek
- 通义千问
- Moonshot (Kimi)
- 智谱 AI
- Claude (通过代理)

### 自定义 Prompt

在设置中可自定义翻译 prompt，支持变量：

- `{target_language}` - 目标语言
- `{text}` - 待翻译文本

默认 prompt：

```
You are a professional translator. Translate the following text to {target_language}.

Requirements:
- Maintain the original meaning and tone
- Use natural, fluent language
- Preserve formatting and special characters
- If the text is already in the target language, respond with "无需翻译"

Text to translate:
{text}
```

## 开发

```bash
# 生成 .xcodeproj
xcodegen generate

# 构建
xcodebuild -project Translator.xcodeproj -scheme Translator -configuration Debug build

# 运行
open Translator.xcodeproj
# 然后在 Xcode 中 ⌘R 运行

# 测试
xcodebuild test -project Translator.xcodeproj -scheme Translator
```

## 许可证

MIT License
