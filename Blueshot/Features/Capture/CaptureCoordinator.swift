import AppKit
import OSLog

/// Orchestrates the full capture flow: trigger → capture → editor/export.
/// Also owns the HotKeyManager and wires hotkeys to capture actions.
@MainActor
final class CaptureCoordinator {

    // MARK: - Dependencies

    private let captureService = ScreenCaptureService()
    private let permissionManager: PermissionManager
    private let preferences: AppPreferences
    private let regionSelector = RegionSelectorWindowController()
    let hotKeyManager: HotKeyManager

    /// 開いているエディタウィンドウコントローラーを保持（ウィンドウが閉じたら自動削除）
    private var editorControllers: [EditorWindowController] = []

    // MARK: - Init

    init(permissionManager: PermissionManager, preferences: AppPreferences) {
        self.permissionManager = permissionManager
        self.preferences = preferences
        self.hotKeyManager = HotKeyManager(preferences: preferences)
    }

    // MARK: - Hotkey Registration

    /// Registers capture actions as global hotkeys. Call on app launch and after settings change.
    func reloadHotKeys() {
        hotKeyManager.registerAll(actions: [
            .regionSelect: { [weak self] in self?.startRegionCapture() },
            .activeWindow: { [weak self] in self?.captureActiveWindow() },
            .fullScreen:   { [weak self] in self?.captureFullScreen() },
        ])
    }

    // MARK: - Public Capture Actions

    func startRegionCapture() {
        guard checkPermission() else { return }
        regionSelector.beginSelection { [weak self] result in
            guard let self else { return }
            switch result {
            case .selected(let rect, let screen):
                let displayID = DisplayManager.displayID(for: screen)
                let scale = DisplayManager.scaleFactor(for: screen)
                let screenFrame = screen.frame
                Task {
                    // オーバーレイウィンドウが GPU から完全に消えるまで待つ
                    try? await Task.sleep(for: .milliseconds(150))
                    await self.performRegionCapture(rect: rect, displayID: displayID, scale: scale, screenFrame: screenFrame)
                }
            case .cancelled:
                Logger.capture.info("Region selection cancelled")
            }
        }
    }

    func captureActiveWindow() {
        guard checkPermission() else { return }
        Task {
            await performCapture {
                try await self.captureService.captureActiveWindow()
            }
        }
    }

    func captureFullScreen() {
        guard checkPermission() else { return }
        let screen = DisplayManager.screenWithCursor
        let displayID = DisplayManager.displayID(for: screen)
        let scale = DisplayManager.scaleFactor(for: screen)
        let screenFrame = screen.frame
        Task {
            await performCapture {
                try await self.captureService.captureFullScreenByID(
                    displayID: displayID, scale: scale, screenFrame: screenFrame
                )
            }
        }
    }

    // MARK: - Private Helpers

    private func checkPermission() -> Bool {
        guard permissionManager.isScreenRecordingGranted else {
            Logger.capture.warning("Screen recording permission not granted")
            permissionManager.openScreenRecordingSettings()
            return false
        }
        return true
    }

    private func performRegionCapture(
        rect: CGRect,
        displayID: CGDirectDisplayID,
        scale: CGFloat,
        screenFrame: CGRect
    ) async {
        await performCapture {
            try await self.captureService.captureRegionByID(
                rect: rect, displayID: displayID, scale: scale, screenFrame: screenFrame
            )
        }
    }

    private func performCapture(block: () async throws -> CaptureResult) async {
        do {
            let delay = preferences.captureDelaySeconds
            if delay > 0 {
                try await Task.sleep(for: .seconds(delay))
            }
            let result = try await block()
            await handleCaptureResult(result)
        } catch {
            Logger.capture.error("Capture failed: \(error)")
            await showCaptureError(error)
        }
    }

    private func handleCaptureResult(_ result: CaptureResult) async {
        if preferences.openEditorAfterCapture {
            openEditor(with: result)
        } else {
            let exportService = ExportService()
            let config = preferences.makeExportConfiguration()
            do {
                try await exportService.export(result, configuration: config)
            } catch {
                Logger.capture.error("Export failed: \(error)")
                await showCaptureError(error)
            }
        }
    }

    private func openEditor(with result: CaptureResult) {
        let controller = EditorWindowController(captureResult: result, preferences: preferences)
        editorControllers.append(controller)
        controller.showWindow(nil)

        // ウィンドウが閉じたら配列から削除してメモリを解放する
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: controller.window,
            queue: .main
        ) { [weak self, weak controller] _ in
            guard let self, let controller else { return }
            self.editorControllers.removeAll { $0 === controller }
        }
    }

    private func showCaptureError(_ error: Error) async {
        let alert = NSAlert()
        alert.messageText = "キャプチャに失敗しました"
        alert.informativeText = (error as? BlueshotError)?.errorDescription ?? error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
