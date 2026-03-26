import AppKit
import CoreGraphics
import ImageIO
import OSLog
import UniformTypeIdentifiers

/// Handles saving CaptureResult to file or clipboard.
actor ExportService {

    func export(_ result: CaptureResult, configuration: ExportConfiguration) async throws {
        switch configuration.destination {
        case .clipboardOnly:
            try copyToClipboard(result.image)
        case .folderOnly:
            try await saveToFile(result, configuration: configuration)
        case .both:
            try copyToClipboard(result.image)
            try await saveToFile(result, configuration: configuration)
        }
    }

    // MARK: - Clipboard

    func copyToClipboard(_ image: CGImage) throws {
        let nsImage = NSImage(cgImage: image, size: .zero)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.writeObjects([nsImage]) else {
            throw BlueshotError.exportClipboardFailed
        }
        Logger.export.info("Image copied to clipboard")
    }

    // MARK: - File

    func saveToFile(_ result: CaptureResult, configuration: ExportConfiguration) async throws {
        let bookmarkManager = await BookmarkManager.shared
        let folder = try await bookmarkManager.resolveURL()

        let naming = FileNamingService()
        let filename = naming.resolve(template: configuration.namingTemplate, date: result.capturedAt, index: nil)
        let fileURL = folder.appendingPathComponent(filename).appendingPathExtension(configuration.format.fileExtension)

        let image = result.image
        let format = configuration.format
        let quality = configuration.jpegQuality
        try await bookmarkManager.withAccess { [fileURL] in
            try ExportService.writeImageStatic(image, to: fileURL, format: format, quality: quality)
        }
        Logger.export.info("Image saved to \(fileURL.path)")
    }

    private static func writeImageStatic(_ image: CGImage, to url: URL, format: ExportFormat, quality: Double) throws {
        let uti: UTType = format == .png ? .png : .jpeg
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uti.identifier as CFString, 1, nil) else {
            throw BlueshotError.exportWriteFailed(underlying: CocoaError(.fileWriteUnknown))
        }

        var properties: [CFString: Any] = [:]
        if format == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw BlueshotError.exportWriteFailed(underlying: CocoaError(.fileWriteUnknown))
        }
    }
}
