import SwiftData
import SwiftUI

@main
struct BiliteralApp: App {
    private let options = LaunchOptions()
    private let container: ModelContainer
    @State private var purchases: PurchaseManager
    @State private var importer = ImportController()

    init() {
        let options = LaunchOptions()
        let defaults = UserDefaults.standard
        if options.isUITest {
            for key in SettingsKey.all { defaults.removeObject(forKey: key) }
            UIView.setAnimationsEnabled(false)
        }
        if options.skipOnboarding { defaults.set(true, forKey: SettingsKey.hasOnboarded) }
        if let theme = options.theme { defaults.set(theme, forKey: SettingsKey.readerTheme) }

        let schema = Schema([Book.self, Chapter.self, VocabCard.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: options.isUITest, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the library store: \(error)")
        }
        _purchases = State(initialValue: PurchaseManager(forcePro: options.forcePro))
    }

    var body: some Scene {
        WindowGroup {
            RootView(options: options)
                .environment(purchases)
                .environment(importer)
                .task { await purchases.load() }
        }
        .modelContainer(container)
    }
}
