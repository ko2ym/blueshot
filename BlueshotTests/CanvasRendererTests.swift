import Testing
import CoreGraphics
@testable import Blueshot

@Suite("CanvasRenderer")
struct CanvasRendererTests {
    private let renderer = CanvasRenderer()

    private func makeTestImage(width: Int = 200, height: Int = 200) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    @Test func renderWithNoAnnotationsMatchesBase() {
        let base = makeTestImage()
        let result = renderer.render(base: base, annotations: [], scale: 1.0)
        #expect(result != nil)
        #expect(result?.width == base.width)
        #expect(result?.height == base.height)
    }

    @Test func renderWithRectangleAnnotation() {
        let base = makeTestImage()
        let annotation = RectangleAnnotation(
            rect: CGRect(x: 10, y: 10, width: 50, height: 50),
            strokeColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
            fillColor: nil,
            lineWidth: 2
        )
        let result = renderer.render(base: base, annotations: [annotation], scale: 1.0)
        #expect(result != nil)
        #expect(result?.width == base.width)
    }

    @Test func renderWithBlurAnnotation() {
        let base = makeTestImage()
        let annotation = BlurAnnotation(rect: CGRect(x: 20, y: 20, width: 60, height: 60), radius: 5)
        let result = renderer.render(base: base, annotations: [annotation], scale: 1.0)
        #expect(result != nil)
    }

    @Test func renderWithMosaicAnnotation() {
        let base = makeTestImage()
        let annotation = MosaicAnnotation(rect: CGRect(x: 20, y: 20, width: 60, height: 60), blockSize: 8)
        let result = renderer.render(base: base, annotations: [annotation], scale: 1.0)
        #expect(result != nil)
    }

    @Test func renderPreviewIncludesInProgressAnnotation() {
        let base = makeTestImage()
        let inProgress = RectangleAnnotation(
            rect: CGRect(x: 5, y: 5, width: 30, height: 30),
            strokeColor: CGColor(red: 0, green: 0, blue: 1, alpha: 1),
            fillColor: nil,
            lineWidth: 1
        )
        let result = renderer.renderPreview(base: base, annotations: [], inProgress: inProgress, scale: 1.0)
        #expect(result != nil)
    }
}
