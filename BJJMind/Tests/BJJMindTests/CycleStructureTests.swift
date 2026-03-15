import XCTest
@testable import BJJMind

// Typealiases to avoid ambiguity with Foundation.Unit / NSUnit
private typealias AppUnit = BJJMind.Unit
private typealias AppUnitKind = BJJMind.UnitKind

final class CycleStructureTests: XCTestCase {

    // MARK: - Helpers

    private var units: [AppUnit] { AppUnit.whitebelt_en }

    // MARK: - UnitKind: new cases

    func test_unitKind_bossFight_isBossFightTrue() {
        let unit = AppUnit(
            id: "boss-test", belt: .white, orderIndex: 0,
            title: "Boss Fight", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .bossFight, questions: [],
            isBoss: true
        )
        XCTAssertTrue(unit.isBossFight)
        XCTAssertTrue(unit.isBoss)
    }

    func test_unitKind_intermediateTournament_isTournamentTrue() {
        let unit = AppUnit(
            id: "inter-t", belt: .white, orderIndex: 0,
            title: "Tournament", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .intermediateTournament, questions: []
        )
        XCTAssertTrue(unit.isTournament)
        XCTAssertFalse(unit.isBossFight)
    }

    func test_unitKind_finalTournament_isTournamentTrue() {
        let unit = AppUnit(
            id: "final-t", belt: .white, orderIndex: 0,
            title: "Final", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .finalTournament, questions: []
        )
        XCTAssertTrue(unit.isTournament)
    }

    func test_unitKind_bossFight_requiresSession() {
        let unit = AppUnit(
            id: "boss-rs", belt: .white, orderIndex: 0,
            title: "Boss", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .bossFight, questions: []
        )
        XCTAssertTrue(unit.requiresSession)
    }

    func test_unitKind_tournament_requiresSession() {
        let unit = AppUnit(
            id: "tour-rs", belt: .white, orderIndex: 0,
            title: "Tournament", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .intermediateTournament, questions: []
        )
        XCTAssertTrue(unit.requiresSession)
    }

    // MARK: - Unit fields: cycleNumber and isBoss defaults

    func test_unit_isBoss_defaultIsFalse() {
        let unit = AppUnit(
            id: "default-boss", belt: .white, orderIndex: 0,
            title: "Lesson", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .lesson, questions: []
        )
        XCTAssertFalse(unit.isBoss)
    }

    func test_unit_cycleNumber_defaultIsNil() {
        let unit = AppUnit(
            id: "default-cycle", belt: .white, orderIndex: 0,
            title: "Lesson", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .lesson, questions: []
        )
        XCTAssertNil(unit.cycleNumber)
    }

    // MARK: - SampleData: 4 cycles structure

    func test_cycle1_hasFourLessonNodes() {
        let cycle1Lessons = units.filter { $0.cycleNumber == 1 && $0.kind == .lesson }
        XCTAssertEqual(cycle1Lessons.count, 4,
                       "Cycle 1 should have exactly 4 lesson nodes")
    }

    func test_cycle2_hasFourLessonNodes() {
        let cycle2Lessons = units.filter { $0.cycleNumber == 2 && $0.kind == .lesson }
        XCTAssertEqual(cycle2Lessons.count, 4,
                       "Cycle 2 should have exactly 4 lesson nodes")
    }

    func test_cycle3_hasFourLessonNodes() {
        let cycle3Lessons = units.filter { $0.cycleNumber == 3 && $0.kind == .lesson }
        XCTAssertEqual(cycle3Lessons.count, 4,
                       "Cycle 3 should have exactly 4 lesson nodes")
    }

    func test_cycle4_hasFourLessonNodes() {
        let cycle4Lessons = units.filter { $0.cycleNumber == 4 && $0.kind == .lesson }
        XCTAssertEqual(cycle4Lessons.count, 4,
                       "Cycle 4 should have exactly 4 lesson nodes")
    }

    func test_cycle1_bossIsBossFight() {
        let bossFights = units.filter { $0.cycleNumber == 1 && $0.kind == .bossFight }
        XCTAssertEqual(bossFights.count, 1, "Cycle 1 should have exactly 1 boss fight")
        XCTAssertTrue(bossFights.first!.isBoss, "Boss fight node must have isBoss = true")
    }

    func test_cycle2_hasBossFight() {
        let bossFights = units.filter { $0.cycleNumber == 2 && $0.kind == .bossFight }
        XCTAssertEqual(bossFights.count, 1, "Cycle 2 should have exactly 1 boss fight")
        XCTAssertTrue(bossFights.first!.isBoss)
    }

    func test_cycle3_hasBossFight() {
        let bossFights = units.filter { $0.cycleNumber == 3 && $0.kind == .bossFight }
        XCTAssertEqual(bossFights.count, 1, "Cycle 3 should have exactly 1 boss fight")
    }

    func test_cycle4_hasBossFight() {
        let bossFights = units.filter { $0.cycleNumber == 4 && $0.kind == .bossFight }
        XCTAssertEqual(bossFights.count, 1, "Cycle 4 should have exactly 1 boss fight")
    }

