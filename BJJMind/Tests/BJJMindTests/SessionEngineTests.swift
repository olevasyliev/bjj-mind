import XCTest
@testable import BJJMind

@MainActor
final class SessionEngineTests: XCTestCase {

    var questions: [Question]!

    override func setUp() {
        super.setUp()
        questions = [
            Question(id: "q1", unitId: "u1", format: .mcq2,
                     prompt: "Q1", options: ["A", "B"], correctAnswer: "A",
                     explanation: "A is correct", tags: [], difficulty: 1, sceneImageName: nil),
            Question(id: "q2", unitId: "u1", format: .trueFalse,
                     prompt: "Q2", options: ["True", "False"], correctAnswer: "True",
                     explanation: "True is correct", tags: [], difficulty: 1, sceneImageName: nil),
            Question(id: "q3", unitId: "u1", format: .mcq2,
                     prompt: "Q3", options: ["X", "Y"], correctAnswer: "X",
                     explanation: "X is correct", tags: [], difficulty: 2, sceneImageName: nil),
        ]
    }

    func test_init_currentQuestionIsFirst() {
        let engine = SessionEngine(questions: questions)
        XCTAssertEqual(engine.currentQuestion?.id, "q1")
    }

    func test_init_heartsAreMax() {
        let engine = SessionEngine(questions: questions)
        XCTAssertEqual(engine.hearts, UserProfile.maxHearts)
    }

    func test_init_stateIsActive() {
        let engine = SessionEngine(questions: questions)
        XCTAssertEqual(engine.state, .answering)
    }

    func test_answer_correctDoesNotLoseHeart() {
        let engine = SessionEngine(questions: questions)
        let heartsBefore = engine.hearts
        engine.submitAnswer("A")
        XCTAssertEqual(engine.hearts, heartsBefore)
    }

    func test_answer_wrongLosesHeart() {
        let engine = SessionEngine(questions: questions)
        let heartsBefore = engine.hearts
        engine.submitAnswer("B")
        XCTAssertEqual(engine.hearts, heartsBefore - 1)
    }

