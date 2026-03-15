# Onboarding Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace BeltSelect + ProblemSelect with SkillAssessment + ClubInfo + KatIntro screens, keeping belt hardcoded to `.white`.

**Architecture:** New `SkillAssessmentEngine` struct handles quiz logic (question selection + skill level computation) — pure, testable, no UI. Three new SwiftUI views wired into an updated `OnboardingFlow`. `completeOnboarding` signature changes to accept `skillLevel` + `clubInfo` instead of `belt` + `weakTags`.

**Tech Stack:** Swift 6.0, SwiftUI, iOS 16+, XCTest, UserDefaults persistence, L10n system via `LanguageManager`

---

## Task 1: Models — SkillLevel, ClubInfo, UserProfile

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Core/Models.swift`
- Test: `BJJMind/Tests/BJJMindTests/AppStateTests.swift`

### Step 1: Write failing tests

Add to `AppStateTests.swift` inside the existing `@MainActor final class AppStateTests`:

```swift
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
```

### Step 2: Run tests to verify they fail

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(error:|TEST SUCCEEDED|TEST FAILED)"
```
Expected: compile error — `SkillLevel`, `ClubInfo` not found.

### Step 3: Add to Models.swift

After the `UnitKind` enum, add:

```swift
// MARK: - SkillLevel

enum SkillLevel: Int, Codable {
    case beginner     = 0
    case intermediate = 1
    case advanced     = 2
}

// MARK: - ClubInfo

struct ClubInfo: Codable, Equatable {
    var country: String
    var city: String
    var clubName: String
}
```

In `UserProfile` struct, add two fields after `weakTags`:

```swift
var skillLevel: SkillLevel
var clubInfo: ClubInfo?
```

In `UserProfile.guest`, add:

```swift
skillLevel: .beginner,
clubInfo: nil,
```

### Step 4: Run tests to verify they pass

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(PASS|FAIL|TEST SUCCEEDED|TEST FAILED)"
```
Expected: TEST SUCCEEDED

### Step 5: Commit

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && git add Sources/BJJMind/Core/Models.swift Tests/BJJMindTests/AppStateTests.swift
git commit -m "feat: add SkillLevel enum and ClubInfo struct to Models"
```

---

## Task 2: AppState — update completeOnboarding

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Core/AppState.swift`
- Modify: `BJJMind/Tests/BJJMindTests/AppStateTests.swift`

### Step 1: Write failing test

Add to `AppStateTests.swift`:

```swift
func test_completeOnboarding_withSkillLevel_setsLevel() {
    sut.completeOnboarding(skillLevel: .advanced, clubInfo: nil)
    XCTAssertEqual(sut.user.skillLevel, .advanced)
}

func test_completeOnboarding_withClubInfo_savesClub() {
    let club = ClubInfo(country: "Brazil", city: "São Paulo", clubName: "Gracie Barra")
    sut.completeOnboarding(skillLevel: .beginner, clubInfo: club)
    XCTAssertEqual(sut.user.clubInfo?.clubName, "Gracie Barra")
}

func test_completeOnboarding_beltAlwaysWhite() {
    sut.completeOnboarding(skillLevel: .advanced, clubInfo: nil)
    XCTAssertEqual(sut.user.belt, .white)
}
```

Also update the existing tests that call the old signature — replace:
```swift
// OLD (delete these 3 tests):
func test_completeOnboarding_transitionsToMain()
func test_completeOnboarding_setsUserBelt()
func test_completeOnboarding_setsWeakTags()
```

With updated versions:
```swift
func test_completeOnboarding_transitionsToMain() {
    sut.completeOnboarding(skillLevel: .beginner, clubInfo: nil)
    XCTAssertEqual(sut.currentScreen, .main)
}

// test_completeOnboarding_setsUserBelt → REMOVED (belt always .white, tested above)

