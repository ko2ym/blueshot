import AppKit
import CoreGraphics
import Observation
import OSLog

@MainActor
@Observable
final class EditorViewModel {

    // MARK: - State

    let captureResult: CaptureResult
    private let preferences: AppPreferences
    private let undoRedo = UndoRedoManager()
    private let renderer = CanvasRenderer()

    /// 設定に従いエクスポートが完了した後に呼び出されるクロージャ（ウィンドウクローズなど）。
    var onExportDone: (() -> Void)?

    private(set) var annotations: [any Annotation] = []
    private(set) var inProgressAnnotation: (any Annotation)?

    var currentTool: DrawingTool = .rectangle
    var strokeColor: CGColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
    var fillColor: CGColor? = nil
    var strokeWidth: CGFloat = 2.0
    var fontSize: CGFloat = 16.0
    var blurRadius: CGFloat = 10.0
    var mosaicBlockSize: CGFloat = 12.0

    var canUndo: Bool { undoRedo.canUndo }
    var canRedo: Bool { undoRedo.canRedo }

    // MARK: - Drag tracking (set by CanvasView)

    private var dragStart: CGPoint?
    private var isEditingText = false
    private var pendingTextOrigin: CGPoint?

    // MARK: - Init

    init(captureResult: CaptureResult, preferences: AppPreferences) {
        self.captureResult = captureResult
        self.preferences = preferences
    }

    // MARK: - Mouse Events (called from CanvasView in point coordinates)

    func mouseDown(at point: CGPoint) {
        switch currentTool {
        case .text:
            pendingTextOrigin = point
            // Text editing handled via overlay; annotation committed in commitText()
        default:
            dragStart = point
            inProgressAnnotation = nil
        }
    }

    func mouseDragged(to point: CGPoint) {
        guard let start = dragStart else { return }
        inProgressAnnotation = makeAnnotation(from: start, to: point, committed: false)
    }

    func mouseUp(at point: CGPoint) {
        guard let start = dragStart else { return }
        dragStart = nil
        inProgressAnnotation = nil

        let annotation = makeAnnotation(from: start, to: point, committed: true)
        guard let a = annotation else { return }
        let minSize: CGFloat = 4
        if a.boundingRect.width < minSize && a.boundingRect.height < minSize { return }

        undoRedo.saveSnapshot(annotations)
        annotations.append(a)
    }

    func commitText(_ text: String) {
        guard !text.isEmpty, let origin = pendingTextOrigin else {
            pendingTextOrigin = nil
            return
        }
        pendingTextOrigin = nil
        let annotation = TextAnnotation(
            origin: origin,
            text: text,
            fontSize: fontSize,
            color: strokeColor
        )
        undoRedo.saveSnapshot(annotations)
        annotations.append(annotation)
    }

    // MARK: - Undo / Redo

    func undo() {
        guard let previous = undoRedo.undo(current: annotations) else { return }
        annotations = previous
        inProgressAnnotation = nil
    }

    func redo() {
        guard let next = undoRedo.redo(current: annotations) else { return }
        annotations = next
        inProgressAnnotation = nil
    }

    // MARK: - Rendered Image

    /// Returns the final composited CGImage with all annotations applied.
    func finalImage() -> CGImage? {
        renderer.render(base: captureResult.image, annotations: annotations, scale: captureResult.scale)
    }

    /// Returns a preview CGImage including any in-progress annotation.
    func previewImage() -> CGImage? {
        renderer.renderPreview(
            base: captureResult.image,
            annotations: annotations,
            inProgress: inProgressAnnotation,
            scale: captureResult.scale
        )
    }

    // MARK: - Export

    /// 設定の exportDestination に従ってエクスポートし、成功したら onExportDone を呼ぶ。
    func exportOnDone() async {
        guard let image = finalImage() else { return }
        let result = CaptureResult(
            image: image,
            scale: captureResult.scale,
            capturedAt: captureResult.capturedAt,
            displayID: captureResult.displayID
        )
        let exportService = ExportService()
        let config = preferences.makeExportConfiguration()
        do {
            try await exportService.export(result, configuration: config)
        } catch {
            Logger.editor.error("Export failed: \(error)")
            let alert = NSAlert()
            alert.messageText = "エクスポートに失敗しました"
            alert.informativeText = (error as? BlueshotError)?.errorDescription ?? error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
        onExportDone?()
    }

    func exportToClipboard() async {
        guard let image = finalImage() else { return }
        let exportService = ExportService()
        do {
            try await exportService.copyToClipboard(image)
        } catch {
            Logger.editor.error("Clipboard export failed: \(error)")
        }
    }

    func exportToFile() async {
        guard let image = finalImage() else { return }
        let result = CaptureResult(
            image: image,
            scale: captureResult.scale,
            capturedAt: captureResult.capturedAt,
            displayID: captureResult.displayID
        )
        let exportService = ExportService()
        let config = preferences.makeExportConfiguration()
        do {
            try await exportService.saveToFile(result, configuration: config)
        } catch {
            Logger.editor.error("File export failed: \(error)")
            let alert = NSAlert()
            alert.messageText = "保存に失敗しました"
            alert.informativeText = (error as? BlueshotError)?.errorDescription ?? error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    // MARK: - Private Factory

    private func makeAnnotation(from start: CGPoint, to end: CGPoint, committed: Bool) -> (any Annotation)? {
        let rect = CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y),
            width: abs(end.x - start.x), height: abs(end.y - start.y)
        )
        switch currentTool {
        case .rectangle:
            return RectangleAnnotation(rect: rect, strokeColor: strokeColor, fillColor: fillColor, lineWidth: strokeWidth)
        case .arrow:
            return ArrowAnnotation(start: start, end: end, color: strokeColor, lineWidth: strokeWidth)
        case .highlight:
            let highlightColor = strokeColor.copy(alpha: 0.4) ?? strokeColor
            return HighlightAnnotation(rect: rect, color: highlightColor)
        case .blur:
            return BlurAnnotation(rect: rect, radius: blurRadius)
        case .mosaic:
            return MosaicAnnotation(rect: rect, blockSize: mosaicBlockSize)
        case .text:
            return nil  // committed via commitText()
        }
    }
}
