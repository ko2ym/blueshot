import AppKit
import SwiftUI

/// Hosts the screenshot editor in an NSWindow.
/// Full implementation in Sprint 4.
@MainActor
final class EditorWindowController: NSWindowController {

    private let captureResult: CaptureResult
    private let preferences: AppPreferences
    private let viewModel: EditorViewModel

    init(captureResult: CaptureResult, preferences: AppPreferences) {
        self.captureResult = captureResult
        self.preferences = preferences

        let viewModel = EditorViewModel(captureResult: captureResult, preferences: preferences)
        self.viewModel = viewModel
        let rootView = EditorView().environment(viewModel)
        let hosting = NSHostingController(rootView: rootView)

        let window = NSWindow(contentViewController: hosting)
        window.title = "Blueshot エディタ"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 800, height: 600))
        window.center()

        super.init(window: window)

        // 完了ボタン押下後にウィンドウを閉じる
        viewModel.onExportDone = { [weak window] in
            window?.close()
        }
    }

    required init?(coder: NSCoder) { fatalError("Use init(captureResult:preferences:)") }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}
