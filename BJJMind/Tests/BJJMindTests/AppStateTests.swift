import XCTest
@testable import BJJMind

@MainActor
final class AppStateTests: XCTestCase {

    var sut: AppState!

    override func setUp() {
        super.setUp()
        // Use isolated UserDefaults to avoid polluting real app state
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        sut = AppState(defaults: defaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_init_showsOnboardingWhenNotCompleted() {
        XCTAssertEqual(sut.currentScreen, .onboarding)
    }

    func test_init_showsMainWhenOnboardingCompleted() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        defaults.set(true, forKey: "onboardingComplete")
        let state = AppState(defaults: defaults)
        XCTAssertEqual(state.currentScreen, .main)
    }

    func test_completeOnboarding_transitionsToMain() {
        sut.completeOnboarding(belt: .blue, weakTags: ["guard"])
        XCTAssertEqual(sut.currentScreen, .main)
    }

    func test_completeOnboarding_setsUserBelt() {
        sut.completeOnboarding(belt: .purple, weakTags: [])
        XCTAssertEqual(sut.user.belt, .purple)
    }

    func test_completeOnboarding_setsWeakTags() {
        sut.completeOnboarding(belt: .white, weakTags: ["guard", "escapes"])
        XCTAssertEqual(sut.user.weakTags, ["guard", "escapes"])
    }

    func test_loseHeart_decrementsHearts() {
        let initial = sut.user.hearts
        sut.loseHeart()
        XCTAssertEqual(sut.user.hearts, initial - 1)
    }

    func test_loseHeart_clampsAtZero() {
        for _ in 0..<10 { sut.loseHeart() }
        XCTAssertEqual(sut.user.hearts, 0)
    }

    func test_addXP_incrementsTotal() {
        sut.addXP(50)
        XCTAssertEqual(sut.user.xpTotal, 50)
    }

    func test_applySessionResult_addsXP() {
        let result = SessionResult(
            userId: sut.user.id, unitId: "u-1",
            completedAt: Date(), xpEarned: 50,
            accuracy: 1.0, heartsUsed: 0, weakTags: []
        )
        sut.applySessionResult(result)
        XCTAssertEqual(sut.user.xpTotal, 50)
    }

    func test_applySessionResult_heartsClampAtMax() {
        // Give max hearts already — regen should not exceed max
        let result = SessionResult(
            userId: sut.user.id, unitId: "u-1",
            completedAt: Date(), xpEarned: 10,
            accuracy: 1.0, heartsUsed: 0, weakTags: []
        )
        sut.applySessionResult(result)
        XCTAssertLessThanOrEqual(sut.user.hearts, UserProfile.maxHearts)
    }

    func test_userProfile_persistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let state1 = AppState(defaults: defaults)
        state1.completeOnboarding(belt: .blue, weakTags: ["mount"])
        state1.addXP(120)

        let state2 = AppState(defaults: defaults)
        XCTAssertEqual(state2.user.belt, .blue)
        XCTAssertEqual(state2.user.xpTotal, 120)
    }

    // MARK: - Unit Progression Tests

    func test_completeUnit_marksUnitCompleted() {
        // wb-02 is initially not completed
        XCTAssertFalse(sut.units.first(where: { $0.id == "wb-02" })!.isCompleted)
        sut.completeUnit(id: "wb-02")
        XCTAssertTrue(sut.units.first(where: { $0.id == "wb-02" })!.isCompleted)
    }

    func test_completeUnit_unlocksNextUnit() {
        // wb-03 is initially locked
        XCTAssertTrue(sut.units.first(where: { $0.id == "wb-03" })!.isLocked)
        sut.completeUnit(id: "wb-02")
        XCTAssertFalse(sut.units.first(where: { $0.id == "wb-03" })!.isLocked)
    }

    func test_completeUnit_invalidId_doesNothing() {
        let unitsBefore = sut.units.map { $0.id }
        sut.completeUnit(id: "nonexistent")
        XCTAssertEqual(sut.units.map { $0.id }, unitsBefore)
    }

    func test_allNonBeltTestUnitsComplete_unlocksBeltTest() {
        // Complete every non-belt-test unit
        let nonTestIds = sut.units.filter { !$0.isBeltTest }.map { $0.id }
        for id in nonTestIds { sut.completeUnit(id: id) }
        let beltTest = sut.units.first(where: { $0.isBeltTest })!
        XCTAssertFalse(beltTest.isLocked)
    }

    func test_passBeltTest_addsStripe() {
        let stripesBefore = sut.user.stripes
        sut.passBeltTest()
        XCTAssertEqual(sut.user.stripes, stripesBefore + 1)
    }

    // MARK: - Belt Test 24h Retry Tests

    func test_canRetryBeltTest_trueWhenNoFailRecorded() {
        XCTAssertTrue(sut.canRetryBeltTest)
    }

    func test_canRetryBeltTest_falseImmediatelyAfterFail() {
        sut.recordBeltTestFail()
        XCTAssertFalse(sut.canRetryBeltTest)
    }

    func test_canRetryBeltTest_trueAfter24Hours() {
        // Inject a fail date 25 hours ago
        let pastDate = Date().addingTimeInterval(-25 * 3600)
        sut.defaults.set(pastDate, forKey: "beltTestFailDate")
        XCTAssertTrue(sut.canRetryBeltTest)
    }

    // MARK: - Sequential Unlock Does Not Touch Belt Test

    func test_completeLastContentUnit_doesNotUnlockBeltTestSequentially() {
        // Complete wb-01 through wb-09 — sequential unlock should NOT open belt test
        // (only the allNonTestDone check should)
        sut.completeUnit(id: "wb-01")
        sut.completeUnit(id: "wb-02")
        sut.completeUnit(id: "wb-03")
        sut.completeUnit(id: "wb-04")
        sut.completeUnit(id: "wb-05")
        sut.completeUnit(id: "wb-06")
        sut.completeUnit(id: "wb-07")
        sut.completeUnit(id: "wb-08")
        sut.completeUnit(id: "wb-09")
        // wb-10 is now unlocked but not yet completed — belt test must still be locked
        XCTAssertTrue(sut.units.first(where: { $0.isBeltTest })!.isLocked)
        // Now complete wb-10 — this triggers allNonTestDone and opens belt test
        sut.completeUnit(id: "wb-10")
        XCTAssertFalse(sut.units.first(where: { $0.isBeltTest })!.isLocked)
    }
}
