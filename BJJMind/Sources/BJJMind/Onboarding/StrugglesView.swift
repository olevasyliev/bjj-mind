import SwiftUI

struct StrugglesView: View {
    let onContinue: ([String]) -> Void

    private let options: [(String, String)] = [
        ("escape",    "Escaping bad positions"),
        ("guard",     "Keeping my guard"),
        ("passing",   "Passing the guard"),
        ("submit",    "Finishing submissions"),
        ("calm",      "Staying calm under pressure"),
        ("timing",    "Timing my attacks"),
        ("defense",   "Defending submissions"),
        ("top",       "Controlling from top"),
    ]

    @State private var selected: Set<String> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            VStack(spacing: 6) {
                Text("What do you struggle with?")
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                Text("Pick everything that applies.")
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(options, id: \.0) { tag, label in
                    let isOn = selected.contains(tag)
                    Button(action: {
                        if isOn { selected.remove(tag) } else { selected.insert(tag) }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(isOn ? .brand : Color(hex: "#cbd5e1"))
                            Text(label)
                                .font(.nunito(14, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(isOn ? Color.brandVeryPale : Color.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isOn ? Color.brand : Color(hex: "#f3f4f6"),
                                    lineWidth: 2
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(
                title: selected.isEmpty ? "Skip" : "Continue (\(selected.count) selected)"
            ) {
                onContinue(Array(selected))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}
