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
    let kind: String?
    let sectionTitle: String?
    let topicTitle: String?
    let topic: String?         // BJJ topic slug (e.g. "guard_passing") — used for adaptive queries
    let lessonIndex: Int?
    let lessonTotal: Int?
    let characterName: String?
    let characterMessage: String?
    let cycleNumber: Int?
    let isBoss: Bool?
    let miniTheoryContent: MiniTheoryData?

    enum CodingKeys: String, CodingKey {
        case id, belt, title, description, tags, kind, topic
        case orderIndex         = "order_index"
        case coachIntro         = "coach_intro"
        case isBeltTest         = "is_belt_test"
        case sectionTitle       = "section_title"
        case topicTitle         = "topic_title"
        case lessonIndex        = "lesson_index"
        case lessonTotal        = "lesson_total"
        case characterName      = "character_name"
        case characterMessage   = "character_message"
        case cycleNumber        = "cycle_number"
        case isBoss             = "is_boss"
        case miniTheoryContent  = "mini_theory_content"
    }
}

private struct RemoteQuestion: Decodable {
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
    // Optional fields for adaptive fetching
    let topic: String?
    let beltLevel: String?
    let perspective: String?
    let subTopic: String?
    let language: String?

    enum CodingKeys: String, CodingKey {
        case id, format, prompt, options, explanation, tags, difficulty
        case unitId        = "unit_id"
        case correctAnswer = "correct_answer"
        case coachNote     = "coach_note"
        case topic
        case beltLevel     = "belt_level"
        case perspective
        case subTopic      = "sub_topic"
        case language
    }

    var questionFormat: QuestionFormat {
        switch format {
        case "trueFalse": return .trueFalse
        case "fillBlank": return .fillBlank
        case "mcq2":      return .mcq2
        case "mcq3":      return .mcq3
        case "mcq4":      return .mcq4
        default:          return .mcq4
        }
    }

