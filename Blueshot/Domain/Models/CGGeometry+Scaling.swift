import CoreGraphics

extension CGRect {
    /// Scales origin and size by the given factor.
    func scaled(by factor: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * factor,
            y: origin.y * factor,
            width: width * factor,
            height: height * factor
        )
    }
}

extension CGPoint {
    func scaled(by factor: CGFloat) -> CGPoint {
        CGPoint(x: x * factor, y: y * factor)
    }
}
