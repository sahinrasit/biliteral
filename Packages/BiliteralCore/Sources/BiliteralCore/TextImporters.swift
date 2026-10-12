import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

/// Pasted text and .txt files.
public enum PlainTextParser {
    private static let chapterHeading = try! NSRegularExpression(
        pattern: #"^(chapter|book|part|kapitel|teil|chapitre|livre|partie|cap[ií]tulo|parte|capitolo|libro|hoofdstuk|deel|b[öo]l[üu]m|k[ıi]s[ıi]m|глава|część|rozdział)\s+([0-9]+|[ivxlcdm]+|[a-zà-ÿ]+)\b"#,
        options: [.caseInsensitive])

    public static func parse(_ text: String, title: String) throws -> ParsedBook {
        let paragraphs = paragraphs(in: text)
        guard !paragraphs.isEmpty else { throw ImportError.noText }

        var chapters: [ParsedChapter] = []
        var current = ParsedChapter(title: nil, paragraphs: [])
        for paragraph in paragraphs {
            if isChapterHeading(paragraph) {
                if !current.paragraphs.isEmpty || current.title != nil { chapters.append(current) }
                current = ParsedChapter(title: paragraph, paragraphs: [])
            } else {
                current.paragraphs.append(paragraph)
            }
        }
        chapters.append(current)

        let cleaned = Chapterizer.clean(chapters)
        if cleaned.count <= 1 {
            let all = cleaned.flatMap(\.paragraphs)
            guard !all.isEmpty else { throw ImportError.noText }
            chapters = all.count > 40 ? Chapterizer.parts(from: all) : [ParsedChapter(title: nil, paragraphs: all)]
        } else {
            chapters = cleaned
        }
        return ParsedBook(title: title, chapters: chapters)
    }

    static func isChapterHeading(_ paragraph: String) -> Bool {
        paragraph.count <= 80
            && chapterHeading.firstMatch(in: paragraph, range: NSRange(paragraph.startIndex..., in: paragraph)) != nil
    }

    /// Blank lines separate paragraphs; hard-wrapped lines inside a paragraph are joined.
    /// Text without blank lines is treated as one paragraph per line.
    static func paragraphs(in text: String) -> [String] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        let hasBlankLines = lines.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard hasBlankLines else {
            return lines.map(HTMLTextExtractor.normalize).filter { !$0.isEmpty }
        }
        var result: [String] = []
        var current: [String] = []
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !current.isEmpty { result.append(joinLines(current)) }
                current = []
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty { result.append(joinLines(current)) }
        return result.filter { !$0.isEmpty }
    }

    static func joinLines(_ lines: [String]) -> String {
        var text = ""
        for line in lines.map({ $0.trimmingCharacters(in: .whitespaces) }) where !line.isEmpty {
            if text.hasSuffix("-"), let first = line.first, first.isLowercase, text.dropLast().last?.isLetter == true {
                text.removeLast()
                text += line
            } else {
                text += text.isEmpty ? line : " " + line
            }
        }
        return HTMLTextExtractor.normalize(text)
    }
}

