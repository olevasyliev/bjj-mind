import Foundation

// MARK: - Remote DTOs

private struct RemoteUnit: Decodable {
    let id: String
    let belt: String
    let orderIndex: Int
    let title: String
    let description: String
    let tags: [String]
    let coachIntro: String?
    let isBeltTest: Bool

    enum CodingKeys: String, CodingKey {
        case id, belt, title, description, tags
        case orderIndex  = "order_index"
        case coachIntro  = "coach_intro"
        case isBeltTest  = "is_belt_test"
    }
}

private struct RemoteQuestion: Decodable {
    let id: String
    let unitId: String
    let format: String
    let prompt: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String
    let tags: [String]
    let difficulty: Int
    let coachNote: String?

    enum CodingKeys: String, CodingKey {
        case id, format, prompt, options, explanation, tags, difficulty
        case unitId        = "unit_id"
        case correctAnswer = "correct_answer"
        case coachNote     = "coach_note"
    }

    var questionFormat: QuestionFormat {
        switch format {
        case "trueFalse": return .trueFalse
        case "fillBlank": return .fillBlank
        case "mcq2":      return .mcq2
        case "mcq4":      return .mcq4
        default:          return .mcq4  // "mcq" → 4-option grid
        }
    }

    func toQuestion() -> Question {
        Question(
            id: id, unitId: unitId, format: questionFormat,
            prompt: prompt, options: options, correctAnswer: correctAnswer,
            explanation: explanation, tags: tags, difficulty: difficulty,
            sceneImageName: nil, coachNote: coachNote
        )
    }
}

// MARK: - SupabaseService

actor SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    private let base = "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1"
    private let key  = "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W"

    /// Fetch all units with their questions, ordered by order_index.
    func fetchCatalog() async throws -> [RemoteUnitBundle] {
        let remoteUnits     = try await get([RemoteUnit].self,     "/units?order=order_index")
        let remoteQuestions = try await get([RemoteQuestion].self, "/questions?order=unit_id")
        let byUnit          = Dictionary(grouping: remoteQuestions, by: \.unitId)

        return remoteUnits.map { ru in
            RemoteUnitBundle(
                id:         ru.id,
                belt:       Belt(rawValue: ru.belt) ?? .white,
                orderIndex: ru.orderIndex,
                title:      ru.title,
                description: ru.description,
                tags:       ru.tags,
                isBeltTest: ru.isBeltTest,
                coachIntro: ru.coachIntro,
                questions:  (byUnit[ru.id] ?? []).map { $0.toQuestion() }
            )
        }
    }

    private func get<T: Decodable>(_ type: T.Type, _ path: String) async throws -> T {
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Plain struct to carry remote data across actor boundary

struct RemoteUnitBundle {
    let id: String
    let belt: Belt
    let orderIndex: Int
    let title: String
    let description: String
    let tags: [String]
    let isBeltTest: Bool
    let coachIntro: String?
    let questions: [Question]
}
