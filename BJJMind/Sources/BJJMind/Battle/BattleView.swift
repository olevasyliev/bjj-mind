import SwiftUI

// MARK: - BattlePreviewView

/// Pre-fight screen shown before the battle starts.
struct BattlePreviewView: View {
    let opponent: OpponentProfile
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Opponent icon
                ZStack {
                    Circle()
                        .fill(Color.brandVeryPale)
                        .frame(width: 110, height: 110)
                        .overlay(Circle().strokeBorder(Color.brandPale, lineWidth: 3))

                    Image(systemName: "person.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.brand)
                }

                Spacer().frame(height: 20)

                // Opponent name + title
                Text(opponent.name)
                    .font(.nunito(28, weight: .black))
                    .foregroundColor(.textPrimary)

                Text(opponent.title.uppercased())
                    .font(.nunito(12, weight: .black))
                    .foregroundColor(.brandLight)
                    .tracking(1.5)
                    .padding(.top, 2)

                // Difficulty stars
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= opponent.difficulty ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(star <= opponent.difficulty ? Color.gold : Color.textDisabled)
                    }
                }
                .padding(.top, 10)

                Spacer().frame(height: 32)

                // Pre-fight quote speech bubble
                VStack(alignment: .leading, spacing: 0) {
                    Text("\"\(opponent.preFightQuote)\"")
                        .font(.nunito(16, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(20)
                        .background(Color.surfaceBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 32)

                Spacer()

                // Accept button
                Button(action: onAccept) {
                    Text("Accept Challenge")
                        .font(.buttonLg)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.brand)
                        .clipShape(Capsule())
                        .shadow(color: Color.brandDark, radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - BattleView

/// Main battle container — drives the full fight via BattleEngine state machine.
struct BattleView: View {
    @StateObject private var engine: BattleEngine
    let opponent: OpponentProfile
    let questions: [Question]
    let onComplete: (Bool) -> Void  // true = player won

    /// Which question is currently active for this turn (cycled through questions list).
    @State private var questionIndex: Int = 0

    /// Timer state for the 8-second countdown.
    @State private var timeRemaining: Int = 8
    @State private var timerTask: Task<Void, Never>? = nil

    init(
        opponent: OpponentProfile,
        scale: BattleScale,
        questions: [Question],
        onComplete: @escaping (Bool) -> Void
    ) {
        self.opponent = opponent
        self.questions = questions
        self.onComplete = onComplete
        _engine = StateObject(wrappedValue: BattleEngine(
            scale: scale,
            opponent: opponent,
            maxTurns: 10
        ))
    }

    private var currentQuestion: Question? {
        guard !questions.isEmpty else { return nil }
        return questions[questionIndex % questions.count]
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Position scale always visible at top
                PositionScaleView(
                    scale: engine.scale,
                    markerIndex: engine.markerIndex
                )
                .padding(.top, 52)
                .padding(.horizontal, 16)

                // Score row
                HStack {
                    ScorePill(label: "YOU", points: engine.playerAdvantagePoints, color: .brand)
                    Spacer()
                    Text("VS")
                        .font(.nunito(12, weight: .black))
                        .foregroundColor(.textMuted)
                        .tracking(1)
                    Spacer()
                    ScorePill(label: opponent.name.uppercased(), points: engine.opponentAdvantagePoints, color: Color(hex: "#ef4444"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                // State-driven content
                Group {
                    switch engine.state {
                    case .playerTurn:
                        if let q = currentQuestion {
                            BattleQuestionView(
                                question: q,
                                timeRemaining: timeRemaining,
                                onAnswer: { wasCorrect in
                                    cancelTimer()
                                    engine.submitAnswer(wasCorrect: wasCorrect)
                                    // After 1.5s delay, proceed to opponent turn
                                    Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                                        engine.proceedToOpponentTurn()
                                    }
                                }
                            )
                            .id(questionIndex) // forces re-render on new question
                        }

                    case .showingPlayerResult(let wasCorrect):
                        BattlePlayerResultView(wasCorrect: wasCorrect)

                    case .opponentTurn:
                        OpponentTurnView(opponent: opponent) {
                            engine.proceedToNextTurn()
                        }

                    case .showingOpponentResult(let markerMoved, let steps):
                        BattleOpponentResultView(
                            markerMoved: markerMoved,
                            steps: steps,
                            onDone: {
                                advanceQuestion()
                                engine.proceedToNextTurn()
                                startTimer()
                            }
                        )

                    case .playerWin(let bySubmission):
                        BattleResultView(
                            playerWon: true,
                            bySubmission: bySubmission,
                            playerPoints: engine.playerAdvantagePoints,
                            opponentPoints: engine.opponentAdvantagePoints,
                            opponentName: opponent.name,
                            onContinue: { onComplete(true) }
                        )

                    case .opponentWin(let bySubmission):
                        BattleResultView(
                            playerWon: false,
                            bySubmission: bySubmission,
                            playerPoints: engine.playerAdvantagePoints,
                            opponentPoints: engine.opponentAdvantagePoints,
                            opponentName: opponent.name,
                            onContinue: { onComplete(false) }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            cancelTimer()
        }
        // Auto-advance from opponentTurn (engine resolves immediately, lands in showingOpponentResult)
        .onChange(of: engine.state) { newState in
            if case .opponentTurn = newState {
                // engine resolves opponent attack synchronously — already moved to showingOpponentResult
            }
        }
    }

    // MARK: - Timer helpers

    private func startTimer() {
        cancelTimer()
        timeRemaining = 8
        timerTask = Task { @MainActor in
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                timeRemaining -= 1
            }
            // Time's up — treat as wrong answer
            guard !Task.isCancelled else { return }
            if case .playerTurn = engine.state {
                engine.submitAnswer(wasCorrect: false)
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                engine.proceedToOpponentTurn()
            }
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func advanceQuestion() {
        questionIndex = (questionIndex + 1) % max(1, questions.count)
    }
}

// MARK: - PositionScaleView

/// Horizontal scrollable scale showing all positions with animated marker.
struct PositionScaleView: View {
    let scale: BattleScale
    let markerIndex: Int

    private let dotSize: CGFloat = 14
    private let cellWidth: CGFloat = 52

    var body: some View {
        VStack(spacing: 6) {
            // Labels row
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Connecting line
                    HStack(spacing: 0) {
                        ForEach(0..<scale.positions.count, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.borderMedium)
                                .frame(width: cellWidth, height: 2)
                        }
                    }
                    .padding(.top, dotSize / 2)

                    // Dots + labels
                    HStack(spacing: 0) {
                        ForEach(Array(scale.positions.enumerated()), id: \.offset) { index, position in
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(dotColor(index: index))
                                        .frame(width: dotSize, height: dotSize)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(dotBorder(index: index), lineWidth: 1.5)
                                        )

                                    // Animated marker
                                    if index == markerIndex {
                                        Circle()
                                            .fill(Color.brand)
                                            .frame(width: dotSize + 6, height: dotSize + 6)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.brandDark, lineWidth: 2)
                                            )
                                            .shadow(color: Color.brand.opacity(0.4), radius: 4)
                                    }
                                }

                                Text(positionLabel(index: index, position: position))
                                    .font(.nunito(8, weight: index == markerIndex ? .black : .bold))
                                    .foregroundColor(index == markerIndex ? .brand : .textMuted)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: cellWidth - 4)
                            }
                            .frame(width: cellWidth)
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: markerIndex)

            // Side labels
            HStack {
                Text("← OPPONENT")
                    .font(.nunito(9, weight: .black))
                    .foregroundColor(Color(hex: "#ef4444"))
                    .tracking(0.8)

                Spacer()

                Text("CENTER")
                    .font(.nunito(9, weight: .black))
                    .foregroundColor(.textMuted)
                    .tracking(0.8)

                Spacer()

                Text("YOUR SIDE →")
                    .font(.nunito(9, weight: .black))
                    .foregroundColor(.brand)
                    .tracking(0.8)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.surfaceBg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.borderMedium, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dotColor(index: Int) -> Color {
        if index == scale.centerIndex { return Color.borderMedium }
        if index == 0 || index == scale.positions.count - 1 { return Color.errorPale }
        if index < scale.centerIndex { return Color(hex: "#fee2e2") }  // opponent's side
        return Color.brandVeryPale  // player's side
    }

    private func dotBorder(index: Int) -> Color {
        if index == 0 || index == scale.positions.count - 1 { return Color.error }
        if index == scale.centerIndex { return Color.borderMedium }
        if index < scale.centerIndex { return Color(hex: "#fca5a5") }
        return Color.brandPale
    }

    private func positionLabel(index: Int, position: BJJPosition) -> String {
        if index == 0 { return "TAP" }
        if index == scale.positions.count - 1 { return "SUB" }
        if index == scale.centerIndex { return "●" }

        switch position {
        case .submission:  return "Sub"
        case .backControl: return "Back"
        case .mount:       return "Mnt"
        case .sideControl: return "Side"
        case .halfGuard:   return "Half"
        case .openGuard:   return "Open"
        case .closedGuard: return "Closed"
        }
    }
}

// MARK: - BattleQuestionView

/// Shows the current question with timer and 3 answer options.
private struct BattleQuestionView: View {
    let question: Question
    let timeRemaining: Int
    let onAnswer: (Bool) -> Void

    @State private var selectedIndex: Int? = nil
    @State private var answered = false

    private var options: [String] { question.options ?? [] }

    var body: some View {
        VStack(spacing: 16) {
            // Timer countdown
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(timerColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text("\(timeRemaining)")
                        .font(.nunito(18, weight: .black))
                        .foregroundColor(timerColor)
                }
            }
            .padding(.horizontal, 4)

            // Question text
            Text(question.prompt)
                .font(.questionLg)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            // Answer options (always 3 in battles)
            VStack(spacing: 10) {
                ForEach(Array(options.prefix(3).enumerated()), id: \.offset) { index, option in
                    let state = optionState(index: index, option: option)
                    OptionButton(
                        letter: String(UnicodeScalar(65 + index)!),
                        text: option,
                        state: state
                    ) {
                        guard !answered else { return }
                        answered = true
                        selectedIndex = index
                        let isCorrect = option == question.correctAnswer
                        onAnswer(isCorrect)
                    }
                    .disabled(answered)
                }
            }
        }
    }

    private var timerColor: Color {
        if timeRemaining <= 3 { return .error }
        if timeRemaining <= 5 { return .gold }
        return .brand
    }

    private func optionState(index: Int, option: String) -> OptionState {
        guard answered else { return .normal }
        if option == question.correctAnswer { return .correct }
        if index == selectedIndex { return .wrong }
        return .normal
    }
}

// MARK: - BattlePlayerResultView

/// Brief overlay shown after player answers (before opponent turn).
private struct BattlePlayerResultView: View {
    let wasCorrect: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(wasCorrect ? Color.successPale : Color.errorPale)
                    .frame(width: 80, height: 80)

                Image(systemName: wasCorrect ? "checkmark" : "xmark")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(wasCorrect ? .success : .error)
            }

            Text(wasCorrect ? "Nice move!" : "Opponent counters...")
                .font(.nunito(20, weight: .black))
                .foregroundColor(wasCorrect ? .success : .error)

            Text(wasCorrect ? "You advanced the position." : "Wrong answer — they'll push back.")
                .font(.bodyMd)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - OpponentTurnView

/// Shows "Opponent is attacking..." animation for 0.8 seconds, then auto-advances.
struct OpponentTurnView: View {
    let opponent: OpponentProfile
    let onDone: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#fee2e2"))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.fill")
                    .font(.system(size: 38))
                    .foregroundColor(Color(hex: "#ef4444"))
            }
            .scaleEffect(scale)
            .opacity(opacity)

            Text("\(opponent.name) attacks!")
                .font(.nunito(20, weight: .black))
                .foregroundColor(Color(hex: "#dc2626"))
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            onDone()
        }
    }
}

// MARK: - BattleOpponentResultView

/// Shows the outcome of the opponent's attack (moved / blocked), then calls onDone.
private struct BattleOpponentResultView: View {
    let markerMoved: Bool
    let steps: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(markerMoved ? Color.errorPale : Color.successPale)
                    .frame(width: 80, height: 80)

                Image(systemName: markerMoved ? "arrow.left" : "shield.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(markerMoved ? .error : .success)
            }

            Text(markerMoved ? "They pushed back!" : "You held position!")
                .font(.nunito(20, weight: .black))
                .foregroundColor(markerMoved ? .error : .success)

            if markerMoved {
                Text(steps == 1 ? "Marker moved back 1 step." : "Marker moved back \(steps) steps!")
                    .font(.bodyMd)
                    .foregroundColor(.textSecondary)
            } else {
                Text("Opponent's attack failed.")
                    .font(.bodyMd)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            onDone()
        }
    }
}

// MARK: - CornerView

/// Shown between tournament fights. Coach Marco gives a tip before the next fight.
struct CornerView: View {
    let opponent: OpponentProfile
    let onFight: () -> Void

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Coach Marco placeholder
                ZStack {
                    Circle()
                        .fill(Color.brandVeryPale)
                        .frame(width: 100, height: 100)
                        .overlay(Circle().strokeBorder(Color.brandPale, lineWidth: 3))

                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.brand)
                }

                Spacer().frame(height: 12)

                Text("COACH MARCO")
                    .font(.nunito(11, weight: .black))
                    .foregroundColor(.brandLight)
                    .tracking(1.5)

                Spacer().frame(height: 24)

                // Corner tip
                VStack(spacing: 8) {
                    Text("Corner Tip")
                        .font(.nunito(12, weight: .black))
                        .foregroundColor(.brand)
                        .tracking(1)

                    Text(opponent.cornerTip)
                        .font(.bodyLg)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(20)
                        .background(Color.surfaceBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 32)

                Spacer()

                // Fight button
                Button(action: onFight) {
                    Text("Fight!")
                        .font(.buttonLg)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.brand)
                        .clipShape(Capsule())
                        .shadow(color: Color.brandDark, radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - BattleResultView

/// Win or loss screen shown when the battle ends.
struct BattleResultView: View {
    let playerWon: Bool
    let bySubmission: Bool
    let playerPoints: Int
    let opponentPoints: Int
    let opponentName: String
    let onContinue: () -> Void

    private var xpEarned: Int { playerWon ? 80 : 20 }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Result icon
                ZStack {
                    Circle()
                        .fill(playerWon ? Color.successPale : Color.errorPale)
                        .frame(width: 100, height: 100)

                    Image(systemName: playerWon ? "trophy.fill" : "figure.fall")
                        .font(.system(size: 48))
                        .foregroundColor(playerWon ? .success : .error)
                }

                Spacer().frame(height: 20)

                // Win/lose title
                Text(playerWon ? "Victory!" : "Defeated")
                    .font(.nunito(32, weight: .black))
                    .foregroundColor(playerWon ? Color(hex: "#15803d") : .error)

                // Decision type
                Text(bySubmission ? "by Submission" : "by Points")
                    .font(.nunito(16, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 4)

                Spacer().frame(height: 32)

                // Score card
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("\(playerPoints)")
                            .font(.nunito(32, weight: .black))
                            .foregroundColor(.brand)
                        Text("YOUR POINTS")
                            .font(.nunito(10, weight: .black))
                            .foregroundColor(.brandLight)
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.borderMedium)
                        .frame(width: 1, height: 50)

                    VStack(spacing: 4) {
                        Text("\(opponentPoints)")
                            .font(.nunito(32, weight: .black))
                            .foregroundColor(Color(hex: "#ef4444"))
                        Text(opponentName.uppercased())
                            .font(.nunito(10, weight: .black))
                            .foregroundColor(Color(hex: "#fca5a5"))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .background(Color.surfaceBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // XP earned
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.gold)
                    Text("+\(xpEarned) XP")
                        .font(.nunito(18, weight: .black))
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.goldPale)
                .overlay(
                    Capsule().strokeBorder(Color.gold.opacity(0.4), lineWidth: 1.5)
                )
                .clipShape(Capsule())

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.buttonLg)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.brand)
                        .clipShape(Capsule())
                        .shadow(color: Color.brandDark, radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - ScorePill

private struct ScorePill: View {
    let label: String
    let points: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(points)")
                .font(.nunito(18, weight: .black))
                .foregroundColor(color)
            Text(label)
                .font(.nunito(9, weight: .black))
                .foregroundColor(color.opacity(0.7))
                .tracking(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
