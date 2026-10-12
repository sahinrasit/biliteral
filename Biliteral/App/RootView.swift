import BiliteralCore
import SwiftData
import SwiftUI

struct RootView: View {
    let options: LaunchOptions

    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var purchases
    @Environment(ImportController.self) private var importer
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    enum Tab: Hashable { case library, review, settings }

    @State private var tab: Tab = .library
    @State private var libraryPath: [Book] = []
    @State private var showPaywall = false

    var body: some View {
        @Bindable var importer = importer
        TabView(selection: $tab) {
            NavigationStack(path: $libraryPath) {
                LibraryView(path: $libraryPath, onPaywall: { showPaywall = true })
                    .navigationDestination(for: Book.self) { book in
                        ReaderView(book: book, demo: options.seedDemo, demoScreen: options.screen,
                                   forceSingleColumn: options.layout == "single")
                    }
            }
            .tabItem { Label("Library", systemImage: "books.vertical") }
            .tag(Tab.library)

            NavigationStack {
                ReviewView(onPaywall: { showPaywall = true })
            }
            .tabItem { Label("Flashcards", systemImage: "rectangle.stack") }
            .tag(Tab.review)

            NavigationStack {
                SettingsView(onPaywall: { showPaywall = true })
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(item: $importer.pending) { pending in
            LanguagePairSheet(pending: pending) { book in
                tab = .library
                libraryPath = [book]
            }
        }
        .alert("Couldn't open", isPresented: .init(get: { importer.errorMessage != nil },
                                                   set: { if !$0 { importer.errorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(importer.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: .init(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView {
                hasOnboarded = true
                openSample()
            }
        }
        .onOpenURL { url in
            guard url.isFileURL else { return }
            if FreeTier.canImport(importedBooks: importedCount(), isPro: purchases.isPro) {
                importer.importFile(url)
            } else {
                showPaywall = true
            }
        }
        .task { await prepare() }
    }

    private func importedCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<Book>(predicate: #Predicate { !$0.isSample }))) ?? 0
    }

    private func prepare() async {
        let target = LanguageCatalog.defaultTarget(for: "en")
        let sample = await BookImporter.installSampleIfNeeded(into: context, target: target)
        if options.seedDemo, let sample { DemoContent.seed(sample, into: context) }
        openScreenFromLaunchOptions(sample: sample)
    }

    /// First value right after onboarding: open the sample book.
    private func openSample() {
        let sample = try? context.fetch(FetchDescriptor<Book>(predicate: #Predicate { $0.isSample })).first
        if let sample, libraryPath.isEmpty { libraryPath = [sample] }
    }

    private func openScreenFromLaunchOptions(sample: Book?) {
        switch options.screen {
        case "reader", "select", "word":
            if let sample { libraryPath = [sample] }
        case "review":
            tab = .review
        case "settings":
            tab = .settings
        case "paywall":
            showPaywall = true
        default:
            break
        }
    }
}
