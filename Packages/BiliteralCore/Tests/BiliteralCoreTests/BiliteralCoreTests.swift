import Foundation
import Testing
@testable import BiliteralCore

private func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite struct EPUBTests {
    @Test func parsesChaptersAndSkipsCoverAndNav() throws {
        let book = try EPUBParser.parse(fixture("simple.epub"))
        #expect(book.title == "Simple Book")
        #expect(book.author == "Test Author")
        #expect(book.language == "en")
        #expect(book.chapters.count == 2)
        #expect(book.chapters[0].title == "Chapter One")
        #expect(book.chapters[1].title == "CHAPTER II. The Pool of Tears")
        #expect(book.chapters[1].paragraphs.count == 3)
        #expect(!book.chapters[1].paragraphs.joined().contains("no"), "script content must be skipped")
    }

    @Test func decodesEntities() throws {
        let book = try EPUBParser.parse(fixture("simple.epub"))
        #expect(book.chapters[0].paragraphs.last == "Café & crème brûlée — done.")
    }

    @Test func splitsSingleFileBooksAtHeadingsAndStripsGutenbergLicence() throws {
        let book = try EPUBParser.parse(fixture("gutenberg.epub"))
        #expect(book.chapters.map(\.title) == ["CHAPTER I.", "CHAPTER II.", "CHAPTER III."])
        let text = book.chapters.flatMap(\.paragraphs).joined()
        #expect(!text.contains("Licence"))
        #expect(!text.contains("Project Gutenberg"))
    }

    @Test func parsesBundledSampleBook() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().appendingPathComponent("../../../../Biliteral/Resources/SampleBook.epub")
        let book = try EPUBParser.parse(Data(contentsOf: url))
        #expect(book.title == "Alice’s Adventures in Wonderland")
        #expect(book.chapters.count == 12)
        #expect(book.chapters[0].title == "Chapter I: Down the Rabbit-Hole")
        #expect(book.chapters[0].paragraphs[0].hasPrefix("Alice was beginning to get very tired"))
        let content = ChapterContent(paragraphs: book.chapters[0].paragraphs, language: "en")
        #expect(content.sentences.count > 60)
    }

    @Test func rejectsDRM() throws {
        #expect(throws: ImportError.drmProtected) { try EPUBParser.parse(fixture("drm.epub")) }
    }

    @Test func rejectsNonZip() {
        #expect(throws: ImportError.unsupportedFile) { try EPUBParser.parse(Data("hello".utf8)) }
    }

    @Test func resolvesRelativeHrefs() {
        #expect(EPUBParser.resolve("../Text/ch%201.xhtml#p3", relativeTo: "OEBPS/Styles") == "OEBPS/Text/ch 1.xhtml")
        #expect(EPUBParser.resolve("ch1.xhtml", relativeTo: "") == "ch1.xhtml")
    }
}

@Suite struct HTMLTests {
    @Test func headingsAndParagraphs() {
        let result = HTMLTextExtractor.extract("<html><head><title>T &amp; U</title></head><body><h2>Head<br/>Line</h2><p>One\n  two</p><div>Three <b>bold</b></div><!-- <p>x</p> --></body></html>")
        #expect(result.title == "T & U")
        #expect(result.blocks == [TextBlock(.heading(2), "Head Line"), TextBlock(.paragraph, "One two"), TextBlock(.paragraph, "Three bold")])
    }

    @Test func toleratesBrokenMarkup() {
        let result = HTMLTextExtractor.extract("<p>a < b & c &unknown; <p>next")
        #expect(result.blocks.map(\.text) == ["a < b & c &unknown;", "next"])
    }

    @Test func articleKeepsMainTextOnly() throws {
        let body = String(repeating: "<p>This is a long paragraph of the article that should be kept by the extractor.</p>", count: 4)
        let html = """
        <html lang="en-GB"><head><meta property="og:title" content="Real Title"></head><body>
        <nav><a>Home</a></nav><div>Subscribe</div><article><h1>Real Title</h1>\(body)<p>Share</p></article></body></html>
        """
        let book = try ArticleExtractor.parse(html: html, url: URL(string: "https://example.com/a")!)
        #expect(book.title == "Real Title")
        #expect(book.language == "en-GB")
        #expect(book.chapters.count == 1)
        #expect(book.chapters[0].paragraphs.count == 4)
    }
}

@Suite struct PlainTextTests {
    @Test func joinsWrappedLinesAndDetectsChapters() throws {
        let filler = String(repeating: "Alice was beginning to get very tired of sitting by her sister on the bank. ", count: 3)
        let text = "CHAPTER I.\n\n\(filler)\nwrapped line here.\n\nCHAPTER II.\n\n\(filler)\n\nSecond para-\ngraph ends."
        let book = try PlainTextParser.parse(text, title: "Pasted")
        #expect(book.chapters.count == 2)
        #expect(book.chapters[0].title == "CHAPTER I.")
        #expect(book.chapters[0].paragraphs[0].hasSuffix("bank. wrapped line here."))
        #expect(book.chapters[1].paragraphs.last == "Second paragraph ends.")
    }

    @Test func shortPasteIsOneChapter() throws {
        let book = try PlainTextParser.parse("Hola. ¿Qué tal?\nMuy bien.", title: "Pasted")
        #expect(book.chapters.count == 1)
        #expect(book.chapters[0].paragraphs == ["Hola. ¿Qué tal?", "Muy bien."])
    }

    @Test func emptyTextThrows() {
        #expect(throws: ImportError.noText) { try PlainTextParser.parse("  \n\n ", title: "x") }
    }

