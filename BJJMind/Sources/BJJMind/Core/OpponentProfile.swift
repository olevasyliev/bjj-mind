import Foundation

// MARK: - OpponentProfile

/// Defines an AI opponent's personality, dialogue, and attack behaviour
/// in the battle system.
struct OpponentProfile: Identifiable {
    let id: String
    let name: String
    let title: String           // e.g. "The Beginner", "The Grinder"
    let preFightQuote: String
    let cornerTip: String       // Coach Marco's tip shown between fights
    let difficulty: Int         // 1–5

    // MARK: Attack probabilities

    /// Probability that the opponent moves the marker back by 1
    /// AFTER the user answers CORRECTLY (weak counter-attack).
    let weakAttackSuccessRate: Double

    /// Probability that the opponent moves the marker back
    /// AFTER the user answers INCORRECTLY (strong punish).
    let strongAttackSuccessRate: Double

    /// Maximum steps the marker moves back on a strong attack (1 or 2).
    let strongAttackMaxSteps: Int
}

// MARK: - Tournament Rosters

extension OpponentProfile {

    /// All opponents across all tournaments, used for lookup by id.
    static var all: [OpponentProfile] {
        whiteBeltFinalTournament + intermediateTournament
    }


    // MARK: White Belt Final Tournament (5 opponents, difficulty 1–5)

    static let whiteBeltFinalTournament: [OpponentProfile] = [
        OpponentProfile(
            id: "marcus",
            name: "Marcus",
            title: "The Beginner",
            preFightQuote: "I just started last month. Go easy on me!",
            cornerTip: "Marcus is still learning — he'll rarely counter. Stay aggressive and push the marker forward.",
            difficulty: 1,
            weakAttackSuccessRate: 0.20,
            strongAttackSuccessRate: 0.60,
            strongAttackMaxSteps: 1
        ),
        OpponentProfile(
            id: "diego",
            name: "Diego",
            title: "The Grinder",
            preFightQuote: "I never tap. Never. We'll be here all day.",
            cornerTip: "Diego grinds every mistake — answer carefully and don't rush. Consistent correct answers will break him.",
            difficulty: 2,
            weakAttackSuccessRate: 0.35,
            strongAttackSuccessRate: 0.75,
            strongAttackMaxSteps: 1
        ),
        OpponentProfile(
            id: "yuki",
            name: "Yuki",
            title: "The Technician",
            preFightQuote: "Position before submission. Let's see if you understand.",
            cornerTip: "Yuki is technical — she punishes mistakes hard. Focus on positional concepts, not just reactions.",
            difficulty: 3,
            weakAttackSuccessRate: 0.45,
            strongAttackSuccessRate: 0.85,
            strongAttackMaxSteps: 1
        ),
        OpponentProfile(
            id: "andre",
            name: "Andre",
            title: "The Veteran",
            preFightQuote: "Twenty years on the mats. You can't surprise me.",
            cornerTip: "Andre has seen everything and can chain attacks — two steps back on mistakes. Think before you answer.",
            difficulty: 4,
            weakAttackSuccessRate: 0.55,
            strongAttackSuccessRate: 0.90,
            strongAttackMaxSteps: 2
        ),
        OpponentProfile(
            id: "coach_santos",
            name: "Coach Santos",
            title: "The Professor",
            preFightQuote: "You've come a long way. Now show me everything you've learned.",
            cornerTip: "Coach Santos is relentless. He counters almost every move and punishes every error with two steps. Perfect answers only.",
            difficulty: 5,
            weakAttackSuccessRate: 0.65,
            strongAttackSuccessRate: 0.95,
            strongAttackMaxSteps: 2
        )
    ]

    // MARK: Intermediate Tournament (3 opponents, after Cycle 2)

    static let intermediateTournament: [OpponentProfile] = [
        OpponentProfile(
            id: "inter_beginner",
            name: "Lena",
            title: "The Newcomer",
            preFightQuote: "Half guard? Sure, I know half guard. Kind of.",
            cornerTip: "Lena is still figuring out half guard — a good opportunity to practise your new positions.",
            difficulty: 1,
            weakAttackSuccessRate: 0.25,
            strongAttackSuccessRate: 0.65,
            strongAttackMaxSteps: 1
        ),
        OpponentProfile(
            id: "inter_mid",
            name: "Raj",
            title: "The Competitor",
            preFightQuote: "I've been competing for two years. Bring it.",
            cornerTip: "Raj has solid fundamentals and will counter consistently. Keep the marker moving forward with clean answers.",
            difficulty: 2,
            weakAttackSuccessRate: 0.40,
            strongAttackSuccessRate: 0.78,
            strongAttackMaxSteps: 1
        ),
        OpponentProfile(
            id: "inter_final",
            name: "Sofia",
            title: "The Blue Belt",
            preFightQuote: "You're only white — this might hurt.",
            cornerTip: "Sofia earned her blue belt fighting opponents just like you. She's a step ahead, but you've trained for this.",
            difficulty: 3,
            weakAttackSuccessRate: 0.50,
            strongAttackSuccessRate: 0.85,
            strongAttackMaxSteps: 1
        )
    ]
}
