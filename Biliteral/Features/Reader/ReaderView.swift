import BiliteralCore
import SwiftData
import SwiftUI
import Translation

struct WordLookup: Identifiable {
    let id = UUID()
    var word: String
    var sentence: Int
    var side: ReaderSide
}

struct ReaderView: View {
    @Bindable var book: Book
    var demo = false
    /// Screenshot entry points: "select", "word".
    var demoScreen: String?
    var forceSingleColumn = false

    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var purchases
    @AppStorage(SettingsKey.readerFont) private var fontRaw = ReaderFont.serif.rawValue
    @AppStorage(SettingsKey.readerTextSize) private var textSize = 19.0
    @AppStorage(SettingsKey.readerTheme) private var themeRaw = ReaderTheme.system.rawValue
    @AppStorage(SettingsKey.translationDisplay) private var displayRaw = TranslationDisplay.below.rawValue
    @AppStorage(SettingsKey.sideBySide) private var sideBySide = true

    @State private var translator = ChapterTranslator()
    @State private var narrator = Narrator()
    @State private var chapters: [Chapter] = []
    @State private var chapterIndex = 0
    @State private var rows: [ReaderRow] = []
    @State private var selected: Int?
    @State private var lookup: WordLookup?
    @State private var showChapters = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var explanation: Explanation?
    /// Row to bring into view once the reader has laid out (demo selection).
    @State private var scrollRequest: Int?

    private var style: ReaderStyle {
        ReaderStyle(font: ReaderFont(rawValue: fontRaw) ?? .serif, size: textSize, theme: ReaderTheme(rawValue: themeRaw) ?? .system)
    }

    private var display: TranslationDisplay { TranslationDisplay(rawValue: displayRaw) ?? .below }
    private var chapter: Chapter? { chapters.indices.contains(chapterIndex) ? chapters[chapterIndex] : nil }

