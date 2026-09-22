# Entwicklung — wie die Bitcoin-Uhr gebaut ist

Dieses Dokument ist für alle, die an der Uhr weiterbauen wollen. Es beschreibt Aufbau, Entscheidungen, Messwerte und die Fallen, die beim Bau aufgetreten sind. Bedienung und Installation stehen im [README](../README.md).

## Überblick

Die Uhr ist eine macOS-App ohne Dock-Symbol (`LSUIElement`). Sie besteht aus einem einzigen randlosen, durchsichtigen Fenster, in dem eine SwiftUI-Ansicht das Zifferblatt zeichnet. Gebaut wird mit dem Swift Package Manager, ein Xcode-Projekt gibt es nicht.

| Datei | Aufgabe |
|---|---|
| `main.swift` | Einstieg; startet die App oder den Schnappschuss-Modus |
| `AppDelegate.swift` | Fenster, Fensterebene, Klick- und Zieh-Erkennung, Erklärfenster, Einstellungen (`ClockSettings`), Autostart |
| `ClockView.swift` | Zifferblatt: Ebenen, Beschriftung, Formel-Schilder, Komplikationen, Rechtsklick-Menü |
| `HandsLayerView.swift` | Zeiger als Core-Animation-Ebenen |
| `MathExpr.swift` | die 24 Formeln als kleiner Formelsatz (`MathExpr`) und ihre Darstellung (`MathView`) |
| `Explanations.swift` | Erklärtexte je Formel und das Zeichen-Glossar |
| `Mempool.swift` | Abfrage von mempool.space, Arten und Plätze der Komplikationen |
| `ComplicationInfo.swift` | Erklärfenster zu den Komplikationen |

## Zifferblatt in Ebenen

Das Blatt ist in Ebenen aufgeteilt, die sich unterschiedlich oft ändern. Das ist der wichtigste Grund für die geringe Last.

| Ebene | Aktualisierung | Inhalt |
|---|---|---|
| statisches Blatt | nie (als `drawingGroup` gerastert) | Gehäuse, Lünette, Sonnenschliff, Wasserzeichen, Minutenring, Schriftzug |
| Beschriftung | `TimelineView(.everyMinute)` | Stundenzahlen, Stundenmarken, AM/PM |
| Komplikationen | bei neuen Daten | Texte von mempool.space |
| Zeiger | Core Animation, siehe unten | Stunde, Minute, Sekunde |
| Formel-Schilder | `TimelineView(.everyMinute)` | Schild über den Zeigern |
| Glas | nie | leichter Lichtreflex |

Die Formel-Schilder liegen bewusst **über** den Zeigern. Der Minutenzeiger zeigt ja genau auf die Formel, die gerade erscheint; darunter wäre sie verdeckt.

## Zeit, Beschriftung und Formeln

- **12-Stunden-Blatt:** Position `p` (1…12) trägt vormittags `p`, nachmittags `p + 12`, oben immer 12 (`DialView.label`). Nachmittags steht an Position 9 das ₿ statt 21.
- **Wann eine Formel erscheint:** nur in der vollen Minute, in der der Minutenzeiger auf einem 5-Minuten-Strich steht, also bei Minute 0, 5, 10 … (`DialView.activePosition`). Vormittags die Formeln 1–12, nachmittags 12–23. Die Formel für 24 (Γ(5)) ist hinterlegt, erscheint auf dem 12-Stunden-Blatt aber nicht.
- **Formeln prüfen:** Jede Formel steht mit ihrem Wert in `HourFormula.all`. Eine neue Formel muss gerundet ihre Stunde ergeben. Schnelltest:

  ```bash
  python3 -c "from math import *; print(round(exp(pi)-pi))"
  ```

- **Formelsatz:** `MathExpr` kennt aufrechte Zeichen, kursive Variablen, Hochstellung, Bruch, Wurzel mit optionalem Wurzelexponent und Reihen. Das reicht für alle 24 Ausdrücke. Tiefgestellte Unicode-Ziffern (₈, ₆) fehlen in der Serifenschrift und erscheinen als Lücke; in Texten deshalb `F(8)` statt `F₈`.

## Zeiger mit Core Animation

Jeder Zeiger wird einmal per `ImageRenderer` als Bild gerastert und in eine eigene `CALayer` gelegt. Die Drehung ist eine `CAKeyframeAnimation` auf `transform.rotation.z`, die der Render-Server von macOS abspielt. Die App selbst rechnet dafür nicht mehr.

- **Phasengenau:** `beginTime = jetzt − bereits vergangene Zeit im Zyklus`, Zyklus 12 h / 1 h / 60 s.
- **Nachstellen:** nach dem Aufwachen (`NSWorkspace.didWakeNotification`), bei geänderter Systemzeit (`NSSystemClockDidChange`) und vorsorglich alle 10 Minuten. Nötig, weil die Medienzeit im Ruhezustand stehen bleibt.
- **In Schritten statt stufenlos:** Stundenzeiger 720 Schritte (jede Minute 0,5°), Minutenzeiger 360 Schritte (alle 10 s 1°), jeweils `calculationMode = .discrete`. Eine stufenlose Drehung zwingt den WindowServer, ständig neu zusammenzusetzen.
- **Drehrichtung:** Die Ebene ist nicht gespiegelt (`isGeometryFlipped == false`), deshalb dreht ein negativer Winkel im Uhrzeigersinn.
- **Klicks:** `HandsNSView.hitTest` gibt `nil` zurück, Klicks gehen durch die Zeiger hindurch.

Sekundenzeiger je nach Einstellung: aus, harter Sprung (60 diskrete Schritte, voreingestellt), weicher Sprung (steht 0,82 s, springt in 0,18 s mit `easeOut`) oder gleitend (stufenlos über 60 s).