// test_completeOnboarding_setsWeakTags → REMOVED (weakTags no longer in onboarding)
```

Also update `test_userProfile_persistsAcrossInstances`:
```swift
func test_userProfile_persistsAcrossInstances() {
    let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    let state1 = AppState(defaults: defaults)
    state1.completeOnboarding(skillLevel: .intermediate, clubInfo: nil)
    state1.addXP(120)

    let state2 = AppState(defaults: defaults)
    XCTAssertEqual(state2.user.skillLevel, .intermediate)
    XCTAssertEqual(state2.user.xpTotal, 120)
}
```

### Step 2: Run tests — expect compile error

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep "error:"
```

### Step 3: Update AppState.swift

Replace `completeOnboarding(belt:weakTags:)`:

```swift
func completeOnboarding(skillLevel: SkillLevel, clubInfo: ClubInfo?) {
    user.belt = .white
    user.skillLevel = skillLevel
    user.clubInfo = clubInfo
    defaults.set(true, forKey: "onboardingComplete")
    persistUser()
    withAnimation(.easeInOut(duration: 0.4)) { currentScreen = .main }
}
```

Remove `weakTags` from `UserProfile` (it's no longer populated during onboarding).

**Note:** `weakTags` in `UserProfile` can stay as a field (future: populated from session results). Just stop setting it from onboarding.

### Step 4: Run tests

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(TEST SUCCEEDED|TEST FAILED)"
```
Expected: TEST SUCCEEDED

### Step 5: Commit

```bash
git add Sources/BJJMind/Core/AppState.swift Tests/BJJMindTests/AppStateTests.swift
git commit -m "feat: update completeOnboarding to use skillLevel + clubInfo"
```

---

## Task 3: SkillAssessmentEngine — pure logic, fully testable

**Files:**
- Create: `BJJMind/Sources/BJJMind/Onboarding/SkillAssessmentEngine.swift`
- Test: `BJJMind/Tests/BJJMindTests/SkillAssessmentTests.swift`

### Step 1: Create test file

`BJJMind/Tests/BJJMindTests/SkillAssessmentTests.swift`:

```swift
import XCTest
@testable import BJJMind

final class SkillAssessmentTests: XCTestCase {

    // MARK: - computeSkillLevel

    func test_beginner_shortTraining_noCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .lessThan6Months, frequency: .onceAWeek, correctCount: 0)
        XCTAssertEqual(level, .beginner)
    }

    func test_intermediate_midTraining_someCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .sixTo18Months, frequency: .twoThreeTimes, correctCount: 2)
        XCTAssertEqual(level, .intermediate)
    }

    func test_advanced_longTraining_allCorrect() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .oneToThreeYears, frequency: .fourPlusTimes, correctCount: 3)
        XCTAssertEqual(level, .advanced)
    }

    func test_beginner_evenWithHighFrequency_ifShortDuration() {
        let level = SkillAssessmentEngine.computeSkillLevel(
            duration: .lessThan6Months, frequency: .fourPlusTimes, correctCount: 3)
        // Short duration caps at intermediate max
        XCTAssertLessThanOrEqual(level.rawValue, SkillLevel.intermediate.rawValue)
    }

    // MARK: - questionDifficulty

    func test_questionDifficulty_beginnerGetsEasy() {
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .lessThan6Months), 1)
    }

    func test_questionDifficulty_midGets2() {
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .sixTo18Months), 2)
    }

    func test_questionDifficulty_advancedGets3() {
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .oneToThreeYears), 3)
        XCTAssertEqual(SkillAssessmentEngine.questionDifficulty(for: .threePlusYears), 3)
    }

    // MARK: - questions(forDifficulty:)

    func test_questionsReturnsExactly3() {
        for diff in [1, 2, 3] {
            let qs = SkillAssessmentEngine.questions(forDifficulty: diff)
            XCTAssertEqual(qs.count, 3, "difficulty \(diff) should return 3 questions")
        }
    }

    func test_questionsHaveNonEmptyPrompts() {
        let qs = SkillAssessmentEngine.questions(forDifficulty: 1)
        for q in qs { XCTAssertFalse(q.prompt.isEmpty) }
    }

    func test_correctAnswerIsAlwaysInOptions() {
        for diff in [1, 2, 3] {
            let qs = SkillAssessmentEngine.questions(forDifficulty: diff)
            for q in qs {
                XCTAssertTrue(q.options.contains(q.correctAnswer),
                    "correct '\(q.correctAnswer)' not in options \(q.options)")
            }
        }
    }
}
```

### Step 2: Run — expect compile error

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep "error:"
```

