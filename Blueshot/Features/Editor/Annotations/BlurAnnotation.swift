import CoreGraphics
import CoreImage
import Foundation

struct BlurAnnotation: Annotation {
    let id = UUID()
    var rect: CGRect
    var radius: CGFloat   // blur radius in points (e.g. 10)

    var boundingRect: CGRect { rect }

    func draw(in context: CGContext, scale: CGFloat) {
        // Actual blur is applied by CanvasRenderer using CIFilter on the base image region.
        // This draw() is a no-op; the renderer detects BlurAnnotation and handles it separately.
    }
}
