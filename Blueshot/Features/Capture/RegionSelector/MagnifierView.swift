import SwiftUI
import AppKit
import CoreGraphics

/// Shows a magnified view of the pixels around the cursor during region selection.
struct MagnifierView: View {
    let cursorPosition: CGPoint
    let screen: NSScreen

    private let magnifierSize: CGFloat = 120
    private let zoomFactor: CGFloat = 4.0
    private let captureRadius: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let localPos = CGPoint(
                x: cursorPosition.x - screen.frame.origin.x,
                y: screen.frame.height - (cursorPosition.y - screen.frame.origin.y)
            )
            let offsetX = localPos.x + 20
            let offsetY = localPos.y - magnifierSize - 20
            let clampedX = min(max(offsetX, 0), geo.size.width - magnifierSize)
            let clampedY = min(max(offsetY, 0), geo.size.height - magnifierSize)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)

                if let image = captureZoomedImage() {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: magnifierSize - 4, height: magnifierSize - 4)
                        .clipped()
                }

                // Crosshair
                Path { path in
                    let center = magnifierSize / 2
                    path.move(to: CGPoint(x: center, y: 0))
                    path.addLine(to: CGPoint(x: center, y: magnifierSize))
                    path.move(to: CGPoint(x: 0, y: center))
                    path.addLine(to: CGPoint(x: magnifierSize, y: center))
                }
                .stroke(Color.red.opacity(0.8), lineWidth: 1)

                // Coordinate label
                VStack {
                    Spacer()
                    Text("\(Int(cursorPosition.x)), \(Int(cursorPosition.y))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: magnifierSize, height: magnifierSize)
            .position(x: clampedX + magnifierSize / 2, y: clampedY + magnifierSize / 2)
        }
    }

    private func captureZoomedImage() -> NSImage? {
        let captureRect = CGRect(
            x: cursorPosition.x - captureRadius,
            y: cursorPosition.y - captureRadius,
            width: captureRadius * 2,
            height: captureRadius * 2
        )
        let displayID = DisplayManager.displayID(for: screen)
        guard let cgImage = CGDisplayCreateImage(displayID, rect: captureRect) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: magnifierSize - 4, height: magnifierSize - 4))
    }
}
