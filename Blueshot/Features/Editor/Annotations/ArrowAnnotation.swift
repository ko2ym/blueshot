import CoreGraphics
import Foundation

struct ArrowAnnotation: Annotation {
    let id = UUID()
    var start: CGPoint
    var end: CGPoint
    var color: CGColor
    var lineWidth: CGFloat

    var boundingRect: CGRect {
        CGRect(
            x: min(start.x, end.x) - lineWidth * 5,
            y: min(start.y, end.y) - lineWidth * 5,
            width: abs(end.x - start.x) + lineWidth * 10,
            height: abs(end.y - start.y) + lineWidth * 10
        )
    }

    func draw(in context: CGContext, scale: CGFloat) {
        let s = start.scaled(by: scale)
        let e = end.scaled(by: scale)
        let w = lineWidth * scale

        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(w)
        context.setLineCap(.round)

        // Shaft
        context.move(to: s)
        context.addLine(to: e)
        context.strokePath()

        // Arrowhead
        let angle = atan2(e.y - s.y, e.x - s.x)
        let headLength = w * 6
        let headAngle: CGFloat = .pi / 6

        let p1 = CGPoint(
            x: e.x - headLength * cos(angle - headAngle),
            y: e.y - headLength * sin(angle - headAngle)
        )
        let p2 = CGPoint(
            x: e.x - headLength * cos(angle + headAngle),
            y: e.y - headLength * sin(angle + headAngle)
        )
        context.move(to: e)
        context.addLine(to: p1)
        context.addLine(to: p2)
        context.closePath()
        context.fillPath()
    }
}
