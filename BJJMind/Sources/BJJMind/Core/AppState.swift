import SwiftUI

@MainActor
final class AppState: ObservableObject {

    enum Screen: Equatable { case onboarding, main }

    @Published var currentScreen: Screen = .onboarding
    @Published var user: UserProfile = .guest
    @Published var units: [Unit] = []
    @Published var language: String = LanguageManager.shared.code
    @Published var isLoadingContent: Bool = false

    /// Questions fetched for the current (or most recently started) session.
    /// `nil` before any session is started. Reset to `nil` when a new session begins.
    @Published private(set) var sessionQuestions: [Question]? = nil

    /// Stable Supabase UUID for this device, persisted in UserDefaults.
    private(set) var remoteUserId: UUID? {
        get {
            guard let str = defaults.string(forKey: "remoteUserId") else { return nil }
            return UUID(uuidString: str)
        }
        set { defaults.set(newValue?.uuidString, forKey: "remoteUserId") }
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.data(forKey: "userProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: saved) {
            self.user = decoded
        }
        if let savedUnits = defaults.data(forKey: "units"),
           let decodedUnits = try? JSONDecoder().decode([Unit].self, from: savedUnits) {
            self.units = decodedUnits
        }
        if defaults.bool(forKey: "onboardingComplete") {
            currentScreen = .main
        }
        Task { await syncWithSupabase() }
    }

    // MARK: - Supabase Sync

    /// Full sync: upsert profile → fetch catalog → apply remote progress.
    func syncWithSupabase() async {
        isLoadingContent = true
        defer { isLoadingContent = false }
        do {
            // 1. Ensure we have a stable remote user ID
            let userId = try await ensureRemoteUser()

            // 2. Fetch fresh catalog
            let bundles = try await SupabaseService.shared.fetchCatalog()

            // 3. Fetch remote progress (authoritative over local cache)
            let remoteProgress = try await SupabaseService.shared.fetchUnitProgress(userId: userId)
            let remoteCompleted = Set(remoteProgress.filter(\.isCompleted).map(\.unitId))

            // 4. Merge: prefer remote completed state, rebuild lock chain
            applyRemoteBundles(bundles, completedIds: remoteCompleted)
            persistUnits()
        } catch {
            print("[Supabase] sync failed: \(error)")
        }
    }

    private func ensureRemoteUser() async throws -> UUID {
        if let existing = remoteUserId { return existing }
        let deviceId = deviceIdentifier()
        let uuid = try await SupabaseService.shared.upsertUserProfile(deviceId: deviceId)
        remoteUserId = uuid
        return uuid
    }

    /// Returns a stable device ID (generated once, stored in UserDefaults).
    private func deviceIdentifier() -> String {
        if let stored = defaults.string(forKey: "deviceId") { return stored }
        let new = UUID().uuidString
        defaults.set(new, forKey: "deviceId")
        return new
    }

    /// Merges remote catalog with completed set, rebuilding lock chain.
    private func applyRemoteBundles(_ bundles: [RemoteUnitBundle], completedIds: Set<String>) {
        guard !bundles.isEmpty else { return }

        var rebuilt: [Unit] = bundles.map { b in
            Unit(
                id: b.id, belt: b.belt, orderIndex: b.orderIndex,
                title: b.title, description: b.description, tags: b.tags,
                isLocked: true,
                isCompleted: completedIds.contains(b.id),
                kind: b.kind,
                questions: b.questions,
                coachIntro: b.coachIntro,
                sectionTitle: b.sectionTitle,
                topicTitle: b.topicTitle,
                topic: b.topic,
                lessonIndex: b.lessonIndex,
                lessonTotal: b.lessonTotal,
                characterMoment: b.characterMoment,
                cycleNumber: b.cycleNumber,
                isBoss: b.isBoss
            )
        }

        if !rebuilt.isEmpty { rebuilt[0].isLocked = false }
        for i in 1..<rebuilt.count {
            if rebuilt[i].isBeltTest {
                let allDone = rebuilt.filter { !$0.isBeltTest }.allSatisfy { $0.isCompleted }
                rebuilt[i].isLocked = !allDone
            } else {
                rebuilt[i].isLocked = !rebuilt[i - 1].isCompleted
            }
        }

        units = rebuilt
    }

