import Foundation

public struct ParsedChapter: Equatable, Sendable {
    /// `nil` when the source has no heading; the app shows a localized "Part n".
    public var title: String?
    public var paragraphs: [String]

    public init(title: String?, paragraphs: [String]) {
        self.title = title
        self.paragraphs = paragraphs
    }

    var characterCount: Int { paragraphs.reduce(0) { $0 + $1.count } }
}

public struct ParsedBook: Equatable, Sendable {
    public var title: String
    public var author: String?
    /// BCP-47 code from the file's metadata, if any.
    public var language: String?
    public var chapters: [ParsedChapter]

    public init(title: String, author: String? = nil, language: String? = nil, chapters: [ParsedChapter]) {
        self.title = title
        self.author = author
        self.language = language
        self.chapters = chapters
    }

    /// Text used for language detection.
    public var sample: String {
        var text = ""
        for paragraph in chapters.lazy.flatMap(\.paragraphs) {
            text += paragraph + "\n"
            if text.count > 2_000 { break }
        }
        return text
    }
}

public enum ImportError: Error, Equatable, Sendable {
    /// The EPUB is encrypted (Adobe/Apple/Kindle DRM).
    case drmProtected
    case unsupportedFile
    /// No readable text, e.g. a scanned PDF.
    case noText
    case unreadable
}

/// Shared clean-up for every importer.
enum Chapterizer {
    static let minimumChapterCharacters = 120
    static let wordsPerPart = 2_500

    /// Drops Project Gutenberg header/licence, near-empty chapters and table-of-contents pages.
    static func clean(_ chapters: [ParsedChapter]) -> [ParsedChapter] {
        var chapters = stripGutenbergBoilerplate(chapters)
        let substantial = chapters.filter { $0.characterCount >= minimumChapterCharacters && !looksLikeContents($0) }
        if !substantial.isEmpty { chapters = substantial }
        return chapters.filter { !$0.paragraphs.isEmpty }
    }

    private static func looksLikeContents(_ chapter: ParsedChapter) -> Bool {
        guard chapter.paragraphs.count >= 6 else { return false }
        let average = chapter.characterCount / chapter.paragraphs.count
        let endsWithPunctuation = chapter.paragraphs.filter { $0.last.map { ".!?\"”»'’".contains($0) } ?? false }.count
        return average < 40 && endsWithPunctuation * 3 < chapter.paragraphs.count
    }

    private static func stripGutenbergBoilerplate(_ chapters: [ParsedChapter]) -> [ParsedChapter] {
        func isMarker(_ text: String, _ kind: String) -> Bool {
            let upper = text.uppercased()
            return upper.hasPrefix("***") && upper.contains("\(kind) OF TH") && upper.contains("PROJECT GUTENBERG")
        }
        var result: [ParsedChapter] = []
        var started = !chapters.contains { $0.paragraphs.contains { isMarker($0, "START") } }
        for chapter in chapters {
            var kept: [String] = []
            for paragraph in chapter.paragraphs {
                if isMarker(paragraph, "START") {
                    started = true
                    kept.removeAll()
                    continue
                }
                if isMarker(paragraph, "END") {
                    if !kept.isEmpty { result.append(ParsedChapter(title: chapter.title, paragraphs: kept)) }
                    return result
                }
                if started { kept.append(paragraph) }
            }
            if started, !kept.isEmpty { result.append(ParsedChapter(title: chapter.title, paragraphs: kept)) }
        }
        return result
    }

    /// Splits a long chapter-less text into parts of roughly `wordsPerPart` words.
    static func parts(from paragraphs: [String]) -> [ParsedChapter] {
        var chapters: [ParsedChapter] = []
        var current: [String] = []
        var words = 0
        for paragraph in paragraphs {
            current.append(paragraph)
            words += paragraph.split(whereSeparator: \.isWhitespace).count
            if words >= wordsPerPart {
                chapters.append(ParsedChapter(title: nil, paragraphs: current))
                current = []
                words = 0
            }
        }
        if !current.isEmpty {
            // Fold a short tail into the previous part.
            if words < wordsPerPart / 4, var last = chapters.popLast() {
                last.paragraphs += current
                chapters.append(last)
            } else {
                chapters.append(ParsedChapter(title: nil, paragraphs: current))
            }
        }
        return chapters
    }
}
