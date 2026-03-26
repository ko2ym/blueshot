import CoreGraphics
import Foundation

/// The result of a single screenshot capture operation.
/// Passed across actor boundaries as a Sendable value type.
struct CaptureResult: Sendable {
    let image: CGImage
    let scale: CGFloat
    let capturedAt: Date
    let displayID: CGDirectDisplayID

    var pixelSize: CGSize {
        CGSize(width: image.width, height: image.height)
    }

    var pointSize: CGSize {
        CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
    }
}
