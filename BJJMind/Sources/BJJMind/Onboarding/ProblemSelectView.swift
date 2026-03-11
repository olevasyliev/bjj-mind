import SwiftUI

struct ProblemSelectView: View {
    @Binding var selectedTags: Set<String>
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 16) {
                AppProgressBar(progress: 0.4)
                CloseButton(action: {})
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            // Question
            VStack(alignment: .leading, spacing: 6) {
                StepLabel(text: L10n.ProblemSelect.step)
                Text(L10n.ProblemSelect.title)
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                Text(L10n.ProblemSelect.subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 20)

            // Problem cards
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(L10n.ProblemSelect.items, id: \.tag) { item in
                        ProblemCard(
                            emoji: item.emoji,
                            name: item.name,
                            description: item.desc,
                            isSelected: selectedTags.contains(item.tag)
                        ) {
                            if selectedTags.contains(item.tag) {
                                selectedTags.remove(item.tag)
                            } else {
                                selectedTags.insert(item.tag)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(
                title: selectedTags.isEmpty ? L10n.ProblemSelect.skip : L10n.ProblemSelect.cta(selectedTags.count),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 52)
        }
        .background(Color.screenBg.ignoresSafeArea())
    }
}

private struct ProblemCard: View {
    let emoji: String
    let name: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.brandPale : Color.surfaceBg)
                        .frame(width: 40, height: 40)
                    Text(emoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.labelLg)
                        .foregroundColor(.textPrimary)
                    Text(description)
                        .font(.bodySm)
                        .foregroundColor(.textMuted)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.brand : Color.borderMedium, lineWidth: 2.5)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle().fill(Color.brand).frame(width: 24, height: 24)
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
