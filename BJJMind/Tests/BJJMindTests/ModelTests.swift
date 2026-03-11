import XCTest
@testable import BJJMind

final class BeltTests: XCTestCase {

    func test_belt_displayName_isCapitalized() {
        XCTAssertEqual(Belt.white.displayName, "White")
        XCTAssertEqual(Belt.blue.displayName, "Blue")
        XCTAssertEqual(Belt.purple.displayName, "Purple")
    }

    func test_belt_maxStripes_isFour() {
        for belt in Belt.allCases {
            XCTAssertEqual(belt.maxStripes, 4)
        }
    }

    func test_belt_allCases_containsFiveBelts() {
        XCTAssertEqual(Belt.allCases.count, 5)
    }
}

final class UserProfileTests: XCTestCase {

    func test_guestProfile_hasFullHearts() {
        XCTAssertEqual(UserProfile.guest.hearts, UserProfile.maxHearts)
    }

    func test_guestProfile_hasZeroXP() {
        XCTAssertEqual(UserProfile.guest.xpTotal, 0)
    }

    func test_guestProfile_hasZeroStreak() {
        XCTAssertEqual(UserProfile.guest.streakCurrent, 0)
    }

    func test_guestProfile_startsAtWhiteBelt() {
        XCTAssertEqual(UserProfile.guest.belt, .white)
    }

    func test_maxHearts_isFive() {
        XCTAssertEqual(UserProfile.maxHearts, 5)
    }

    func test_guestProfile_hasUniqueId() {
        XCTAssertNotEqual(UserProfile.guest.id, UserProfile.guest.id)
    }

    func test_stripes_cannotExceedMaxStripes() {
        var user = UserProfile.guest
        for _ in 0..<10 { user.addStripe() }
        XCTAssertEqual(user.stripes, Belt.white.maxStripes)
    }
}

final class UnitTests: XCTestCase {

    func test_unit_isBeltTest_flagIsRespected() {
        let beltTest = Unit(
            id: "bt-1", belt: .white, orderIndex: 7,
            title: "Stripe 1 Test", description: "",
            tags: [], isLocked: false, isCompleted: false, isBeltTest: true, questions: []
        )
        XCTAssertTrue(beltTest.isBeltTest)
    }

    func test_unit_lockedByDefault_isRespected() {
        let unit = Unit(
            id: "u-1", belt: .white, orderIndex: 1,
            title: "Closed Guard", description: "",
            tags: ["guard"], isLocked: true, isCompleted: false, isBeltTest: false, questions: []
        )
        XCTAssertTrue(unit.isLocked)
        XCTAssertFalse(unit.isCompleted)
    }
}

final class QuestionTests: XCTestCase {

    func test_question_trueFalse_hasTwoOptions() {
        let q = Question(
            id: "q-1", unitId: "u-1", format: .trueFalse,
            prompt: "Is closed guard a dominant position?",
            options: ["True", "False"],
            correctAnswer: "True",
            explanation: "Closed guard gives control.",
            tags: ["guard"], difficulty: 1, sceneImageName: nil
        )
        XCTAssertEqual(q.options?.count, 2)
    }

    func test_question_mcq4_correctAnswerIsInOptions() {
        let q = Question(
            id: "q-2", unitId: "u-1", format: .mcq4,
            prompt: "Best grip in closed guard?",
            options: ["Collar and sleeve", "Double collar", "Underhooks", "Wrist control"],
            correctAnswer: "Double collar",
            explanation: "Double collar breaks posture.",
            tags: ["guard"], difficulty: 2, sceneImageName: nil
        )
        XCTAssertTrue(q.options?.contains(q.correctAnswer) ?? false)
    }

    func test_question_difficulty_clampedAboveMax() {
        let q = Question(
            id: "q-3", unitId: "u-1", format: .mcq2,
            prompt: "Test", options: ["A", "B"],
            correctAnswer: "A", explanation: "",
            tags: [], difficulty: 99, sceneImageName: nil
        )
        XCTAssertEqual(q.difficulty, 5)
    }

    func test_question_difficulty_clampedBelowMin() {
        let q = Question(
            id: "q-4", unitId: "u-1", format: .mcq2,
            prompt: "Test", options: ["A", "B"],
            correctAnswer: "A", explanation: "",
            tags: [], difficulty: 0, sceneImageName: nil
        )
        XCTAssertEqual(q.difficulty, 1)
    }

    func test_sessionResult_hasUserId() {
        let result = SessionResult(
            userId: "user-123",
            unitId: "u-1",
            completedAt: Date(),
            xpEarned: 30,
            accuracy: 1.0,
            heartsUsed: 0,
            weakTags: []
        )
        XCTAssertEqual(result.userId, "user-123")
    }
}