### Step 3: Create SkillAssessmentEngine.swift

```swift
import Foundation

// MARK: - Assessment Types

enum TrainingDuration: Int {
    case lessThan6Months = 0
    case sixTo18Months   = 1
    case oneToThreeYears = 2
    case threePlusYears  = 3
}

enum TrainingFrequency: Int {
    case justStarted    = 0
    case onceAWeek      = 1
    case twoThreeTimes  = 2
    case fourPlusTimes  = 3
}

struct AssessmentQuestion {
    let prompt: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - Engine

enum SkillAssessmentEngine {

    /// Maps training duration → question difficulty level (1, 2, or 3)
    static func questionDifficulty(for duration: TrainingDuration) -> Int {
        switch duration {
        case .lessThan6Months: return 1
        case .sixTo18Months:   return 2
        case .oneToThreeYears, .threePlusYears: return 3
        }
    }

    /// Computes overall skill level from experience + quiz performance.
    static func computeSkillLevel(
        duration: TrainingDuration,
        frequency: TrainingFrequency,
        correctCount: Int
    ) -> SkillLevel {
        let baseScore = duration.rawValue          // 0–3
        let freqBonus = frequency.rawValue >= 2 ? 1 : 0  // bonus for 2+ sessions/week
        let quizBonus = correctCount >= 3 ? 1 : (correctCount >= 2 ? 0 : -1)

        let total = baseScore + freqBonus + quizBonus
        switch total {
        case ..<2: return .beginner
        case 2...3: return .intermediate
        default:   return .advanced
        }
    }

    /// Returns exactly 3 BJJ questions for the given difficulty level.
    static func questions(forDifficulty difficulty: Int) -> [AssessmentQuestion] {
        switch difficulty {
        case 1:
            return [
                AssessmentQuestion(
                    prompt: "Side control is a top position.",
                    options: ["True", "False"],
                    correctAnswer: "True"
                ),
                AssessmentQuestion(
                    prompt: "In closed guard, your main goal is to control and threaten attacks.",
                    options: ["True", "False"],
                    correctAnswer: "True"
                ),
                AssessmentQuestion(
                    prompt: "After passing the guard, your immediate priority is:",
                    options: ["Go for a submission", "Establish top position control",
                              "Stand back up", "Call for a timeout"],
                    correctAnswer: "Establish top position control"
                ),
            ]
        case 2:
            return [
                AssessmentQuestion(
                    prompt: "Your opponent postures up in your closed guard. First move?",
                    options: ["Break their posture down", "Open guard immediately"],
                    correctAnswer: "Break their posture down"
                ),
                AssessmentQuestion(
                    prompt: "After passing the guard, you should immediately go for a submission.",
                    options: ["True", "False"],
                    correctAnswer: "False"
                ),
                AssessmentQuestion(
                    prompt: "Cross-face pressure in side control helps flatten your opponent.",
                    options: ["True", "False"],
                    correctAnswer: "True"
                ),
            ]
        default: // 3+
            return [
                AssessmentQuestion(
                    prompt: "You're mounted and your opponent is leaning forward. Best escape?",
                    options: ["Upa (bridge and roll)", "Elbow-knee escape",
                              "Stand up immediately", "Grab their collar"],
                    correctAnswer: "Upa (bridge and roll)"
                ),
                AssessmentQuestion(
                    prompt: "When framing in side control, your bottom forearm goes:",
                    options: ["Across their throat", "On their hip",
                              "Under their arm", "Against their knee"],
                    correctAnswer: "On their hip"
                ),
                AssessmentQuestion(
                    prompt: "To set up a triangle from closed guard, you must first:",
                    options: ["Open your guard wide",
                              "Break posture and isolate one arm outside your legs",
                              "Grab their ankle", "Stand up"],
                    correctAnswer: "Break posture and isolate one arm outside your legs"
                ),
            ]
        }
    }
}
```

