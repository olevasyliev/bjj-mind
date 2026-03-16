import SwiftUI

private enum HomeSheet: Identifiable {
    case session(Unit)
    case beltTest(Unit)
    case characterMoment(Unit)
    case bossFight(Unit)
    case tournament(Unit)
    case miniTheory(Unit)

    var id: String {
        switch self {
        case .session(let u):         return "session-\(u.id)"
        case .beltTest(let u):        return "belttest-\(u.id)"
        case .characterMoment(let u): return "moment-\(u.id)"
        case .bossFight(let u):       return "bossfight-\(u.id)"
        case .tournament(let u):      return "tournament-\(u.id)"
        case .miniTheory(let u):      return "minitheory-\(u.id)"
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

                // Subtle sync indicator — visible only during background Supabase refresh
                if appState.isLoadingContent {
                    SyncBar()
                }

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
                        if let active = units.first(where: { !$0.isCompleted && !$0.isLocked && !$0.isBeltTest && !$0.isCharacterMoment && !$0.isBossFight && !$0.isTournament }) {
                            ActiveUnitBanner(unit: active)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                .id(appState.language + active.id)
                        }

                        // Belt path
                        BeltPathView(units: units) { unit in
                            guard !unit.isLocked else { return }
                            switch unit.kind {
                            case .beltTest:
                                activeSheet = .beltTest(unit)
                            case .characterMoment:
                                activeSheet = .characterMoment(unit)
                            case .bossFight:
                                activeSheet = .bossFight(unit)
                            case .intermediateTournament, .finalTournament:
                                activeSheet = .tournament(unit)
                            case .miniTheory:
                                activeSheet = .miniTheory(unit)
                            default:
                                activeSheet = .session(unit)
                            }
                        }
                        .id(appState.language)
                        .padding(.bottom, 32)
                    }
                }
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .session(let unit):
                    SessionView(unit: unit, isBeltTest: false, streak: appState.user.streakCurrent)
                        .environmentObject(appState)
                case .beltTest(let unit):
                    BeltTestGateView(unit: unit).environmentObject(appState)
                case .characterMoment(let unit):
                    CharacterMomentView(unit: unit) {
                        appState.completeUnit(id: unit.id)
                        activeSheet = nil
                    }
                case .bossFight(let unit):
                    BattleLauncherView(
                        unit: unit,
                        scale: appState.battleScale(for: unit),
                        opponent: appState.battleOpponent(for: unit) ?? OpponentProfile.all[0]
                    ) { won in
                        appState.completeBattle(unitId: unit.id, won: won)
                        activeSheet = nil
                    }
                    .environmentObject(appState)
                case .tournament(let unit):
                    TournamentFlowView(unit: unit) { tournament in
                        appState.completeTournament(unitId: unit.id, tournament: tournament)
                        activeSheet = nil
                    }
                    .environmentObject(appState)
                case .miniTheory(let unit):
                    if let theoryData = unit.miniTheoryData {
                        MiniTheoryView(
                            data: theoryData,
                            unitTitle: unit.title
                        ) {
                            appState.completeUnit(id: unit.id)
                            activeSheet = nil
                        }
                    } else {
                        // Defensive: no data → complete immediately
                        Color.clear.onAppear {
                            appState.completeUnit(id: unit.id)
                            activeSheet = nil
                        }
                    }
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
            // Right side: lesson progress or question count
            if let lessonIdx = unit.lessonIndex, let total = unit.lessonTotal {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("LESSON \(lessonIdx)/\(total)")
                        .font(.nunito(13, weight: .black))
                        .foregroundColor(.white)
                    Text("PROGRESS")
                        .font(.nunito(9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                }
            } else {
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

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in

                // Section header: show when sectionTitle changes
                let prevSection = index > 0 ? units[index - 1].sectionTitle : nil
                if let section = unit.sectionTitle, section != prevSection {
                    SectionDividerView(title: section.uppercased())
                        .padding(.top, index == 0 ? 8 : 24)
                        .padding(.bottom, 4)
                }

                // Topic header: show when topicTitle changes (and is non-nil)
                let prevTopic = index > 0 ? units[index - 1].topicTitle : nil
                if let topic = unit.topicTitle, topic != prevTopic {
                    TopicHeaderView(title: topic)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
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

// MARK: - Topic Header

private struct TopicHeaderView: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.nunito(9, weight: .black))
            .foregroundColor(Color(hex: "#94a3b8"))
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .center)
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
        if unit.isCompleted        { return Color(hex: "#dcfce7") }
        if unit.isLocked           { return Color(hex: "#f1f5f9") }
        if unit.isBeltTest         { return Color(hex: "#fef3c7") }
        if unit.isBossFight        { return Color(hex: "#fce7f3") }
        if unit.isTournament       { return Color(hex: "#fefce8") }
        if unit.isCharacterMoment  { return Color(hex: "#f3e8ff") }
        if unit.isMiniExam         { return Color(hex: "#fff7ed") }
        if unit.isMixedReview      { return Color(hex: "#eff6ff") }
        return .brand
    }

