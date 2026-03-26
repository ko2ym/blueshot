import SwiftUI
import AppKit
import Carbon.HIToolbox

/// A view that records a single key+modifier combination from the user.
struct HotKeyRecorderView: View {
    let currentBinding: HotKeyBinding?
    let isReserved: Bool
    let onRecord: (HotKeyBinding) -> Void

    @State private var isRecording = false
    @State private var pendingBinding: HotKeyBinding?

    var body: some View {
        RecorderNSViewBridge(
            isRecording: $isRecording,
            onRecord: { binding in
                pendingBinding = binding
                isRecording = false
                onRecord(binding)
            },
            onCancel: { isRecording = false }
        )
        .frame(width: 140, height: 26)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isRecording ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .overlay(alignment: .center) {
            label
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 5))
        .onTapGesture { isRecording = true }
    }

    @ViewBuilder
    private var label: some View {
        if isRecording {
            Text("キーを入力…")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        } else if let binding = pendingBinding ?? currentBinding {
            HStack(spacing: 3) {
                Text(binding.displayString)
                    .font(.system(.body, design: .monospaced))
                if isReserved {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
        } else {
            Text("—")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - NSView Bridge

private struct RecorderNSViewBridge: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onRecord: (HotKeyBinding) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onRecord = onRecord
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.onRecord = onRecord
        nsView.onCancel = onCancel
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class Coordinator {}
}

// MARK: - Recorder NSView

private final class RecorderNSView: NSView {
    var onRecord: ((HotKeyBinding) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if Int(event.keyCode) == kVK_Escape {
            onCancel?()
            return
        }
        let mods = event.modifierFlags.intersection([.command, .option, .shift, .control])
        // F1-F12 はファンクションキー単独でも許可する
        let isFunctionKey: Bool = {
            let code = Int(event.keyCode)
            return code == kVK_F1 || code == kVK_F2 || code == kVK_F3 ||
                   code == kVK_F4 || code == kVK_F5 || code == kVK_F6 ||
                   code == kVK_F7 || code == kVK_F8 || code == kVK_F9 ||
                   code == kVK_F10 || code == kVK_F11 || code == kVK_F12
        }()
        guard !mods.isEmpty || isFunctionKey else { return }

        var carbonMods: UInt32 = 0
        if mods.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if mods.contains(.option)  { carbonMods |= UInt32(optionKey) }
        if mods.contains(.shift)   { carbonMods |= UInt32(shiftKey) }
        if mods.contains(.control) { carbonMods |= UInt32(controlKey) }

        onRecord?(HotKeyBinding(keyCode: UInt32(event.keyCode), modifiers: carbonMods))
    }
}
