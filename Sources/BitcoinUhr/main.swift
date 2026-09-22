import AppKit
import SwiftUI

// `BitcoinUhr --snapshot <ordner> [HH:mm:ss ...]` rendert das Zifferblatt als PNG und beendet sich.
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
    let dir = URL(fileURLWithPath: args[i + 1])
    let times = args.count > i + 2 ? Array(args[(i + 2)...]) : ["10:09:30", "20:50:00", "21:00:00"]
    MainActor.assumeIsolated {
        // Echte Werte von mempool.space für die Standard-Komplikationen
        let mempool = MempoolData()
        mempool.configure(kinds: Set(ComplicationSlot.allCases.map(\.defaultKind)), interval: 3600)
        RunLoop.main.run(until: Date().addingTimeInterval(6))
        for t in times {
            let p = t.split(separator: ":").compactMap { Int($0) }
            let date = Calendar.current.date(bySettingHour: p[0], minute: p[1], second: p[2], of: Date())!
            let view = ZStack {
                DialView(date: date, d: 600)
                ForEach(ComplicationSlot.allCases) { slot in
                    if slot.defaultKind != .off {
                        ComplicationView(kind: slot.defaultKind, value: mempool.value(for: slot.defaultKind), d: 600)
                            .offset(slot.offset(d: 600))
                    }
                }
            }
                .frame(width: 672, height: 672)
                .background(Color.clear)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            if let img = renderer.nsImage, let tiff = img.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: dir.appendingPathComponent("uhr-\(t.replacingOccurrences(of: ":", with: "")).png"))
            }
        }
    }
    MainActor.assumeIsolated {
        let m = MempoolData()
        m.configure(kinds: [.blockHeight, .fees, .halving], interval: 3600)
        RunLoop.main.run(until: Date().addingTimeInterval(6))
        for k in [ComplicationKind.blockHeight, .fees, .halving] {
            let r = ImageRenderer(content: ComplicationInfoView(kind: k, mempool: m))
            r.scale = 2
            if let img = r.nsImage, let tiff = img.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: dir.appendingPathComponent("info-\(k.rawValue).png"))
            }
        }
        for h in [6, 21] {
            let r = ImageRenderer(content: ExplanationView(hour: h))
            r.scale = 2
            if let img = r.nsImage, let tiff = img.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: dir.appendingPathComponent("erklaerung-\(h).png"))
            }
        }
    }
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
