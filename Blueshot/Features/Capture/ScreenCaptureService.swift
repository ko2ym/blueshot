import AppKit
import CoreGraphics
import ScreenCaptureKit
import OSLog

/// Wraps ScreenCaptureKit to provide screenshot operations.
/// Runs as an Actor to serialize async capture requests.
/// All parameters are Sendable (no NSScreen crossing actor boundary).
actor ScreenCaptureService {

    // MARK: - Full Screen

    /// Captures the entire display identified by `displayID`.
    func captureFullScreenByID(
        displayID: CGDirectDisplayID,
        scale: CGFloat,
        screenFrame: CGRect
    ) async throws -> CaptureResult {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw BlueshotError.captureFailedNoDisplays
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = makeConfig(width: Int(screenFrame.width * scale), height: Int(screenFrame.height * scale))

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        Logger.capture.info("Full screen captured: \(image.width)x\(image.height)px on display \(displayID)")
        return CaptureResult(image: image, scale: scale, capturedAt: Date(), displayID: displayID)
    }

    // MARK: - Active Window

    /// Captures the frontmost application window.
    func captureActiveWindow() async throws -> CaptureResult {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        let pid = await MainActor.run { NSWorkspace.shared.frontmostApplication?.processIdentifier }
        guard let pid else { throw BlueshotError.captureFailedNoWindow }

        let appWindows = content.windows.filter { $0.owningApplication?.processID == pid && $0.isOnScreen }
        guard let targetWindow = appWindows.first else {
            throw BlueshotError.captureFailedNoWindow
        }

        let windowFrame = targetWindow.frame
        // Find display for window center — computed here in actor (no NSScreen needed)
        let displayID = CGMainDisplayID()  // fallback; improved in Phase 2
        let scale: CGFloat = 2.0           // Retina default; refined via SCDisplay

        let filter = SCContentFilter(desktopIndependentWindow: targetWindow)
        let config = SCStreamConfiguration()
        config.scalesToFit = false
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.colorSpaceName = CGColorSpace.sRGB
        config.width = Int(windowFrame.width * scale)
        config.height = Int(windowFrame.height * scale)

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        Logger.capture.info("Window captured: \(image.width)x\(image.height)px")
        return CaptureResult(image: image, scale: scale, capturedAt: Date(), displayID: displayID)
    }

    // MARK: - Region

    /// Captures a specific rect on the display identified by `displayID`.
    /// `rect` and `screenFrame` are in AppKit screen coordinates.
    func captureRegionByID(
        rect: CGRect,
        displayID: CGDirectDisplayID,
        scale: CGFloat,
        screenFrame: CGRect
    ) async throws -> CaptureResult {
        guard rect.width > 0, rect.height > 0 else {
            throw BlueshotError.captureFailedInvalidRegion
        }

        // フル画面をネイティブ解像度でキャプチャして切り抜く。
        // sourceRect + scalesToFit=false の組み合わせは SCKit が補間処理を行いぼやけが生じるため使用しない。
        let fullResult = try await captureFullScreenByID(
            displayID: displayID, scale: scale, screenFrame: screenFrame
        )

        // AppKit 座標（左下原点・y上向き）→ ピクセル座標（左上原点・y下向き）に変換
        let localX = rect.origin.x - screenFrame.origin.x
        let localY = screenFrame.height - (rect.maxY - screenFrame.origin.y)
        let pixelRect = CGRect(
            x: (localX * scale).rounded(),
            y: (localY * scale).rounded(),
            width: (rect.width * scale).rounded(),
            height: (rect.height * scale).rounded()
        )

        guard let cropped = fullResult.image.cropping(to: pixelRect) else {
            throw BlueshotError.captureFailedInvalidRegion
        }

        Logger.capture.info("Region captured: \(cropped.width)x\(cropped.height)px")
        return CaptureResult(image: cropped, scale: scale, capturedAt: Date(), displayID: displayID)
    }

    // MARK: - Helpers

    private func makeConfig(width: Int, height: Int) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.scalesToFit = false
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.colorSpaceName = CGColorSpace.sRGB
        config.width = width
        config.height = height
        return config
    }
}
