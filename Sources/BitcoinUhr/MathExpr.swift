import SwiftUI

/// Kleiner Formelsatz: genug für die 24 Ausdrücke des Zifferblatts.
indirect enum MathExpr {
    case n(String)                  // aufrecht: Ziffern, Funktionsnamen, Operatoren
    case v(String)                  // kursiv: Variablen und Konstanten
    case sup(MathExpr, MathExpr)    // Basis, Exponent
    case frac(MathExpr, MathExpr)   // Zähler, Nenner
    case root(MathExpr, String?)    // Radikand, Wurzelexponent
    case row([MathExpr])
}

/// Stunde → Ausdruck, dessen Wert gerundet die Stunde ergibt.
enum HourFormula {
    static let phi = (1 + 5.0.squareRoot()) / 2

    static let all: [Int: (expr: MathExpr, value: Double)] = [
        1: (.n("ln(3)"), log(3)),
        2: (.frac(.row([.n("7"), .v("π")]), .n("11")), 7 * .pi / 11),
        3: (.row([.root(.n("2"), nil), .n(" + "), .frac(.v("π"), .n("2"))]), 2.0.squareRoot() + .pi / 2),
        4: (.frac(.n("7"), .root(.n("5"), "3")), 7 / cbrt(5)),
        5: (.sup(.v("e"), .v("φ")), exp(phi)),
        6: (.row([.sup(.n("sec"), .n("2")), .n("(20)")]), 1 / pow(cos(20), 2)),
        7: (.row([.n("4"), .root(.n("3"), nil)]), 4 * 3.0.squareRoot()),
        8: (.row([.n("5"), .v("φ")]), 5 * phi),
        9: (.row([.n("2"), .v("π"), .n(" + "), .v("e")]), 2 * .pi + M_E),
        10: (.n("sinh(3)"), sinh(3)),
        11: (.row([.sup(.v("π"), .n("3")), .n(" − 20")]), pow(.pi, 3) - 20),
        12: (.row([.sup(.n("csc"), .n("2")), .n("(16)")]), 1 / pow(sin(16), 2)),
        13: (.row([.sup(.v("π"), .n("2")), .n(" + "), .v("π")]), .pi * .pi + .pi),
        14: (.row([.n("10"), .root(.n("2"), nil)]), 10 * 2.0.squareRoot()),
        15: (.sup(.v("e"), .v("e")), pow(M_E, M_E)),
        16: (.row([.n("ln "), .sup(.n("10"), .n("7"))]), log(1e7)),
        17: (.sup(.v("e"), .row([.n("2"), .root(.n("2"), nil)])), exp(2 * 2.0.squareRoot())),
        18: (.sup(.v("φ"), .n("6")), pow(phi, 6)),
        19: (.row([.sup(.v("e"), .n("3")), .n(" − 1")]), exp(3) - 1),
        20: (.row([.sup(.v("e"), .v("π")), .n(" − "), .v("π")]), exp(.pi) - .pi),
        21: (.frac(.sup(.v("φ"), .n("8")), .root(.n("5"), nil)), pow(phi, 8) / 5.0.squareRoot()),
        22: (.row([.n("7"), .v("π")]), 7 * .pi),
        23: (.sup(.v("e"), .v("π")), exp(.pi)),
        24: (.n("Γ(5)"), tgamma(5)),
    ]
}

struct MathView: View {
    let expr: MathExpr
    let size: CGFloat

    var body: some View { Self.render(expr, size) }

    static func render(_ e: MathExpr, _ s: CGFloat) -> AnyView {
        let line = max(0.8, s * 0.055)
        switch e {
        case .n(let t):
            return AnyView(Text(t).font(.system(size: s, weight: .regular, design: .serif)))
        case .v(let t):
            return AnyView(Text(t).font(.system(size: s, weight: .regular, design: .serif)).italic())
        case .row(let xs):
            return AnyView(HStack(alignment: .center, spacing: 0) {
                ForEach(xs.indices, id: \.self) { render(xs[$0], s) }
            })
        case .sup(let base, let exp):
            return AnyView(HStack(alignment: .top, spacing: s * 0.04) {
                render(base, s)
                render(exp, s * 0.6).offset(y: -s * 0.2)
            })
        case .frac(let num, let den):
            return AnyView(VStack(spacing: s * 0.24) {
                render(num, s * 0.8)
                render(den, s * 0.8)
            }
            .padding(.horizontal, s * 0.1)
            .overlay(Rectangle().frame(height: line)))
        case .root(let radicand, let index):
            return AnyView(HStack(alignment: .center, spacing: 0) {
                Text("√")
                    .font(.system(size: s * 1.05, weight: .light, design: .serif))
                    .overlay(alignment: .topLeading) {
                        if let index {
                            Text(index)
                                .font(.system(size: s * 0.42, design: .serif))
                                .offset(x: -s * 0.06, y: s * 0.12)
                        }
                    }
                render(radicand, s)
                    .padding(.top, s * 0.14)
                    .padding(.trailing, s * 0.04)
                    .overlay(alignment: .top) { Rectangle().frame(height: line).offset(y: s * 0.1) }
            })
        }
    }
}
