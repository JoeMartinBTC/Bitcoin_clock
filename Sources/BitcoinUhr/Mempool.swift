import AppKit
import SwiftUI

/// Was eine Komplikation zeigt. Quelle: mempool.space (öffentliche API, ohne Schlüssel).
enum ComplicationKind: String, CaseIterable, Identifiable {
    case off, blockHeight, fees, priceUSD, priceEUR, mempool, halving, difficulty

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .off: return "Aus"
        case .blockHeight: return "Blockhöhe"
        case .fees: return "Gebühren (sat/vB)"
        case .priceUSD: return "Preis in USD"
        case .priceEUR: return "Preis in EUR"
        case .mempool: return "Unbestätigte Transaktionen"
        case .halving: return "Blöcke bis zum Halving"
        case .difficulty: return "Nächste Difficulty-Anpassung"
        }
    }

    var caption: String {
        switch self {
        case .off: return ""
        case .blockHeight: return "BLOCK"
        case .fees: return "SAT/VB"
        case .priceUSD: return "BTC · USD"
        case .priceEUR: return "BTC · EUR"
        case .mempool: return "MEMPOOL"
        case .halving: return "HALVING"
        case .difficulty: return "DIFFICULTY"
        }
    }

    /// Ziel beim Anklicken.
    func url(height: Int?) -> URL {
        switch self {
        case .blockHeight:
            return URL(string: height.map { "https://mempool.space/block/\($0)" } ?? "https://mempool.space/blocks")!
        case .difficulty, .halving: return URL(string: "https://mempool.space/mining")!
        case .priceUSD, .priceEUR: return URL(string: "https://mempool.space/graphs/mempool")!
        default: return URL(string: "https://mempool.space/")!
        }
    }
}

/// Die vier Plätze für Komplikationen auf dem Blatt.
enum ComplicationSlot: String, CaseIterable, Identifiable {
    case top, left, right, bottom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top: return "Oben"
        case .left: return "Links"
        case .right: return "Rechts"
        case .bottom: return "Unten"
        }
    }

    var defaultKind: ComplicationKind {
        switch self {
        case .top: return .off
        case .left: return .blockHeight
        case .right: return .fees
        case .bottom: return .priceUSD
        }
    }

    /// Mittelpunkt relativ zur Blattmitte (SwiftUI, y nach unten).
    func offset(d: CGFloat) -> CGSize {
        switch self {
        case .top: return CGSize(width: 0, height: -d * 0.095)
        case .left: return CGSize(width: -d * 0.18, height: 0)
        case .right: return CGSize(width: d * 0.18, height: 0)
        case .bottom: return CGSize(width: 0, height: d * 0.11)
        }
    }

    static let hitHalfSize = CGSize(width: 0.1, height: 0.035)   // relativ zu d
}

@MainActor
final class MempoolData: ObservableObject {
    @Published private(set) var height: Int?
    @Published private(set) var fees: (fast: Int, halfHour: Int, hour: Int)?
    @Published private(set) var usd: Int?
    @Published private(set) var eur: Int?
    @Published private(set) var txCount: Int?
    @Published private(set) var difficulty: (change: Double, remaining: Int)?

    private var timer: Timer?
    private var kinds: Set<ComplicationKind> = []
    private static let base = "https://mempool.space/api/"

    /// Abfragen nur für die gerade sichtbaren Komplikationen; ohne sichtbare kein Netzverkehr.
    func configure(kinds: Set<ComplicationKind>, interval: TimeInterval) {
        self.kinds = kinds.subtracting([.off])
        timer?.invalidate()
        timer = nil
        guard !self.kinds.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        Task { await refresh() }
    }

    func refresh() async {
        let k = kinds
        if k.contains(.blockHeight) || k.contains(.halving) {
            if let s = await Self.text("blocks/tip/height"), let h = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                height = h
            }
        }
        if k.contains(.fees), let j = await Self.json("v1/fees/recommended"),
           let f = j["fastestFee"] as? Int, let h = j["halfHourFee"] as? Int, let o = j["hourFee"] as? Int {
            fees = (f, h, o)
        }
        if k.contains(.priceUSD) || k.contains(.priceEUR), let j = await Self.json("v1/prices") {
            usd = j["USD"] as? Int
            eur = j["EUR"] as? Int
        }
        if k.contains(.mempool), let j = await Self.json("mempool") {
            txCount = j["count"] as? Int
        }
        if k.contains(.difficulty), let j = await Self.json("v1/difficulty-adjustment"),
           let c = j["difficultyChange"] as? Double, let r = j["remainingBlocks"] as? Int {
            difficulty = (c, r)
        }
    }

    func value(for kind: ComplicationKind) -> String {
        let dash = "–"
        switch kind {
        case .off: return ""
        case .blockHeight: return height.map(Self.grouped) ?? dash
        case .fees: return fees.map { "\($0.fast) · \($0.halfHour) · \($0.hour)" } ?? dash
        case .priceUSD: return usd.map { "$ " + Self.grouped($0) } ?? dash
        case .priceEUR: return eur.map { Self.grouped($0) + " €" } ?? dash
        case .mempool: return txCount.map { Self.grouped($0) + " tx" } ?? dash
        case .halving:
            guard let h = height else { return dash }
            let next = (h / 210_000 + 1) * 210_000
            return Self.grouped(next - h) + " Blöcke"
        case .difficulty:
            guard let d = difficulty else { return dash }
            let pct = d.change.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always()))
            return "\(pct) % · \(Self.grouped(d.remaining)) Bl."
        }
    }

    private static func grouped(_ n: Int) -> String {
        n.formatted(.number.grouping(.automatic).locale(Locale(identifier: "de_DE")))
    }

    private static func data(_ path: String) async -> Data? {
        guard let url = URL(string: base + path) else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("BitcoinUhr/1.0", forHTTPHeaderField: "User-Agent")
        guard let (d, r) = try? await URLSession.shared.data(for: req),
              (r as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return d
    }

    private static func text(_ path: String) async -> String? {
        await data(path).flatMap { String(data: $0, encoding: .utf8) }
    }

    private static func json(_ path: String) async -> [String: Any]? {
        await data(path).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    }
}

/// Eine Komplikation: nur Text in Orange, Beschriftung klein darüber.
struct ComplicationView: View {
    let kind: ComplicationKind
    let value: String
    let d: CGFloat

    var body: some View {
        VStack(spacing: d * 0.004) {
            Text(kind.caption)
                .font(.system(size: d * 0.016, weight: .medium, design: .serif))
                .tracking(d * 0.004)
                .opacity(0.6)
            Text(value)
                .font(.system(size: d * 0.028, weight: .regular, design: .serif).monospacedDigit())
        }
        .foregroundStyle(Palette.orange)
        .fixedSize()
    }
}
