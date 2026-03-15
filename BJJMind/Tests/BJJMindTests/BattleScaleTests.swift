import XCTest
@testable import BJJMind

final class BattleScaleTests: XCTestCase {

    // MARK: - Scale Structure

    func test_cycle1_hasCorrectPositions() {
        let scale = BattleScale.forCycle(1)
        // [sub, mnt, sc, cg, ●, cg, sc, mnt, sub]
        XCTAssertEqual(scale.positions.count, 9)
        XCTAssertEqual(scale.positions.first, .submission)
        XCTAssertEqual(scale.positions.last, .submission)
        XCTAssertEqual(scale.positions[scale.centerIndex], .closedGuard)
    }

    func test_cycle2_isLongerThanCycle1() {
        let cycle1 = BattleScale.forCycle(1)
        let cycle2 = BattleScale.forCycle(2)
        // Cycle 2: [sub, bk, mnt, sc, hg, ●, hg, sc, mnt, bk, sub] = 11 positions
        XCTAssertGreaterThan(cycle2.positions.count, cycle1.positions.count)
        XCTAssertEqual(cycle2.positions.count, 11)
    }

    func test_cycle3_usesSameScaleAsHalfGuard() {
        // Cycle 3 (Turtle) doesn't add new scale positions — same as cycle 2
        let cycle2 = BattleScale.forCycle(2)
        let cycle3 = BattleScale.forCycle(3)
        XCTAssertEqual(cycle3.positions.count, cycle2.positions.count)
    }

    func test_cycle4_isLongerThanCycle2() {
        let cycle2 = BattleScale.forCycle(2)
        let cycle4 = BattleScale.forCycle(4)
        // Cycle 4: [sub, bk, mnt, sc, hg, og, ●, og, hg, sc, mnt, bk, sub] = 13 positions
        XCTAssertGreaterThan(cycle4.positions.count, cycle2.positions.count)
        XCTAssertEqual(cycle4.positions.count, 13)
    }

    // MARK: - Center Index

    func test_centerIndex_isMiddleOfScale() {
        for cycle in 1...4 {
            let scale = BattleScale.forCycle(cycle)
            let expectedCenter = scale.positions.count / 2
            XCTAssertEqual(scale.centerIndex, expectedCenter, "Cycle \(cycle): center should be at middle index")
        }
    }

    func test_centerIndex_hasClosedGuardForCycle1() {
        let scale = BattleScale.forCycle(1)
        XCTAssertEqual(scale.positions[scale.centerIndex], .closedGuard)
    }

    // MARK: - Perspective

    func test_perspective_bottomAtCenter() {
        let scale = BattleScale.forCycle(1)
        // At center (neutral), player is on bottom (playing guard)
        XCTAssertEqual(scale.perspective(atMarkerIndex: scale.centerIndex), "bottom")
    }

    func test_perspective_topWhenMarkerInOpponentZone() {
        let scale = BattleScale.forCycle(1)
        // marker > center = you're in opponent's territory = on top (attacking)
        let opponentZoneIndex = scale.centerIndex + 1
        XCTAssertEqual(scale.perspective(atMarkerIndex: opponentZoneIndex), "top")
    }

    func test_perspective_bottomWhenMarkerInPlayerZone() {
        let scale = BattleScale.forCycle(1)
        // marker < center = opponent is in your territory = on bottom (defending)
        let playerZoneIndex = scale.centerIndex - 1
        XCTAssertEqual(scale.perspective(atMarkerIndex: playerZoneIndex), "bottom")
    }

    // MARK: - Submission Detection

    func test_isSubmission_atEndPoints() {
        let scale = BattleScale.forCycle(1)
        XCTAssertTrue(scale.isSubmission(atMarkerIndex: 0))
        XCTAssertTrue(scale.isSubmission(atMarkerIndex: scale.positions.count - 1))
    }

    func test_isSubmission_falseForMiddlePositions() {
        let scale = BattleScale.forCycle(1)
        XCTAssertFalse(scale.isSubmission(atMarkerIndex: scale.centerIndex))
        XCTAssertFalse(scale.isSubmission(atMarkerIndex: scale.centerIndex + 1))
    }

    // MARK: - BJJ Points

    func test_bjjPoints_correctValues() {
        // submission = 0 (ends the fight, no points needed)
        XCTAssertEqual(BJJPosition.submission.bjjPoints, 0)
        // sideControl = 2 points in real BJJ
        XCTAssertEqual(BJJPosition.sideControl.bjjPoints, 2)
        // mount = 4 points in real BJJ
        XCTAssertEqual(BJJPosition.mount.bjjPoints, 4)
        // backControl = 4 points in real BJJ
        XCTAssertEqual(BJJPosition.backControl.bjjPoints, 4)
        // halfGuard = 0 (transition position, no points awarded)
        XCTAssertEqual(BJJPosition.halfGuard.bjjPoints, 0)
        // openGuard / closedGuard = 0 (guard positions, no points)
        XCTAssertEqual(BJJPosition.openGuard.bjjPoints, 0)
        XCTAssertEqual(BJJPosition.closedGuard.bjjPoints, 0)
    }

    func test_bjjPoints_viaScale_matchesPosition() {
        let scale = BattleScale.forCycle(1)
        // Center is closedGuard = 0 points
        XCTAssertEqual(scale.pointsForPosition(atMarkerIndex: scale.centerIndex), 0)
    }
}