    @Test func longTextWithoutHeadingsIsSplitIntoParts() throws {
        let paragraph = String(repeating: "word ", count: 100)
        let text = Array(repeating: paragraph, count: 60).joined(separator: "\n\n")
        let book = try PlainTextParser.parse(text, title: "Long")
        #expect(book.chapters.count == 3, "6,000 words in parts of 2,500")
        #expect(book.chapters.allSatisfy { $0.title == nil })
    }
}

@Suite struct LanguageTests {
    @Test func splitsSentencesKeepingAbbreviations() {
        let sentences = SentenceSplitter.split("Mr. Smith went home. He was tired! Was he? Yes.", language: "en")
        #expect(sentences == ["Mr. Smith went home.", "He was tired!", "Was he?", "Yes."])
    }

    @Test func keepsQuotesWithTheirSentence() {
        let sentences = SentenceSplitter.split("“Oh dear! Oh dear! I shall be late!” said the Rabbit.", language: "en")
        #expect(sentences.first?.hasPrefix("“Oh dear!") == true)
        #expect(sentences.joined(separator: " ").contains("I shall be late!”"))
    }

    @Test func mergesLowercaseContinuations() {
        let sentences = SentenceSplitter.split("“Well!” thought Alice to herself. “I wonder?” she said aloud.", language: "en")
        #expect(sentences == ["“Well!” thought Alice to herself.", "“I wonder?” she said aloud."])
    }

    @Test func detectsLanguage() {
        #expect(LanguageGuesser.dominantLanguage(of: "Ceci est une phrase en français, avec quelques mots de plus.") == "fr")
    }

    @Test func lemmatizes() {
        #expect(WordTokenizer.lemma(of: "ran", language: "en") == "run")
        #expect(WordTokenizer.wordRanges(in: "Hello, world!").count == 2)
    }
}

@Suite struct ChapterContentTests {
    private func content() -> ChapterContent {
        ChapterContent(paragraphs: ["One. Two. Three. Four.", "Five."], language: "en")
    }

    @Test func splitsIntoSentencesPerParagraph() {
        let content = content()
        #expect(content.sentences.map(\.text) == ["One.", "Two.", "Three.", "Four.", "Five."])
        #expect(content.paragraphCount == 2)
    }

    @Test func rowsSpreadSentencesEvenly() {
        let rows = content().rows(maxSentences: 3)
        #expect(rows.map(\.sentences) == [0..<2, 2..<4, 4..<5])
        #expect(rows.map(\.startsParagraph) == [true, false, true])
    }

    @Test func appliesResponsesAndMarksFailures() {
        var content = ChapterContent(sentences: [
            SentenceRecord(paragraph: 0, text: "Hello there."),
            SentenceRecord(paragraph: 0, text: "This one stays the same."),
            SentenceRecord(paragraph: 0, text: "Bye.")
        ])
        content.apply([(0, "Hola."), (1, "This one stays the same."), (2, "  ")])
        #expect(content.sentences[0].translation == "Hola.")
        #expect(content.sentences[1].failed)
        #expect(content.sentences[2].failed)
        #expect(content.pendingIndices == [1, 2])
        #expect(content.batches(skipFailed: true).isEmpty)
        #expect(content.batches() == [[1, 2]])
    }

    @Test func batchesRespectLimits() {
        let content = ChapterContent(sentences: (0..<10).map { SentenceRecord(paragraph: $0, text: String(repeating: "a", count: 100)) })
        #expect(content.batches(maxSentences: 4, maxCharacters: 10_000).map(\.count) == [4, 4, 2])
        #expect(content.batches(maxSentences: 40, maxCharacters: 250).map(\.count) == [2, 2, 2, 2, 2])
    }

    @Test func roundTripsThroughJSON() {
        var content = content()
        content.apply([(0, "Uno.")])
        #expect(ChapterContent.decode(content.encoded()) == content)
        #expect(ChapterContent.decode(nil).sentences.isEmpty)
    }
}

@Suite struct PolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func sm2Progression() {
        var state = ReviewState(due: now)
        state = SRSScheduler.review(state, grade: .good, now: now)
        #expect(state.interval == 1)
        state = SRSScheduler.review(state, grade: .good, now: now)
        #expect(state.interval == 6)
        state = SRSScheduler.review(state, grade: .good, now: now)
        #expect(state.interval == 15)
        #expect(state.due == now.addingTimeInterval(15 * 86_400))
    }

    @Test func againResetsAndLowersEase() {
        let learned = ReviewState(ease: 2.5, interval: 20, repetitions: 4, due: now)
        let state = SRSScheduler.review(learned, grade: .again, now: now)
        #expect(state.repetitions == 0)
        #expect(state.due == now.addingTimeInterval(SRSScheduler.relearnDelay))
        #expect(state.ease < 2.5)
        #expect(SRSScheduler.review(ReviewState(ease: 1.3, due: now), grade: .again, now: now).ease == 1.3)
    }

    @Test func freeTier() {
        #expect(FreeTier.canImport(importedBooks: 0, isPro: false))
        #expect(!FreeTier.canImport(importedBooks: 1, isPro: false))
        #expect(FreeTier.canImport(importedBooks: 9, isPro: true))
        #expect(FreeTier.canRead(chapterIndex: 2, isSample: false, isPro: false))
        #expect(!FreeTier.canRead(chapterIndex: 3, isSample: false, isPro: false))
        #expect(FreeTier.canRead(chapterIndex: 9, isSample: true, isPro: false))
        #expect(!FreeTier.canReview(reviewedToday: 20, isPro: false))
        #expect(FreeTier.canReview(reviewedToday: 20, isPro: true))
    }
}
