import BiliteralCore
import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID = UUID()
    var title: String = ""
    var author: String?
    /// BCP-47 codes, e.g. "en", "es", "zh-Hans".
    var sourceLanguage: String = "en"
    var targetLanguage: String = "es"
    /// epub, pdf, web, text
    var format: String = "epub"
    var addedAt: Date = Date.now
    var lastOpenedAt: Date?
    var currentChapter: Int = 0
    /// The bundled public-domain book. Always free; not counted against the free tier.
    var isSample: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Chapter.book) var chapters: [Chapter]? = []

    init(title: String, author: String?, sourceLanguage: String, targetLanguage: String, format: String, isSample: Bool = false) {
        self.title = title
        self.author = author
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.format = format
        self.isSample = isSample
    }

    var sortedChapters: [Chapter] {
        (chapters ?? []).sorted { $0.index < $1.index }
    }

    var progress: Double {
        let count = chapters?.count ?? 0
        guard count > 0, lastOpenedAt != nil else { return 0 }
        return Double(min(currentChapter + 1, count)) / Double(count)
    }
}

@Model
final class Chapter {
    var index: Int = 0
    var title: String?
    /// `ChapterContent` JSON: sentences and cached translations.
    @Attribute(.externalStorage) var contentData: Data?
    /// Language the cached translations are in; differs from the book's target after a language change.
    var translatedLanguage: String?
    var sentenceCount: Int = 0
    var translatedCount: Int = 0
    var book: Book?

    init(index: Int, title: String?, content: ChapterContent) {
        self.index = index
        self.title = title
        self.contentData = content.encoded()
        self.sentenceCount = content.sentences.count
    }

    var content: ChapterContent {
        get { ChapterContent.decode(contentData) }
        set {
            contentData = newValue.encoded()
            sentenceCount = newValue.sentences.count
            translatedCount = newValue.translatedCount
        }
    }

    func displayTitle(in book: Book) -> String {
        if let title, !title.isEmpty { return title }
        return String(localized: "Part \(index + 1)")
    }
}

@Model
final class VocabCard {
    var id: UUID = UUID()
    var term: String = ""
    var lemma: String = ""
    var meaning: String = ""
    var context: String = ""
    var contextTranslation: String?
    var sourceLanguage: String = "en"
    var targetLanguage: String = "es"
    var bookTitle: String?
    var createdAt: Date = Date.now
    var ease: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0
    var due: Date = Date.now
    var lastReviewedAt: Date?

    init(term: String, lemma: String, meaning: String, context: String, contextTranslation: String?,
         sourceLanguage: String, targetLanguage: String, bookTitle: String?) {
        self.term = term
        self.lemma = lemma
        self.meaning = meaning
        self.context = context
        self.contextTranslation = contextTranslation
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.bookTitle = bookTitle
    }

    var reviewState: ReviewState {
        get { ReviewState(ease: ease, interval: interval, repetitions: repetitions, due: due) }
        set {
            ease = newValue.ease
            interval = newValue.interval
            repetitions = newValue.repetitions
            due = newValue.due
        }
    }
}
