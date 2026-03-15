# Onboarding Redesign — Design Document

**Date:** 2026-03-13
**Status:** Approved, ready for implementation

---

## New Flow

```
Welcome (existing, no changes)
  ↓
SkillAssessment (NEW — replaces BeltSelect + ProblemSelect)
  ↓
ClubInfo (NEW)
  ↓
AhaMoment (existing, no changes)
  ↓
KatIntro (NEW)
  ↓
HomeView
```

**Removed:** `BeltSelectView`, `ProblemSelectView`
**Belt:** Always `.white` — hardcoded, not user-selected

---

## SkillAssessment

Two blocks with a separator intro screen between them.

### Block A — Experience (intro: "First, tell us a bit about your experience")

**Q1:** "How long have you been training BJJ?"
→ Less than 6 months / 6–18 months / 1–3 years / 3+ years `[MCQ4]`

**Q2:** "How often do you train?"
→ Once a week / 2–3 times a week / 4+ times a week / I just started `[MCQ4]`

### Block B — BJJ Situations (intro: "Now let's see what you've got")

3 BJJ questions. Difficulty adapts from Block A answers:
- < 6 months → difficulty 1 (easy)
- 6–18 months → difficulty 2 (medium)
- 1+ years → difficulty 2–3 (hard)

**Sample questions per difficulty:**

Easy:
- "Side control is a top position." [trueFalse, correct: True]
- "Your closed guard goal is to control and threaten attacks." [trueFalse, correct: True]

Medium:
- "Your opponent postures up in your closed guard. First move?" [MCQ2: Break posture / Open guard]
- "After passing guard, you should immediately go for a submission." [trueFalse, correct: False]

Hard:
- "You're mounted, opponent leaning forward. Best escape?" [MCQ4: Upa / Elbow-knee / Stand up / Turtle]
- "When framing in side control, bottom forearm goes where?" [MCQ4]

### Result screen
- `.beginner` (< 6 months OR 0–1 correct) → "We'll get you rolling in no time."
- `.intermediate` (6–18 months OR 2 correct) → "Solid foundation. Let's sharpen it."
- `.advanced` (1+ year AND 3 correct) → "Nice, you clearly know your way around the mat."

**UI rules:** No hearts, no timer, no feedback screen between questions. Progress bar 1/5 → 5/5.

---

## ClubInfo

**Header:** "Where do you train?"
**Subheader:** "We'll use this to connect you with your gym community."

**Fields (all optional):**
- Country → Picker (default: device locale)
- City → TextField
- Club name → TextField (future: autocomplete from club DB)

**"Detect my location" button** — triggers CoreLocation permission inline (not at app launch). Pre-fills Country + City on success.

**Skip link** at bottom. Continue always active.

---

## KatIntro

**Visual:** Dark background (contrast with rest of onboarding)

**Layout:**
- "Meet your rival" (small label, top)
- Kat avatar + name + "Blue Belt · 847 wins"
- Speech bubble with provocative line (varies by SkillLevel):
  - `.beginner` → "A fresh white belt. Don't worry, we all started somewhere."
  - `.intermediate` → "Another white belt. Let's see if you actually know anything... or if you just watch YouTube."
  - `.advanced` → "Okay, you've got some mat time. Let's find out if it shows."
- CTA: **"I'll prove it"** → completeOnboarding → HomeView
- Small note: "vs Kat matches unlock after your first lesson"

---

## AppState Changes

### New types
```swift
enum SkillLevel: Int, Codable { case beginner, intermediate, advanced }

struct ClubInfo: Codable {
    var country: String
    var city: String
    var clubName: String
}
```

### UserProfile additions
```swift
var skillLevel: SkillLevel  // default: .beginner
var clubInfo: ClubInfo?
```

### completeOnboarding signature change
```swift
// Before:
func completeOnboarding(belt: Belt, weakTags: [String])

// After:
func completeOnboarding(skillLevel: SkillLevel, clubInfo: ClubInfo?)
// Belt hardcoded to .white internally
```

---

## Files to Create
- `SkillAssessmentView.swift`
- `ClubInfoView.swift`
- `KatIntroView.swift`

## Files to Modify
- `OnboardingFlow.swift` — new Step enum, new state vars
- `AppState.swift` — new completeOnboarding signature
- `Models.swift` — SkillLevel enum, ClubInfo struct, UserProfile fields
- `AppStateTests.swift` — update tests for new completeOnboarding signature
- `Localizable.strings` (EN/ES/PT) — new strings

## Files to Delete
- `BeltSelectView.swift`
- `ProblemSelectView.swift`
