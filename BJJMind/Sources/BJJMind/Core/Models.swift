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
    var skillLevel: SkillLevel
    var clubInfo: ClubInfo?

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
            weakTags: [],
            skillLevel: .beginner,
            clubInfo: nil
        )
    }
}

// MARK: - SkillLevel

enum SkillLevel: Int, Codable {
    case beginner     = 0
    case intermediate = 1
    case advanced     = 2
}

// MARK: - ClubInfo

struct ClubInfo: Codable, Equatable {
    var country: String
    var city: String
    var clubName: String
}

// MARK: - UnitKind

enum UnitKind: String, Codable {
    // Existing (keep these)
    case lesson           // regular lesson (~4-8 questions) within a topic
    case mixedReview      // cross-topic review lesson
    case miniExam         // section-level exam (~8 questions)
    case beltTest         // belt test / finalTournament gateway
    case characterMoment  // character card — no questions, tap to complete

    // New: battle system nodes
    case bossFight              // boss fight at end of each cycle
    case intermediateTournament // 3-fight tournament (after Cycle 2)
    case finalTournament        // 5-fight tournament (leads to Blue Belt)
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
    var topicTitle: String?    // Display text, e.g. "Guard Passing"
    var topic: String?         // DB slug for adaptive queries, e.g. "guard_passing"
    var lessonIndex: Int?
    var lessonTotal: Int?
    var characterMoment: CharacterMomentData?

    // Cycle / battle metadata
    var cycleNumber: Int?      // which cycle (1–4) this unit belongs to
    var isBoss: Bool           // true for boss fight nodes

    // Custom init so that existing call sites (SampleData) that omit optional params still compile.
    // New params default to nil / false so no existing call sites need updating.
    init(
        id: String, belt: Belt, orderIndex: Int,
        title: String, description: String, tags: [String],
        isLocked: Bool, isCompleted: Bool,
        kind: UnitKind,
        questions: [Question],
        coachIntro: String? = nil,
        sectionTitle: String? = nil,
        topicTitle: String? = nil,
        topic: String? = nil,
        lessonIndex: Int? = nil,
        lessonTotal: Int? = nil,
        characterMoment: CharacterMomentData? = nil,
        cycleNumber: Int? = nil,
        isBoss: Bool = false
    ) {
        self.id = id
        self.belt = belt
        self.orderIndex = orderIndex
        self.title = title
        self.description = description
        self.tags = tags
        self.isLocked = isLocked
        self.isCompleted = isCompleted
        self.kind = kind
        self.questions = questions
        self.coachIntro = coachIntro
        self.sectionTitle = sectionTitle
        self.topicTitle = topicTitle
        self.topic = topic
        self.lessonIndex = lessonIndex
        self.lessonTotal = lessonTotal
        self.characterMoment = characterMoment
        self.cycleNumber = cycleNumber
        self.isBoss = isBoss
    }

    // MARK: - Computed backward-compat
    var isBeltTest: Bool        { kind == .beltTest }
    var isCharacterMoment: Bool { kind == .characterMoment }
    var isMiniExam: Bool        { kind == .miniExam }
    var isMixedReview: Bool     { kind == .mixedReview }
    var isBossFight: Bool       { kind == .bossFight }
    var isTournament: Bool      { kind == .intermediateTournament || kind == .finalTournament }
    var requiresSession: Bool {
        switch kind {
        case .lesson, .mixedReview, .miniExam, .beltTest,
             .bossFight, .intermediateTournament, .finalTournament:
            return true
        case .characterMoment:
            return false
        }
    }
}

// MARK: - Question

enum QuestionFormat: String, Codable {
    case mcq2, mcq3, mcq4, trueFalse, sequence, tapZone, fillBlank, spotMistake
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
