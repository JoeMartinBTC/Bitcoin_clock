import SwiftUI

enum Palette {
    static let orange = Color(red: 247 / 255, green: 147 / 255, blue: 26 / 255)   // Bitcoin-Orange #F7931A
    static let gold = Color(red: 1.0, green: 0.80, blue: 0.48)
    static let ember = Color(red: 0.62, green: 0.32, blue: 0.03)
    static let ivory = Color(red: 0.94, green: 0.90, blue: 0.83)
}

struct ClockView: View {
    @ObservedObject var settings: ClockSettings
    @ObservedObject var mempool: MempoolData

    private func dial(_ date: Date, _ d: CGFloat) -> DialView {
        DialView(date: date, d: d, showWatermark: settings.showWatermark,
                 showFormulas: settings.showFormulas, showAmPm: settings.showAmPm)
    }

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height) / ClockSettings.windowFactor
            // Nur die Zeiger laufen schnell; Blatt und Beschriftung ändern sich selten.
            ZStack {
                dial(.now, d).staticFace.drawingGroup()
                // Beschriftung und Schilder ändern sich nur zur vollen Minute.
                TimelineView(.everyMinute) { ctx in
                    dial(ctx.date, d).marks
                }
                complications(d)
                // Zeiger drehen sich per Core Animation, ohne Rechenlast in der App.
                HandsLayer(d: d, secondHand: settings.secondHand).frame(width: d, height: d)
                DialView.centerCap(d: d)
                TimelineView(.everyMinute) { ctx in
                    dial(ctx.date, d).plaques
                }
                dial(.now, d).glass
            }
            .frame(width: d, height: d)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .contextMenu { menu }
    }

    private func complications(_ d: CGFloat) -> some View {
        ZStack {
            ForEach(ComplicationSlot.allCases) { slot in
                if let kind = settings.complications[slot], kind != .off {
                    ComplicationView(kind: kind, value: mempool.value(for: kind), d: d)
                        .offset(slot.offset(d: d))
                }
            }
        }
        .frame(width: d, height: d)
        .allowsHitTesting(false)
    }

    private func check<T: Equatable>(_ title: String, _ value: T, _ current: Binding<T>) -> some View {
        Toggle(title, isOn: Binding(get: { current.wrappedValue == value },
                                    set: { if $0 { current.wrappedValue = value } }))
    }

    @ViewBuilder private var menu: some View {
        Menu("Größe") {
            ForEach(ClockSettings.Size.allCases) { check($0.title, $0, $settings.size) }
        }
        Menu("Sekundenzeiger (CPU-Last)") {
            ForEach(ClockSettings.SecondHand.allCases) { check($0.title, $0, $settings.secondHand) }
        }
        Menu("Anzeige") {
            Toggle("Formeln auf den 5-Minuten-Strichen", isOn: $settings.showFormulas)
            Toggle("₿-Wasserzeichen", isOn: $settings.showWatermark)
            Toggle("AM/PM", isOn: $settings.showAmPm)
        }
        Menu("Komplikationen (mempool.space)") {
            ForEach(ComplicationSlot.allCases) { slot in
                Menu(slot.title) {
                    ForEach(ComplicationKind.allCases) { kind in
                        Toggle(kind.menuTitle, isOn: Binding(
                            get: { settings.complications[slot] == kind },
                            set: { if $0 { settings.complications[slot] = kind } }))
                    }
                }
            }
            Divider()
            Menu("Aktualisierung") {
                ForEach(ClockSettings.Refresh.allCases) { check($0.title, $0, $settings.refresh) }
            }
            Button("Jetzt aktualisieren") { Task { await mempool.refresh() } }
        }
        Divider()
        Toggle("Über allen Fenstern", isOn: $settings.floating)
        Toggle("Beim Anmelden starten", isOn: Binding(
            get: { settings.launchAtLogin },
            set: { settings.setLaunchAtLogin($0) }
        ))
        Divider()
        Button("Bitcoin-Uhr beenden") { NSApp.terminate(nil) }
    }
}

struct DialView: View {
    let date: Date
    let d: CGFloat
    var showWatermark = true
    var showFormulas = true
    var showAmPm = true

    private var active: Int? { showFormulas ? Self.activePosition(at: date) : nil }

