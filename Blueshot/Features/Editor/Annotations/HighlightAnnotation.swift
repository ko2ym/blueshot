import CoreGraphics
import Foundation

struct HighlightAnnotation: Annotation {
    let id = UUID()
    var rect: CGRect
    var color: CGColor   // should have alpha ~0.4

    var boundingRect: CGRect { rect }

    func draw(in context: CGContext, scale: CGFloat) {
        let scaledRect = rect.scaled(by: scale)
        context.setFillColor(color)
        context.fill(scaledRect)
    }
}
