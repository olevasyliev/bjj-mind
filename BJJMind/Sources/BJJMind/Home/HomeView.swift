import SwiftUI

private enum HomeSheet: Identifiable {
    case session(Unit)
    case beltTest(Unit)

    var id: String {
        switch self {
        case .session(let u):  return "session-\(u.id)"
        case .beltTest(let u): return "belttest-\(u.id)"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeSheet: HomeSheet?

    private var units: [Unit] { appState.units }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Stats bar
                        HStack {
                            StreakBadge(streak: appState.user.streakCurrent)
                            Spacer()
                            HeartsPill(count: appState.user.hearts)
                            Spacer()
                            XPBadge(xp: appState.user.xpTotal)
                            LanguageToggleButton()
                                .padding(.leading, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 52)
                        .padding(.bottom, 12)

                        // Active unit banner
                        if let active = units.first(where: { !$0.isCompleted && !$0.isLocked && !$0.isBeltTest }) {
                            ActiveUnitBanner(unit: active)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                .id(appState.language + active.id)
                        }

                        // Belt path
                        BeltPathView(units: units) { unit in
                            guard !unit.isLocked else { return }
                            activeSheet = unit.isBeltTest ? .beltTest(unit) : .session(unit)
                        }
                        .id(appState.language)
                        .padding(.bottom, 32)
                    }
                }
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .session(let unit):
                    SessionView(unit: unit, isBeltTest: false).environmentObject(appState)
                case .beltTest(let unit):
                    BeltTestGateView(unit: unit).environmentObject(appState)
                }
            }
        }
    }
}

// MARK: - Active Unit Banner

private struct ActiveUnitBanner: View {
    let unit: Unit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Home.currentUnit.uppercased())
                    .font(.nunito(9, weight: .black))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
                Text(unit.title)
                    .font(.nunito(15, weight: .black))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(unit.questions.count)")
                    .font(.nunito(22, weight: .black))
                    .foregroundColor(.white)
                Text(L10n.Home.questions.uppercased())
                    .font(.nunito(9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(hex: "#7c3aed"), Color(hex: "#5b21b6")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color(hex: "#4c1d95"), radius: 0, x: 0, y: 4)
    }
}

// MARK: - Belt Path

struct BeltPathView: View {
    let units: [Unit]
    let onTap: (Unit) -> Void

    // Section header shown BEFORE the unit with this id
    private static let sectionHeaders: [String: String] = [
        "wb-01":  "GUARD GAME",
        "wb-04":  "TOP GAME",
        "wb-08":  "BACK & SUBMISSIONS",
        "wb-bt1": "BELT TEST",
    ]

    var body: some View {
        // Zigzag layout matching HTML prototype
        VStack(spacing: 0) {
            ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                if let header = Self.sectionHeaders[unit.id] {
                    SectionDividerView(title: header)
                        .padding(.top, index == 0 ? 8 : 24)
                        .padding(.bottom, 4)
                }
                HStack {
                    if index % 2 == 0 {
                        Spacer().frame(width: 60)
                        BeltNode(unit: unit) { onTap(unit) }
                        Spacer()
                    } else {
                        Spacer()
                        BeltNode(unit: unit) { onTap(unit) }
                        Spacer().frame(width: 60)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Section Divider

private struct SectionDividerView: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.brandPale)
                .frame(height: 1.5)

            Text(title)
                .font(.nunito(10, weight: .black))
                .foregroundColor(Color(hex: "#a78bfa"))
                .tracking(1.5)
                .fixedSize()

            Rectangle()
                .fill(Color.brandPale)
                .frame(height: 1.5)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Belt Node

struct BeltNode: View {
    let unit: Unit
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(nodeBg)
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(Circle().strokeBorder(nodeBorder, lineWidth: nodeBorderWidth))
                        .shadow(color: nodeShadow, radius: 0, x: 0, y: nodeShadowY)

                    Text(nodeEmoji)
                        .font(.system(size: nodeEmojiSize))

                    // Check badge for completed
                    if unit.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.success)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2.5))
                            .offset(x: nodeSize/2 - 8, y: -(nodeSize/2 - 8))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(unit.isLocked)

            Text(unit.title)
                .font(.nunito(unit.isActive ? 13 : 11, weight: unit.isActive ? .black : .extraBold))
                .foregroundColor(nodeLabel)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
    }

    private var isActive: Bool { !unit.isCompleted && !unit.isLocked }

    private var nodeSize: CGFloat { unit.isActive ? 82 : 64 }
    private var nodeEmojiSize: CGFloat { unit.isActive ? 36 : (unit.isCompleted ? 0 : 24) }
    private var nodeBorderWidth: CGFloat { unit.isActive ? 4 : 3.5 }
    private var nodeShadowY: CGFloat { unit.isActive ? 6 : 5 }

    private var nodeBg: Color {
        if unit.isCompleted { return Color(hex: "#dcfce7") }
        if unit.isLocked    { return Color(hex: "#f1f5f9") }
        if unit.isBeltTest  { return Color(hex: "#fef3c7") }
        return .brand
    }

    private var nodeBorder: Color {
        if unit.isCompleted { return Color(hex: "#22c55e") }
        if unit.isLocked    { return Color(hex: "#cbd5e1") }
        if unit.isBeltTest  { return Color(hex: "#f59e0b") }
        return Color(hex: "#a78bfa")
    }

    private var nodeShadow: Color {
        if unit.isCompleted { return Color(hex: "#15803d") }
        if unit.isLocked    { return Color(hex: "#94a3b8") }
        if unit.isBeltTest  { return Color(hex: "#d97706") }
        return Color(hex: "#5b21b6")
    }

    private var nodeLabel: Color {
        if unit.isCompleted { return Color(hex: "#16a34a") }
        if unit.isLocked    { return Color(hex: "#94a3b8") }
        return .brand
    }

    private var nodeEmoji: String {
        if unit.isCompleted { return "" }
        if unit.isLocked    { return "🔒" }
        if unit.isBeltTest  { return "🛡️" }
        return "🥋"
    }
}

private extension Unit {
    var isActive: Bool { !isCompleted && !isLocked }
}

// MARK: - Language Toggle

struct LanguageToggleButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: {
            appState.setLanguage(appState.language == "en" ? "es" : "en")
        }) {
            Text(appState.language == "en" ? "🇪🇸" : "🇺🇸")
                .font(.system(size: 20))
                .frame(width: 34, height: 34)
                .background(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
