import Foundation

/// Reads DRM-free EPUB 2/3 files: container → OPF → spine → XHTML text.
public enum EPUBParser {
    /// Font obfuscation is allowed; any other encryption means DRM.
    private static let fontObfuscation: Set<String> = ["http://www.idpf.org/2008/embedding", "http://ns.adobe.com/pdf/enc#RC"]

    public static func parse(_ data: Data, fallbackTitle: String = "Untitled") throws -> ParsedBook {
        let zip: ZipArchive
        do { zip = try ZipArchive(data: data) } catch { throw ImportError.unsupportedFile }

        if zip.contains("META-INF/rights.xml") { throw ImportError.drmProtected }
        if let encryption = try? zip.string(for: "META-INF/encryption.xml") {
            let algorithms = matches(of: #"Algorithm\s*=\s*["']([^"']+)["']"#, in: encryption)
            let protected = algorithms.contains { !fontObfuscation.contains($0) && !$0.contains("xmldsig") }
            if protected { throw ImportError.drmProtected }
        }

        guard let container = try? zip.string(for: "META-INF/container.xml"),
              let opfPath = matches(of: #"full-path\s*=\s*["']([^"']+)["']"#, in: container).first,
              let opfData = try? zip.data(for: opfPath)
        else { throw ImportError.unsupportedFile }

        let package = OPFDocument(data: opfData)
        let base = (opfPath as NSString).deletingLastPathComponent

        var chapters: [ParsedChapter] = []
        for idref in package.spine {
            guard let item = package.manifest[idref], item.isDocument, !item.properties.contains("nav") else { continue }
            let path = resolve(item.href, relativeTo: base)
            guard let html = try? zip.string(for: path) else { continue }
            chapters += chaptersFrom(HTMLTextExtractor.extract(html))
        }
        chapters = Chapterizer.clean(chapters)
        guard !chapters.isEmpty else {
            throw zip.entries.keys.contains(where: { $0.hasSuffix(".xhtml") || $0.hasSuffix(".html") })
                ? ImportError.noText : ImportError.unsupportedFile
        }
        let title = package.title.map(HTMLTextExtractor.normalize).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackTitle
        return ParsedBook(title: title, author: package.creator.map(HTMLTextExtractor.normalize),
                          language: package.language, chapters: chapters)
    }

    /// One spine document becomes one chapter, unless it holds several same-level headings
    /// (Gutenberg often puts a whole book into a few large files).
    static func chaptersFrom(_ document: HTMLTextExtractor.Result) -> [ParsedChapter] {
        let levels = document.blocks.compactMap { block -> Int? in
            if case .heading(let level) = block.kind { return level }
            return nil
        }
        let top = levels.min()
        let splitsAtTop = levels.filter { $0 == top }.count >= 2

        var chapters: [ParsedChapter] = []
        var headingLines: [String] = []
        var paragraphs: [String] = []
        func flush() {
            chapters.append(ParsedChapter(title: headingLines.isEmpty ? nil : headingLines.joined(separator: " "),
                                          paragraphs: paragraphs))
            headingLines = []
            paragraphs = []
        }
        for block in document.blocks {
            if case .heading(let level) = block.kind {
                if splitsAtTop, level == top, !paragraphs.isEmpty { flush() }
                // Leading headings ("CHAPTER I." + "Down the Rabbit-Hole") form the title.
                if paragraphs.isEmpty, headingLines.count < 2 {
                    headingLines.append(block.text)
                    continue
                }
            }
            paragraphs.append(block.text)
        }
        if !paragraphs.isEmpty || chapters.isEmpty { flush() }
        return chapters
    }

    static func resolve(_ href: String, relativeTo base: String) -> String {
        var href = href
        if let hash = href.firstIndex(of: "#") { href = String(href[..<hash]) }
        href = href.removingPercentEncoding ?? href
        var parts = base.isEmpty ? [] : base.split(separator: "/").map(String.init)
        for component in href.split(separator: "/").map(String.init) {
            switch component {
            case ".", "": continue
            case "..": if !parts.isEmpty { parts.removeLast() }
            default: parts.append(component)
            }
        }
        return parts.joined(separator: "/")
    }

    static func matches(of pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            Range($0.range(at: 1), in: text).map { String(text[$0]) }
        }
    }
}

/// The parts of an OPF package document the reader needs.
final class OPFDocument: NSObject, XMLParserDelegate {
    struct Item {
        var href: String
        var mediaType: String
        var properties: String
        var isDocument: Bool { mediaType.contains("html") || href.hasSuffix(".xhtml") || href.hasSuffix(".html") || href.hasSuffix(".htm") }
    }

    private(set) var title: String?
    private(set) var creator: String?
    private(set) var language: String?
    private(set) var manifest: [String: Item] = [:]
    private(set) var spine: [String] = []

    private var text = ""

    init(data: Data) {
        super.init()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = self
        parser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes: [String: String] = [:]) {
        text = ""
        switch elementName {
        case "item":
            if let id = attributes["id"], let href = attributes["href"] {
                manifest[id] = Item(href: href, mediaType: attributes["media-type"] ?? "", properties: attributes["properties"] ?? "")
            }
        case "itemref":
            if let idref = attributes["idref"], attributes["linear"] != "no" { spine.append(idref) }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        switch elementName {
        case "title" where title == nil: title = value
        case "creator" where creator == nil: creator = value
        case "language" where language == nil: language = value
        default: break
        }
    }
}
