import Foundation

/// A run of visible text from an HTML/XHTML document.
public struct TextBlock: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case heading(Int)
        case paragraph
    }

    public var kind: Kind
    public var text: String

    public init(_ kind: Kind, _ text: String) {
        self.kind = kind
        self.text = text
    }

    public var isHeading: Bool {
        if case .heading = kind { return true }
        return false
    }
}

/// Lenient tag scanner that turns (X)HTML into headings and paragraphs. It never fails on
/// malformed markup or undeclared entities, which a strict XML parser would.
public enum HTMLTextExtractor {
    public struct Result: Sendable {
        public var title: String?
        public var blocks: [TextBlock]
    }

    private static let blockTags: Set<String> = [
        "p", "div", "li", "blockquote", "tr", "section", "article", "header", "footer", "pre", "dt", "dd",
        "figcaption", "table", "ul", "ol", "hr", "body", "aside", "h1", "h2", "h3", "h4", "h5", "h6", "main", "td", "th"
    ]
    private static let skippedTags: Set<String> = ["script", "style", "noscript", "svg", "math", "rt", "rp", "nav", "template", "iframe"]

    public static func extract(_ html: String) -> Result {
        let scalars = Array(html.unicodeScalars)
        var index = 0
        var title: String?
        var blocks: [TextBlock] = []
        var buffer = String.UnicodeScalarView()
        var headingLevel: Int?
        var skipDepth = 0
        var inHead = false
        var inTitle = false
        var titleBuffer = ""

        func flush() {
            let text = normalize(String(buffer))
            buffer.removeAll(keepingCapacity: true)
            guard !text.isEmpty else { return }
            blocks.append(TextBlock(headingLevel.map { .heading($0) } ?? .paragraph, text))
        }

        while index < scalars.count {
            let scalar = scalars[index]
            if scalar == "<" {
                // Comments, doctype, processing instructions, CDATA.
                if matches(scalars, at: index, "<!--") {
                    index = find(scalars, "-->", from: index + 4).map { $0 + 3 } ?? scalars.count
                    continue
                }
                if matches(scalars, at: index, "<![CDATA[") {
                    let end = find(scalars, "]]>", from: index + 9) ?? scalars.count
                    if skipDepth == 0 { buffer.append(contentsOf: scalars[(index + 9)..<end]) }
                    index = min(end + 3, scalars.count)
                    continue
                }
                if index + 1 < scalars.count, scalars[index + 1] == "!" || scalars[index + 1] == "?" {
                    index = find(scalars, ">", from: index).map { $0 + 1 } ?? scalars.count
                    continue
                }
                guard let tag = readTag(scalars, at: index) else {
                    if skipDepth == 0 { buffer.append(scalar) }
                    index += 1
                    continue
                }
                index = tag.end
                let name = tag.name

                if skippedTags.contains(name) {
                    if tag.isClosing {
                        skipDepth = max(0, skipDepth - 1)
                    } else if !tag.isSelfClosing {
                        skipDepth += 1
                    }
                    continue
                }
                if name == "head" { inHead = !tag.isClosing; continue }
                if name == "title" {
                    inTitle = !tag.isClosing && !tag.isSelfClosing
                    if tag.isClosing, title == nil {
                        let text = normalize(titleBuffer)
                        if !text.isEmpty { title = text }
                    }
                    continue
                }
                if skipDepth > 0 || inHead { continue }

                if name == "br" {
                    buffer.append(" ")
                } else if blockTags.contains(name) {
                    flush()
                    if name.count == 2, name.first == "h", let level = Int(String(name.last!)) {
                        headingLevel = tag.isClosing ? nil : level
                    }
                }
                continue
            }

            if scalar == "&" {
                let (decoded, next) = decodeEntity(scalars, at: index)
                index = next
                if inTitle { titleBuffer.unicodeScalars.append(contentsOf: decoded.unicodeScalars) }
                if skipDepth == 0, !inHead { buffer.append(contentsOf: decoded.unicodeScalars) }
                continue
            }

            if inTitle { titleBuffer.unicodeScalars.append(scalar) }
            if skipDepth == 0, !inHead { buffer.append(scalar) }
            index += 1
        }
        flush()
        return Result(title: title, blocks: blocks)
    }

    /// Collapses whitespace (including no-break spaces) and trims.
    static func normalize(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var pendingSpace = false
        for character in text {
            if character.isWhitespace || character == "\u{00AD}" {
                if character != "\u{00AD}" { pendingSpace = !result.isEmpty }
                continue
            }
            if pendingSpace { result.append(" ") }
            pendingSpace = false
            result.append(character)
        }
        return result
    }

    // MARK: Tags

    private struct Tag {
        var name: String
        var isClosing: Bool
        var isSelfClosing: Bool
        var end: Int
    }

