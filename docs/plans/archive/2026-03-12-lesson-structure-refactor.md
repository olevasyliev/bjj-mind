# Lesson Structure Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Break monolithic units (8-15 questions each) into short lessons (~8 questions), add character moment cards between topics, mixed review, and section mini-exams — turning a boring question list into a rhythmic learning experience.

**Architecture:** Add `UnitKind` enum to replace `isBeltTest: Bool`. Each former "unit" becomes a "topic" containing multiple lesson nodes, plus special nodes (CharacterMoment, MixedReview, MiniExam). `SessionEngine` is unchanged — it receives `[Question]` regardless of kind. `AppState` handles CharacterMoment completion without launching a session.

**Tech Stack:** Swift 6.0, SwiftUI, XCTest (TDD), existing `AppState` / `SessionEngine` / `QuestionProvider` architecture.

---

## What changes and why

| File | Change |
|------|--------|
| `Models.swift` | Add `UnitKind`, `AppCharacter`, `CharacterMomentData`; update `Unit` |
| `SampleData.swift` | Split units into lessons; add CharacterMoment / MixedReview / MiniExam nodes |
| `AppState.swift` | Update `applyRemoteBundles` init; update lock chain for CharacterMoment nodes |
| `HomeView.swift` | Topic headers, new node types, CharacterMoment sheet |
| `CharacterMomentView.swift` | New file — full-screen character card |
| `ModelTests.swift` | Update Unit inits, add new type tests |
| `AppStateTests.swift` | Update Unit inits |
| `SessionEngineTests.swift` | No changes needed |

---

## Task 1: Add new model types

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Core/Models.swift`
- Test: `BJJMind/Tests/BJJMindTests/ModelTests.swift`

### Step 1: Write failing tests

Add to `ModelTests.swift` in a new `UnitKindTests` class:

```swift
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
}
```

### Step 2: Run — expect FAIL (UnitKind, AppCharacter, CharacterMomentData don't exist yet)

```bash
cd bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|PASSED|FAILED|warning:" | head -30
```

Expected: compile error — `UnitKind` undefined.

### Step 3: Update Models.swift

Replace the `// MARK: - Unit` section with:

```swift
// MARK: - UnitKind

enum UnitKind: String, Codable {
    case lesson           // regular lesson (~8 questions) within a topic
    case mixedReview      // cross-topic review lesson
    case miniExam         // section-level exam (~12 questions)
    case beltTest         // existing stripe belt test
    case characterMoment  // character card — no questions, auto-completes
}

// MARK: - AppCharacter

enum AppCharacter: String, Codable {
    case marco, oldChen, rex, giGhost

    var displayName: String {
        switch self {
        case .marco:    return "Marco"
        case .oldChen:  return "Old Chen"
        case .rex:      return "Rex"
        case .giGhost:  return "Gi Ghost"
        }
    }
}

// MARK: - CharacterMomentData

struct CharacterMomentData: Codable, Equatable {
    var character: AppCharacter
    var message: String
}

// MARK: - Unit

struct Unit: Identifiable, Codable, Hashable {
    static func == (lhs: Unit, rhs: Unit) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var id: String
    var belt: Belt
    var orderIndex: Int
    var title: String
    var description: String
    var tags: [String]
    var isLocked: Bool
    var isCompleted: Bool
    var kind: UnitKind
    var questions: [Question]

    // Optional metadata
    var coachIntro: String?
    var sectionTitle: String?    // shown as section divider when it changes
    var topicTitle: String?      // shown as topic sub-header when it changes
    var lessonIndex: Int?        // 1-based lesson number within topic (for "Lesson 2 of 3" display)
    var lessonTotal: Int?        // total lessons in this topic
    var characterMoment: CharacterMomentData?

    // MARK: - Computed backward-compat

    var isBeltTest: Bool        { kind == .beltTest }
    var isCharacterMoment: Bool { kind == .characterMoment }
    var isMiniExam: Bool        { kind == .miniExam }
    var isMixedReview: Bool     { kind == .mixedReview }

    /// True when this node requires a session to complete (has questions)
    var requiresSession: Bool {
        switch kind {
        case .lesson, .mixedReview, .miniExam, .beltTest: return true
        case .characterMoment: return false
        }
    }
}
```

### Step 4: Run tests — expect FAIL (old Unit inits still use `isBeltTest:` param)

```bash
xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:" | head -20
```

Expected: compile errors in `ModelTests.swift`, `AppStateTests.swift`, `AppState.swift`, `SampleData.swift`.

### Step 5: Commit models (before fixing call sites)

