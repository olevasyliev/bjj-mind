import XCTest
@testable import BJJMind

final class StrengthDecayTests: XCTestCase {

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    // MARK: - One decay period (3 days)

    func test_decay_strength60_after3Days_becomes55() {
        // Given: strength = 60, last_seen = 3 days ago
        // When: applying decay
        // Then: strength drops by 5 (one 3-day period)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(3))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 55, "Three days = one decay period = -5")
    }

    // MARK: - Three decay periods (9 days)

    func test_decay_strength60_after9Days_becomes45() {
        // Given: strength = 60, last_seen = 9 days ago
        // When: applying decay
        // Then: strength drops by 15 (three 3-day periods)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(9))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 45, "Nine days = three decay periods = -15")
    }

    // MARK: - Less than one decay period (no decay)

    func test_decay_strength60_after1Day_unchanged() {
        // Given: strength = 60, last_seen = 1 day ago (less than 3 days)
        // When: applying decay
        // Then: no change (decay threshold not reached)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(1))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 60, "Less than 3 days = no decay applied")
    }

    func test_decay_strength60_after2Days_unchanged() {
        // Given: strength = 60, last_seen = 2 days ago (still less than 3)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(2))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 60)
    }

    // MARK: - Floor at zero

    func test_decay_lowStrength_doesNotGoBelowZero() {
        // Given: strength = 5, last_seen = 9 days ago (would decay by 15 to -10)
        // When: applying decay
        // Then: floor at 0, no negative values
        let stat = StatFixtures.make(questionId: "q1", strength: 5, lastSeen: daysAgo(9))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 0, "Strength must not decay below 0")
    }

    func test_decay_strength0_remainsZeroAfterAnyTime() {
        // Given: strength = 0 (already at floor)
        // When: 30 days have passed
        // Then: still 0
        let stat = StatFixtures.make(questionId: "q1", strength: 0, lastSeen: daysAgo(30))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 0, "Strength of 0 cannot decay further")
    }

    // MARK: - Null last_seen

    func test_decay_nullLastSeen_noDecayApplied() {
        // Given: last_seen is nil (question was never tracked with a timestamp)
        // When: applying decay
        // Then: strength unchanged (nil = unknown date = no decay)
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: nil)
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 60, "nil last_seen must not trigger decay")
    }

    // MARK: - Partial period (4, 5 days)

    func test_decay_strength60_after4Days_loses5() {
        // Given: 4 days elapsed = floor(4/3) = 1 full period
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(4))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 55, "4 days = 1 complete decay period = -5")
    }

    func test_decay_strength60_after6Days_loses10() {
        // Given: 6 days = floor(6/3) = 2 full periods
        let stat = StatFixtures.make(questionId: "q1", strength: 60, lastSeen: daysAgo(6))
        let result = StrengthDecayCalculator.apply(to: stat, referenceDate: Date())
        XCTAssertEqual(result, 50, "6 days = 2 complete decay periods = -10")
    }
}