### Step 4: Run tests

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(TEST SUCCEEDED|TEST FAILED)"
```
Expected: TEST SUCCEEDED

### Step 5: Commit

```bash
git add Sources/BJJMind/Onboarding/SkillAssessmentEngine.swift Tests/BJJMindTests/SkillAssessmentTests.swift
git commit -m "feat: SkillAssessmentEngine with adaptive difficulty and skill level computation"
```

---

## Task 4: L10n — new strings for all 3 screens

**Files:**
- Modify: `BJJMind/Sources/BJJMind/en.lproj/Localizable.strings`
- Modify: `BJJMind/Sources/BJJMind/es.lproj/Localizable.strings`
- Modify: `BJJMind/Sources/BJJMind/Core/L10n.swift`

### Step 1: Add to en.lproj/Localizable.strings

```
// MARK: - Skill Assessment
"assessment.block_a.intro_title" = "Tell us about your experience";
"assessment.block_a.intro_subtitle" = "A couple of quick questions before we dive in.";
"assessment.block_b.intro_title" = "Now let's see what you've got";
"assessment.block_b.intro_subtitle" = "A few real BJJ situations.";
"assessment.q1.prompt" = "How long have you been training BJJ?";
"assessment.q1.opt1" = "Less than 6 months";
"assessment.q1.opt2" = "6–18 months";
"assessment.q1.opt3" = "1–3 years";
"assessment.q1.opt4" = "3+ years";
"assessment.q2.prompt" = "How often do you train?";
"assessment.q2.opt1" = "Just starting out";
"assessment.q2.opt2" = "Once a week";
"assessment.q2.opt3" = "2–3 times a week";
"assessment.q2.opt4" = "4+ times a week";
"assessment.result.beginner" = "We'll get you rolling in no time.";
"assessment.result.intermediate" = "Solid foundation. Let's sharpen it.";
"assessment.result.advanced" = "Nice, you clearly know your way around the mat.";
"assessment.result.cta" = "Continue";
"assessment.progress" = "%d of 5";

// MARK: - Club Info
"club_info.title" = "Where do you train?";
"club_info.subtitle" = "We'll use this to connect you with your gym community.";
"club_info.country_placeholder" = "Country";
"club_info.city_placeholder" = "City";
"club_info.club_placeholder" = "Club name";
"club_info.detect_location" = "Detect my location";
"club_info.skip" = "Skip for now";
"club_info.continue" = "Continue";

// MARK: - Kat Intro
"kat_intro.eyebrow" = "Meet your rival";
"kat_intro.name" = "Kat";
"kat_intro.record" = "Blue Belt · 847 wins";
"kat_intro.message.beginner" = "A fresh white belt. Don't worry, we all started somewhere.";
"kat_intro.message.intermediate" = "Another white belt. Let's see if you actually know anything... or if you just watch YouTube.";
"kat_intro.message.advanced" = "Okay, you've got some mat time. Let's find out if it shows.";
"kat_intro.cta" = "I'll prove it";
"kat_intro.unlock_note" = "vs Kat matches unlock after your first lesson";
```

### Step 2: Add to es.lproj/Localizable.strings

```
// MARK: - Skill Assessment
"assessment.block_a.intro_title" = "Cuéntanos sobre tu experiencia";
"assessment.block_a.intro_subtitle" = "Un par de preguntas rápidas antes de empezar.";
"assessment.block_b.intro_title" = "Ahora veamos qué sabes";
"assessment.block_b.intro_subtitle" = "Algunas situaciones reales de BJJ.";
"assessment.q1.prompt" = "¿Cuánto tiempo llevas entrenando BJJ?";
"assessment.q1.opt1" = "Menos de 6 meses";
"assessment.q1.opt2" = "6–18 meses";
"assessment.q1.opt3" = "1–3 años";
"assessment.q1.opt4" = "3+ años";
"assessment.q2.prompt" = "¿Con qué frecuencia entrenas?";
"assessment.q2.opt1" = "Estoy empezando";
"assessment.q2.opt2" = "Una vez a la semana";
"assessment.q2.opt3" = "2–3 veces por semana";
"assessment.q2.opt4" = "4+ veces por semana";
"assessment.result.beginner" = "Te pondremos en marcha en poco tiempo.";
"assessment.result.intermediate" = "Buena base. Vamos a mejorarla.";
"assessment.result.advanced" = "Genial, claramente conoces bien el tapiz.";
"assessment.result.cta" = "Continuar";
"assessment.progress" = "%d de 5";