    private var time: (hour: Double, minute: Double, second: Double) {
        let c = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let s = Double(c.second ?? 0)
        let m = Double(c.minute ?? 0) + s / 60
        let h = Double(c.hour ?? 0) + m / 60
        return (h, m, s)
    }

    var isPM: Bool { Calendar.current.component(.hour, from: date) >= 12 }

    /// Beschriftung an Position p (1…12): vormittags 1–11, nachmittags 13–23, oben immer 12.
    static func label(position p: Int, pm: Bool) -> Int { p == 12 ? 12 : (pm ? p + 12 : p) }

    /// Position, auf deren 5-Minuten-Strich der Minutenzeiger steht (die ganze Minute lang), sonst nil.
    static func activePosition(at date: Date) -> Int? {
        let m = Calendar.current.component(.minute, from: date)
        guard m % 5 == 0 else { return nil }
        return m == 0 ? 12 : m / 5
    }

    static let plaqueRadius: CGFloat = 0.30
    /// Mittelpunkt des Schilds relativ zur Blattmitte (SwiftUI-Koordinaten, y nach unten).
    static func plaqueOffset(position p: Int, d: CGFloat) -> CGSize {
        let a = Double(p) / 12 * 2 * .pi
        return CGSize(width: d * plaqueRadius * sin(a), height: -d * plaqueRadius * cos(a))
    }

    var body: some View {
        ZStack { staticFace; marks; handsLayer; plaques; glass }
            .frame(width: d, height: d)
    }

    // MARK: Ebenen

    var staticFace: some View {
        ZStack {
            caseAndFace
            if showWatermark { watermark }
            minuteTrack
            brand
        }
        .frame(width: d, height: d)
    }

    var marks: some View {
        let active = self.active
        let pm = isPM
        return ZStack {
            hourMarkers(active: active)
            ForEach(1...12, id: \.self) { p in
                HourLabel(position: p, label: Self.label(position: p, pm: pm), active: active, d: d)
            }
            if showAmPm { amPm(pm) }
        }
        .frame(width: d, height: d)
    }

    var handsLayer: some View {
        let t = time
        return hands(t)
    }

    var plaques: some View {
        let active = self.active
        let pm = isPM
        return ZStack {
            ForEach(1...12, id: \.self) { p in
                FormulaPlaque(position: p, label: Self.label(position: p, pm: pm), active: active, d: d)
            }
        }
        .frame(width: d, height: d)
    }

    // MARK: Gehäuse und Blatt

