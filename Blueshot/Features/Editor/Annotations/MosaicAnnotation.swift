import CoreGraphics
import Foundation

struct MosaicAnnotation: Annotation {
    let id = UUID()
    var rect: CGRect
    var blockSize: CGFloat   // pixel block size in points (e.g. 12)

    var boundingRect: CGRect { rect }

    func draw(in context: CGContext, scale: CGFloat) {
        // Actual pixelation is applied by CanvasRenderer.
        // This draw() is a no-op; the renderer detects MosaicAnnotation and handles it separately.
    }
}
