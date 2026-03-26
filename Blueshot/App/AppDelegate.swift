import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app alive even when all windows are closed (menu bar app)
        false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement in Info.plist handles Dock icon hiding at launch.
        // Additional runtime hiding for edge cases:
        NSApp.setActivationPolicy(.accessory)
    }
}
