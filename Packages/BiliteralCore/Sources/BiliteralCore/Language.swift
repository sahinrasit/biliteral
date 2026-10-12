import Foundation
import NaturalLanguage

public enum SentenceSplitter {
    /// Abbreviations NLTokenizer sometimes treats as sentence ends.
    private static let abbreviations: Set<String> = [
        "mr", "mrs", "ms", "dr", "prof", "st", "jr", "sr", "vs", "etc", "e.g", "i.e", "no", "fig", "vol", "pp", "cf",
        "z.b", "bzw", "usw", "nr", "ca", "mme", "mlle", "sra", "srta", "dña", "sig", "dott", "dhr", "mevr", "bkz", "vb"
    ]

    public static func split(_ paragraph: String, language: String? = nil) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = paragraph
        if let language { tokenizer.setLanguage(NLLanguage(rawValue: language)) }
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: paragraph.startIndex..<paragraph.endIndex) { range, _ in
            let sentence = paragraph[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty { sentences.append(sentence) }
            return true
        }
        return merge(sentences)
    }

    static func merge(_ sentences: [String]) -> [String] {
        var result: [String] = []
        for sentence in sentences {
            guard let previous = result.last else {
                result.append(sentence)
                continue
            }
            let lastWord = previous.split(separator: " ").last.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".(\"“'")) } ?? ""
            let hasLetters = sentence.contains { $0.isLetter || $0.isNumber }
            // “Well!” thought Alice — a lowercase start continues the previous sentence.
            let continues = sentence.first(where: \.isLetter)?.isLowercase == true
            if !hasLetters || continues || (previous.hasSuffix(".") && abbreviations.contains(lastWord)) {
                result[result.count - 1] = hasLetters ? previous + " " + sentence : previous + sentence
            } else {
                result.append(sentence)
            }
        }
        return result
    }
}

public enum LanguageGuesser {
    /// BCP-47 code of the dominant language, e.g. "en", "zh-Hans".
    public static func dominantLanguage(of text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(String(text.prefix(4_000)))
        return recognizer.dominantLanguage?.rawValue
    }
}

public enum WordTokenizer {
    /// Ranges of the words in `text`, without punctuation.
    public static func wordRanges(in text: String) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
    }

    /// Dictionary form ("ran" → "run") when NaturalLanguage knows the language, otherwise the lowercased word.
    public static func lemma(of word: String, language: String?) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        if let language { tagger.setLanguage(NLLanguage(rawValue: language), range: word.startIndex..<word.endIndex) }
        let (tag, _) = tagger.tag(at: word.startIndex, unit: .word, scheme: .lemma)
        let lemma = tag?.rawValue ?? word
        return lemma.isEmpty ? word.lowercased() : lemma.lowercased()
    }
}