    private var nodeBorder: Color {
        if unit.isCompleted        { return Color(hex: "#22c55e") }
        if unit.isLocked           { return Color(hex: "#cbd5e1") }
        if unit.isBeltTest         { return Color(hex: "#f59e0b") }
        if unit.isBossFight        { return Color(hex: "#ec4899") }
        if unit.isTournament       { return Color(hex: "#eab308") }
        if unit.isCharacterMoment  { return Color(hex: "#c084fc") }
        if unit.isMiniExam         { return Color(hex: "#fb923c") }
        if unit.isMixedReview      { return Color(hex: "#60a5fa") }
        return Color(hex: "#a78bfa")
    }

    private var nodeShadow: Color {
        if unit.isCompleted        { return Color(hex: "#15803d") }
        if unit.isLocked           { return Color(hex: "#94a3b8") }
        if unit.isBeltTest         { return Color(hex: "#d97706") }
        if unit.isBossFight        { return Color(hex: "#db2777") }
        if unit.isTournament       { return Color(hex: "#ca8a04") }
        if unit.isCharacterMoment  { return Color(hex: "#a855f7") }
        if unit.isMiniExam         { return Color(hex: "#ea580c") }
        if unit.isMixedReview      { return Color(hex: "#3b82f6") }
        return Color(hex: "#5b21b6")
    }

    private var nodeLabel: Color {
        if unit.isCompleted        { return Color(hex: "#16a34a") }
        if unit.isLocked           { return Color(hex: "#94a3b8") }
        if unit.isBossFight        { return Color(hex: "#db2777") }
        if unit.isTournament       { return Color(hex: "#ca8a04") }
        if unit.isCharacterMoment  { return Color(hex: "#9333ea") }
        if unit.isMiniExam         { return Color(hex: "#ea580c") }
        if unit.isMixedReview      { return Color(hex: "#2563eb") }
        return .brand
    }

    private var nodeEmoji: String {
        if unit.isCompleted        { return "" }
        if unit.isLocked           { return "🔒" }
        if unit.isBeltTest         { return "🛡️" }
        if unit.isBossFight        { return "⚔️" }
        if unit.isTournament       { return "🏆" }
        if unit.isCharacterMoment  { return "💬" }
        if unit.isMiniExam         { return "📋" }
        if unit.isMixedReview      { return "🔀" }
        return "🥋"
    }
}

private extension Unit {
    var isActive: Bool { !isCompleted && !isLocked }
}

// MARK: - Sync Bar

/// Thin animated bar shown while Supabase content refresh is in progress.
private struct SyncBar: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.brand.opacity(0.12)
                    .frame(height: 3)

                Color.brand
                    .frame(width: geo.size.width * 0.4, height: 3)
                    .offset(x: phase * geo.size.width)
                    .animation(
                        .linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: phase
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(Rectangle())
        }
        .frame(height: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .onAppear { phase = 1.6 }
    }
}

// MARK: - Battle Launcher

/// Async wrapper that fetches battle questions then shows BattlePreviewView → BattleView.
private struct BattleLauncherView: View {
    @EnvironmentObject var appState: AppState

    let unit: Unit
    let scale: BattleScale
    let opponent: OpponentProfile
    let onComplete: (Bool) -> Void

