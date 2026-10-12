import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// "Explain this sentence" with the on-device Apple Intelligence model (iOS 26+, Pro).
enum SentenceExplainer {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    static func explain(sentence: String, translation: String?, source: String, target: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let sourceName = Locale(identifier: "en").localizedString(forIdentifier: source) ?? source
            let targetName = Locale(identifier: "en").localizedString(forIdentifier: target) ?? target
            let session = LanguageModelSession(instructions: """
                You are a friendly language tutor. A learner reading a \(sourceName) book asks about one sentence. \
                Answer in \(targetName), in at most 80 words, as two or three short bullet points: \
                the meaning, the key grammar, and one useful word or idiom. No introduction.
                """)
            var prompt = "Sentence: \(sentence)"
            if let translation { prompt += "\nTranslation: \(translation)" }
            return try await session.respond(to: prompt).content
        }
        #endif
        throw CancellationError()
    }
}