### Messwerte (Mac Studio, `top`, Größe „Groß“)

| Variante | App-CPU | zusätzlich beim WindowServer |
|---|---|---|
| ganzes Blatt per `TimelineView`, 8 Bilder pro Sekunde | 13,7 % | – |
| ganzes Blatt, 1 Bild pro Sekunde | 0,6 % | – |
| 1 Bild pro Sekunde mit Feder-Animation | 5,3 % | – |
| Ebenen getrennt, Zeiger einzeln gerastert | 3,6–4,4 % | – |
| Core Animation, Stunde/Minute stufenlos | 0,0 % | +4,5 Prozentpunkte |
| Core Animation, alles in Schritten, weicher Sekundensprung | 0,0 % | +1,3 Prozentpunkte |
| Core Animation, alles in Schritten, harter Sekundensprung | 0,0 % | im Rauschen (−2,7 bis +0,1) |

WindowServer-Werte sind A/B-Vergleiche mit und ohne laufende Uhr, je 10 Proben in mehreren Runden.

## Klicks auf dem Zifferblatt

Das Fenster ist randlos und liegt normalerweise auf Schreibtisch-Ebene (`CGWindowLevelForKey(.desktopIconWindow) + 1`, über den Symbolen, unter allen Programmfenstern). Auf dieser Ebene kommen SwiftUI-Taps nicht zuverlässig an. Deshalb fängt ein lokaler `NSEvent`-Monitor jeden Linksklick ab und entscheidet geometrisch:

1. Liegt der Klick auf dem sichtbaren Formel-Schild (`plaqueHit`), öffnet sich die Erklärung.
2. Liegt er auf einer Komplikation (`complicationHit`), öffnet sich deren Erklärung.
3. Sonst wird die Uhr per `performDrag` verschoben.

Die Schild- und Komplikationspositionen kommen aus denselben Funktionen, mit denen gezeichnet wird (`DialView.plaqueOffset`, `ComplicationSlot.offset`). Achtung: SwiftUI zählt y nach unten, AppKit nach oben.

Der Rechtsklick läuft über SwiftUIs `.contextMenu`.

## Komplikationen und Datenschutz

Quelle ist die öffentliche API von mempool.space, ohne Schlüssel:

| Anzeige | Endpunkt |
|---|---|
| Blockhöhe, Halving | `/api/blocks/tip/height` |
| Gebühren | `/api/v1/fees/recommended` (`fastestFee`, `halfHourFee`, `hourFee`) |
| Preis USD/EUR | `/api/v1/prices` |
| Mempool | `/api/mempool` (`count`) |
| Difficulty | `/api/v1/difficulty-adjustment` (`difficultyChange`, `remainingBlocks`) |

Abgefragt wird nur, was gerade sichtbar ist. Die Gebühren holen zusätzlich den Preis, damit das Erklärfenster die Kosten einer Überweisung in Euro nennen kann. Sind alle Komplikationen aus, gibt es keinen Netzverkehr. Das Halving wird aus der Blockhöhe berechnet (Epoche 210.000 Blöcke).

## Einstellungen

Alles liegt in `UserDefaults` der Bundle-ID `com.joemartinbtc.BitcoinUhr`:

`size`, `floating`, `secondHand`, `showFormulas`, `showWatermark`, `showAmPm`, `refresh`, `complication.top|left|right|bottom`, `autostartInitialized`, dazu die Fensterposition unter `NSWindow Frame BitcoinUhr`.

## Autostart

Beim ersten Start trägt sich die App mit `SMAppService.mainApp.register()` als Anmeldeobjekt ein. Im macOS-26-SDK heißt die Eigenschaft `mainApp`, nicht mehr `mainAppService`. Prüfen:

```bash
sfltool dumpbtm | grep -A8 "Name: BitcoinUhr" | grep -E "Disposition|Bundle Identifier"
```

Wer die Bundle-ID ändert, bekommt einen zweiten Eintrag. Beide lassen sich so entfernen; danach trägt sich die App beim nächsten Start neu ein, wenn `autostartInitialized` gelöscht ist:

```bash
osascript -e 'tell application "System Events" to delete (every login item whose name is "BitcoinUhr")'
```

## Schnappschüsse ohne Bildschirmaufnahme

```bash
.build/…/BitcoinUhr --snapshot <ordner> 21:45:00 10:12:00
```

rendert das Zifferblatt zu den angegebenen Zeiten mit transparentem Hintergrund, dazu Erklärfenster, mit echten Werten von mempool.space. So entstehen die Bilder in `docs/`. Die Zeiger zeichnet dieser Modus mit SwiftUI, nicht mit Core Animation.

## Bauen

```bash
bash Scripts/build_local_app.sh
```

Das Skript holt den Pfad der fertigen Binärdatei über `swift build -c release --show-bin-path`. Aktuelle Toolchains legen sie unter `.build/out/Products/Release/` ab, ältere unter `.build/arm64-apple-macosx/release/`; der Pfad darf deshalb nicht fest im Skript stehen.

## Wo man anfangen kann

- Neue Komplikation: Fall in `ComplicationKind` ergänzen (Titel, Beschriftung, Ziel-URL), Abfrage und Formatierung in `MempoolData`, Erklärtext in `ComplicationInfoView`.
- Neue Formel: Eintrag in `HourFormula.all`, Erklärung in `HourExplanation.text`, Zeichen in `Glossary.perHour`.
- Neuer Menüpunkt: Eigenschaft in `ClockSettings` mit `UserDefaults`, Eintrag im `menu` von `ClockView`.
