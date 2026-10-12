import Foundation

public enum ReviewGrade: Int, CaseIterable, Codable, Sendable {
    case again, hard, good, easy
}

/// Spaced-repetition state of one flashcard.
public struct ReviewState: Codable, Equatable, Sendable {
    public var ease: Double
    /// Days until the next review once learned.
    public var interval: Int
    public var repetitions: Int
    public var due: Date

    public init(ease: Double = 2.5, interval: Int = 0, repetitions: Int = 0, due: Date) {
        self.ease = ease
        self.interval = interval
        self.repetitions = repetitions
        self.due = due
    }
}

/// SM-2 with Anki-style grades. "Again" brings the card back in ten minutes.
public enum SRSScheduler {
    public static let relearnDelay: TimeInterval = 10 * 60

    public static func review(_ state: ReviewState, grade: ReviewGrade, now: Date = .now) -> ReviewState {
        var next = state
        let quality: Double = switch grade {
        case .again: 1
        case .hard: 3
        case .good: 4
        case .easy: 5
        }
        next.ease = max(1.3, state.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))

        if grade == .again {
            next.repetitions = 0
            next.interval = 0
            next.due = now.addingTimeInterval(relearnDelay)
            return next
        }

        next.repetitions = state.repetitions + 1
        switch next.repetitions {
        case 1: next.interval = grade == .easy ? 3 : 1
        case 2: next.interval = grade == .hard ? 3 : 6
        default:
            let factor = grade == .hard ? 1.2 : grade == .easy ? state.ease * 1.3 : state.ease
            next.interval = max(state.interval + 1, Int((Double(state.interval) * factor).rounded()))
        }
        next.due = now.addingTimeInterval(TimeInterval(next.interval) * 86_400)
        return next
    }
}

/// What the free tier includes: one imported book, its first three chapters, 20 reviews a day.
/// The bundled sample book is always free.
public enum FreeTier {
    public static let books = 1
    public static let chapters = 3
    public static let dailyReviews = 20

    public static func canImport(importedBooks: Int, isPro: Bool) -> Bool {
        isPro || importedBooks < books
    }

    public static func canRead(chapterIndex: Int, isSample: Bool, isPro: Bool) -> Bool {
        isPro || isSample || chapterIndex < chapters
    }

    public static func canReview(reviewedToday: Int, isPro: Bool) -> Bool {
        isPro || reviewedToday < dailyReviews
    }
}
