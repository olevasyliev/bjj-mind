import SwiftUI

struct SummaryView: View {
    let xpEarned: Int
    let accuracy: Double
    let heartsRemaining: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero
            VStack(spacing: 8) {
                Text("🏆")
                    .font(.system(size: 72))

                Text(L10n.Summary.title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)

                Text(L10n.Summary.subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)

                // XP earned badge
                Text("+\(xpEarned) XP")
                    .font(.nunito(16, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.brand)
                    .clipShape(Capsule())
                    .shadow(color: .brandDark, radius: 0, x: 0, y: 4)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)

            // Stats row
            HStack(spacing: 10) {
                SummaryStatCard(
                    emoji: "🎯",
                    value: "\(Int(accuracy * 100))%",
                    label: L10n.Summary.accuracy
                )
                SummaryStatCard(
                    emoji: "❤️",
                    value: "\(heartsRemaining)",
                    label: L10n.Summary.heartsLeft
                )
                SummaryStatCard(
                    emoji: "🔥",
                    value: L10n.Summary.keepIt,
                    label: L10n.Summary.streak
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // Buttons
            VStack(spacing: 10) {
                PrimaryButton(title: L10n.Summary.continueCta, action: onDone)
                SecondaryButton(title: L10n.Summary.reviewMistakes, action: {})
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct SummaryStatCard: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 22))
            Text(value)
                .font(.nunito(22, weight: .black))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.labelXXS)
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
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
