import BiliteralCore
import SwiftData
import SwiftUI
import Translation
import UIKit

// MARK: Word lookup

struct WordSheet: View {
    let lookup: WordLookup
    let book: Book
    let content: ChapterContent
    let narrator: Narrator
    var demo = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var meaning: String?
    @State private var failed = false
    @State private var configuration: TranslationSession.Configuration?
    @State private var added = false
    @State private var showDictionary = false

    private var wordLanguage: String { lookup.side == .source ? book.sourceLanguage : book.targetLanguage }
    private var otherLanguage: String { lookup.side == .source ? book.targetLanguage : book.sourceLanguage }
    private var lemma: String { WordTokenizer.lemma(of: lookup.word, language: wordLanguage) }
    private var sentence: SentenceRecord? {
        content.sentences.indices.contains(lookup.sentence) ? content.sentences[lookup.sentence] : nil
    }
    private var usage: (text: String, translation: String?) {
        guard let sentence else { return ("", nil) }
        return lookup.side == .source ? (sentence.text, sentence.translation) : (sentence.translation ?? "", sentence.text)
    }
    private var hasDictionary: Bool {
        UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: lemma)
            || UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: lookup.word)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(lookup.word)
                                .font(.largeTitle.bold())
                                .accessibilityIdentifier("lookupWord")
                            Button {
                                narrator.say(lookup.word, language: wordLanguage)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                            }
                            .accessibilityLabel(Text("Listen"))
                        }
                        if lemma != lookup.word.lowercased() {
                            Text("Dictionary form: \(lemma)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GroupBox {
                        Group {
                            if let meaning {
                                Text(meaning)
                                    .font(.title2.weight(.semibold))
                                    .accessibilityIdentifier("lookupMeaning")
                            } else if failed {
                                Text("No translation available offline for this word.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Label(LanguageCatalog.name(otherLanguage), systemImage: "translate")
                    }

                    if !usage.text.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("In context")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(highlighted(usage.text))
                                .font(.callout)
                            if let translation = usage.translation {
                                Text(translation)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        Button {
                            addCard()
                        } label: {
                            Label(added ? "Added to flashcards" : "I don't know this word",
                                  systemImage: added ? "checkmark.circle.fill" : "rectangle.stack.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(added || meaning == nil && !failed)
                        .accessibilityIdentifier("addCardButton")

                        if hasDictionary {
                            Button {
                                showDictionary = true
                            } label: {
                                Label("Open Dictionary", systemImage: "character.book.closed")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(lookup.word)
                meaning = response.targetText
            } catch {
                failed = true
            }
        }
        .sheet(isPresented: $showDictionary) {
            DictionaryView(term: hasDictionary && UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: lemma) ? lemma : lookup.word)
                .ignoresSafeArea()
        }
        .onAppear(perform: start)
    }

    private func start() {
        added = !demo && existingCard() != nil
        if demo {
            meaning = DemoContent.meaning(of: lookup.word, in: otherLanguage)
            if meaning == nil { failed = true }
        } else {
            configuration = TranslationSession.Configuration(source: Locale.Language(identifier: wordLanguage),
                                                             target: Locale.Language(identifier: otherLanguage))
        }
    }

    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: lookup.word) {
            attributed[range].font = .callout.bold()
            attributed[range].backgroundColor = Color.accentColor.opacity(0.18)
        }
        return attributed
    }

    private func existingCard() -> VocabCard? {
        let lemma = lemma
        let language = wordLanguage
        let descriptor = FetchDescriptor<VocabCard>(predicate: #Predicate { $0.lemma == lemma && $0.sourceLanguage == language })
        return try? context.fetch(descriptor).first
    }

    private func addCard() {
        guard existingCard() == nil else {
            added = true
            return
        }
        let card = VocabCard(term: lookup.word, lemma: lemma, meaning: meaning ?? "", context: usage.text,
                             contextTranslation: usage.translation, sourceLanguage: wordLanguage,
                             targetLanguage: otherLanguage, bookTitle: book.title)
        context.insert(card)
        try? context.save()
        withAnimation { added = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct DictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ controller: UIReferenceLibraryViewController, context: Context) {}
}

// MARK: Chapters

struct ChapterListSheet: View {
    let book: Book
    let chapters: [Chapter]
    let current: Int
    let isPro: Bool
    var onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List(chapters) { chapter in
                    Button {
                        onSelect(chapter.index)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(chapter.displayTitle(in: book))
                                    .foregroundStyle(.primary)
                                    .fontWeight(chapter.index == current ? .semibold : .regular)
                                if chapter.sentenceCount > 0 {
                                    Text(chapter.translatedCount >= chapter.sentenceCount
                                         ? String(localized: "Translated")
                                         : String(localized: "\(chapter.sentenceCount) sentences"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if !FreeTier.canRead(chapterIndex: chapter.index, isSample: book.isSample, isPro: isPro) {
                                Image(systemName: "lock.fill").foregroundStyle(.secondary)
                            } else if chapter.index == current {
                                Image(systemName: "book.fill").foregroundStyle(.tint)
                            }
                        }
                    }
                    .id(chapter.index)
                }
                .onAppear { proxy.scrollTo(current, anchor: .center) }
            }
            .navigationTitle("Chapters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: Reading settings

struct ReaderSettingsSheet: View {
    @Bindable var book: Book
    var onLanguagesChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.readerFont) private var fontRaw = ReaderFont.serif.rawValue
    @AppStorage(SettingsKey.readerTextSize) private var textSize = 19.0
    @AppStorage(SettingsKey.readerTheme) private var themeRaw = ReaderTheme.system.rawValue
    @AppStorage(SettingsKey.translationDisplay) private var displayRaw = TranslationDisplay.below.rawValue
    @AppStorage(SettingsKey.sideBySide) private var sideBySide = true
    @State private var languages: [String] = LanguageCatalog.fallback

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    Picker("Font", selection: $fontRaw) {
                        ForEach(ReaderFont.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $textSize, in: 14...30, step: 1)
                            .accessibilityLabel(Text("Text Size"))
                        Image(systemName: "textformat.size.larger")
                    }
                    Picker("Theme", selection: $themeRaw) {
                        ForEach(ReaderTheme.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Two pages side by side", isOn: $sideBySide)
                    Picker("Translation in one column", selection: $displayRaw) {
                        ForEach(TranslationDisplay.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                } header: {
                    Text("Layout")
                } footer: {
                    Text("Two pages are used on wide screens: iPad, an unfolded phone or a large iPhone in landscape.")
                }

                Section {
                    Picker("Book language", selection: Binding(get: { book.sourceLanguage }, set: { setSource($0) })) {
                        ForEach(options(including: book.sourceLanguage), id: \.self) { Text(LanguageCatalog.name($0)).tag($0) }
                    }
                    Picker("Translate into", selection: Binding(get: { book.targetLanguage }, set: { setTarget($0) })) {
                        ForEach(options(including: book.targetLanguage), id: \.self) { Text(LanguageCatalog.name($0)).tag($0) }
                    }
                } header: {
                    Text("Languages")
                } footer: {
                    Text("Translation runs on your device. The first time you use a language pair, iOS asks to download it.")
                }
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { languages = await LanguageCatalog.supported() }
        }
        .presentationDetents([.medium, .large])
    }

    private func options(including code: String) -> [String] {
        languages.contains(code) ? languages : [code] + languages
    }

    private func setSource(_ code: String) {
        guard code != book.sourceLanguage else { return }
        book.sourceLanguage = code
        for chapter in book.chapters ?? [] { chapter.translatedLanguage = nil }
        onLanguagesChanged()
    }

    private func setTarget(_ code: String) {
        guard code != book.targetLanguage else { return }
        book.targetLanguage = code
        UserDefaults.standard.set(code, forKey: SettingsKey.targetLanguage)
        onLanguagesChanged()
    }
}

// MARK: Explain

struct Explanation: Identifiable {
    let id = UUID()
    var sentence: String
    var translation: String?
    var source: String
    var target: String
}

struct ExplainSheet: View {
    let explanation: Explanation
    @Environment(\.dismiss) private var dismiss
    @State private var text: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(explanation.sentence)
                        .font(.body.italic())
                        .foregroundStyle(.secondary)
                    if let text {
                        Text(LocalizedStringKey(text))
                            .textSelection(.enabled)
                    } else if let error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            do {
                text = try await SentenceExplainer.explain(sentence: explanation.sentence, translation: explanation.translation,
                                                           source: explanation.source, target: explanation.target)
            } catch {
                self.error = String(localized: "Apple Intelligence couldn't explain this sentence. It may not support this language yet.")
            }
        }
    }
}
