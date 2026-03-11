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

            // Mascot
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.brandVeryPale)
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .strokeBorder(Color.xpBorder, lineWidth: 2.5)
                    )
                    .shadow(color: Color.brandPale, radius: 0, x: 0, y: 6)
                Text("🥋")
                    .font(.system(size: 52))
            }
            .padding(.bottom, 20)

            Text(L10n.Aha.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .padding(.bottom, 6)

            Text(L10n.Aha.subtitle)
                .font(.bodyMd)
                .foregroundColor(.textMuted)
                .padding(.bottom, 24)

            // Insight strips
            VStack(spacing: 10) {
                ForEach(L10n.Aha.insights, id: \.text) { item in
                    InsightStrip(emoji: item.emoji, text: item.text)
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

private struct InsightStrip: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 24)
            Text(text)
                .font(.nunito(13, weight: .bold))
                .foregroundColor(.brandDark)
                .lineSpacing(3)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.brandVeryPale)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.xpBorder, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