```bash
git add BJJMind/Sources/BJJMind/Core/Models.swift
git commit -m "feat: add UnitKind enum, AppCharacter, CharacterMomentData to models"
```

---

## Task 2: Fix all Unit initializations

**Files:**
- Modify: `BJJMind/Tests/BJJMindTests/ModelTests.swift`
- Modify: `BJJMind/Tests/BJJMindTests/AppStateTests.swift`
- Modify: `BJJMind/Sources/BJJMind/Core/AppState.swift`

### Step 1: Fix ModelTests.swift

In `UnitTests` class, update both test units — replace `isBeltTest: true/false` with `kind: .beltTest` / `kind: .lesson`:

```swift
final class UnitTests: XCTestCase {

    func test_unit_isBeltTest_flagIsRespected() {
        let beltTest = Unit(
            id: "bt-1", belt: .white, orderIndex: 7,
            title: "Stripe 1 Test", description: "",
            tags: [], isLocked: false, isCompleted: false,
            kind: .beltTest, questions: []
        )
        XCTAssertTrue(beltTest.isBeltTest)
    }

    func test_unit_lockedByDefault_isRespected() {
        let unit = Unit(
            id: "u-1", belt: .white, orderIndex: 1,
            title: "Closed Guard", description: "",
            tags: ["guard"], isLocked: true, isCompleted: false,
            kind: .lesson, questions: []
        )
        XCTAssertTrue(unit.isLocked)
        XCTAssertFalse(unit.isCompleted)
    }
}
```

### Step 2: Fix AppStateTests.swift

Read the file first, then replace every `isBeltTest:` parameter:
- `isBeltTest: false` → `kind: .lesson`
- `isBeltTest: true`  → `kind: .beltTest`

### Step 3: Fix AppState.swift — applyRemoteBundles

Find `applyRemoteBundles`. The `RemoteUnitBundle` still has `isBeltTest: Bool`. Map it to `kind`:

```swift
Unit(
    id: b.id, belt: b.belt, orderIndex: b.orderIndex,
    title: b.title, description: b.description, tags: b.tags,
    isLocked: true,
    isCompleted: completedIds.contains(b.id),
    kind: b.isBeltTest ? .beltTest : .lesson,
    questions: b.questions,
    coachIntro: b.coachIntro
)
```

Also update the lock chain inside `applyRemoteBundles` — CharacterMoment nodes should be treated like regular lessons in the chain (not like belt tests):

```swift
for i in 1..<rebuilt.count {
    if rebuilt[i].isBeltTest {
        let allDone = rebuilt.filter { !$0.isBeltTest }.allSatisfy { $0.isCompleted }
        rebuilt[i].isLocked = !allDone
    } else {
        rebuilt[i].isLocked = !rebuilt[i - 1].isCompleted
    }
}
```

(No change needed here — CharacterMoment nodes will unlock sequentially like lessons.)

### Step 4: Run tests — expect all PASS

```bash
xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED|error:" | head -20
```