// MARK: - Club Info
"club_info.title" = "¿Dónde entrenas?";
"club_info.subtitle" = "Lo usaremos para conectarte con tu comunidad del gimnasio.";
"club_info.country_placeholder" = "País";
"club_info.city_placeholder" = "Ciudad";
"club_info.club_placeholder" = "Nombre del club";
"club_info.detect_location" = "Detectar mi ubicación";
"club_info.skip" = "Saltar por ahora";
"club_info.continue" = "Continuar";

// MARK: - Kat Intro
"kat_intro.eyebrow" = "Conoce a tu rival";
"kat_intro.name" = "Kat";
"kat_intro.record" = "Cinturón azul · 847 victorias";
"kat_intro.message.beginner" = "Un cinturón blanco nuevo. No te preocupes, todos empezamos en algún lugar.";
"kat_intro.message.intermediate" = "Otro cinturón blanco. A ver si realmente sabes algo... o solo ves YouTube.";
"kat_intro.message.advanced" = "Okay, tienes algo de tiempo en el tapiz. Veamos si se nota.";
"kat_intro.cta" = "Lo voy a demostrar";
"kat_intro.unlock_note" = "Los combates vs Kat se desbloquean tras tu primera lección";
```

### Step 3: Add to L10n.swift

Remove `enum BeltSelect` and `enum ProblemSelect`. Add:

```swift
// MARK: Skill Assessment
enum Assessment {
    static var blockATitle: String    { l("assessment.block_a.intro_title") }
    static var blockASubtitle: String { l("assessment.block_a.intro_subtitle") }
    static var blockBTitle: String    { l("assessment.block_b.intro_title") }
    static var blockBSubtitle: String { l("assessment.block_b.intro_subtitle") }
    static var resultCta: String      { l("assessment.result.cta") }
    static func progress(_ n: Int) -> String { lf("assessment.progress", n) }
    static func result(for level: SkillLevel) -> String {
        switch level {
        case .beginner:     return l("assessment.result.beginner")
        case .intermediate: return l("assessment.result.intermediate")
        case .advanced:     return l("assessment.result.advanced")
        }
    }
    // Q1 options (maps to TrainingDuration)
    static var q1Prompt: String  { l("assessment.q1.prompt") }
    static var q1Options: [String] { [
        l("assessment.q1.opt1"), l("assessment.q1.opt2"),
        l("assessment.q1.opt3"), l("assessment.q1.opt4")
    ]}
    // Q2 options (maps to TrainingFrequency)
    static var q2Prompt: String  { l("assessment.q2.prompt") }
    static var q2Options: [String] { [
        l("assessment.q2.opt1"), l("assessment.q2.opt2"),
        l("assessment.q2.opt3"), l("assessment.q2.opt4")
    ]}
}

