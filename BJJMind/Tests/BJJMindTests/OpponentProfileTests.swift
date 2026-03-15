import XCTest
@testable import BJJMind

final class OpponentProfileTests: XCTestCase {

    // MARK: - White Belt Final Tournament

    func test_whiteBeltFinalTournament_hasFiveOpponents() {
        XCTAssertEqual(OpponentProfile.whiteBeltFinalTournament.count, 5)
    }

    func test_opponentsAreSortedByDifficulty() {
        let opponents = OpponentProfile.whiteBeltFinalTournament
        for i in 0..<(opponents.count - 1) {
            XCTAssertLessThanOrEqual(
                opponents[i].difficulty,
                opponents[i + 1].difficulty,
                "Opponents should be sorted by difficulty ascending"
            )
        }
    }

    func test_coachSantos_isHardest() {
        let opponents = OpponentProfile.whiteBeltFinalTournament
        let coachSantos = opponents.last
        XCTAssertEqual(coachSantos?.difficulty, 5)
        XCTAssertEqual(coachSantos?.name, "Coach Santos")
    }

    func test_whiteBeltTournament_difficultyRange_is1to5() {
        let opponents = OpponentProfile.whiteBeltFinalTournament
        XCTAssertEqual(opponents.first?.difficulty, 1)
        XCTAssertEqual(opponents.last?.difficulty, 5)
    }

    func test_marcus_isFirst() {
        let first = OpponentProfile.whiteBeltFinalTournament.first
        XCTAssertEqual(first?.name, "Marcus")
        XCTAssertEqual(first?.title, "The Beginner")
    }

    // MARK: - Intermediate Tournament

    func test_intermediateTournament_hasThreeOpponents() {
        XCTAssertEqual(OpponentProfile.intermediateTournament.count, 3)
    }

    func test_intermediateTournament_difficultyRange_is1to3() {
        let opponents = OpponentProfile.intermediateTournament
        let difficulties = opponents.map { $0.difficulty }
        XCTAssertTrue(difficulties.contains(1))
        XCTAssertTrue(difficulties.contains(2))
        XCTAssertTrue(difficulties.contains(3))
    }

    func test_intermediateTournament_isSortedByDifficulty() {
        let opponents = OpponentProfile.intermediateTournament
        for i in 0..<(opponents.count - 1) {
            XCTAssertLessThanOrEqual(
                opponents[i].difficulty,
                opponents[i + 1].difficulty,
                "Intermediate tournament opponents should be sorted by difficulty"
            )
        }
    }

    // MARK: - Attack Rate Validity

    func test_attackRates_areValidProbabilities() {
        let allOpponents = OpponentProfile.whiteBeltFinalTournament + OpponentProfile.intermediateTournament
        for opponent in allOpponents {
            XCTAssertGreaterThanOrEqual(
                opponent.weakAttackSuccessRate, 0.0,
                "\(opponent.name) weakAttackSuccessRate must be >= 0"
            )
            XCTAssertLessThanOrEqual(
                opponent.weakAttackSuccessRate, 1.0,
                "\(opponent.name) weakAttackSuccessRate must be <= 1"
            )
            XCTAssertGreaterThanOrEqual(
                opponent.strongAttackSuccessRate, 0.0,
                "\(opponent.name) strongAttackSuccessRate must be >= 0"
            )
            XCTAssertLessThanOrEqual(
                opponent.strongAttackSuccessRate, 1.0,
                "\(opponent.name) strongAttackSuccessRate must be <= 1"
            )
        }
    }

    func test_strongAttack_isAlwaysStrongerThanWeak() {
        let allOpponents = OpponentProfile.whiteBeltFinalTournament + OpponentProfile.intermediateTournament
        for opponent in allOpponents {
            XCTAssertGreaterThan(
                opponent.strongAttackSuccessRate,
                opponent.weakAttackSuccessRate,
                "\(opponent.name): strongAttack should always be more likely than weakAttack"
            )
        }
    }

    func test_strongAttackMaxSteps_isValidRange() {
        let allOpponents = OpponentProfile.whiteBeltFinalTournament + OpponentProfile.intermediateTournament
        for opponent in allOpponents {
            XCTAssertGreaterThanOrEqual(opponent.strongAttackMaxSteps, 1)
            XCTAssertLessThanOrEqual(opponent.strongAttackMaxSteps, 2)
        }
    }

    // MARK: - Identifiable

    func test_allOpponents_haveUniqueIDs() {
        let allOpponents = OpponentProfile.whiteBeltFinalTournament + OpponentProfile.intermediateTournament
        let ids = allOpponents.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "All opponents must have unique IDs")
    }

    // MARK: - Content Completeness

    func test_allOpponents_haveNonEmptyStrings() {
        let allOpponents = OpponentProfile.whiteBeltFinalTournament + OpponentProfile.intermediateTournament
        for opponent in allOpponents {
            XCTAssertFalse(opponent.name.isEmpty, "\(opponent.id) has empty name")
            XCTAssertFalse(opponent.title.isEmpty, "\(opponent.id) has empty title")
            XCTAssertFalse(opponent.preFightQuote.isEmpty, "\(opponent.id) has empty preFightQuote")
            XCTAssertFalse(opponent.cornerTip.isEmpty, "\(opponent.id) has empty cornerTip")
        }
    }
}
