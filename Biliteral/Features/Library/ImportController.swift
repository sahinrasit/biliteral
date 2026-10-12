import BiliteralCore
import Foundation
import Observation

/// Shared import state: Library buttons and "Open in Biliteral" from other apps both end here.
@MainActor
@Observable
final class ImportController {
    var pending: PendingImport?
    var isWorking = false
    var errorMessage: String?

    func importFile(_ url: URL) {
        run { try await BookImporter.parseFile(at: url) }
    }

    func importText(_ text: String, title: String) {
        run { try await BookImporter.parseText(text, title: title) }
    }

    func importArticle(_ address: String) {
        var address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if !address.lowercased().hasPrefix("http") { address = "https://" + address }
        guard let url = URL(string: address), url.host() != nil else {
            errorMessage = String(localized: "That doesn't look like a web address.")
            return
        }
        run { try await BookImporter.parseArticle(at: url) }
    }

    private func run(_ work: @escaping () async throws -> PendingImport) {
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                pending = try await work()
            } catch {
                errorMessage = BookImporter.message(for: error)
            }
        }
    }
}
