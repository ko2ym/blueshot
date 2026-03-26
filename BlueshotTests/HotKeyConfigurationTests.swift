import Testing
import Foundation
import Carbon.HIToolbox
@testable import Blueshot

@Suite("HotKeyConfiguration")
struct HotKeyConfigurationTests {

    @Test func defaultBindingsAreSet() {
        let config = HotKeyConfiguration.default
        #expect(config.bindings[.regionSelect] != nil)
        #expect(config.bindings[.activeWindow] != nil)
        #expect(config.bindings[.fullScreen] != nil)
    }

    @Test func defaultBindingsDoNotConflictWithReserved() {
        // macOS reserved: Cmd+Shift+3/4/5/6
        let reserved: Set<HotKeyBinding> = [
            HotKeyBinding(keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | shiftKey)),
            HotKeyBinding(keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey)),
            HotKeyBinding(keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey)),
            HotKeyBinding(keyCode: UInt32(kVK_ANSI_6), modifiers: UInt32(cmdKey | shiftKey)),
        ]
        let config = HotKeyConfiguration.default
        for (action, binding) in config.bindings {
            #expect(!reserved.contains(binding), "Default binding for \(action.rawValue) conflicts with reserved macOS shortcut")
        }
    }

    @Test func bindingDisplayStringContainsModifiers() {
        let binding = HotKeyBinding(keyCode: UInt32(kVK_ANSI_1), modifiers: UInt32(cmdKey | shiftKey))
        let display = binding.displayString
        #expect(display.contains("⌘"))
        #expect(display.contains("⇧"))
        #expect(display.contains("1"))
    }

    @Test func bindingEqualityIsCorrect() {
        let a = HotKeyBinding(keyCode: 1, modifiers: 256)
        let b = HotKeyBinding(keyCode: 1, modifiers: 256)
        let c = HotKeyBinding(keyCode: 2, modifiers: 256)
        #expect(a == b)
        #expect(a != c)
    }

    @Test @MainActor func hotKeyConfigurationRoundTripsViaPreferences() {
        let prefs = AppPreferences.shared
        let config = HotKeyConfiguration.default
        prefs.saveHotKeyConfiguration(config)
        let loaded = prefs.makeHotKeyConfiguration()
        for action in CaptureAction.allCases {
            #expect(loaded.bindings[action] == config.bindings[action])
        }
    }
}
