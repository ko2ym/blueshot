#!/usr/bin/env swift
import AppKit
import CoreGraphics

// MARK: - Icon Generator for Blueshot
// Design: Blue gradient background (rounded square) + white screen + dashed selection box + crosshair

func generateIcon(size: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(size)
    let ctx = NSGraphicsContext.current!.cgContext

    // --- Background: rounded square with blue gradient ---
    let radius = s * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient: deep blue (top) → bright blue (bottom)  ※CGContext y=0 is bottom
    let colors = [
        CGColor(red: 0.05, green: 0.35, blue: 0.85, alpha: 1.0),  // bright blue (bottom in CGContext = visual top)
        CGColor(red: 0.02, green: 0.18, blue: 0.55, alpha: 1.0),  // deep blue
    ] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: s / 2, y: s),
        end: CGPoint(x: s / 2, y: 0),
        options: []
    )
    ctx.resetClip()

    // --- Screen frame (white rounded rect) ---
    let screenInset = s * 0.15
    let screenRect = CGRect(
        x: screenInset, y: screenInset + s * 0.06,
        width: s - screenInset * 2, height: s - screenInset * 2 - s * 0.10
    )
    let screenRadius = s * 0.04
    let screenPath = CGPath(roundedRect: screenRect, cornerWidth: screenRadius, cornerHeight: screenRadius, transform: nil)

    // Screen fill: very dark blue (simulates screen content)
    ctx.addPath(screenPath)
    ctx.setFillColor(CGColor(red: 0.06, green: 0.10, blue: 0.22, alpha: 0.85))
    ctx.fillPath()

    // Screen border: white
    ctx.addPath(screenPath)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(s * 0.025)
    ctx.strokePath()

    // Stand/base (small rect at bottom center)
    let standW = s * 0.20
    let standH = s * 0.05
    let standX = (s - standW) / 2
    let standY = screenInset + s * 0.06 - standH
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
    ctx.fill(CGRect(x: standX, y: standY, width: standW, height: standH))

    // --- Dashed selection rectangle (inside screen) ---
    let selInset = screenRect.width * 0.18
    let selRect = CGRect(
        x: screenRect.minX + selInset,
        y: screenRect.minY + selInset,
        width: screenRect.width - selInset * 2,
        height: screenRect.height - selInset * 2
    )
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.setLineWidth(s * 0.022)
    ctx.setLineDash(phase: 0, lengths: [s * 0.05, s * 0.03])
    ctx.stroke(selRect)
    ctx.setLineDash(phase: 0, lengths: [])

    // Corner handles
    let handleSize = s * 0.04
    let handleColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)
    ctx.setFillColor(handleColor)
    let corners: [(CGFloat, CGFloat)] = [
        (selRect.minX, selRect.minY),
        (selRect.maxX, selRect.minY),
        (selRect.minX, selRect.maxY),
        (selRect.maxX, selRect.maxY),
    ]
    for (cx, cy) in corners {
        ctx.fill(CGRect(x: cx - handleSize/2, y: cy - handleSize/2, width: handleSize, height: handleSize))
    }

    // --- Crosshair cursor (center of screen) ---
    let cx = screenRect.midX + selRect.width * 0.18
    let cy = screenRect.midY - selRect.height * 0.10
    let crossLen = s * 0.07
    let crossGap = s * 0.025
    let crossW = s * 0.022

    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.setLineWidth(crossW)
    ctx.setLineCap(.round)

    // Horizontal lines (left and right of center gap)
    ctx.move(to: CGPoint(x: cx - crossLen, y: cy))
    ctx.addLine(to: CGPoint(x: cx - crossGap, y: cy))
    ctx.move(to: CGPoint(x: cx + crossGap, y: cy))
    ctx.addLine(to: CGPoint(x: cx + crossLen, y: cy))

    // Vertical lines (above and below center gap)
    ctx.move(to: CGPoint(x: cx, y: cy - crossLen))
    ctx.addLine(to: CGPoint(x: cx, y: cy - crossGap))
    ctx.move(to: CGPoint(x: cx, y: cy + crossGap))
    ctx.addLine(to: CGPoint(x: cx, y: cy + crossLen))

    ctx.strokePath()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// MARK: - Output sizes
let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

let sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes {
    let rep = generateIcon(size: size)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(size)x\(size)")
        continue
    }
    let path = "\(outputDir)/icon_\(size).png"
    try! data.write(to: URL(fileURLWithPath: path))
    print("Generated: \(path)")
}
