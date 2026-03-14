import SwiftUI

struct AhaMomentView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with step dots
            HStack(spacing: 16) {
                AppProgressBar(progress: 0.7)
                CloseButton(action: {})
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            Spacer()

            Image("gi-ghost")
                .resizable()
                .scaledToFit()
                .frame(height: 260)
                .padding(.bottom, 4)

            Text(L10n.Aha.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .padding(.bottom, 4)

            Text(L10n.Aha.subtitle)
                .font(.bodyMd)
                .foregroundColor(.textMuted)
                .padding(.bottom, 20)

            // Insight cards
            VStack(spacing: 10) {
                ForEach(Array(L10n.Aha.insights.enumerated()), id: \.offset) { idx, item in
                    InsightCard(emoji: item.emoji, text: item.text, index: idx)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            PrimaryButton(title: L10n.Aha.cta, action: onStart)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
        .background(Color.screenBg.ignoresSafeArea())
    }
}

private struct InsightCard: View {
    let emoji: String
    let text: String
    let index: Int

    private let iconBg: [Color] = [
        .brandPale,
        .errorPale,
        .goldPale,
        .successPale,
    ]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBg[index % 4])
                    .frame(width: 48, height: 48)
                Text(emoji)
                    .font(.system(size: 24))
            }

            Text(text)
                .font(.nunito(14, weight: .bold))
                .foregroundColor(.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.borderMedium, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
