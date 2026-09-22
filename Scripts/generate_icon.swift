// Erzeugt build/AppIcon.icns: dunkles Zifferblatt, orange Lünette, ₿.
import AppKit

let orange = NSColor(red: 247 / 255, green: 147 / 255, blue: 26 / 255, alpha: 1)
let gold = NSColor(red: 1.0, green: 0.80, blue: 0.48, alpha: 1)

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset = s * 0.08
    let disc = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    NSGradient(colors: [NSColor(white: 0.16, alpha: 1), NSColor(white: 0.03, alpha: 1)])!
        .draw(in: NSBezierPath(ovalIn: disc), relativeCenterPosition: NSPoint(x: 0, y: 0.2))

    let ring = NSBezierPath(ovalIn: disc.insetBy(dx: s * 0.018, dy: s * 0.018))
    ring.lineWidth = s * 0.036
    NSGradient(colors: [gold, orange, NSColor(red: 0.62, green: 0.32, blue: 0.03, alpha: 1), orange, gold])!
        .draw(in: ring.bezierPathByStrokingPath(), angle: 45)

    let cfg = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .bold)
        .applying(.init(paletteColors: [orange]))
    if let sym = NSImage(systemSymbolName: "bitcoinsign", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let sz = sym.size
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: s / 2, y: s / 2)
        ctx.rotate(by: -14 * .pi / 180)
        sym.draw(in: NSRect(x: -sz.width / 2, y: -sz.height / 2, width: sz.width, height: sz.height))
        ctx.restoreGState()
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

extension NSBezierPath {
    func bezierPathByStrokingPath() -> NSBezierPath {
        let cg = self.cgPath.copy(strokingWithWidth: lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: 10)
        return NSBezierPath(cgPath: cg)
    }
}

let iconset = URL(fileURLWithPath: "build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "build/AppIcon.icns"]
try! p.run()
p.waitUntilExit()
print(p.terminationStatus == 0 ? "build/AppIcon.icns" : "iconutil fehlgeschlagen")