    var body: some View {
        GeometryReader { geometry in
            let twoPage = sideBySide && !forceSingleColumn && geometry.size.width >= 600
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        header(twoPage: twoPage)
                            .id("top")
                        ForEach(rows) { row in
                            ReaderRowView(row: row, content: translator.content, twoPage: twoPage, display: display,
                                          selected: selected, speaking: narrator.speakingIndex, style: style)
                                .id(row.id)
                        }
                        footer
                    }
                    .padding(.horizontal, twoPage ? 36 : 22)
                    .padding(.bottom, 120)
                    .frame(maxWidth: twoPage ? 1180 : 700)
                    .frame(maxWidth: .infinity)
                    .background(alignment: .top) {
                        if twoPage {
                            Rectangle()
                                .fill(style.theme.secondaryText.opacity(0.18))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                        }
                    }
                }
                .scrollIndicators(.automatic)
                .onChange(of: chapterIndex) { proxy.scrollTo("top", anchor: .top) }
                .task(id: scrollRequest) {
                    guard let scrollRequest else { return }
                    try? await Task.sleep(for: .milliseconds(300))
                    proxy.scrollTo(scrollRequest, anchor: .center)
                }
                .onChange(of: narrator.speakingIndex) { _, index in
                    guard let index, let row = rows.last(where: { $0.sentences.lowerBound <= index }) else { return }
                    withAnimation { proxy.scrollTo(row.id, anchor: .center) }
                }
            }
        }
        .background(style.theme.background.ignoresSafeArea())
        .environment(\.openURL, OpenURLAction { url in
            handle(url)
            return .handled
        })
        .safeAreaInset(edge: .bottom) { bottomBar }
        .navigationTitle(chapter?.displayTitle(in: book) ?? book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(style.theme == .system ? .automatic : .visible, for: .navigationBar)
        .toolbarBackground(style.theme.background, for: .navigationBar)
        .toolbarColorScheme(style.theme.colorScheme, for: .navigationBar)
        .toolbar { toolbarContent }
        .translationTask(translator.configuration) { session in
            await translator.run(session)
        }
        .sheet(item: $lookup) { lookup in
            WordSheet(lookup: lookup, book: book, content: translator.content, narrator: narrator, demo: demo)
        }
        .sheet(isPresented: $showChapters) {
            ChapterListSheet(book: book, chapters: chapters, current: chapterIndex, isPro: purchases.isPro) { index in
                showChapters = false
                goTo(index)
            }
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsSheet(book: book) { reloadChapter() }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(item: $explanation) { ExplainSheet(explanation: $0) }
        .onAppear(perform: start)
        .onDisappear {
            narrator.stop()
            try? context.save()
        }
    }

    // MARK: Layout pieces

    private func header(twoPage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(book.title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(style.theme.secondaryText)
            if let chapter {
                Text(chapter.displayTitle(in: book))
                    .font(style.font(scale: 1.35).weight(.semibold))
                    .foregroundStyle(style.theme.text)
            }
            if twoPage {
                HStack(spacing: 56) {
                    languageLabel(book.sourceLanguage)
                    languageLabel(book.targetLanguage)
                }
                .padding(.top, 10)
            }
        }
        .padding(.top, 24)
    }

    private func languageLabel(_ code: String) -> some View {
        Text(LanguageCatalog.name(code))
            .font(.caption.weight(.medium))
            .foregroundStyle(style.theme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Divider().padding(.vertical, 24)
            if chapterIndex + 1 < chapters.count {
                Button {
                    goTo(chapterIndex + 1)
                } label: {
                    Label {
                        Text("Next: \(chapters[chapterIndex + 1].displayTitle(in: book))")
                    } icon: {
                        Image(systemName: FreeTier.canRead(chapterIndex: chapterIndex + 1, isSample: book.isSample, isPro: purchases.isPro)
                              ? "arrow.right" : "lock.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("nextChapter")
            } else {
                Text("The end").font(style.font()).foregroundStyle(style.theme.secondaryText)
            }
            if chapterIndex > 0 {
                Button("Previous chapter") { goTo(chapterIndex - 1) }
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let selected, translator.content.sentences.indices.contains(selected) {
            SentenceBar(sentence: translator.content.sentences[selected],
                        isSpeaking: narrator.isSpeaking,
                        canExplain: SentenceExplainer.isAvailable,
                        onListen: { toggleListening(from: selected) },
                        onExplain: { explain(selected) },
                        onClose: { self.selected = nil })
                .padding(.horizontal)
                .padding(.bottom, 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            statusBar
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        switch translator.phase {
        case .translating:
            HStack(spacing: 10) {
                ProgressView(value: translator.progress)
                    .frame(width: 80)
                Text("Translating on device… \(Int(translator.progress * 100))%")
                    .font(.footnote)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: .capsule)
            .padding(.bottom, 8)
            .accessibilityIdentifier("translationProgress")
        case .failed(let message):
            Notice(message: message, systemImage: "exclamationmark.triangle", actionTitle: "Try Again") { translator.retry() }
        case .unsupported:
            Notice(message: String(localized: "Your device can't translate \(LanguageCatalog.name(book.sourceLanguage)) to \(LanguageCatalog.name(book.targetLanguage)). Choose another language pair in Aa."),
                   systemImage: "character.book.closed", actionTitle: "Change", action: { showSettings = true })
        case .idle, .done:
            EmptyView()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                toggleListening(from: selected ?? rows.first?.sentences.lowerBound ?? 0)
            } label: {
                Label(narrator.isSpeaking ? "Stop" : "Listen", systemImage: narrator.isSpeaking ? "stop.fill" : "speaker.wave.2")
            }
            .accessibilityIdentifier("listenButton")
            Button {
                showChapters = true
            } label: {
                Label("Chapters", systemImage: "list.bullet")
            }
            .accessibilityIdentifier("chaptersButton")
            Button {
                showSettings = true
            } label: {
                Label("Reading Settings", systemImage: "textformat.size")
            }
            .accessibilityIdentifier("readerSettingsButton")
        }
    }

    // MARK: Actions

    private func start() {
        chapters = book.sortedChapters
        let index = min(book.currentChapter, max(chapters.count - 1, 0))
        if !FreeTier.canRead(chapterIndex: index, isSample: book.isSample, isPro: purchases.isPro) {
            chapterIndex = 0
        } else {
            chapterIndex = index
        }
        book.lastOpenedAt = .now
        reloadChapter()
        guard demo, translator.content.sentences.indices.contains(DemoContent.selectedSentence) else { return }
        if demoScreen == "select" || demoScreen == "word" {
            scrollRequest = rows.last { $0.sentences.lowerBound <= DemoContent.selectedSentence }?.id
        }
        switch demoScreen {
        case "select":
            selected = DemoContent.selectedSentence
        case "word":
            selected = DemoContent.selectedSentence
            if let word = DemoContent.lookupWord(in: translator.content.sentences[DemoContent.selectedSentence].text) {
                lookup = WordLookup(word: word, sentence: DemoContent.selectedSentence, side: .source)
            }
        default:
            break
        }
    }

    private func reloadChapter() {
        guard let chapter else { return }
        narrator.stop()
        selected = nil
        let next = chapters.indices.contains(chapterIndex + 1) ? chapters[chapterIndex + 1] : nil
        let prefetch = next.flatMap { FreeTier.canRead(chapterIndex: $0.index, isSample: book.isSample, isPro: purchases.isPro) ? $0 : nil }
        translator.load(chapter, of: book, prefetch: prefetch, translate: !demo)
        rows = translator.content.rows()
    }

    private func goTo(_ index: Int) {
        guard chapters.indices.contains(index) else { return }
        guard FreeTier.canRead(chapterIndex: index, isSample: book.isSample, isPro: purchases.isPro) else {
            showPaywall = true
            return
        }
        chapterIndex = index
        book.currentChapter = index
        book.lastOpenedAt = .now
        reloadChapter()
    }

    private func handle(_ url: URL) {
        guard url.scheme == "biliteral" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch url.host() {
        case "s":
            guard let index = parts.first.flatMap(Int.init) else { return }
            withAnimation(.snappy) { selected = selected == index ? nil : index }
        case "w":
            guard parts.count == 2, let side = ReaderSide(rawValue: parts[0]), let index = Int(parts[1]),
                  let word = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "q" })?.value
            else { return }
            lookup = WordLookup(word: word, sentence: index, side: side)
        default:
            break
        }
    }

    private func toggleListening(from index: Int) {
        if narrator.isSpeaking {
            narrator.stop()
            return
        }
        let sentences = translator.content.sentences
        guard sentences.indices.contains(index) else { return }
        narrator.speak(sentences[index...].enumerated().map { (index + $0.offset, $0.element.text) }, language: book.sourceLanguage)
    }

    private func explain(_ index: Int) {
        guard purchases.isPro else {
            showPaywall = true
            return
        }
        let sentence = translator.content.sentences[index]
        explanation = Explanation(sentence: sentence.text, translation: sentence.translation,
                                  source: book.sourceLanguage, target: book.targetLanguage)
    }
}

/// Selected sentence: its translation and actions.
private struct SentenceBar: View {
    let sentence: SentenceRecord
    let isSpeaking: Bool
    let canExplain: Bool
    var onListen: () -> Void
    var onExplain: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sentence.translation ?? String(localized: "Translating…"))
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(6)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("selectedTranslation")
                    Text("Tap a word to look it up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Close"))
            }
            HStack(spacing: 8) {
                Button(action: onListen) {
                    Label(isSpeaking ? "Stop" : "Listen", systemImage: isSpeaking ? "stop.fill" : "play.fill")
                }
                if canExplain {
                    Button(action: onExplain) {
                        Label("Explain", systemImage: "sparkles")
                    }
                }
                Button {
                    UIPasteboard.general.string = [sentence.text, sentence.translation].compactMap { $0 }.joined(separator: "\n")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 2)
        .frame(maxWidth: 700)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sentenceBar")
    }
}

struct Notice: View {
    let message: String
    let systemImage: String
    let actionTitle: LocalizedStringKey
    var action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(14)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 6)
        .frame(maxWidth: 700)
    }
}
