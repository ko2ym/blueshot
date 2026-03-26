import SwiftUI

struct MenuBarView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !env.permissionManager.isScreenRecordingGranted {
                permissionWarningSection
                Divider()
            }

            captureSection
            Divider()
            appSection
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sections

    private var permissionWarningSection: some View {
        Button {
            env.permissionManager.openScreenRecordingSettings()
        } label: {
            Label("画面収録の許可が必要です", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    private var captureSection: some View {
        let config = env.preferences.makeHotKeyConfiguration()
        return Group {
            Button {
                env.captureCoordinator.startRegionCapture()
            } label: {
                captureLabel("範囲を選択してキャプチャ", binding: config.bindings[.regionSelect])
            }
            .disabled(!env.permissionManager.isScreenRecordingGranted)

            Button {
                env.captureCoordinator.captureActiveWindow()
            } label: {
                captureLabel("アクティブウィンドウをキャプチャ", binding: config.bindings[.activeWindow])
            }
            .disabled(!env.permissionManager.isScreenRecordingGranted)

            Button {
                env.captureCoordinator.captureFullScreen()
            } label: {
                captureLabel("全画面をキャプチャ", binding: config.bindings[.fullScreen])
            }
            .disabled(!env.permissionManager.isScreenRecordingGranted)
        }
    }

    private func captureLabel(_ title: String, binding: HotKeyBinding?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let binding {
                Text(binding.displayString)
                    .foregroundStyle(.secondary)
                    .font(.caption.monospaced())
            }
        }
    }

    private var appSection: some View {
        Group {
            SettingsLink {
                Text("設定...")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Blueshot を終了") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
