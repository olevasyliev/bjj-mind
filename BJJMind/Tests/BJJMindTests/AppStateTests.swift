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
        // wb-01-l2 is initially not completed
        XCTAssertFalse(sut.units.first(where: { $0.id == "wb-01-l2" })!.isCompleted)
        sut.completeUnit(id: "wb-01-l2")
        XCTAssertTrue(sut.units.first(where: { $0.id == "wb-01-l2" })!.isCompleted)
    }

    func test_completeUnit_unlocksNextUnit() {
        // wb-02-l1 is initially locked
        XCTAssertTrue(sut.units.first(where: { $0.id == "wb-02-l1" })!.isLocked)
        sut.completeUnit(id: "wb-01-l2")
        XCTAssertFalse(sut.units.first(where: { $0.id == "wb-02-l1" })!.isLocked)
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
        // Complete all non-belt-test units except the last one — belt test must stay locked
        let nonTestUnits = sut.units.filter { !$0.isBeltTest }
        let allButLast = nonTestUnits.dropLast()
        for unit in allButLast { sut.completeUnit(id: unit.id) }
        // Belt test must still be locked after all but the last content unit
        XCTAssertTrue(sut.units.first(where: { $0.isBeltTest })!.isLocked)
        // Now complete the last content unit — this triggers allNonTestDone and opens belt test
        sut.completeUnit(id: nonTestUnits.last!.id)
        XCTAssertFalse(sut.units.first(where: { $0.isBeltTest })!.isLocked)
    }
}

@MainActor
final class CharacterMomentLockTests: XCTestCase {

    func test_completingLesson_unlocksCharacterMoment() {
        let defaults = UserDefaults(suiteName: "test_cm_unlock")!
        defaults.removePersistentDomain(forName: "test_cm_unlock")
        let state = AppState(defaults: defaults)

        state.units = [
            Unit(id: "l1", belt: .white, orderIndex: 0, title: "Lesson 1", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "cm1", belt: .white, orderIndex: 1, title: "", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .characterMoment, questions: []),
            Unit(id: "l2", belt: .white, orderIndex: 2, title: "Lesson 2", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
        ]

        state.completeUnit(id: "l1")
        XCTAssertFalse(state.units[1].isLocked, "CharacterMoment should unlock after lesson completes")
        XCTAssertTrue(state.units[2].isLocked, "Next lesson stays locked until moment is done")
    }

    func test_completingCharacterMoment_unlocksNextLesson() {
        let defaults = UserDefaults(suiteName: "test_cm_complete")!
        defaults.removePersistentDomain(forName: "test_cm_complete")
        let state = AppState(defaults: defaults)

        state.units = [
            Unit(id: "l1", belt: .white, orderIndex: 0, title: "Lesson 1", description: "",
                 tags: [], isLocked: false, isCompleted: true, kind: .lesson, questions: []),
            Unit(id: "cm1", belt: .white, orderIndex: 1, title: "", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .characterMoment, questions: []),
            Unit(id: "l2", belt: .white, orderIndex: 2, title: "Lesson 2", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
        ]

        state.completeUnit(id: "cm1")
        XCTAssertTrue(state.units[1].isCompleted, "CharacterMoment should be marked complete")
        XCTAssertFalse(state.units[2].isLocked, "Next lesson should unlock after moment completes")
    }
}
