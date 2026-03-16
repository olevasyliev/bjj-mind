import XCTest
@testable import BJJMind

final class MiniTheoryViewTests: XCTestCase {

    // MARK: - Helpers

    private func makeScreen(
        title: String? = "Screen Title",
        body: String = "Body text here.",
        coachLine: String? = nil,
        show3D: Bool = false
    ) -> MiniTheoryScreen {
        MiniTheoryScreen(title: title, body: body, coachLine: coachLine, show3D: show3D)
    }

    private func makeData(
        screenCount: Int = 3,
        buttonLabel: String = "Let's Roll →",
        type: String = "blockIntro"
    ) -> MiniTheoryData {
        let screens = (0..<screenCount).map { i in
            MiniTheoryScreen(
                title: "Screen \(i + 1)",
                body: "Body for screen \(i + 1).",
                coachLine: nil,
                show3D: false
            )
        }
        let miniType = MiniTheoryType(rawValue: type) ?? .unknown
        return MiniTheoryData(type: miniType, screens: screens, buttonLabel: buttonLabel)
    }

    // MARK: - Screen count

    func test_miniTheoryData_screenCount_isCorrect() {
        let data = makeData(screenCount: 3)
        XCTAssertEqual(data.screens.count, 3)
    }

    func test_miniTheoryData_singleScreen_hasCountOne() {
        let data = makeData(screenCount: 1)
        XCTAssertEqual(data.screens.count, 1)
    }

    // MARK: - buttonLabel

    func test_miniTheoryData_buttonLabel_isAccessible() {
        let data = makeData(buttonLabel: "Let's Fight →")
        XCTAssertEqual(data.buttonLabel, "Let's Fight →")
    }

    func test_miniTheoryData_buttonLabel_startLessons_variant() {
        let data = makeData(buttonLabel: "Start Lessons →")
        XCTAssertEqual(data.buttonLabel, "Start Lessons →")
    }

    // MARK: - MiniTheoryScreen with nil title

    func test_miniTheoryScreen_nilTitle_decodesCorrectly() {
        let screen = makeScreen(title: nil, body: "Some body text.")
        XCTAssertNil(screen.title)
        XCTAssertEqual(screen.body, "Some body text.")
    }

    func test_miniTheoryScreen_nilCoachLine_decodesCorrectly() {
        let screen = makeScreen(coachLine: nil)
        XCTAssertNil(screen.coachLine)
    }

    func test_miniTheoryScreen_withCoachLine_isPresent() {
        let screen = makeScreen(coachLine: "Keep your elbows in.")
        XCTAssertEqual(screen.coachLine, "Keep your elbows in.")
    }

    func test_miniTheoryScreen_show3D_defaultsFalse() {
        let screen = makeScreen(show3D: false)
        XCTAssertFalse(screen.show3D)
    }

    func test_miniTheoryScreen_show3D_canBeTrue() {
        let screen = makeScreen(show3D: true)
        XCTAssertTrue(screen.show3D)
    }

    // MARK: - JSON round-trip (nil title)

    func test_miniTheoryScreen_jsonRoundTrip_nilTitle() throws {
        let original = MiniTheoryScreen(title: nil, body: "Test body.", coachLine: nil, show3D: false)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MiniTheoryScreen.self, from: encoded)
        XCTAssertNil(decoded.title)
        XCTAssertEqual(decoded.body, "Test body.")
    }

    func test_miniTheoryData_jsonRoundTrip_preservesScreenCount() throws {
        let original = makeData(screenCount: 3, buttonLabel: "Done!")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MiniTheoryData.self, from: encoded)
        XCTAssertEqual(decoded.screens.count, 3)
        XCTAssertEqual(decoded.buttonLabel, "Done!")
    }

    // MARK: - Completion flow (model level)

    func test_miniTheory_unitKind_isCorrect() {
        let unit = Unit(
            id: "mt-1", belt: .white, orderIndex: 0,
            title: "Closed Guard Intro", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .miniTheory, questions: [],
            miniTheoryData: makeData(screenCount: 2)
        )
        XCTAssertEqual(unit.kind, .miniTheory)
        XCTAssertFalse(unit.requiresSession)
    }

    func test_miniTheory_unit_miniTheoryDataIsPresent() {
        let data = makeData(screenCount: 2, buttonLabel: "Go!")
        let unit = Unit(
            id: "mt-2", belt: .white, orderIndex: 1,
            title: "Half Guard Intro", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .miniTheory, questions: [],
            miniTheoryData: data
        )
        XCTAssertNotNil(unit.miniTheoryData)
        XCTAssertEqual(unit.miniTheoryData?.screens.count, 2)
        XCTAssertEqual(unit.miniTheoryData?.buttonLabel, "Go!")
    }

    func test_miniTheory_unit_nilMiniTheoryData_doesNotCrash() {
        let unit = Unit(
            id: "mt-3", belt: .white, orderIndex: 2,
            title: "Orphan Node", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .miniTheory, questions: [],
            miniTheoryData: nil
        )
        XCTAssertNil(unit.miniTheoryData)
    }

    func test_miniTheory_bossPrep_type() {
        let data = makeData(screenCount: 1, buttonLabel: "Let's Fight →", type: "bossPrep")
        XCTAssertEqual(data.type, .bossPrep)
        XCTAssertEqual(data.screens.count, 1)
    }

    func test_miniTheory_cycleIntro_type() {
        let data = makeData(screenCount: 2, buttonLabel: "Start Lessons →", type: "cycleIntro")
        XCTAssertEqual(data.type, .cycleIntro)
        XCTAssertEqual(data.buttonLabel, "Start Lessons →")
    }
}