    private var caseAndFace: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(white: 0.14), Color(white: 0.075), Color(white: 0.035)],
                    center: .init(x: 0.5, y: 0.42), startRadius: 0, endRadius: d * 0.55))
                .shadow(color: .black.opacity(0.6), radius: d * 0.035, y: d * 0.018)
            // Sonnenschliff
            Circle()
                .fill(AngularGradient(
                    colors: (0..<120).map { $0 % 2 == 0 ? Color.white.opacity(0.022) : .clear },
                    center: .center))
                .padding(d * 0.02)
            // Lünette in gebürstetem Orange-Gold
            Circle()
                .strokeBorder(AngularGradient(
                    colors: [Palette.gold, Palette.orange, Palette.ember, Palette.orange,
                             Palette.gold, Palette.orange, Palette.ember, Palette.orange, Palette.gold],
                    center: .center), lineWidth: d * 0.018)
            Circle()
                .strokeBorder(Color.black.opacity(0.7), lineWidth: d * 0.004)
                .padding(d * 0.018)
            Circle()
                .strokeBorder(Palette.orange.opacity(0.28), lineWidth: 0.7)
                .padding(d * 0.078)
        }
    }

    private var watermark: some View {
        Image(systemName: "bitcoinsign")
            .font(.system(size: d * 0.46, weight: .heavy))
            .foregroundStyle(
                LinearGradient(colors: [Palette.orange.opacity(0.10), Palette.orange.opacity(0.035)],
                               startPoint: .top, endPoint: .bottom))
            .rotationEffect(.degrees(14))
            .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: d * 0.003)
    }

    private var minuteTrack: some View {
        ForEach(0..<60, id: \.self) { i in
            let major = i % 5 == 0
            Capsule()
                .fill(Palette.ivory.opacity(major ? 0.5 : 0.2))
                .frame(width: major ? d * 0.005 : d * 0.0028, height: major ? d * 0.024 : d * 0.014)
                .offset(y: -d * 0.445 + (major ? d * 0.005 : 0))
                .rotationEffect(.degrees(Double(i) * 6))
        }
    }

    private func hourMarkers(active: Int?) -> some View {
        ForEach(1...12, id: \.self) { p in
            let isActive = p == active
            RoundedRectangle(cornerRadius: d * 0.002)
                .fill(LinearGradient(colors: [Palette.gold, Palette.orange], startPoint: .top, endPoint: .bottom))
                .frame(width: d * (p % 3 == 0 ? 0.009 : 0.006), height: d * (p % 3 == 0 ? 0.045 : 0.03))
                .shadow(color: Palette.orange.opacity(isActive ? 0.9 : 0), radius: d * 0.012)
                .opacity(isActive ? 1 : 0.8)
                .offset(y: -d * 0.395)
                .rotationEffect(.degrees(Double(p) * 30))
                .animation(.easeInOut(duration: 0.8), value: isActive)
        }
    }

    private func amPm(_ pm: Bool) -> some View {
        HStack(spacing: d * 0.035) {
            Text("AM").opacity(pm ? 0.22 : 1)
            Text("PM").opacity(pm ? 1 : 0.22)
        }
        .font(.system(size: d * 0.028, weight: .medium, design: .serif))
        .tracking(d * 0.008)
        .foregroundStyle(Palette.orange)
        .offset(y: d * 0.2)
    }

    private var brand: some View {
        VStack(spacing: d * 0.008) {
            Text("BITCOIN")
                .font(.system(size: d * 0.03, weight: .medium, design: .serif))
                .tracking(d * 0.012)
                .foregroundStyle(Palette.orange.opacity(0.8))
            Text("21 000 000")
                .font(.system(size: d * 0.017, weight: .regular, design: .serif))
                .tracking(d * 0.004)
                .foregroundStyle(Palette.ivory.opacity(0.35))
        }
        .offset(y: -d * 0.175)
    }

    // MARK: Zeiger

    /// Stunden-, Minuten- und Sekundenzeiger in 12-Uhr-Stellung, je im Rahmen d × d.
    static func handViews(d: CGFloat) -> [AnyView] {
        let shadow = Color.black.opacity(0.55)
        return [
            AnyView(Hand(length: d * 0.24, tail: d * 0.045, base: d * 0.028, tip: d * 0.012)
                .fill(LinearGradient(colors: [Palette.gold, Palette.orange, Palette.ember],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: shadow, radius: d * 0.008, x: d * 0.003, y: d * 0.008)),
            AnyView(Hand(length: d * 0.36, tail: d * 0.05, base: d * 0.018, tip: d * 0.006)
                .fill(LinearGradient(colors: [Palette.ivory, Color(white: 0.72)],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: shadow, radius: d * 0.009, x: d * 0.004, y: d * 0.01)),
            AnyView(ZStack {
                Hand(length: d * 0.42, tail: d * 0.09, base: d * 0.006, tip: d * 0.0028)
                    .fill(Palette.orange)
                Circle()
                    .fill(Palette.orange)
                    .frame(width: d * 0.026, height: d * 0.026)
                    .offset(y: d * 0.075)
            }
            .shadow(color: shadow, radius: d * 0.006, x: d * 0.004, y: d * 0.012)),
        ]
    }

    static func centerCap(d: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.gold, Palette.orange, Palette.ember],
                                     center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: d * 0.025))
                .frame(width: d * 0.036, height: d * 0.036)
            Circle().fill(Color(white: 0.08)).frame(width: d * 0.011, height: d * 0.011)
        }
        .allowsHitTesting(false)
    }

    /// Zeiger als SwiftUI-Ansicht, nur für den Schnappschuss-Modus.
    private func hands(_ t: (hour: Double, minute: Double, second: Double)) -> some View {
        let v = Self.handViews(d: d)
        let angles = [t.hour / 12 * 360, t.hour * 360, t.hour * 3600 * 6]
        return ZStack {
            ForEach(0..<3, id: \.self) { i in
                v[i].frame(width: d, height: d).rotationEffect(.degrees(angles[i]))
            }
            Self.centerCap(d: d)
        }
        .frame(width: d, height: d)
    }

    var glass: some View {
        Circle()
            .fill(LinearGradient(colors: [.white.opacity(0.07), .white.opacity(0.0)],
                                 startPoint: .topLeading, endPoint: .center))
            .padding(d * 0.02)
            .allowsHitTesting(false)
    }
}

