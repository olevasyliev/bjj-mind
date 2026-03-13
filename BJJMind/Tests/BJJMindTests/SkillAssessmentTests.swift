import XCTest
@testable import BJJMind

final class SkillAssessmentTests: XCTestCase {

    // MARK: - computeSkillLevel

    func test_beginner_shortTraining_noCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .lessThan6Months, frequency: .onceAWeek, correctCount: 0)
        XCTAssertEqual(level, .beginner)
    }

    func test_intermediate_midTraining_someCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .sixTo18Months, frequency: .twoThreeTimes, correctCount: 2)
        XCTAssertEqual(level, .intermediate)
    }

    func test_advanced_longTraining_allCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .oneToThreeYears, frequency: .fourPlusTimes, correctCount: 3)
        XCTAssertEqual(level, .advanced)
    }

    func test_beginner_shortDuration_overridesQuizScore() {
        // < 6 months → beginner even with perfect quiz (design doc: "< 6 months OR 0–1 correct")
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .lessThan6Months, frequency: .fourPlusTimes, correctCount: 3)
        XCTAssertEqual(level, .beginner)
    }

    func test_advanced_threePlusYears_allCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .threePlusYears, frequency: .fourPlusTimes, correctCount: 3)
        XCTAssertEqual(level, .advanced)
    }

    func test_beginner_longTraining_zeroCorrect() {
        // 0–1 correct always → beginner, even with 3+ years (design doc: "0–1 correct → beginner")
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .threePlusYears, frequency: .onceAWeek, correctCount: 0)
        XCTAssertEqual(level, .beginner)
    }

    // MARK: - questionDifficulty

    func test_questionDifficulty_beginnerGetsEasy() {
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .lessThan6Months), 1)
    }

    func test_questionDifficulty_midGets2() {
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .sixTo18Months), 2)
    }

    func test_questionDifficulty_advancedGets3() {
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .oneToThreeYears), 3)
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .threePlusYears), 3)
    }

    // MARK: - questions(forDifficulty:)

    func test_questionsReturnsExactly3() {
        for diff in [1, 2, 3] {
            let qs = SkillAssessmentEngine.questions(forDifficulty: diff)
            XCTAssertEqual(qs.count, 3, "difficulty \(diff) should return 3 questions")
        }
    }

    func test_questionsHaveNonEmptyPrompts() {
        let qs = SkillAssessmentEngine.questions(forDifficulty: 1)
        for q in qs { XCTAssertFalse(q.prompt.isEmpty) }
    }

    func test_correctAnswerIsAlwaysInOptions() {
        for diff in [1, 2, 3] {
            let qs = SkillAssessmentEngine.questions(forDifficulty: diff)
            for q in qs {
                XCTAssertTrue(q.options.contains(q.correctAnswer),
                    "correct '\(q.correctAnswer)' not in options \(q.options)")
            }
        }
    }
}
