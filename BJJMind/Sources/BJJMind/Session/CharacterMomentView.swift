import SwiftUI

struct CharacterMomentView: View {
    let unit: Unit
    let onDismiss: () -> Void

    private var moment: CharacterMomentData? { unit.characterMoment }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(characterImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(.bottom, 8)

                // Character name
                Text(moment?.character.displayName ?? "")
                    .font(.nunito(13, weight: .black))
                    .foregroundColor(characterColor)
                    .tracking(1)
                    .padding(.bottom, 16)

                // Message bubble
                Text(moment?.message ?? "")
                    .font(.nunito(17, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.nunito(17, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private var characterColor: Color {
        switch moment?.character {
        case .marco:    return Color(hex: "#2563EB")
        case .oldChen:  return Color(hex: "#6b7280")
        case .rex:      return Color(hex: "#F59E0B")
        case .giGhost:  return Color(hex: "#7C3AED")
        case .none:     return Color.brand
        }
    }

    private var characterImageName: String {
        switch moment?.character {
        case .marco:    return "marco"
        case .oldChen:  return "old-chen"
        case .rex:      return "rex"
        case .giGhost:  return "gi-ghost"
        case .none:     return "gi-ghost"
        }
    }
}