// MARK: Club Info
enum ClubInfoL10n {
    static var title: String              { l("club_info.title") }
    static var subtitle: String           { l("club_info.subtitle") }
    static var countryPlaceholder: String { l("club_info.country_placeholder") }
    static var cityPlaceholder: String    { l("club_info.city_placeholder") }
    static var clubPlaceholder: String    { l("club_info.club_placeholder") }
    static var detectLocation: String     { l("club_info.detect_location") }
    static var skip: String               { l("club_info.skip") }
    static var continueCta: String        { l("club_info.continue") }
}

// MARK: Kat Intro
enum KatIntro {
    static var eyebrow: String    { l("kat_intro.eyebrow") }
    static var name: String       { l("kat_intro.name") }
    static var record: String     { l("kat_intro.record") }
    static var cta: String        { l("kat_intro.cta") }
    static var unlockNote: String { l("kat_intro.unlock_note") }
    static func message(for level: SkillLevel) -> String {
        switch level {
        case .beginner:     return l("kat_intro.message.beginner")
        case .intermediate: return l("kat_intro.message.intermediate")
        case .advanced:     return l("kat_intro.message.advanced")
        }
    }
}
```

### Step 4: Build to verify no compile errors

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```
Expected: BUILD SUCCEEDED

### Step 5: Commit

```bash
git add Sources/BJJMind/en.lproj/Localizable.strings Sources/BJJMind/es.lproj/Localizable.strings Sources/BJJMind/Core/L10n.swift
git commit -m "feat: add L10n strings and enums for SkillAssessment, ClubInfo, KatIntro"
```

---

## Task 5: SkillAssessmentView

**Files:**
- Create: `BJJMind/Sources/BJJMind/Onboarding/SkillAssessmentView.swift`

No separate UI tests — logic is in `SkillAssessmentEngine` (already tested). View is presentational.

### Step 1: Create SkillAssessmentView.swift

```swift
import SwiftUI

struct SkillAssessmentView: View {
    let onComplete: (SkillLevel) -> Void

    // Internal state machine
    private enum Phase {
        case blockAIntro
        case blockA(questionIndex: Int)   // 0=Q1, 1=Q2
        case blockBIntro
        case blockB(questionIndex: Int)   // 0-2 BJJ questions
        case result(SkillLevel)
    }

    @State private var phase: Phase = .blockAIntro
    @State private var duration: TrainingDuration = .lessThan6Months
    @State private var frequency: TrainingFrequency = .justStarted
    @State private var bjjCorrect: Int = 0
    @State private var bjjQuestions: [AssessmentQuestion] = []

    // Progress: 1-5 across all phases
    private var progressStep: Int {
        switch phase {
        case .blockAIntro:         return 0
        case .blockA(let i):       return i + 1       // 1, 2
        case .blockBIntro:         return 2
        case .blockB(let i):       return i + 3       // 3, 4, 5
        case .result:              return 5
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if case .result = phase { } else {
                HStack(spacing: 16) {
                    AppProgressBar(progress: Double(progressStep) / 5.0)
                    CloseButton(action: {})
                }
                .padding(.horizontal, 24)
                .padding(.top, 52)
            }

            switch phase {
            case .blockAIntro:
                AssessmentIntroBlock(
                    title: L10n.Assessment.blockATitle,
                    subtitle: L10n.Assessment.blockASubtitle,
                    onContinue: { phase = .blockA(questionIndex: 0) }
                )

            case .blockA(let idx):
                if idx == 0 {
                    ExperienceQuestionView(
                        prompt: L10n.Assessment.q1Prompt,
                        options: L10n.Assessment.q1Options,
                        onSelect: { selectedIdx in
                            duration = TrainingDuration(rawValue: selectedIdx) ?? .lessThan6Months
                            phase = .blockA(questionIndex: 1)
                        }
                    )
                } else {
                    ExperienceQuestionView(
                        prompt: L10n.Assessment.q2Prompt,
                        options: L10n.Assessment.q2Options,
                        onSelect: { selectedIdx in
                            frequency = TrainingFrequency(rawValue: selectedIdx) ?? .justStarted
                            phase = .blockBIntro
                        }
                    )
                }

            case .blockBIntro:
                AssessmentIntroBlock(
                    title: L10n.Assessment.blockBTitle,
                    subtitle: L10n.Assessment.blockBSubtitle,
                    onContinue: {
                        let diff = SkillAssessmentEngine.questionDifficulty(for: duration)
                        bjjQuestions = SkillAssessmentEngine.questions(forDifficulty: diff)
                        phase = .blockB(questionIndex: 0)
                    }
                )

            case .blockB(let idx):
                let q = bjjQuestions[idx]
                BJJQuestionView(question: q) { isCorrect in
                    if isCorrect { bjjCorrect += 1 }
                    if idx < 2 {
                        phase = .blockB(questionIndex: idx + 1)
                    } else {
                        let level = SkillAssessmentEngine.computeSkillLevel(
                            duration: duration, frequency: frequency, correctCount: bjjCorrect)
                        phase = .result(level)
                    }
                }

            case .result(let level):
                AssessmentResultView(level: level) { onComplete(level) }
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: progressStep)
    }
}

// MARK: - Sub-views

private struct AssessmentIntroBlock: View {
    let title: String
    let subtitle: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Text(title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: "Let's go", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }
}

private struct ExperienceQuestionView: View {
    let prompt: String
    let options: [String]
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(prompt)
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { idx in
                    Button(action: { onSelect(idx) }) {
                        HStack {
                            Text(options[idx])
                                .font(.labelXL)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private struct BJJQuestionView: View {
    let question: AssessmentQuestion
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(question.prompt)
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    Button(action: { onAnswer(option == question.correctAnswer) }) {
                        HStack {
                            Text(option)
                                .font(.labelXL)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private struct AssessmentResultView: View {
    let level: SkillLevel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("🥋")
                .font(.system(size: 72))
                .padding(.bottom, 24)
            Text(L10n.Assessment.result(for: level))
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: L10n.Assessment.resultCta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }
}
```