    func test_intermediateTournament_appearsAfterCycle2() {
        let tournament = units.first(where: { $0.kind == .intermediateTournament })
        XCTAssertNotNil(tournament, "There should be an intermediate tournament node")
        XCTAssertEqual(tournament!.cycleNumber, 2,
                       "Intermediate tournament should belong to Cycle 2")

        let c2Boss = units.first(where: { $0.cycleNumber == 2 && $0.kind == .bossFight })
        XCTAssertNotNil(c2Boss)
        XCTAssertGreaterThan(tournament!.orderIndex, c2Boss!.orderIndex,
                             "Tournament must come after the Cycle 2 boss fight")
    }

    func test_finalTournament_appearsAfterCycle4Boss() {
        let finalTournament = units.first(where: { $0.kind == .finalTournament })
        XCTAssertNotNil(finalTournament, "There should be a final tournament node")

        let c4Boss = units.first(where: { $0.cycleNumber == 4 && $0.kind == .bossFight })
        XCTAssertNotNil(c4Boss)
        XCTAssertGreaterThan(finalTournament!.orderIndex, c4Boss!.orderIndex,
                             "Final tournament must come after the Cycle 4 boss fight")
    }

    func test_beltTestNode_stillPresent() {
        let beltTest = units.first(where: { $0.kind == .beltTest })
        XCTAssertNotNil(beltTest, "Belt test node must still be present")
        XCTAssertEqual(beltTest!.id, "wb-bt1")
    }

    func test_beltTestNode_isLastUnit() {
        let beltTest = units.first(where: { $0.kind == .beltTest })
        XCTAssertNotNil(beltTest)
        let maxOrderIndex = units.map { $0.orderIndex }.max()!
        XCTAssertEqual(beltTest!.orderIndex, maxOrderIndex,
                       "Belt test should have the highest orderIndex")
    }

    func test_firstUnit_isUnlocked() {
        let first = units.min(by: { $0.orderIndex < $1.orderIndex })
        XCTAssertNotNil(first)
        XCTAssertFalse(first!.isLocked, "First unit must start unlocked")
    }

    func test_cycle1_topicIsClosedGuard() {
        let c1 = units.filter { $0.cycleNumber == 1 && $0.kind == .lesson }
        for unit in c1 {
            XCTAssertEqual(unit.topic, "closed_guard",
                           "Cycle 1 lessons must use topic slug 'closed_guard'")
        }
    }

    func test_cycle2_topicIsHalfGuard() {
        let c2 = units.filter { $0.cycleNumber == 2 && $0.kind == .lesson }
        for unit in c2 {
            XCTAssertEqual(unit.topic, "half_guard",
                           "Cycle 2 lessons must use topic slug 'half_guard'")
        }
    }

    func test_cycle3_topicIsGuardPassing() {
        let c3 = units.filter { $0.cycleNumber == 3 && $0.kind == .lesson }
        for unit in c3 {
            XCTAssertEqual(unit.topic, "guard_passing",
                           "Cycle 3 lessons must use topic slug 'guard_passing'")
        }
    }

    func test_cycle4_topicIsSubmissions() {
        let c4 = units.filter { $0.cycleNumber == 4 && $0.kind == .lesson }
        for unit in c4 {
            XCTAssertEqual(unit.topic, "submissions",
                           "Cycle 4 lessons must use topic slug 'submissions'")
        }
    }

    func test_allUnitsHaveUniqueIds() {
        let ids = units.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "All unit IDs must be unique")
    }

    func test_cycle2_hasMixedReview() {
        let reviews = units.filter { $0.cycleNumber == 2 && $0.kind == .mixedReview }
        XCTAssertEqual(reviews.count, 1, "Cycle 2 should have exactly 1 mixed review")
    }

    func test_cycle3_hasMixedReview() {
        let reviews = units.filter { $0.cycleNumber == 3 && $0.kind == .mixedReview }
        XCTAssertEqual(reviews.count, 1, "Cycle 3 should have exactly 1 mixed review")
    }

    func test_cycle4_hasMixedReview() {
        let reviews = units.filter { $0.cycleNumber == 4 && $0.kind == .mixedReview }
        XCTAssertEqual(reviews.count, 1, "Cycle 4 should have exactly 1 mixed review")
    }

    func test_sampleData_en_and_es_haveIdenticalNodeCount() {
        XCTAssertEqual(AppUnit.whitebelt_en.count, AppUnit.whitebelt_es.count,
                       "EN and ES catalogs must have the same number of nodes")
    }

    func test_sampleData_en_and_es_haveIdenticalIds() {
        let enIds = Set(AppUnit.whitebelt_en.map { $0.id })
        let esIds = Set(AppUnit.whitebelt_es.map { $0.id })
        XCTAssertEqual(enIds, esIds, "EN and ES catalogs must have identical unit IDs")
    }

    func test_sampleData_en_and_es_haveIdenticalKinds() {
        let sortedEN = AppUnit.whitebelt_en.sorted { $0.orderIndex < $1.orderIndex }
        let sortedES = AppUnit.whitebelt_es.sorted { $0.orderIndex < $1.orderIndex }
        for (en, es) in zip(sortedEN, sortedES) {
            XCTAssertEqual(en.kind, es.kind,
                           "Unit \(en.id): EN kind '\(en.kind)' != ES kind '\(es.kind)'")
        }
    }
}
