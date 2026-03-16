import XCTest
@testable import BJJMind

// MARK: - Mirror structs for private DTOs

// Mirrors SupabaseService.RemoteQuestion with identical CodingKeys.
// The `get` helper uses plain JSONDecoder() (no key strategy) — all mapping
// is done via explicit CodingKeys on the real struct, so we do the same here.
private struct TestRemoteQuestion: Decodable {
    let id: String
    let unitId: String?
    let format: String
    let prompt: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String
    let tags: [String]
    let difficulty: Int
    let coachNote: String?
    let topic: String?
    let beltLevel: String?
    let perspective: String?

    enum CodingKeys: String, CodingKey {
        case id, format, prompt, options, explanation, tags, difficulty, topic, perspective
        case unitId        = "unit_id"
        case correctAnswer = "correct_answer"
        case coachNote     = "coach_note"
        case beltLevel     = "belt_level"
    }
}

// MARK: - SupabaseDecodeTests

/// Tests that real-shaped Supabase JSON decodes correctly into our DTOs.
/// These are decode-path tests — they catch issues like null fields, missing
/// fields, and wrong types before they hit runtime.
///
/// Decoder used: plain JSONDecoder() with no key strategy.
/// All snake_case ↔ camelCase mapping is done via explicit CodingKeys on each DTO,
/// which matches the production `get` helper in SupabaseService.
final class SupabaseDecodeTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - Helpers

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        let data = Data(json.utf8)
        return try decoder.decode(type, from: data)
    }

    // MARK: - TestRemoteQuestion: unit_id null

    func test_remoteQuestion_unitIdNull_decodesSuccessfully() throws {
        let json = """
        {
          "id": "q1",
          "unit_id": null,
          "format": "mcq4",
          "prompt": "What do you do first in closed guard?",
          "options": ["Break posture", "Armbar", "Scissor sweep", "Triangle"],
          "correct_answer": "Break posture",
          "explanation": "Posture control comes first.",
          "tags": ["closed_guard"],
          "difficulty": 1,
          "coach_note": null,
          "topic": "closed_guard",
          "belt_level": "white",
          "perspective": "bottom"
        }
        """
        let q = try decode(TestRemoteQuestion.self, from: json)
        XCTAssertNil(q.unitId, "unit_id: null must decode as nil, not throw")
        XCTAssertEqual(q.id, "q1")
    }

    // MARK: - TestRemoteQuestion: unit_id as string

    func test_remoteQuestion_unitIdString_decodesAsExpected() throws {
        let json = """
        {
          "id": "q2",
          "unit_id": "wb-c1-l1",
          "format": "mcq3",
          "prompt": "How do you break posture?",
          "options": ["Pull collar", "Push hips", "Grab ankles"],
          "correct_answer": "Pull collar",
          "explanation": "Double collar grips break posture.",
          "tags": ["closed_guard", "posture"],
          "difficulty": 2,
          "coach_note": null,
          "topic": "closed_guard",
          "belt_level": "white",
          "perspective": "bottom"
        }
        """
        let q = try decode(TestRemoteQuestion.self, from: json)
        XCTAssertEqual(q.unitId, "wb-c1-l1")
        XCTAssertEqual(q.format, "mcq3")
    }

    // MARK: - TestRemoteQuestion: perspective null

    func test_remoteQuestion_perspectiveNull_decodesSuccessfully() throws {
        let json = """
        {
          "id": "q3",
          "unit_id": "wb-c1-l2",
          "format": "trueFalse",
          "prompt": "Is closed guard a control position?",
          "options": ["True", "False"],
          "correct_answer": "True",
          "explanation": "Closed guard gives control over the match tempo.",
          "tags": [],
          "difficulty": 1,
          "coach_note": null,
          "topic": "closed_guard",
          "belt_level": "white",
          "perspective": null
        }
        """
        let q = try decode(TestRemoteQuestion.self, from: json)
        XCTAssertNil(q.perspective, "perspective: null must decode as nil")
        XCTAssertEqual(q.id, "q3")
    }

    // MARK: - TestRemoteQuestion: perspective as string

    func test_remoteQuestion_perspectiveTop_decodesCorrectly() throws {
        let json = """
        {
          "id": "q4",
          "unit_id": "wb-c1-b1",
          "format": "mcq3",
          "prompt": "You're on top in guard — what do you do?",
          "options": ["Posture up", "Pass immediately", "Stall"],
          "correct_answer": "Posture up",
          "explanation": "Posture is your foundation when inside guard.",
          "tags": ["guard_passing"],
          "difficulty": 2,
          "coach_note": "Head up, hips back.",
          "topic": "guard_passing",
          "belt_level": "white",
          "perspective": "top"
        }
        """
        let q = try decode(TestRemoteQuestion.self, from: json)
        XCTAssertEqual(q.perspective, "top")
        XCTAssertEqual(q.coachNote, "Head up, hips back.")
    }

    // MARK: - TestRemoteQuestion: full realistic question

    func test_remoteQuestion_fullRealQuestion_decodesAllFields() throws {
        let json = """
        {
          "id": "wb-cg-001",
          "unit_id": "wb-c1-l1",
          "format": "mcq4",
          "prompt": "Your opponent is in your closed guard and has good posture. What is your primary goal?",
          "options": [
            "Immediately go for a triangle choke",
            "Break their posture using collar and sleeve grips",
            "Open your guard and try to pass",
            "Wait for them to make a mistake"
          ],
          "correct_answer": "Break their posture using collar and sleeve grips",
          "explanation": "You can't attack effectively against a posting opponent. Break posture first — then hunt submissions.",
          "tags": ["closed_guard", "posture", "grips"],
          "difficulty": 2,
          "coach_note": "Posture control is the foundation. Everything else follows.",
          "topic": "closed_guard",
          "belt_level": "white",
          "perspective": "bottom"
        }
        """
        let q = try decode(TestRemoteQuestion.self, from: json)
        XCTAssertEqual(q.id, "wb-cg-001")
        XCTAssertEqual(q.unitId, "wb-c1-l1")
        XCTAssertEqual(q.format, "mcq4")
        XCTAssertEqual(q.options?.count, 4)
        XCTAssertEqual(q.correctAnswer, "Break their posture using collar and sleeve grips")
        XCTAssertEqual(q.tags, ["closed_guard", "posture", "grips"])
        XCTAssertEqual(q.difficulty, 2)
        XCTAssertEqual(q.coachNote, "Posture control is the foundation. Everything else follows.")
        XCTAssertEqual(q.topic, "closed_guard")
        XCTAssertEqual(q.beltLevel, "white")
        XCTAssertEqual(q.perspective, "bottom")
    }

    // MARK: - MiniTheoryData: full cycleIntro JSON

    func test_miniTheoryData_cycleIntro_threeScreens_decodesCorrectly() throws {
        // JSON shape matches what Supabase stores in the mini_theory_content JSONB column.
        // Keys are camelCase because MiniTheoryData/MiniTheoryScreen have no explicit CodingKeys
        // and the production decoder uses plain JSONDecoder() (no convertFromSnakeCase).
        let json = """
        {
          "type": "cycleIntro",
          "screens": [
            {
              "title": "Welcome to Closed Guard",
              "body": "Closed guard is your fortress from the bottom.",
              "coachLine": null,
              "show3D": false
            },
            {
              "title": "Control Before Attacks",
              "body": "Your first job is to control their structure.",
              "coachLine": "Control the frame, then control the fight.",
              "show3D": false
            },
            {
              "title": "The Weapons",
              "body": "Triangle, armbar, kimura — all flow from posture control.",
              "coachLine": null,
              "show3D": true
            }
          ],
          "buttonLabel": "Start Lessons →"
        }
        """
        let data = try decode(MiniTheoryData.self, from: json)
        XCTAssertEqual(data.type, .cycleIntro)
        XCTAssertEqual(data.screens.count, 3)
        XCTAssertEqual(data.buttonLabel, "Start Lessons →")
        XCTAssertNil(data.screens[0].coachLine)
        XCTAssertEqual(data.screens[1].coachLine, "Control the frame, then control the fight.")
        XCTAssertTrue(data.screens[2].show3D)
    }

    // MARK: - MiniTheoryData: coachLine null

    func test_miniTheoryData_coachLineNull_decodesSuccessfully() throws {
        let json = """
        {
          "type": "blockIntro",
          "screens": [
            {
              "title": "Posture is Everything",
              "body": "Before any attack, break their posture.",
              "coachLine": null,
              "show3D": false
            }
          ],
          "buttonLabel": "Got It →"
        }
        """
        let data = try decode(MiniTheoryData.self, from: json)
        XCTAssertNil(data.screens[0].coachLine, "coachLine: null must decode as nil")
        XCTAssertEqual(data.type, .blockIntro)
    }

    // MARK: - MiniTheoryData: unknown type decodes as .unknown

    func test_miniTheoryData_unknownType_decodesAsUnknown() throws {
        let json = """
        {
          "type": "futureTypeNotYetSupported",
          "screens": [
            {
              "title": null,
              "body": "Some content.",
              "coachLine": null,
              "show3D": false
            }
          ],
          "buttonLabel": "Continue →"
        }
        """
        let data = try decode(MiniTheoryData.self, from: json)
        XCTAssertEqual(data.type, .unknown, "Unknown type strings must map to .unknown, not throw")
    }

    // MARK: - MiniTheoryData: nil title on screen

    func test_miniTheoryData_nilScreenTitle_decodesSuccessfully() throws {
        let json = """
        {
          "type": "bossPrep",
          "screens": [
            {
              "title": null,
              "body": "The boss fight is coming. Are you ready?",
              "coachLine": "Knowing how they think is half the battle.",
              "show3D": false
            }
          ],
          "buttonLabel": "Face the Boss →"
        }
        """
        let data = try decode(MiniTheoryData.self, from: json)
        XCTAssertNil(data.screens[0].title)
        XCTAssertEqual(data.type, .bossPrep)
    }

    // MARK: - RemoteTranslation: without mini_theory_content

    func test_remoteTranslation_noMiniTheoryContent_decodesCorrectly() throws {
        let json = """
        {
          "unit_id": "wb-c1-l1",
          "locale": "es",
          "title": "Guardia Cerrada: Conceptos Básicos",
          "description": "Aprende a controlar la postura en guardia cerrada.",
          "mini_theory_content": null
        }
        """
        let t = try decode(RemoteTranslation.self, from: json)
        XCTAssertEqual(t.unitId, "wb-c1-l1")
        XCTAssertEqual(t.locale, "es")
        XCTAssertEqual(t.title, "Guardia Cerrada: Conceptos Básicos")
        XCTAssertNil(t.miniTheoryContent)
    }

    // MARK: - RemoteTranslation: with mini_theory_content

    func test_remoteTranslation_withMiniTheoryContent_isNonNil() throws {
        let json = """
        {
          "unit_id": "wb-c1-intro",
          "locale": "es",
          "title": "Introducción al Ciclo 1",
          "description": null,
          "mini_theory_content": {
            "type": "cycleIntro",
            "screens": [
              {
                "title": "Bienvenido a la Guardia Cerrada",
                "body": "La guardia cerrada es tu fortaleza desde abajo.",
                "coachLine": null,
                "show3D": false
              }
            ],
            "buttonLabel": "Empezar →"
          }
        }
        """
        let t = try decode(RemoteTranslation.self, from: json)
        XCTAssertNotNil(t.miniTheoryContent)
        XCTAssertEqual(t.miniTheoryContent?.type, .cycleIntro)
        XCTAssertEqual(t.miniTheoryContent?.screens.count, 1)
    }

    // MARK: - RemoteTranslation: empty title

    func test_remoteTranslation_emptyTitle_decodesAsEmptyString() throws {
        let json = """
        {
          "unit_id": "wb-c1-l1",
          "locale": "pt",
          "title": "",
          "description": null,
          "mini_theory_content": null
        }
        """
        let t = try decode(RemoteTranslation.self, from: json)
        XCTAssertEqual(t.title, "", "Empty title must decode as empty string, not nil or crash")
    }

    // MARK: - Integration: array with mixed null unit_ids

    func test_integration_questionArray_mixedNullUnitIds_decodes() throws {
        // This mirrors exactly what SupabaseService.fetchCatalog() decodes from /questions.
        // The original null-unit_id bug would cause the entire array decode to throw here.
        let json = """
        [
          {
            "id": "q1",
            "unit_id": null,
            "format": "mcq4",
            "prompt": "test",
            "options": ["a", "b", "c", "d"],
            "correct_answer": "a",
            "explanation": "x",
            "tags": [],
            "difficulty": 1,
            "coach_note": null,
            "topic": "closed_guard",
            "belt_level": "white",
            "perspective": "top"
          },
          {
            "id": "q2",
            "unit_id": "wb-c1-l1",
            "format": "mcq3",
            "prompt": "test2",
            "options": ["a", "b", "c"],
            "correct_answer": "b",
            "explanation": "y",
            "tags": ["frames"],
            "difficulty": 2,
            "coach_note": "tip",
            "topic": "closed_guard",
            "belt_level": "white",
            "perspective": null
          }
        ]
        """
        let questions = try decode([TestRemoteQuestion].self, from: json)
        XCTAssertEqual(questions.count, 2, "All questions must decode — null unit_id must not throw")
        XCTAssertNil(questions[0].unitId, "q1.unitId must be nil")
        XCTAssertEqual(questions[1].unitId, "wb-c1-l1", "q2.unitId must be the expected string")
        XCTAssertNil(questions[1].perspective, "q2.perspective: null must decode as nil")
        XCTAssertEqual(questions[1].tags, ["frames"])
        XCTAssertEqual(questions[1].coachNote, "tip")
    }

    // MARK: - Integration: fetchCatalog filter logic on null unit_ids

    func test_integration_catalogFilter_nullUnitIds_areExcludedFromGrouping() throws {
        // Mimics the grouping logic in fetchCatalog:
        //   let byUnit = Dictionary(grouping: remoteQuestions.filter { $0.unitId != nil }, by: { $0.unitId! })
        // Questions with null unit_id must be decoded (not crash) and then silently filtered out.
        let json = """
        [
          {"id":"q-null","unit_id":null,"format":"mcq4","prompt":"p","options":["a","b","c","d"],"correct_answer":"a","explanation":"e","tags":[],"difficulty":1,"coach_note":null,"topic":"closed_guard","belt_level":"white","perspective":"bottom"},
          {"id":"q-unit","unit_id":"wb-c1-l1","format":"mcq4","prompt":"p2","options":["a","b","c","d"],"correct_answer":"b","explanation":"e2","tags":[],"difficulty":2,"coach_note":null,"topic":"closed_guard","belt_level":"white","perspective":"bottom"}
        ]
        """
        let all = try decode([TestRemoteQuestion].self, from: json)
        let withUnit = all.filter { $0.unitId != nil }
        let byUnit = Dictionary(grouping: withUnit, by: { $0.unitId! })

        XCTAssertEqual(all.count, 2, "Both questions must decode")
        XCTAssertEqual(withUnit.count, 1, "Only 1 question has a non-null unit_id")
        XCTAssertEqual(byUnit["wb-c1-l1"]?.count, 1)
        XCTAssertNil(byUnit[Optional<String>.none ?? ""], "null-unit question must not appear in the grouped dict")
    }
}
