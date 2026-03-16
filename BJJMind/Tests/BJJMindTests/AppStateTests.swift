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
        sut.completeOnboarding(belt: .white, skillLevel: .beginner, struggles: [], clubInfo: nil)
        XCTAssertEqual(sut.currentScreen, .main)
    }

    func test_completeOnboarding_withSkillLevel_setsLevel() {
        sut.completeOnboarding(belt: .white, skillLevel: .advanced, struggles: [], clubInfo: nil)
        XCTAssertEqual(sut.user.skillLevel, .advanced)
    }

    func test_completeOnboarding_withClubInfo_savesClub() {
        let club = ClubInfo(country: "Brazil", city: "São Paulo", clubName: "Gracie Barra")
        sut.completeOnboarding(belt: .white, skillLevel: .beginner, struggles: [], clubInfo: club)
        XCTAssertEqual(sut.user.clubInfo?.clubName, "Gracie Barra")
    }

    func test_completeOnboarding_beltAlwaysWhite() {
        sut.completeOnboarding(belt: .white, skillLevel: .advanced, struggles: [], clubInfo: nil)
        XCTAssertEqual(sut.user.belt, .white)
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
        state1.completeOnboarding(belt: .white, skillLevel: .intermediate, struggles: [], clubInfo: nil)
        state1.addXP(120)

        let state2 = AppState(defaults: defaults)
        XCTAssertEqual(state2.user.skillLevel, .intermediate)
        XCTAssertEqual(state2.user.xpTotal, 120)
    }

    // MARK: - SkillLevel Tests

    func test_skillLevel_rawValues() {
        XCTAssertEqual(SkillLevel.beginner.rawValue, 0)
        XCTAssertEqual(SkillLevel.intermediate.rawValue, 1)
        XCTAssertEqual(SkillLevel.advanced.rawValue, 2)
    }

    func test_userProfile_defaultSkillLevel_isBeginner() {
        XCTAssertEqual(sut.user.skillLevel, .beginner)
    }

    func test_userProfile_defaultClubInfo_isNil() {
        XCTAssertNil(sut.user.clubInfo)
    }

    func test_clubInfo_codable_roundtrip() throws {
        let club = ClubInfo(country: "Spain", city: "Barcelona", clubName: "Checkmat BCN")
        let data = try JSONEncoder().encode(club)
        let decoded = try JSONDecoder().decode(ClubInfo.self, from: data)
        XCTAssertEqual(decoded.country, "Spain")
        XCTAssertEqual(decoded.city, "Barcelona")
        XCTAssertEqual(decoded.clubName, "Checkmat BCN")
    }

    // MARK: - Unit Progression Tests

    func test_completeUnit_marksUnitCompleted() {
        sut.units = [
            Unit(id: "u-first", belt: .white, orderIndex: 0, title: "First", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "u-second", belt: .white, orderIndex: 1, title: "Second", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
        ]
        XCTAssertFalse(sut.units.first(where: { $0.id == "u-first" })!.isCompleted)
        sut.completeUnit(id: "u-first")
        XCTAssertTrue(sut.units.first(where: { $0.id == "u-first" })!.isCompleted)
    }

    func test_completeUnit_unlocksNextUnit() {
        sut.units = [
            Unit(id: "u-first", belt: .white, orderIndex: 0, title: "First", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "u-second", belt: .white, orderIndex: 1, title: "Second", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
        ]
        XCTAssertTrue(sut.units.first(where: { $0.id == "u-second" })!.isLocked)
        sut.completeUnit(id: "u-first")
        XCTAssertFalse(sut.units.first(where: { $0.id == "u-second" })!.isLocked)
    }

    func test_completeUnit_invalidId_doesNothing() {
        let unitsBefore = sut.units.map { $0.id }
        sut.completeUnit(id: "nonexistent")
        XCTAssertEqual(sut.units.map { $0.id }, unitsBefore)
    }

    func test_allNonBeltTestUnitsComplete_unlocksBeltTest() {
        sut.units = [
            Unit(id: "l1", belt: .white, orderIndex: 0, title: "L1", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "l2", belt: .white, orderIndex: 1, title: "L2", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "bt1", belt: .white, orderIndex: 2, title: "Belt Test", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .beltTest, questions: []),
        ]
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

    // MARK: - Adaptive Session Fetching Tests

    /// When no remoteUserId is set, fetchQuestionsForSession must fall back to unit.questions.
    func test_fetchQuestionsForSession_noUserId_returnsLocalQuestions() async {
        // Arrange: build a unit with local questions (no remote user, no topic)
        let localQuestion = Question(
            id: "local-q99", unitId: "local-unit", format: .mcq4,
            prompt: "Test prompt", options: ["A", "B"], correctAnswer: "A",
            explanation: "Because A", tags: [], difficulty: 1, sceneImageName: nil
        )
        let unit = Unit(
            id: "local-unit", belt: .white, orderIndex: 0,
            title: "Local Unit", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .lesson, questions: [localQuestion]
        )
        // No remoteUserId is set (fresh defaults) — fallback path must fire

        // Act
        let questions = await sut.fetchQuestionsForSession(for: unit)

        // Assert: falls back to the unit's local question list
        XCTAssertFalse(questions.isEmpty, "Fallback should return unit's local questions")
        XCTAssertEqual(
            Set(questions.map(\.id)),
            Set(unit.questions.map(\.id)),
            "Fallback questions should match unit.questions"
        )
    }

    /// When the unit has no topic, fetchQuestionsForSession must fall back to unit.questions.
    func test_fetchQuestionsForSession_noTopic_returnsLocalQuestions() async {
        // Arrange: create a unit with NO topicTitle but with questions
        let localQuestion = Question(
            id: "local-q1", unitId: "no-topic-unit", format: .mcq4,
            prompt: "Test prompt", options: ["A", "B"], correctAnswer: "A",
            explanation: "Because A", tags: [], difficulty: 1, sceneImageName: nil
        )
        let noTopicUnit = Unit(
            id: "no-topic-unit", belt: .white, orderIndex: 99,
            title: "No Topic Unit", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .lesson, questions: [localQuestion]
        )
        // No remoteUserId, no topicTitle → must fall back

        // Act
        let questions = await sut.fetchQuestionsForSession(for: noTopicUnit)

        // Assert
        XCTAssertEqual(questions.count, 1)
        XCTAssertEqual(questions.first?.id, "local-q1")
    }

    /// sessionQuestions is nil before any session is started.
    func test_sessionQuestions_isNilInitially() {
        XCTAssertNil(sut.sessionQuestions)
    }

    /// After fetchQuestionsForSession, sessionQuestions is populated.
    func test_fetchQuestionsForSession_setsSessionQuestions() async {
        let localQuestion = Question(
            id: "local-q98", unitId: "session-unit", format: .mcq4,
            prompt: "Test prompt", options: ["A", "B"], correctAnswer: "A",
            explanation: "Because A", tags: [], difficulty: 1, sceneImageName: nil
        )
        let unit = Unit(
            id: "session-unit", belt: .white, orderIndex: 0,
            title: "Session Unit", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .lesson, questions: [localQuestion]
        )

        _ = await sut.fetchQuestionsForSession(for: unit)

        XCTAssertNotNil(sut.sessionQuestions, "sessionQuestions should be set after fetch")
        XCTAssertFalse(sut.sessionQuestions!.isEmpty)
    }

    /// recordQuestionAnswers with no userId is a no-op (must not crash).
    func test_recordQuestionAnswers_noUserId_isNoOp() {
        // No remoteUserId — this should silently do nothing (fire-and-forget)
        // We just verify no crash and the method exists
        let answers: [(questionId: String, wasWrong: Bool)] = [
            ("q1", false), ("q2", true)
        ]
        sut.recordQuestionAnswers(answers)
        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    /// recordQuestionAnswers with empty list is a no-op (must not crash).
    func test_recordQuestionAnswers_emptyList_isNoOp() {
        sut.recordQuestionAnswers([])
        XCTAssertTrue(true)
    }

    // MARK: - Sequential Unlock Does Not Touch Belt Test

    func test_completeLastContentUnit_doesNotUnlockBeltTestSequentially() {
        sut.units = [
            Unit(id: "c1", belt: .white, orderIndex: 0, title: "C1", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "c2", belt: .white, orderIndex: 1, title: "C2", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "c3", belt: .white, orderIndex: 2, title: "C3", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "bt", belt: .white, orderIndex: 3, title: "Belt Test", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .beltTest, questions: []),
        ]
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

    // Belt test gate must require characterMoment completion (not just lessons).
    // Relevant for Supabase sync: if remote progress has no row for a character moment,
    // isCompleted=false, and the belt test must stay locked until the user taps through it.
    func test_beltTestGate_requiresCharacterMomentCompletion() {
        let defaults = UserDefaults(suiteName: "test_bt_cm_gate")!
        defaults.removePersistentDomain(forName: "test_bt_cm_gate")
        let state = AppState(defaults: defaults)

        state.units = [
            Unit(id: "l1", belt: .white, orderIndex: 0, title: "Lesson", description: "",
                 tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
            Unit(id: "cm1", belt: .white, orderIndex: 1, title: "", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .characterMoment, questions: []),
            Unit(id: "bt1", belt: .white, orderIndex: 2, title: "Belt Test", description: "",
                 tags: [], isLocked: true, isCompleted: false, kind: .beltTest, questions: []),
        ]

        // Complete lesson but NOT the character moment
        state.completeUnit(id: "l1")
        XCTAssertTrue(state.units.first(where: { $0.isBeltTest })!.isLocked,
                      "Belt test must stay locked while character moment is incomplete")

        // Complete the character moment — now belt test should unlock
        state.completeUnit(id: "cm1")
        XCTAssertFalse(state.units.first(where: { $0.isBeltTest })!.isLocked,
                       "Belt test should unlock once character moment is complete")
    }
}
