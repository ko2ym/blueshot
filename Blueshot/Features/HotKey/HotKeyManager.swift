import AppKit
import Carbon.HIToolbox
import OSLog

/// Registers and dispatches global hotkeys using Carbon's RegisterEventHotKey API.
/// This works in sandboxed apps without Input Monitoring permission.
@MainActor
final class HotKeyManager {

    // MARK: - Types

    typealias Action = @MainActor () -> Void

    private struct Registration {
        let hotKeyRef: EventHotKeyRef
        let action: Action
    }

    // macOS built-in screenshot shortcuts to never override
    static let reservedBindings: Set<HotKeyBinding> = [
        HotKeyBinding(keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | shiftKey)),
        HotKeyBinding(keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey)),
        HotKeyBinding(keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey)),
        HotKeyBinding(keyCode: UInt32(kVK_ANSI_6), modifiers: UInt32(cmdKey | shiftKey)),
    ]

    // MARK: - State

    private var registrations: [UInt32: Registration] = [:]   // id → registration
    private var nextID: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?
    private let preferences: AppPreferences

    // deinit からアクセスするための nonisolated ストレージ
    nonisolated(unsafe) private var _hotKeyRefsForDeinit: [EventHotKeyRef] = []
    nonisolated(unsafe) private var _eventHandlerRefForDeinit: EventHandlerRef?

    // MARK: - Init

    init(preferences: AppPreferences) {
        self.preferences = preferences
        installCarbonHandler()
    }

    // MARK: - Registration

    func registerAll(actions: [CaptureAction: Action]) {
        unregisterAll()
        let config = preferences.makeHotKeyConfiguration()
        for (action, binding) in config.bindings {
            guard let closure = actions[action] else { continue }
            if Self.reservedBindings.contains(binding) {
                Logger.hotKey.warning("Skipping reserved binding \(binding.displayString) for \(action.rawValue)")
                continue
            }
            register(binding: binding, action: closure)
        }
    }

    func unregisterAll() {
        for (_, reg) in registrations {
            UnregisterEventHotKey(reg.hotKeyRef)
        }
        registrations.removeAll()
        Logger.hotKey.info("All hotkeys unregistered")
    }

    // MARK: - Conflict Detection

    func isReserved(_ binding: HotKeyBinding) -> Bool {
        Self.reservedBindings.contains(binding)
    }

    func conflictingAction(for binding: HotKeyBinding) -> CaptureAction? {
        let config = preferences.makeHotKeyConfiguration()
        return config.bindings.first(where: { $0.value == binding })?.key
    }

    // MARK: - Private Registration

    private func register(binding: HotKeyBinding, action: @escaping Action) {
        let id = nextID
        nextID += 1

        let hotKeyID = EventHotKeyID(signature: fourCharCode("BSHT"), id: id)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let ref = hotKeyRef else {
            Logger.hotKey.error("Failed to register hotkey \(binding.displayString): \(status)")
            return
        }

        registrations[id] = Registration(hotKeyRef: ref, action: action)
        _hotKeyRefsForDeinit.append(ref)
        Logger.hotKey.info("Registered hotkey \(binding.displayString) [id=\(id)]")
    }

    // MARK: - Carbon Event Handler

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // We pass `self` as an unretained pointer via context.
        // The handler calls back into the @MainActor class via DispatchQueue.main.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context -> OSStatus in
                guard let event, let context else { return noErr }
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                let manager = Unmanaged<HotKeyManager>.fromOpaque(context).takeUnretainedValue()
                let id = hotKeyID.id
                DispatchQueue.main.async {
                    manager.handleHotKeyPressed(id: id)
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
        _eventHandlerRefForDeinit = eventHandlerRef
    }

    private func handleHotKeyPressed(id: UInt32) {
        guard let reg = registrations[id] else { return }
        Logger.hotKey.info("Hotkey fired [id=\(id)]")
        reg.action()
    }

    // MARK: - Helpers

    private func fourCharCode(_ string: String) -> FourCharCode {
        var result: FourCharCode = 0
        for char in string.utf8.prefix(4) {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }

    deinit {
        for ref in _hotKeyRefsForDeinit {
            UnregisterEventHotKey(ref)
        }
        if let ref = _eventHandlerRefForDeinit {
            RemoveEventHandler(ref)
        }
    }
}