/// Web articles: keeps the main text and drops navigation, captions and other short fragments.
public enum ArticleExtractor {
    public static func parse(html: String, url: URL) throws -> ParsedBook {
        let scoped = scope(html)
        let document = HTMLTextExtractor.extract(scoped)
        let blocks = document.blocks.filter { block in
            block.isHeading ? block.text.count >= 3 : (block.text.count >= 60 || (block.text.count >= 25 && endsSentence(block.text)))
        }
        // Drop leading headings so the title is not repeated as the first paragraph.
        var paragraphs = blocks.map(\.text)
        let title = metaTitle(in: html) ?? HTMLTextExtractor.extract(html).title ?? blocks.first(where: \.isHeading)?.text
            ?? url.host() ?? "Article"
        if let first = paragraphs.first, first == title { paragraphs.removeFirst() }
        guard paragraphs.reduce(0, { $0 + $1.count }) >= 200 else { throw ImportError.noText }
        let language = EPUBParser.matches(of: #"<html[^>]*\blang\s*=\s*["']([^"']+)["']"#, in: html).first
        let chapters = paragraphs.count > 60 ? Chapterizer.parts(from: paragraphs) : [ParsedChapter(title: nil, paragraphs: paragraphs)]
        return ParsedBook(title: title, author: url.host(), language: language, chapters: chapters)
    }

    private static func endsSentence(_ text: String) -> Bool {
        guard let last = text.last else { return false }
        return ".!?\"”»'’:".contains(last)
    }

    /// The `<article>` element, else `<main>`, else the whole page.
    private static func scope(_ html: String) -> String {
        for tag in ["article", "main"] {
            if let open = html.range(of: "<\(tag)", options: .caseInsensitive),
               let close = html.range(of: "</\(tag)>", options: [.caseInsensitive, .backwards]),
               open.lowerBound < close.lowerBound {
                let inner = String(html[open.lowerBound..<close.upperBound])
                if inner.count > 500 { return inner }
            }
        }
        return html
    }

    private static func metaTitle(in html: String) -> String? {
        let patterns = [
            #"<meta[^>]+property\s*=\s*["']og:title["'][^>]+content\s*=\s*["']([^"']+)["']"#,
            #"<meta[^>]+content\s*=\s*["']([^"']+)["'][^>]+property\s*=\s*["']og:title["']"#
        ]
        for pattern in patterns {
            if let raw = EPUBParser.matches(of: pattern, in: html).first {
                let text = HTMLTextExtractor.extract("<p>\(raw)</p>").blocks.first?.text
                if let text, !text.isEmpty { return text }
            }
        }
        return nil
    }
}

#if canImport(PDFKit)
/// PDFs with a text layer. Lines are re-joined into paragraphs; chapters follow the outline,
/// or every 10 pages when there is none.
public enum PDFTextParser {
    static let pagesPerPart = 10

    public static func parse(_ data: Data, fallbackTitle: String) throws -> ParsedBook {
        guard let document = PDFDocument(data: data) else { throw ImportError.unsupportedFile }
        if document.isEncrypted, document.isLocked { throw ImportError.drmProtected }
        let pageTexts = (0..<document.pageCount).map { document.page(at: $0)?.string ?? "" }
        guard pageTexts.joined().trimmingCharacters(in: .whitespacesAndNewlines).count >= 50 else { throw ImportError.noText }

        var ranges: [(title: String?, pages: Range<Int>)] = []
        if let outline = document.outlineRoot, outline.numberOfChildren >= 2 {
            let starts = (0..<outline.numberOfChildren).compactMap { index -> (String?, Int)? in
                guard let child = outline.child(at: index), let page = child.destination?.page else { return nil }
                return (child.label, document.index(for: page))
            }.sorted { $0.1 < $1.1 }
            for (offset, start) in starts.enumerated() {
                let end = offset + 1 < starts.count ? starts[offset + 1].1 : document.pageCount
                if end > start.1 { ranges.append((start.0, start.1..<end)) }
            }
            if let first = starts.first?.1, first > 0 { ranges.insert((nil, 0..<first), at: 0) }
        }
        if ranges.isEmpty {
            ranges = stride(from: 0, to: document.pageCount, by: pagesPerPart).map {
                (nil, $0..<min($0 + pagesPerPart, document.pageCount))
            }
        }

        let chapters = ranges.map { range in
            ParsedChapter(title: range.title, paragraphs: paragraphs(fromPages: Array(pageTexts[range.pages])))
        }
        let cleaned = Chapterizer.clean(chapters)
        guard !cleaned.isEmpty else { throw ImportError.noText }
        let attributes = document.documentAttributes
        let title = (attributes?[PDFDocumentAttribute.titleAttribute] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackTitle
        return ParsedBook(title: title, author: attributes?[PDFDocumentAttribute.authorAttribute] as? String, chapters: cleaned)
    }

    static func paragraphs(fromPages pages: [String]) -> [String] {
        let lines = pages.flatMap { page in
            page.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.allSatisfy(\.isNumber) }
        }
        guard !lines.isEmpty else { return [] }
        let lengths = lines.map(\.count).sorted()
        let typical = lengths[lengths.count * 3 / 4]

        var paragraphs: [String] = []
        var current: [String] = []
        for line in lines {
            current.append(line)
            let ends = line.last.map { ".!?:\"”»".contains($0) } ?? false
            if ends && line.count < typical * 4 / 5 {
                paragraphs.append(PlainTextParser.joinLines(current))
                current = []
            }
        }
        if !current.isEmpty { paragraphs.append(PlainTextParser.joinLines(current)) }
        return paragraphs.filter { !$0.isEmpty }
    }
}
#endif
