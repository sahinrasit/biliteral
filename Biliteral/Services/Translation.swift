import BiliteralCore
import Foundation
import Observation
import SwiftData
import SwiftUI
import Translation

enum LanguageCatalog {
    /// Used when the system list is unavailable (e.g. in the simulator).
    static let fallback = ["en", "es", "fr", "de", "it", "pt", "nl", "tr", "pl", "ru", "uk", "ar", "zh-Hans", "zh-Hant",
                           "ja", "ko", "hi", "id", "th", "vi"]

    /// Languages the system translator supports, as stable codes ("en", "zh-Hans").
    static func supported() async -> [String] {
        let languages = await LanguageAvailability().supportedLanguages
        var codes: [String] = []
        for language in languages {
            let code = code(for: language)
            if !codes.contains(code) { codes.append(code) }
        }
        let result = codes.isEmpty ? fallback : codes
        return result.sorted { name($0).localizedStandardCompare(name($1)) == .orderedAscending }
    }

    static func code(for language: Locale.Language) -> String {
        guard let base = language.languageCode?.identifier else { return language.minimalIdentifier }
        if base == "zh" { return language.script?.identifier == "Hant" ? "zh-Hant" : "zh-Hans" }
        return base
    }

    static func name(_ code: String) -> String {
        let name = Locale.current.localizedString(forIdentifier: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    /// Short label for book covers: "EN → ES".
    static func pairLabel(_ source: String, _ target: String) -> String {
        "\(source.prefix(2).uppercased()) → \(target.prefix(2).uppercased())"
    }

    /// The device language, unless the book is already in it; then English (or Spanish for English books).
    static func defaultTarget(for source: String) -> String {
        let saved = UserDefaults.standard.string(forKey: SettingsKey.targetLanguage)
        let device = Locale.preferredLanguages.first.map { code(for: Locale.Language(identifier: $0)) } ?? "en"
        for candidate in [saved, device].compactMap({ $0 }) where BookImporter.baseCode(candidate) != BookImporter.baseCode(source) {
            return candidate
        }
        return BookImporter.baseCode(source) == "en" ? "es" : "en"
    }
}

/// Translates a chapter sentence by sentence and caches the result in SwiftData.
/// The session comes from SwiftUI's `.translationTask`, which also shows the system's
/// language-download prompt the first time a pair is used.
@MainActor
@Observable
final class ChapterTranslator {
    enum Phase: Equatable {
        case idle
        case translating
        case done
        case unsupported
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var content = ChapterContent(sentences: [])
    var configuration: TranslationSession.Configuration?

    private var chapter: Chapter?
    private var next: Chapter?
    private var source = "en"
    private var target = "es"
    private var generation = 0

    var progress: Double {
        content.sentences.isEmpty ? 1 : Double(content.translatedCount) / Double(content.sentences.count)
    }

    /// Shows a chapter; starts translating whatever is missing. `prefetch` is translated afterwards.
    func load(_ chapter: Chapter, of book: Book, prefetch: Chapter?, translate: Bool = true) {
        generation += 1
        self.chapter = chapter
        self.next = prefetch
        source = book.sourceLanguage
        target = book.targetLanguage
        resetIfLanguageChanged(chapter)
        content = chapter.content
        if content.isFullyTranslated || !translate {
            phase = .done
            if translate, prefetch.map({ $0.translatedCount < $0.sentenceCount }) == true { requestSession() }
            return
        }
        requestSession()
    }

    func retry() {
        requestSession()
    }

    private func resetIfLanguageChanged(_ chapter: Chapter) {
        guard chapter.translatedLanguage != target else { return }
        var content = chapter.content
        content.clearTranslations()
        chapter.content = content
        chapter.translatedLanguage = target
    }

    private func requestSession() {
        let sourceLanguage = Locale.Language(identifier: source)
        let targetLanguage = Locale.Language(identifier: target)
        Task {
            let status = await LanguageAvailability().status(from: sourceLanguage, to: targetLanguage)
            guard status != .unsupported else {
                phase = .unsupported
                return
            }
            if !content.isFullyTranslated { phase = .translating }
            if configuration?.source == sourceLanguage, configuration?.target == targetLanguage {
                configuration?.invalidate()
            } else {
                configuration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
            }
        }
    }

    /// Called from `.translationTask` with a ready session.
    func run(_ session: TranslationSession) async {
        let generation = generation
        guard let chapter else { return }
        if !content.isFullyTranslated {
            phase = .translating
            do {
                try await translate(chapter, with: session, generation: generation, isCurrent: true)
            } catch {
                guard generation == self.generation else { return }
                phase = .failed(Self.message(for: error, target: target))
                return
            }
            guard generation == self.generation else { return }
            phase = .done
        }
        // Read-ahead so the next chapter opens already translated.
        if let next, next.translatedCount < next.sentenceCount {
            try? await translate(next, with: session, generation: generation, isCurrent: false)
        }
    }

    private func translate(_ chapter: Chapter, with session: TranslationSession, generation: Int, isCurrent: Bool) async throws {
        resetIfLanguageChanged(chapter)
        var working = isCurrent ? content : chapter.content
        for batch in working.batches() {
            let requests = batch.map { TranslationSession.Request(sourceText: working.sentences[$0].text, clientIdentifier: String($0)) }
            let responses = try await session.translations(from: requests)
            guard generation == self.generation else { return }
            working.apply(responses.compactMap { response in
                response.clientIdentifier.flatMap(Int.init).map { ($0, response.targetText) }
            })
            chapter.content = working
            if isCurrent { content = working }
        }
        // Sentences the batch left untouched get one more try on their own; whatever comes back is kept.
        for index in working.pendingIndices {
            guard let response = try? await session.translate(working.sentences[index].text) else { continue }
            guard generation == self.generation else { return }
            working.sentences[index].translation = response.targetText
            working.sentences[index].failed = false
        }
        chapter.content = working
        if isCurrent { content = working }
        try? chapter.modelContext?.save()
    }

    /// Demo and screenshots: show stored content without a translator.
    func show(_ content: ChapterContent) {
        self.content = content
        phase = .done
    }

    static func message(for error: Error, target: String) -> String {
        let language = LanguageCatalog.name(target)
        return String(localized: "Translation into \(language) isn't available right now. Download the language in Settings › Apps › Translate › Downloaded Languages, or connect to the internet once and try again.")
    }
}
