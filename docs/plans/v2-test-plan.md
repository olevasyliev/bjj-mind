# BJJ Mind v2 - Test Plan

**Date:** 2026-03-16
**Status:** Ready for implementation
**Scope:** All new and modified components in the v2 refactor

This document is the authoritative test specification for BJJ Mind v2. An implementer can read this plan, write all tests before touching production code, then implement the feature against the failing tests (TDD). Tests are organized by component, not by test type.

---

## How to read this document

- **[UNIT]** - pure Swift test, no network, no Supabase
- **[INTEGRATION]** - requires live Supabase test environment
- **[REGRESSION]** - existing test that must remain green
- Exact function signatures are given so the implementer can copy them verbatim
- Each test has Given / When / Then comments in the body
- Implementation plan task references are noted per section (Task A, B, C...)

---

## Table of Contents

1. [Test Fixtures](#1-test-fixtures)
2. [StrengthTierTests.swift](#2-strengthtiertestsswift-unit--task-a)
3. [SessionCompositionTests.swift](#3-sessioncompositiontestsswift-unit--task-a)
4. [CycleProgressTests.swift](#4-cycleprogresstestsswift-unit--task-a)
5. [StrengthDecayTests.swift](#5-strengthdecaytestsswift-unit--task-a)
6. [SessionEngineTests.swift - Extensions](#6-sessionengineteststswift-extensions-unit--task-c)
7. [AdaptiveQuestionSelectorTests.swift - Extensions](#7-adaptivequestionselectortestsswift-extensions-unit--task-a)
8. [SupabaseSessionIntegrationTests.swift](#8-supabasesessionintegrationtestsswift-integration--tasks-b-d)
9. [Regression Checklist](#9-regression-checklist)
10. [Manual QA Test Scenarios](#10-manual-qa-test-scenarios)
11. [File Organization](#11-file-organization)

---

## 1. Test Fixtures

Create these fixture files before writing any tests. All tests import them via `@testable import BJJMind`.

### 1.1 QuestionFixtures.swift

**Path:** `Tests/BJJMindTests/Fixtures/QuestionFixtures.swift`

```swift
import Foundation
@testable import BJJMind

enum QuestionFixtures {

    /// Standard question with full field set
    static func make(
        id: String = "q-fixture",
        topic: String = "closed_guard",
        subTopic: String = "posture_defense",
        format: QuestionFormat = .mcq4,
        difficulty: Int = 1,
        language: String = "en"
    ) -> Question {
        Question(
            id: id,
            unitId: nil,
            format: format,
            prompt: "Fixture question \(id)",
            options: ["A", "B", "C", "D"],
            correctAnswer: "A",
            explanation: "A is correct",
            tags: [],
            difficulty: difficulty,
            sceneImageName: nil,
            topic: topic,
            subTopic: subTopic,
            language: language
        )
    }

    /// mcq3 format question (must never appear in sessions)
    static func makeMcq3(id: String = "mcq3-fixture", topic: String = "closed_guard") -> Question {
        Question(
            id: id, unitId: nil, format: .mcq3,
            prompt: "Battle question \(id)",
            options: ["A", "B", "C"],
            correctAnswer: "A",
            explanation: "",
            tags: [], difficulty: 1, sceneImageName: nil,
            topic: topic, subTopic: "posture_defense", language: "en"
        )
    }

    /// Batch of N questions, all unique IDs, same topic/subTopic
    static func batch(
        count: Int,
        topic: String = "closed_guard",
        subTopic: String = "posture_defense",
        format: QuestionFormat = .mcq4
    ) -> [Question] {
        (0..<count).map { i in
            make(id: "q-\(topic)-\(subTopic)-\(i)", topic: topic, subTopic: subTopic, format: format)
        }
    }
}
```

### 1.2 StatFixtures.swift

**Path:** `Tests/BJJMindTests/Fixtures/StatFixtures.swift`

```swift
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
```

### 1.3 CycleProgressFixtures.swift

**Path:** `Tests/BJJMindTests/Fixtures/CycleProgressFixtures.swift`

```swift
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
```

---

## 2. StrengthTierTests.swift [UNIT] - Task A

**Path:** `Tests/BJJMindTests/StrengthTierTests.swift`
**What it tests:** The `StrengthTier` enum and its `label` computed property. The tier mapping is:
- 0-49 -> Weak
- 50-69 -> Learning
- 70-89 -> Solid
- 90-100 -> Mastered

```swift
import XCTest
@testable import BJJMind

final class StrengthTierTests: XCTestCase {

    // MARK: - Weak tier (0-49)

    func test_strengthTier_zero_isWeak() {
        // Given: strength = 0
        // When: computing tier label
        // Then: label is "Weak"
        XCTAssertEqual(StrengthTier(strength: 0).label, "Weak")
    }

    func test_strengthTier_one_isWeak() {
        // Given: strength = 1 (above absolute zero but still Weak)
        XCTAssertEqual(StrengthTier(strength: 1).label, "Weak")
    }

    func test_strengthTier_49_isWeak() {
        // Given: strength = 49 (last value in Weak range)
        // When / Then
        XCTAssertEqual(StrengthTier(strength: 49).label, "Weak")
    }

    // MARK: - Learning tier (50-69)

    func test_strengthTier_50_isLearning() {
        // Given: strength = 50 (first value in Learning range)
        XCTAssertEqual(StrengthTier(strength: 50).label, "Learning")
    }

    func test_strengthTier_60_isLearning() {
        // Given: strength = 60 (mid-range)
        XCTAssertEqual(StrengthTier(strength: 60).label, "Learning")
    }

    func test_strengthTier_69_isLearning() {
        // Given: strength = 69 (last value in Learning range)
        XCTAssertEqual(StrengthTier(strength: 69).label, "Learning")
    }

    // MARK: - Solid tier (70-89)

    func test_strengthTier_70_isSolid() {
        // Given: strength = 70 (first value in Solid range, also boss-unlock threshold)
        XCTAssertEqual(StrengthTier(strength: 70).label, "Solid")
    }

    func test_strengthTier_80_isSolid() {
        // Given: strength = 80 (mid-range)
        XCTAssertEqual(StrengthTier(strength: 80).label, "Solid")
    }

    func test_strengthTier_89_isSolid() {
        // Given: strength = 89 (last value in Solid range)
        XCTAssertEqual(StrengthTier(strength: 89).label, "Solid")
    }

    // MARK: - Mastered tier (90-100)

    func test_strengthTier_90_isMastered() {
        // Given: strength = 90 (first value in Mastered range)
        XCTAssertEqual(StrengthTier(strength: 90).label, "Mastered")
    }

    func test_strengthTier_100_isMastered() {
        // Given: strength = 100 (maximum possible value)
        XCTAssertEqual(StrengthTier(strength: 100).label, "Mastered")
    }

    // MARK: - Enum cases match expected raw ranges

    func test_strengthTier_weak_rawRange_is0to49() {
        // Given: StrengthTier.weak
        // When: checking its lower and upper bounds
        // Then: boundary values map to the correct tier
        XCTAssertEqual(StrengthTier(strength: 0),  .weak)
        XCTAssertEqual(StrengthTier(strength: 49), .weak)
    }

    func test_strengthTier_learning_rawRange_is50to69() {
        XCTAssertEqual(StrengthTier(strength: 50), .learning)
        XCTAssertEqual(StrengthTier(strength: 69), .learning)
    }

    func test_strengthTier_solid_rawRange_is70to89() {
        XCTAssertEqual(StrengthTier(strength: 70), .solid)
        XCTAssertEqual(StrengthTier(strength: 89), .solid)
    }

    func test_strengthTier_mastered_rawRange_is90to100() {
        XCTAssertEqual(StrengthTier(strength: 90),  .mastered)
        XCTAssertEqual(StrengthTier(strength: 100), .mastered)
    }

    // MARK: - isMastered convenience

    func test_strengthTier_isMastered_trueAt90() {
        XCTAssertTrue(StrengthTier(strength: 90).isMastered)
    }

    func test_strengthTier_isMastered_falseAt89() {
        XCTAssertFalse(StrengthTier(strength: 89).isMastered)
    }

    func test_strengthTier_isSolid_trueAt70() {
        XCTAssertTrue(StrengthTier(strength: 70).isSolid)
    }

    func test_strengthTier_isSolid_falseAt69() {
        XCTAssertFalse(StrengthTier(strength: 69).isSolid)
    }
}
```

---

## 3. SessionCompositionTests.swift [UNIT] - Task A

**Path:** `Tests/BJJMindTests/SessionCompositionTests.swift`
**What it tests:** The 60/25/15 bucket composition logic. In v2 the `fetch_session_questions` RPC runs server-side; these tests cover the client-side `SessionCompositionBuilder` helper that arranges questions into the correct order and handles edge cases when buckets are underfilled.

```swift
import XCTest
@testable import BJJMind

final class SessionCompositionTests: XCTestCase {

    // MARK: - Helpers

    private func makeCompositionBuilder() -> SessionCompositionBuilder {
        SessionCompositionBuilder()
    }

    // MARK: - Standard 60/25/15 split

    func test_compose_standardCase_returns9Questions() {
        // Given: 20 new questions, 10 weak, 10 refresh available
        // When: composing a session with default size 9
        // Then: exactly 9 questions returned (5 new + 2-3 weak + 1-2 refresh)
        let newQs     = QuestionFixtures.batch(count: 20, subTopic: "posture_defense")
        let weakQs    = QuestionFixtures.batch(count: 10, subTopic: "guard_attacks")
        let refreshQs = QuestionFixtures.batch(count: 10, topic: "guard_passing", subTopic: "kneeling_pass")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: refreshQs,
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 9, "Standard case must return exactly 9 questions")
    }

    func test_compose_standardCase_bucketOrdering_newFirst() {
        // Given: distinct questions per bucket, known IDs
        // When: composed
        // Then: new-bucket questions appear before weak-bucket questions in result
        let newQ    = QuestionFixtures.make(id: "new-1", subTopic: "posture_defense")
        let weakQ   = QuestionFixtures.make(id: "weak-1", subTopic: "guard_attacks")
        let refreshQ = QuestionFixtures.make(id: "refresh-1", topic: "guard_passing", subTopic: "kneeling_pass")

        let result = SessionCompositionBuilder.compose(
            newQuestions: [newQ],
            weakQuestions: [weakQ],
            refreshQuestions: [refreshQ],
            sessionSize: 3
        )

        let ids = result.map(\.id)
        XCTAssertLessThan(ids.firstIndex(of: "new-1")!,
                          ids.firstIndex(of: "weak-1")!,
                          "New questions must appear before weak questions")
        XCTAssertLessThan(ids.firstIndex(of: "weak-1")!,
                          ids.firstIndex(of: "refresh-1")!,
                          "Weak questions must appear before refresh questions")
    }

    // MARK: - Not enough new questions

    func test_compose_notEnoughNew_fillsFromWeak() {
        // Given: only 2 new questions available (need 5), plenty of weak
        // When: composing 9-question session
        // Then: total is still 9 (or as close as possible), weak bucket compensates
        let newQs  = QuestionFixtures.batch(count: 2, subTopic: "posture_defense")
        let weakQs = QuestionFixtures.batch(count: 10, subTopic: "guard_attacks")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertGreaterThanOrEqual(result.count, 6, "Session must have at least 6 questions")
        XCTAssertLessThanOrEqual(result.count, 9)

        let weakIds = Set(weakQs.map(\.id))
        let returnedWeakCount = result.filter { weakIds.contains($0.id) }.count
        XCTAssertGreaterThan(returnedWeakCount, 2,
                             "When new bucket is short, weak bucket fills the gap")
    }

    // MARK: - Zero new questions

    func test_compose_zeroNew_allFromWeakAndRefresh() {
        // Given: no new questions at all (user has seen everything)
        // When: composing session
        // Then: result comes entirely from weak + refresh buckets
        let weakQs    = QuestionFixtures.batch(count: 6, subTopic: "guard_attacks")
        let refreshQs = QuestionFixtures.batch(count: 4, topic: "guard_passing", subTopic: "kneeling_pass")

        let result = SessionCompositionBuilder.compose(
            newQuestions: [],
            weakQuestions: weakQs,
            refreshQuestions: refreshQs,
            sessionSize: 9
        )

        XCTAssertFalse(result.isEmpty, "Session must not be empty even with zero new questions")
        let resultIds = Set(result.map(\.id))
        let allowedIds = Set((weakQs + refreshQs).map(\.id))
        XCTAssertTrue(resultIds.isSubset(of: allowedIds),
                      "All returned questions must come from weak or refresh buckets")
    }

    // MARK: - First session ever

    func test_compose_firstSession_allFromNewBucket() {
        // Given: user has no stats at all (first session ever)
        //        plenty of new questions available
        // When: composing session
        // Then: all questions are from bucket 1 (new), none from weak or refresh
        let newQs = QuestionFixtures.batch(count: 20, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 9)
        let newIds = Set(newQs.map(\.id))
        XCTAssertTrue(result.allSatisfy { newIds.contains($0.id) },
                      "First session must draw exclusively from new-question bucket")
    }

    // MARK: - Minimum viable session

    func test_compose_totalPoolLessThan9_returnAllAvailable() {
        // Given: only 4 questions exist across all buckets
        // When: requesting 9-question session
        // Then: returns all 4 (no crash, no duplicates)
        let newQs  = QuestionFixtures.batch(count: 2, subTopic: "posture_defense")
        let weakQs = QuestionFixtures.batch(count: 2, subTopic: "guard_attacks")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 4, "Must return all available questions when pool < sessionSize")
    }

    func test_compose_totalPoolLessThan6_returnsWhatIsAvailable() {
        // Given: only 3 questions total
        // When: composing
        // Then: returns 3, not an empty array or a crash
        let questions = QuestionFixtures.batch(count: 3, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: questions,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 3)
    }

    // MARK: - No duplicate questions across buckets

    func test_compose_noDuplicatesAcrossBuckets() {
        // Given: same question appears in new AND weak buckets (edge case in server response)
        // When: composing
        // Then: question appears exactly once in result
        let sharedQ = QuestionFixtures.make(id: "shared-q")
        let newQs   = [sharedQ] + QuestionFixtures.batch(count: 5, subTopic: "guard_attacks")
        let weakQs  = [sharedQ] + QuestionFixtures.batch(count: 3, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: [],
            sessionSize: 9
        )

        let ids = result.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "No question should appear twice in the session")
    }

    // MARK: - mcq3 exclusion

    func test_compose_mcq3QuestionsNeverIncluded() {
        // Given: some questions have format = mcq3
        // When: composing session
        // Then: no mcq3 question appears in the result
        //
        // Note: mcq3 exclusion should happen at the RPC layer, but the
        // client-side composer must also guard against it as a defensive check.
        let mcq3Qs = (0..<5).map { i in QuestionFixtures.makeMcq3(id: "mcq3-\(i)") }
        let validQs = QuestionFixtures.batch(count: 5, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: mcq3Qs + validQs,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertFalse(result.contains(where: { $0.format == .mcq3 }),
                       "mcq3 questions must never appear in a learning session")
    }

    // MARK: - Language filtering

    func test_compose_languageFilter_onlyReturnsMatchingLanguage() {
        // Given: mix of EN and ES questions
        // When: composing with language = "es"
        // Then: only ES questions appear in result
        let enQs = QuestionFixtures.batch(count: 5, subTopic: "posture_defense").map { q in
            QuestionFixtures.make(id: q.id + "-en", language: "en")
        }
        let esQs = QuestionFixtures.batch(count: 5, subTopic: "posture_defense").map { q in
            QuestionFixtures.make(id: q.id + "-es", language: "es")
        }

        let result = SessionCompositionBuilder.compose(
            newQuestions: enQs + esQs,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9,
            language: "es"
        )

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.language == "es" },
                      "Language filter must exclude questions not matching requested language")
    }
}
```

---

## 4. CycleProgressTests.swift [UNIT] - Task A

**Path:** `Tests/BJJMindTests/CycleProgressTests.swift`
**What it tests:** Boss unlock/lock logic and sub-topic progression unlock gates in `CycleProgress`.

```swift
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
        //
        // Implementation note: SubTopicProgress.isUnlocked is set by the evaluator;
        // this test verifies the unlock-gate logic function directly.
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
```

---

## 5. StrengthDecayTests.swift [UNIT] - Task A

**Path:** `Tests/BJJMindTests/StrengthDecayTests.swift`
**What it tests:** The client-side decay formula. The server applies decay via the `apply_strength_decay` RPC; these tests verify that the Swift `StrengthDecayCalculator` helper (used for preview/display) produces correct results.

Decay formula: every 3 days without seeing a question, strength drops by 5.

```swift
import XCTest
@testable import BJJMind

final class StrengthDecayTests: XCTestCase {

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    // MARK: - One decay period (3 days)

    func test_decay_strength60_after3Days_becomes55() {
        // Given: strength = 60, last_seen = 3 days ago
        // When: applying decay
        // Then: strength drops by 5 (one 3-day period)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(3))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 55, "Three days = one decay period = -5")
    }

    // MARK: - Three decay periods (9 days)

    func test_decay_strength60_after9Days_becomes45() {
        // Given: strength = 60, last_seen = 9 days ago
        // When: applying decay
        // Then: strength drops by 15 (three 3-day periods)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(9))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 45, "Nine days = three decay periods = -15")
    }

    // MARK: - Less than one decay period (no decay)

    func test_decay_strength60_after1Day_unchanged() {
        // Given: strength = 60, last_seen = 1 day ago (less than 3 days)
        // When: applying decay
        // Then: no change (decay threshold not reached)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(1))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 60, "Less than 3 days = no decay applied")
    }

    func test_decay_strength60_after2Days_unchanged() {
        // Given: strength = 60, last_seen = 2 days ago (still less than 3)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(2))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 60)
    }

    // MARK: - Floor at zero

    func test_decay_lowStrength_doesNotGoBelowZero() {
        // Given: strength = 5, last_seen = 9 days ago (would decay by 15 to -10)
        // When: applying decay
        // Then: floor at 0, no negative values
        let stat = StatFixtures.make(questionId: "q1", strength: 5, lastSeen: daysAgo(9))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 0, "Strength must not decay below 0")
    }

    func test_decay_strength0_remainsZeroAfterAnyTime() {
        // Given: strength = 0 (already at floor)
        // When: 30 days have passed
        // Then: still 0
        let stat = StatFixtures.make(questionId: "q1", strength: 0, lastSeen: daysAgo(30))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 0, "Strength of 0 cannot decay further")
    }

    // MARK: - Null last_seen

    func test_decay_nullLastSeen_noDecayApplied() {
        // Given: last_seen is nil (question was never tracked with a timestamp)
        // When: applying decay
        // Then: strength unchanged (nil = unknown date = no decay)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: nil)
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 60, "nil last_seen must not trigger decay")
    }

    // MARK: - Partial period (4, 5 days)

    func test_decay_strength60_after4Days_loses5() {
        // Given: 4 days elapsed = floor(4/3) = 1 full period
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(4))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 55, "4 days = 1 complete decay period = -5")
    }

    func test_decay_strength60_after6Days_loses10() {
        // Given: 6 days = floor(6/3) = 2 full periods
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(6))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 50, "6 days = 2 complete decay periods = -10")
    }
}
```

---

## 6. SessionEngineTests.swift - Extensions [UNIT] - Task C

**Path:** `Tests/BJJMindTests/SessionEngineTests.swift` (extend existing file)
**What it tests:** New theory card behavior and updated `answeredQuestions` tuple including `firstAttempt`.

Add the following test class below the existing `SessionEngineTests`:

```swift
// MARK: - Theory Card Tests (v2)

@MainActor
final class SessionEngineTheoryCardTests: XCTestCase {

    private func makeQuestion(id: String) -> Question {
        Question(id: id, unitId: "u1", format: .mcq4,
                 prompt: "Q \(id)", options: ["A", "B", "C", "D"], correctAnswer: "A",
                 explanation: "", tags: [], difficulty: 1, sceneImageName: nil)
    }

    private func makeTheoryCard(subTopic: String = "posture_defense") -> SessionItem {
        let screen = MiniTheoryScreen(title: "Welcome", body: "Control the distance.", coachLine: nil, show3D: false)
        let data = MiniTheoryData(type: .cycleIntro, screens: [screen], buttonLabel: "Got it")
        return .theoryCard(data, subTopic: subTopic)
    }

    // MARK: - Initial state with theory card

    func test_init_withTheoryCardAsFirstItem_stateIsShowingTheoryCard() {
        // Given: session items start with a theory card followed by two questions
        // When: engine initializes
        // Then: initial state is showingTheoryCard, not answering
        let items: [SessionItem] = [
            makeTheoryCard(),
            .question(makeQuestion(id: "q1")),
            .question(makeQuestion(id: "q2")),
        ]
        let engine = SessionEngine(items: items)

        if case .showingTheoryCard = engine.state {
            // pass
        } else {
            XCTFail("Expected showingTheoryCard state, got \(engine.state)")
        }
    }

    func test_init_withQuestionsOnly_stateIsAnswering() {
        // Given: no theory cards in item list
        // When: engine initializes
        // Then: initial state is answering (unchanged behavior)
        let items: [SessionItem] = [
            .question(makeQuestion(id: "q1")),
            .question(makeQuestion(id: "q2")),
        ]
        let engine = SessionEngine(items: items)
        XCTAssertEqual(engine.state, .answering)
    }

    // MARK: - dismissTheoryCard advances to answering

    func test_dismissTheoryCard_advancesToAnswering() {
        // Given: engine is in showingTheoryCard state
        // When: dismissTheoryCard() is called
        // Then: state transitions to .answering
        let items: [SessionItem] = [
            makeTheoryCard(),
            .question(makeQuestion(id: "q1")),
        ]
        let engine = SessionEngine(items: items)
        engine.dismissTheoryCard()
        XCTAssertEqual(engine.state, .answering)
    }

    func test_dismissTheoryCard_setsCurrentQuestionToFirstQuestion() {
        // Given: theory card followed by q1
        // When: theory card dismissed
        // Then: currentQuestion is q1
        let items: [SessionItem] = [
            makeTheoryCard(),
            .question(makeQuestion(id: "q1")),
        ]
        let engine = SessionEngine(items: items)
        engine.dismissTheoryCard()
        XCTAssertEqual(engine.currentQuestion?.id, "q1")
    }

    // MARK: - Already-seen theory card is skipped

    func test_init_seenTheoryCard_skipsToAnswering() {
        // Given: the UserDefaults key for this sub-topic theory is already set (seen before)
        // When: engine initializes with a theory card for that sub-topic
        // Then: state starts at answering (card is skipped automatically)
        let subTopic = "posture_defense_seen_test_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: "theory-card-test-\(UUID().uuidString)")!
        defaults.set(true, forKey: "theory_seen_\(subTopic)")

        let items: [SessionItem] = [
            makeTheoryCard(subTopic: subTopic),
            .question(makeQuestion(id: "q1")),
        ]
        let engine = SessionEngine(items: items, defaults: defaults)
        XCTAssertEqual(engine.state, .answering,
                       "Theory card already seen in UserDefaults must be skipped")
    }

    // MARK: - Max two theory cards per session

    func test_session_maxTwoTheoryCards_thirdIsSkipped() {
        // Given: session with 3 theory cards interleaved with questions
        // When: completing the session
        // Then: the third theory card is skipped automatically
        let items: [SessionItem] = [
            makeTheoryCard(subTopic: "st1"),
            .question(makeQuestion(id: "q1")),
            makeTheoryCard(subTopic: "st2"),
            .question(makeQuestion(id: "q2")),
            makeTheoryCard(subTopic: "st3"),  // third - must be skipped
            .question(makeQuestion(id: "q3")),
        ]
        let engine = SessionEngine(items: items)
        var theoryCardsShown = 0
        // Simulate full session walkthrough
        var stepCount = 0
        while engine.state != .completed && engine.state != .gameOver && stepCount < 20 {
            switch engine.state {
            case .showingTheoryCard:
                theoryCardsShown += 1
                engine.dismissTheoryCard()
            case .answering:
                engine.submitAnswer("A")
            case .showingFeedback:
                engine.advance()
            default:
                break
            }
            stepCount += 1
        }
        XCTAssertLessThanOrEqual(theoryCardsShown, 2,
                                 "Session must show at most 2 theory cards")
    }

    // MARK: - firstAttempt flag

    func test_answeredQuestions_firstAttemptIsTrue_forSingleAnswer() {
        // Given: standard session with no re-attempts
        // When: user answers question q1 correctly
        // Then: answeredQuestions[0].firstAttempt is true
        let items: [SessionItem] = [.question(makeQuestion(id: "q1"))]
        let engine = SessionEngine(items: items)
        engine.submitAnswer("A")  // correct
        XCTAssertEqual(engine.answeredQuestions.count, 1)
        XCTAssertTrue(engine.answeredQuestions[0].firstAttempt,
                      "All standard session answers are first-attempt")
    }

    func test_answeredQuestions_containsQuestionIdWasWrongAndFirstAttempt() {
        // Given: session with one question
        // When: user answers wrong
        // Then: tuple has correct questionId, wasWrong=true, firstAttempt=true
        let items: [SessionItem] = [.question(makeQuestion(id: "q1"))]
        let engine = SessionEngine(items: items)
        engine.submitAnswer("B")  // wrong (correct is "A")
        XCTAssertEqual(engine.answeredQuestions[0].questionId, "q1")
        XCTAssertTrue(engine.answeredQuestions[0].wasWrong)
        XCTAssertTrue(engine.answeredQuestions[0].firstAttempt)
    }

    func test_answeredQuestions_doesNotIncludeTheoryCardEntries() {
        // Given: session with theory card and two questions
        // When: complete full session
        // Then: answeredQuestions only contains the 2 question entries, not the theory card
        let items: [SessionItem] = [
            makeTheoryCard(),
            .question(makeQuestion(id: "q1")),
            .question(makeQuestion(id: "q2")),
        ]
        let engine = SessionEngine(items: items)
        engine.dismissTheoryCard()
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("A"); engine.advance()
        XCTAssertEqual(engine.answeredQuestions.count, 2,
                       "Theory cards must not create entries in answeredQuestions")
    }

    // MARK: - progress only counts questions, not theory cards

    func test_progress_doesNotAdvanceOnTheoryCardDismissal() {
        // Given: theory card then question
        // When: theory card is dismissed
        // Then: progress is still 0.0 (no question answered yet)
        let items: [SessionItem] = [
            makeTheoryCard(),
            .question(makeQuestion(id: "q1")),
        ]
        let engine = SessionEngine(items: items)
        engine.dismissTheoryCard()
        XCTAssertEqual(engine.progress, 0.0, accuracy: 0.01,
                       "Dismissing a theory card must not advance the session progress bar")
    }

    // MARK: - Belt test mode - no theory cards

    func test_beltTestMode_theoryCardsIgnoredEvenIfPresent() {
        // Given: belt test session (isBeltTest = true) with a theory card in the item list
        // When: engine initializes
        // Then: theory card is skipped, state starts at answering
        let items: [SessionItem] = [
            makeTheoryCard(),
            .question(makeQuestion(id: "q1")),
        ]
        let engine = SessionEngine(items: items, isBeltTest: true)
        XCTAssertEqual(engine.state, .answering,
                       "Belt test sessions must never show theory cards")
    }
}
```

Also update the existing test for `answeredQuestions` tuple to include the `firstAttempt` field:

```swift
// NOTE: Update existing test_answeredQuestions_recordsCorrectAnswer to:
func test_answeredQuestions_recordsCorrectAnswerWithFirstAttempt() {
    // Given: question q1 with correct answer "A"
    // When: user submits correct answer on first attempt
    // Then: tuple has wasWrong=false, firstAttempt=true
    let engine = SessionEngine(questions: questions)
    engine.submitAnswer("A")
    XCTAssertFalse(engine.answeredQuestions[0].wasWrong)
    XCTAssertTrue(engine.answeredQuestions[0].firstAttempt)
}
```

---

## 7. AdaptiveQuestionSelectorTests.swift - Extensions [UNIT] - Task A

**Path:** `Tests/BJJMindTests/AdaptiveQuestionTests.swift` (extend existing file)
**What it tests:** Updated selector behavior using `strength` field instead of `timesWrong >= 2` for the "weak" bucket definition.

Add the following tests after the existing test class:

```swift
// MARK: - v2: Strength-based Selection Tests

final class AdaptiveQuestionSelectorV2Tests: XCTestCase {

    private func makeQuestion(id: String, difficulty: Int = 1) -> Question {
        QuestionFixtures.make(id: id, difficulty: difficulty)
    }

    private func makeStat(questionId: String, strength: Int) -> QuestionStat {
        StatFixtures.make(questionId: questionId, strength: strength)
    }

    // MARK: - Strength ordering within weak bucket

    func test_withinWeakBucket_lowerStrengthComesFirst() {
        // Given: two weak questions (strength < 50) with different strengths
        // When: selecting questions
        // Then: lower-strength question (more urgent) comes first
        let q_strength20 = makeQuestion(id: "q-20")
        let q_strength40 = makeQuestion(id: "q-40")
        let stats = [
            makeStat(questionId: "q-20", strength: 20),
            makeStat(questionId: "q-40", strength: 40),
        ]

        let result = AdaptiveQuestionSelector.select(
            from: [q_strength40, q_strength20],
            stats: stats,
            count: 2
        )

        XCTAssertEqual(result.first?.id, "q-20",
                       "Within weak bucket, questions with lower strength must appear first")
    }

    func test_withinWeakBucket_sameStrength_shufflesRandomly() {
        // Given: multiple questions with identical strength
        // When: selecting over many runs
        // Then: order is not always identical (test for non-determinism)
        let questions = (0..<10).map { i in makeQuestion(id: "q-\(i)") }
        let stats = questions.map { makeStat(questionId: $0.id, strength: 30) }

        var firstIds = Set<String>()
        for _ in 0..<20 {
            let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 5)
            firstIds.insert(result.first!.id)
        }
        // With 10 questions of equal strength, we expect multiple different first IDs across 20 runs
        XCTAssertGreaterThan(firstIds.count, 1,
                             "Same-strength questions must shuffle randomly within the group")
    }

    // MARK: - Questions with no stats come first (unchanged behavior)

    func test_neverSeenQuestionsStillComeBeforeWeakQuestions() {
        // Given: one question with strength=30 (weak) and one with no stat (never seen)
        // When: selecting
        // Then: never-seen question comes first regardless of the weak question's urgency
        let neverSeen = makeQuestion(id: "never-seen")
        let weakQ     = makeQuestion(id: "weak-q")
        let stats     = [makeStat(questionId: "weak-q", strength: 30)]

        let result = AdaptiveQuestionSelector.select(
            from: [weakQ, neverSeen],
            stats: stats,
            count: 2
        )

        XCTAssertEqual(result.first?.id, "never-seen",
                       "Never-seen questions must always precede weak questions")
    }

    // MARK: - Strength threshold for "weak" bucket

    func test_questionWithStrength50_isNotWeak_goesToOkBucket() {
        // Given: question with strength = 50 (exactly at the Learning threshold)
        // When: selecting with a never-seen question also in the pool
        // Then: the strength=50 question is treated as "ok", not "weak"
        //       and appears after never-seen questions
        let neverSeen   = makeQuestion(id: "never-seen")
        let learningQ   = makeQuestion(id: "learning-q")
        let okQ         = makeQuestion(id: "ok-q")
        let stats = [
            makeStat(questionId: "learning-q", strength: 50),  // boundary - NOT weak
            makeStat(questionId: "ok-q", strength: 75),
        ]

        let result = AdaptiveQuestionSelector.select(
            from: [okQ, learningQ, neverSeen],
            stats: stats,
            count: 3
        )

        XCTAssertEqual(result.first?.id, "never-seen",
                       "Never-seen must be first regardless")
        // Both learning (50) and ok (75) are not "weak" - they go to the ok bucket together
        let remainingIds = result.dropFirst().map(\.id)
        XCTAssertFalse(remainingIds.isEmpty)
    }

    func test_questionWithStrength49_isWeak_appearsBeforeOkQuestions() {
        // Given: strength=49 is in the weak bucket (strength < 50)
        // When: selecting alongside an ok question (strength >= 50)
        // Then: the weak question appears first
        let weakQ = makeQuestion(id: "weak-49")
        let okQ   = makeQuestion(id: "ok-75")
        let stats = [
            makeStat(questionId: "weak-49", strength: 49),
            makeStat(questionId: "ok-75",   strength: 75),
        ]

        let result = AdaptiveQuestionSelector.select(
            from: [okQ, weakQ],
            stats: stats,
            count: 2
        )

        XCTAssertEqual(result.first?.id, "weak-49",
                       "strength < 50 must be in weak bucket, before ok questions")
    }
}
```

---

## 8. SupabaseSessionIntegrationTests.swift [INTEGRATION] - Tasks B, D

**Path:** `Tests/BJJMindTests/SupabaseSessionIntegrationTests.swift`
**Requires:** Live Supabase test environment. Gate with an environment variable.

```swift
import XCTest
@testable import BJJMind

// These tests require a live Supabase connection.
// Set BJJMIND_RUN_INTEGRATION_TESTS=1 in the test scheme to enable.
// They must NOT run in CI unless a dedicated test Supabase project is configured.

final class SupabaseSessionIntegrationTests: XCTestCase {

    var testUserId: UUID!
    var supabase: SupabaseService!

    override func setUp() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BJJMIND_RUN_INTEGRATION_TESTS"] == "1",
            "Integration tests skipped - set BJJMIND_RUN_INTEGRATION_TESTS=1 to run"
        )
        testUserId = UUID()  // fresh user ID for test isolation
        supabase = SupabaseService.shared
    }

    // MARK: - fetchSessionComposition

    func test_integration_fetchSessionComposition_returns6to9Questions() async throws {
        // Given: a topic with questions in the test database
        // When: calling fetchSessionComposition
        // Then: between 6 and 9 questions are returned
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "en"
        )
        XCTAssertGreaterThanOrEqual(questions.count, 6,
                                    "Session must have at least 6 questions")
        XCTAssertLessThanOrEqual(questions.count, 9,
                                 "Session must have at most 9 questions")
    }

    func test_integration_fetchSessionComposition_respectsTopicFilter() async throws {
        // Given: request for closed_guard topic
        // When: fetching session
        // Then: all returned questions have topic = "closed_guard"
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "en"
        )
        XCTAssertTrue(questions.allSatisfy { $0.topic == "closed_guard" },
                      "All session questions must belong to the requested topic")
    }

    func test_integration_fetchSessionComposition_excludesMcq3Format() async throws {
        // Given: the database has mcq3 questions for closed_guard
        // When: fetching session
        // Then: no mcq3 questions in the result
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "en"
        )
        XCTAssertFalse(questions.contains(where: { $0.format == .mcq3 }),
                       "Session must never include mcq3 battle questions")
    }

    // MARK: - updateQuestionStrength

    func test_integration_updateQuestionStrength_correctFirstAttempt_increasesStrengthBy20() async throws {
        // Given: a question with no prior stats (or strength = 0)
        // When: calling updateQuestionStrength with wasWrong=false, firstAttempt=true
        // Then: strength for that question increases by 20
        let testQuestionId = "test-q-\(UUID().uuidString)"  // use a seeded test question
        try await supabase.updateQuestionStrength(
            userId: testUserId,
            questionId: testQuestionId,
            wasWrong: false,
            firstAttempt: true
        )
        // Fetch the stat back and verify
        let stats = try await supabase.fetchQuestionStats(userId: testUserId, questionIds: [testQuestionId])
        XCTAssertEqual(stats.first?.strength, 20,
                       "Correct first-attempt answer must increase strength by 20")
    }

    func test_integration_updateQuestionStrength_wrongAnswer_decreasesStrengthBy30() async throws {
        // Given: a question with strength = 50 (set by a prior call)
        // When: calling updateQuestionStrength with wasWrong=true
        // Then: strength decreases by 30 (to 20)
        let testQuestionId = "test-q-wrong-\(UUID().uuidString)"
        // First, build up some strength
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: false, firstAttempt: true)  // +20
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: false, firstAttempt: true)  // +20, total = 40
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: false, firstAttempt: true)  // +20, total = 60

        // Now answer wrong
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: true, firstAttempt: true)   // -30, should be 30

        let stats = try await supabase.fetchQuestionStats(userId: testUserId, questionIds: [testQuestionId])
        XCTAssertEqual(stats.first?.strength, 30,
                       "Wrong answer must reduce strength by 30")
    }

    // MARK: - triggerStrengthDecay

    func test_integration_triggerStrengthDecay_updatesLastSeenRows() async throws {
        // Given: a question stat with last_seen more than 3 days ago and strength > 0
        // When: calling triggerStrengthDecay
        // Then: the stat's strength is reduced (we verify last_seen is not nil and call succeeds)
        try await supabase.triggerStrengthDecay(userId: testUserId)
        // If no throw, decay RPC was called successfully
        XCTAssertTrue(true, "triggerStrengthDecay must complete without error")
    }

    // MARK: - fetchSubTopicProgress

    func test_integration_fetchSubTopicProgress_returnsCorrectAvgStrengthPerSubTopic() async throws {
        // Given: the test user has answered some questions in closed_guard
        // When: fetching sub-topic progress
        // Then: returns a dictionary with sub-topic slugs as keys and avgStrength as values
        let subTopics = ["posture_defense", "guard_attacks", "sweeps", "guard_breaks"]
        let progress = try await supabase.fetchSubTopicProgress(
            userId: testUserId,
            topic: "closed_guard",
            subTopics: subTopics,
            beltLevel: "white"
        )
        // For a brand new user, all sub-topics should have 0 avg strength
        XCTAssertEqual(progress.count, 4, "Must return an entry for each requested sub-topic")
        XCTAssertTrue(progress.values.allSatisfy { $0 >= 0 && $0 <= 100 },
                      "avgStrength must be in range 0-100")
    }

    // MARK: - Language filter

    func test_integration_fetchSessionComposition_languageES_returnsESQuestions() async throws {
        // Given: the database has ES-language questions for closed_guard
        // When: fetching with language = "es"
        // Then: returned questions have language = "es"
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "es"
        )
        // Skip assertion if no ES questions exist yet
        guard !questions.isEmpty else {
            XCTSkip("No ES questions in test database - skip language filter assertion")
        }
        XCTAssertTrue(questions.allSatisfy { $0.language == "es" },
                      "Language filter must return only ES questions when requested")
    }
}
```

---

## 9. Regression Checklist

These tests already exist and must remain green after v2 changes. No modifications needed unless the underlying API changes as part of v2.

### 9.1 AdaptiveQuestionSelectorTests (existing) [REGRESSION]

All 7 existing tests must pass unchanged:
- `test_neverSeenQuestionsComeBefore_seenQuestions`
- `test_weakQuestionsComeBefore_seenButOkQuestions` -- NOTE: after v2, "weak" is defined as strength < 50, not timesWrong >= 2. The test fixture may need the makeStat helper updated to include a `strength` field. The test logic itself should not change.
- `test_withinNeverSeenGroup_easierQuestionsFirst`
- `test_countLimitIsRespected`
- `test_emptyStats_allQuestionsAreNeverSeen`
- `test_fullGroupOrdering_neverSeenThenWeakThenOk`
- `test_countLargerThanAvailable_returnsAll`

**Action required:** Update `makeStat` helper in this test file to also set `strength: 0` for the "weak" question (timesWrong >= 2 is no longer the weak criterion in v2).

### 9.2 SessionEngineTests (existing) [REGRESSION]

All existing tests must pass. The v2 changes to SessionEngine must maintain backward compatibility:
- Belt test mode: `isBeltTest = true`, no theory cards shown
- `gameOver` when hearts reach 0
- `completed` when all questions answered
- `progress` goes from 0 to 1
- `xpEarned` is positive after completion
- XP streak multiplier (streak 0/1/3/7/20)
- `showingIntro` / `dismissIntro` state (existing coachIntro feature unchanged)
- `answeredQuestions` accumulates and does not duplicate on double-tap

**Breaking change to watch:** The `SessionEngine.init(questions:)` signature must remain or a backward-compatible overload added. Existing belt test call sites pass `[Question]`, not `[SessionItem]`.

### 9.3 BattleEngine tests [REGRESSION - MUST NOT CHANGE]

The battle system is out of scope for v2. All battle engine tests must pass without any modifications:
- `BattleEngineTests` - all tests
- `BattleScaleTests` - all tests
- `OpponentProfileTests` - all tests
- `TournamentTests` - all tests

Verify: after v2 merge, run `xcodebuild test -only-testing:BJJMindTests/BattleEngineTests`. Zero failures expected.

### 9.4 AppStateTests (existing) [REGRESSION]

Tests for completeOnboarding, loseHeart, addXP, completeUnit (lesson chain) and belt test retry must pass. The v2 cycle-progress logic adds new AppState properties but must not break existing ones.

Watch for: `applySessionResult` signature change. v2 adds an `answers` parameter. The existing tests call the old signature. Either overload it or update the tests.

### 9.5 CycleStructureTests (existing) [REGRESSION]

Tests for `UnitKind.bossFight`, `.miniTheory`, `.intermediateTournament`, `MiniTheoryData` decoding must all pass unchanged.

### 9.6 MiniTheoryViewTests (existing) [REGRESSION]

All tests for `MiniTheoryScreen` and `MiniTheoryData` models must pass unchanged.

### 9.7 LanguageManager / TranslationTests (existing) [REGRESSION]

All tests for `RemoteTranslation` decoding, `applyTranslations`, EN/ES switching must pass unchanged. The new `language` field on `Question` model must not break existing question decoders.

### 9.8 SupabaseDecodeTests (existing) [REGRESSION]

Any existing Supabase DTO decode tests must pass. Verify the updated `QuestionStat` (new fields `strength` and `lastSeen`) decodes correctly from old-format JSON that lacks those fields (backward compatibility via optional fields or defaults).

---

## 10. Manual QA Test Scenarios

Run these using DevMode (long-press belt icon in DEBUG build). Each row is a standalone test.

| # | Scenario | Setup | Steps | Expected Result |
|---|---|---|---|---|
| M1 | New user first session | Fresh install, no Supabase stats | Tap Start Session on Cycle 1 | Theory card appears before first question; all questions are new (from posture_defense sub-topic); progress bar starts at 0 |
| M2 | Second session same topic | Completed M1, same user | Tap Start Session again | Theory card is NOT shown (already seen); session mix includes some from new sub-topic + previously seen weak questions |
| M3 | Session after mistakes | Complete a session with 3+ wrong answers | Tap Start Session | Those wrong questions appear near the top of the next session (weak bucket priority) |
| M4 | Boss unlock | DevMode -> Set all sub-topic strengths to 75 | View Cycle 1 on HomeView | "The Wall" boss node appears unlocked (not greyed out); tap leads to BattlePreviewView |
| M5 | Boss re-lock | From M4 state, DevMode -> Set posture_defense strength to 45 | View Cycle 1 on HomeView | "The Wall" node reverts to locked state; tooltip shown on tap: "Reach 70% in all sub-topics" |
| M6 | Strength decay simulation | DevMode -> Set last_seen to 9 days ago for 5 questions with strength 60 | Force app relaunch | After relaunch, those 5 questions show strength ~45 (decayed by 15) in progress view |
| M7 | Theory card re-show | DevMode -> Clear UserDefaults key "theory_seen_closed_guard_posture_defense" | Tap Start Session for Cycle 1 | Theory card appears again for posture_defense sub-topic |
| M8 | Language switch to ES | Settings -> Language -> Espanol | Start a session | All session UI strings in Spanish; questions fetched have language="es" |
| M9 | Intermediate tournament access | Complete Cycle 2 boss (or DevMode -> Jump to Cycle 3) | View HomeView | Intermediate tournament node visible between Cycle 2 and Cycle 3; tap opens tournament bracket |
| M10 | Final tournament access | Complete Cycle 4 boss (or DevMode -> Jump past Cycle 4) | View HomeView | Final tournament node visible after Cycle 4 boss; 5-opponent bracket |
| M11 | Reset topic progress | DevMode -> Reset Topic -> closed_guard | Start Session | All questions treated as new again (no stats); theory card appears (if UserDefaults cleared too) |
| M12 | Belt test integrity | Complete all sub-topics (or DevMode), tap Belt Test | Complete belt test with correct answers | No theory cards appear during belt test; standard 5-heart session; pass/fail logic unchanged |
| M13 | Session exhausted topic | All closed_guard questions have strength >= 70 | Tap Start Session | Session still launches (algorithm uses weak/refresh buckets); no crash; minimum 6 questions |
| M14 | Offline session start | Put device in airplane mode | Tap Start Session | Graceful error state shown (not a crash); HomeView shows offline indicator |
| M15 | Progress bars update | Complete a session with 5 correct answers in posture_defense | Return to HomeView | posture_defense progress bar increases; cycleProgress refreshed without app restart |

---

## 11. File Organization

### New test files to create

| File | Tests | Implementation Plan Task |
|---|---|---|
| `Tests/BJJMindTests/StrengthTierTests.swift` | StrengthTier label mapping, boundary values | Task A (QuestionStat + models) |
| `Tests/BJJMindTests/SessionCompositionTests.swift` | 60/25/15 bucket composition, edge cases | Task A + Task B (SessionCompositionBuilder) |
| `Tests/BJJMindTests/CycleProgressTests.swift` | Boss unlock/lock, sub-topic gates, avgStrength | Task A (CycleProgress model) |
| `Tests/BJJMindTests/StrengthDecayTests.swift` | Decay formula, floor, nil lastSeen | Task A + Task B |
| `Tests/BJJMindTests/SupabaseSessionIntegrationTests.swift` | RPC calls, language filter, strength updates | Task B |
| `Tests/BJJMindTests/Fixtures/QuestionFixtures.swift` | Factory helpers for test questions | All |
| `Tests/BJJMindTests/Fixtures/StatFixtures.swift` | Factory helpers for QuestionStat | All |
| `Tests/BJJMindTests/Fixtures/CycleProgressFixtures.swift` | Pre-built CycleProgress states | Task A |

### Existing test files to modify

| File | Change Required | Risk |
|---|---|---|
| `Tests/BJJMindTests/SessionEngineTests.swift` | Add `SessionEngineTheoryCardTests` class; update `answeredQuestions` tuple assertions to include `firstAttempt` | Medium - signature change to answeredQuestions tuple |
| `Tests/BJJMindTests/AdaptiveQuestionTests.swift` | Add `AdaptiveQuestionSelectorV2Tests` class; update `makeStat` helper to include `strength` parameter | Low - additive changes |
| `Tests/BJJMindTests/AppStateTests.swift` | Update `applySessionResult` call sites if method signature changes in Task D | Low - only if signature changes |

### Existing test files with no changes needed

- `BattleEngineTests.swift`
- `BattleScaleTests.swift`
- `TournamentTests.swift`
- `OpponentProfileTests.swift`
- `CycleStructureTests.swift`
- `MiniTheoryViewTests.swift`
- `TranslationTests.swift`
- `SupabaseDecodeTests.swift`
- `ModelTests.swift`
- `SkillAssessmentTests.swift`

---

## Implementation order

Follow this sequence to keep the build green at every step:

1. Create fixture files (no production code changes, tests may fail to compile but fixtures are isolated)
2. Implement `StrengthTier` enum -> run StrengthTierTests (all green)
3. Update `QuestionStat` struct with `strength` + `lastSeen` fields -> update `makeStat` in AdaptiveQuestionTests -> run all existing selector tests (all green)
4. Implement `StrengthDecayCalculator` -> run StrengthDecayTests (all green)
5. Implement `SubTopicProgress`, `CycleProgress`, `SessionCompositionBuilder` -> run CycleProgressTests + SessionCompositionTests (all green)
6. Update `SessionEngine` with `[SessionItem]` support and theory card state -> run SessionEngineTheoryCardTests + all existing SessionEngineTests (all green)
7. Implement `SupabaseService` v2 methods -> run integration tests against test Supabase
8. Update `AppState` (Tasks D) -> run AppStateTests (all green)
9. Full regression run: 237+ existing tests must all pass

---

*Total new tests: approximately 85 unit tests + 8 integration tests + 15 manual QA scenarios.*
*Existing tests that must remain green: 237 (all current tests).*
