import Foundation

// MARK: - Belt

enum Belt: String, Codable, CaseIterable {
    case white, blue, purple, brown, black

    var displayName: String { rawValue.capitalized }
    var maxStripes: Int { 4 }
}

// MARK: - UserProfile

struct UserProfile: Codable {
    var id: String
    var displayName: String
    var belt: Belt
    private(set) var stripes: Int
    var xpTotal: Int
    var streakCurrent: Int
    var streakLongest: Int
    var hearts: Int
    var gems: Int
    var weakTags: [String]

    static let maxHearts = 5

    mutating func addStripe() {
        stripes = min(stripes + 1, belt.maxStripes)
    }

    static var guest: UserProfile {
        UserProfile(
            id: UUID().uuidString,
            displayName: "Practitioner",
            belt: .white,
            stripes: 0,
            xpTotal: 0,
            streakCurrent: 0,
            streakLongest: 0,
            hearts: maxHearts,
            gems: 100,
            weakTags: []
        )
    }
}

// MARK: - UnitKind

enum UnitKind: String, Codable {
    case lesson           // regular lesson (~4-8 questions) within a topic
    case mixedReview      // cross-topic review lesson
    case miniExam         // section-level exam (~8 questions)
    case beltTest         // existing stripe belt test
    case characterMoment  // character card — no questions, tap to complete
}

// MARK: - AppCharacter

/// Raw values must match Supabase `character_name` column exactly (case-sensitive).
/// Valid values: "marco", "oldChen", "rex", "giGhost"
enum AppCharacter: String, Codable {
    case marco, oldChen, rex, giGhost

    var displayName: String {
        switch self {
        case .marco:    return "Marco"
        case .oldChen:  return "Old Chen"
        case .rex:      return "Rex"
        case .giGhost:  return "Gi Ghost"
        }
    }
}

// MARK: - CharacterMomentData

struct CharacterMomentData: Codable, Equatable {
    var character: AppCharacter
    var message: String
}

// MARK: - Unit

struct Unit: Identifiable, Codable, Hashable {
    static func == (lhs: Unit, rhs: Unit) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var id: String
    var belt: Belt
    var orderIndex: Int
    var title: String
    var description: String
    var tags: [String]
    var isLocked: Bool
    var isCompleted: Bool
    var kind: UnitKind
    var questions: [Question]

    // Optional metadata
    var coachIntro: String?
    var sectionTitle: String?
    var topicTitle: String?
    var lessonIndex: Int?
    var lessonTotal: Int?
    var characterMoment: CharacterMomentData?

    // MARK: - Computed backward-compat
    var isBeltTest: Bool        { kind == .beltTest }
    var isCharacterMoment: Bool { kind == .characterMoment }
    var isMiniExam: Bool        { kind == .miniExam }
    var isMixedReview: Bool     { kind == .mixedReview }
    var requiresSession: Bool {
        switch kind {
        case .lesson, .mixedReview, .miniExam, .beltTest: return true
        case .characterMoment: return false
        }
    }
}

// MARK: - Question

enum QuestionFormat: String, Codable {
    case mcq2, mcq4, trueFalse, sequence, tapZone, fillBlank, spotMistake
}

struct Question: Identifiable, Codable {
    var id: String
    var unitId: String
    var format: QuestionFormat
    var prompt: String
    var options: [String]?
    var correctAnswer: String
    var explanation: String
    var tags: [String]
    private(set) var difficulty: Int
    var sceneImageName: String?
    var coachNote: String?

    init(id: String, unitId: String, format: QuestionFormat, prompt: String,
         options: [String]?, correctAnswer: String, explanation: String,
         tags: [String], difficulty: Int, sceneImageName: String?,
         coachNote: String? = nil) {
        self.id = id
        self.unitId = unitId
        self.format = format
        self.prompt = prompt
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.tags = tags
        self.difficulty = min(5, max(1, difficulty))
        self.sceneImageName = sceneImageName
        self.coachNote = coachNote
    }
}

// MARK: - SessionResult

struct SessionResult: Codable {
    var userId: String
    var unitId: String
    var completedAt: Date
    var xpEarned: Int
    var accuracy: Double
    var heartsUsed: Int
    var weakTags: [String]
}