### Step 2: Build to verify

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

### Step 3: Commit

```bash
git add Sources/BJJMind/Onboarding/SkillAssessmentView.swift
git commit -m "feat: SkillAssessmentView with adaptive 2-block quiz"
```

---

## Task 6: ClubInfoView

**Files:**
- Create: `BJJMind/Sources/BJJMind/Onboarding/ClubInfoView.swift`

```swift
import SwiftUI

struct ClubInfoView: View {
    let onContinue: (ClubInfo?) -> Void

    @State private var country: String = ""
    @State private var city: String = ""
    @State private var clubName: String = ""

    private var clubInfo: ClubInfo? {
        guard !country.isEmpty || !city.isEmpty || !clubName.isEmpty else { return nil }
        return ClubInfo(country: country, city: city, clubName: clubName)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                AppProgressBar(progress: 0.7)
                CloseButton(action: {})
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.ClubInfoL10n.title)
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                Text(L10n.ClubInfoL10n.subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                ClubTextField(placeholder: L10n.ClubInfoL10n.countryPlaceholder,
                              text: $country)
                ClubTextField(placeholder: L10n.ClubInfoL10n.cityPlaceholder,
                              text: $city)
                ClubTextField(placeholder: L10n.ClubInfoL10n.clubPlaceholder,
                              text: $clubName)

                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(L10n.ClubInfoL10n.detectLocation)
                            .font(.labelMd)
                    }
                    .foregroundColor(.brand)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: L10n.ClubInfoL10n.continueCta) {
                    onContinue(clubInfo)
                }
                Button(L10n.ClubInfoL10n.skip) { onContinue(nil) }
                    .font(.bodySm)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .background(Color.screenBg.ignoresSafeArea())
    }
}

private struct ClubTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.labelXL)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(Color.cardBg)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

### Build + commit

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
git add Sources/BJJMind/Onboarding/ClubInfoView.swift
git commit -m "feat: ClubInfoView with country/city/club fields"
```

---

## Task 7: KatIntroView

