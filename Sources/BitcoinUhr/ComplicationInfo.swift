import AppKit
import SwiftUI

/// Erklärung einer Komplikation für Einsteiger, mit optionalem Weg zu mempool.space.
struct ComplicationInfoView: View {
    let kind: ComplicationKind
    @ObservedObject var mempool: MempoolData
    private let deep = InfoStyle.deep

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(kind.caption)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .tracking(2)
                .foregroundStyle(Palette.orange.opacity(0.8))
            Text(mempool.value(for: kind))
                .font(.system(size: 36, weight: .regular, design: .serif).monospacedDigit())
                .foregroundStyle(Palette.orange)
            Text(title)
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(deep)

            Rectangle().fill(Palette.orange.opacity(0.35)).frame(height: 1)

            ForEach(paragraphs, id: \.self) { p in
                Text(p)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(deep)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Rectangle().fill(Palette.orange.opacity(0.35)).frame(height: 1)

            HStack(alignment: .center) {
                Text("Daten: mempool.space,\nöffentlich und ohne Anmeldung.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(deep.opacity(0.7))
                    .fixedSize()
                Spacer(minLength: 16)
                Button {
                    NSWorkspace.shared.open(kind.url(height: mempool.height))
                } label: {
                    Text("Auf mempool.space ansehen →")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Palette.orange))
                        .fixedSize()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(30)
        .frame(width: InfoStyle.width, alignment: .leading)
        .background(Color.white)
    }

    private var title: String {
        switch kind {
        case .off: return ""
        case .blockHeight: return "Wie viele Blöcke die Bitcoin-Kette schon hat"
        case .fees: return "Was eine Überweisung gerade kostet"
        case .priceUSD, .priceEUR: return "Was ein ganzer Bitcoin gerade wert ist"
        case .mempool: return "Wie viele Überweisungen gerade warten"
        case .halving: return "Wann die Belohnung für neue Blöcke halbiert wird"
        case .difficulty: return "Wie schwer das Rätsel für neue Blöcke wird"
        }
    }

    private var paragraphs: [String] {
        let g = Self.grouped
        switch kind {
        case .off:
            return []
        case .blockHeight:
            var p = [
                "Bitcoin führt ein öffentliches Kassenbuch, das jeder einsehen und prüfen kann. Etwa alle zehn Minuten kommt eine neue Seite hinzu, ein sogenannter Block. Er enthält die Überweisungen, die seit dem letzten Block eingegangen sind.",
                "Jeder Block verweist fest auf den Block davor. So entsteht eine Kette. Wer einen alten Eintrag fälschen wollte, müsste diesen Block und alle danach neu berechnen, schneller als der Rest der Welt weiterschreibt. Das macht die Kette praktisch unveränderlich.",
                "Die Blockhöhe zählt, wie viele Blöcke seit dem allerersten Block vom 3. Januar 2009 hinzugekommen sind. Der erste Block hat die Nummer 0. Pro Tag kommen im Schnitt rund 144 Blöcke dazu.",
            ]
            if let h = mempool.height {
                p.append("Der nächste Block bekommt die Nummer \(g(h + 1)).")
            }
            return p
        case .fees:
            var p = [
                "Ein Bitcoin lässt sich in 100 Millionen kleinste Teile zerlegen, die Satoshi oder kurz sat heißen. Gebühren werden in sat bezahlt.",
                "Der Platz in jedem Block ist begrenzt. Wer eine Überweisung schickt, bietet deshalb eine Gebühr pro Datenmenge an, gemessen in sat pro virtuellem Byte (sat/vB). Die Rechner, die neue Blöcke bauen, nehmen die Überweisungen mit dem höchsten Gebot zuerst.",
                "Die drei Zahlen zeigen, wie viel man gerade bieten sollte: links für den nächsten Block (etwa 10 Minuten), in der Mitte für eine Bestätigung in etwa 30 Minuten, rechts in etwa einer Stunde.",
            ]
            if let f = mempool.fees {
                let sat = f.fast * 140
                var line = "Eine einfache Überweisung ist rund 140 vB groß. Bei der schnellsten Stufe kostet sie gerade etwa \(g(sat)) sat"
                if let eur = mempool.eur {
                    let euro = Double(sat) / 100_000_000 * Double(eur)
                    line += ", das sind ungefähr \(euro.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "de_DE")))) €"
                }
                p.append(line + ".")
            }
            return p
        case .priceUSD, .priceEUR:
            return [
                "Der Preis zeigt, was ein ganzer Bitcoin gerade kostet. Niemand legt ihn fest. Er entsteht an vielen Börsen weltweit aus Angebot und Nachfrage, mempool.space bildet daraus einen Mittelwert.",
                "Man muss keinen ganzen Bitcoin kaufen. Jeder Bitcoin lässt sich in 100 Millionen Satoshi teilen, man kann also auch für wenige Euro einen kleinen Teil besitzen.",
                "Der Preis schwankt stark, oft um mehrere Prozent an einem Tag. Die Menge ist dagegen fest begrenzt: Es wird nie mehr als 21 Millionen Bitcoin geben.",
            ]
        case .mempool:
            return [
                "Wer Bitcoin überweist, schickt die Überweisung zuerst an das Netzwerk. Bis sie in einem Block landet, wartet sie im Mempool, einer Art Wartezimmer. Jeder Rechner im Netzwerk führt seine eigene Kopie davon.",
                "Die Zahl zeigt, wie viele Überweisungen gerade dort warten. Beim Bau des nächsten Blocks kommen die mit der höchsten Gebühr zuerst dran.",
                "Ist das Wartezimmer voll, steigen die Gebühren, weil mehr Leute um denselben Platz bieten. Ist es fast leer, reicht schon eine sehr kleine Gebühr.",
            ]
        case .halving:
            var p = [
                "Wer einen neuen Block baut, bekommt dafür neu geschaffene Bitcoin als Belohnung. So kommen neue Bitcoin in Umlauf.",
                "Alle 210.000 Blöcke, also etwa alle vier Jahre, halbiert sich diese Belohnung. 2009 waren es 50 Bitcoin pro Block, dann 25, 12,5, 6,25 und seit 2024 sind es 3,125.",
                "Durch die ständige Halbierung nähert sich die Gesamtmenge immer mehr 21 Millionen Bitcoin, erreicht sie aber nie ganz. Das ist die eingebaute Knappheit von Bitcoin.",
            ]
            if let h = mempool.height {
                let next = (h / 210_000 + 1) * 210_000
                let left = next - h
                let days = Double(left) / 144
                p.append("Das nächste Halving kommt bei Block \(g(next)), also in \(g(left)) Blöcken. Bei zehn Minuten pro Block sind das rund \(g(Int(days.rounded()))) Tage.")
            }
            return p
        case .difficulty:
            var p = [
                "Um einen Block bauen zu dürfen, müssen Rechner weltweit ein Zahlenrätsel lösen. Das kostet Strom und Rechenzeit und schützt die Kette vor Fälschungen.",
                "Kommen mehr Rechner dazu, würden Blöcke schneller gefunden. Deshalb passt Bitcoin die Schwierigkeit alle 2016 Blöcke an, also etwa alle zwei Wochen. Ziel sind im Schnitt zehn Minuten pro Block, egal wie viel Rechenleistung gerade mitmacht.",
                "Die Prozentzahl ist die geschätzte Änderung bei der nächsten Anpassung: plus heißt schwerer, minus heißt leichter. Dahinter steht, wie viele Blöcke bis dahin noch fehlen.",
            ]
            if let d = mempool.difficulty {
                p.append("Bis zur nächsten Anpassung fehlen noch \(g(d.remaining)) Blöcke, rund \(g(Int((Double(d.remaining) / 144).rounded()))) Tage.")
            }
            return p
        }
    }

    private static func grouped(_ n: Int) -> String {
        n.formatted(.number.grouping(.automatic).locale(Locale(identifier: "de_DE")))
    }
}
