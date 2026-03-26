import SwiftUI

@main
struct BlueshotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var env = AppEnvironment()

    var body: some Scene {
        MenuBarExtra("Blueshot", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environment(env)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(env)
        }
    }
}