**Files:**
- Create: `BJJMind/Sources/BJJMind/Onboarding/KatIntroView.swift`

```swift
import SwiftUI

struct KatIntroView: View {
    let skillLevel: SkillLevel
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0f0f14").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Eyebrow
                Text(L10n.KatIntro.eyebrow)
                    .font(.nunito(12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .padding(.bottom, 20)

                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "#1e1e28"))
                        .frame(width: 100, height: 100)
                    Text("🥋")
                        .font(.system(size: 48))
                }
                .padding(.bottom, 16)

                // Name + record
                Text(L10n.KatIntro.name)
                    .font(.screenTitle)
                    .foregroundColor(.white)
                    .tracking(-0.5)
                Text(L10n.KatIntro.record)
                    .font(.bodySm)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 28)

                // Speech bubble
                Text("\"\(L10n.KatIntro.message(for: skillLevel))\"")
                    .font(.bodyMd)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#1e1e28"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)

                Spacer()

                // CTA
                VStack(spacing: 10) {
                    Button(action: onAccept) {
                        Text(L10n.KatIntro.cta)
                            .font(.labelXL)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Text(L10n.KatIntro.unlockNote)
                        .font(.bodySm)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}
```

### Build + commit

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
git add Sources/BJJMind/Onboarding/KatIntroView.swift
git commit -m "feat: KatIntroView with dark theme and adaptive Kat message"
```

---

## Task 8: Wire OnboardingFlow + delete old files

**Files:**
- Modify: `BJJMind/Sources/BJJMind/Onboarding/OnboardingFlow.swift`
- Delete: `BJJMind/Sources/BJJMind/Onboarding/BeltSelectView.swift`
- Delete: `BJJMind/Sources/BJJMind/Onboarding/ProblemSelectView.swift`

### Step 1: Replace OnboardingFlow.swift

```swift
import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Step = .welcome
    @State private var skillLevel: SkillLevel = .beginner
    @State private var clubInfo: ClubInfo? = nil

    enum Step {
        case welcome, skillAssessment, clubInfo, ahaMoment, katIntro
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeView { step = .skillAssessment }

            case .skillAssessment:
                SkillAssessmentView { level in
                    skillLevel = level
                    step = .clubInfo
                }

            case .clubInfo:
                ClubInfoView { info in
                    clubInfo = info
                    step = .ahaMoment
                }

            case .ahaMoment:
                AhaMomentView { step = .katIntro }

            case .katIntro:
                KatIntroView(skillLevel: skillLevel) {
                    appState.completeOnboarding(skillLevel: skillLevel, clubInfo: clubInfo)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}
```

### Step 2: Delete old files

```bash
rm /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind/Sources/BJJMind/Onboarding/BeltSelectView.swift
rm /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind/Sources/BJJMind/Onboarding/ProblemSelectView.swift
```

### Step 3: Build to verify

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild build -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

If there are errors about `L10n.BeltSelect` or `L10n.ProblemSelect`, remove those enum cases from `L10n.swift` as well.

### Step 4: Run all tests

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | grep -E "(TEST SUCCEEDED|TEST FAILED)"
```
Expected: TEST SUCCEEDED

### Step 5: Commit

```bash
git add Sources/BJJMind/Onboarding/OnboardingFlow.swift
git rm Sources/BJJMind/Onboarding/BeltSelectView.swift
git rm Sources/BJJMind/Onboarding/ProblemSelectView.swift
git commit -m "feat: wire new OnboardingFlow, remove BeltSelectView and ProblemSelectView"
```

---

## Final: Run full test suite + code review

```bash
cd /Users/aleksei/Desktop/kindergarden/bjj-prototype/BJJMind && xcodebuild test -scheme BJJMind -destination 'platform=iOS Simulator,id=8FEE0FF6-C162-4869-9D1C-F3CD153419F0' 2>&1 | tail -5
```
Expected: all tests pass.

Then request code review via `superpowers:requesting-code-review`.
