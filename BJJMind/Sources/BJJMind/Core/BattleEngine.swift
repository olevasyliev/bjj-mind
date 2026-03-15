import Foundation

// MARK: - BattleEngine

/// State machine that drives a single battle between the player and an AI opponent.
///
/// Turn cycle:
///   playerTurn → (submitAnswer) → showingPlayerResult
///              → (proceedToOpponentTurn) → showingOpponentResult
///              → (proceedToNextTurn) → playerTurn  (or win state)
@MainActor
final class BattleEngine: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case playerTurn
        case showingPlayerResult(wasCorrect: Bool)
        case opponentTurn
        case showingOpponentResult(markerMoved: Bool, steps: Int)
        case playerWin(bySubmission: Bool)
        case opponentWin(bySubmission: Bool)
    }

    // MARK: - Published Properties

    @Published private(set) var state: State = .playerTurn
    @Published private(set) var markerIndex: Int
    @Published private(set) var turnCount: Int = 0
    @Published private(set) var playerAdvantagePoints: Int = 0
    @Published private(set) var opponentAdvantagePoints: Int = 0

    // MARK: - Configuration

    let scale: BattleScale
    let opponent: OpponentProfile
    let maxTurns: Int

    // MARK: - Private State

    /// Whether the last player answer was correct. Used by opponent attack to pick rate.
    private var lastAnswerWasCorrect: Bool = false

    /// Questions provided for the battle. Cycled by `questionForCurrentPosition()`.
    private(set) var questions: [Question]

    /// Index into `questions` for the current turn.
    private var questionCursor: Int = 0

    // MARK: - Init

    init(scale: BattleScale, opponent: OpponentProfile, maxTurns: Int, questions: [Question] = []) {
        self.scale = scale
        self.opponent = opponent
        self.maxTurns = maxTurns
        self.markerIndex = scale.centerIndex
        self.questions = questions
    }

    // MARK: - Computed Properties

    var currentPerspective: String {
        scale.perspective(atMarkerIndex: markerIndex)
    }

    var currentPosition: BJJPosition {
        scale.positions[markerIndex]
    }

    // MARK: - Question Access

    /// Returns the next unused question from the provided questions array and advances the cursor.
    /// Cycles back to the start when all questions have been used.
    /// Returns `nil` if no questions are available.
    func questionForCurrentPosition() -> Question? {
        guard !questions.isEmpty else { return nil }
        let q = questions[questionCursor % questions.count]
        questionCursor = (questionCursor + 1) % questions.count
        return q
    }

    // MARK: - Player Turn

    /// Call when the player selects an answer.
    func submitAnswer(wasCorrect: Bool) {
        guard case .playerTurn = state else { return }

        lastAnswerWasCorrect = wasCorrect

        if wasCorrect {
            let newIndex = markerIndex + 1
            markerIndex = newIndex
            accumulateAdvantage(afterMovingTo: newIndex)

            if scale.isSubmission(atMarkerIndex: newIndex) {
                state = .playerWin(bySubmission: true)
                return
            }
        }

        state = .showingPlayerResult(wasCorrect: wasCorrect)
    }

    // MARK: - Opponent Turn

    /// Call after showing the player result (UI handles the 1.5 s delay).
    func proceedToOpponentTurn() {
        guard case .showingPlayerResult = state else { return }

        state = .opponentTurn

        // Resolve opponent attack immediately — UI shows animation while in showingOpponentResult.
        let (moved, steps, submissionWin) = opponentAttack()
        if submissionWin {
            state = .opponentWin(bySubmission: true)
        } else {
            state = .showingOpponentResult(markerMoved: moved, steps: steps)
        }
    }

    /// Call after showing the opponent result (UI handles the 1.0 s delay).
    func proceedToNextTurn() {
        guard case .showingOpponentResult = state else { return }

        turnCount += 1

        if turnCount >= maxTurns {
            resolveByAdvantage()
            return
        }

        state = .playerTurn
    }

    // MARK: - Private Helpers

    /// Executes the opponent's attack and updates marker. Returns (moved, steps, submissionWin).
    private func opponentAttack() -> (markerMoved: Bool, steps: Int, submissionWin: Bool) {
        let successRate = lastAnswerWasCorrect
            ? opponent.weakAttackSuccessRate
            : opponent.strongAttackSuccessRate

        let success = Double.random(in: 0...1) < successRate
        guard success else { return (false, 0, false) }

        let steps: Int
        if lastAnswerWasCorrect {
            // Weak attack: always 1 step
            steps = 1
        } else {
            // Strong attack: 1…strongAttackMaxSteps
            steps = Int.random(in: 1...opponent.strongAttackMaxSteps)
        }

        let newIndex = markerIndex - steps
        markerIndex = max(0, newIndex)
        accumulateAdvantage(afterMovingTo: markerIndex)

        if scale.isSubmission(atMarkerIndex: markerIndex) {
            return (true, steps, true)
        }

        return (true, steps, false)
    }

    /// Accumulates BJJ advantage points for the side that owns the new marker position.
    private func accumulateAdvantage(afterMovingTo index: Int) {
        let pts = scale.pointsForPosition(atMarkerIndex: index)
        guard pts > 0 else { return }

        if index > scale.centerIndex {
            // Player advanced into opponent's zone
            playerAdvantagePoints += pts
        } else if index < scale.centerIndex {
            // Opponent advanced into player's zone
            opponentAdvantagePoints += pts
        }
        // index == centerIndex → neutral, no points
    }

    /// Determines winner by accumulated advantage points when turn limit is reached.
    private func resolveByAdvantage() {
        if playerAdvantagePoints >= opponentAdvantagePoints {
            // Exact tie → player wins (home advantage)
            state = .playerWin(bySubmission: false)
        } else {
            state = .opponentWin(bySubmission: false)
        }
    }
}
