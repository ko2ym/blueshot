import CoreGraphics
import CoreImage
import Foundation

/// Pure rendering engine: composites a base image with annotations into a final CGImage.
/// Stateless and side-effect free — safe to call from any context.
struct CanvasRenderer {

    // MARK: - Public API

    /// Renders the base image with all annotations and returns the final CGImage.
    /// - Parameters:
    ///   - base: The original screenshot image (in physical pixels).
    ///   - annotations: Ordered list of annotations to apply.
    ///   - scale: The display scale factor (e.g. 2.0 for Retina).
    /// - Returns: A new CGImage with all annotations composited, or nil on failure.
    func render(base: CGImage, annotations: [any Annotation], scale: CGFloat) -> CGImage? {
        let width = base.width
        let height = base.height

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        // Draw base image first in the default (y-up) context.
        // CGContext.draw in y-up places source row 0 at buffer row 0 (top of bitmap),
        // producing a correctly-oriented PNG without an additional flip.
        context.draw(base, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Apply flip CTM so annotation coordinates use top-left origin (y-down).
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // Apply each annotation
        for annotation in annotations {
            switch annotation {
            case let blur as BlurAnnotation:
                applyBlur(blur, to: context, base: base, scale: scale, imageSize: CGSize(width: width, height: height))
            case let mosaic as MosaicAnnotation:
                applyMosaic(mosaic, to: context, base: base, scale: scale, imageSize: CGSize(width: width, height: height))
            default:
                annotation.draw(in: context, scale: scale)
            }
        }

        return context.makeImage()
    }

    // MARK: - Preview Rendering

    /// Renders a lightweight preview with a single in-progress annotation (e.g. while dragging).
    func renderPreview(
        base: CGImage,
        annotations: [any Annotation],
        inProgress: (any Annotation)?,
        scale: CGFloat
    ) -> CGImage? {
        var all = annotations
        if let inProgress { all.append(inProgress) }
        return render(base: base, annotations: all, scale: scale)
    }

    // MARK: - Blur

    private func applyBlur(
        _ annotation: BlurAnnotation,
        to context: CGContext,
        base: CGImage,
        scale: CGFloat,
        imageSize: CGSize
    ) {
        let scaledRect = annotation.rect.scaled(by: scale)
        // Flip y for CGImage crop (which uses top-left origin)
        let cropRect = CGRect(
            x: scaledRect.origin.x,
            y: imageSize.height - scaledRect.maxY,
            width: scaledRect.width,
            height: scaledRect.height
        )
        guard let cropped = base.cropping(to: cropRect) else { return }

        let ciImage = CIImage(cgImage: cropped)
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(annotation.radius * scale, forKey: kCIInputRadiusKey)

        let ciContext = CIContext()
        guard let outputCI = blurFilter.outputImage,
              let blurredCG = ciContext.createCGImage(outputCI, from: ciImage.extent) else { return }

        context.draw(blurredCG, in: scaledRect)
    }

    // MARK: - Mosaic

    private func applyMosaic(
        _ annotation: MosaicAnnotation,
        to context: CGContext,
        base: CGImage,
        scale: CGFloat,
        imageSize: CGSize
    ) {
        let scaledRect = annotation.rect.scaled(by: scale)
        let cropRect = CGRect(
            x: scaledRect.origin.x,
            y: imageSize.height - scaledRect.maxY,
            width: scaledRect.width,
            height: scaledRect.height
        )
        guard let cropped = base.cropping(to: cropRect) else { return }

        // Pixelate via CIFilter
        let ciImage = CIImage(cgImage: cropped)
        guard let pixelFilter = CIFilter(name: "CIPixellate") else { return }
        pixelFilter.setValue(ciImage, forKey: kCIInputImageKey)
        pixelFilter.setValue(annotation.blockSize * scale, forKey: kCIInputScaleKey)

        let ciContext = CIContext()
        guard let outputCI = pixelFilter.outputImage,
              let pixelatedCG = ciContext.createCGImage(outputCI, from: ciImage.extent) else { return }

        context.draw(pixelatedCG, in: scaledRect)
    }
}
