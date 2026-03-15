# BJJ Mind — User Flow
**Last updated: 2026-03-15**

> Actual implemented flows. Sections marked [PLANNED] are specced but not yet built.

---

## First Launch — Onboarding

```
App Open
  └── Welcome Screen
        ├── "Get Started" → Belt Select
        └── "I have account" → [PLANNED: Login]

Belt Select → Skill Assessment (2 questions: experience + situational)
  └── → Struggles (multi-select: what's hard for you)
        └── → Club Info (country/city/club — optional, can skip)
              └── → Aha Moment (pitch + Gi Ghost)
                    └── → Kat Intro (Kat's speech bubble, belt-personalized message)
                          └── → completeOnboarding() → Home Screen
```

**What's saved after onboarding:**
- `belt` (white/blue/purple/brown/black)
- `skillLevel` (beginner/intermediate/advanced)
- `struggles[]`
- `clubInfo` (optional)
- Supabase user profile created

---

## Home Screen

- 31 nodes displayed as vertical path map
- Node types: lesson (📚) / character moment (💬) / mixed review (🔀) / mini exam (📋) / belt test (🥋)
- Completed nodes: filled circle
- Active node: pulsing, tappable
- Locked nodes: greyed out

---

## Session Flow

```
Tap active node on Home
  └── SessionView loads
        └── .task: fetchQuestionsForSession(for: unit)
              ├── Has topic + userId → fetch from Supabase (adaptive)
              └── Offline / no topic → local SampleData questions
                    ↓
              Show ProgressView spinner while loading
                    ↓
              SessionEngineView initializes with [Question]

Session Loop:
  Question shown
    ├── User answers → correct: feedback(1.5s) → next question
    │                  wrong: -1 heart → feedback(2.5s) → next question
    └── hearts == 0 → GameOverView → recordQuestionAnswers() → dismiss

All questions done → SummaryView
  └── Shows: accuracy, hearts left, XP earned, streak
        └── "Continue" → recordQuestionAnswers() → completeUnit() → Home
```

**After session:** `upsertQuestionStats` called fire-and-forget for each answered question via `increment_question_stats` RPC.

---

## Question Formats (implemented)

| Format | Description |
|--------|-------------|
| `mcq2` | 2-option multiple choice |
| `mcq4` | 4-option multiple choice |
| `trueFalse` | True / False |
| `fillBlank` | Fill in blank from word bank |

---

## Adaptive Question Selection

On session start, `AdaptiveQuestionSelector.select()` orders questions:
1. **Never seen** (`times_seen == 0`) — first
2. **Weak** (`times_wrong >= 2`) — second
3. **Rest** — last

Within each group: difficulty ascending. 8 questions returned per session.

---

## Belt Test Flow

```
All lesson nodes completed → Belt Test node becomes active
  └── Tap → BeltTestGateView (rules: no hints, 80% threshold, hearts carry over)
        └── "Start Test" → Session (belt test mode)
              ├── Correct: show answer only (no coach note)
              └── Wrong: show correct answer (no explanation)
                    ↓
              All 16 questions answered (or hearts = 0)
                    ↓
              accuracy >= 80% → BeltTestPassView → belt.advance() saved to Supabase
              accuracy < 80%  → BeltTestFailView → 24h cooldown → can retry
              hearts = 0      → BeltTestFailView (fail reason: hearts)
```

---

## Character Moment Flow

```
Character moment node becomes active
  └── Tap → CharacterMomentView
        └── Character image + quote + "Got it" button → marks unit complete → Home
```

No questions. No hearts. No XP. Just narrative.

---

## [PLANNED] vs Kat Match

```
Compete Tab → vs Kat
  └── Kat Intro → 5 questions (8s timer)
        └── Kat "plays" same questions via Claude API
              └── Score comparison → Win/Lose screen → XP
```

---

## [PLANNED] Streak Flow

```
Session completed
  └── Check: first session today?
        ├── Yes → streak_days + 1, save to Supabase
        └── No  → streak unchanged

Next app open (no session yesterday)
  └── streak_days = 0 (streak freeze auto-activates if available)
```

---

## [PLANNED] Subscription / Paywall

```
Free user completes White Belt Stripe 1
  └── Taps locked Stripe 2 node → Paywall screen
        ├── Subscribe → all content unlocked
        ├── Promo code → full access, no expiry
        └── Not now → Home
```
