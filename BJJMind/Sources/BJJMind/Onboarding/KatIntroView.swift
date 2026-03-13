import SwiftUI

struct KatIntroView: View {
    let skillLevel: SkillLevel
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0f0f14").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text(L10n.KatIntro.eyebrow)
                    .font(.nunito(12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .padding(.bottom, 20)

                ZStack {
                    Circle()
                        .fill(Color(hex: "#1e1e28"))
                        .frame(width: 100, height: 100)
                    Text("🥋")
                        .font(.system(size: 48))
                }
                .padding(.bottom, 16)

                Text(L10n.KatIntro.name)
                    .font(.screenTitle)
                    .foregroundColor(.white)
                    .tracking(-0.5)
                Text(L10n.KatIntro.record)
                    .font(.bodySm)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 28)

                Text("\"\(L10n.KatIntro.message(for: skillLevel))\"")
                    .font(.bodyMd)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#1e1e28"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: onAccept) {
                        Text(L10n.KatIntro.cta)
                            .font(.labelXL)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Text(L10n.KatIntro.unlockNote)
                        .font(.bodySm)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}
