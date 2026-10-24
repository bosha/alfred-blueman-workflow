// Generates the workflow icon (icon.png) and the "Bluetooth is off" row icon
// (assets/off.png).
//
// Usage:
//   xcrun swift tools/generate_app_icon.swift [--style dot|rune|plate] [--output DIR]
//
// The icon carries its own plate: Alfred draws it as-is on light and dark
// backgrounds (Workflows list, Gallery, notifications) and has no dark variant.
// Colours are the same ones tools/generate_icons.swift uses for the device
// icons, so the two sets stay in sync.

import AppKit

let canvas: CGFloat = 512
// macOS app icons sit on a small margin and use a ~22% corner radius.
let inset: CGFloat = 16
let plateRect = NSRect(
    x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
let plateRadius = plateRect.width * 0.2237

let surfaceTop = NSColor(srgbRed: 0.180, green: 0.180, blue: 0.190, alpha: 1)
let surfaceBottom = NSColor(srgbRed: 0.098, green: 0.098, blue: 0.106, alpha: 1)
// Same green/gray as the connected and disconnected device icons.
let green = NSColor(srgbRed: 0.204, green: 0.780, blue: 0.349, alpha: 1)
let greenDeep = NSColor(srgbRed: 0.157, green: 0.655, blue: 0.271, alpha: 1)
let gray = NSColor(srgbRed: 0.557, green: 0.557, blue: 0.576, alpha: 1)
let white = NSColor.white

// The Bluetooth rune as one continuous stroke: two crossing diagonals and the
// spine between the apexes. Coordinates are in a unit box, y up.
let runePoints: [(CGFloat, CGFloat)] = [
    (0.22, 0.71), (0.78, 0.29), (0.50, 0.05),
    (0.50, 0.95), (0.78, 0.71), (0.22, 0.29),
]
// Height and stroke weight as a fraction of the plate width.
let runeHeightRatio: CGFloat = 0.58
let runeStrokeRatio: CGFloat = 0.072
let dotDiameterRatio: CGFloat = 0.145

// How the rune is coloured. `dot` is the default look: a white rune with a
// green status dot, echoing the badges on the device icons.
enum Style: String {
    case dot
    case rune
    case plate
}

func parseStyle() -> Style {
    let args = CommandLine.arguments
    guard let index = args.firstIndex(of: "--style"), index + 1 < args.count,
          let style = Style(rawValue: args[index + 1]) else {
        return .dot
    }
    return style
}

func parseOutputDir() -> String {
    let args = CommandLine.arguments
    if let index = args.firstIndex(of: "--output"), index + 1 < args.count {
        return args[index + 1]
    }
    let cwd = FileManager.default.currentDirectoryPath
    let scriptPath = CommandLine.arguments[0].hasPrefix("/")
        ? CommandLine.arguments[0]
        : "\(cwd)/\(CommandLine.arguments[0])"
    let scriptURL = URL(fileURLWithPath: scriptPath).standardizedFileURL
    return scriptURL.deletingLastPathComponent().deletingLastPathComponent().path
}

func drawPlate(_ top: NSColor, _ bottom: NSColor) {
    let path = NSBezierPath(
        roundedRect: plateRect, xRadius: plateRadius, yRadius: plateRadius)
    NSGradient(starting: top, ending: bottom)?.draw(in: path, angle: -90)
}

func drawRune(color: NSColor) {
    let height = plateRect.width * runeHeightRatio
    let unit = height / 0.9  // the rune uses 90% of the unit box
    let center = NSPoint(x: canvas / 2, y: canvas / 2)

    let path = NSBezierPath()
    path.lineWidth = plateRect.width * runeStrokeRatio
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    for (index, point) in runePoints.enumerated() {
        let position = NSPoint(
            x: center.x + (point.0 - 0.5) * unit,
            y: center.y + (point.1 - 0.5) * unit)
        if index == 0 {
            path.move(to: position)
        } else {
            path.line(to: position)
        }
    }
    color.setStroke()
    path.stroke()
}

// Status dot in the bottom-right corner, clear of the rune's lower arm.
func drawDot(color: NSColor) {
    let diameter = plateRect.width * dotDiameterRatio
    let center = NSPoint(
        x: plateRect.minX + plateRect.width * 0.815,
        y: plateRect.minY + plateRect.height * 0.185)
    color.setFill()
    NSBezierPath(ovalIn: NSRect(
        x: center.x - diameter / 2,
        y: center.y - diameter / 2,
        width: diameter,
        height: diameter)).fill()
}

func render(style: Style, runeColor: NSColor, dotColor: NSColor?) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas),
        pixelsHigh: Int(canvas),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: canvas, height: canvas).fill(using: .copy)

    switch style {
    case .plate:
        drawPlate(green, greenDeep)
    case .dot, .rune:
        drawPlate(surfaceTop, surfaceBottom)
    }
    drawRune(color: runeColor)
    if let dotColor = dotColor {
        drawDot(color: dotColor)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, to path: String) {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode \(path)")
    }
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

let style = parseStyle()
let outputDir = parseOutputDir()

switch style {
case .dot:
    // Workflow icon: white rune, green status dot.
    write(render(style: .dot, runeColor: white, dotColor: green),
          to: "\(outputDir)/icon.png")
    // "Bluetooth is off" row: the same icon, muted.
    write(render(style: .dot, runeColor: gray, dotColor: gray),
          to: "\(outputDir)/assets/off.png")
case .rune:
    write(render(style: .rune, runeColor: green, dotColor: nil),
          to: "\(outputDir)/icon.png")
case .plate:
    write(render(style: .plate, runeColor: white, dotColor: nil),
          to: "\(outputDir)/icon.png")
}
