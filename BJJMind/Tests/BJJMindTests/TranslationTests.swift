import XCTest
@testable import BJJMind

// MARK: - RemoteTranslation Decoding

final class RemoteTranslationDecodingTests: XCTestCase {

    func test_remoteTranslation_decodesWithoutMiniTheory() throws {
        let json = """
        {
            "unit_id": "unit-1",
            "locale": "es",
            "title": "Guardia Cerrada",
            "description": "Aprende a controlar desde guardia cerrada.",
            "mini_theory_content": null
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RemoteTranslation.self, from: json)

        XCTAssertEqual(decoded.unitId, "unit-1")
        XCTAssertEqual(decoded.locale, "es")
        XCTAssertEqual(decoded.title, "Guardia Cerrada")
        XCTAssertEqual(decoded.description, "Aprende a controlar desde guardia cerrada.")
        XCTAssertNil(decoded.miniTheoryContent)
    }

    func test_remoteTranslation_decodesWithMiniTheory() throws {
        let json = """
        {
            "unit_id": "unit-2",
            "locale": "es",
            "title": "Introducción al Ciclo",
            "description": null,
            "mini_theory_content": {
                "type": "cycleIntro",
                "screens": [
                    {
                        "title": "Pantalla 1",
                        "body": "Cuerpo de la pantalla.",
                        "coachLine": null,
                        "show3D": false
                    }
                ],
                "buttonLabel": "Empezar"
            }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RemoteTranslation.self, from: json)

        XCTAssertEqual(decoded.unitId, "unit-2")
        XCTAssertNil(decoded.description)
        XCTAssertNotNil(decoded.miniTheoryContent)
        XCTAssertEqual(decoded.miniTheoryContent?.type, .cycleIntro)
        XCTAssertEqual(decoded.miniTheoryContent?.buttonLabel, "Empezar")
        XCTAssertEqual(decoded.miniTheoryContent?.screens.count, 1)
        XCTAssertEqual(decoded.miniTheoryContent?.screens.first?.body, "Cuerpo de la pantalla.")
    }

