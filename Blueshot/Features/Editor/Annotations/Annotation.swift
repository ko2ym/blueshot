import CoreGraphics
import Foundation

/// Base protocol for all drawing annotations applied to a screenshot.
protocol Annotation: Identifiable, Sendable {
    var id: UUID { get }
    /// Draws the annotation into the given Core Graphics context.
    func draw(in context: CGContext, scale: CGFloat)
    var boundingRect: CGRect { get }
}
