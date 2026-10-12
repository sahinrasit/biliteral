import BiliteralCore
import Foundation
import Testing
@testable import Biliteral

@Suite struct DemoContentTests {
    /// The screenshot translations are indexed by sentence; they must match how chapter VII is split.
    @Test func demoTranslationsMatchTheSampleChapter() throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "SampleBook", withExtension: "epub")
            ?? Bundle.main.url(forResource: "SampleBook", withExtension: "epub"))
        let book = try EPUBParser.parse(Data(contentsOf: url))
        let chapter = book.chapters[DemoContent.chapterIndex]
        #expect(chapter.title == "Chapter VII: A Mad Tea-Party")
        let content = ChapterContent(paragraphs: chapter.paragraphs, language: "en")
        #expect(content.sentences[DemoContent.selectedSentence].text.hasPrefix("“Your hair wants cutting"))
        #expect(content.sentences[23].text.hasPrefix("“You might just as well say that ‘I see what I eat’"))
        for (language, lines) in DemoContent.translations {
            #expect(lines.count == 24, "\(language)")
        }
    }

    @Test func demoWordHasAMeaningInEveryLanguage() {
        for language in DemoContent.translations.keys {
            #expect(DemoContent.meaning(of: DemoContent.lookupTerm, in: language) != nil, "\(language)")
        }
    }
}

@Suite struct PricingTests {
    @Test func samplePricesFollowThePricingPlan() {
        let us = PaywallOption.samples(for: Locale(identifier: "en_US"))
        #expect(us.map(\.price) == ["$14.99", "$2.99"])
        #expect(us.first?.kind == .lifetime)
    }

    @Test func languageDefaults() {
        #expect(LanguageCatalog.code(for: Locale.Language(identifier: "zh-Hant-TW")) == "zh-Hant")
        #expect(LanguageCatalog.code(for: Locale.Language(identifier: "pt-BR")) == "pt")
        #expect(LanguageCatalog.pairLabel("en", "zh-Hans") == "EN → ZH")
    }
}

private final class BundleToken {}
