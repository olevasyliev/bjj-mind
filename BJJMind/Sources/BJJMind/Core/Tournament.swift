import Foundation

// MARK: - TournamentType

enum TournamentType: String, Codable {
    case intermediate   // 3 fights, after Cycle 2
    case final_         // 5 fights, leads to Blue Belt
}

// MARK: - TournamentRound

enum TournamentRound: String, Codable, CaseIterable {
    // Intermediate (3 fights)
    case quarterfinal
    case semifinal
    case intermediateFinal

    // Final tournament (5 fights)
    case r16
    case r8
    case quarterfinalFinal
    case semifinalFinal
    case grandFinal

    var displayName: String {
        switch self {
        case .quarterfinal:      return "Quarterfinal"
        case .semifinal:         return "Semifinal"
        case .intermediateFinal: return "Final"
        case .r16:               return "Round of 16"
        case .r8:                return "Round of 8"
        case .quarterfinalFinal: return "Quarter-Final"
        case .semifinalFinal:    return "Semi-Final"
        case .grandFinal:        return "Grand Final"
        }
    }
}

// MARK: - FightResult

enum FightResult: Codable {
    case win(bySubmission: Bool)
    case loss(bySubmission: Bool)

    // MARK: Manual Codable

    private enum CodingKeys: String, CodingKey {
        case type, bySubmission
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .win(let bySubmission):
            try container.encode("win", forKey: .type)
            try container.encode(bySubmission, forKey: .bySubmission)
        case .loss(let bySubmission):
            try container.encode("loss", forKey: .type)
            try container.encode(bySubmission, forKey: .bySubmission)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let bySubmission = try container.decode(Bool.self, forKey: .bySubmission)
        switch type {
        case "win":  self = .win(bySubmission: bySubmission)
        case "loss": self = .loss(bySubmission: bySubmission)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown FightResult type: \(type)"
            )
        }
    }
}

// MARK: - TournamentFight

struct TournamentFight: Identifiable, Codable {
    let id: String
    let round: TournamentRound
    let opponentId: String
    let maxTurns: Int
    var result: FightResult?

    var isComplete: Bool { result != nil }

    var playerWon: Bool {
        guard let result = result else { return false }
        if case .win = result { return true }
        return false
    }
}

// MARK: - Tournament

struct Tournament: Identifiable, Codable {
    let id: String
    let type: TournamentType
    var fights: [TournamentFight]
    var currentFightIndex: Int

    var isComplete: Bool {
        currentFightIndex >= fights.count || playerEliminated
    }

    var playerEliminated: Bool {
        fights.prefix(currentFightIndex).contains { !$0.playerWon }
    }

    var playerWon: Bool {
        isComplete && !playerEliminated && fights.allSatisfy { $0.playerWon }
    }

    var currentFight: TournamentFight? {
        guard currentFightIndex < fights.count else { return nil }
        return fights[currentFightIndex]
    }

    var opponent: OpponentProfile? {
        guard let fight = currentFight else { return nil }
        return OpponentProfile.all.first { $0.id == fight.opponentId }
    }

    // MARK: - Fight Recording

    mutating func recordFightResult(_ result: FightResult) {
        guard !isComplete else { return }
        fights[currentFightIndex].result = result
        currentFightIndex += 1
    }

    // MARK: - Factory Methods

    static func intermediateTournament() -> Tournament {
        let opponents = OpponentProfile.intermediateTournament
        let fights = [
            TournamentFight(
                id: "inter_fight_0",
                round: .quarterfinal,
                opponentId: opponents[0].id,
                maxTurns: 10
            ),
            TournamentFight(
                id: "inter_fight_1",
                round: .semifinal,
                opponentId: opponents[1].id,
                maxTurns: 10
            ),
            TournamentFight(
                id: "inter_fight_2",
                round: .intermediateFinal,
                opponentId: opponents[2].id,
                maxTurns: 10
            )
        ]
        return Tournament(
            id: "tournament_intermediate_\(UUID().uuidString)",
            type: .intermediate,
            fights: fights,
            currentFightIndex: 0
        )
    }

    static func finalTournament() -> Tournament {
        let opponents = OpponentProfile.whiteBeltFinalTournament
        let fights = [
            TournamentFight(
                id: "final_fight_0",
                round: .r16,
                opponentId: opponents[0].id,   // marcus
                maxTurns: 10
            ),
            TournamentFight(
                id: "final_fight_1",
                round: .r8,
                opponentId: opponents[1].id,   // diego
                maxTurns: 10
            ),
            TournamentFight(
                id: "final_fight_2",
                round: .quarterfinalFinal,
                opponentId: opponents[2].id,   // yuki
                maxTurns: 12
            ),
            TournamentFight(
                id: "final_fight_3",
                round: .semifinalFinal,
                opponentId: opponents[3].id,   // andre
                maxTurns: 12
            ),
            TournamentFight(
                id: "final_fight_4",
                round: .grandFinal,
                opponentId: opponents[4].id,   // coach_santos
                maxTurns: 15
            )
        ]
        return Tournament(
            id: "tournament_final_\(UUID().uuidString)",
            type: .final_,
            fights: fights,
            currentFightIndex: 0
        )
    }
}
