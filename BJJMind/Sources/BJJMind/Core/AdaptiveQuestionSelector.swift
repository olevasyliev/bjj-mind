import Foundation

// MARK: - QuestionStat

/// Lightweight model representing a user's performance on a single question.
/// Used by `AdaptiveQuestionSelector` to prioritise unseen and weak questions.
struct QuestionStat {
    let questionId: String
    let timesSeen: Int
    let timesWrong: Int
}

// MARK: - AdaptiveQuestionSelector

/// Pure, stateless sorting logic for adaptive question selection.
/// Dependency-free so it is easily unit-tested without network access.
enum AdaptiveQuestionSelector {

    /// Selects up to `count` questions from `questions`, ordered adaptively:
    ///
    /// Priority groups (in order):
    ///  1. Never seen (`timesSeen == 0` or no stat present)
    ///  2. Weak (`timesWrong >= 2`)
    ///  3. Everything else (seen and not weak)
    ///
    /// Within each group questions are sorted by `difficulty` ascending (easiest first).
    ///
    /// - Parameters:
    ///   - questions: Full list of candidate questions.
    ///   - stats:     Per-question performance stats for the current user.
    ///   - count:     Maximum number of questions to return.
    /// - Returns: Ordered slice of at most `count` questions.
    static func select(from questions: [Question], stats: [QuestionStat], count: Int) -> [Question] {
        let statByQuestionId = Dictionary(uniqueKeysWithValues: stats.map { ($0.questionId, $0) })

        var neverSeen: [Question] = []
        var weak:      [Question] = []
        var ok:        [Question] = []

        for question in questions {
            if let stat = statByQuestionId[question.id] {
                if stat.timesWrong >= 2 {
                    weak.append(question)
                } else {
                    ok.append(question)
                }
            } else {
                neverSeen.append(question)
            }
        }

        // Shuffle each group first, then stable-sort by difficulty
        // so questions of equal difficulty appear in random order each session
        neverSeen.shuffle()
        weak.shuffle()
        ok.shuffle()
        let byDifficulty: (Question, Question) -> Bool = { $0.difficulty < $1.difficulty }
        neverSeen.sort(by: byDifficulty)
        weak.sort(by: byDifficulty)
        ok.sort(by: byDifficulty)

        let ordered = neverSeen + weak + ok
        return Array(ordered.prefix(count))
    }
}