    private static func readTag(_ scalars: [Unicode.Scalar], at start: Int) -> Tag? {
        var index = start + 1
        var isClosing = false
        if index < scalars.count, scalars[index] == "/" {
            isClosing = true
            index += 1
        }
        var name = ""
        while index < scalars.count, scalars[index].properties.isAlphabetic || ("0"..."9").contains(scalars[index])
                || scalars[index] == ":" || scalars[index] == "-" {
            name.unicodeScalars.append(scalars[index])
            index += 1
        }
        guard !name.isEmpty else { return nil }
        // Drop a namespace prefix such as "xhtml:p".
        if let colon = name.lastIndex(of: ":") { name = String(name[name.index(after: colon)...]) }

        var quote: Unicode.Scalar?
        let attributesStart = index
        while index < scalars.count {
            let scalar = scalars[index]
            if let open = quote {
                if scalar == open { quote = nil }
            } else if scalar == "\"" || scalar == "'" {
                quote = scalar
            } else if scalar == ">" {
                break
            }
            index += 1
        }
        let raw = String(String.UnicodeScalarView(scalars[attributesStart..<min(index, scalars.count)]))
        return Tag(name: name.lowercased(), isClosing: isClosing, isSelfClosing: raw.hasSuffix("/"),
                   end: min(index + 1, scalars.count))
    }

    private static func matches(_ scalars: [Unicode.Scalar], at index: Int, _ pattern: String) -> Bool {
        var position = index
        for scalar in pattern.unicodeScalars {
            guard position < scalars.count, scalars[position] == scalar else { return false }
            position += 1
        }
        return true
    }

    private static func find(_ scalars: [Unicode.Scalar], _ pattern: String, from start: Int) -> Int? {
        guard let first = pattern.unicodeScalars.first else { return nil }
        var index = start
        while index < scalars.count {
            if scalars[index] == first, matches(scalars, at: index, pattern) { return index }
            index += 1
        }
        return nil
    }

    // MARK: Entities

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}", "shy": "\u{00AD}",
        "mdash": "—", "ndash": "–", "hellip": "…", "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
        "sbquo": "‚", "bdquo": "„", "laquo": "«", "raquo": "»", "lsaquo": "‹", "rsaquo": "›", "copy": "©",
        "reg": "®", "trade": "™", "deg": "°", "middot": "·", "bull": "•", "times": "×", "divide": "÷",
        "euro": "€", "pound": "£", "sect": "§", "para": "¶", "iexcl": "¡", "iquest": "¿", "thinsp": "\u{2009}",
        "ensp": "\u{2002}", "emsp": "\u{2003}", "zwnj": "", "zwj": "", "prime": "′", "Prime": "″",
        "aacute": "á", "eacute": "é", "iacute": "í", "oacute": "ó", "uacute": "ú", "Aacute": "Á", "Eacute": "É",
        "Iacute": "Í", "Oacute": "Ó", "Uacute": "Ú", "agrave": "à", "egrave": "è", "igrave": "ì", "ograve": "ò",
        "ugrave": "ù", "Agrave": "À", "Egrave": "È", "acirc": "â", "ecirc": "ê", "icirc": "î", "ocirc": "ô",
        "ucirc": "û", "auml": "ä", "euml": "ë", "iuml": "ï", "ouml": "ö", "uuml": "ü", "Auml": "Ä", "Ouml": "Ö",
        "Uuml": "Ü", "szlig": "ß", "ntilde": "ñ", "Ntilde": "Ñ", "ccedil": "ç", "Ccedil": "Ç", "aelig": "æ",
        "oelig": "œ", "aring": "å", "oslash": "ø", "atilde": "ã", "otilde": "õ", "yuml": "ÿ"
    ]

    private static func decodeEntity(_ scalars: [Unicode.Scalar], at start: Int) -> (String, Int) {
        var index = start + 1
        var name = ""
        while index < scalars.count, index - start <= 10, scalars[index] != ";" {
            let scalar = scalars[index]
            guard scalar.properties.isAlphabetic || ("0"..."9").contains(scalar) || scalar == "#" else { break }
            name.unicodeScalars.append(scalar)
            index += 1
        }
        guard index < scalars.count, scalars[index] == ";", !name.isEmpty else { return ("&", start + 1) }
        let end = index + 1
        if name.hasPrefix("#") {
            let digits = name.dropFirst()
            let value = digits.lowercased().hasPrefix("x") ? UInt32(digits.dropFirst(), radix: 16) : UInt32(digits)
            if let value, let scalar = Unicode.Scalar(value) { return (String(scalar), end) }
            return ("", end)
        }
        if let text = namedEntities[name] { return (text, end) }
        return ("&\(name);", end)
    }
}