    func toQuestion() -> Question {
        Question(
            id: id, unitId: unitId, format: questionFormat,
            prompt: prompt, options: options, correctAnswer: correctAnswer,
            explanation: explanation, tags: tags, difficulty: difficulty,
            sceneImageName: nil, coachNote: coachNote,
            topic: topic, subTopic: subTopic, language: language ?? "en"
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

struct RemoteQuestionStat: Decodable {
    let questionId: String
    let timesSeen: Int
    let timesWrong: Int
    let strength: Int?
    let lastSeen: Date?

    enum CodingKeys: String, CodingKey {
        case questionId  = "question_id"
        case timesSeen   = "times_seen"
        case timesWrong  = "times_wrong"
        case strength
        case lastSeen    = "last_seen"
    }

    func toQuestionStat() -> QuestionStat {
        QuestionStat(
            questionId: questionId,
            timesSeen: timesSeen,
            timesWrong: timesWrong,
            strength: strength ?? 0,
            lastSeen: lastSeen
        )
    }
}

// MARK: - Remote DTOs (Translations)

struct RemoteTranslation: Decodable {
    let unitId: String
    let locale: String
    let title: String
    let description: String?
    let miniTheoryContent: MiniTheoryData?

    enum CodingKeys: String, CodingKey {
        case unitId             = "unit_id"
        case locale
        case title
        case description
        case miniTheoryContent  = "mini_theory_content"
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
    let kind: UnitKind
    let sectionTitle: String?
    let topicTitle: String?
    let topic: String?         // BJJ topic slug (e.g. "guard_passing")
    let lessonIndex: Int?
    let lessonTotal: Int?
    let characterMoment: CharacterMomentData?
    let cycleNumber: Int?
    let isBoss: Bool
    let miniTheoryContent: MiniTheoryData?
}

// MARK: - SupabaseService

actor SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    private let base = "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1"
    private let key  = "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W"

    // Reused across calls to avoid repeated allocations.
    private let iso8601: ISO8601DateFormatter = ISO8601DateFormatter()

    // MARK: Catalog

    func fetchCatalog() async throws -> [RemoteUnitBundle] {
        let remoteUnits     = try await get([RemoteUnit].self,     "/units?order=order_index")
        let remoteQuestions = try await get([RemoteQuestion].self, "/questions?order=unit_id")
        let byUnit          = Dictionary(grouping: remoteQuestions.filter { $0.unitId != nil }, by: { $0.unitId! })

        return remoteUnits.map { ru in
            let resolvedKind: UnitKind
            if let rawKind = ru.kind {
                if let k = UnitKind(rawValue: rawKind) {
                    resolvedKind = k
                } else {
                    print("[Supabase] unknown kind '\(rawKind)' for unit \(ru.id), falling back to \(ru.isBeltTest ? "beltTest" : "lesson")")
                    resolvedKind = ru.isBeltTest ? .beltTest : .lesson
                }
            } else if ru.isBeltTest {
                resolvedKind = .beltTest
            } else {
                resolvedKind = .lesson
            }

            let characterMoment: CharacterMomentData?
            if resolvedKind == .characterMoment,
               let charName = ru.characterName,
               let charMsg  = ru.characterMessage {
                if let char = AppCharacter(rawValue: charName) {
                    characterMoment = CharacterMomentData(character: char, message: charMsg)
                } else {
                    print("[Supabase] unknown character_name '\(charName)' for unit \(ru.id) — expected one of: marco, oldChen, rex, giGhost")
                    characterMoment = nil
                }
            } else {
                characterMoment = nil
            }

            return RemoteUnitBundle(
                id:              ru.id,
                belt:            Belt(rawValue: ru.belt) ?? .white,
                orderIndex:      ru.orderIndex,
                title:           ru.title,
                description:     ru.description,
                tags:            ru.tags,
                isBeltTest:      ru.isBeltTest,
                coachIntro:      ru.coachIntro,
                questions:       (byUnit[ru.id] ?? []).map { $0.toQuestion() },
                kind:            resolvedKind,
                sectionTitle:    ru.sectionTitle,
                topicTitle:      ru.topicTitle,
                topic:           ru.topic,
                lessonIndex:     ru.lessonIndex,
                lessonTotal:     ru.lessonTotal,
                characterMoment: characterMoment,
                cycleNumber:     ru.cycleNumber,
                isBoss:          ru.isBoss ?? false,
                miniTheoryContent: ru.miniTheoryContent
            )
        }
    }

    // MARK: Translations

    func fetchTranslations(locale: String) async throws -> [RemoteTranslation] {
        let encoded = locale.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? locale
        return try await get(
            [RemoteTranslation].self,
            "/unit_translations?locale=eq.\(encoded)&select=unit_id,locale,title,description,mini_theory_content"
        )
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

    // MARK: Adaptive Question Fetching

    /// Fetches questions for a session, ordered adaptively based on user's history.
    ///
    /// Priority: never seen → weak (timesWrong ≥ 2) → seen-but-ok.
    /// Within each group, easier questions come first (difficulty ascending).
    ///
    /// Fetch strategy:
    ///  1. If `unitId` is provided and has questions in DB → use those (unit-specific pool).
    ///  2. Otherwise fall back to topic-wide pool, excluding battle questions (mcq3).
    ///
    /// - Parameters:
    ///   - topic:     The BJJ topic slug (e.g. "closed_guard").
    ///   - beltLevel: The belt level (e.g. "white").
    ///   - userId:    The authenticated user's UUID.
    ///   - count:     Maximum number of questions to return.
    ///   - unitId:    The specific unit ID to fetch questions for (tried first; optional).
    func fetchQuestionsForSession(
        topic: String,
        beltLevel: String,
        userId: UUID,
        count: Int,
        unitId: String? = nil
    ) async throws -> [Question] {
        // 1. Try unit-specific questions first (lesson-scoped pool)
        if let uid = unitId {
            let encodedUid = uid.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uid
            let unitQuestions: [RemoteQuestion] = try await get(
                [RemoteQuestion].self,
                "/questions?unit_id=eq.\(encodedUid)&format=neq.mcq3&order=id"
            )
            if !unitQuestions.isEmpty {
                let questions = unitQuestions.map { $0.toQuestion() }
                return try await applyAdaptiveSelection(to: questions, userId: userId, count: count)
            }
        }

        // 2. Fall back to topic-wide pool, excluding battle questions
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
        let encodedBelt  = beltLevel.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? beltLevel
        let remoteQuestions: [RemoteQuestion] = try await get(
            [RemoteQuestion].self,
            "/questions?topic=eq.\(encodedTopic)&belt_level=eq.\(encodedBelt)&format=neq.mcq3&order=id"
        )
        let questions = remoteQuestions.map { $0.toQuestion() }

        guard !questions.isEmpty else { return [] }

        return try await applyAdaptiveSelection(to: questions, userId: userId, count: count)
    }

    /// Fetches user stats for the given questions and applies adaptive ordering.
    private func applyAdaptiveSelection(to questions: [Question], userId: UUID, count: Int) async throws -> [Question] {
        let ids = questions.map { $0.id }.joined(separator: ",")
        let remoteStats: [RemoteQuestionStat] = try await get(
            [RemoteQuestionStat].self,
            "/user_question_stats?user_id=eq.\(userId.uuidString)&question_id=in.(\(ids))&select=question_id,times_seen,times_wrong,strength,last_seen"
        )
        let stats = remoteStats.map { $0.toQuestionStat() }
        return AdaptiveQuestionSelector.select(from: questions, stats: stats, count: count)
    }

    /// Fetches questions for a battle turn, filtered by position, perspective, and belt level.
    ///
    /// Primary fetch: topic + belt_level + perspective + format=mcq3.
    /// Fallback (if fewer than `count` results): drops perspective filter and shuffles.
    /// Applies adaptive ordering (unseen → weak → ok, easiest first) using user stats.
    ///
    /// - Parameters:
    ///   - position:    The BJJPosition the marker is currently on.
    ///   - perspective: "top" or "bottom" based on marker side of center.
    ///   - beltLevel:   The user's current belt level (e.g. "white").
    ///   - userId:      The authenticated user's UUID for adaptive prioritisation.
    ///   - count:       Maximum number of questions to return.
    func fetchQuestionsForBattle(
        position: BJJPosition,
        perspective: String,
        beltLevel: String,
        userId: UUID,
        count: Int
    ) async throws -> [Question] {
        let topic = position.topic
        let encodedTopic   = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
        let encodedBelt    = beltLevel.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? beltLevel
        let encodedPersp   = perspective.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? perspective

        // Primary: filter by topic + belt + perspective + mcq3 format
        let primary: [RemoteQuestion] = try await get(
            [RemoteQuestion].self,
            "/questions?topic=eq.\(encodedTopic)&belt_level=eq.\(encodedBelt)&perspective=eq.\(encodedPersp)&format=eq.mcq3&order=id"
        )

        var questions = primary.map { $0.toQuestion() }

        // Fallback: if sparse, fetch without perspective filter and shuffle
        if questions.count < count {
            let fallback: [RemoteQuestion] = try await get(
                [RemoteQuestion].self,
                "/questions?topic=eq.\(encodedTopic)&belt_level=eq.\(encodedBelt)&format=eq.mcq3&order=id"
            )
            let fallbackQuestions = fallback.map { $0.toQuestion() }
            // Merge: keep primary questions, add any from fallback not already present
            let existingIds = Set(questions.map { $0.id })
            let extras = fallbackQuestions.filter { !existingIds.contains($0.id) }.shuffled()
            questions = questions + extras
        }

        guard !questions.isEmpty else { return [] }

        // Fetch user stats for adaptive ordering
        let ids = questions.map { $0.id }.joined(separator: ",")
        let remoteStats: [RemoteQuestionStat] = try await get(
            [RemoteQuestionStat].self,
            "/user_question_stats?user_id=eq.\(userId.uuidString)&question_id=in.(\(ids))&select=question_id,times_seen,times_wrong,strength,last_seen"
        )
        let stats = remoteStats.map { $0.toQuestionStat() }

        return AdaptiveQuestionSelector.select(from: questions, stats: stats, count: count)
    }

    /// Atomically increments question stats for a user after a session.
    ///
    /// Calls the `increment_question_stats` Supabase RPC (PostgreSQL function) which
    /// uses `ON CONFLICT DO UPDATE SET col = col + 1` — a true atomic increment.
    /// This avoids the PostgREST `merge-duplicates` behaviour which overwrites the
    /// existing value with the incoming value (always resetting to 1).
    ///
    /// - Parameters:
    ///   - userId:     The authenticated user's UUID.
    ///   - questionId: The question that was answered.
    ///   - wasWrong:   Whether the user answered incorrectly.
    func upsertQuestionStats(userId: UUID, questionId: String, wasWrong: Bool) async throws {
        struct Body: Encodable {
            let p_user_id: String
            let p_question_id: String
            let p_was_wrong: Bool
        }

        _ = try await post(
            path: "/rpc/increment_question_stats",
            body: Body(
                p_user_id: userId.uuidString,
                p_question_id: questionId,
                p_was_wrong: wasWrong
            ),
            prefer: "return=minimal"
        )
    }

    // MARK: - v2 Adaptive Session Methods

    /// Calls fetch_session_questions RPC and returns ordered questions (6-9).
    func fetchSessionComposition(
        userId: UUID,
        topic: String,
        beltLevel: String,
        language: String = "en",
        sessionSize: Int = 9
    ) async throws -> [Question] {
        struct Body: Encodable {
            let p_user_id: String
            let p_topic: String
            let p_belt_level: String
            let p_language: String
            let p_session_size: Int
        }
        let data = try await post(
            path: "/rpc/fetch_session_questions",
            body: Body(
                p_user_id: userId.uuidString,
                p_topic: topic,
                p_belt_level: beltLevel,
                p_language: language,
                p_session_size: sessionSize
            ),
            prefer: "return=representation"
        )
        let remote = try JSONDecoder().decode([RemoteQuestion].self, from: data)
        return remote.map { $0.toQuestion() }
    }

    /// Calls increment_question_strength RPC.
    func updateQuestionStrength(
        userId: UUID,
        questionId: String,
        wasWrong: Bool,
        firstAttempt: Bool = true
    ) async throws {
        struct Body: Encodable {
            let p_user_id: String
            let p_question_id: String
            let p_was_wrong: Bool
            let p_first_attempt: Bool
        }
        _ = try await post(
            path: "/rpc/increment_question_strength",
            body: Body(
                p_user_id: userId.uuidString,
                p_question_id: questionId,
                p_was_wrong: wasWrong,
                p_first_attempt: firstAttempt
            ),
            prefer: "return=minimal"
        )
    }

    /// Fetches avg strength per sub-topic for the given topic.
    func fetchSubTopicProgress(
        userId: UUID,
        topic: String,
        subTopics: [String],
        beltLevel: String
    ) async throws -> [String: Int] {
        struct Body: Encodable {
            let p_user_id: String
            let p_topic: String
            let p_belt_level: String
        }
        struct Row: Decodable {
            let subTopic: String
            let avgStrength: Int
            enum CodingKeys: String, CodingKey {
                case subTopic    = "sub_topic"
                case avgStrength = "avg_strength"
            }
        }
        do {
            let data = try await post(
                path: "/rpc/get_subtopic_progress",
                body: Body(p_user_id: userId.uuidString, p_topic: topic, p_belt_level: beltLevel),
                prefer: "return=representation"
            )
            let rows = try JSONDecoder().decode([Row].self, from: data)
            var result: [String: Int] = Dictionary(uniqueKeysWithValues: subTopics.map { ($0, 0) })
            for row in rows { result[row.subTopic] = row.avgStrength }
            return result
        } catch {
            // Fallback: return zeros for all sub-topics
            return Dictionary(uniqueKeysWithValues: subTopics.map { ($0, 0) })
        }
    }

    /// Fetches question stats for the given question IDs.
    func fetchQuestionStats(userId: UUID, questionIds: [String]) async throws -> [QuestionStat] {
        guard !questionIds.isEmpty else { return [] }
        let idList = questionIds.joined(separator: ",")
        let path = "/user_question_stats?user_id=eq.\(userId.uuidString)&question_id=in.(\(idList))&select=question_id,times_seen,times_wrong,strength,last_seen"
        let remote: [RemoteQuestionStat] = try await get([RemoteQuestionStat].self, path)
        return remote.map { $0.toQuestionStat() }
    }

    /// Calls apply_strength_decay RPC. Called once per app launch.
    func triggerStrengthDecay(userId: UUID) async throws {
        struct Body: Encodable { let p_user_id: String }
        _ = try await post(
            path: "/rpc/apply_strength_decay",
            body: Body(p_user_id: userId.uuidString),
            prefer: "return=minimal"
        )
    }

    // MARK: HTTP Helpers

    private func get<T: Decodable>(_ type: T.Type, _ path: String) async throws -> T {
        guard let url = URL(string: "\(base)\(path)") else {
            throw SupabaseError.invalidURL("\(base)\(path)")
        }
        var req = URLRequest(url: url)
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SupabaseError.httpError(statusCode: http.statusCode, body: data)
        }
        return try JSONDecoder().decode(type, from: data)
    }

    private func post<B: Encodable>(path: String, body: B, prefer: String) async throws -> Data {
        guard let url = URL(string: "\(base)\(path)") else {
            throw SupabaseError.invalidURL("\(base)\(path)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(key,               forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)",   forHTTPHeaderField: "Authorization")
        req.setValue("application/json",forHTTPHeaderField: "Content-Type")
        req.setValue(prefer,            forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SupabaseError.httpError(statusCode: http.statusCode, body: data)
        }
        return data
    }
}

// MARK: - Errors

enum SupabaseError: Error {
    case noData
    case invalidURL(_ url: String)
    case httpError(statusCode: Int, body: Data)
}
