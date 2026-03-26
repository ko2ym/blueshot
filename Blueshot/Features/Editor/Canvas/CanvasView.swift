import AppKit
import SwiftUI

/// NSViewRepresentable wrapper that hosts the actual CanvasNSView.
/// Use CanvasViewWrapper (the non-Binding version) from SwiftUI views.
struct CanvasView: NSViewRepresentable {
    @Binding var viewModel: EditorViewModel

    func makeNSView(context: Context) -> CanvasNSView {
        let view = CanvasNSView()
        view.viewModel = viewModel
        return view
    }

    func updateNSView(_ nsView: CanvasNSView, context: Context) {
        nsView.viewModel = viewModel
        nsView.needsDisplay = true
    }
}

/// Convenience wrapper for use with @Observable (no Binding needed).
struct CanvasViewWrapper: NSViewRepresentable {
    var viewModel: EditorViewModel

    func makeNSView(context: Context) -> CanvasNSView {
        let view = CanvasNSView()
        view.viewModel = viewModel
        return view
    }

    func updateNSView(_ nsView: CanvasNSView, context: Context) {
        nsView.viewModel = viewModel
        nsView.needsDisplay = true
    }
}

/// The actual drawing surface. Handles mouse events and renders via CanvasRenderer.
final class CanvasNSView: NSView {

    var viewModel: EditorViewModel? {
        didSet { needsDisplay = true }
    }

    private var isShowingTextInput = false

    // MARK: - Setup

    override var isFlipped: Bool { true }   // top-left origin for point coordinates
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    // MARK: - Image Layout

    /// 現在の bounds 内で画像をアスペクト比を保って中央配置したときの描画 rect を返す。
    /// draw() と viewToImagePoint() の両方でこの rect を基準にすることで座標が一致する。
    private var imageDrawRect: CGRect {
        guard let vm = viewModel else { return bounds }
        let img = vm.captureResult.image
        let scale = vm.captureResult.scale
        let logW = CGFloat(img.width) / scale
        let logH = CGFloat(img.height) / scale
        let fitScale = min(bounds.width / logW, bounds.height / logH, 1.0)
        let w = (logW * fitScale).rounded(.down)
        let h = (logH * fitScale).rounded(.down)
        let x = ((bounds.width - w) / 2).rounded(.down)
        let y = ((bounds.height - h) / 2).rounded(.down)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext,
              let vm = viewModel else { return }

        let image = vm.previewImage() ?? vm.captureResult.image
        let rect = imageDrawRect

        // isFlipped=true の NSView では AppKit が CGContext に flip CTM を適用済み（y-down）。
        // CGContext.draw は y-up 前提で描画するため、さらに flip を重ねることで
        // double-flip（net y-up）となり、CanvasRenderer が生成した CGImage が正しく表示される。
        ctx.saveGState()
        ctx.translateBy(x: rect.origin.x, y: rect.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(image, in: CGRect(origin: .zero, size: rect.size))
        ctx.restoreGState()
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let imagePoint = viewToImagePoint(point)
        viewModel?.mouseDown(at: imagePoint)

        if viewModel?.currentTool == .text {
            showTextInput(at: point)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        viewModel?.mouseDragged(to: viewToImagePoint(point))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        viewModel?.mouseUp(at: viewToImagePoint(point))
        needsDisplay = true
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "z":
                if event.modifierFlags.contains(.shift) {
                    viewModel?.redo()
                } else {
                    viewModel?.undo()
                }
                needsDisplay = true
                return
            default: break
            }
        }
        super.keyDown(with: event)
    }

    // MARK: - Text Input

    private func showTextInput(at point: CGPoint) {
        guard !isShowingTextInput else { return }
        isShowingTextInput = true

        let field = NSTextField(frame: CGRect(x: point.x, y: point.y - 24, width: 200, height: 28))
        field.placeholderString = "テキストを入力…"
        field.bezelStyle = .roundedBezel
        field.isBordered = true
        field.backgroundColor = .controlBackgroundColor
        field.focusRingType = .none
        addSubview(field)
        window?.makeFirstResponder(field)

        // Observe commit via NotificationCenter
        NotificationCenter.default.addObserver(
            forName: NSControl.textDidEndEditingNotification,
            object: field,
            queue: .main
        ) { [weak self, weak field] _ in
            guard let self, let field else { return }
            let text = field.stringValue
            field.removeFromSuperview()
            self.isShowingTextInput = false
            self.viewModel?.commitText(text)
            self.needsDisplay = true
            self.window?.makeFirstResponder(self)
        }
    }

    // MARK: - Coordinate Conversion

    /// Converts a view-space point (flipped, points) to image-space coordinates (points).
    /// imageDrawRect を基準にすることで、ビュー内の画像位置と描画座標が一致する。
    private func viewToImagePoint(_ viewPoint: CGPoint) -> CGPoint {
        guard let vm = viewModel else { return viewPoint }
        let rect = imageDrawRect
        guard rect.width > 0, rect.height > 0 else { return viewPoint }
        let img = vm.captureResult.image
        let scale = vm.captureResult.scale
        let logW = CGFloat(img.width) / scale
        let logH = CGFloat(img.height) / scale
        let localX = viewPoint.x - rect.origin.x
        let localY = viewPoint.y - rect.origin.y
        return CGPoint(
            x: localX * logW / rect.width,
            y: localY * logH / rect.height
        )
    }
}
