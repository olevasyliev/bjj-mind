import SwiftUI

struct CompeteView: View {
    @EnvironmentObject var appState: AppState

    private let leaderboard: [(rank: Int, name: String, xp: Int, isMe: Bool)] = [
        (1, "Kat",              860, false),
        (2, "Rex",              740, false),
        (3, "Coach_Al",         620, false),
        (4, "You",              480, true),
        (5, "WhiteBeltWarrior", 360, false),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Tab.compete)
                        .font(.nunito(28, weight: .black))
                        .foregroundColor(.textPrimary)
                    Text("Bronze League · \(appState.user.belt.displayName) Belt")
                        .font(.nunito(14, weight: .semiBold))
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Weekly Tournament Card
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#7c3aed"), Color(hex: "#4f46e5")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 6)

                    // BG icon
                    Text("🏆")
                        .font(.system(size: 64))
                        .opacity(0.15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 16).padding(.top, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        // Badge
                        Text("⚔️ WEEKLY TOURNAMENT")
                            .font(.nunito(11, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())

                        Text("Tournament Run")
                            .font(.nunito(22, weight: .black))
                            .foregroundColor(.white)

                        Text("5 matches in a row. Resources carry between matches. How far can you go?")
                            .font(.nunito(13, weight: .semiBold))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(2)

                        Text("⏳ Resets in 4 days 12 hours")
                            .font(.nunito(13, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))

                        Button(action: {}) {
                            Text("🥊 Start Run")
                                .font(.nunito(16, weight: .black))
                                .foregroundColor(Color(hex: "#7c3aed"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }

                // MARK: Quick Match vs Kat
                CompeteCard {
                    HStack(spacing: 16) {
                        // Avatars
                        HStack(spacing: 8) {
                            Circle().fill(Color(hex: "#eff6ff"))
                                .frame(width: 52, height: 52)
                                .overlay(Text("🥋").font(.system(size: 24)))
                            Text("VS")
                                .font(.nunito(14, weight: .black))
                                .foregroundColor(Color(hex: "#d1d5db"))
                            Circle().fill(Color(hex: "#fef2f2"))
                                .frame(width: 52, height: 52)
                                .overlay(Text("🥷").font(.system(size: 24)))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("vs Kat")
                                .font(.nunito(17, weight: .black))
                                .foregroundColor(.textPrimary)
                            Text("Full match · 2-3 min · Turn-based")
                                .font(.nunito(13, weight: .semiBold))
                                .foregroundColor(.textMuted)
                        }

                        Spacer()

                        Button(action: {}) {
                            Text("Fight")
                                .font(.nunito(14, weight: .extraBold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .frame(height: 44)
                                .background(Color.brand)
                                .clipShape(Capsule())
                                .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: Bronze League Ladder
                CompeteCard {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("🥉 Bronze League")
                                .font(.nunito(17, weight: .black))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("+120 XP to Silver")
                                .font(.nunito(12, weight: .extraBold))
                                .foregroundColor(Color(hex: "#92400e"))
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color(hex: "#fef3c7"))
                                .overlay(Capsule().strokeBorder(Color(hex: "#fde68a"), lineWidth: 1.5))
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 14)

                        // Rows
                        ForEach(leaderboard, id: \.rank) { player in
                            LeaderboardRow(player: player)
                            if player.rank < leaderboard.count {
                                if !player.isMe {
                                    Divider().background(Color(hex: "#f9f8ff"))
                                }
                            }
                        }
                    }
                }

            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Card

private struct CompeteCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBg)
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.brandPale, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let player: (rank: Int, name: String, xp: Int, isMe: Bool)

    var body: some View {
        HStack(spacing: 12) {
            Text("\(player.rank)")
                .font(.nunito(14, weight: .black))
                .foregroundColor(player.rank <= 3 ? Color(hex: "#f59e0b") : Color(hex: "#9ca3af"))
                .frame(width: 24, alignment: .trailing)

            Text(player.name)
                .font(.nunito(15, weight: player.isMe ? .black : .bold))
                .foregroundColor(player.isMe ? Color.brand : .textPrimary)

            Spacer()

            Text("\(player.xp) XP")
                .font(.nunito(13, weight: .extraBold))
                .foregroundColor(Color.brand)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, player.isMe ? 10 : 0)
        .background(player.isMe ? Color(hex: "#f5f0ff") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, player.isMe ? -4 : 0)
    }
}
