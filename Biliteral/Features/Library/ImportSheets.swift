import BiliteralCore
import SwiftData
import SwiftUI
import Translation

struct ArticleSheet: View {
    @Environment(ImportController.self) private var importer
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://", text: $address)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .onSubmit(load)
                        .accessibilityIdentifier("articleURL")
                } footer: {
                    Text("Biliteral keeps the article text and drops menus and ads. Articles behind a paywall or login can't be loaded; paste their text instead.")
                }
            }
            .navigationTitle("Web Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Open", action: load)
                        .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if UIPasteboard.general.hasURLs, let url = UIPasteboard.general.url { address = url.absoluteString }
                focused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func load() {
        importer.importArticle(address)
        dismiss()
    }
}

struct PasteSheet: View {
    @Environment(ImportController.self) private var importer
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                }
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 240)
                        .accessibilityIdentifier("pasteText")
                } footer: {
                    Button("Paste from Clipboard", systemImage: "doc.on.clipboard") {
                        text = UIPasteboard.general.string ?? text
                    }
                    .font(.footnote)
                }
            }
            .navigationTitle("Paste Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let name = title.trimmingCharacters(in: .whitespaces)
                        importer.importText(text, title: name.isEmpty ? String(localized: "Pasted Text") : name)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

/// Confirms the book's language and the translation language, then saves the book.
struct LanguagePairSheet: View {
    let pending: PendingImport
    var onSaved: (Book) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var source = "en"
    @State private var target = "es"
    @State private var languages = LanguageCatalog.fallback
    @State private var status: LanguageAvailability.Status?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        BookCover(title: pending.book.title, author: pending.book.author,
                                  pair: LanguageCatalog.pairLabel(source, target), format: pending.format)
                            .frame(width: 70)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pending.book.title).font(.headline).lineLimit(3)
                            if let author = pending.book.author { Text(author).foregroundStyle(.secondary) }
                            Text("\(pending.book.chapters.count) chapters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Picker("Book language", selection: $source) {
                        ForEach(options(source), id: \.self) { Text(LanguageCatalog.name($0)).tag($0) }
                    }
                    Picker("Translate into", selection: $target) {
                        ForEach(options(target), id: \.self) { Text(LanguageCatalog.name($0)).tag($0) }
                    }
                } footer: {
                    switch status {
                    case .supported?:
                        Text("iOS will ask to download this language pair once. After that, translation works offline.")
                    case .unsupported?:
                        Text("Your device can't translate between these languages. Choose another pair.")
                            .foregroundStyle(.red)
                    default:
                        Text("Translation runs on your device. Nothing you read is uploaded.")
                    }
                }
            }
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Reading", action: save)
                        .disabled(saving || source == target || status == .unsupported)
                        .accessibilityIdentifier("startReading")
                }
            }
            .task {
                source = pending.detectedLanguage.map { LanguageCatalog.code(for: Locale.Language(identifier: $0)) } ?? "en"
                target = LanguageCatalog.defaultTarget(for: source)
                languages = await LanguageCatalog.supported()
            }
            .task(id: "\(source)>\(target)") {
                status = await LanguageAvailability().status(from: Locale.Language(identifier: source),
                                                             to: Locale.Language(identifier: target))
            }
        }
        .interactiveDismissDisabled(saving)
    }

    private func options(_ code: String) -> [String] {
        languages.contains(code) ? languages : [code] + languages
    }

    private func save() {
        saving = true
        UserDefaults.standard.set(target, forKey: SettingsKey.targetLanguage)
        Task {
            let book = await BookImporter.save(pending, source: source, target: target, into: context)
            dismiss()
            onSaved(book)
        }
    }
}
