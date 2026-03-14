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

    private func makeStat(questionId: String, timesSeen: Int, timesWrong: Int) -> QuestionStat {
        QuestionStat(questionId: questionId, timesSeen: timesSeen, timesWrong: timesWrong)
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

    func test_withinNeverSeenGroup_easierQuestionsComFirst() {
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
