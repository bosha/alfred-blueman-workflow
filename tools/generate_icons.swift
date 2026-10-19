// Generates the workflow device icons from SF Symbols.
//
// Usage:
//   xcrun swift tools/generate_icons.swift
//
// The output is written to assets/icons/. Add or change entries in `specs`
// below and rerun the script to regenerate the PNGs.

import AppKit

let size: CGFloat = 512
let blue = NSColor(srgbRed: 0.039, green: 0.518, blue: 1.0, alpha: 1.0)
let white = NSColor.white

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

func drawMagicTrackpad() {
    let rect = NSRect(x: 76, y: 126, width: 360, height: 260)
    let path = NSBezierPath(roundedRect: rect, xRadius: 54, yRadius: 54)
    blue.setFill()
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

func drawBadge(_ badge: Badge, at center: NSPoint, diameter: CGFloat) {
    let rect = NSRect(
        x: center.x - diameter / 2,
        y: center.y - diameter / 2,
        width: diameter,
        height: diameter)
    blue.setFill()
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

for spec in specs {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0) else {
        fatalError("could not create bitmap for \(spec.name)")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill(using: .copy)

    if spec.name == "magic_trackpad" {
        drawMagicTrackpad()
    } else {
        let hasBadge = spec.badge != nil
        let maxSide: CGFloat = hasBadge ? 390 : 440
        let centerY: CGFloat = hasBadge ? 280 : 256

        if let image = symbolImage(named: spec.symbol, pointSize: 400, color: blue) {
            drawCentered(
                image,
                in: NSRect(x: 0, y: 0, width: size, height: size),
                maxSide: maxSide,
                centerY: centerY)
        } else {
            FileHandle.standardError.write(
                "missing SF Symbol: \(spec.symbol)\n".data(using: .utf8)!)
        }

        if let badge = spec.badge {
            drawBadge(badge, at: NSPoint(x: 400, y: 108), diameter: 140)
        }
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode \(spec.name)")
    }
    let outputPath = "\(outputDir)/\(spec.name).png"
    try! data.write(to: URL(fileURLWithPath: outputPath))
    print("wrote \(outputPath)")
}
