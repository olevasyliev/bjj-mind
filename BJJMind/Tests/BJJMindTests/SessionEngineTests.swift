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

    // NOTE: Updated test to include firstAttempt field (v2)
    func test_answeredQuestions_recordsCorrectAnswerWithFirstAttempt() {
        // Given: question q1 with correct answer "A"
        // When: user submits correct answer on first attempt
        // Then: tuple has wasWrong=false, firstAttempt=true
        let engine = SessionEngine(questions: questions)
        engine.submitAnswer("A")
        XCTAssertFalse(engine.answeredQuestions[0].wasWrong)
        XCTAssertTrue(engine.answeredQuestions[0].firstAttempt)
    }
}

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
