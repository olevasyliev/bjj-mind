import SwiftUI

// MARK: - Belt Test Gate (pre-test screen)

struct BeltTestGateView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isTestPresented = false

    let unit: Unit

    var body: some View {
        ZStack {
            Color(hex: "#fffbeb").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        CloseButton(action: { dismiss() })
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 52)

                    // Hero
                    VStack(spacing: 12) {
                        Text("🛡️")
                            .font(.system(size: 64))
                        Text(unit.title)
                            .font(.screenTitle)
                            .foregroundColor(Color(hex: "#92400e"))
                        Text(L10n.BeltTest.description)
                            .font(.bodyMd)
                            .foregroundColor(Color(hex: "#a16207"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 28)

                    // Rules card
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.BeltTest.rulesHeader)
                            .font(.nunito(11, weight: .black))
                            .foregroundColor(Color(hex: "#92400e"))
                            .tracking(1.5)
                            .padding(.bottom, 12)

                        VStack(spacing: 10) {
                            ForEach(L10n.BeltTest.rules, id: \.text) { rule in
                                BeltTestRule(emoji: rule.emoji, text: rule.text)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(hex: "#fef9c3"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color(hex: "#fde68a"), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Topics covered
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.BeltTest.topicsHeader)
                            .font(.nunito(11, weight: .black))
                            .foregroundColor(Color(hex: "#92400e"))
                            .tracking(1.5)

                        let topics = ["guard", "escapes", "side control", "mount", "back control", "submissions", "takedowns"]
                        FlowLayout(spacing: 8) {
                            ForEach(topics, id: \.self) { topic in
                                Text(topic)
                                    .font(.nunito(12, weight: .bold))
                                    .foregroundColor(Color(hex: "#92400e"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#fef3c7"))
                                    .overlay(Capsule().strokeBorder(Color(hex: "#fde68a"), lineWidth: 1.5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                    // CTA
                    if appState.canRetryBeltTest {
                        PrimaryButton(
                            title: L10n.BeltTest.startCta,
                            action: { isTestPresented = true },
                            color: Color(hex: "#f59e0b"),
                            shadowColor: Color(hex: "#b45309")
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                    } else {
                        VStack(spacing: 8) {
                            Text("⏳")
                                .font(.system(size: 36))
                            if let unlockDate = appState.beltTestFailRetryDate().map({ $0.addingTimeInterval(24 * 3600) }) {
                                Text(L10n.BeltTest.retryMessage + " " + unlockDate.formatted(date: .omitted, time: .shortened))
                                    .font(.bodyMd)
                                    .foregroundColor(Color(hex: "#a16207"))
                            }
                        }
                        .padding(.bottom, 48)
                        .onAppear {
                            // Re-check lock status when view appears (handles returning after 24h)
                            _ = appState.canRetryBeltTest
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isTestPresented) {
            SessionView(unit: unit, isBeltTest: true)
                .environmentObject(appState)
        }
    }
}

// MARK: - Belt Test Rule Row

private struct BeltTestRule: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 28)
            Text(text)
                .font(.nunito(14, weight: .semiBold))
                .foregroundColor(Color(hex: "#92400e"))
            Spacer()
        }
    }
}

// MARK: - Flow Layout (for topic chips)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Belt Test Pass View

struct BeltTestPassView: View {
    let accuracy: Double
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#fffbeb").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text("🏅")
                        .font(.system(size: 80))

                    Text(L10n.BeltTest.passTitle)
                        .font(.appTitle)
                        .foregroundColor(Color(hex: "#92400e"))

                    Text(L10n.BeltTest.passSubtitle)
                        .font(.bodyMd)
                        .foregroundColor(Color(hex: "#a16207"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Gold accuracy badge
                    Text(L10n.BeltTest.passAccuracy(Int(accuracy * 100)))
                        .font(.nunito(16, weight: .black))
                        .foregroundColor(Color(hex: "#92400e"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#fef3c7"))
                        .overlay(Capsule().strokeBorder(Color(hex: "#f59e0b"), lineWidth: 2))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)

                Spacer()

                PrimaryButton(
                    title: L10n.BeltTest.passCta,
                    action: onDone,
                    color: Color(hex: "#f59e0b"),
                    shadowColor: Color(hex: "#b45309")
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Belt Test Fail View

enum BeltTestFailReason {
    case outOfHearts    // ran out of 3 hearts mid-test
    case lowAccuracy    // completed but < 70%
}

struct BeltTestFailView: View {
    let accuracy: Double
    let reason: BeltTestFailReason
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#fffbeb").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text(reason == .outOfHearts ? "💔" : "💪")
                        .font(.system(size: 80))

                    Text(L10n.BeltTest.failTitle)
                        .font(.appTitle)
                        .foregroundColor(Color(hex: "#92400e"))

                    Text(reason == .outOfHearts ? L10n.BeltTest.failHeartsMessage : L10n.BeltTest.failAccuracyMessage)
                        .font(.bodyMd)
                        .foregroundColor(Color(hex: "#a16207"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text("\(Int(accuracy * 100))%")
                                .font(.nunito(22, weight: .black))
                                .foregroundColor(Color(hex: "#92400e"))
                            Text(reason == .outOfHearts ? L10n.BeltTest.failAccuracyLabel : L10n.BeltTest.failYourScore)
                                .font(.labelXXS)
                                .foregroundColor(Color(hex: "#a16207"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#fef9c3"))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: "#fde68a"), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        VStack(spacing: 4) {
                            Text(reason == .outOfHearts ? "0" : "70%")
                                .font(.nunito(22, weight: .black))
                                .foregroundColor(Color(hex: "#92400e"))
                            Text(reason == .outOfHearts ? L10n.BeltTest.failMistakesLeft : L10n.BeltTest.failRequired)
                                .font(.labelXXS)
                                .foregroundColor(Color(hex: "#a16207"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#fef9c3"))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: "#fde68a"), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                PrimaryButton(
                    title: L10n.BeltTest.failCta,
                    action: onDone,
                    color: Color(hex: "#f59e0b"),
                    shadowColor: Color(hex: "#b45309")
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
    }
}
