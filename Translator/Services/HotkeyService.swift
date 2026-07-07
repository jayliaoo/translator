import Foundation
import Carbon
import AppKit

/// 全局快捷键管理器
class HotkeyService {
    static let shared = HotkeyService()

    private var hotkeyRef: EventHotKeyRef?
    private var onTrigger: (() -> Void)?

    private init() {
        registerEventHandler()
    }

    deinit {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    /// 注册全局快捷键
    func register(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        onTrigger = callback

        // 注销旧的
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
        }

        var hotkeyId = EventHotKeyID()
        hotkeyId.signature = 0x5452414E // "TRAN"
        hotkeyId.id = 1

        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyId,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            hotkeyRef = hotKeyRef
        }
    }

    /// 注销全局快捷键
    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
    }

    private func registerEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyService.shared.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }
}

/// 常用修饰键
struct HotkeyModifiers {
    static let option = UInt32(optionKey)
    static let command = UInt32(cmdKey)
    static let control = UInt32(controlKey)
    static let shift = UInt32(shiftKey)
}
