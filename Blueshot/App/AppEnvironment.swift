import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let preferences: AppPreferences
    let permissionManager: PermissionManager
    let captureCoordinator: CaptureCoordinator

    init() {
        let prefs = AppPreferences.shared
        let perm = PermissionManager()
        self.preferences = prefs
        self.permissionManager = perm
        self.captureCoordinator = CaptureCoordinator(permissionManager: perm, preferences: prefs)
        // アプリ起動直後にホットキーを登録する。MenuBarExtra を開くまで待たない。
        Task { await self.bootstrap() }
    }

    func bootstrap() async {
        await permissionManager.checkPermissions()
        if permissionManager.isScreenRecordingGranted {
            captureCoordinator.reloadHotKeys()
        } else {
            // Watch for permission grant and register hotkeys automatically
            Task { [weak self] in
                guard let self else { return }
                while !self.permissionManager.isScreenRecordingGranted {
                    try? await Task.sleep(for: .seconds(1))
                }
                self.captureCoordinator.reloadHotKeys()
            }
        }
    }
}
