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
            tags: [], isLocked: false, isCompleted: false, kind: .beltTest, questions: []
        )
        XCTAssertTrue(beltTest.isBeltTest)
    }

    func test_unit_lockedByDefault_isRespected() {
        let unit = Unit(
            id: "u-1", belt: .white, orderIndex: 1,
            title: "Closed Guard", description: "",
            tags: ["guard"], isLocked: true, isCompleted: false, kind: .lesson, questions: []
        )
        XCTAssertTrue(unit.isLocked)
        XCTAssertFalse(unit.isCompleted)
    }
}

final class UnitKindTests: XCTestCase {

    func test_unitKind_beltTest_isBeltTestTrue() {
        let unit = Unit(
            id: "bt-1", belt: .white, orderIndex: 0,
            title: "Stripe Test", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .beltTest, questions: []
        )
        XCTAssertTrue(unit.isBeltTest)
    }

    func test_unitKind_lesson_isBeltTestFalse() {
        let unit = Unit(
            id: "l-1", belt: .white, orderIndex: 0,
            title: "Lesson 1", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .lesson, questions: []
        )
        XCTAssertFalse(unit.isBeltTest)
    }

    func test_unitKind_characterMoment_isCharacterMomentTrue() {
        let unit = Unit(
            id: "cm-1", belt: .white, orderIndex: 0,
            title: "", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .characterMoment,
            questions: [],
            characterMoment: CharacterMomentData(
                character: .marco,
                message: "Hip frame first — always."
            )
        )
        XCTAssertTrue(unit.isCharacterMoment)
        XCTAssertEqual(unit.characterMoment?.character, .marco)
    }

    func test_unitKind_miniExam_isMiniExamTrue() {
        let unit = Unit(
            id: "me-1", belt: .white, orderIndex: 0,
            title: "Section Exam", description: "", tags: [],
            isLocked: true, isCompleted: false,
            kind: .miniExam, questions: []
        )
        XCTAssertTrue(unit.isMiniExam)
    }

    func test_appCharacter_displayNames() {
        XCTAssertEqual(AppCharacter.marco.displayName, "Marco")
        XCTAssertEqual(AppCharacter.oldChen.displayName, "Old Chen")
        XCTAssertEqual(AppCharacter.rex.displayName, "Rex")
        XCTAssertEqual(AppCharacter.giGhost.displayName, "Gi Ghost")
    }

    func test_unitKind_mixedReview_isMixedReviewTrue() {
        let unit = Unit(
            id: "mr-1", belt: .white, orderIndex: 0,
            title: "Mixed Review", description: "", tags: [],
            isLocked: true, isCompleted: false,
            kind: .mixedReview, questions: []
        )
        XCTAssertTrue(unit.isMixedReview)
    }

    func test_unit_requiresSession_falseForCharacterMoment() {
        let unit = Unit(
            id: "cm-2", belt: .white, orderIndex: 0,
            title: "", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .characterMoment, questions: []
        )
        XCTAssertFalse(unit.requiresSession)
    }

    func test_unit_requiresSession_trueForLesson() {
        let unit = Unit(
            id: "l-2", belt: .white, orderIndex: 0,
            title: "Lesson", description: "", tags: [],
            isLocked: false, isCompleted: false,
            kind: .lesson, questions: []
        )
        XCTAssertTrue(unit.requiresSession)
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
