import AppKit
import CoreGraphics
import Observation
import OSLog

@MainActor
@Observable
final class PermissionManager {

    enum Status: CustomStringConvertible {
        case notDetermined, granted, denied
        var description: String {
            switch self {
            case .notDetermined: return "notDetermined"
            case .granted: return "granted"
            case .denied: return "denied"
            }
        }
    }

    private(set) var screenRecordingStatus: Status = .notDetermined
    private var pollingTask: Task<Void, Never>?

    var isScreenRecordingGranted: Bool { screenRecordingStatus == .granted }

    // MARK: - Check

    func checkPermissions() async {
        let granted = CGPreflightScreenCaptureAccess()
        screenRecordingStatus = granted ? .granted : .denied
        Logger.permission.info("Screen recording: \(self.screenRecordingStatus)")

        // CGRequestScreenCaptureAccess() を呼ぶことで、
        // システム設定のスクリーン収録リストにアプリが登録される。
        // まだ未許可の場合のみ呼び出す（許可済みなら何もしない）。
        if !granted {
            CGRequestScreenCaptureAccess()
            startPollingForPermissionGrant()
        }
    }

    // MARK: - Request

    func requestScreenRecording() {
        CGRequestScreenCaptureAccess()
        startPollingForPermissionGrant()
    }

    /// Opens System Settings directly to the Screen Recording pane.
    func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
        startPollingForPermissionGrant()
    }

    // MARK: - Polling

    /// Polls every 2 seconds until permission is granted (user toggled the switch).
    private func startPollingForPermissionGrant() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { break }
                if Task.isCancelled { break }
                await self.checkPermissions()
                if self.isScreenRecordingGranted {
                    self.pollingTask = nil
                    break
                }
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
