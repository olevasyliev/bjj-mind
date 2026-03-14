import SwiftUI

struct BeltSelectView: View {
    let onSelect: (Belt) -> Void

    @State private var selected: Belt = .white

    private let belts: [(Belt, String, Color)] = [
        (.white,  "White Belt",  Color(hex: "#e2e8f0")),
        (.blue,   "Blue Belt",   Color(hex: "#2563EB")),
        (.purple, "Purple Belt", Color(hex: "#7C3AED")),
        (.brown,  "Brown Belt",  Color(hex: "#92400e")),
        (.black,  "Black Belt",  Color(hex: "#1a1a1a")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Text("What's your belt?")
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                Text("Be honest — training adapts to your level.")
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                ForEach(belts, id: \.0) { belt, label, color in
                    Button(action: { selected = belt }) {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color)
                                .frame(width: 40, height: 10)
                                .overlay(
                                    belt == .white ?
                                    RoundedRectangle(cornerRadius: 3)
                                        .strokeBorder(Color(hex: "#cbd5e1"), lineWidth: 1.5)
                                    : nil
                                )

                            Text(label)
                                .font(.labelXL)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            if selected == belt {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.brand)
                            }
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 58)
                        .background(selected == belt ? Color.brandVeryPale : Color.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    selected == belt ? Color.brand : Color(hex: "#f3f4f6"),
                                    lineWidth: 2
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(title: "Continue") { onSelect(selected) }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
        .background(Color.screenBg.ignoresSafeArea())
    }
}
