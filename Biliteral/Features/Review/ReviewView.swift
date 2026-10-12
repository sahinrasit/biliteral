import BiliteralCore
import SwiftData
import SwiftUI

/// Daily review counter for the free tier.
enum ReviewCounter {
    static var todayKey: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    static var reviewedToday: Int {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: SettingsKey.reviewDay) == todayKey ? defaults.integer(forKey: SettingsKey.reviewsToday) : 0
    }

    static func recordReview() {
        let defaults = UserDefaults.standard
        defaults.set(reviewedToday + 1, forKey: SettingsKey.reviewsToday)
        defaults.set(todayKey, forKey: SettingsKey.reviewDay)
    }
}

struct ReviewView: View {
    var onPaywall: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var purchases
    @Query(sort: \VocabCard.due) private var cards: [VocabCard]
    @State private var session: ReviewQueue?
    @State private var search = ""

    private var dueCards: [VocabCard] { cards.filter { $0.due <= .now } }

    private var filtered: [VocabCard] {
        guard !search.isEmpty else { return cards }
        return cards.filter { $0.term.localizedCaseInsensitiveContains(search) || $0.meaning.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView {
                    Label("No flashcards yet", systemImage: "rectangle.stack")
                } description: {
                    Text("While reading, tap a sentence, then tap a word you don't know and choose “I don't know this word”.")
                }
            } else {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .firstTextBaseline, spacing: 24) {
                                stat(dueCards.count, "Due now")
                                stat(cards.count, "Cards")
                                stat(cards.filter { $0.interval >= 21 }.count, "Mastered")
                            }
                            Button {
                                startReview()
                            } label: {
                                Label(dueCards.isEmpty ? "All caught up" : "Review \(dueCards.count) cards", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(dueCards.isEmpty)
                            .accessibilityIdentifier("startReview")
                        }
                        .padding(.vertical, 6)
                    }
                    Section("All Cards") {
                        ForEach(filtered) { card in
                            CardRow(card: card)
                        }
                        .onDelete { offsets in
                            for index in offsets { context.delete(filtered[index]) }
                            try? context.save()
                        }
                    }
                }
                .searchable(text: $search)
            }
        }
        .navigationTitle("Flashcards")
        .fullScreenCover(item: $session) { queue in
            ReviewSessionView(cards: queue.cards, onPaywall: {
                session = nil
                onPaywall()
            })
        }
    }

    private func stat(_ value: Int, _ title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.title.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func startReview() {
        guard FreeTier.canReview(reviewedToday: ReviewCounter.reviewedToday, isPro: purchases.isPro) else {
            onPaywall()
            return
        }
        session = ReviewQueue(cards: dueCards)
    }
}

private struct ReviewQueue: Identifiable {
    let id = UUID()
    let cards: [VocabCard]
}

private struct CardRow: View {
    let card: VocabCard

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(card.term).font(.headline)
                Text(card.meaning).foregroundStyle(.secondary)
                Spacer()
                Text(card.due, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !card.context.isEmpty {
                Text(card.context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

struct ReviewSessionView: View {
    var onPaywall: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchases
    @State private var queue: [VocabCard]
    @State private var revealed = false
    @State private var reviewed = 0

    init(cards: [VocabCard], onPaywall: @escaping () -> Void) {
        _queue = State(initialValue: cards)
        self.onPaywall = onPaywall
    }

    var body: some View {
        NavigationStack {
            Group {
                if let card = queue.first {
                    VStack(spacing: 24) {
                        Spacer(minLength: 0)
                        CardFace(card: card, revealed: revealed)
                            .onTapGesture { withAnimation(.snappy) { revealed = true } }
                        Spacer(minLength: 0)
                        if revealed {
                            HStack(spacing: 10) {
                                ForEach(ReviewGrade.allCases, id: \.self) { grade in
                                    gradeButton(grade, card: card)
                                }
                            }
                        } else {
                            Button {
                                withAnimation(.snappy) { revealed = true }
                            } label: {
                                Text("Show Answer").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .accessibilityIdentifier("showAnswer")
                        }
                    }
                    .padding()
                    .frame(maxWidth: 600)
                } else {
                    ContentUnavailableView {
                        Label("Done for now", systemImage: "checkmark.seal")
                    } description: {
                        Text("You reviewed \(reviewed) cards. Keep reading to find new words.")
                    } actions: {
                        Button("Close") { dismiss() }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(queue.isEmpty ? "" : String(localized: "\(queue.count) left"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }

    private func gradeButton(_ grade: ReviewGrade, card: VocabCard) -> some View {
        let next = SRSScheduler.review(card.reviewState, grade: grade)
        let label: LocalizedStringKey = switch grade {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
        let color: Color = switch grade {
        case .again: .red
        case .hard: .orange
        case .good: .green
        case .easy: .blue
        }
        return Button {
            answer(card, grade: grade)
        } label: {
            VStack(spacing: 2) {
                Text(label).font(.subheadline.weight(.semibold))
                Text(intervalText(next)).font(.caption2).opacity(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .accessibilityIdentifier("grade-\(grade.rawValue)")
    }

    private func intervalText(_ state: ReviewState) -> String {
        if state.interval == 0 { return String(localized: "10 min") }
        return String(localized: "\(state.interval) d")
    }

    private func answer(_ card: VocabCard, grade: ReviewGrade) {
        guard FreeTier.canReview(reviewedToday: ReviewCounter.reviewedToday, isPro: purchases.isPro) else {
            onPaywall()
            return
        }
        card.reviewState = SRSScheduler.review(card.reviewState, grade: grade)
        card.lastReviewedAt = .now
        try? context.save()
        ReviewCounter.recordReview()
        reviewed += 1
        withAnimation(.snappy) {
            queue.removeFirst()
            if grade == .again { queue.append(card) }
            revealed = false
        }
    }
}

private struct CardFace: View {
    let card: VocabCard
    let revealed: Bool

    var body: some View {
        VStack(spacing: 18) {
            Text(card.term)
                .font(.system(size: 40, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
            if !card.context.isEmpty {
                Text(highlighted)
                    .font(.system(.body, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            if revealed {
                Divider()
                Text(card.meaning)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.tint)
                    .accessibilityIdentifier("cardMeaning")
                if let translation = card.contextTranslation {
                    Text(translation)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            if let book = card.bookTitle {
                Label(book, systemImage: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24))
        .contentShape(.rect)
    }

    private var highlighted: AttributedString {
        var text = AttributedString(card.context)
        if let range = text.range(of: card.term) {
            text[range].font = .system(.body, design: .serif).bold()
            text[range].foregroundColor = .primary
        }
        return text
    }
}
