import Foundation

// MARK: - QuestionStat

/// Lightweight model representing a user's performance on a single question.
/// Used by `AdaptiveQuestionSelector` to prioritise unseen and weak questions.
struct QuestionStat {
    let questionId: String
    let timesSeen: Int
    let timesWrong: Int
    let strength: Int      // 0-100
    let lastSeen: Date?    // for decay display

    init(questionId: String, timesSeen: Int, timesWrong: Int, strength: Int = 0, lastSeen: Date? = nil) {
        self.questionId = questionId
        self.timesSeen = timesSeen
        self.timesWrong = timesWrong
        self.strength = strength
        self.lastSeen = lastSeen
    }
}

// MARK: - AdaptiveQuestionSelector

/// Pure, stateless sorting logic for adaptive question selection.
/// Dependency-free so it is easily unit-tested without network access.
enum AdaptiveQuestionSelector {

    /// Selects up to `count` questions from `questions`, ordered adaptively:
    ///
    /// Priority groups (in order):
    ///  1. Never seen (no stat present)
    ///  2. Weak (`strength < 50`)
    ///  3. Everything else (seen and not weak)
    ///
    /// Within the never-seen group, questions are sorted by `difficulty` ascending (easiest first).
    /// Within the weak group, questions are sorted by `strength` ascending (lower = more urgent),
    /// then shuffled within same-strength groups.
    /// Within the ok group, questions are sorted by `difficulty` ascending.
    ///
    /// - Parameters:
    ///   - questions: Full list of candidate questions.
    ///   - stats:     Per-question performance stats for the current user.
    ///   - count:     Maximum number of questions to return.
    /// - Returns: Ordered slice of at most `count` questions.
    static func select(from questions: [Question], stats: [QuestionStat], count: Int) -> [Question] {
        let statByQuestionId = Dictionary(uniqueKeysWithValues: stats.map { ($0.questionId, $0) })

        var neverSeen: [Question] = []
        var weak:      [(question: Question, strength: Int)] = []
        var ok:        [Question] = []

        for question in questions {
            if let stat = statByQuestionId[question.id] {
                if stat.strength < 50 {
                    weak.append((question, stat.strength))
                } else {
                    ok.append(question)
                }
            } else {
                neverSeen.append(question)
            }
        }

        // Never-seen: shuffle first, then stable-sort by difficulty
        neverSeen.shuffle()
        neverSeen.sort { $0.difficulty < $1.difficulty }

        // Weak: sort by strength ascending (lower = more urgent), shuffle within same-strength groups
        weak.sort { $0.strength < $1.strength }
        // Group by strength and shuffle within each group
        var weakSorted: [Question] = []
        var i = 0
        while i < weak.count {
            let currentStrength = weak[i].strength
            var group: [Question] = []
            while i < weak.count && weak[i].strength == currentStrength {
                group.append(weak[i].question)
                i += 1
            }
            weakSorted += group.shuffled()
        }

        // Ok: shuffle first, then stable-sort by difficulty
        ok.shuffle()
        ok.sort { $0.difficulty < $1.difficulty }

        let ordered = neverSeen + weakSorted + ok
        return Array(ordered.prefix(count))
    }
}
