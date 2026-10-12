import Foundation

/// Launch arguments used by UI tests and fastlane snapshot.
struct LaunchOptions {
    let arguments: [String]

    init(_ arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.arguments = arguments
    }

    /// In-memory store and fresh defaults.
    var isUITest: Bool { arguments.contains("-UITest") }
    var skipOnboarding: Bool { arguments.contains("-SkipOnboarding") }
    /// Sample book with ready translations of chapter VII and a few flashcards (the simulator has no translator).
    var seedDemo: Bool { arguments.contains("-SeedDemo") }

    /// `-Pro YES|NO` overrides the purchase state.
    var forcePro: Bool? {
        value(after: "-Pro").map { $0 == "YES" }
    }

    /// `-Screen reader|select|word|import|review|offline|paywall|settings` opens a screen for screenshots.
    var screen: String? { value(after: "-Screen") }

    /// `-Theme paper|night` sets the reader theme.
    var theme: String? { value(after: "-Theme") }

    /// `-Layout single` forces the one-column reader.
    var layout: String? { value(after: "-Layout") }

    private func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

enum SettingsKey {
    static let hasOnboarded = "hasOnboarded"
    static let targetLanguage = "targetLanguage"
    static let translationDisplay = "translationDisplay"
    static let readerFont = "readerFont"
    static let readerTextSize = "readerTextSize"
    static let readerTheme = "readerTheme"
    static let sideBySide = "sideBySide"
    static let reviewDay = "reviewDay"
    static let reviewsToday = "reviewsToday"

    static let all = [hasOnboarded, targetLanguage, translationDisplay, readerFont, readerTextSize, readerTheme,
                      sideBySide, reviewDay, reviewsToday]
}

enum Links {
    static let privacy = URL(string: "https://sahinrasit.github.io/biliteral/privacy")!
    static let support = URL(string: "https://sahinrasit.github.io/biliteral/")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportEmail = "mrrasitsahin@icloud.com"
}
