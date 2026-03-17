import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var appState: AppState

    private var nextBossFight: Unit? {
        appState.units.first { $0.kind == .bossFight && !$0.isCompleted }
    }

    private var stripeHint: String {
        if appState.user.stripes >= 4 {
            return "All 4 stripes earned"
        }
        if let boss = nextBossFight {
            return "Stripe \(appState.user.stripes + 1) unlocked after beating \(boss.title)"
        }
        return "Complete all boss fights to earn stripes"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // MARK: Belt Progress Card
                    ProgCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(appState.user.belt.displayName) Belt · Stripe \(appState.user.stripes) of 4")
                                .font(.nunito(16, weight: .black))
                                .foregroundColor(.textPrimary)

                            HStack(spacing: 10) {
                                // Stripe fill bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 100)
                                            .fill(Color(hex: "#f3f4f6"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 100)
                                                    .strokeBorder(Color(hex: "#e5e7eb"), lineWidth: 2)
                                            )
                                        RoundedRectangle(cornerRadius: 100)
                                            .fill(Color.brand.opacity(0.7))
                                            .frame(width: geo.size.width * Double(appState.user.stripes) / 4.0)
                                    }
                                }
                                .frame(height: 24)

                                // Stripe dots
                                HStack(spacing: 4) {
                                    ForEach(1...4, id: \.self) { i in
                                        Circle()
                                            .fill(i <= appState.user.stripes ? Color.brand : Color(hex: "#e5e7eb"))
                                            .frame(width: 14, height: 14)
                                    }
                                }
                            }

                            Text(stripeHint)
                                .font(.nunito(13, weight: .semiBold))
                                .foregroundColor(.textMuted)
                        }
                    }

                    // MARK: Cycle Sub-topic Strength
                    if !appState.cycleProgress.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(appState.cycleProgress, id: \.cycleNumber) { cycle in
                                CycleProgressCard(cycle: cycle)
                            }
                        }
                    }

                    // MARK: Stats Row
                    HStack(spacing: 10) {
                        MiniStat(icon: "🎯", value: "147", label: "Questions\nanswered")
                        MiniStat(icon: "📅", value: "\(appState.user.streakCurrent)", label: "Day\nstreak")
                        MiniStat(icon: "⚔️", value: "12", label: "Matches\nvs Kat")
                    }

                    // MARK: Personal Bests
                    ProgCard(title: "PERSONAL BESTS") {
                        VStack(spacing: 12) {
                            BestRow(icon: "🔥", title: "Longest streak", subtitle: "\(appState.user.streakLongest) days in a row")
                            BestRow(icon: "⚡", title: "Best session score", subtitle: "10/10 correct · 3m 42s")
                        }
                    }

                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
}

// MARK: - Card container

private struct ProgCard<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(.nunito(13, weight: .black))
                    .foregroundColor(Color(hex: "#a78bfa"))
                    .tracking(1)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBg)
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.brandPale, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Mastery Row

private struct MasteryRow: View {
    let icon: String
    let label: String
    let pct: Double

    private var barColor: Color {
        if pct < 0.5 { return Color(hex: "#ef4444") }
        if pct < 0.7 { return Color(hex: "#f59e0b") }
        return Color(hex: "#22c55e")
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(icon) \(label)")
                .font(.nunito(14, weight: .extraBold))
                .foregroundColor(Color(hex: "#374151"))
                .frame(width: 120, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 100).fill(Color(hex: "#f3f0ff"))
                    RoundedRectangle(cornerRadius: 100)
                        .fill(barColor)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 10)

            Text("\(Int(pct * 100))%")
                .font(.nunito(13, weight: .extraBold))
                .foregroundColor(barColor)
                .frame(width: 38, alignment: .trailing)
        }
    }
}

// MARK: - Mini Stat

private struct MiniStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(icon).font(.system(size: 20))
            Text(value)
                .font(.nunito(20, weight: .black))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.nunito(11, weight: .bold))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(Color.cardBg)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.brandPale, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Best Row

private struct BestRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.nunito(14, weight: .extraBold))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.nunito(13, weight: .semiBold))
                    .foregroundColor(.textMuted)
            }
            Spacer()
        }
    }
}
