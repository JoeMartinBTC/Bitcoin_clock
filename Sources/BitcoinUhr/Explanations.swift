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

/// Die Zeichen und Begriffe, die in den Formeln vorkommen, in einfacher Sprache.
enum Glossary: CaseIterable {
    case pi, e, phi, power, sqrt, cbrt, ln, sinCos, sec, csc, radian, sinh, gamma, fibonacci, lucas

    var symbol: String {
        switch self {
        case .pi: return "π"
        case .e: return "e"
        case .phi: return "φ"
        case .power: return "aⁿ"
        case .sqrt: return "√"
        case .cbrt: return "∛"
        case .ln: return "ln"
        case .sinCos: return "sin, cos"
        case .sec: return "sec"
        case .csc: return "csc"
        case .radian: return "rad"
        case .sinh: return "sinh"
        case .gamma: return "Γ, !"
        case .fibonacci: return "Fₙ"
        case .lucas: return "Lₙ"
        }
    }

    var name: String {
        switch self {
        case .pi: return "Kreiszahl Pi, ≈ 3,14159"
        case .e: return "Eulersche Zahl, ≈ 2,71828"
        case .phi: return "Goldener Schnitt, ≈ 1,61803"
        case .power: return "Potenz (hochgestellte Zahl)"
        case .sqrt: return "Quadratwurzel"
        case .cbrt: return "Kubikwurzel (dritte Wurzel)"
        case .ln: return "Natürlicher Logarithmus"
        case .sinCos: return "Sinus und Kosinus"
        case .sec: return "Sekans"
        case .csc: return "Kosekans"
        case .radian: return "Bogenmaß"
        case .sinh: return "Hyperbelsinus"
        case .gamma: return "Gammafunktion und Fakultät"
        case .fibonacci: return "Fibonacci-Zahlen"
        case .lucas: return "Lucas-Zahlen"
        }
    }

    var text: String {
        switch self {
        case .pi:
            return "Das Verhältnis von Umfang zu Durchmesser eines Kreises. Jeder Kreis ist ringsherum gut dreimal so lang wie quer hindurch, genau 3,14159 … mal. Die Nachkommastellen enden nie und wiederholen sich nie."
        case .e:
            return "Die Grundzahl des natürlichen Wachstums. Legt man 1 € zu 100 % Jahreszins an und schreibt die Zinsen nicht einmal im Jahr, sondern in jedem Augenblick gut, hat man nach einem Jahr genau e Euro, also 2,72 €."
        case .phi:
            return "Teilt man eine Strecke so, dass die ganze Strecke zum längeren Stück im selben Verhältnis steht wie das längere zum kürzeren, ist dieses Verhältnis φ = (1 + √5) / 2. Es steckt in Sonnenblumen, Muscheln, Bauwerken und in den Fibonacci-Zahlen."
        case .power:
            return "Eine hochgestellte Zahl sagt, wie oft man die Zahl darunter mit sich selbst malnimmt: 10³ = 10 · 10 · 10 = 1000. Ist die Hochzahl keine ganze Zahl, wie bei e hoch φ, setzt man diese Regel stufenlos fort."
        case .sqrt:
            return "√a ist die Zahl, die mit sich selbst malgenommen a ergibt. √2 = 1,41421 …, denn 1,41421² ≈ 2. Geometrisch: die Diagonale eines Quadrats mit Seitenlänge 1."
        case .cbrt:
            return "∛a ist die Zahl, die dreimal mit sich selbst malgenommen a ergibt. ∛8 = 2, weil 2 · 2 · 2 = 8. Geometrisch: die Kantenlänge eines Würfels mit dem Volumen a."
        case .ln:
            return "Die Frage nach der Hochzahl zur Basis e: ln(x) ist die Zahl, mit der man e potenzieren muss, um x zu erhalten. ln(e) = 1, ln(1) = 0."
        case .sinCos:
            return "Ein Punkt wandert auf einem Kreis mit Radius 1. Der Sinus ist seine Höhe über der Mitte, der Kosinus sein Abstand nach rechts. Beide schwanken zwischen −1 und 1, wie eine Welle."
        case .sec:
            return "Der Kehrwert des Kosinus: sec x = 1 / cos x. Ist der Kosinus klein, wird der Sekans groß."
        case .csc:
            return "Der Kehrwert des Sinus: csc x = 1 / sin x. Ist der Sinus klein, wird der Kosekans groß."
        case .radian:
            return "Winkel werden in der Mathematik oft nicht in Grad gemessen, sondern als Länge des Bogens auf einem Kreis mit Radius 1. Ein voller Kreis sind dann 2π ≈ 6,28 statt 360°. Die 20 bei sec²(20) sind also gut drei volle Umdrehungen."
        case .sinh:
            return "Ein Verwandter des Sinus, gebaut aus der Eulerschen Zahl: sinh x = (eˣ − e⁻ˣ) / 2. Er gehört zur Hyperbel wie der Sinus zum Kreis."
        case .gamma:
            return "Die Fakultät n! multipliziert alle Zahlen von 1 bis n: 4! = 1 · 2 · 3 · 4 = 24. Die Gammafunktion Γ setzt das auf alle Zahlen fort, auch zwischen den ganzen. Für ganze Zahlen gilt Γ(n) = (n − 1)!."
        case .fibonacci:
            return "Die Folge 1, 1, 2, 3, 5, 8, 13, 21, 34 …: Jede Zahl ist die Summe der beiden davor. Das Verhältnis zweier Nachbarn nähert sich immer mehr dem goldenen Schnitt φ."
        case .lucas:
            return "Die Schwester der Fibonacci-Folge mit anderem Anfang: 2, 1, 3, 4, 7, 11, 18, 29 … Auch hier ist jede Zahl die Summe der beiden davor."
        }
    }

