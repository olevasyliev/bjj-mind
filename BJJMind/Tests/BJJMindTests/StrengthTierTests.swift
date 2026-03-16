import XCTest
@testable import BJJMind

final class StrengthTierTests: XCTestCase {

    // MARK: - Weak tier (0-49)

    func test_strengthTier_zero_isWeak() {
        // Given: strength = 0
        // When: computing tier label
        // Then: label is "Weak"
        XCTAssertEqual(StrengthTier(strength: 0).label, "Weak")
    }

    func test_strengthTier_one_isWeak() {
        // Given: strength = 1 (above absolute zero but still Weak)
        XCTAssertEqual(StrengthTier(strength: 1).label, "Weak")
    }

    func test_strengthTier_49_isWeak() {
        // Given: strength = 49 (last value in Weak range)
        XCTAssertEqual(StrengthTier(strength: 49).label, "Weak")
    }

    // MARK: - Learning tier (50-69)

    func test_strengthTier_50_isLearning() {
        // Given: strength = 50 (first value in Learning range)
        XCTAssertEqual(StrengthTier(strength: 50).label, "Learning")
    }

    func test_strengthTier_60_isLearning() {
        // Given: strength = 60 (mid-range)
        XCTAssertEqual(StrengthTier(strength: 60).label, "Learning")
    }

    func test_strengthTier_69_isLearning() {
        // Given: strength = 69 (last value in Learning range)
        XCTAssertEqual(StrengthTier(strength: 69).label, "Learning")
    }

    // MARK: - Solid tier (70-89)

    func test_strengthTier_70_isSolid() {
        // Given: strength = 70 (first value in Solid range, also boss-unlock threshold)
        XCTAssertEqual(StrengthTier(strength: 70).label, "Solid")
    }

    func test_strengthTier_80_isSolid() {
        // Given: strength = 80 (mid-range)
        XCTAssertEqual(StrengthTier(strength: 80).label, "Solid")
    }

    func test_strengthTier_89_isSolid() {
        // Given: strength = 89 (last value in Solid range)
        XCTAssertEqual(StrengthTier(strength: 89).label, "Solid")
    }

    // MARK: - Mastered tier (90-100)

    func test_strengthTier_90_isMastered() {
        // Given: strength = 90 (first value in Mastered range)
        XCTAssertEqual(StrengthTier(strength: 90).label, "Mastered")
    }

    func test_strengthTier_100_isMastered() {
        // Given: strength = 100 (maximum possible value)
        XCTAssertEqual(StrengthTier(strength: 100).label, "Mastered")
    }

    // MARK: - Enum cases match expected raw ranges

    func test_strengthTier_weak_rawRange_is0to49() {
        XCTAssertEqual(StrengthTier(strength: 0),  .weak)
        XCTAssertEqual(StrengthTier(strength: 49), .weak)
    }

    func test_strengthTier_learning_rawRange_is50to69() {
        XCTAssertEqual(StrengthTier(strength: 50), .learning)
        XCTAssertEqual(StrengthTier(strength: 69), .learning)
    }

    func test_strengthTier_solid_rawRange_is70to89() {
        XCTAssertEqual(StrengthTier(strength: 70), .solid)
        XCTAssertEqual(StrengthTier(strength: 89), .solid)
    }

    func test_strengthTier_mastered_rawRange_is90to100() {
        XCTAssertEqual(StrengthTier(strength: 90),  .mastered)
        XCTAssertEqual(StrengthTier(strength: 100), .mastered)
    }

    // MARK: - isMastered convenience

    func test_strengthTier_isMastered_trueAt90() {
        XCTAssertTrue(StrengthTier(strength: 90).isMastered)
    }

    func test_strengthTier_isMastered_falseAt89() {
        XCTAssertFalse(StrengthTier(strength: 89).isMastered)
    }

    func test_strengthTier_isSolid_trueAt70() {
        XCTAssertTrue(StrengthTier(strength: 70).isSolid)
    }

    func test_strengthTier_isSolid_falseAt69() {
        XCTAssertFalse(StrengthTier(strength: 69).isSolid)
    }
}
