import AppKit
import QuartzCore
import SwiftUI

/// Zeiger als Core-Animation-Ebenen: einmal gerastert, gedreht vom Render-Server.
/// Die App rechnet dafür nicht pro Sekunde; neu ausgerichtet wird nur bei Aufwachen,
/// Uhrzeitänderung und alle zehn Minuten.
struct HandsLayer: NSViewRepresentable {
    let d: CGFloat
    let secondHand: ClockSettings.SecondHand

    func makeNSView(context: Context) -> HandsNSView { HandsNSView() }

    func updateNSView(_ view: HandsNSView, context: Context) {
        view.secondHand = secondHand
        view.configure(d: d)
    }
}

final class HandsNSView: NSView {
    private let hourLayer = CALayer()
    private let minuteLayer = CALayer()
    private let secondLayer = CALayer()
    private var d: CGFloat = 0
    private var scale: CGFloat = 0
    private var timer: Timer?
    var secondHand: ClockSettings.SecondHand = .tick {
        didSet { if secondHand != oldValue { resync() } }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        for l in [hourLayer, minuteLayer, secondLayer] {
            l.contentsGravity = .resizeAspect
            layer?.addSublayer(l)
        }
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(resync), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resync), name: .NSSystemClockDidChange, object: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in self?.resync() }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    /// Klicks gehen durch die Zeiger hindurch an die Uhr.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        configure(d: d, force: true)
    }

    func configure(d: CGFloat, force: Bool = false) {
        let s = window?.backingScaleFactor ?? 2
        guard d > 0, force || d != self.d || s != scale else { return }
        self.d = d
        scale = s
        let images = MainActor.assumeIsolated { HandImages.render(d: d, scale: s) }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (l, img) in zip([hourLayer, minuteLayer, secondLayer], images) {
            l.contents = img
            l.contentsScale = s
            l.bounds = CGRect(x: 0, y: 0, width: d, height: d)
            l.position = CGPoint(x: bounds.midX, y: bounds.midY)
        }
        CATransaction.commit()
        resync()
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for l in [hourLayer, minuteLayer, secondLayer] { l.position = CGPoint(x: bounds.midX, y: bounds.midY) }
        CATransaction.commit()
    }

    /// Setzt alle drei Drehungen passend zur aktuellen Uhrzeit neu auf.
    @objc func resync() {
        let now = Date()
        let c = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
        let sec = Double(c.second ?? 0) + Double(c.nanosecond ?? 0) / 1e9
        let secOfHour = Double(c.minute ?? 0) * 60 + sec
        let secOf12h = Double((c.hour ?? 0) % 12) * 3600 + secOfHour

        // Schrittweise statt stufenlos: der Render-Server zeichnet nur zu den Sprüngen neu.
        step(hourLayer, period: 12 * 3600, steps: 720, elapsed: secOf12h)     // jede Minute 0,5°
        step(minuteLayer, period: 3600, steps: 360, elapsed: secOfHour)       // alle 10 s 1°
        secondLayer.isHidden = secondHand == .off
        secondLayer.removeAllAnimations()
        switch secondHand {
        case .off: break
        case .tick: step(secondLayer, period: 60, steps: 60, elapsed: sec)   // jede Sekunde 6°, harter Sprung
        case .soft: softTick(secondLayer, elapsed: sec)
        case .glide: glide(secondLayer, elapsed: sec)
        }
    }

    /// Drehung im Uhrzeigersinn in gleichen Sprüngen, phasengenau zur Uhrzeit.
    private func step(_ l: CALayer, period: Double, steps: Int, elapsed: Double) {
        let a = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        a.calculationMode = .discrete
        a.values = (0...steps).map { -Double($0) / Double(steps) * 2 * .pi }
        a.keyTimes = (0...steps).map { NSNumber(value: Double($0) / Double(steps)) }
        a.duration = period
        a.repeatCount = .infinity
        a.beginTime = l.convertTime(CACurrentMediaTime(), from: nil) - elapsed
        a.isRemovedOnCompletion = false
        l.add(a, forKey: "step")
    }

}

extension HandsNSView {
    /// Steht 0,82 s, springt dann in 0,18 s weich zur nächsten Sekunde.
    fileprivate func softTick(_ l: CALayer, elapsed: Double) {
        var values: [Double] = []
        var times: [NSNumber] = []
        var timing: [CAMediaTimingFunction] = []
        for i in 0..<60 {
            let a = -Double(i) / 60 * 2 * .pi
            values += [a, a]
            times += [NSNumber(value: Double(i) / 60), NSNumber(value: (Double(i) + 0.82) / 60)]
            timing += [CAMediaTimingFunction(name: .linear), CAMediaTimingFunction(name: .easeOut)]
        }
        values.append(-2 * .pi)
        times.append(1)
        let k = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        k.values = values
        k.keyTimes = times
        k.timingFunctions = timing
        k.duration = 60
        k.repeatCount = .infinity
        k.beginTime = l.convertTime(CACurrentMediaTime(), from: nil) - elapsed
        k.isRemovedOnCompletion = false
        l.add(k, forKey: "step")
    }

    /// Stufenlos gleitend wie ein mechanisches Werk.
    fileprivate func glide(_ l: CALayer, elapsed: Double) {
        let a = CABasicAnimation(keyPath: "transform.rotation.z")
        a.fromValue = 0
        a.toValue = -2 * Double.pi
        a.duration = 60
        a.repeatCount = .infinity
        a.beginTime = l.convertTime(CACurrentMediaTime(), from: nil) - elapsed
        a.isRemovedOnCompletion = false
        l.add(a, forKey: "step")
    }
}

/// Rastert die drei Zeiger (mit Schatten) aus den SwiftUI-Formen in 12-Uhr-Stellung.
enum HandImages {
    @MainActor
    static func render(d: CGFloat, scale: CGFloat) -> [CGImage?] {
        DialView.handViews(d: d).map { view in
            let r = ImageRenderer(content: view.frame(width: d, height: d))
            r.scale = scale
            return r.cgImage
        }
    }
}
