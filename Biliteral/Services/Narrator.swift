import AVFoundation
import Foundation
import Observation

/// Reads sentences aloud one after another and reports which one is being spoken.
@MainActor
@Observable
final class Narrator: NSObject {
    private(set) var speakingIndex: Int?

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var indices: [ObjectIdentifier: Int] = [:]
    @ObservationIgnored private var last: ObjectIdentifier?

    var isSpeaking: Bool { speakingIndex != nil }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ sentences: [(index: Int, text: String)], language: String) {
        stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let voice = AVSpeechSynthesisVoice(language: language)
        for sentence in sentences {
            let utterance = AVSpeechUtterance(string: sentence.text)
            utterance.voice = voice
            utterance.postUtteranceDelay = 0.15
            indices[ObjectIdentifier(utterance)] = sentence.index
            last = ObjectIdentifier(utterance)
            synthesizer.speak(utterance)
        }
        speakingIndex = sentences.first?.index
    }

    /// Speaks a single word or phrase without moving the sentence highlight.
    func say(_ text: String, language: String) {
        stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        synthesizer.speak(utterance)
    }

    func stop() {
        indices.removeAll()
        last = nil
        speakingIndex = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }

    private func started(_ id: ObjectIdentifier) {
        if let index = indices[id] { speakingIndex = index }
    }

    private func finished(_ id: ObjectIdentifier) {
        indices[id] = nil
        if id == last {
            speakingIndex = nil
            last = nil
        }
    }
}

extension Narrator: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.started(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }
}
