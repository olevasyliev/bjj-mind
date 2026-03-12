import SwiftUI

@MainActor
final class AppState: ObservableObject {

    enum Screen: Equatable { case onboarding, main }

    @Published var currentScreen: Screen = .onboarding
    @Published var user: UserProfile = .guest
    @Published var units: [Unit] = QuestionProvider.whitebelt
    @Published var language: String = LanguageManager.shared.code
    @Published var isLoadingContent: Bool = false

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
        var rebuilt: [Unit] = bundles.map { b in
            Unit(
                id: b.id, belt: b.belt, orderIndex: b.orderIndex,
                title: b.title, description: b.description, tags: b.tags,
                isLocked: true,
                isCompleted: completedIds.contains(b.id),
                isBeltTest: b.isBeltTest,
                questions: b.questions,
                coachIntro: b.coachIntro
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

    func completeOnboarding(belt: Belt, weakTags: [String]) {
        user.belt = belt
        user.weakTags = weakTags
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
