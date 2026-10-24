// Generates the workflow device icons from SF Symbols.
//
// Usage:
//   xcrun swift tools/generate_icons.swift
//
// The output is written to assets/icons/. Add or change entries in `specs`
// below and rerun the script to regenerate the PNGs.
//
// Alfred draws the same PNG on the theme background and, for the selected row,
// on the theme's selection colour, and its script filter API has no per-state
// icon. A saturated glyph therefore disappears on a selection of the same
// colour (the blue highlight most themes use, for example), so every icon is
// drawn with a dark rim: invisible on dark themes, but it keeps the glyph
// readable on light backgrounds and on any saturated selection colour.

import AppKit

// Icons are drawn in a 512pt canvas and rasterised at `pixelSize`. 256px is
// still 4x the size Alfred draws a result icon at, which keeps the bundled
// assets small.
let canvas: CGFloat = 512
let pixelSize: CGFloat = 256
// Width of the rim at the rasterised size (2px at the 64pt Alfred draws).
let rimRadius: CGFloat = 8
// Connected devices: systemGreen, which reads as "active" and stays distinct
// from the blue selection most themes use.
let green = NSColor(srgbRed: 0.204, green: 0.780, blue: 0.349, alpha: 1.0)
// Opaque mid-gray so disconnected icons stay visible on light and dark themes.
let gray = NSColor(srgbRed: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)
let white = NSColor.white
// Destructive action accent (systemRed-ish), used by the unpair icon.
let red = NSColor(srgbRed: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)
// Rim colour: near-black, so it works as a shadow on dark backgrounds and as a
// defining edge on light ones.
let rim = NSColor(srgbRed: 0.110, green: 0.110, blue: 0.118, alpha: 1.0)

let cwd = FileManager.default.currentDirectoryPath
let scriptPath = CommandLine.arguments[0].hasPrefix("/")
    ? CommandLine.arguments[0]
    : "\(cwd)/\(CommandLine.arguments[0])"
let scriptURL = URL(fileURLWithPath: scriptPath).standardizedFileURL
let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputDir = repoRoot.appendingPathComponent("assets/icons").path

enum Badge {
    case apple
    case letter(String)
}

struct Spec {
    let name: String
    let symbol: String
    let badge: Badge?
    // When set, the icon is drawn once in this color (no `_off` variant).
    // Device icons leave it nil and get the green/gray variants instead.
    let color: NSColor?

    init(name: String, symbol: String, badge: Badge?, color: NSColor? = nil) {
        self.name = name
        self.symbol = symbol
        self.badge = badge
        self.color = color
    }
}

let specs: [Spec] = [
    Spec(name: "keyboard", symbol: "keyboard", badge: nil),
    Spec(name: "mouse", symbol: "computermouse", badge: nil),
    Spec(name: "trackpad", symbol: "rectangle.and.hand.point.up.left", badge: nil),
    Spec(name: "headphones", symbol: "headphones", badge: nil),
    Spec(name: "speaker", symbol: "hifispeaker", badge: nil),
    Spec(name: "phone", symbol: "iphone", badge: nil),
    Spec(name: "tablet", symbol: "ipad", badge: nil),
    Spec(name: "watch", symbol: "applewatch", badge: nil),
    Spec(name: "gamecontroller", symbol: "gamecontroller", badge: nil),
    Spec(name: "computer", symbol: "laptopcomputer", badge: nil),
    Spec(name: "bluetooth", symbol: "dot.radiowaves.left.and.right", badge: nil),
    Spec(name: "magic_mouse", symbol: "magicmouse", badge: nil),
    Spec(name: "magic_keyboard", symbol: "keyboard.fill", badge: .apple),
    // Drawn separately: a flat rounded rectangle with an Apple logo.
    Spec(name: "magic_trackpad", symbol: "", badge: nil),
    Spec(name: "airpods", symbol: "airpods", badge: nil),
    Spec(name: "airpods_pro", symbol: "airpodspro", badge: nil),
    Spec(name: "airpods_max", symbol: "airpodsmax", badge: nil),
    Spec(name: "mx_master", symbol: "computermouse.fill", badge: nil),
    Spec(name: "keychron", symbol: "keyboard", badge: .letter("K")),
    // Action icons for the unpair confirmation, drawn once in their own color.
    Spec(name: "unpair", symbol: "antenna.radiowaves.left.and.right.slash", badge: nil, color: red),
    Spec(name: "cancel", symbol: "xmark.circle", badge: nil, color: gray),
]

struct IconVariant {
    let suffix: String
    let color: NSColor
}

let variants: [IconVariant] = [
    IconVariant(suffix: "", color: green),
    IconVariant(suffix: "_off", color: gray),
]

try! FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true)

func symbolImage(named: String, pointSize: CGFloat, color: NSColor) -> NSImage? {
    guard let base = NSImage(systemSymbolName: named, accessibilityDescription: "") else {
        return nil
    }
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    return base.withSymbolConfiguration(config)
}

