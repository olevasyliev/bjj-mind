import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // MARK: Hero Card
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "#f5f0ff"))
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Color(hex: "#ddd6fe"), lineWidth: 2)
                            )
                            .overlay(Text("🥋").font(.system(size: 38)))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(appState.user.displayName)
                                .font(.nunito(20, weight: .black))
                                .foregroundColor(.textPrimary)
                            Text("🥋 \(appState.user.belt.displayName) Belt · Stripe \(appState.user.stripes)")
                                .font(.nunito(14, weight: .bold))
                                .foregroundColor(.textMuted)

                            HStack(spacing: 4) {
                                Text("🔥 \(appState.user.streakCurrent) day streak")
                                    .font(.nunito(13, weight: .extraBold))
                                    .foregroundColor(Color(hex: "#ea580c"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "#fff7ed"))
                                    .overlay(Capsule().strokeBorder(Color(hex: "#fed7aa"), lineWidth: 1.5))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.brandPale, lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // MARK: Titles Card
                    ProfileCard(title: "TITLES") {
                        FlexWrap(items: titleBadges) { badge in
                            TitleBadgeView(badge: badge)
                        }
                    }

                    // MARK: Gym Stats Card
                    ProfileCard(title: "THE GARAGE STATS") {
                        VStack(spacing: 0) {
                            StatRow(icon: "⚡", label: "Total XP earned",    value: "\(appState.user.xpTotal) XP", highlight: true)
                            StatRow(icon: "🎯", label: "Sessions completed", value: "24")
                            StatRow(icon: "⚔️", label: "Matches vs Kat",    value: "12")
                            StatRow(icon: "✅", label: "Questions answered", value: "147")
                            StatRow(icon: "🔥", label: "Longest streak",     value: "\(appState.user.streakLongest) days", last: true)
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

    private var titleBadges: [(label: String, locked: Bool)] { [
        ("🛡️ Frame Builder",   false),
        ("🎯 Focused Mind",    false),
        ("🌀 Escape Artist",   true),
        ("⚡ Quick Reactor",   true),
        ("🏆 Tournament Vet",  true),
    ]}
}

// MARK: - Profile Card

private struct ProfileCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.nunito(13, weight: .black))
                .foregroundColor(Color(hex: "#a78bfa"))
                .tracking(1)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBg)
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.brandPale, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Title Badge

private struct TitleBadgeView: View {
    let badge: (label: String, locked: Bool)

    var body: some View {
        Text(badge.label)
            .font(.nunito(13, weight: .black))
            .foregroundColor(badge.locked ? Color(hex: "#d1d5db") : Color(hex: "#7c3aed"))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(badge.locked ? Color(hex: "#f9fafb") : Color(hex: "#f5f0ff"))
            .overlay(
                Capsule().strokeBorder(
                    badge.locked ? Color(hex: "#e5e7eb") : Color(hex: "#ddd6fe"),
                    lineWidth: 1.5
                )
            )
            .clipShape(Capsule())
    }
}

// MARK: - Flex Wrap (simple wrapping layout for badges)

private struct FlexWrap<T, Content: View>: View {
    let items: [T]
    @ViewBuilder let content: (T) -> Content

    var body: some View {
        // Simple approach: wrap into rows manually via GeometryReader is complex,
        // use a LazyVGrid with flexible columns approximation
        _WrappingHStack(items: items, content: content)
    }
}

private struct _WrappingHStack<T, Content: View>: View {
    let items: [T]
    @ViewBuilder let content: (T) -> Content
    @State private var totalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lastHeight: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                content(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= lastHeight
                        }
                        lastHeight = d.height
                        let result = width
                        if item as AnyObject === items.last as AnyObject { width = 0 }
                        else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item as AnyObject === items.last as AnyObject { height = 0 }
                        return result
                    }
            }
        }
        .background(heightReader($totalHeight))
    }

    private func heightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: HeightKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightKey.self) { binding.wrappedValue = $0 }
    }
}

private struct HeightKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var highlight: Bool = false
    var last: Bool = false

    var body: some View {
        HStack {
            Text(icon).font(.system(size: 16))
            Text(label)
                .font(.nunito(15, weight: .bold))
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .font(.nunito(15, weight: .black))
                .foregroundColor(highlight ? Color.brand : .textPrimary)
        }
        .padding(.vertical, 9)
        .overlay(
            last ? nil :
            Rectangle()
                .fill(Color(hex: "#f9f8ff"))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
