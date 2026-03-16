import XCTest
@testable import BJJMind

final class SessionCompositionTests: XCTestCase {

    // MARK: - Standard 60/25/15 split

    func test_compose_standardCase_returns9Questions() {
        // Given: 20 new questions, 10 weak, 10 refresh available
        // When: composing a session with default size 9
        // Then: exactly 9 questions returned
        let newQs     = QuestionFixtures.batch(count: 20, subTopic: "posture_defense")
        let weakQs    = QuestionFixtures.batch(count: 10, subTopic: "guard_attacks")
        let refreshQs = QuestionFixtures.batch(count: 10, topic: "guard_passing", subTopic: "kneeling_pass")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: refreshQs,
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 9, "Standard case must return exactly 9 questions")
    }

    func test_compose_standardCase_bucketOrdering_newFirst() {
        // Given: distinct questions per bucket, known IDs
        // When: composed
        // Then: new-bucket questions appear before weak-bucket, which appear before refresh
        let newQ     = QuestionFixtures.make(id: "new-1", subTopic: "posture_defense")
        let weakQ    = QuestionFixtures.make(id: "weak-1", subTopic: "guard_attacks")
        let refreshQ = QuestionFixtures.make(id: "refresh-1", topic: "guard_passing", subTopic: "kneeling_pass")

        let result = SessionCompositionBuilder.compose(
            newQuestions: [newQ],
            weakQuestions: [weakQ],
            refreshQuestions: [refreshQ],
            sessionSize: 3
        )

        let ids = result.map(\.id)
        XCTAssertLessThan(ids.firstIndex(of: "new-1")!,
                          ids.firstIndex(of: "weak-1")!,
                          "New questions must appear before weak questions")
        XCTAssertLessThan(ids.firstIndex(of: "weak-1")!,
                          ids.firstIndex(of: "refresh-1")!,
                          "Weak questions must appear before refresh questions")
    }

    // MARK: - Not enough new questions

    func test_compose_notEnoughNew_fillsFromWeak() {
        // Given: only 2 new questions available (need 5), plenty of weak
        // When: composing 9-question session
        // Then: total is still 9 (or as close as possible), weak bucket compensates
        let newQs  = QuestionFixtures.batch(count: 2, subTopic: "posture_defense")
        let weakQs = QuestionFixtures.batch(count: 10, subTopic: "guard_attacks")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertGreaterThanOrEqual(result.count, 6, "Session must have at least 6 questions")
        XCTAssertLessThanOrEqual(result.count, 9)

        let weakIds = Set(weakQs.map(\.id))
        let returnedWeakCount = result.filter { weakIds.contains($0.id) }.count
        XCTAssertGreaterThan(returnedWeakCount, 2,
                             "When new bucket is short, weak bucket fills the gap")
    }

    // MARK: - Zero new questions

    func test_compose_zeroNew_allFromWeakAndRefresh() {
        // Given: no new questions at all (user has seen everything)
        // When: composing session
        // Then: result comes entirely from weak + refresh buckets
        let weakQs    = QuestionFixtures.batch(count: 6, subTopic: "guard_attacks")
        let refreshQs = QuestionFixtures.batch(count: 4, topic: "guard_passing", subTopic: "kneeling_pass")

        let result = SessionCompositionBuilder.compose(
            newQuestions: [],
            weakQuestions: weakQs,
            refreshQuestions: refreshQs,
            sessionSize: 9
        )

        XCTAssertFalse(result.isEmpty, "Session must not be empty even with zero new questions")
        let resultIds = Set(result.map(\.id))
        let allowedIds = Set((weakQs + refreshQs).map(\.id))
        XCTAssertTrue(resultIds.isSubset(of: allowedIds),
                      "All returned questions must come from weak or refresh buckets")
    }

    // MARK: - First session ever

    func test_compose_firstSession_allFromNewBucket() {
        // Given: user has no stats at all (first session ever), plenty of new questions
        // When: composing session
        // Then: all questions are from bucket 1 (new), none from weak or refresh
        let newQs = QuestionFixtures.batch(count: 20, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 9)
        let newIds = Set(newQs.map(\.id))
        XCTAssertTrue(result.allSatisfy { newIds.contains($0.id) },
                      "First session must draw exclusively from new-question bucket")
    }

    // MARK: - Minimum viable session

    func test_compose_totalPoolLessThan9_returnAllAvailable() {
        // Given: only 4 questions exist across all buckets
        // When: requesting 9-question session
        // Then: returns all 4 (no crash, no duplicates)
        let newQs  = QuestionFixtures.batch(count: 2, subTopic: "posture_defense")
        let weakQs = QuestionFixtures.batch(count: 2, subTopic: "guard_attacks")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 4, "Must return all available questions when pool < sessionSize")
    }

    func test_compose_totalPoolLessThan6_returnsWhatIsAvailable() {
        // Given: only 3 questions total
        // When: composing
        // Then: returns 3, not an empty array or a crash
        let questions = QuestionFixtures.batch(count: 3, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: questions,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertEqual(result.count, 3)
    }

    // MARK: - No duplicate questions across buckets

    func test_compose_noDuplicatesAcrossBuckets() {
        // Given: same question appears in new AND weak buckets (edge case in server response)
        // When: composing
        // Then: question appears exactly once in result
        let sharedQ = QuestionFixtures.make(id: "shared-q")
        let newQs   = [sharedQ] + QuestionFixtures.batch(count: 5, subTopic: "guard_attacks")
        let weakQs  = [sharedQ] + QuestionFixtures.batch(count: 3, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: newQs,
            weakQuestions: weakQs,
            refreshQuestions: [],
            sessionSize: 9
        )

        let ids = result.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "No question should appear twice in the session")
    }

    // MARK: - mcq3 exclusion

    func test_compose_mcq3QuestionsNeverIncluded() {
        // Given: some questions have format = mcq3
        // When: composing session
        // Then: no mcq3 question appears in the result
        let mcq3Qs = (0..<5).map { i in QuestionFixtures.makeMcq3(id: "mcq3-\(i)") }
        let validQs = QuestionFixtures.batch(count: 5, subTopic: "posture_defense")

        let result = SessionCompositionBuilder.compose(
            newQuestions: mcq3Qs + validQs,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9
        )

        XCTAssertFalse(result.contains(where: { $0.format == .mcq3 }),
                       "mcq3 questions must never appear in a learning session")
    }

    // MARK: - Language filtering

    func test_compose_languageFilter_onlyReturnsMatchingLanguage() {
        // Given: mix of EN and ES questions
        // When: composing with language = "es"
        // Then: only ES questions appear in result
        let enQs = (0..<5).map { i in QuestionFixtures.make(id: "q-en-\(i)", language: "en") }
        let esQs = (0..<5).map { i in QuestionFixtures.make(id: "q-es-\(i)", language: "es") }

        let result = SessionCompositionBuilder.compose(
            newQuestions: enQs + esQs,
            weakQuestions: [],
            refreshQuestions: [],
            sessionSize: 9,
            language: "es"
        )

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.language == "es" },
                      "Language filter must exclude questions not matching requested language")
    }
}
