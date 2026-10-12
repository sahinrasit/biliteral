import BiliteralCore
import SwiftUI

enum ReaderFont: String, CaseIterable, Identifiable {
    case serif, sans
    var id: String { rawValue }
    var label: LocalizedStringKey { self == .serif ? "Serif" : "Sans Serif" }
}

enum ReaderTheme: String, CaseIterable, Identifiable {
    case system, paper, night
    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .system: "Automatic"
        case .paper: "Paper"
        case .night: "Night"
        }
    }

    var background: Color {
        switch self {
        case .system: Color(.systemBackground)
        case .paper: Color(red: 0.98, green: 0.955, blue: 0.9)
        case .night: Color(red: 0.07, green: 0.07, blue: 0.08)
        }
    }

    var text: Color {
        switch self {
        case .system: .primary
        case .paper: Color(red: 0.2, green: 0.16, blue: 0.12)
        case .night: Color(white: 0.86)
        }
    }

    var secondaryText: Color {
        switch self {
        case .system: .secondary
        case .paper: Color(red: 0.45, green: 0.38, blue: 0.3)
        case .night: Color(white: 0.6)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .paper: .light
        case .night: .dark
        }
    }
}

/// How the single-column reader shows translations.
enum TranslationDisplay: String, CaseIterable, Identifiable {
    case below, onTap
    var id: String { rawValue }
    var label: LocalizedStringKey { self == .below ? "Under each paragraph" : "Only when I tap a sentence" }
}

struct ReaderStyle {
    var font: ReaderFont
    var size: Double
    var theme: ReaderTheme

    func font(scale: Double = 1) -> Font {
        .system(size: size * scale, design: font == .serif ? .serif : .default)
    }

    var lineSpacing: Double { size * 0.42 }
    var highlight: Color { Color.accentColor.opacity(theme == .night ? 0.38 : 0.2) }
    var speakingHighlight: Color { Color.yellow.opacity(theme == .night ? 0.3 : 0.35) }
}

enum ReaderSide: String {
    case source = "s"
    case translation = "t"
}

/// Builds the tappable text of a row. Every sentence is a link (`biliteral://s/<index>`);
/// in the selected sentence every word is a link (`biliteral://w/<side>/<index>?q=<word>`).
enum SentenceText {
    static func make(_ range: Range<Int>, in content: ChapterContent, side: ReaderSide, selected: Int?,
                     speaking: Int?, style: ReaderStyle) -> AttributedString {
        var result = AttributedString()
        for index in range {
            let sentence = content.sentences[index]
            let text = side == .source ? sentence.text : sentence.translation
            if index > range.lowerBound { result += AttributedString(" ") }
            guard let text, !text.isEmpty else {
                var placeholder = AttributedString(sentence.failed ? "—" : "…")
                placeholder.foregroundColor = style.theme.secondaryText
                result += placeholder
                continue
            }
            var piece = index == selected ? words(of: text, index: index, side: side) : AttributedString(text)
            if index != selected { piece.link = URL(string: "biliteral://s/\(index)") }
            if index == selected {
                piece.backgroundColor = style.highlight
            } else if index == speaking {
                piece.backgroundColor = style.speakingHighlight
            }
            result += piece
        }
        return result
    }

    private static func words(of text: String, index: Int, side: ReaderSide) -> AttributedString {
        var result = AttributedString()
        var cursor = text.startIndex
        for range in WordTokenizer.wordRanges(in: text) {
            if cursor < range.lowerBound {
                var gap = AttributedString(String(text[cursor..<range.lowerBound]))
                gap.link = URL(string: "biliteral://s/\(index)")
                result += gap
            }
            var word = AttributedString(String(text[range]))
            var components = URLComponents()
            components.scheme = "biliteral"
            components.host = "w"
            components.path = "/\(side.rawValue)/\(index)"
            components.queryItems = [URLQueryItem(name: "q", value: String(text[range]))]
            word.link = components.url
            result += word
            cursor = range.upperBound
        }
        if cursor < text.endIndex {
            var tail = AttributedString(String(text[cursor...]))
            tail.link = URL(string: "biliteral://s/\(index)")
            result += tail
        }
        return result
    }
}

/// One aligned row: original and translation side by side, or stacked in one column.
struct ReaderRowView: View {
    let row: ReaderRow
    let content: ChapterContent
    let twoPage: Bool
    let display: TranslationDisplay
    let selected: Int?
    let speaking: Int?
    let style: ReaderStyle

    var body: some View {
        Group {
            if twoPage {
                HStack(alignment: .top, spacing: 56) {
                    text(.source)
                    text(.translation)
                }
            } else {
                VStack(alignment: .leading, spacing: style.size * 0.35) {
                    text(.source)
                    if display == .below {
                        text(.translation, scale: 0.88, color: style.theme.secondaryText)
                    }
                }
            }
        }
        .padding(.top, row.startsParagraph ? style.size * 1.1 : style.size * 0.35)
    }

    private func text(_ side: ReaderSide, scale: Double = 1, color: Color? = nil) -> some View {
        Text(SentenceText.make(row.sentences, in: content, side: side, selected: selected, speaking: speaking, style: style))
            .font(style.font(scale: scale))
            .lineSpacing(style.lineSpacing * scale)
            .tint(color ?? style.theme.text)
            .foregroundStyle(color ?? style.theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(side == .source ? "source-\(row.id)" : "translation-\(row.id)")
    }
}