/// Zahl an einer Stundenposition; weicht dem Schild, wenn dort eine Formel steht.
struct HourLabel: View {
    let position: Int
    let label: Int
    let active: Int?
    let d: CGFloat

    private var isActive: Bool { position == active }
    private var isNeighbor: Bool {
        guard let active else { return false }
        let diff = abs(position - active)
        return diff == 1 || diff == 11
    }

    var body: some View {
        let angle = Double(position) / 12 * 2 * .pi
        let r = d * 0.335
        number
            .opacity(isActive ? 0 : (isNeighbor ? (label == 21 ? 0.5 : 0.25) : 1))
            .scaleEffect(isActive ? 1.2 : 1)
            .offset(x: r * sin(angle), y: -r * cos(angle))
            .animation(.easeInOut(duration: 0.8), value: isActive)
            .animation(.easeInOut(duration: 0.8), value: isNeighbor)
            .animation(.easeInOut(duration: 1.2), value: label)
    }

    @ViewBuilder private var number: some View {
        let major = position % 3 == 0
        if label == 21 {
            Image(systemName: "bitcoinsign")
                .font(.system(size: d * 0.078, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [Palette.gold, Palette.orange],
                                                startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(14))
                .shadow(color: Palette.orange.opacity(0.55), radius: d * 0.012)
        } else {
            Text("\(label)")
                .font(.system(size: d * (major ? 0.078 : 0.062), weight: major ? .regular : .light, design: .serif))
                .foregroundStyle(Palette.orange.opacity(major ? 1 : 0.88))
        }
    }
}

/// Die aktive Formel auf einem Schild über den Zeigern, darunter ihr Wert. Klick öffnet die Erläuterung.
struct FormulaPlaque: View {
    let position: Int
    let label: Int
    let active: Int?
    let d: CGFloat

    var body: some View {
        let isActive = position == active
        if let f = HourFormula.all[label] {
            VStack(spacing: d * 0.008) {
                MathView(expr: f.expr, size: d * 0.054)
                    .foregroundStyle(Palette.orange)
                    .fixedSize()
                HStack(spacing: d * 0.008) {
                    Text(f.value, format: .number.precision(.fractionLength(4)))
                        .foregroundStyle(Palette.ivory.opacity(0.55))
                    if label == 21 {
                        Image(systemName: "bitcoinsign")
                            .foregroundStyle(Palette.orange)
                            .rotationEffect(.degrees(14))
                    }
                }
                .font(.system(size: d * 0.022, design: .serif).monospacedDigit())
            }
            .padding(.horizontal, d * 0.02)
            .padding(.vertical, d * 0.014)
            .background(
                RoundedRectangle(cornerRadius: d * 0.02, style: .continuous)
                    .fill(Color(white: 0.055).opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: d * 0.02, style: .continuous)
                            .strokeBorder(LinearGradient(colors: [Palette.gold.opacity(0.8), Palette.ember.opacity(0.6)],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: max(0.7, d * 0.002))
                    )
                    .shadow(color: .black.opacity(0.6), radius: d * 0.015, y: d * 0.006)
                    .shadow(color: Palette.orange.opacity(0.18), radius: d * 0.02)
            )
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.85)
            .offset(DialView.plaqueOffset(position: position, d: d))
            .animation(.easeInOut(duration: 0.8), value: isActive)
        }
    }
}

/// Spitz zulaufender Zeiger, gezeichnet um die Mitte des Rahmens.
struct Hand: Shape {
    let length: CGFloat
    let tail: CGFloat
    let base: CGFloat
    let tip: CGFloat

    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        var p = Path()
        p.move(to: CGPoint(x: c.x - base / 2, y: c.y + tail))
        p.addLine(to: CGPoint(x: c.x - tip / 2, y: c.y - length))
        p.addQuadCurve(to: CGPoint(x: c.x + tip / 2, y: c.y - length),
                       control: CGPoint(x: c.x, y: c.y - length - tip))
        p.addLine(to: CGPoint(x: c.x + base / 2, y: c.y + tail))
        p.closeSubpath()
        return p
    }
}
