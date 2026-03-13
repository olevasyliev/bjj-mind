import Foundation

// MARK: - Assessment Types

enum TrainingDuration: Int {
    case lessThan6Months = 0
    case sixTo18Months   = 1
    case oneToThreeYears = 2
    case threePlusYears  = 3
}

enum TrainingFrequency: Int {
    case justStarted    = 0
    case onceAWeek      = 1
    case twoThreeTimes  = 2
    case fourPlusTimes  = 3
}

struct AssessmentQuestion {
    let prompt: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - Engine

enum SkillAssessmentEngine {

    /// Maps training duration → question difficulty level (1, 2, or 3)
    static func questionDifficulty(for duration: TrainingDuration) -> Int {
        switch duration {
        case .lessThan6Months: return 1
        case .sixTo18Months:   return 2
        case .oneToThreeYears, .threePlusYears: return 3
        }
    }

    /// Computes overall skill level from experience + quiz performance.
    static func computeSkillLevel(
        duration: TrainingDuration,
        frequency: TrainingFrequency,
        correctCount: Int
    ) -> SkillLevel {
        let baseScore = duration.rawValue
        let freqBonus = frequency.rawValue >= 2 ? 1 : 0
        let quizBonus = correctCount >= 3 ? 1 : (correctCount >= 2 ? 0 : -1)

        let total = baseScore + freqBonus + quizBonus
        switch total {
        case ..<2: return .beginner
        case 2...3: return .intermediate
        default:   return .advanced
        }
    }

    /// Returns exactly 3 BJJ questions for the given difficulty level.
    static func questions(forDifficulty difficulty: Int) -> [AssessmentQuestion] {
        switch difficulty {
        case 1:
            return [
                AssessmentQuestion(
                    prompt: "Side control is a top position.",
                    options: ["True", "False"],
                    correctAnswer: "True"
                ),
                AssessmentQuestion(
                    prompt: "In closed guard, your main goal is to control and threaten attacks.",
                    options: ["True", "False"],
                    correctAnswer: "True"
                ),
                AssessmentQuestion(
                    prompt: "After passing the guard, your immediate priority is:",
                    options: ["Go for a submission", "Establish top position control",
                              "Stand back up", "Call for a timeout"],
                    correctAnswer: "Establish top position control"
                ),
            ]
        case 2:
            return [
                AssessmentQuestion(
                    prompt: "Your opponent postures up in your closed guard. First move?",
                    options: ["Break their posture down", "Open guard immediately"],
                    correctAnswer: "Break their posture down"
                ),
                AssessmentQuestion(
                    prompt: "After passing the guard, you should immediately go for a submission.",
                    options: ["True", "False"],
                    correctAnswer: "False"
                ),
                AssessmentQuestion(
                    prompt: "Cross-face pressure in side control helps flatten your opponent.",
                    options: ["True", "False"],
                    correctAnswer: "True"
                ),
            ]
        default: // 3+
            return [
                AssessmentQuestion(
                    prompt: "You're mounted and your opponent is leaning forward. Best escape?",
                    options: ["Upa (bridge and roll)", "Elbow-knee escape",
                              "Stand up immediately", "Grab their collar"],
                    correctAnswer: "Upa (bridge and roll)"
                ),
                AssessmentQuestion(
                    prompt: "When framing in side control, your bottom forearm goes:",
                    options: ["Across their throat", "On their hip",
                              "Under their arm", "Against their knee"],
                    correctAnswer: "On their hip"
                ),
                AssessmentQuestion(
                    prompt: "To set up a triangle from closed guard, you must first:",
                    options: ["Open your guard wide",
                              "Break posture and isolate one arm outside your legs",
                              "Grab their ankle", "Stand up"],
                    correctAnswer: "Break posture and isolate one arm outside your legs"
                ),
            ]
        }
    }
}
