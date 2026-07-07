# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定位

macOS menubar 常驻翻译器，基于 SwiftUI 构建，通过大模型 API（LLM）完成翻译。纯 menubar 模式（无主窗口），支持选词翻译、剪贴板翻译和手动输入。

## 技术栈

- **SwiftUI** + **Swift**（最低 macOS 14+ Sonoma，使用 `MenuBarExtra`）
- **Xcode 15+** + [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml` 描述项目结构，`xcodegen generate` 生成 `.xcodeproj`）
- UI 全部用 SwiftUI 声明，无 Storyboard / xib
- 数据层：`UserDefaults` 存配置；API key 存 Keychain
- 网络层：`URLSession` + `async/await`，封装 OpenAI 兼容 API（流式 SSE）
- 全局快捷键：Carbon `RegisterEventHotKey`（见 `HotkeyService`）

## 构建与运行

```bash
# 首次 / 修改 project.yml 后：生成 .xcodeproj
xcodegen generate

# 命令行构建
xcodebuild -project Translator.xcodeproj -scheme Translator -configuration Debug build

# 或通过 Xcode
open Translator.xcodeproj
# ⌘R 运行
```

> `project.yml` 是项目的唯一描述文件，`.xcodeproj` 由它生成，已加入 `.gitignore`。
> 需要新的源文件 / 资源 / 配置时，改 `project.yml` 后重新 `xcodegen generate`。

## 架构要点

- **App 入口**：`TranslatorApp.swift`，使用 `MenuBarExtra(.window)` 创建 menubar 弹窗，`LSUIElement = true` 隐藏 Dock 图标
- **核心模块**：
  - `Models/` — `TranslationService` 协议、`Settings` 配置管理
  - `Services/` — `LLMTranslationService`（OpenAI 兼容 API）、`KeychainService`、`AccessibilityService`
  - `Views/` — `MenuBarView`（menubar 弹窗）、`TranslationView`（翻译 UI）、`SettingsView`（设置窗口）、`TranslationViewModel`
- **LLM 调用**：OpenAI 兼容接口 `/v1/chat/completions`，支持流式 SSE 输出，可配置 `baseURL / apiKey / model`
- **输入来源优先级**：Accessibility API 获取选中文本 → 剪贴板 → 手动输入
- **并发**：`async/await` + `Task` 管理翻译请求，支持取消
- **安全**：API key 存 Keychain，不写入代码或日志

## 翻译流程

1. 用户按全局快捷键或点击 menubar 图标
2. `AccessibilityService` 获取选中文本，或读取剪贴板，或手动输入
3. `LLMTranslationService.translate()` 发起流式请求
4. 实时渲染到 `TranslationView`
5. 用户可复制结果

## 测试

```bash
xcodebuild test -project Translator.xcodeproj -scheme Translator
```

`TranslationService` 协议抽象便于 mock；网络层测试用 `URLProtocol` 桩。

## 开发约定

- 文件命名：`PascalCase.swift`，与主类型同名
- 单 View 不超过 ~200 行
- 错误处理：`TranslationError` 枚举，不静默吞错
- 日志：`Logger`（`os.log`）分 category
