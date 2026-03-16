import Foundation
@testable import BJJMind

enum CycleProgressFixtures {

    /// All sub-topics at given strength
    static func uniform(strength: Int, subTopicCount: Int = 4) -> CycleProgress {
        let subs = (0..<subTopicCount).map { i in
            SubTopicProgress(
                slug: "sub_topic_\(i)",
                title: "Sub Topic \(i)",
                avgStrength: strength,
                questionsSeen: 10,
                totalQuestions: 20,
                isUnlocked: true,
                isMastered: strength >= 70
            )
        }
        return CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
    }

    /// Pre-boss: all sub-topics exactly at the boss-unlock threshold (all = 70)
    static var bossJustUnlocked: CycleProgress {
        uniform(strength: 70)
    }

    /// One sub-topic below 50 - boss should re-lock
    static func bossRelocked(weakIndex: Int = 0) -> CycleProgress {
        var subs = (0..<4).map { i in
            SubTopicProgress(
                slug: "sub_topic_\(i)",
                title: "Sub Topic \(i)",
                avgStrength: 75,
                questionsSeen: 10,
                totalQuestions: 20,
                isUnlocked: true,
                isMastered: true
            )
        }
        subs[weakIndex] = SubTopicProgress(
            slug: subs[weakIndex].slug,
            title: subs[weakIndex].title,
            avgStrength: 45,
            questionsSeen: 10,
            totalQuestions: 20,
            isUnlocked: true,
            isMastered: false
        )
        return CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
    }

    /// Empty - no sub-topics at all
    static var empty: CycleProgress {
        CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: [])
    }
}
