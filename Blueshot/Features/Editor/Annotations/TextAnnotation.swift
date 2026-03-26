import CoreGraphics
import CoreText
import Foundation

struct TextAnnotation: Annotation {
    let id = UUID()
    var origin: CGPoint      // top-left in point coordinates
    var text: String
    var fontSize: CGFloat
    var color: CGColor

    var boundingRect: CGRect {
        CGRect(origin: origin, size: CGSize(width: fontSize * CGFloat(text.count) * 0.7, height: fontSize * 1.4))
    }

    func draw(in context: CGContext, scale: CGFloat) {
        guard !text.isEmpty else { return }

        let scaledFontSize = fontSize * scale
        let scaledOrigin = origin.scaled(by: scale)

        // Build attributed string
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, scaledFontSize, nil)
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]
        let attrString = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrString)

        // Draw background for readability
        let bounds = CTLineGetBoundsWithOptions(line, [])
        let bgRect = CGRect(
            x: scaledOrigin.x - 2,
            y: scaledOrigin.y - bounds.height - 2,
            width: bounds.width + 4,
            height: bounds.height + 4
        )
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        context.fill(bgRect)

        // Draw text (Core Text uses bottom-left origin)
        context.saveGState()
        context.textPosition = CGPoint(x: scaledOrigin.x, y: scaledOrigin.y - bounds.height)
        CTLineDraw(line, context)
        context.restoreGState()
    }
}
