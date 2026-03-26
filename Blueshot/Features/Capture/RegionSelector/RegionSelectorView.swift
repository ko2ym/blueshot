import SwiftUI
import AppKit

/// Shared mutable state for the region selection gesture, coordinated across screens.
@MainActor
@Observable
final class RegionSelectionState {
    var dragStart: CGPoint? = nil
    var dragCurrent: CGPoint? = nil
    var selectedRect: CGRect? = nil
    var targetScreen: NSScreen? = nil

    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?

    var isDragging: Bool { dragStart != nil }

    var currentRect: CGRect? {
        guard let start = dragStart, let current = dragCurrent else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }
}

/// The SwiftUI overlay drawn on a single screen during region selection.
struct RegionSelectorView: View {
    let screen: NSScreen
    let state: RegionSelectionState

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 完全透明な背景（ヒットテスト用）
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(dragGesture(in: geo))

                if let rect = state.currentRect {
                    let localRect = rectInLocalCoordinates(rect, geo: geo)

                    // 選択枠（白 + 黒のダブルボーダーで背景を問わず視認性を確保）
                    Rectangle()
                        .stroke(Color.black.opacity(0.5), lineWidth: 3)
                        .frame(width: localRect.width, height: localRect.height)
                        .position(x: localRect.midX, y: localRect.midY)
                        .allowsHitTesting(false)

                    Rectangle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: localRect.width, height: localRect.height)
                        .position(x: localRect.midX, y: localRect.midY)
                        .allowsHitTesting(false)

                    // サイズラベル
                    sizeLabelView(for: rect, localRect: localRect)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func rectInLocalCoordinates(_ rect: CGRect, geo: GeometryProxy) -> CGRect {
        // rect is in screen coordinates; convert to local view coordinates
        let origin = CGPoint(
            x: rect.origin.x - screen.frame.origin.x,
            y: screen.frame.height - (rect.origin.y - screen.frame.origin.y) - rect.height
        )
        return CGRect(origin: origin, size: rect.size)
    }

    private func screenPoint(from localPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: localPoint.x + screen.frame.origin.x,
            y: screen.frame.height - localPoint.y + screen.frame.origin.y
        )
    }

    private func dragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                let start = screenPoint(from: value.startLocation)
                let current = screenPoint(from: value.location)
                if state.dragStart == nil {
                    state.dragStart = start
                    state.targetScreen = screen
                }
                state.dragCurrent = current
            }
            .onEnded { value in
                if let rect = state.currentRect, rect.width > 10, rect.height > 10 {
                    state.selectedRect = rect
                    state.onCommit?()
                } else {
                    state.dragStart = nil
                    state.dragCurrent = nil
                }
            }
    }

    @ViewBuilder
    private func sizeLabelView(for rect: CGRect, localRect: CGRect) -> some View {
        let scale = DisplayManager.scaleFactor(for: screen)
        let px = Int(rect.width * scale)
        let py = Int(rect.height * scale)
        Text("\(px) × \(py)")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
            .position(x: localRect.midX, y: max(localRect.minY - 18, 18))
            .allowsHitTesting(false)
    }
}
