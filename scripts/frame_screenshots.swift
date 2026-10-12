// Adds a marketing caption above each App Store screenshot (§12 of the launch plan).
// Usage: swift scripts/frame_screenshots.swift <raw-dir> <out-dir>
// <raw-dir>/<locale>/<device>-NN-name.png  ->  <out-dir>/<locale>/<device>-NN-name.png (same pixel size)
import AppKit
import CoreGraphics
import CoreText

let captions: [String: [String]] = [
    "en-US": ["Your book. Two languages.", "Sentence-by-sentence alignment", "Import anything you read",
              "Tap a word, get the dictionary", "Unknown words become flashcards", "Works offline, on your device",
              "Fits every screen", "One payment. Yours forever."],
    "tr": ["Kendi kitabın. İki dil.", "Cümle cümle hizalı", "Okuduğun her şeyi aktar",
           "Kelimeye dokun, sözlüğü gör", "Bilinmeyen kelimeler kart olur", "Çevrimdışı, cihazında çalışır",
           "Her ekrana uyar", "Tek ödeme. Sonsuza dek senin."],
    "de-DE": ["Dein Buch. Zwei Sprachen.", "Satz für Satz ausgerichtet", "Importiere alles, was du liest",
              "Wort antippen, Wörterbuch sehen", "Neue Wörter werden Karteikarten", "Offline, direkt auf deinem Gerät",
              "Passt auf jeden Bildschirm", "Einmal zahlen. Für immer deins."],
    "fr-FR": ["Votre livre. Deux langues.", "Alignement phrase par phrase", "Importez tout ce que vous lisez",
              "Touchez un mot, voyez le dictionnaire", "Les mots inconnus deviennent des cartes", "Hors ligne, sur votre appareil",
              "S'adapte à chaque écran", "Un seul paiement. À vous pour toujours."],
    "es-ES": ["Tu libro. Dos idiomas.", "Alineado frase por frase", "Importa todo lo que lees",
              "Toca una palabra, mira el diccionario", "Las palabras nuevas se vuelven tarjetas", "Sin conexión, en tu dispositivo",
              "Se adapta a cada pantalla", "Un solo pago. Tuyo para siempre."],
    "it": ["Il tuo libro. Due lingue.", "Allineato frase per frase", "Importa tutto ciò che leggi",
           "Tocca una parola, ecco il dizionario", "Le parole nuove diventano flashcard", "Offline, sul tuo dispositivo",
           "Si adatta a ogni schermo", "Un solo pagamento. Tuo per sempre."],
    "nl-NL": ["Jouw boek. Twee talen.", "Zin voor zin uitgelijnd", "Importeer alles wat je leest",
              "Tik op een woord, zie het woordenboek", "Onbekende woorden worden flashcards", "Offline, op je eigen toestel",
              "Past op elk scherm", "Eén betaling. Voor altijd van jou."]
]

let args = CommandLine.arguments
guard args.count == 3 else { fatalError("usage: frame_screenshots.swift <raw-dir> <out-dir>") }
let rawRoot = URL(fileURLWithPath: args[1]), outRoot = URL(fileURLWithPath: args[2])
let fm = FileManager.default
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func frame(_ input: URL, caption: String, to output: URL) throws {
    guard let src = NSImage(contentsOf: input)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw NSError(domain: "frame", code: 1, userInfo: [NSLocalizedDescriptionKey: "cannot read \(input.path)"])
    }
    let w = src.width, h = src.height
    let W = CGFloat(w), H = CGFloat(h)
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

    let gradient = CGGradient(colorsSpace: space, colors: [
        CGColor(srgbRed: 0.02, green: 0.17, blue: 0.22, alpha: 1),
        CGColor(srgbRed: 0.04, green: 0.45, blue: 0.47, alpha: 1)
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: H), end: CGPoint(x: W, y: 0), options: [])

    // Caption in the top band.
    let isTablet = W / H > 0.6
    let band = H * (isTablet ? 0.15 : 0.19)
    let fontSize = W * (isTablet ? 0.052 : 0.075)
    let font = CTFontCreateWithName("SFProDisplay-Bold" as CFString, fontSize, nil)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    let text = NSAttributedString(string: caption, attributes: [
        .font: font, .foregroundColor: NSColor.white, .paragraphStyle: paragraph
    ])
    let setter = CTFramesetterCreateWithAttributedString(text)
    let textWidth = W * 0.86
    let fit = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil, CGSize(width: textWidth, height: band), nil)
    let textRect = CGRect(x: (W - textWidth) / 2, y: H - band / 2 - fit.height / 2 - H * 0.01,
                          width: textWidth, height: fit.height + 4)
    CTFrameDraw(CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: textRect, transform: nil), nil), ctx)

    // Screenshot below, scaled, rounded, with a soft shadow; it bleeds off the bottom edge.
    let scale: CGFloat = isTablet ? 0.84 : 0.82
    let sw = W * scale, sh = H * scale
    let shotRect = CGRect(x: (W - sw) / 2, y: H - band - sh, width: sw, height: sh)
    let radius = W * 0.05
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -H * 0.006), blur: W * 0.04,
                  color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.addPath(CGPath(roundedRect: shotRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: shotRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.clip()
    ctx.interpolationQuality = .high
    ctx.draw(src, in: shotRect)
    ctx.restoreGState()

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try rep.representation(using: .png, properties: [:])!.write(to: output)
}

var count = 0
for locale in (try fm.contentsOfDirectory(atPath: rawRoot.path)).sorted() {
    let dir = rawRoot.appendingPathComponent(locale)
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { continue }
    guard let list = captions[locale] else { print("no captions for \(locale), skipping"); continue }
    let outDir = outRoot.appendingPathComponent(locale)
    try fm.createDirectory(at: outDir, withIntermediateDirectories: true)
    for file in try fm.contentsOfDirectory(atPath: dir.path) where file.hasSuffix(".png") {
        // "<device>-NN-name.png": NN selects the caption.
        guard let match = file.range(of: #"-(\d\d)-"#, options: .regularExpression),
              let index = Int(file[match].dropFirst().prefix(2)), (1...list.count).contains(index) else { continue }
        try frame(dir.appendingPathComponent(file), caption: list[index - 1], to: outDir.appendingPathComponent(file))
        count += 1
    }
}
print("framed \(count) screenshots")