func drawCentered(_ image: NSImage, in canvas: NSRect, maxSide: CGFloat, centerY: CGFloat) {
    let scale = min(maxSide / image.size.width, maxSide / image.size.height)
    let width = image.size.width * scale
    let height = image.size.height * scale
    let rect = NSRect(
        x: (canvas.width - width) / 2,
        y: centerY - height / 2,
        width: width,
        height: height)
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
}

func drawMagicTrackpad(color: NSColor) {
    let rect = NSRect(x: 76, y: 126, width: 360, height: 260)
    let path = NSBezierPath(roundedRect: rect, xRadius: 54, yRadius: 54)
    color.setFill()
    path.fill()

    guard let image = symbolImage(
        named: "apple.logo", pointSize: 150, color: white) else {
        return
    }
    let scale = min(110 / image.size.width, 136 / image.size.height)
    let width = image.size.width * scale
    let height = image.size.height * scale
    image.draw(in: NSRect(
        x: 256 - width / 2,
        y: 256 - height / 2,
        width: width,
        height: height))
}

func drawBadge(_ badge: Badge, at center: NSPoint, diameter: CGFloat, color: NSColor) {
    let rect = NSRect(
        x: center.x - diameter / 2,
        y: center.y - diameter / 2,
        width: diameter,
        height: diameter)
    color.setFill()
    NSBezierPath(ovalIn: rect).fill()

    switch badge {
    case .apple:
        guard let image = symbolImage(
            named: "apple.logo", pointSize: diameter * 0.62, color: white) else {
            return
        }
        let scale = min(
            (diameter * 0.54) / image.size.width,
            (diameter * 0.54) / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        image.draw(in: NSRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height))
    case .letter(let text):
        let font = NSFont.systemFont(ofSize: diameter * 0.62, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: white,
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let stringSize = string.size()
        string.draw(at: NSPoint(
            x: center.x - stringSize.width / 2,
            y: center.y - stringSize.height / 2))
    }
}

func makeBitmap(_ iconName: String) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(pixelSize),
        pixelsHigh: Int(pixelSize),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0) else {
        fatalError("could not create bitmap for \(iconName)")
    }
    return rep
}

func image(from rep: NSBitmapImageRep) -> NSImage {
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.addRepresentation(rep)
    return image
}

// Draws the icon itself: the glyph plus whatever is drawn on top of it (the
// badge, or the Magic Trackpad plate). Coordinates stay in the 512pt canvas
// space; the transform scales them down to the rasterised size.
func drawBody(spec: Spec, color: NSColor, iconName: String) -> NSBitmapImageRep {
    let rep = makeBitmap(iconName)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    let scale = NSAffineTransform()
    scale.scale(by: pixelSize / canvas)
    scale.concat()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: canvas, height: canvas).fill(using: .copy)

    if spec.name == "magic_trackpad" {
        drawMagicTrackpad(color: color)
    } else {
        let hasBadge = spec.badge != nil
        let maxSide: CGFloat = hasBadge ? 390 : 440
        let centerY: CGFloat = hasBadge ? 280 : canvas / 2

        if let image = symbolImage(
            named: spec.symbol, pointSize: 400, color: color) {
            drawCentered(
                image,
                in: NSRect(x: 0, y: 0, width: canvas, height: canvas),
                maxSide: maxSide,
                centerY: centerY)
        } else {
            FileHandle.standardError.write(
                "missing SF Symbol: \(spec.symbol)\n".data(using: .utf8)!)
        }

        if let badge = spec.badge {
            drawBadge(
                badge,
                at: NSPoint(x: 400, y: 108),
                diameter: 140,
                color: color)
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// The body's alpha painted in one colour, used as the stencil for the rim.
func silhouette(of body: NSBitmapImageRep, color: NSColor) -> NSImage {
    let rep = makeBitmap("rim")

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    color.setFill()
    NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize).fill()
    image(from: body).draw(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        from: .zero,
        operation: .destinationIn,
        fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    return image(from: rep)
}

for spec in specs {
    let specVariants = spec.color.map { [IconVariant(suffix: "", color: $0)] } ?? variants
    for variant in specVariants {
        let iconName = "\(spec.name)\(variant.suffix)"
        let body = drawBody(spec: spec, color: variant.color, iconName: iconName)
        let rimMask = silhouette(of: body, color: rim)

        let rep = makeBitmap(iconName)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize).fill(using: .copy)

        // Dilating the silhouette keeps the rim square to the glyph at every
        // edge, which a stroked copy of the symbol cannot do.
        let steps = 48
        for step in 0..<steps {
            let angle = CGFloat(step) * 2 * .pi / CGFloat(steps)
            rimMask.draw(
                in: NSRect(
                    x: cos(angle) * rimRadius,
                    y: sin(angle) * rimRadius,
                    width: pixelSize,
                    height: pixelSize),
                from: .zero,
                operation: .sourceOver,
                fraction: 1)
        }
        image(from: body).draw(
            in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1)

        NSGraphicsContext.restoreGraphicsState()

        guard let data = rep.representation(using: .png, properties: [:]) else {
            fatalError("could not encode \(iconName)")
        }
        let outputPath = "\(outputDir)/\(iconName).png"
        try! data.write(to: URL(fileURLWithPath: outputPath))
        print("wrote \(outputPath)")
    }
}
