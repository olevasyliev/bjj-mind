import Foundation

// MARK: - Remote DTOs (Catalog)

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
        default:          return .mcq4
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

// MARK: - Remote DTOs (User & Progress)

struct RemoteUserProfile: Decodable {
    let id: UUID

    enum CodingKeys: String, CodingKey { case id }
}

struct RemoteUnitProgress: Decodable {
    let unitId: String
    let isCompleted: Bool
    let isLocked: Bool

    enum CodingKeys: String, CodingKey {
        case unitId      = "unit_id"
        case isCompleted = "is_completed"
        case isLocked    = "is_locked"
    }
}

// MARK: - Transfer bundle (crosses actor boundary)

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

// MARK: - SupabaseService

actor SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    private let base = "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1"
    private let key  = "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W"

    // MARK: Catalog

    func fetchCatalog() async throws -> [RemoteUnitBundle] {
        let remoteUnits     = try await get([RemoteUnit].self,     "/units?order=order_index")
        let remoteQuestions = try await get([RemoteQuestion].self, "/questions?order=unit_id")
        let byUnit          = Dictionary(grouping: remoteQuestions, by: \.unitId)

        return remoteUnits.map { ru in
            RemoteUnitBundle(
                id:          ru.id,
                belt:        Belt(rawValue: ru.belt) ?? .white,
                orderIndex:  ru.orderIndex,
                title:       ru.title,
                description: ru.description,
                tags:        ru.tags,
                isBeltTest:  ru.isBeltTest,
                coachIntro:  ru.coachIntro,
                questions:   (byUnit[ru.id] ?? []).map { $0.toQuestion() }
            )
        }
    }

    // MARK: User Profile

    /// Upserts an anonymous profile keyed by device_id. Returns the stable UUID.
    func upsertUserProfile(deviceId: String) async throws -> UUID {
        struct Body: Encodable { let device_id: String }
        let data = try await post(
            path: "/user_profiles?on_conflict=device_id",
            body: Body(device_id: deviceId),
            prefer: "return=representation,resolution=merge-duplicates"
        )
        let profiles = try JSONDecoder().decode([RemoteUserProfile].self, from: data)
        guard let profile = profiles.first else { throw SupabaseError.noData }
        return profile.id
    }

    // MARK: Unit Progress

    func fetchUnitProgress(userId: UUID) async throws -> [RemoteUnitProgress] {
        try await get([RemoteUnitProgress].self, "/unit_progress?user_id=eq.\(userId.uuidString)")
    }

    func upsertUnitProgress(userId: UUID, unitId: String, isCompleted: Bool, isLocked: Bool) async throws {
        struct Body: Encodable {
            let user_id: String
            let unit_id: String
            let is_completed: Bool
            let is_locked: Bool
        }
        _ = try await post(
            path: "/unit_progress?on_conflict=user_id,unit_id",
            body: Body(user_id: userId.uuidString, unit_id: unitId,
                       is_completed: isCompleted, is_locked: isLocked),
            prefer: "return=minimal,resolution=merge-duplicates"
        )
    }

    // MARK: Session Results

    func insertSessionResult(userId: UUID, unitId: String,
                             xpEarned: Int, accuracy: Double, heartsUsed: Int) async throws {
        struct Body: Encodable {
            let user_id: String
            let unit_id: String
            let xp_earned: Int
            let accuracy: Double
            let hearts_used: Int
        }
        _ = try await post(
            path: "/session_results",
            body: Body(user_id: userId.uuidString, unit_id: unitId,
                       xp_earned: xpEarned, accuracy: accuracy, hearts_used: heartsUsed),
            prefer: "return=minimal"
        )
    }

    // MARK: HTTP Helpers

    private func get<T: Decodable>(_ type: T.Type, _ path: String) async throws -> T {
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(type, from: data)
    }

    private func post<B: Encodable>(path: String, body: B, prefer: String) async throws -> Data {
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.httpMethod = "POST"
        req.setValue(key,               forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)",   forHTTPHeaderField: "Authorization")
        req.setValue("application/json",forHTTPHeaderField: "Content-Type")
        req.setValue(prefer,            forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }
}

// MARK: - Errors

enum SupabaseError: Error {
    case noData
}
