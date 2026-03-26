import SwiftUI
import AppKit

struct EditorView: View {
    @Environment(EditorViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            canvas
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            toolButtons
            Divider().frame(height: 24)
            strokeControls
            Divider().frame(height: 24)
            undoRedoButtons
            Spacer()
            exportButtons
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Tool Buttons

    private var toolButtons: some View {
        HStack(spacing: 2) {
            ForEach(DrawingTool.allCases, id: \.self) { tool in
                Button {
                    viewModel.currentTool = tool
                } label: {
                    Image(systemName: tool.iconName)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    viewModel.currentTool == tool
                        ? Color.accentColor.opacity(0.25)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
                .help(tool.localizedTitle)
            }
        }
    }

    // MARK: - Stroke Controls

    private var strokeControls: some View {
        HStack(spacing: 6) {
            ColorPicker("", selection: Binding(
                get: { Color(cgColor: viewModel.strokeColor) ?? .red },
                set: { newColor in
                    viewModel.strokeColor = NSColor(newColor).cgColor
                }
            ))
            .labelsHidden()
            .help("線の色")

            Slider(
                value: Binding(get: { viewModel.strokeWidth }, set: { viewModel.strokeWidth = $0 }),
                in: 1...10,
                step: 0.5
            )
            .frame(width: 60)
            .help("線の太さ")

            Text("\(Int(viewModel.strokeWidth))px")
                .font(.caption.monospacedDigit())
                .frame(width: 28)
        }
    }

    // MARK: - Undo / Redo

    private var undoRedoButtons: some View {
        HStack(spacing: 2) {
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canUndo)
            .keyboardShortcut("z", modifiers: .command)
            .help("元に戻す")

            Button {
                viewModel.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canRedo)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .help("やり直す")
        }
    }

    // MARK: - Export Buttons

    private var exportButtons: some View {
        Button {
            Task { await viewModel.exportOnDone() }
        } label: {
            Label("完了", systemImage: "checkmark")
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.return, modifiers: .command)
        .help("設定に従いエクスポートして閉じる (⌘Return)")
    }

    // MARK: - Canvas

    private var canvas: some View {
        // キャンバス NSView をビューポート全体に広げる。
        // 画像の中央配置とフィットスケールは CanvasNSView 内部で管理する。
        CanvasViewWrapper(viewModel: viewModel)
            .cursor(viewModel.currentTool == .text ? .iBeam : .crosshair)
            .background(Color(nsColor: .underPageBackgroundColor))
    }
}

// MARK: - Cursor Modifier

private struct CursorModifier: ViewModifier {
    let cursor: NSCursor
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering { cursor.set() } else { NSCursor.arrow.set() }
        }
    }
}

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        modifier(CursorModifier(cursor: cursor))
    }
}
