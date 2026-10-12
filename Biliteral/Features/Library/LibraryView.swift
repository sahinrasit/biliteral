import BiliteralCore
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Binding var path: [Book]
    var onPaywall: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var purchases
    @Environment(ImportController.self) private var importer
    @Query private var books: [Book]
    @State private var showFilePicker = false
    @State private var showArticle = false
    @State private var showPaste = false
    @State private var bookToDelete: Book?
    /// Import started from a sheet; runs after the sheet has gone so the language sheet can appear.
    @State private var afterSheet: (() -> Void)?

    private var sortedBooks: [Book] {
        books.sorted { ($0.lastOpenedAt ?? $0.addedAt) > ($1.lastOpenedAt ?? $1.addedAt) }
    }

    private var importedCount: Int { books.filter { !$0.isSample }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if importedCount == 0 {
                    ImportOptionsCard(onFile: { begin { showFilePicker = true } },
                                      onArticle: { begin { showArticle = true } },
                                      onPaste: { begin { showPaste = true } })
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 210), spacing: 20, alignment: .top)],
                          alignment: .leading, spacing: 28) {
                    ForEach(sortedBooks) { book in
                        Button {
                            path.append(book)
                        } label: {
                            BookCard(book: book)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if !book.isSample {
                                Button("Delete", systemImage: "trash", role: .destructive) { bookToDelete = book }
                            }
                        }
                        .accessibilityIdentifier(book.isSample ? "sampleBook" : "book")
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Choose File (EPUB, PDF, TXT)", systemImage: "folder") { begin { showFilePicker = true } }
                    Button("Web Article", systemImage: "safari") { begin { showArticle = true } }
                    Button("Paste Text", systemImage: "doc.on.clipboard") { begin { showPaste = true } }
                } label: {
                    Label("Add Book", systemImage: "plus")
                }
                .accessibilityIdentifier("addBookButton")
            }
        }
        .overlay {
            if importer.isWorking {
                ProgressView("Opening…")
                    .padding(24)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: BookImporter.fileTypes) { result in
            if case .success(let url) = result { importer.importFile(url) }
        }
        .sheet(isPresented: $showArticle, onDismiss: runAfterSheet) { ArticleSheet { afterSheet = $0 } }
        .sheet(isPresented: $showPaste, onDismiss: runAfterSheet) { PasteSheet { afterSheet = $0 } }
        .confirmationDialog("Delete this book?", isPresented: .init(get: { bookToDelete != nil }, set: { if !$0 { bookToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let bookToDelete { context.delete(bookToDelete) }
                try? context.save()
                bookToDelete = nil
            }
        } message: {
            Text("The book and its translations are removed from this device. Your flashcards stay.")
        }
    }

    private func runAfterSheet() {
        afterSheet?()
        afterSheet = nil
    }

    /// Free tier: one imported book.
    private func begin(_ action: () -> Void) {
        if FreeTier.canImport(importedBooks: importedCount, isPro: purchases.isPro) {
            action()
        } else {
            onPaywall()
        }
    }
}

struct ImportOptionsCard: View {
    var onFile: () -> Void
    var onArticle: () -> Void
    var onPaste: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Read your own book in two languages")
                .font(.title3.bold())
            Text("Import a DRM-free EPUB or PDF, a web article or any text. Translation happens on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { buttons }
                VStack(spacing: 10) { buttons }
            }
        }
        .padding(18)
        .background(Color.accentColor.opacity(0.08), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("importOptions")
    }

    @ViewBuilder
    private var buttons: some View {
        ImportButton(title: "EPUB, PDF or TXT", systemImage: "doc.text", action: onFile)
            .accessibilityIdentifier("importFile")
        ImportButton(title: "Web Article", systemImage: "safari", action: onArticle)
            .accessibilityIdentifier("importArticle")
        ImportButton(title: "Paste Text", systemImage: "doc.on.clipboard", action: onPaste)
            .accessibilityIdentifier("importPaste")
    }
}

private struct ImportButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct BookCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookCover(title: book.title, author: book.author, pair: LanguageCatalog.pairLabel(book.sourceLanguage, book.targetLanguage),
                      format: book.format)
            if book.progress > 0 {
                ProgressView(value: book.progress)
                    .tint(.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if book.isSample {
                        Text("Sample")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.tint.opacity(0.15), in: .capsule)
                    }
                    Text(book.author ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

/// A generated cover: a colour from the title, the title in serif and the language pair.
struct BookCover: View {
    let title: String
    let author: String?
    let pair: String
    var format: String = "epub"

    private var hue: Double {
        Double(title.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF } % 360) / 360
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hue: hue, saturation: 0.45, brightness: 0.55),
                                    Color(hue: hue, saturation: 0.55, brightness: 0.32)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
                if let author {
                    Text(author)
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text(pair)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.2), in: .capsule)
                    Spacer()
                    Image(systemName: format == "web" ? "safari" : format == "pdf" ? "doc.richtext" : format == "text" ? "doc.plaintext" : "book.closed")
                        .font(.caption)
                }
                .foregroundStyle(.white)
            }
            .padding(14)
            .padding(.leading, 4)
        }
        .aspectRatio(2 / 3, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 10))
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}