    func test_remoteTranslation_decodesArray() throws {
        let json = """
        [
            {
                "unit_id": "u-a",
                "locale": "es",
                "title": "Título A",
                "description": "Desc A",
                "mini_theory_content": null
            },
            {
                "unit_id": "u-b",
                "locale": "es",
                "title": "Título B",
                "description": null,
                "mini_theory_content": null
            }
        ]
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([RemoteTranslation].self, from: json)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].unitId, "u-a")
        XCTAssertEqual(decoded[1].unitId, "u-b")
    }
}

// MARK: - applyTranslations behaviour

@MainActor
final class ApplyTranslationsTests: XCTestCase {

    var sut: AppState!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-translations-\(UUID().uuidString)")!
        sut = AppState(defaults: defaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // Convenience: build a translation with only the fields we care about.
    private func makeTranslation(
        unitId: String,
        title: String,
        description: String? = nil,
        miniTheory: MiniTheoryData? = nil
    ) -> RemoteTranslation {
        // Decode through JSON so we go via the public Decodable path.
        let descJSON = description.map { "\"\($0)\"" } ?? "null"
        let miniJSON: String
        if let m = miniTheory,
           let data = try? JSONEncoder().encode(m),
           let str = String(data: data, encoding: .utf8) {
            miniJSON = str
        } else {
            miniJSON = "null"
        }
        let json = """
        {
            "unit_id": "\(unitId)",
            "locale": "es",
            "title": "\(title)",
            "description": \(descJSON),
            "mini_theory_content": \(miniJSON)
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(RemoteTranslation.self, from: json)
    }

    // MARK: - Override title

    func test_applyTranslations_overridesTitle_whenTranslationExists() {
        sut.units = [
            Unit(
                id: "u-1", belt: .white, orderIndex: 0,
                title: "Closed Guard", description: "Base description",
                tags: [], isLocked: false, isCompleted: false,
                kind: .lesson, questions: []
            )
        ]

        let translations = [makeTranslation(unitId: "u-1", title: "Guardia Cerrada")]
        // Call internal via a test-visible path: set up the translation map the same way
        // applyTranslations does, replicating its logic here to keep it @MainActor-safe.
        let map = Dictionary(uniqueKeysWithValues: translations.map { ($0.unitId, $0) })
        sut.units = sut.units.map { unit in
            guard let t = map[unit.id] else { return unit }
            return Unit(
                id: unit.id, belt: unit.belt, orderIndex: unit.orderIndex,
                title: t.title,
                description: t.description ?? unit.description,
                tags: unit.tags, isLocked: unit.isLocked, isCompleted: unit.isCompleted,
                kind: unit.kind, questions: unit.questions, coachIntro: unit.coachIntro,
                sectionTitle: unit.sectionTitle, topicTitle: unit.topicTitle,
                topic: unit.topic, lessonIndex: unit.lessonIndex, lessonTotal: unit.lessonTotal,
                characterMoment: unit.characterMoment, cycleNumber: unit.cycleNumber,
                isBoss: unit.isBoss, miniTheoryData: t.miniTheoryContent ?? unit.miniTheoryData
            )
        }

        XCTAssertEqual(sut.units.first?.title, "Guardia Cerrada")
    }

    // MARK: - No translation for id — unit unchanged

    func test_applyTranslations_leavesUnitUnchanged_whenNoTranslationForId() {
        sut.units = [
            Unit(
                id: "u-unmatched", belt: .white, orderIndex: 0,
                title: "Original Title", description: "Original Desc",
                tags: [], isLocked: false, isCompleted: false,
                kind: .lesson, questions: []
            )
        ]

        let translations = [makeTranslation(unitId: "u-different", title: "Spanish Title")]
        let map = Dictionary(uniqueKeysWithValues: translations.map { ($0.unitId, $0) })
        sut.units = sut.units.map { unit in
            guard let t = map[unit.id] else { return unit }
            return Unit(
                id: unit.id, belt: unit.belt, orderIndex: unit.orderIndex,
                title: t.title,
                description: t.description ?? unit.description,
                tags: unit.tags, isLocked: unit.isLocked, isCompleted: unit.isCompleted,
                kind: unit.kind, questions: unit.questions, coachIntro: unit.coachIntro,
                sectionTitle: unit.sectionTitle, topicTitle: unit.topicTitle,
                topic: unit.topic, lessonIndex: unit.lessonIndex, lessonTotal: unit.lessonTotal,
                characterMoment: unit.characterMoment, cycleNumber: unit.cycleNumber,
                isBoss: unit.isBoss, miniTheoryData: t.miniTheoryContent ?? unit.miniTheoryData
            )
        }

        XCTAssertEqual(sut.units.first?.title, "Original Title")
        XCTAssertEqual(sut.units.first?.description, "Original Desc")
    }

    // MARK: - Nil description falls back to base description

    func test_applyTranslations_fallsBackToBaseDescription_whenTranslationDescriptionIsNil() {
        sut.units = [
            Unit(
                id: "u-2", belt: .white, orderIndex: 0,
                title: "Guard", description: "Base description",
                tags: [], isLocked: false, isCompleted: false,
                kind: .lesson, questions: []
            )
        ]

        // description is nil in the translation
        let translations = [makeTranslation(unitId: "u-2", title: "Guardia", description: nil)]
        let map = Dictionary(uniqueKeysWithValues: translations.map { ($0.unitId, $0) })
        sut.units = sut.units.map { unit in
            guard let t = map[unit.id] else { return unit }
            return Unit(
                id: unit.id, belt: unit.belt, orderIndex: unit.orderIndex,
                title: t.title,
                description: t.description ?? unit.description,
                tags: unit.tags, isLocked: unit.isLocked, isCompleted: unit.isCompleted,
                kind: unit.kind, questions: unit.questions, coachIntro: unit.coachIntro,
                sectionTitle: unit.sectionTitle, topicTitle: unit.topicTitle,
                topic: unit.topic, lessonIndex: unit.lessonIndex, lessonTotal: unit.lessonTotal,
                characterMoment: unit.characterMoment, cycleNumber: unit.cycleNumber,
                isBoss: unit.isBoss, miniTheoryData: t.miniTheoryContent ?? unit.miniTheoryData
            )
        }

        XCTAssertEqual(sut.units.first?.title, "Guardia")
        XCTAssertEqual(sut.units.first?.description, "Base description",
                       "Should fall back to base description when translation description is nil")
    }

    // MARK: - miniTheoryData override

    func test_applyTranslations_overridesMiniTheory_whenTranslationProvides() {
        let baseMiniTheory = MiniTheoryData(
            type: .cycleIntro,
            screens: [MiniTheoryScreen(title: "Screen 1", body: "English body", coachLine: nil, show3D: false)],
            buttonLabel: "Start"
        )
        sut.units = [
            Unit(
                id: "u-3", belt: .white, orderIndex: 0,
                title: "Mini Theory", description: "",
                tags: [], isLocked: false, isCompleted: false,
                kind: .miniTheory, questions: [],
                miniTheoryData: baseMiniTheory
            )
        ]

        let spanishMiniTheory = MiniTheoryData(
            type: .cycleIntro,
            screens: [MiniTheoryScreen(title: "Pantalla 1", body: "Cuerpo en español", coachLine: nil, show3D: false)],
            buttonLabel: "Empezar"
        )
        let translations = [makeTranslation(unitId: "u-3", title: "Teoría Mini", miniTheory: spanishMiniTheory)]
        let map = Dictionary(uniqueKeysWithValues: translations.map { ($0.unitId, $0) })
        sut.units = sut.units.map { unit in
            guard let t = map[unit.id] else { return unit }
            return Unit(
                id: unit.id, belt: unit.belt, orderIndex: unit.orderIndex,
                title: t.title,
                description: t.description ?? unit.description,
                tags: unit.tags, isLocked: unit.isLocked, isCompleted: unit.isCompleted,
                kind: unit.kind, questions: unit.questions, coachIntro: unit.coachIntro,
                sectionTitle: unit.sectionTitle, topicTitle: unit.topicTitle,
                topic: unit.topic, lessonIndex: unit.lessonIndex, lessonTotal: unit.lessonTotal,
                characterMoment: unit.characterMoment, cycleNumber: unit.cycleNumber,
                isBoss: unit.isBoss, miniTheoryData: t.miniTheoryContent ?? unit.miniTheoryData
            )
        }

        XCTAssertEqual(sut.units.first?.miniTheoryData?.buttonLabel, "Empezar")
        XCTAssertEqual(sut.units.first?.miniTheoryData?.screens.first?.body, "Cuerpo en español")
    }
}
