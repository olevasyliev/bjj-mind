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
}
