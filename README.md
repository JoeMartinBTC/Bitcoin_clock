# Bitcoin-Uhr

Eine analoge Schreibtischuhr für macOS in Bitcoin-Orange. Auf den 5-Minuten-Strichen erscheinen mathematische Formeln, deren Wert gerundet genau die Stunde ergibt. Um 21 Uhr steht dort das ₿. Live-Daten von [mempool.space](https://mempool.space) zeigt die Uhr als schlichte Textanzeigen auf dem Zifferblatt.

*An analog macOS desktop clock in Bitcoin orange with math formulas on the hour marks and live data from mempool.space. UI in German.*

<p align="center"><img src="docs/uhr.png" width="480" alt="Bitcoin-Uhr um 21:45 mit der Formel φ⁸/√5 ≈ 21 an der ₿-Position"></p>

Die Idee stammt von der „mathematical clock“ von [@Math_files](https://x.com/Math_files/status/2102353716305170664) und wurde hier auf 24 Formeln erweitert.

## Was sie kann

- **12-Stunden-Blatt mit AM/PM.** Vormittags stehen 1–11 auf dem Blatt, nachmittags 13–23. Nachmittags steht an der Stelle der 9 das ₿ für 21 Uhr, dazu ein ₿ als Wasserzeichen.
- **Formeln auf den 5-Minuten-Strichen.** Steht der Minutenzeiger genau auf einem Strich, ersetzt ein Schild die Zahl dort durch eine Formel, etwa e^π − π ≈ 20 oder φ⁸/√5 ≈ 21. Ein Klick darauf öffnet eine Erklärung, die auch jedes vorkommende Zeichen erklärt (π, e, φ, Bogenmaß …).
- **Komplikationen von mempool.space.** Vier Plätze zeigen wahlweise Blockhöhe, Gebühren, Preis in USD oder EUR, wartende Transaktionen, Blöcke bis zum Halving oder die nächste Difficulty-Anpassung. Ein Klick öffnet eine Erklärung in einfacher Sprache, von dort geht es auf Wunsch zu mempool.space.
- **Alles per Rechtsklick einstellbar:** Größe, Sekundenzeiger mit CPU-Stufe (aus, harter Sprung, weicher Sprung, gleitend), Formeln, Wasserzeichen, AM/PM, Komplikationen je Platz, Aktualisierungsintervall, Ebene („Über allen Fenstern“) und Autostart.
- **Sparsam.** Die Zeiger dreht Core Animation, die App selbst braucht im Betrieb praktisch keine CPU.

<p align="center">
  <img src="docs/erklaerung-formel.png" width="380" alt="Erklärfenster zur Formel für 21">
  <img src="docs/erklaerung-halving.png" width="380" alt="Erklärfenster zum Halving">
</p>

## Bauen und installieren

Voraussetzungen: macOS 14 oder neuer und die Swift-Toolchain (Xcode oder die Command Line Tools).

```bash
git clone https://github.com/JoeMartinBTC/Bitcoin_clock.git
cd Bitcoin_clock
bash Scripts/build_local_app.sh
```

Das Skript baut die App, erzeugt das Symbol, signiert ad hoc, installiert nach `/Applications/BitcoinUhr.app` und startet sie. Beim ersten Start trägt sich die Uhr als Anmeldeobjekt ein. Das lässt sich per Rechtsklick wieder abschalten.

Bedienung: Linke Maustaste verschiebt die Uhr, Rechtsklick öffnet das Menü.

## Datenschutz

Die Uhr sammelt nichts und sendet nichts. Sie ruft nur die öffentliche API von mempool.space ab, und nur für die Komplikationen, die gerade sichtbar sind. Sind alle ausgeschaltet, gibt es keinen Netzverkehr.

## Lizenz

[MIT](LICENSE)