    // MARK: - Persistence

    private func persistUser() {
        if let encoded = try? JSONEncoder().encode(user) {
            defaults.set(encoded, forKey: "userProfile")
        }
    }

    private func persistUnits() {
        if let encoded = try? JSONEncoder().encode(units) {
            defaults.set(encoded, forKey: "units")
        }
    }

    // MARK: - Actions

    func completeOnboarding(belt: Belt, skillLevel: SkillLevel, struggles: [String], clubInfo: ClubInfo?) {
        user.belt = belt
        user.skillLevel = skillLevel
        user.weakTags = struggles
        user.clubInfo = clubInfo
        defaults.set(true, forKey: "onboardingComplete")
        persistUser()
        withAnimation(.easeInOut(duration: 0.4)) { currentScreen = .main }
    }

    func loseHeart() {
        guard user.hearts > 0 else { return }
        user.hearts -= 1
        persistUser()
    }

    func addXP(_ amount: Int) {
        user.xpTotal += amount
        persistUser()
    }

    func addGems(_ amount: Int) {
        user.gems += amount
        persistUser()
    }

    func applySessionResult(_ result: SessionResult) {
        addXP(result.xpEarned)
        user.hearts = min(user.hearts + 1, UserProfile.maxHearts)
        persistUser()

        guard let userId = remoteUserId else { return }
        Task {
            try? await SupabaseService.shared.insertSessionResult(
                userId: userId, unitId: result.unitId,
                xpEarned: result.xpEarned, accuracy: result.accuracy,
                heartsUsed: result.heartsUsed
            )
        }
    }

    func completeUnit(id: String) {
        guard let idx = units.firstIndex(where: { $0.id == id }) else { return }
        units[idx].isCompleted = true

        let nextIdx = idx + 1
        if nextIdx < units.count, !units[nextIdx].isBeltTest {
            units[nextIdx].isLocked = false
        }
        let allNonTestDone = units.filter { !$0.isBeltTest }.allSatisfy { $0.isCompleted }
        if allNonTestDone, let beltTestIdx = units.firstIndex(where: { $0.isBeltTest }) {
            units[beltTestIdx].isLocked = false
        }
        persistUnits()

        // Sync to Supabase (fire-and-forget)
        let unit = units[idx]
        if let userId = remoteUserId {
            Task {
                try? await SupabaseService.shared.upsertUnitProgress(
                    userId: userId, unitId: unit.id,
                    isCompleted: true, isLocked: false
                )
            }
        }
    }

    func setLanguage(_ code: String) {
        LanguageManager.shared.setLanguage(code)
        language = code
    }

    // MARK: - Adaptive Session

    /// Fetches questions for a session using adaptive ordering when possible.
    ///
    /// If the unit has a `topicTitle` and a `remoteUserId` is available, questions are
    /// fetched from Supabase and ordered adaptively (unseen → weak → ok, easiest-first within
    /// each group). On any failure — network error, empty result, missing topic, or no userId —
    /// the method falls back transparently to the unit's local question list.
    ///
    /// The fetched questions are also stored in `sessionQuestions` so views can read them
    /// without re-fetching.
    ///
    /// - Parameter unit: The unit the user is about to start.
    /// - Returns: The adaptive question list, or the unit's local questions as fallback.
    @discardableResult
    func fetchQuestionsForSession(for unit: Unit) async -> [Question] {
        // Reset any previously stored session questions
        sessionQuestions = nil

        guard let topic = unit.topic, let userId = remoteUserId else {
            // Offline or anonymous: fall back to unit's embedded questions
            sessionQuestions = unit.questions
            return unit.questions
        }

        do {
            let fetched = try await SupabaseService.shared.fetchQuestionsForSession(
                topic: topic,
                beltLevel: user.belt.rawValue,
                userId: userId,
                count: 8
            )
            // Guard against an empty remote result (e.g. topic not yet seeded in DB)
            let result = fetched.isEmpty ? unit.questions : fetched
            sessionQuestions = result
            return result
        } catch {
            print("[AppState] fetchQuestionsForSession failed, using local fallback: \(error)")
            sessionQuestions = unit.questions
            return unit.questions
        }
    }

