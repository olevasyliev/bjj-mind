import Foundation
@testable import BJJMind

enum StatFixtures {

    static func make(
        questionId: String,
        strength: Int,
        timesSeen: Int = 1,
        timesWrong: Int = 0,
        lastSeen: Date? = Date()
    ) -> QuestionStat {
        QuestionStat(
            questionId: questionId,
            timesSeen: timesSeen,
            timesWrong: timesWrong,
            strength: strength,
            lastSeen: lastSeen
        )
    }

    /// Batch: parallel arrays of ids and strengths
    static func batch(ids: [String], strengths: [Int]) -> [QuestionStat] {
        zip(ids, strengths).map { id, s in make(questionId: id, strength: s) }
    }

    /// A stat representing a question never seen (no stat row exists in reality;
    /// use this to test nil-stat handling by simply not including it in the stats array)
    static func neverSeenIds(from questions: [Question], stats: [QuestionStat]) -> [String] {
        let seenIds = Set(stats.map(\.questionId))
        return questions.map(\.id).filter { !seenIds.contains($0) }
    }
}
