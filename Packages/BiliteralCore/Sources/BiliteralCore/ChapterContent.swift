import Foundation

/// One source sentence and its cached translation.
public struct SentenceRecord: Codable, Hashable, Sendable {
    public var paragraph: Int
    public var text: String
    public var translation: String?
    /// Set when the system translator returned nothing usable; retried on the next pass.
    public var failed: Bool

    public init(paragraph: Int, text: String, translation: String? = nil, failed: Bool = false) {
        self.paragraph = paragraph
        self.text = text
        self.translation = translation
        self.failed = failed
    }
}

/// Rows the reader lays out side by side. A row never crosses a paragraph and holds at most
/// `maxSentences`, so the original and the translation stay vertically close.
public struct ReaderRow: Hashable, Identifiable, Sendable {
    public var sentences: Range<Int>
    public var paragraph: Int
    /// First row of its paragraph: gets paragraph spacing above it.
    public var startsParagraph: Bool
    public var id: Int { sentences.lowerBound }
}

/// The sentences of a chapter with their translations, stored as one JSON blob per chapter.
public struct ChapterContent: Codable, Equatable, Sendable {
    public var sentences: [SentenceRecord]

    public init(sentences: [SentenceRecord]) {
        self.sentences = sentences
    }

    public init(paragraphs: [String], language: String?) {
        var sentences: [SentenceRecord] = []
        for (index, paragraph) in paragraphs.enumerated() {
            let parts = SentenceSplitter.split(paragraph, language: language)
            sentences += (parts.isEmpty ? [paragraph] : parts).map { SentenceRecord(paragraph: index, text: $0) }
        }
        self.sentences = sentences
    }

    public static func decode(_ data: Data?) -> ChapterContent {
        guard let data, let content = try? JSONDecoder().decode(ChapterContent.self, from: data) else {
            return ChapterContent(sentences: [])
        }
        return content
    }

    public func encoded() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    public var paragraphCount: Int { (sentences.last?.paragraph ?? -1) + 1 }

    public var translatedCount: Int { sentences.filter { $0.translation != nil }.count }

    public var isFullyTranslated: Bool { sentences.allSatisfy { $0.translation != nil } }

    /// Indices still waiting for a translation, in reading order.
    public var pendingIndices: [Int] {
        sentences.indices.filter { sentences[$0].translation == nil }
    }

    public func rows(maxSentences: Int = 3) -> [ReaderRow] {
        var rows: [ReaderRow] = []
        var start = 0
        while start < sentences.count {
            let paragraph = sentences[start].paragraph
            var end = start
            while end < sentences.count, sentences[end].paragraph == paragraph { end += 1 }
            var chunkStart = start
            let count = end - start
            // Spread sentences evenly: 4 → 2+2 rather than 3+1.
            let chunks = Int((Double(count) / Double(maxSentences)).rounded(.up))
            for chunk in 0..<chunks {
                let size = count / chunks + (chunk < count % chunks ? 1 : 0)
                rows.append(ReaderRow(sentences: chunkStart..<(chunkStart + size), paragraph: paragraph, startsParagraph: chunk == 0))
                chunkStart += size
            }
            start = end
        }
        return rows
    }

    /// Writes translator responses keyed by sentence index. Empty output, or output identical
    /// to a source sentence of several words, is marked failed so it can be retried.
    public mutating func apply(_ responses: [(index: Int, text: String)]) {
        for response in responses where sentences.indices.contains(response.index) {
            let source = sentences[response.index].text
            let output = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let untouched = output == source && source.split(separator: " ").count >= 4
            if output.isEmpty || untouched {
                sentences[response.index].failed = true
            } else {
                sentences[response.index].translation = output
                sentences[response.index].failed = false
            }
        }
    }

    public mutating func clearTranslations() {
        for index in sentences.indices {
            sentences[index].translation = nil
            sentences[index].failed = false
        }
    }

    /// Batches of pending sentence indices for one translator call.
    public func batches(maxSentences: Int = 40, maxCharacters: Int = 4_000, skipFailed: Bool = false) -> [[Int]] {
        var batches: [[Int]] = []
        var current: [Int] = []
        var characters = 0
        for index in pendingIndices where !(skipFailed && sentences[index].failed) {
            let length = sentences[index].text.count
            if !current.isEmpty, current.count >= maxSentences || characters + length > maxCharacters {
                batches.append(current)
                current = []
                characters = 0
            }
            current.append(index)
            characters += length
        }
        if !current.isEmpty { batches.append(current) }
        return batches
    }
}
