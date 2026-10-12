import SwiftUI

struct SettingsView: View {
    var onPaywall: () -> Void

    @Environment(PurchaseManager.self) private var purchases
    @AppStorage(SettingsKey.targetLanguage) private var targetLanguage = LanguageCatalog.defaultTarget(for: "en")
    @AppStorage(SettingsKey.translationDisplay) private var displayRaw = TranslationDisplay.below.rawValue
    @AppStorage(SettingsKey.sideBySide) private var sideBySide = true
    @State private var languages = LanguageCatalog.fallback

    var body: some View {
        @Bindable var purchases = purchases
        Form {
            Section {
                if purchases.isPro {
                    Label("Biliteral Pro is active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.tint)
                } else {
                    Button {
                        onPaywall()
                    } label: {
                        Label("Unlock Biliteral Pro", systemImage: "sparkles")
                    }
                    .accessibilityIdentifier("upgradeButton")
                }
                Button("Restore Purchases") { Task { await purchases.restore() } }
            }

            Section {
                Picker("Translate new books into", selection: $targetLanguage) {
                    ForEach(languages.contains(targetLanguage) ? languages : [targetLanguage] + languages, id: \.self) {
                        Text(LanguageCatalog.name($0)).tag($0)
                    }
                }
                Toggle("Two pages side by side", isOn: $sideBySide)
                Picker("Translation in one column", selection: $displayRaw) {
                    ForEach(TranslationDisplay.allCases) { Text($0.label).tag($0.rawValue) }
                }
            } header: {
                Text("Reading")
            } footer: {
                Text("Downloaded translation languages are managed in the Settings app under Apps › Translate.")
            }

            Section("About") {
                Link(destination: Links.privacy) { Label("Privacy Policy", systemImage: "hand.raised") }
                Link(destination: Links.terms) { Label("Terms of Use", systemImage: "doc.text") }
                Link(destination: URL(string: "mailto:\(Links.supportEmail)")!) { Label("Contact Support", systemImage: "envelope") }
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            }

            Section {
                Text("The sample book is “Alice’s Adventures in Wonderland” by Lewis Carroll, from Project Gutenberg (public domain). Translations are made on your device by Apple’s translation models; quality depends on the language pair.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task { languages = await LanguageCatalog.supported() }
        .alert("Purchase", isPresented: .init(get: { purchases.errorMessage != nil },
                                              set: { if !$0 { purchases.errorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(purchases.errorMessage ?? "")
        }
    }
}