    func test_answer_correctMarksLastAnswerCorrect() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A")
        XCTAssertTrue(engine.lastAnswerWasCorrect)
    }

    func test_answer_wrongMarksLastAnswerIncorrect() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("B")
        XCTAssertFalse(engine.lastAnswerWasCorrect)
    }

    func test_advance_movesToNextQuestion() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A")
        engine.advance()
        XCTAssertEqual(engine.currentQuestion?.id, "q2")
    }

    func test_allQuestionsAnswered_stateCompletes() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.state, .completed)
    }

    func test_zeroHearts_stateBecomesGameOver() {
        // Need more questions than maxHearts so game-over triggers before completion
        let manyQuestions = (0..<10).map { i in
            Question(id: "q\(i)", unitId: "u1", format: .mcq2,
                     prompt: "Q\(i)", options: ["Right", "Wrong"], correctAnswer: "Right",
                     explanation: "", tags: [], difficulty: 1, sceneImageName: nil)
        }
        let engine = SessionEngine(questions: manyQuestions)
        while engine.state == .answering || engine.state == .showingFeedback {
            if engine.state == .answering { engine.submitAnswer("Wrong") }
            else if engine.state == .showingFeedback { engine.advance() }
        }
        XCTAssertEqual(engine.state, .gameOver)
    }

    func test_progress_isZeroAtStart() {
        let engine = SessionEngine(questions: questions)
        XCTAssertEqual(engine.progress, 0.0)
    }

    func test_progress_isOneAfterAllAnswered() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.progress, 1.0, accuracy: 0.01)
    }

    func test_accuracy_isOneWhenAllCorrect() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.accuracy, 1.0, accuracy: 0.01)
    }

    func test_accuracy_isZeroWhenAllWrong() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("B"); engine.advance()
        engine.submitAnswer("False"); engine.advance()
        // game over after 5 wrong, so only test 2 here for accuracy calc
        let engine2 = SessionEngine(questions: [questions[0]])
        engine2.submitAnswer("B"); engine2.advance()
        XCTAssertEqual(engine2.accuracy, 0.0, accuracy: 0.01)
    }

    func test_submitAnswer_doubleTap_doesNotDoubleDecrementHearts() {
        let engine = SessionEngine(questions: questions)
        let heartsBefore = engine.hearts
        engine.submitAnswer("B")   // wrong
        engine.submitAnswer("B")   // second tap — should be ignored
        XCTAssertEqual(engine.hearts, heartsBefore - 1)
    }

    func test_submitAnswer_doubleTap_doesNotDoubleIncrementAnsweredCount() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A")   // correct
        engine.submitAnswer("A")   // second tap — should be ignored
        XCTAssertEqual(engine.accuracy, 1.0, accuracy: 0.01)
    }

    func test_xpEarned_isPositiveAfterCompletion() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertGreaterThan(engine.xpEarned, 0)
    }

    // MARK: - Streak XP Multiplier
    // All 3 questions answered correctly → base = 3*10 + 5hearts*2 = 40

    func test_xpEarned_streak0HasNoMultiplier() {
        let engine = SessionEngine(questions: questions, streak: 0)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.xpEarned, 40) // base 40, ×1.0
    }

    func test_xpEarned_streak1Applies1_1Multiplier() {
        let engine = SessionEngine(questions: questions, streak: 1)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.xpEarned, 44) // Int(40 * 1.1) = 44
    }

    func test_xpEarned_streak3Applies1_25Multiplier() {
        let engine = SessionEngine(questions: questions, streak: 3)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.xpEarned, 50) // Int(40 * 1.25) = 50
    }

    func test_xpEarned_streak7Applies1_5Multiplier() {
        let engine = SessionEngine(questions: questions, streak: 7)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.xpEarned, 60) // Int(40 * 1.5) = 60
    }

    func test_xpEarned_streak20StillApplies1_5Multiplier() {
        let engine = SessionEngine(questions: questions, streak: 20)
        engine.submitAnswer("A"); engine.advance()
        engine.submitAnswer("True"); engine.advance()
        engine.submitAnswer("X"); engine.advance()
        XCTAssertEqual(engine.xpEarned, 60) // capped at 1.5
    }

    // MARK: - showingIntro state

    func test_init_withCoachIntro_stateIsShowingIntro() {
        let engine = SessionEngine(questions: questions, coachIntro: "Tip text")
        XCTAssertEqual(engine.state, .showingIntro)
    }

    func test_init_withoutCoachIntro_stateIsAnswering() {
        let engine = SessionEngine(questions: questions, coachIntro: nil)
        XCTAssertEqual(engine.state, .answering)
    }

    func test_dismissIntro_transitionsToAnswering() {
        let engine = SessionEngine(questions: questions, coachIntro: "Tip")
        XCTAssertEqual(engine.state, .showingIntro)
        engine.dismissIntro()
        XCTAssertEqual(engine.state, .answering)
    }

    func test_dismissIntro_ignoredWhenNotInIntro() {
        let engine = SessionEngine(questions: questions)
        // state is .answering, not .showingIntro
        engine.dismissIntro()
        XCTAssertEqual(engine.state, .answering)
    }

    func test_submitAnswer_ignoredWhileShowingIntro() {
        let engine = SessionEngine(questions: questions, coachIntro: "Tip")
        let heartsBefore = engine.hearts
        engine.submitAnswer("A")   // should be ignored — still in intro
        XCTAssertEqual(engine.state, .showingIntro)
        XCTAssertEqual(engine.hearts, heartsBefore)
    }

    // MARK: - Gap 2: answeredQuestions tracking

    func test_answeredQuestions_emptyAtStart() {
        let engine = SessionEngine(questions: questions)
        XCTAssertTrue(engine.answeredQuestions.isEmpty)
    }

    func test_answeredQuestions_recordsCorrectAnswer() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A") // correct for q1
        XCTAssertEqual(engine.answeredQuestions.count, 1)
        XCTAssertEqual(engine.answeredQuestions[0].questionId, "q1")
        XCTAssertFalse(engine.answeredQuestions[0].wasWrong)
    }

    func test_answeredQuestions_recordsWrongAnswer() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("B") // wrong for q1 (correct is "A")
        XCTAssertEqual(engine.answeredQuestions.count, 1)
        XCTAssertEqual(engine.answeredQuestions[0].questionId, "q1")
        XCTAssertTrue(engine.answeredQuestions[0].wasWrong)
    }

    func test_answeredQuestions_accumulatesAcrossMultipleAnswers() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A"); engine.advance()   // q1 correct
        engine.submitAnswer("False"); engine.advance() // q2 wrong (correct is "True")
        engine.submitAnswer("X"); engine.advance()   // q3 correct
        XCTAssertEqual(engine.answeredQuestions.count, 3)
        XCTAssertFalse(engine.answeredQuestions[0].wasWrong)
        XCTAssertTrue(engine.answeredQuestions[1].wasWrong)
        XCTAssertFalse(engine.answeredQuestions[2].wasWrong)
    }

    func test_answeredQuestions_notDuplicatedOnDoubleTap() {
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A")   // correct
        engine.submitAnswer("A")   // double tap — ignored
        XCTAssertEqual(engine.answeredQuestions.count, 1)
    }
}
