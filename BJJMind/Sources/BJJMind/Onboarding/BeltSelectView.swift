import SwiftUI

struct BeltSelectView: View {
    @Binding var selectedBelt: Belt
    let onContinue: () -> Void

    private var belts: [(belt: Belt, emoji: String)] {[
        (.white, "🤍"),
        (.blue,  "💙"),
        (.purple,"💜"),
    ]}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                AppProgressBar(progress: 0.2)
                CloseButton(action: {})
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            VStack(alignment: .leading, spacing: 6) {
                StepLabel(text: L10n.BeltSelect.step)
                Text(L10n.BeltSelect.title)
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                Text(L10n.BeltSelect.subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 24)

            VStack(spacing: 10) {
                ForEach(belts, id: \.belt) { item in
                    BeltCard(
                        belt: item.belt,
                        emoji: item.emoji,
                        isSelected: selectedBelt == item.belt
                    ) { selectedBelt = item.belt }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(title: L10n.BeltSelect.cta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
        .background(Color.screenBg.ignoresSafeArea())
    }
}

private struct BeltCard: View {
    let belt: Belt
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.beltColor(belt))
                        .frame(width: 36, height: 36)
                    Text(emoji)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Belt.fullName(belt))
                        .font(.labelXL)
                        .foregroundColor(.textPrimary)
                    Text(L10n.Belt.description(belt))
                        .font(.bodySm)
                        .foregroundColor(.textMuted)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.brand : Color.borderMedium, lineWidth: 2.5)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 66)
            .background(isSelected ? Color.brandVeryPale : Color.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.brand : Color(hex: "#f3f4f6"), lineWidth: 2.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
