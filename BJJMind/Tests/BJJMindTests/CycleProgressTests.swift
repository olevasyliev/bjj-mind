import XCTest
@testable import BJJMind

final class CycleProgressTests: XCTestCase {

    // MARK: - Boss unlock (all sub-topics >= 70)

    func test_isBossUnlocked_trueWhenAllSubTopicsAreAtOrAbove70() {
        // Given: all 4 sub-topics have avgStrength >= 70 (Solid or better)
        // When: checking isBossUnlocked
        // Then: true
        let cycle = CycleProgressFixtures.uniform(strength: 70)
        XCTAssertTrue(cycle.isBossUnlocked,
                      "Boss unlocks when all sub-topics reach Solid (strength >= 70)")
    }

    func test_isBossUnlocked_trueWhenAllSubTopicsAre100() {
        // Given: all sub-topics fully mastered
        let cycle = CycleProgressFixtures.uniform(strength: 100)
        XCTAssertTrue(cycle.isBossUnlocked)
    }

    func test_isBossUnlocked_falseWhenOneSubTopicBelow70() {
        // Given: 3 sub-topics at 80, one sub-topic at 69
        // When: checking isBossUnlocked
        // Then: false - boss requires ALL sub-topics to meet threshold
        let subs = [
            SubTopicProgress(slug: "a", title: "A", avgStrength: 80, questionsSeen: 10, totalQuestions: 20, isUnlocked: true, isMastered: true),
            SubTopicProgress(slug: "b", title: "B", avgStrength: 80, questionsSeen: 10, totalQuestions: 20, isUnlocked: true, isMastered: true),
            SubTopicProgress(slug: "c", title: "C", avgStrength: 80, questionsSeen: 10, totalQuestions: 20, isUnlocked: true, isMastered: true),
            SubTopicProgress(slug: "d", title: "D", avgStrength: 69, questionsSeen: 10, totalQuestions: 20, isUnlocked: true, isMastered: false),
        ]
        let cycle = CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
        XCTAssertFalse(cycle.isBossUnlocked,
                       "Boss must stay locked if any sub-topic is below 70")
    }

    func test_isBossUnlocked_falseWhenAllSubTopicsAt69() {
        // Given: all sub-topics exactly one point below threshold
        let cycle = CycleProgressFixtures.uniform(strength: 69)
        XCTAssertFalse(cycle.isBossUnlocked)
    }

    // MARK: - Boss re-lock (sub-topic decays below 50)

    func test_isBossLocked_trueWhenOneSubTopicDecaysBelowFifty() {
        // Given: cycle was unlocked (all >= 70), but one sub-topic decayed to 45
        // When: checking isBossLocked
        // Then: true - boss re-locks to force the user to review
        let cycle = CycleProgressFixtures.bossRelocked(weakIndex: 2)
        XCTAssertTrue(cycle.isBossLocked,
                      "Boss must re-lock if any sub-topic decays below 50")
    }

    func test_isBossLocked_falseWhenAllSubTopicsAt50OrAbove() {
        // Given: all sub-topics have strength >= 50
        let cycle = CycleProgressFixtures.uniform(strength: 50)
        XCTAssertFalse(cycle.isBossLocked)
    }

    func test_isBossLocked_falseWhenBossJustUnlocked() {
        // Given: boss just unlocked (all sub-topics at exactly 70)
        let cycle = CycleProgressFixtures.bossJustUnlocked
        XCTAssertFalse(cycle.isBossLocked)
    }

    // MARK: - Sub-topic sequential unlock (prior sub-topic >= 60)

    func test_subTopic2UnlocksWhenSubTopic1ReachesStrength60() {
        // Given: sub-topic 1 has avgStrength = 60, sub-topic 2 starts locked
        // When: evaluating unlock state
        // Then: sub-topic 2 becomes unlocked
        let subs = [
            SubTopicProgress(slug: "st1", title: "ST1", avgStrength: 60, questionsSeen: 10, totalQuestions: 20, isUnlocked: true, isMastered: false),
            SubTopicProgress(slug: "st2", title: "ST2", avgStrength: 0,  questionsSeen: 0,  totalQuestions: 20, isUnlocked: false, isMastered: false),
        ]
        let cycle = CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
        let unlockStates = cycle.subTopicUnlockStates()
        XCTAssertTrue(unlockStates[1].isUnlocked,
                      "Sub-topic 2 must unlock when sub-topic 1 reaches strength 60")
    }

    func test_subTopic2RemainsLockedWhenSubTopic1IsAt59() {
        // Given: sub-topic 1 is at 59, one point below the unlock gate
        let subs = [
            SubTopicProgress(slug: "st1", title: "ST1", avgStrength: 59, questionsSeen: 10, totalQuestions: 20, isUnlocked: true, isMastered: false),
            SubTopicProgress(slug: "st2", title: "ST2", avgStrength: 0,  questionsSeen: 0,  totalQuestions: 20, isUnlocked: false, isMastered: false),
        ]
        let cycle = CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
        let unlockStates = cycle.subTopicUnlockStates()
        XCTAssertFalse(unlockStates[1].isUnlocked,
                       "Sub-topic 2 must stay locked when prior sub-topic is below 60")
    }

    func test_subTopic1_alwaysUnlocked_whenCycleStarts() {
        // Given: a fresh cycle with no progress
        // When: evaluating unlock states
        // Then: sub-topic 1 is always unlocked (first sub-topic has no gate)
        let subs = [
            SubTopicProgress(slug: "st1", title: "ST1", avgStrength: 0, questionsSeen: 0, totalQuestions: 20, isUnlocked: false, isMastered: false),
        ]
        let cycle = CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
        let unlockStates = cycle.subTopicUnlockStates()
        XCTAssertTrue(unlockStates[0].isUnlocked,
                      "The first sub-topic is always unlocked when the cycle starts")
    }

    // MARK: - Edge case: empty sub-topics

    func test_isBossUnlocked_falseWhenNoSubTopics() {
        // Given: a cycle with no sub-topics defined yet
        // When: checking isBossUnlocked
        // Then: false (vacuously: no sub-topics means nothing is satisfied)
        let cycle = CycleProgressFixtures.empty
        XCTAssertFalse(cycle.isBossUnlocked,
                       "isBossUnlocked must be false when subTopics array is empty")
    }

    // MARK: - avgStrength computation

    func test_avgStrength_computesCorrectlyAcrossSubTopics() {
        // Given: sub-topics with strengths [40, 60, 80, 100]
        // When: computing avgStrength on the cycle
        // Then: returns 70 (average)
        let subs = [40, 60, 80, 100].enumerated().map { i, s in
            SubTopicProgress(slug: "st\(i)", title: "ST\(i)", avgStrength: s,
                             questionsSeen: 10, totalQuestions: 20,
                             isUnlocked: true, isMastered: s >= 70)
        }
        let cycle = CycleProgress(cycleNumber: 1, topic: "closed_guard", subTopics: subs)
        XCTAssertEqual(cycle.avgStrength, 70)
    }

    func test_avgStrength_isZeroWhenNoSubTopics() {
        // Given: empty sub-topics
        // Then: avgStrength = 0, not a crash
        let cycle = CycleProgressFixtures.empty
        XCTAssertEqual(cycle.avgStrength, 0)
    }
}
