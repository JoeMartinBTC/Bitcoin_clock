import AppKit
import SwiftUI
import ServiceManagement

/// Einstellungen der Uhr, dauerhaft in UserDefaults.
final class ClockSettings: ObservableObject {
    enum Size: String, CaseIterable, Identifiable {
        case small, medium, large, xlarge
        var id: String { rawValue }
        var diameter: CGFloat {
            switch self {
            case .small: return 260
            case .medium: return 360
            case .large: return 480
            case .xlarge: return 640
            }
        }
        var title: String {
            switch self {
            case .small: return "Klein"
            case .medium: return "Mittel"
            case .large: return "Groß"
            case .xlarge: return "Sehr groß"
            }
        }
    }

    enum SecondHand: String, CaseIterable, Identifiable {
        case off, tick, soft, glide
        var id: String { rawValue }
        var title: String {
            switch self {
            case .off: return "Aus – keine Last"
            case .tick: return "Harter Sprung – minimale Last"
            case .soft: return "Weicher Sprung – geringe Last"
            case .glide: return "Gleitend – höchste Last"
            }
        }
    }

    enum Refresh: Int, CaseIterable, Identifiable {
        case one = 60, five = 300, fifteen = 900
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .one: return "Jede Minute"
            case .five: return "Alle 5 Minuten"
            case .fifteen: return "Alle 15 Minuten"
            }
        }
    }

    /// Fensterseite = Zifferblatt + Rand für den Schatten.
    static let windowFactor: CGFloat = 1.12

    var onChange: (() -> Void)?

    @Published var size: Size {
        didSet { UserDefaults.standard.set(size.rawValue, forKey: "size"); onChange?() }
    }
    @Published var floating: Bool {
        didSet { UserDefaults.standard.set(floating, forKey: "floating"); onChange?() }
    }
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled

    @Published var secondHand: SecondHand {
        didSet { UserDefaults.standard.set(secondHand.rawValue, forKey: "secondHand") }
    }
    @Published var showFormulas: Bool { didSet { UserDefaults.standard.set(showFormulas, forKey: "showFormulas") } }
    @Published var showWatermark: Bool { didSet { UserDefaults.standard.set(showWatermark, forKey: "showWatermark") } }
    @Published var showAmPm: Bool { didSet { UserDefaults.standard.set(showAmPm, forKey: "showAmPm") } }

    var onComplicationsChange: (() -> Void)?
    @Published var complications: [ComplicationSlot: ComplicationKind] {
        didSet {
            for (slot, kind) in complications { UserDefaults.standard.set(kind.rawValue, forKey: "complication.\(slot.rawValue)") }
            onComplicationsChange?()
        }
    }
    @Published var refresh: Refresh {
        didSet { UserDefaults.standard.set(refresh.rawValue, forKey: "refresh"); onComplicationsChange?() }
    }

    init() {
        let ud = UserDefaults.standard
        size = Size(rawValue: ud.string(forKey: "size") ?? "") ?? .medium
        floating = ud.bool(forKey: "floating")
        secondHand = SecondHand(rawValue: ud.string(forKey: "secondHand") ?? "") ?? .tick
        showFormulas = ud.object(forKey: "showFormulas") as? Bool ?? true
        showWatermark = ud.object(forKey: "showWatermark") as? Bool ?? true
        showAmPm = ud.object(forKey: "showAmPm") as? Bool ?? true
        refresh = Refresh(rawValue: ud.integer(forKey: "refresh")) ?? .five
        var c: [ComplicationSlot: ComplicationKind] = [:]
        for slot in ComplicationSlot.allCases {
            c[slot] = ComplicationKind(rawValue: ud.string(forKey: "complication.\(slot.rawValue)") ?? "") ?? slot.defaultKind
        }
        complications = c
    }

    /// Beim ersten Start trägt sich die App einmal als Anmeldeobjekt ein.
    func registerAutostartOnFirstRun() {
        guard !UserDefaults.standard.bool(forKey: "autostartInitialized") else { return }
        UserDefaults.standard.set(true, forKey: "autostartInitialized")
        setLaunchAtLogin(true)
    }

    func setLaunchAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        do {
            if on { try service.register() } else { try service.unregister() }
        } catch {
            NSLog("BitcoinUhr: Anmeldeobjekt \(on ? "register" : "unregister") fehlgeschlagen: \(error)")
        }
        launchAtLogin = service.status == .enabled
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = ClockSettings()
    private let mempool = MempoolData()
    private var window: NSWindow!
    private var dragMonitor: Any?
    private var explanationWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let side = settings.size.diameter * ClockSettings.windowFactor
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: side, height: side),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.contentView = NSHostingView(rootView: ClockView(settings: settings, mempool: mempool))

        if !window.setFrameUsingName("BitcoinUhr"), let screen = NSScreen.main {
            let vf = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: vf.maxX - side - 40, y: vf.maxY - side - 40))
        }
        window.setFrameAutosaveName("BitcoinUhr")

        settings.onChange = { [weak self] in self?.applyWindowSettings() }
        settings.onComplicationsChange = { [weak self] in self?.applyComplications() }
        applyComplications()
        applyWindowSettings()
        window.orderFrontRegardless()

        // Klick auf Formel-Schild oder Komplikation öffnet das Ziel, sonst verschiebt die linke Maustaste die Uhr.
        dragMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            if let label = self.plaqueHit(at: event.locationInWindow) {
                self.showExplanation(for: label)
            } else if let kind = self.complicationHit(at: event.locationInWindow) {
                NSWorkspace.shared.open(kind.url(height: self.mempool.height))
            } else {
                self.window.performDrag(with: event)
            }
            return nil
        }

        settings.registerAutostartOnFirstRun()
    }

    /// Beschriftung der aktiven Formel, wenn der Klick auf ihrem Schild liegt.
    private func plaqueHit(at point: NSPoint) -> Int? {
        let now = Date()
        guard settings.showFormulas, let p = DialView.activePosition(at: now) else { return nil }
        let size = window.contentView?.bounds.size ?? window.frame.size
        let d = min(size.width, size.height) / ClockSettings.windowFactor
        let o = DialView.plaqueOffset(position: p, d: d)
        let center = NSPoint(x: size.width / 2 + o.width, y: size.height / 2 - o.height)   // AppKit: y nach oben
        guard abs(point.x - center.x) < d * 0.13, abs(point.y - center.y) < d * 0.09 else { return nil }
        return DialView.label(position: p, pm: Calendar.current.component(.hour, from: now) >= 12)
    }

    /// Komplikation unter dem Klick, falls eine sichtbar ist.
    private func complicationHit(at point: NSPoint) -> ComplicationKind? {
        let size = window.contentView?.bounds.size ?? window.frame.size
        let d = min(size.width, size.height) / ClockSettings.windowFactor
        let half = ComplicationSlot.hitHalfSize
        for slot in ComplicationSlot.allCases {
            guard let kind = settings.complications[slot], kind != .off else { continue }
            let o = slot.offset(d: d)
            let c = NSPoint(x: size.width / 2 + o.width, y: size.height / 2 - o.height)
            if abs(point.x - c.x) < d * half.width, abs(point.y - c.y) < d * half.height { return kind }
        }
        return nil
    }

    private func applyComplications() {
        mempool.configure(kinds: Set(settings.complications.values), interval: TimeInterval(settings.refresh.rawValue))
    }

    private func showExplanation(for label: Int) {
        let host = NSHostingView(rootView: ExplanationView(hour: label))
        host.frame.size = host.fittingSize
        let w = explanationWindow ?? {
            let w = NSWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
            w.isReleasedWhenClosed = false
            w.backgroundColor = .white
            w.titlebarAppearsTransparent = true
            w.appearance = NSAppearance(named: .aqua)
            w.level = .floating
            explanationWindow = w
            return w
        }()
        w.title = label == 21 ? "Formel für ₿ (21)" : "Formel für \(label)"
        w.contentView = host
        w.setContentSize(host.fittingSize)
        if !w.isVisible {
            // neben die Uhr, auf die Seite mit mehr Platz
            let f = window.frame
            let vf = window.screen?.visibleFrame ?? f
            let x = f.minX - vf.minX > vf.maxX - f.maxX ? f.minX - w.frame.width - 12 : f.maxX + 12
            w.setFrameOrigin(NSPoint(x: x, y: f.midY - w.frame.height / 2))
        }
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    private func applyWindowSettings() {
        window.level = settings.floating
            ? .floating
            : NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

        let side = settings.size.diameter * ClockSettings.windowFactor
        let old = window.frame
        guard old.width != side else { return }
        let frame = NSRect(x: old.midX - side / 2, y: old.midY - side / 2, width: side, height: side)
        window.setFrame(frame, display: true, animate: true)
    }
}
