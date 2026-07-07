import Foundation
import AppKit
import ApplicationServices

/// Accessibility 服务 - 获取当前选中的文本
struct AccessibilityService {
    /// 检查是否有辅助功能权限
    static func checkPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 获取当前应用选中的文本
    static func getSelectedText() -> String? {
        // 获取前台应用
        let workspace = NSWorkspace.shared
        guard let frontApp = workspace.frontmostApplication else { return nil }

        let pid = frontApp.processIdentifier
        let app = AXUIElementCreateApplication(pid)

        // 获取 focused UI element
        var focusedElement: AnyObject?
        let focusedResult = AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard focusedResult == .success,
              let element = focusedElement else {
            return nil
        }

        // 获取选中的文本
        var selectedText: AnyObject?
        let selectedResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)

        guard selectedResult == .success,
              let text = selectedText as? String,
              !text.isEmpty else {
            return nil
        }

        return text
    }
}
