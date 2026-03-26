import CoreGraphics
import Foundation

struct RectangleAnnotation: Annotation {
    let id = UUID()
    var rect: CGRect
    var strokeColor: CGColor
    var fillColor: CGColor?
    var lineWidth: CGFloat

    var boundingRect: CGRect { rect.insetBy(dx: -lineWidth, dy: -lineWidth) }

    func draw(in context: CGContext, scale: CGFloat) {
        let scaledRect = rect.scaled(by: scale)
        let scaledWidth = lineWidth * scale

        if let fill = fillColor {
            context.setFillColor(fill)
            context.fill(scaledRect)
        }
        context.setStrokeColor(strokeColor)
        context.setLineWidth(scaledWidth)
        context.stroke(scaledRect)
    }
}
