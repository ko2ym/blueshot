import SwiftUI

struct PermissionPromptView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("画面収録の許可が必要です")
                .font(.headline)

            Text("Blueshot がスクリーンショットを撮るには、画面収録の許可が必要です。システム設定で有効にしてください。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("システム設定を開く") {
                    env.permissionManager.openScreenRecordingSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("再確認") {
                    Task {
                        await env.permissionManager.checkPermissions()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
