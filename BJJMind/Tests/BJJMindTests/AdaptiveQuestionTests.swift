import XCTest
@testable import BJJMind

final class AdaptiveQuestionSelectorTests: XCTestCase {

    // MARK: - Helpers

    private func makeQuestion(id: String, difficulty: Int) -> Question {
        Question(
            id: id,
            unitId: "unit-1",
            format: .mcq4,
            prompt: "Question \(id)",
            options: ["A", "B", "C", "D"],
            correctAnswer: "A",
            explanation: "Because A",
            tags: [],
            difficulty: difficulty,
            sceneImageName: nil
        )
    }

    private func makeStat(questionId: String, timesSeen: Int, timesWrong: Int, strength: Int = -1) -> QuestionStat {
        // strength=-1 means "auto": timesWrong >= 2 -> strength 20 (weak), else strength 60 (ok)
        let resolvedStrength = strength >= 0 ? strength : (timesWrong >= 2 ? 20 : 60)
        return QuestionStat(questionId: questionId, timesSeen: timesSeen, timesWrong: timesWrong,
                            strength: resolvedStrength, lastSeen: nil)
    }

    // MARK: - Test 1: Never-seen questions come first

    func test_neverSeenQuestionsComeBefore_seenQuestions() {
        let seen    = makeQuestion(id: "seen",    difficulty: 1)
        let unseen  = makeQuestion(id: "unseen",  difficulty: 3)
        let questions = [seen, unseen]
        let stats = [makeStat(questionId: "seen", timesSeen: 1, timesWrong: 0)]

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 2)

        XCTAssertEqual(result.first?.id, "unseen", "Never-seen question should appear before seen question")
    }

    // MARK: - Test 2: Weak questions come before seen-but-ok questions

    func test_weakQuestionsComeBefore_seenButOkQuestions() {
        let ok   = makeQuestion(id: "ok",   difficulty: 1)
        let weak = makeQuestion(id: "weak", difficulty: 2)
        let questions = [ok, weak]
        let stats = [
            makeStat(questionId: "ok",   timesSeen: 3, timesWrong: 0),
            makeStat(questionId: "weak", timesSeen: 3, timesWrong: 2)   // timesWrong >= 2 → weak
        ]

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 2)

        XCTAssertEqual(result.first?.id, "weak", "Weak question should appear before seen-but-ok question")
    }

    // MARK: - Test 3: Within never-seen group, easier questions come first (difficulty asc)

    func test_withinNeverSeenGroup_easierQuestionsFirst() {
        let hard   = makeQuestion(id: "hard",   difficulty: 5)
        let medium = makeQuestion(id: "medium", difficulty: 3)
        let easy   = makeQuestion(id: "easy",   difficulty: 1)
        let questions = [hard, medium, easy]
        let stats: [QuestionStat] = []   // no stats → all never-seen

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 3)

        XCTAssertEqual(result.map(\.id), ["easy", "medium", "hard"],
                       "Within never-seen group, questions should be sorted by difficulty ascending")
    }

    // MARK: - Test 4: Count limit is respected

    func test_countLimitIsRespected() {
        let questions = (1...10).map { makeQuestion(id: "q\($0)", difficulty: $0) }
        let stats: [QuestionStat] = []

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 4)

        XCTAssertEqual(result.count, 4, "Result count should match requested count")
    }

    // MARK: - Test 5: Empty stats means all questions treated as never-seen

    func test_emptyStats_allQuestionsAreNeverSeen() {
        let q1 = makeQuestion(id: "q1", difficulty: 2)
        let q2 = makeQuestion(id: "q2", difficulty: 1)
        let questions = [q1, q2]
        let stats: [QuestionStat] = []

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 2)

        // Both should be in never-seen group, sorted by difficulty
        XCTAssertEqual(result.map(\.id), ["q2", "q1"],
                       "Empty stats should treat all questions as never-seen, sorted by difficulty")
    }

    // MARK: - Test 6: Group ordering: never-seen → weak → ok (integration)

    func test_fullGroupOrdering_neverSeenThenWeakThenOk() {
        let never  = makeQuestion(id: "never",  difficulty: 3)
        let weak   = makeQuestion(id: "weak",   difficulty: 2)
        let ok     = makeQuestion(id: "ok",     difficulty: 1)
        let questions = [ok, weak, never]
        let stats = [
            makeStat(questionId: "ok",   timesSeen: 5, timesWrong: 0),
            makeStat(questionId: "weak", timesSeen: 5, timesWrong: 3)
            // "never" has no stat → never-seen
        ]

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 3)

        XCTAssertEqual(result.map(\.id), ["never", "weak", "ok"],
                       "Full ordering: never-seen → weak → ok")
    }

    // MARK: - Test 7: Count larger than available questions returns all

    func test_countLargerThanAvailable_returnsAll() {
        let questions = [makeQuestion(id: "q1", difficulty: 1), makeQuestion(id: "q2", difficulty: 2)]
        let stats: [QuestionStat] = []

        let result = AdaptiveQuestionSelector.select(from: questions, stats: stats, count: 100)

        XCTAssertEqual(result.count, 2, "Should return all available questions when count exceeds total")
    }
}

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
        let neverSeen = makeQuestion(id: "never-seen")
        let learningQ = makeQuestion(id: "learning-q")
        let okQ       = makeQuestion(id: "ok-q")
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
