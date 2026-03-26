import AppKit
import Carbon.HIToolbox
import SwiftUI

/// オーバーレイウィンドウ専用の NSWindow サブクラス。
/// resetCursorRects() を空にすることで NSHostingView を含む全ビューの
/// カーソルrects処理を完全に止め、NSCursor.push()/pop() だけでカーソルを管理する。
private final class OverlayCursorWindow: NSWindow {
    override func resetCursorRects() {
        // intentionally empty: cursor managed via NSCursor.push()/pop() in RegionSelectorWindowController
    }
}

/// Manages the fullscreen transparent overlay windows used for region selection.
/// One window is created per screen. The selected rect is returned via the completion handler.
@MainActor
final class RegionSelectorWindowController: NSObject {

    // MARK: - Types

    enum Result {
        case selected(rect: CGRect, screen: NSScreen)
        case cancelled
    }

    // MARK: - Private State

    private var windows: [NSWindow] = []
    private var hostingControllers: [NSHostingController<RegionSelectorView>] = []
    private var completion: ((Result) -> Void)?
    private var selectionState = RegionSelectionState()
    private var keyEventMonitor: Any?
    private var cursorMonitors: [Any] = []

    // MARK: - Public API

    /// Shows the region selector overlay on all screens and calls completion when done.
    func beginSelection(completion: @escaping @MainActor (Result) -> Void) {
        self.completion = completion
        selectionState = RegionSelectionState()
        selectionState.onCommit = { [weak self] in
            self?.commitSelection()
        }
        selectionState.onCancel = { [weak self] in
            self?.cancel()
        }

        for screen in NSScreen.screens {
            showOverlay(on: screen)
        }

        // .onKeyPress は SwiftUI フォーカスが必要で透過ウィンドウでは動作しないため
        // NSEvent のローカルモニターで ESC を処理する
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if Int(event.keyCode) == kVK_Escape {
                self?.cancel()
                return nil   // イベントを消費
            }
            return event
        }

        // マウス移動イベントのたびに crosshair を強制設定する。
        // ローカル（メニューなど自アプリがアクティブな場合）と
        // グローバル（ショートカットキー起動で他アプリがフォアグラウンドの場合）の
        // 両方を登録して確実に crosshair を維持する。
        let eventMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp]
        NSCursor.crosshair.set()
        if let local = NSEvent.addLocalMonitorForEvents(matching: eventMask, handler: { event in
            NSCursor.crosshair.set()
            return event
        }) {
            cursorMonitors.append(local)
        }
        NSEvent.addGlobalMonitorForEvents(matching: eventMask) { _ in
            NSCursor.crosshair.set()
        }.map { cursorMonitors.append($0) }
    }

    // MARK: - Private

    private func showOverlay(on screen: NSScreen) {
        let window = OverlayCursorWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = RegionSelectorView(screen: screen, state: selectionState)
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = CGRect(origin: .zero, size: screen.frame.size)
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = .clear
        window.contentView = hosting.view

        // ウィンドウ表示前に cursor rects を無効化（makeKeyAndOrderFront でのカーソル更新を防ぐ）
        window.disableCursorRects()
        window.makeKeyAndOrderFront(nil)

        windows.append(window)
        hostingControllers.append(hosting)
    }

    private func commitSelection() {
        guard let rect = selectionState.selectedRect,
              let screen = selectionState.targetScreen else {
            cancel()
            return
        }
        dismissOverlays()
        completion?(.selected(rect: rect, screen: screen))
        completion = nil
    }

    private func cancel() {
        dismissOverlays()
        completion?(.cancelled)
        completion = nil
    }

    private func dismissOverlays() {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        cursorMonitors.forEach { NSEvent.removeMonitor($0) }
        cursorMonitors.removeAll()
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        hostingControllers.removeAll()
        NSCursor.arrow.set()  // 元のカーソルに戻す
    }
}
