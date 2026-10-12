import BiliteralCore
import Foundation
import SwiftData
import UniformTypeIdentifiers

/// A parsed book waiting for the reader to confirm its languages.
struct PendingImport: Identifiable {
    let id = UUID()
    var book: ParsedBook
    var format: String
    var detectedLanguage: String?
}

enum BookImporter {
    static let fileTypes: [UTType] = [.epub, .pdf, .plainText]

    /// Parses a file picked in Files or opened from another app. Runs off the main actor.
    static func parseFile(at url: URL) async throws -> PendingImport {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let name = url.deletingPathExtension().lastPathComponent
        let type = UTType(filenameExtension: url.pathExtension.lowercased())
        return try await Task.detached(priority: .userInitiated) {
            if type?.conforms(to: .epub) == true || url.pathExtension.lowercased() == "epub" {
                return pending(try EPUBParser.parse(data, fallbackTitle: name), format: "epub")
            }
            if type?.conforms(to: .pdf) == true {
                return pending(try PDFTextParser.parse(data, fallbackTitle: name), format: "pdf")
            }
            if type?.conforms(to: .text) == true {
                return pending(try PlainTextParser.parse(data.decodedString, title: name), format: "text")
            }
            throw ImportError.unsupportedFile
        }.value
    }

    static func parseText(_ text: String, title: String) async throws -> PendingImport {
        try await Task.detached(priority: .userInitiated) {
            pending(try PlainTextParser.parse(text, title: title), format: "text")
        }.value
    }

    static func parseArticle(at url: URL) async throws -> PendingImport {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
                         forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try await Task.detached(priority: .userInitiated) {
            pending(try ArticleExtractor.parse(html: data.decodedString, url: url), format: "web")
        }.value
    }

    private static func pending(_ book: ParsedBook, format: String) -> PendingImport {
        let detected = LanguageGuesser.dominantLanguage(of: book.sample) ?? book.language.map(baseCode)
        return PendingImport(book: book, format: format, detectedLanguage: detected)
    }

    /// Splits the chapters into sentences and stores the book.
    @MainActor
    static func save(_ pending: PendingImport, source: String, target: String, isSample: Bool = false,
                     into context: ModelContext) async -> Book {
        let parsed = pending.book
        let contents = await Task.detached(priority: .userInitiated) {
            parsed.chapters.map { ChapterContent(paragraphs: $0.paragraphs, language: source) }
        }.value
        let book = Book(title: parsed.title, author: parsed.author, sourceLanguage: source, targetLanguage: target,
                        format: pending.format, isSample: isSample)
        context.insert(book)
        for (index, chapter) in parsed.chapters.enumerated() {
            let stored = Chapter(index: index, title: chapter.title, content: contents[index])
            stored.translatedLanguage = target
            book.chapters?.append(stored)
        }
        try? context.save()
        return book
    }

    /// Imports the bundled sample book once.
    @MainActor
    static func installSampleIfNeeded(into context: ModelContext, target: String) async -> Book? {
        let existing = try? context.fetch(FetchDescriptor<Book>(predicate: #Predicate { $0.isSample }))
        if let book = existing?.first { return book }
        guard let url = Bundle.main.url(forResource: "SampleBook", withExtension: "epub"),
              let data = try? Data(contentsOf: url),
              let parsed = try? EPUBParser.parse(data)
        else { return nil }
        let pending = PendingImport(book: parsed, format: "epub", detectedLanguage: "en")
        let book = await save(pending, source: "en", target: target, isSample: true, into: context)
        book.addedAt = .distantPast
        return book
    }

    static func baseCode(_ code: String) -> String {
        Locale.Language(identifier: code).languageCode?.identifier ?? code
    }

    static func message(for error: Error) -> String {
        switch error as? ImportError {
        case .drmProtected:
            return String(localized: "This book is protected by DRM, so it can't be opened. Books bought in big e-book stores are usually protected. Try a DRM-free EPUB, for example from Project Gutenberg or Standard Ebooks.")
        case .noText:
            return String(localized: "No readable text was found. Scanned PDFs without a text layer aren't supported yet.")
        case .unsupportedFile, .unreadable:
            return String(localized: "This file couldn't be read. Biliteral opens EPUB, PDF and plain-text files.")
        case nil:
            if error is URLError {
                return String(localized: "The page couldn't be loaded. Check the address and your connection.")
            }
            return error.localizedDescription
        }
    }
}

extension Data {
    var decodedString: String {
        if let text = String(data: self, encoding: .utf8) { return text }
        return String(data: self, encoding: .windowsCP1252) ?? String(decoding: self, as: UTF8.self)
    }
}
