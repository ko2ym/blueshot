import AppKit
import CoreGraphics
import ScreenCaptureKit

/// Utility for querying displays and mapping between AppKit screens and Core Graphics displays.
struct DisplayManager {

    // MARK: - Screen Queries

    /// All connected screens, ordered: main screen first.
    static var screens: [NSScreen] {
        var result = NSScreen.screens
        if let main = NSScreen.main, let idx = result.firstIndex(of: main), idx != 0 {
            result.swapAt(0, idx)
        }
        return result
    }

    /// The screen that currently contains the mouse cursor.
    static var screenWithCursor: NSScreen {
        let cursor = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    /// Returns the screen that contains the given point (in screen coordinates).
    static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }

    // MARK: - Scale Factor

    /// The backing scale factor (1.0 for standard, 2.0 for Retina) for the given screen.
    static func scaleFactor(for screen: NSScreen) -> CGFloat {
        screen.backingScaleFactor
    }

    // MARK: - Display ID

    /// The Core Graphics display ID for an NSScreen.
    static func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return CGMainDisplayID()
        }
        return CGDirectDisplayID(number.uint32Value)
    }

    // MARK: - Frame Conversion

    /// Converts an NSScreen frame (AppKit coordinates, origin at bottom-left) to
    /// Core Graphics coordinates (origin at top-left of main display).
    static func cgFrame(for screen: NSScreen) -> CGRect {
        let mainHeight = NSScreen.screens.map(\.frame.maxY).max() ?? screen.frame.maxY
        return CGRect(
            x: screen.frame.origin.x,
            y: mainHeight - screen.frame.maxY,
            width: screen.frame.width,
            height: screen.frame.height
        )
    }

    /// Converts a rect in AppKit screen coordinates to CG coordinates.
    static func cgRect(from appKitRect: CGRect, in screen: NSScreen) -> CGRect {
        let screenCGFrame = cgFrame(for: screen)
        return CGRect(
            x: screenCGFrame.origin.x + appKitRect.origin.x - screen.frame.origin.x,
            y: screenCGFrame.origin.y + (screen.frame.height - appKitRect.maxY + screen.frame.origin.y),
            width: appKitRect.width,
            height: appKitRect.height
        )
    }
}