    @State private var questions: [Question] = []
    @State private var isLoading = true
    @State private var showingBattle = false

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.screenBg.ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.brand)
                }
            } else if showingBattle {
                BattleView(
                    opponent: opponent,
                    scale: scale,
                    questions: questions,
                    onComplete: onComplete
                )
            } else {
                BattlePreviewView(opponent: opponent) {
                    showingBattle = true
                }
            }
        }
        .task {
            let fetched = await appState.fetchQuestionsForBattle(
                position: scale.positions[scale.centerIndex],
                perspective: "bottom",
                count: 15
            )
            questions = fetched.isEmpty ? unit.questions : fetched
            isLoading = false
        }
    }
}

// MARK: - Tournament Flow

/// Wrapper that manages a @State Tournament and wires each fight to BattleView.
private struct TournamentFlowView: View {
    @EnvironmentObject var appState: AppState

    let unit: Unit
    let onComplete: (Tournament) -> Void

    @State private var tournament: Tournament
    @State private var activeFight: TournamentFight? = nil
    @State private var fightQuestions: [Question] = []
    @State private var isFetchingQuestions = false

    init(unit: Unit, onComplete: @escaping (Tournament) -> Void) {
        self.unit = unit
        self.onComplete = onComplete
        let t = unit.kind == .intermediateTournament
            ? Tournament.intermediateTournament()
            : Tournament.finalTournament()
        _tournament = State(initialValue: t)
    }

    var body: some View {
        ZStack {
            if let fight = activeFight {
                fightView(fight: fight)
            } else {
                TournamentBracketView(
                    tournament: $tournament,
                    onStartFight: { fight in
                        Task { await startFight(fight) }
                    },
                    onComplete: {
                        onComplete(tournament)
                    }
                )
            }

            if isFetchingQuestions {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.white)
            }
        }
    }

    @ViewBuilder
    private func fightView(fight: TournamentFight) -> some View {
        let opponent = OpponentProfile.all.first { $0.id == fight.opponentId }
            ?? OpponentProfile.all[0]
        let scale = appState.battleScale(for: unit)

        if fightQuestions.isEmpty {
            // Show corner tip while questions load
            CornerView(opponent: opponent) { }
        } else {
            BattleView(
                opponent: opponent,
                scale: scale,
                questions: fightQuestions,
                onComplete: { playerWon in
                    let result: FightResult = playerWon
                        ? .win(bySubmission: false)
                        : .loss(bySubmission: false)
                    tournament.recordFightResult(result)
                    activeFight = nil
                    fightQuestions = []
                }
            )
        }
    }

    private func startFight(_ fight: TournamentFight) async {
        isFetchingQuestions = true
        let scale = appState.battleScale(for: unit)
        let fetched = await appState.fetchQuestionsForBattle(
            position: scale.positions[scale.centerIndex],
            perspective: "bottom",
            count: 15
        )
        fightQuestions = fetched.isEmpty ? unit.questions : fetched
        isFetchingQuestions = false
        activeFight = fight
    }
}

// MARK: - Language Picker

private struct LanguageOption {
    let code: String
    let flag: String
    let label: String
    let available: Bool
}

struct LanguageToggleButton: View {
    @EnvironmentObject var appState: AppState

    private let options: [LanguageOption] = [
        LanguageOption(code: "en", flag: "🇺🇸", label: "English",    available: true),
        LanguageOption(code: "es", flag: "🇪🇸", label: "Español",    available: true),
        LanguageOption(code: "pt", flag: "🇧🇷", label: "Português — Coming soon", available: false),
        LanguageOption(code: "ua", flag: "🇺🇦", label: "Українська — Coming soon", available: false),
    ]

    private var currentFlag: String {
        options.first(where: { $0.code == appState.language })?.flag ?? "🇺🇸"
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.code) { option in
                Button(action: {
                    guard option.available else { return }
                    appState.setLanguage(option.code)
                }) {
                    Label(option.flag + " " + option.label,
                          systemImage: appState.language == option.code ? "checkmark" : "")
                }
                .disabled(!option.available)
            }
        } label: {
            Text(currentFlag)
                .font(.system(size: 20))
                .frame(width: 34, height: 34)
                .background(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
