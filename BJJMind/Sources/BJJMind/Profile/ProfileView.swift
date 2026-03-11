import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.brandVeryPale)
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .strokeBorder(Color.brandPale, lineWidth: 2.5)
                            )
                        Text("🥋")
                            .font(.system(size: 52))
                    }
                    .padding(.top, 24)

                    // Name & belt
                    VStack(spacing: 6) {
                        Text(appState.user.displayName)
                            .font(.nunito(22, weight: .black))
                            .foregroundColor(.textPrimary)

                        Text(appState.user.belt.displayName + " Belt")
                            .font(.bodyMd)
                            .foregroundColor(.textMuted)
                    }

                    // Stats row
                    HStack(spacing: 12) {
                        ProfileStat(value: "\(appState.user.xpTotal)", label: L10n.Profile.totalXP)
                        ProfileStat(value: "\(appState.user.streakLongest)", label: L10n.Profile.bestStreak)
                        ProfileStat(value: "\(appState.user.gems)💎", label: L10n.Profile.gems)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(L10n.Profile.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.nunito(22, weight: .black))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.labelXXS)
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.brandPale, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
