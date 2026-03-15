import XCTest
@testable import BJJMind

@MainActor
final class BattleEngineTests: XCTestCase {

    // MARK: - Deterministic test setup
    //
    // weakAttackSuccessRate=0.0  → opponent NEVER attacks after correct answer
    // strongAttackSuccessRate=1.0 → opponent ALWAYS attacks after wrong answer (1 step)

    var scale: BattleScale!
    var easyOpponent: OpponentProfile!

    override func setUp() {
        super.setUp()
        scale = BattleScale.forCycle(1)   // 9 positions, center at index 4
        easyOpponent = OpponentProfile(
            id: "test_dummy",
            name: "Dummy",
            title: "Test Dummy",
            preFightQuote: "",
            cornerTip: "",
            difficulty: 1,
            weakAttackSuccessRate: 0.0,
            strongAttackSuccessRate: 1.0,
            strongAttackMaxSteps: 1
        )
    }

    // MARK: - Initial State

    func test_initialState_isPlayerTurn() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.state, .playerTurn)
    }

    func test_initialMarker_isAtCenter() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.markerIndex, scale.centerIndex)
    }

    func test_initialTurnCount_isZero() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.turnCount, 0)
    }

    func test_initialAdvantagePoints_areBothZero() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.playerAdvantagePoints, 0)
        XCTAssertEqual(engine.opponentAdvantagePoints, 0)
    }

    // MARK: - Answer Submission

    func test_correctAnswer_movesMarkerForward() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        let before = engine.markerIndex
        engine.submitAnswer(wasCorrect: true)
        XCTAssertEqual(engine.markerIndex, before + 1)
    }

    func test_wrongAnswer_markerDoesNotMove() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        let before = engine.markerIndex
        engine.submitAnswer(wasCorrect: false)
        XCTAssertEqual(engine.markerIndex, before)
    }

    func test_correctAnswer_transitionsToShowingResult() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        engine.submitAnswer(wasCorrect: true)
        if case .showingPlayerResult(let wasCorrect) = engine.state {
            XCTAssertTrue(wasCorrect)
        } else {
            XCTFail("Expected .showingPlayerResult(wasCorrect: true), got \(engine.state)")
        }
    }

    func test_wrongAnswer_transitionsToShowingResult() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        engine.submitAnswer(wasCorrect: false)
        if case .showingPlayerResult(let wasCorrect) = engine.state {
            XCTAssertFalse(wasCorrect)
        } else {
            XCTFail("Expected .showingPlayerResult(wasCorrect: false), got \(engine.state)")
        }
    }

    // MARK: - Win Conditions

    func test_submission_win_whenMarkerReachesEnd() {
        // scale has 9 positions; index 8 = submission win for player
        // Center is 4; need to advance 4 steps to reach index 8
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 20)
        // Advance marker to one step before the end
        for _ in 0..<3 {
            engine.submitAnswer(wasCorrect: true)  // moves forward
            engine.proceedToOpponentTurn()         // opponent never attacks (rate=0.0)
            engine.proceedToNextTurn()
        }
        // One more correct answer should reach submission
        engine.submitAnswer(wasCorrect: true)
        if case .playerWin(let bySubmission) = engine.state {
            XCTAssertTrue(bySubmission)
        } else {
            XCTFail("Expected .playerWin(bySubmission: true), got \(engine.state)")
        }
    }

    func test_opponentWin_whenMarkerReachesPlayerEnd() {
        // With strongAttackSuccessRate=1.0, opponent always punishes wrong answers.
        // Center=4; index 0 = submission win for opponent.
        // Wrong answer → opponent attacks and moves marker back 1 step each turn.
        // We need 4 turns of wrong answers where opponent punishes each time.
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 20)

        for _ in 0..<3 {
            engine.submitAnswer(wasCorrect: false) // wrong → marker stays
            engine.proceedToOpponentTurn()          // opponent attacks (rate=1.0) → marker -1
            engine.proceedToNextTurn()
        }
        // Fourth wrong answer: opponent moves marker to index 0
        engine.submitAnswer(wasCorrect: false)
        engine.proceedToOpponentTurn()
        if case .opponentWin(let bySubmission) = engine.state {
            XCTAssertTrue(bySubmission)
        } else {
            XCTFail("Expected .opponentWin(bySubmission: true), got \(engine.state)")
        }
    }

    // MARK: - Turn Limit & Advantage

    func test_turnLimit_triggersAdvantageCalculation() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 2)
        // Turn 1: correct answer, opponent doesn't attack → player advances
        engine.submitAnswer(wasCorrect: true)
        engine.proceedToOpponentTurn()
        engine.proceedToNextTurn()  // turnCount = 1
        // Turn 2: correct answer, opponent doesn't attack → player advances further
        engine.submitAnswer(wasCorrect: true)
        engine.proceedToOpponentTurn()
        engine.proceedToNextTurn()  // turnCount = 2 → triggers advantage check
        // Player advanced into opponent zone → should win by advantage
        switch engine.state {
        case .playerWin, .opponentWin:
            break // expected — advantage resolved
        default:
            XCTFail("Expected win state after maxTurns reached, got \(engine.state)")
        }
    }

    func test_playerWins_tieBreak() {
        // Equal advantage → player wins (home advantage)
        // Use maxTurns=1, both sides have 0 advantage points → tie → player wins
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 1)
        // Wrong answer → marker stays at center (0 points), opponent doesn't move it
        // (opponent rate=1.0 but we'll use a "never" opponent here)
        let neverOpponent = OpponentProfile(
            id: "never",
            name: "Never",
            title: "Never",
            preFightQuote: "",
            cornerTip: "",
            difficulty: 1,
            weakAttackSuccessRate: 0.0,
            strongAttackSuccessRate: 0.0,
            strongAttackMaxSteps: 1
        )
        let tieEngine = BattleEngine(scale: scale, opponent: neverOpponent, maxTurns: 1)
        // Correct answer, but center position has 0 points
        // After moving to index 5 (closedGuard = 0 pts) both sides still 0
        tieEngine.submitAnswer(wasCorrect: false) // marker stays at center
        tieEngine.proceedToOpponentTurn()
        tieEngine.proceedToNextTurn() // maxTurns=1, both sides 0 → tie → player wins
        if case .playerWin(let bySubmission) = tieEngine.state {
            XCTAssertFalse(bySubmission)
        } else {
            XCTFail("Expected .playerWin(bySubmission: false) on tie, got \(tieEngine.state)")
        }
    }

    func test_advantagePoints_accumulateCorrectly() {
        // scale cycle1: positions = [sub, mnt, sc, cg, cg(center), cg, sc, mnt, sub]
        // Advancing from center(4) to index 5 = closedGuard = 0 pts
        // Advancing from index 5 to index 6 = sideControl = 2 pts (player zone)
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.playerAdvantagePoints, 0)

        // First correct → moves to index 5 (closedGuard = 0 pts)
        engine.submitAnswer(wasCorrect: true)
        engine.proceedToOpponentTurn()
        engine.proceedToNextTurn()
        XCTAssertEqual(engine.playerAdvantagePoints, 0)

        // Second correct → moves to index 6 (sideControl = 2 pts)
        engine.submitAnswer(wasCorrect: true)
        engine.proceedToOpponentTurn()
        engine.proceedToNextTurn()
        XCTAssertEqual(engine.playerAdvantagePoints, 2)
    }

    // MARK: - State Transitions

    func test_proceedToOpponentTurn_transitionsState() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        engine.submitAnswer(wasCorrect: true) // → showingPlayerResult
        engine.proceedToOpponentTurn()        // → showingOpponentResult
        if case .showingOpponentResult = engine.state {
            // correct
        } else {
            XCTFail("Expected .showingOpponentResult, got \(engine.state)")
        }
    }

    func test_proceedToNextTurn_incrementsTurnCount() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.turnCount, 0)
        engine.submitAnswer(wasCorrect: true)
        engine.proceedToOpponentTurn()
        engine.proceedToNextTurn()
        XCTAssertEqual(engine.turnCount, 1)
    }

    func test_proceedToNextTurn_returnsToPlayerTurn() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        engine.submitAnswer(wasCorrect: true)
        engine.proceedToOpponentTurn()
        engine.proceedToNextTurn()
        XCTAssertEqual(engine.state, .playerTurn)
    }

    // MARK: - Opponent Attack Behaviour

    func test_opponentNeverAttacks_whenWeakRateIsZero() {
        // Correct answer → weakAttackSuccessRate=0.0 → marker should NOT move back
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        engine.submitAnswer(wasCorrect: true) // marker → 5
        let afterPlayer = engine.markerIndex
        engine.proceedToOpponentTurn()
        // Opponent had 0.0 weak rate → marker unchanged
        if case .showingOpponentResult(let moved, _) = engine.state {
            XCTAssertFalse(moved, "Opponent with 0.0 weak rate should not move marker")
        }
        engine.proceedToNextTurn()
        XCTAssertEqual(engine.markerIndex, afterPlayer)
    }

    func test_opponentAlwaysAttacks_whenStrongRateIsOne() {
        // Wrong answer → strongAttackSuccessRate=1.0 → marker MUST move back
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        let startIndex = engine.markerIndex
        engine.submitAnswer(wasCorrect: false) // marker stays (wrong answer)
        engine.proceedToOpponentTurn()
        if case .showingOpponentResult(let moved, let steps) = engine.state {
            XCTAssertTrue(moved, "Opponent with 1.0 strong rate should always move marker")
            XCTAssertEqual(steps, 1)
        } else {
            XCTFail("Expected .showingOpponentResult, got \(engine.state)")
        }
        engine.proceedToNextTurn()
        XCTAssertEqual(engine.markerIndex, startIndex - 1)
    }

    // MARK: - Computed Properties

    func test_currentPerspective_isBottomAtStart() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        XCTAssertEqual(engine.currentPerspective, "bottom")
    }

    func test_currentPosition_isClosedGuardAtStart() {
        let engine = BattleEngine(scale: scale, opponent: easyOpponent, maxTurns: 10)
        // Cycle 1 center = closedGuard
        XCTAssertEqual(engine.currentPosition, .closedGuard)
    }
}
