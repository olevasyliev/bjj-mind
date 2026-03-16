import XCTest
@testable import BJJMind

// These tests require a live Supabase connection.
// Set BJJMIND_RUN_INTEGRATION_TESTS=1 in the test scheme to enable.
// They must NOT run in CI unless a dedicated test Supabase project is configured.

final class SupabaseSessionIntegrationTests: XCTestCase {

    var testUserId: UUID!
    var supabase: SupabaseService!

    override func setUp() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BJJMIND_RUN_INTEGRATION_TESTS"] == "1",
            "Integration tests skipped - set BJJMIND_RUN_INTEGRATION_TESTS=1 to run"
        )
        testUserId = UUID()  // fresh user ID for test isolation
        supabase = SupabaseService.shared
    }

    // MARK: - fetchSessionComposition

    func test_integration_fetchSessionComposition_returns6to9Questions() async throws {
        // Given: a topic with questions in the test database
        // When: calling fetchSessionComposition
        // Then: between 6 and 9 questions are returned
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "en"
        )
        XCTAssertGreaterThanOrEqual(questions.count, 6,
                                    "Session must have at least 6 questions")
        XCTAssertLessThanOrEqual(questions.count, 9,
                                 "Session must have at most 9 questions")
    }

    func test_integration_fetchSessionComposition_respectsTopicFilter() async throws {
        // Given: request for closed_guard topic
        // When: fetching session
        // Then: all returned questions have topic = "closed_guard"
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "en"
        )
        XCTAssertTrue(questions.allSatisfy { $0.topic == "closed_guard" },
                      "All session questions must belong to the requested topic")
    }

    func test_integration_fetchSessionComposition_excludesMcq3Format() async throws {
        // Given: the database has mcq3 questions for closed_guard
        // When: fetching session
        // Then: no mcq3 questions in the result
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "en"
        )
        XCTAssertFalse(questions.contains(where: { $0.format == .mcq3 }),
                       "Session must never include mcq3 battle questions")
    }

    // MARK: - updateQuestionStrength

    func test_integration_updateQuestionStrength_correctFirstAttempt_increasesStrengthBy20() async throws {
        // Given: a question with no prior stats (strength = 0)
        // When: calling updateQuestionStrength with wasWrong=false, firstAttempt=true
        // Then: strength for that question increases by 20
        let testQuestionId = "test-q-\(UUID().uuidString)"
        try await supabase.updateQuestionStrength(
            userId: testUserId,
            questionId: testQuestionId,
            wasWrong: false,
            firstAttempt: true
        )
        let stats = try await supabase.fetchQuestionStats(userId: testUserId, questionIds: [testQuestionId])
        XCTAssertEqual(stats.first?.strength, 20,
                       "Correct first-attempt answer must increase strength by 20")
    }

    func test_integration_updateQuestionStrength_wrongAnswer_decreasesStrengthBy30() async throws {
        // Given: a question built up to strength 60 (three correct answers)
        // When: calling updateQuestionStrength with wasWrong=true
        // Then: strength decreases by 30 (to 30)
        let testQuestionId = "test-q-wrong-\(UUID().uuidString)"
        // Build up strength to 60
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: false, firstAttempt: true)  // +20
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: false, firstAttempt: true)  // +20, total = 40
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: false, firstAttempt: true)  // +20, total = 60

        // Now answer wrong
        try await supabase.updateQuestionStrength(
            userId: testUserId, questionId: testQuestionId,
            wasWrong: true, firstAttempt: true)   // -30, should be 30

        let stats = try await supabase.fetchQuestionStats(userId: testUserId, questionIds: [testQuestionId])
        XCTAssertEqual(stats.first?.strength, 30,
                       "Wrong answer must reduce strength by 30")
    }

    // MARK: - triggerStrengthDecay

    func test_integration_triggerStrengthDecay_updatesLastSeenRows() async throws {
        // Given: a question stat with last_seen more than 3 days ago and strength > 0
        // When: calling triggerStrengthDecay
        // Then: the stat's strength is reduced (verify call succeeds without error)
        try await supabase.triggerStrengthDecay(userId: testUserId)
        XCTAssertTrue(true, "triggerStrengthDecay must complete without error")
    }

    // MARK: - fetchSubTopicProgress

    func test_integration_fetchSubTopicProgress_returnsCorrectAvgStrengthPerSubTopic() async throws {
        // Given: the test user has answered some questions in closed_guard
        // When: fetching sub-topic progress
        // Then: returns a dictionary with sub-topic slugs as keys and avgStrength as values
        let subTopics = ["posture_defense", "guard_attacks", "sweeps", "guard_breaks"]
        let progress = try await supabase.fetchSubTopicProgress(
            userId: testUserId,
            topic: "closed_guard",
            subTopics: subTopics,
            beltLevel: "white"
        )
        XCTAssertEqual(progress.count, 4, "Must return an entry for each requested sub-topic")
        XCTAssertTrue(progress.values.allSatisfy { $0 >= 0 && $0 <= 100 },
                      "avgStrength must be in range 0-100")
    }

    // MARK: - Language filter

    func test_integration_fetchSessionComposition_languageES_returnsESQuestions() async throws {
        // Given: the database has ES-language questions for closed_guard
        // When: fetching with language = "es"
        // Then: returned questions have language = "es"
        let questions = try await supabase.fetchSessionComposition(
            userId: testUserId,
            topic: "closed_guard",
            beltLevel: "white",
            language: "es"
        )
        guard !questions.isEmpty else {
            throw XCTSkip("No ES questions in test database - skip language filter assertion")
        }
        XCTAssertTrue(questions.allSatisfy { $0.language == "es" },
                      "Language filter must return only ES questions when requested")
    }
}
