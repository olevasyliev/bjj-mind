import XCTest
@testable import BJJMind

// Typealiases to avoid ambiguity with Foundation.Unit / NSUnit
private typealias AppUnit = BJJMind.Unit
private typealias AppUnitKind = BJJMind.UnitKind

final class CycleStructureTests: XCTestCase {

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

    // MARK: - UnitKind.miniTheory

    func test_unitKind_miniTheory_exists() {
        let kind = AppUnitKind.miniTheory
        XCTAssertEqual(kind.rawValue, "miniTheory")
    }

    func test_unitKind_miniTheory_doesNotRequireSession() {
        let unit = AppUnit(
            id: "mt-1", belt: .white, orderIndex: 0,
            title: "Intro", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .miniTheory, questions: []
        )
        XCTAssertFalse(unit.requiresSession)
    }

    func test_unitKind_miniTheory_isNotBossFight() {
        let unit = AppUnit(
            id: "mt-2", belt: .white, orderIndex: 0,
            title: "Intro", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .miniTheory, questions: []
        )
        XCTAssertFalse(unit.isBossFight)
        XCTAssertFalse(unit.isTournament)
        XCTAssertFalse(unit.isBeltTest)
    }

    // MARK: - MiniTheoryData decoding

    func test_miniTheoryData_decodesFromJSON() throws {
        let json = """
        {
            "type": "cycleIntro",
            "screens": [
                {"title": "Closed Guard", "body": "Control the distance.", "coachLine": "Stay tight.", "show3D": false},
                {"body": "Break posture first.", "show3D": true}
            ],
            "buttonLabel": "Let's go"
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(MiniTheoryData.self, from: json)
        XCTAssertEqual(data.type, "cycleIntro")
        XCTAssertEqual(data.screens.count, 2)
        XCTAssertEqual(data.screens[0].title, "Closed Guard")
        XCTAssertEqual(data.screens[0].body, "Control the distance.")
        XCTAssertEqual(data.screens[0].coachLine, "Stay tight.")
        XCTAssertFalse(data.screens[0].show3D)
        XCTAssertNil(data.screens[1].title)
        XCTAssertNil(data.screens[1].coachLine)
        XCTAssertTrue(data.screens[1].show3D)
        XCTAssertEqual(data.buttonLabel, "Let's go")
    }

    func test_miniTheoryScreen_equatable() {
        let s1 = MiniTheoryScreen(title: "A", body: "Body", coachLine: nil, show3D: false)
        let s2 = MiniTheoryScreen(title: "A", body: "Body", coachLine: nil, show3D: false)
        let s3 = MiniTheoryScreen(title: "B", body: "Body", coachLine: nil, show3D: false)
        XCTAssertEqual(s1, s2)
        XCTAssertNotEqual(s1, s3)
    }

    func test_miniTheoryData_equatable() {
        let screen = MiniTheoryScreen(title: nil, body: "Test", coachLine: nil, show3D: false)
        let d1 = MiniTheoryData(type: "blockIntro", screens: [screen], buttonLabel: "OK")
        let d2 = MiniTheoryData(type: "blockIntro", screens: [screen], buttonLabel: "OK")
        let d3 = MiniTheoryData(type: "bossPrep", screens: [screen], buttonLabel: "OK")
        XCTAssertEqual(d1, d2)
        XCTAssertNotEqual(d1, d3)
    }

    // MARK: - Unit with miniTheoryData encode/decode roundtrip

    func test_unit_withMiniTheoryData_codableRoundtrip() throws {
        let screen = MiniTheoryScreen(title: "Welcome", body: "Closed guard basics.", coachLine: "Stay low.", show3D: false)
        let theory = MiniTheoryData(type: "cycleIntro", screens: [screen], buttonLabel: "Start")
        let unit = AppUnit(
            id: "mt-unit-1", belt: .white, orderIndex: 5,
            title: "Cycle 1 Intro", description: "Intro to closed guard",
            tags: ["guard"], isLocked: false, isCompleted: false,
            kind: .miniTheory, questions: [],
            cycleNumber: 1,
            miniTheoryData: theory
        )

        let encoded = try JSONEncoder().encode(unit)
        let decoded = try JSONDecoder().decode(AppUnit.self, from: encoded)

        XCTAssertEqual(decoded.id, "mt-unit-1")
        XCTAssertEqual(decoded.kind, .miniTheory)
        XCTAssertNotNil(decoded.miniTheoryData)
        XCTAssertEqual(decoded.miniTheoryData?.type, "cycleIntro")
        XCTAssertEqual(decoded.miniTheoryData?.screens.count, 1)
        XCTAssertEqual(decoded.miniTheoryData?.screens[0].title, "Welcome")
        XCTAssertEqual(decoded.miniTheoryData?.buttonLabel, "Start")
        XCTAssertEqual(decoded.cycleNumber, 1)
    }

    func test_unit_withoutMiniTheoryData_miniTheoryDataIsNil() throws {
        let unit = AppUnit(
            id: "lesson-1", belt: .white, orderIndex: 1,
            title: "Lesson", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .lesson, questions: []
        )
        XCTAssertNil(unit.miniTheoryData)

        let encoded = try JSONEncoder().encode(unit)
        let decoded = try JSONDecoder().decode(AppUnit.self, from: encoded)
        XCTAssertNil(decoded.miniTheoryData)
    }
}