Expected: all pass (SampleData.swift still broken — that's Task 3).

### Step 5: Commit

```bash
git add BJJMind/Tests/BJJMindTests/ModelTests.swift \
        BJJMind/Tests/BJJMindTests/AppStateTests.swift \
        BJJMind/Sources/BJJMind/Core/AppState.swift
git commit -m "fix: update all Unit inits to use kind: instead of isBeltTest:"
```

---

## Task 3: Rewrite SampleData

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Core/SampleData.swift`

This is the biggest content task. The goal: split each topic's 8 questions into 2 lessons of 4 questions, add CharacterMoment nodes between topic groups, add a MixedReview lesson, add a MiniExam per section.

**No new tests needed** — SampleData is static content, validated by the app running.

### Step 1: Plan the new node sequence

New `whitebelt_en` array (44 nodes total replacing 11):

```
GUARD GAME section:
  wb-01-l1  Closed Guard Control · Lesson 1  (q-cg-01..04, kind: .lesson)
  wb-01-l2  Closed Guard Control · Lesson 2  (q-cg-05..08, kind: .lesson)
  wb-02-l1  Closed Guard Attacks · Lesson 1  (q-ca-01..04, kind: .lesson)
  wb-02-l2  Closed Guard Attacks · Lesson 2  (q-ca-05..08, kind: .lesson)
  wb-cm-01  [CharacterMoment: Marco — guard tip]
  wb-03-l1  Guard Passing · Lesson 1         (q-gp-01..04, kind: .lesson)
  wb-03-l2  Guard Passing · Lesson 2         (q-gp-05..08, kind: .lesson)
  wb-mr-gg  Guard Game Mixed Review          (2 questions from each topic, kind: .mixedReview)
  wb-me-gg  Guard Game Mini Exam             (8 questions mixed, kind: .miniExam)

TOP GAME section:
  wb-04-l1  Side Control Top · Lesson 1      (kind: .lesson)
  wb-04-l2  Side Control Top · Lesson 2      (kind: .lesson)
  wb-05-l1  Side Control Escape · Lesson 1   (kind: .lesson)
  wb-05-l2  Side Control Escape · Lesson 2   (kind: .lesson)
  wb-cm-02  [CharacterMoment: Old Chen — control tip]
  wb-06-l1  Mount Control · Lesson 1         (kind: .lesson)
  wb-06-l2  Mount Control · Lesson 2         (kind: .lesson)
  wb-07-l1  Mount Escape · Lesson 1          (kind: .lesson)
  wb-07-l2  Mount Escape · Lesson 2          (kind: .lesson)
  wb-cm-03  [CharacterMoment: Rex — mount celebration]
  wb-mr-tg  Top Game Mixed Review            (kind: .mixedReview)
  wb-me-tg  Top Game Mini Exam               (kind: .miniExam)

BACK & SUBMISSIONS section:
  wb-08-l1  Back Control · Lesson 1          (kind: .lesson)
  wb-08-l2  Back Control · Lesson 2          (kind: .lesson)
  wb-09-l1  Submissions · Lesson 1           (kind: .lesson)
  wb-09-l2  Submissions · Lesson 2           (kind: .lesson)
  wb-cm-04  [CharacterMoment: Old Chen — submission principle]
  wb-10-l1  Takedowns · Lesson 1             (kind: .lesson)
  wb-10-l2  Takedowns · Lesson 2             (kind: .lesson)
  wb-mr-bs  Back & Submissions Mixed Review  (kind: .mixedReview)
  wb-me-bs  Back & Submissions Mini Exam     (kind: .miniExam)

BELT TEST:
  wb-bt1    Stripe 1 Test                    (kind: .beltTest)
```

### Step 2: Rewrite the `Unit` extension at the bottom of SampleData.swift

Keep all the existing question arrays unchanged. Only the `whitebelt_en` array changes.

Split each question array into two halves. Example for closedGuardControlQuestions (8 questions):
- Lesson 1: questions at indices 0..<4 → `Array(closedGuardControlQuestions[0..<4])`
- Lesson 2: questions at indices 4..<8 → `Array(closedGuardControlQuestions[4..<8])`

For CharacterMoment nodes, questions is `[]`.

For MixedReview, pick 2 questions from each preceding topic (use existing question IDs).

For MiniExam, pick 8 questions mixed from the section topics.

```swift
extension Unit {
    static let whitebelt_en: [Unit] = [

        // ── GUARD GAME ─────────────────────────────────────────────────────

        Unit(id: "wb-01-l1", belt: .white, orderIndex: 0,
             title: "Closed Guard Control", description: "Control and break posture",
             tags: ["guard"], isLocked: false, isCompleted: false,
             kind: .lesson,
             questions: Array(closedGuardControlQuestions[0..<4]),
             coachIntro: "Closed guard is your first weapon. Pull their head down, keep your knees tight.",
             sectionTitle: "Guard Game",
             topicTitle: "Closed Guard Control",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-01-l2", belt: .white, orderIndex: 1,
             title: "Closed Guard Control", description: "Control and break posture",
             tags: ["guard"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(closedGuardControlQuestions[4..<8]),
             topicTitle: "Closed Guard Control",
             lessonIndex: 2, lessonTotal: 2),

        Unit(id: "wb-02-l1", belt: .white, orderIndex: 2,
             title: "Closed Guard Attacks", description: "Sweeps and submissions",
             tags: ["guard", "sweeps"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(closedGuardAttackQuestions[0..<4]),
             coachIntro: "Attacks flow from a broken posture. Triangle, armbar, hip bump — they all start the same way.",
             topicTitle: "Closed Guard Attacks",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-02-l2", belt: .white, orderIndex: 3,
             title: "Closed Guard Attacks", description: "Sweeps and submissions",
             tags: ["guard", "sweeps"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(closedGuardAttackQuestions[4..<8]),
             topicTitle: "Closed Guard Attacks",
             lessonIndex: 2, lessonTotal: 2),

        // Character moment: Marco after Closed Guard
        Unit(id: "wb-cm-01", belt: .white, orderIndex: 4,
             title: "Marco", description: "",
             tags: [], isLocked: true, isCompleted: false,
             kind: .characterMoment,
             questions: [],
             characterMoment: CharacterMomentData(
                 character: .marco,
                 message: "Closed guard is a system, not just a position. You're not waiting — you're hunting. Every second they're in your guard, you're looking for the break."
             )),

        Unit(id: "wb-03-l1", belt: .white, orderIndex: 5,
             title: "Guard Passing", description: "Break and pass the closed guard",
             tags: ["guard", "passing"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(guardPassingQuestions[0..<4]),
             coachIntro: "Passing guard requires patience. Keep elbows tight, control their hips.",
             topicTitle: "Guard Passing",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-03-l2", belt: .white, orderIndex: 6,
             title: "Guard Passing", description: "Break and pass the closed guard",
             tags: ["guard", "passing"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(guardPassingQuestions[4..<8]),
             topicTitle: "Guard Passing",
             lessonIndex: 2, lessonTotal: 2),

        // Mixed Review: Guard Game
        Unit(id: "wb-mr-gg", belt: .white, orderIndex: 7,
             title: "Guard Game Review", description: "Mixed questions from all guard topics",
             tags: ["guard"], isLocked: true, isCompleted: false,
             kind: .mixedReview,
             questions: [
                 closedGuardControlQuestions[0],
                 closedGuardControlQuestions[4],
                 closedGuardAttackQuestions[0],
                 closedGuardAttackQuestions[4],
                 guardPassingQuestions[0],
                 guardPassingQuestions[4],
             ],
             sectionTitle: nil,
             topicTitle: nil),

        // Mini Exam: Guard Game
        Unit(id: "wb-me-gg", belt: .white, orderIndex: 8,
             title: "Guard Game Exam", description: "Prove your guard game",
             tags: ["guard"], isLocked: true, isCompleted: false,
             kind: .miniExam,
             questions: [
                 closedGuardControlQuestions[1],
                 closedGuardControlQuestions[5],
                 closedGuardAttackQuestions[1],
                 closedGuardAttackQuestions[5],
                 guardPassingQuestions[1],
                 guardPassingQuestions[5],
                 closedGuardControlQuestions[2],
                 closedGuardAttackQuestions[2],
             ]),

        // ── TOP GAME ───────────────────────────────────────────────────────

        Unit(id: "wb-04-l1", belt: .white, orderIndex: 9,
             title: "Side Control Top", description: "Maintain and dominate",
             tags: ["side control"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(sideControlTopQuestions[0..<4]),
             coachIntro: "Side control is all about weight and angles. Hips low, cross-face on.",
             sectionTitle: "Top Game",
             topicTitle: "Side Control Top",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-04-l2", belt: .white, orderIndex: 10,
             title: "Side Control Top", description: "Maintain and dominate",
             tags: ["side control"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(sideControlTopQuestions[4..<8]),
             topicTitle: "Side Control Top",
             lessonIndex: 2, lessonTotal: 2),

        Unit(id: "wb-05-l1", belt: .white, orderIndex: 11,
             title: "Side Control Escape", description: "Recover guard",
             tags: ["side control", "escapes"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(sideControlEscapeQuestions[0..<4]),
             coachIntro: "Escaping side control starts with frames — create space before you move.",
             topicTitle: "Side Control Escape",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-05-l2", belt: .white, orderIndex: 12,
             title: "Side Control Escape", description: "Recover guard",
             tags: ["side control", "escapes"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(sideControlEscapeQuestions[4..<8]),
             topicTitle: "Side Control Escape",
             lessonIndex: 2, lessonTotal: 2),

        // Character moment: Old Chen after side control
        Unit(id: "wb-cm-02", belt: .white, orderIndex: 13,
             title: "Old Chen", description: "",
             tags: [], isLocked: true, isCompleted: false,
             kind: .characterMoment,
             questions: [],
             characterMoment: CharacterMomentData(
                 character: .oldChen,
                 message: "You moved before you were ready. The escape starts earlier than you think."
             )),

        Unit(id: "wb-06-l1", belt: .white, orderIndex: 14,
             title: "Mount Control", description: "Maintain and advance from mount",
             tags: ["mount"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(mountControlQuestions[0..<4]),
             coachIntro: "Mount is your highest value position. Low hips, cross-face, follow their escapes.",
             topicTitle: "Mount Control",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-06-l2", belt: .white, orderIndex: 15,
             title: "Mount Control", description: "Maintain and advance from mount",
             tags: ["mount"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(mountControlQuestions[4..<8]),
             topicTitle: "Mount Control",
             lessonIndex: 2, lessonTotal: 2),

        Unit(id: "wb-07-l1", belt: .white, orderIndex: 16,
             title: "Mount Escape", description: "Escape from the bottom of mount",
             tags: ["mount", "escapes"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(mountEscapeQuestions[0..<4]),
             coachIntro: "Two tools: upa (bridge and roll) and elbow-knee. Learn which to use when.",
             topicTitle: "Mount Escape",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-07-l2", belt: .white, orderIndex: 17,
             title: "Mount Escape", description: "Escape from the bottom of mount",
             tags: ["mount", "escapes"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(mountEscapeQuestions[4..<8]),
             topicTitle: "Mount Escape",
             lessonIndex: 2, lessonTotal: 2),

        // Character moment: Rex after mount
        Unit(id: "wb-cm-03", belt: .white, orderIndex: 18,
             title: "Rex", description: "",
             tags: [], isLocked: true, isCompleted: false,
             kind: .characterMoment,
             questions: [],
             characterMoment: CharacterMomentData(
                 character: .rex,
                 message: "Okay okay okay — mount escape is the one where I keep trying to muscle out and Marco keeps sighing at me. But you? You actually got it. BRO."
             )),

        // Mixed Review: Top Game
        Unit(id: "wb-mr-tg", belt: .white, orderIndex: 19,
             title: "Top Game Review", description: "Mixed questions from top game topics",
             tags: [], isLocked: true, isCompleted: false,
             kind: .mixedReview,
             questions: [
                 sideControlTopQuestions[0], sideControlTopQuestions[4],
                 sideControlEscapeQuestions[0], sideControlEscapeQuestions[4],
                 mountControlQuestions[0], mountControlQuestions[4],
                 mountEscapeQuestions[0], mountEscapeQuestions[4],
             ]),

        // Mini Exam: Top Game
        Unit(id: "wb-me-tg", belt: .white, orderIndex: 20,
             title: "Top Game Exam", description: "Prove your top game",
             tags: [], isLocked: true, isCompleted: false,
             kind: .miniExam,
             questions: [
                 sideControlTopQuestions[1], sideControlTopQuestions[5],
                 sideControlEscapeQuestions[1], sideControlEscapeQuestions[5],
                 mountControlQuestions[1], mountControlQuestions[5],
                 mountEscapeQuestions[1], mountEscapeQuestions[5],
             ]),

        // ── BACK & SUBMISSIONS ─────────────────────────────────────────────

        Unit(id: "wb-08-l1", belt: .white, orderIndex: 21,
             title: "Back Control", description: "Take and keep the back",
             tags: ["back control"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(backControlQuestions[0..<4]),
             coachIntro: "The back is the most dominant position. Hooks inside, seatbelt tight.",
             sectionTitle: "Back & Submissions",
             topicTitle: "Back Control",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-08-l2", belt: .white, orderIndex: 22,
             title: "Back Control", description: "Take and keep the back",
             tags: ["back control"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(backControlQuestions[4..<8]),
             topicTitle: "Back Control",
             lessonIndex: 2, lessonTotal: 2),

        Unit(id: "wb-09-l1", belt: .white, orderIndex: 23,
             title: "Submissions", description: "Basic submissions",
             tags: ["submissions"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(submissionQuestions[0..<4]),
             coachIntro: "Submissions only work from controlled positions. Position first, then submission.",
             topicTitle: "Submissions",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-09-l2", belt: .white, orderIndex: 24,
             title: "Submissions", description: "Basic submissions",
             tags: ["submissions"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(submissionQuestions[4..<8]),
             topicTitle: "Submissions",
             lessonIndex: 2, lessonTotal: 2),

        // Character moment: Old Chen after submissions
        Unit(id: "wb-cm-04", belt: .white, orderIndex: 25,
             title: "Old Chen", description: "",
             tags: [], isLocked: true, isCompleted: false,
             kind: .characterMoment,
             questions: [],
             characterMoment: CharacterMomentData(
                 character: .oldChen,
                 message: "The submission is the punctuation. The sentence is the position. Learn to write the sentence."
             )),

        Unit(id: "wb-10-l1", belt: .white, orderIndex: 26,
             title: "Takedowns", description: "Get the fight to the ground",
             tags: ["takedowns"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(takedownQuestions[0..<4]),
             coachIntro: "Two shots to learn first: double-leg and single-leg. Level change, penetration step, drive through.",
             topicTitle: "Takedowns",
             lessonIndex: 1, lessonTotal: 2),

        Unit(id: "wb-10-l2", belt: .white, orderIndex: 27,
             title: "Takedowns", description: "Get the fight to the ground",
             tags: ["takedowns"], isLocked: true, isCompleted: false,
             kind: .lesson,
             questions: Array(takedownQuestions[4..<8]),
             topicTitle: "Takedowns",
             lessonIndex: 2, lessonTotal: 2),

        // Mixed Review: Back & Submissions
        Unit(id: "wb-mr-bs", belt: .white, orderIndex: 28,
             title: "Back & Submissions Review", description: "",
             tags: [], isLocked: true, isCompleted: false,
             kind: .mixedReview,
             questions: [
                 backControlQuestions[0], backControlQuestions[4],
                 submissionQuestions[0], submissionQuestions[4],
                 takedownQuestions[0], takedownQuestions[4],
             ]),

        // Mini Exam: Back & Submissions
        Unit(id: "wb-me-bs", belt: .white, orderIndex: 29,
             title: "Back & Submissions Exam", description: "",
             tags: [], isLocked: true, isCompleted: false,
             kind: .miniExam,
             questions: [
                 backControlQuestions[1], backControlQuestions[5],
                 submissionQuestions[1], submissionQuestions[5],
                 takedownQuestions[1], takedownQuestions[5],
                 backControlQuestions[2], submissionQuestions[2],
             ]),

        // ── BELT TEST ─────────────────────────────────────────────────────

        Unit(id: "wb-bt1", belt: .white, orderIndex: 30,
             title: "Stripe 1 Test", description: "Prove your White Belt foundations",
             tags: [], isLocked: true, isCompleted: false,
             kind: .beltTest,
             questions: beltTestQuestions,
             sectionTitle: "Belt Test"),
    ]
}
```

### Step 3: Build — fix any compiler errors

If the `Unit` initializer complains about new optional fields, add default nil values in the struct definition (already done in Task 1 models).

### Step 4: Verify app builds

```bash
xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

### Step 5: Commit

```bash
git add BJJMind/Sources/BJJMind/Core/SampleData.swift
git commit -m "feat: split units into lessons, add CharacterMoment/MixedReview/MiniExam nodes"
```

---

## Task 4: Update AppState lock chain

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Core/AppState.swift`
- Modify: `BJJMind/Tests/BJJMindTests/AppStateTests.swift`

### Step 1: Write failing tests

In `AppStateTests.swift`, add:

```swift
func test_completeLesson_unlocksNextLesson() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let state = AppState(defaults: defaults)

    // Use real unit IDs from SampleData
    let units = QuestionProvider.whitebelt
    state.units = units

    let firstId = units[0].id
    state.completeUnit(id: firstId)
    XCTAssertFalse(state.units[1].isLocked)
}

func test_completeCharacterMoment_unlocksNextUnit() {
    let defaults = UserDefaults(suiteName: #function + "cm")!
    defaults.removePersistentDomain(forName: #function + "cm")
    let state = AppState(defaults: defaults)

    // Build a minimal sequence: lesson → characterMoment → lesson
    state.units = [
        Unit(id: "l1", belt: .white, orderIndex: 0, title: "Lesson 1", description: "",
             tags: [], isLocked: false, isCompleted: false, kind: .lesson, questions: []),
        Unit(id: "cm1", belt: .white, orderIndex: 1, title: "", description: "",
             tags: [], isLocked: true, isCompleted: false, kind: .characterMoment, questions: []),
        Unit(id: "l2", belt: .white, orderIndex: 2, title: "Lesson 2", description: "",
             tags: [], isLocked: true, isCompleted: false, kind: .lesson, questions: []),
    ]

    state.completeUnit(id: "l1")
    XCTAssertFalse(state.units[1].isLocked, "CharacterMoment should unlock")

    state.completeUnit(id: "cm1")
    XCTAssertFalse(state.units[2].isLocked, "Next lesson should unlock after moment")
}
```

### Step 2: Run — expect FAIL (completeUnit doesn't handle CharacterMoment yet — actually it should work already, just verify)

```bash
xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED|error:"
```

### Step 3: Update completeUnit in AppState if needed

The current `completeUnit` unlocks `nextIdx + 1` only if it's not a belt test. Update to:

```swift
func completeUnit(id: String) {
    guard let idx = units.firstIndex(where: { $0.id == id }) else { return }
    units[idx].isCompleted = true

    // Unlock next unit in sequence (works for all kinds)
    let nextIdx = idx + 1
    if nextIdx < units.count, !units[nextIdx].isBeltTest {
        units[nextIdx].isLocked = false
    }

    // Unlock belt test when all non-test units are done
    let allNonTestDone = units.filter { !$0.isBeltTest }.allSatisfy { $0.isCompleted }
    if allNonTestDone, let beltTestIdx = units.firstIndex(where: { $0.isBeltTest }) {
        units[beltTestIdx].isLocked = false
    }

    persistUnits()

    // Sync to Supabase (fire-and-forget)
    let unit = units[idx]
    if let userId = remoteUserId {
        Task {
            try? await SupabaseService.shared.upsertUnitProgress(
                userId: userId, unitId: unit.id,
                isCompleted: true, isLocked: false
            )
        }
    }
}
```

### Step 4: Run tests — all pass

```bash
xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED" | tail -5
```

### Step 5: Commit

```bash
git add BJJMind/Sources/BJJMind/Core/AppState.swift \
        BJJMind/Tests/BJJMindTests/AppStateTests.swift
git commit -m "test: verify CharacterMoment lock chain works in AppState"
```

---

## Task 5: CharacterMomentView (new file)

**Files:**
- Create: `BJJMind/Sources/BJJMind/Session/CharacterMomentView.swift`

No tests — this is pure UI. Verify visually in simulator.

### Step 1: Create the file

```swift
import SwiftUI

struct CharacterMomentView: View {
    let unit: Unit
    let onDismiss: () -> Void

    private var moment: CharacterMomentData? { unit.characterMoment }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Character image
                Image(moment?.character.imageName ?? "gi-ghost-neutral")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .padding(.bottom, 24)

                // Character name
                Text(moment?.character.displayName ?? "")
                    .font(.nunito(13, weight: .black))
                    .foregroundColor(Color(hex: "#a78bfa"))
                    .tracking(1)
                    .padding(.bottom, 12)

                // Message bubble
                Text(moment?.message ?? "")
                    .font(.nunito(17, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.borderMedium, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.nunito(17, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

private extension AppCharacter {
    var imageName: String {
        switch self {
        case .marco:    return "marco-talking"
        case .oldChen:  return "old-chen-talking"
        case .rex:      return "rex-excited"
        case .giGhost:  return "gi-ghost-happy"
        }
    }
}
```

> **Note on images:** Character images don't exist yet in the asset catalog. Use `Image(systemName: "person.circle.fill")` as placeholder until assets arrive. The image names match the Nano Banana brief naming convention.

### Step 2: Build to verify no compile errors

```bash
xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED"
```

### Step 3: Commit

```bash
git add BJJMind/Sources/BJJMind/Session/CharacterMomentView.swift
git commit -m "feat: add CharacterMomentView — character card between topics"
```

---

## Task 6: Update HomeView

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Home/HomeView.swift`

Changes:
1. `HomeSheet` — add `.characterMoment(Unit)` case
2. `BeltPathView` — data-driven section/topic headers (not hardcoded IDs)
3. `BeltNode` — new visual styles for `.characterMoment`, `.miniExam`, `.mixedReview`
4. `ActiveUnitBanner` — show lesson progress ("Lesson 2 of 3")

### Step 1: Update HomeSheet enum

```swift
private enum HomeSheet: Identifiable {
    case session(Unit)
    case beltTest(Unit)
    case characterMoment(Unit)

    var id: String {
        switch self {
        case .session(let u):          return "session-\(u.id)"
        case .beltTest(let u):         return "belttest-\(u.id)"
        case .characterMoment(let u):  return "moment-\(u.id)"
        }
    }
}
```

### Step 2: Update tap handler in HomeView body

```swift
BeltPathView(units: units) { unit in
    guard !unit.isLocked else { return }
    switch unit.kind {
    case .beltTest:
        activeSheet = .beltTest(unit)
    case .characterMoment:
        activeSheet = .characterMoment(unit)
    default:
        activeSheet = .session(unit)
    }
}
```

### Step 3: Update fullScreenCover to handle new case

```swift
.fullScreenCover(item: $activeSheet) { sheet in
    switch sheet {
    case .session(let unit):
        SessionView(unit: unit, isBeltTest: false, streak: appState.user.streakCurrent)
            .environmentObject(appState)
    case .beltTest(let unit):
        BeltTestGateView(unit: unit).environmentObject(appState)
    case .characterMoment(let unit):
        CharacterMomentView(unit: unit) {
            appState.completeUnit(id: unit.id)
            activeSheet = nil
        }
    }
}
```

### Step 4: Update BeltPathView — data-driven headers

Replace the hardcoded `sectionHeaders` dictionary with logic that compares consecutive units:

```swift
struct BeltPathView: View {
    let units: [Unit]
    let onTap: (Unit) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in

                // Section header: show when sectionTitle changes
                let prevSection = index > 0 ? units[index - 1].sectionTitle : nil
                if let section = unit.sectionTitle, section != prevSection {
                    SectionDividerView(title: section.uppercased())
                        .padding(.top, index == 0 ? 8 : 24)
                        .padding(.bottom, 4)
                }

                // Topic header: show when topicTitle changes (and is non-nil)
                let prevTopic = index > 0 ? units[index - 1].topicTitle : nil
                if let topic = unit.topicTitle, topic != prevTopic {
                    TopicHeaderView(title: topic)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                }

                HStack {
                    if index % 2 == 0 {
                        Spacer().frame(width: 60)
                        BeltNode(unit: unit) { onTap(unit) }
                        Spacer()
                    } else {
                        Spacer()
                        BeltNode(unit: unit) { onTap(unit) }
                        Spacer().frame(width: 60)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 20)
    }
}
```

### Step 5: Add TopicHeaderView

```swift
private struct TopicHeaderView: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.nunito(9, weight: .black))
            .foregroundColor(Color(hex: "#94a3b8"))
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
```

### Step 6: Update BeltNode — new visual styles

Add handling for CharacterMoment, MiniExam, MixedReview in the computed properties:

```swift
private var nodeBg: Color {
    if unit.isCompleted        { return Color(hex: "#dcfce7") }
    if unit.isLocked           { return Color(hex: "#f1f5f9") }
    if unit.isBeltTest         { return Color(hex: "#fef3c7") }
    if unit.isCharacterMoment  { return Color(hex: "#f3e8ff") }
    if unit.isMiniExam         { return Color(hex: "#fff7ed") }
    if unit.isMixedReview      { return Color(hex: "#eff6ff") }
    return .brand
}

private var nodeBorder: Color {
    if unit.isCompleted        { return Color(hex: "#22c55e") }
    if unit.isLocked           { return Color(hex: "#cbd5e1") }
    if unit.isBeltTest         { return Color(hex: "#f59e0b") }
    if unit.isCharacterMoment  { return Color(hex: "#c084fc") }
    if unit.isMiniExam         { return Color(hex: "#fb923c") }
    if unit.isMixedReview      { return Color(hex: "#60a5fa") }
    return Color(hex: "#a78bfa")
}

private var nodeEmoji: String {
    if unit.isCompleted        { return "" }
    if unit.isLocked           { return "🔒" }
    if unit.isBeltTest         { return "🛡️" }
    if unit.isCharacterMoment  { return "💬" }
    if unit.isMiniExam         { return "📋" }
    if unit.isMixedReview      { return "🔀" }
    return "🥋"
}
```

### Step 7: Update ActiveUnitBanner — show lesson progress

```swift
// In ActiveUnitBanner body, replace the question count VStack:
if let lessonIdx = unit.lessonIndex, let lessonTotal = unit.lessonTotal {
    VStack(alignment: .trailing, spacing: 2) {
        Text("LESSON \(lessonIdx)/\(lessonTotal)")
            .font(.nunito(13, weight: .black))
            .foregroundColor(.white)
        Text(L10n.Home.questions.uppercased())
            .font(.nunito(9, weight: .bold))
            .foregroundColor(.white.opacity(0.6))
            .tracking(1.5)
    }
} else {
    VStack(alignment: .trailing, spacing: 2) {
        Text("\(unit.questions.count)")
            .font(.nunito(22, weight: .black))
            .foregroundColor(.white)
        Text(L10n.Home.questions.uppercased())
            .font(.nunito(9, weight: .bold))
            .foregroundColor(.white.opacity(0.6))
            .tracking(1.5)
    }
}
```

### Step 8: Build and run in simulator — verify visually

```bash
xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED"
```

### Step 9: Commit

```bash
git add BJJMind/Sources/BJJMind/Home/HomeView.swift
git commit -m "feat: update HomeView for lesson structure — character moments, topic headers, lesson progress"
```

---

## Task 7: Run all tests + final verification

### Step 1: Run full test suite

```bash
xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "Test Case|PASSED|FAILED|error:" | tail -30
```

Expected: all tests pass.

### Step 2: Manual smoke test in simulator

1. Launch app → learning path shows section headers and lesson nodes
2. Tap Lesson 1 → session starts with 4 questions → completes → returns to map
3. Lesson 2 is now unlocked
4. Complete Lesson 2 → CharacterMoment node unlocks
5. Tap CharacterMoment → character card appears → "Got it" → marks complete → next topic unlocks
6. Mixed Review node → shows questions from multiple topics
7. Mini Exam node → session with 8 mixed questions
8. Active banner shows "LESSON 1/2"

### Step 3: Final commit

```bash
git add -A
git commit -m "feat: lesson structure refactor complete — short lessons, character moments, mixed review, mini exam"
```

---

## Out of scope (next sprint)

- More questions per topic (currently 4 per lesson — 10 is the goal)
- Real character art assets in the asset catalog (currently emoji placeholders)
- SampleData_ES.swift update (Spanish translation of new nodes)
- Supabase schema update for new unit kinds
- Lesson completion animation / XP celebration screen
- Onboarding redesign (separate plan)
