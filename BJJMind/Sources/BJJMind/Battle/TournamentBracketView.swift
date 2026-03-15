import SwiftUI

// MARK: - TournamentBracketView

/// Shows the full tournament bracket as a vertical list of fights.
/// Highlights the current fight, shows results for completed fights,
/// and transitions to TournamentDebriefView when done.
struct TournamentBracketView: View {
    @Binding var tournament: Tournament
    let onStartFight: (TournamentFight) -> Void
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            if tournament.isComplete {
                TournamentDebriefView(tournament: tournament, onDone: onComplete)
            } else {
                bracketContent
            }
        }
    }

    // MARK: - Bracket Content

    private var bracketContent: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(tournament.type == .intermediate ? "INTERMEDIATE TOURNAMENT" : "FINAL TOURNAMENT")
                    .font(.nunito(11, weight: .black))
                    .foregroundColor(.brandLight)
                    .tracking(1.5)

                Text("Tournament Bracket")
                    .font(.nunito(24, weight: .black))
                    .foregroundColor(.textPrimary)
            }
            .padding(.top, 60)
            .padding(.bottom, 32)

            // Fight list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(tournament.fights.enumerated()), id: \.element.id) { index, fight in
                        FightRowView(
                            fight: fight,
                            isCurrent: index == tournament.currentFightIndex,
                            isPast: index < tournament.currentFightIndex,
                            onFight: {
                                onStartFight(fight)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - FightRowView

private struct FightRowView: View {
    let fight: TournamentFight
    let isCurrent: Bool
    let isPast: Bool
    let onFight: () -> Void

    private var opponent: OpponentProfile? {
        OpponentProfile.all.first { $0.id == fight.opponentId }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Round label column
            VStack(spacing: 2) {
                Text(fight.round.displayName.uppercased())
                    .font(.nunito(9, weight: .black))
                    .foregroundColor(isCurrent ? .brand : .textMuted)
                    .tracking(1)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 72)

            // Connector dot
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)

            // Opponent info
            VStack(alignment: .leading, spacing: 2) {
                Text(opponent?.name ?? fight.opponentId)
                    .font(.nunito(16, weight: .black))
                    .foregroundColor(isCurrent ? .textPrimary : (isPast ? .textSecondary : .textDisabled))

                if let title = opponent?.title {
                    Text(title.uppercased())
                        .font(.nunito(9, weight: .bold))
                        .foregroundColor(isCurrent ? .brandLight : .textDisabled)
                        .tracking(1)
                }
            }

            Spacer()

            // Result or action
            resultBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(rowBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(rowBorder, lineWidth: isCurrent ? 2 : 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subviews

    @ViewBuilder
    private var resultBadge: some View {
        if let result = fight.result {
            switch result {
            case .win(let bySubmission):
                ResultBadge(
                    text: bySubmission ? "Sub Win" : "Win",
                    color: .success
                )
            case .loss(let bySubmission):
                ResultBadge(
                    text: bySubmission ? "Sub Loss" : "Loss",
                    color: .error
                )
            }
        } else if isCurrent {
            Button(action: onFight) {
                Text("Fight!")
                    .font(.nunito(14, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.brand)
                    .clipShape(Capsule())
                    .shadow(color: Color.brandDark, radius: 0, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        } else {
            Text("?")
                .font(.nunito(18, weight: .black))
                .foregroundColor(.textDisabled)
                .frame(width: 32)
        }
    }

    // MARK: - Computed Colors

    private var dotColor: Color {
        guard let result = fight.result else {
            return isCurrent ? Color.brand : Color.textDisabled
        }
        if case .win = result { return Color.success }
        return Color.error
    }

    private var rowBackground: Color {
        if isCurrent { return Color.brandVeryPale }
        guard let result = fight.result else { return Color.surfaceBg }
        if case .win = result { return Color.successPale }
        return Color.errorPale
    }

    private var rowBorder: Color {
        if isCurrent { return Color.brandPale }
        guard let result = fight.result else { return Color.borderMedium }
        if case .win = result { return Color(hex: "#86efac") }
        return Color(hex: "#fca5a5")
    }
}

// MARK: - ResultBadge

private struct ResultBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.nunito(12, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .overlay(
                Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1.5)
            )
            .clipShape(Capsule())
    }
}

// MARK: - TournamentDebriefView

/// Shown when the tournament is complete (win or loss).
struct TournamentDebriefView: View {
    let tournament: Tournament
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Result icon
                    ZStack {
                        Circle()
                            .fill(tournament.playerWon ? Color.successPale : Color.errorPale)
                            .frame(width: 100, height: 100)

                        Image(systemName: tournament.playerWon ? "trophy.fill" : "figure.fall")
                            .font(.system(size: 48))
                            .foregroundColor(tournament.playerWon ? .success : .error)
                    }

                    Spacer().frame(height: 20)

                    // Main result title
                    Text(tournament.playerWon ? "Tournament Champion!" : "Eliminated")
                        .font(.nunito(28, weight: .black))
                        .foregroundColor(tournament.playerWon ? Color(hex: "#15803d") : .error)

                    // Subtitle
                    Text(resultSubtitle)
                        .font(.nunito(15, weight: .bold))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 32)

                    // Fight summary
                    VStack(alignment: .leading, spacing: 10) {
                        Text("RESULTS")
                            .font(.nunito(10, weight: .black))
                            .foregroundColor(.textMuted)
                            .tracking(1.5)
                            .padding(.horizontal, 4)

                        ForEach(tournament.fights) { fight in
                            DebriefFightRow(fight: fight)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Mistake patterns (if any fights were lost)
                    if !tournament.playerWon, let pattern = mistakePattern {
                        Spacer().frame(height: 24)

                        VStack(spacing: 8) {
                            Text("AREAS TO IMPROVE")
                                .font(.nunito(10, weight: .black))
                                .foregroundColor(.textMuted)
                                .tracking(1.5)

                            Text(pattern)
                                .font(.bodyMd)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .background(Color.surfaceBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 40)

                    // CTA button
                    Button(action: onDone) {
                        Text("Back to Training")
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

    // MARK: - Helpers

    private var resultSubtitle: String {
        if tournament.playerWon {
            return tournament.type == .intermediate
                ? "You beat all 3 opponents!"
                : "You claimed the White Belt title!"
        } else {
            if let lostFight = tournament.fights.first(where: { !$0.playerWon }),
               let opponent = OpponentProfile.all.first(where: { $0.id == lostFight.opponentId }) {
                return "Good fight — you fell to \(opponent.name) in the \(lostFight.round.displayName)."
            }
            return "Good fight — keep training!"
        }
    }

    /// Returns a coaching note based on which opponents the player lost to.
    private var mistakePattern: String? {
        let lostFights = tournament.fights.filter { fight in
            guard let result = fight.result else { return false }
            if case .loss = result { return true }
            return false
        }
        guard !lostFights.isEmpty else { return nil }

        let lostOpponentIds = lostFights.map { $0.opponentId }

        // Infer focus areas from opponent IDs
        if lostOpponentIds.contains("inter_final") || lostOpponentIds.contains("coach_santos") {
            return "You struggled against the toughest opponents — focus on positional control and clean decision-making under pressure."
        } else if lostOpponentIds.contains("yuki") || lostOpponentIds.contains("inter_mid") {
            return "You struggled with technical opponents — practice half guard and transition positions."
        } else if lostOpponentIds.contains("andre") || lostOpponentIds.contains("semifinalFinal") {
            return "Advanced opponents pushed you back — work on consistency when the opponent has two-step attacks."
        } else {
            return "You struggled early — revisit the basics and build confidence in your guard positions."
        }
    }
}

// MARK: - DebriefFightRow

private struct DebriefFightRow: View {
    let fight: TournamentFight

    private var opponent: OpponentProfile? {
        OpponentProfile.all.first { $0.id == fight.opponentId }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Round name
            Text(fight.round.displayName)
                .font(.nunito(13, weight: .bold))
                .foregroundColor(.textSecondary)
                .frame(width: 100, alignment: .leading)

            // Opponent name
            Text(opponent?.name ?? fight.opponentId)
                .font(.nunito(14, weight: .black))
                .foregroundColor(.textPrimary)

            Spacer()

            // Result
            if let result = fight.result {
                switch result {
                case .win(let bySub):
                    Text(bySub ? "W (Sub)" : "W")
                        .font(.nunito(13, weight: .black))
                        .foregroundColor(.success)
                case .loss(let bySub):
                    Text(bySub ? "L (Sub)" : "L")
                        .font(.nunito(13, weight: .black))
                        .foregroundColor(.error)
                }
            } else {
                Text("—")
                    .font(.nunito(13, weight: .bold))
                    .foregroundColor(.textDisabled)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surfaceBg)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderMedium, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