    /// Fetches questions for a battle turn filtered by BJJ position, perspective, and belt.
    ///
    /// Uses adaptive ordering (unseen → weak → ok) when a remote user ID is available.
    /// On any error — network, empty result, missing userId — returns an empty array.
    /// BattleView is expected to handle an empty result gracefully (e.g. skip the question).
    ///
    /// - Parameters:
    ///   - position:    The BJJPosition the battle marker is currently on.
    ///   - perspective: "top" or "bottom" from BattleScale.perspective(atMarkerIndex:).
    ///   - count:       Maximum number of questions to fetch (typically 10–15 to cover a battle).
    /// - Returns: An adaptively ordered list of up to `count` questions, or [] on failure.
    func fetchQuestionsForBattle(
        position: BJJPosition,
        perspective: String,
        count: Int
    ) async -> [Question] {
        guard let userId = remoteUserId else {
            print("[AppState] fetchQuestionsForBattle: no remoteUserId, returning empty")
            return []
        }

        do {
            return try await SupabaseService.shared.fetchQuestionsForBattle(
                position: position,
                perspective: perspective,
                beltLevel: user.belt.rawValue,
                userId: userId,
                count: count
            )
        } catch {
            print("[AppState] fetchQuestionsForBattle failed: \(error)")
            return []
        }
    }

    /// Records per-question answer stats after a session completes.
    ///
    /// Fire-and-forget: runs in a background `Task` so it never blocks the UI.
    /// Silently skipped when no `remoteUserId` is available (offline / anonymous).
    ///
    /// - Parameter answers: Pairs of (questionId, wasWrong) for every question answered.
    func recordQuestionAnswers(_ answers: [(questionId: String, wasWrong: Bool)]) {
        guard let userId = remoteUserId, !answers.isEmpty else { return }
        Task {
            for (questionId, wasWrong) in answers {
                try? await SupabaseService.shared.upsertQuestionStats(
                    userId: userId, questionId: questionId, wasWrong: wasWrong
                )
            }
        }
    }

    // MARK: - Battle / Tournament Completion

    func completeBattle(unitId: String, won: Bool) {
        addXP(won ? 80 : 20)
        guard won else { return }
        completeUnit(id: unitId)
    }

    func completeTournament(unitId: String, tournament: Tournament) {
        guard tournament.playerWon else { return }
        completeUnit(id: unitId)
    }

    // MARK: - Battle Helpers

    func battleScale(for unit: Unit) -> BattleScale {
        let cycle = unit.cycleNumber ?? 1
        return BattleScale.forCycle(cycle)
    }

    func battleOpponent(for unit: Unit) -> OpponentProfile? {
        guard unit.kind == .bossFight else { return nil }
        let cycle = unit.cycleNumber ?? 1
        // Cycle 1 → marcus, Cycle 2 → diego, Cycle 3 → yuki, Cycle 4 → andre
        let bossIds: [Int: String] = [1: "marcus", 2: "diego", 3: "yuki", 4: "andre"]
        guard let bossId = bossIds[cycle] else { return OpponentProfile.all.first }
        return OpponentProfile.all.first { $0.id == bossId }
    }

    func passBeltTest() {
        user.addStripe()
        persistUser()
    }

    func beltTestFailRetryDate() -> Date? {
        guard let ts = defaults.object(forKey: "beltTestFailDate") as? Date else { return nil }
        return ts
    }

    func recordBeltTestFail() {
        defaults.set(Date(), forKey: "beltTestFailDate")
    }

    var canRetryBeltTest: Bool {
        guard let failDate = beltTestFailRetryDate() else { return true }
        return Date().timeIntervalSince(failDate) >= 24 * 3600
    }
}