    /// Welche Begriffe in welcher Formel vorkommen.
    static let perHour: [Int: [Glossary]] = [
        1: [.ln, .e], 2: [.pi], 3: [.sqrt, .pi, .radian], 4: [.cbrt],
        5: [.e, .phi, .power], 6: [.sec, .sinCos, .radian, .power], 7: [.sqrt], 8: [.phi, .fibonacci],
        9: [.pi, .e, .radian], 10: [.sinh, .e], 11: [.pi, .power], 12: [.csc, .sinCos, .radian, .power],
        13: [.pi, .power], 14: [.sqrt], 15: [.e, .power], 16: [.ln, .e, .power],
        17: [.e, .sqrt, .power], 18: [.phi, .power, .lucas], 19: [.e, .power], 20: [.e, .pi, .power],
        21: [.phi, .sqrt, .power, .fibonacci], 22: [.pi], 23: [.e, .pi, .power], 24: [.gamma],
    ]
}

/// Gemeinsamer Rahmen der Erklärfenster: weißer Grund, orange Schrift.
enum InfoStyle {
    static let deep = Color(red: 0.72, green: 0.38, blue: 0.0)   // dunkleres Orange für Fließtext, besser lesbar auf Weiß
    static let width: CGFloat = 520
}

struct ExplanationView: View {
    let hour: Int
    private let deep = InfoStyle.deep

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

            if let terms = Glossary.perHour[hour], !terms.isEmpty {
                Text("WAS DIE ZEICHEN BEDEUTEN")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .tracking(1.5)
                    .foregroundStyle(Palette.orange)
                    .padding(.top, 4)
                ForEach(terms, id: \.self) { t in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(t.symbol)
                            .font(.system(size: 18, design: .serif).italic())
                            .foregroundStyle(Palette.orange)
                            .frame(width: 64, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.name)
                                .font(.system(size: 14, weight: .semibold, design: .serif))
                            Text(t.text)
                                .font(.system(size: 14, design: .serif))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(deep)
                    }
                }
            }
        }
        .padding(30)
        .frame(width: InfoStyle.width, alignment: .leading)
        .background(Color.white)
    }
}
