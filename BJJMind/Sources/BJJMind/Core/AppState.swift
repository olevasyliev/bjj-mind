import SwiftUI

@MainActor
final class AppState: ObservableObject {

    enum Screen: Equatable { case onboarding, main }

    @Published var currentScreen: Screen = .onboarding
    @Published var user: UserProfile = .guest
    @Published var units: [Unit] = QuestionProvider.whitebelt
    @Published var language: String = LanguageManager.shared.code

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
    }

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
    }

    func completeUnit(id: String) {
        guard let idx = units.firstIndex(where: { $0.id == id }) else { return }
        units[idx].isCompleted = true
        // Unlock next content unit in sequence (never unlock belt test this way)
        let nextIdx = idx + 1
        if nextIdx < units.count, !units[nextIdx].isBeltTest {
            units[nextIdx].isLocked = false
        }
        // If all non-belt-test units are done, unlock the belt test
        let allNonTestDone = units.filter { !$0.isBeltTest }.allSatisfy { $0.isCompleted }
        if allNonTestDone, let beltTestIdx = units.firstIndex(where: { $0.isBeltTest }) {
            units[beltTestIdx].isLocked = false
        }
        persistUnits()
    }

    func setLanguage(_ code: String) {
        LanguageManager.shared.setLanguage(code)
        units = QuestionProvider.whitebelt   // update data first
        persistUnits()
        language = code                       // trigger re-render last
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
