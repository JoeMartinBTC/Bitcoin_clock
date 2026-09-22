import SwiftUI

/// Erläuterung je Formel, angezeigt nach Klick auf das Schild.
enum HourExplanation {
    static let text: [Int: String] = [
        1: "ln ist der natürliche Logarithmus, die Umkehrung von eˣ. ln(3) beantwortet die Frage: Mit welcher Zahl muss man e potenzieren, um 3 zu erhalten? Antwort: 1,0986.",
        2: "Sieben Elftel von π. Weil π ungefähr 22/7 ist (Archimedes), ergibt 7π/11 fast genau 7 · 22 / (7 · 11) = 2.",
        3: "√2 ist die Diagonale eines Quadrats mit Seite 1. π/2 ist ein rechter Winkel im Bogenmaß, ein Viertel des Einheitskreises. Zusammen fast 3.",
        4: "∛5 ist die Zahl, die dreimal mit sich selbst multipliziert 5 ergibt: 1,7100. 7 geteilt durch diese Zahl ergibt 4,0936.",
        5: "Die Eulersche Zahl e hoch den goldenen Schnitt φ: 2,7183 hoch 1,6180 ergibt 5,0432.",
        6: "sec x ist 1 / cos x. Das Argument 20 steht im Bogenmaß: cos(20) = 0,4081, also sec²(20) = 1 / 0,4081² = 6,0049.",
        7: "Viermal √3. √3 ist die doppelte Höhe eines gleichseitigen Dreiecks mit Seite 1.",
        8: "Fünfmal der goldene Schnitt φ. Aufeinanderfolgende Fibonacci-Zahlen wachsen etwa um den Faktor φ: auf 5 folgt 8.",
        9: "Ein voller Kreis im Bogenmaß (2π = 6,2832) plus die Eulersche Zahl e (2,7183) ergibt 9,0015.",
        10: "Der Hyperbelsinus: sinh x = (eˣ − e⁻ˣ) / 2. Für x = 3 ergibt das (20,0855 − 0,0498) / 2 = 10,0179.",
        11: "π hoch drei ist 31,0063. Minus 20 bleibt 11,0063.",
        12: "csc x ist 1 / sin x, das Argument 16 steht im Bogenmaß: sin(16) = −0,2879, quadriert 0,0829, der Kehrwert ist 12,0644.",
        13: "π zum Quadrat (9,8696) plus π (3,1416) ergibt 13,0112.",
        14: "Zehnmal √2: die Diagonale eines Quadrats mit Seitenlänge 10.",
        15: "Die Eulersche Zahl mit sich selbst potenziert: e hoch e ergibt 15,1543.",
        16: "Der natürliche Logarithmus von zehn Millionen: ln 10⁷ = 7 · ln 10 = 7 · 2,3026 = 16,1181.",
        17: "e hoch 2√2, also e hoch 2,8284, ergibt 16,9188.",
        18: "Der goldene Schnitt hoch sechs. Potenzen von φ liegen immer nahe an den Lucas-Zahlen 2, 1, 3, 4, 7, 11, 18 … Hier ist es L(6) = 18.",
        19: "e hoch drei ist 20,0855. Minus 1 bleibt 19,0855.",
        20: "Ein berühmter Beinahe-Zufall: e^π − π liegt nur 0,0009 unter 20, ohne dass es dafür einen bekannten Grund gibt.",
        21: "Die Formel von Binet: Die n-te Fibonacci-Zahl ist ungefähr φⁿ / √5. Für n = 8 ergibt das F(8) = 21. Und 21 Millionen ist die Obergrenze aller Bitcoin.",
        22: "Siebenmal π. Das ist die Umkehrung der Näherung von Archimedes, π ≈ 22/7.",
        23: "Die Gelfondsche Konstante e^π. Sie ist nachweislich transzendent, also keine Lösung einer Gleichung mit ganzen Zahlen (Satz von Gelfond-Schneider).",
        24: "Die Gammafunktion verallgemeinert die Fakultät: Γ(n) = (n − 1)!. Also Γ(5) = 4! = 24.",
    ]
}

struct ExplanationView: View {
    let hour: Int
    private let deep = Color(red: 0.72, green: 0.38, blue: 0.0)   // dunkleres Orange für Fließtext, besser lesbar auf Weiß

    var body: some View {
        let f = HourFormula.all[hour]!
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                MathView(expr: f.expr, size: 38)
                    .fixedSize()
                Text("≈").font(.system(size: 30, weight: .light, design: .serif)).opacity(0.6)
                if hour == 21 {
                    Image(systemName: "bitcoinsign")
                        .font(.system(size: 34, weight: .semibold))
                        .rotationEffect(.degrees(14))
                } else {
                    Text("\(hour)").font(.system(size: 38, weight: .regular, design: .serif))
                }
            }
            .foregroundStyle(Palette.orange)

            Text(f.value, format: .number.precision(.fractionLength(6)))
                .font(.system(size: 17, design: .serif).monospacedDigit())
                .foregroundStyle(deep.opacity(0.75))

            Rectangle().fill(Palette.orange.opacity(0.35)).frame(height: 1)

            Text(HourExplanation.text[hour] ?? "")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(deep)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("φ = (1 + √5) / 2 ≈ 1,6180   ·   e ≈ 2,7183   ·   π ≈ 3,1416")
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Palette.orange.opacity(0.8))
        }
        .padding(30)
        .frame(width: 460, alignment: .leading)
        .background(Color.white)
    }
}
