# BJJ Mind — Session Logic Spec

---

## Session State Machine

```
IDLE → LOADING → ACTIVE → COMPLETE → SUMMARY → IDLE
                    ↓
               OUT_OF_HEARTS
                    ↓
               INTERRUPTED (user quits)
```

### State definitions

| State | Description |
|-------|-------------|
| `IDLE` | No session running. Home screen. |
| `LOADING` | Questions being selected and shuffled. Max 500ms. |
| `ACTIVE` | Session in progress. Question visible, timer running. |
| `COMPLETE` | All questions answered. Calculating results. |
| `SUMMARY` | Summary screen shown. XP animated. |
| `OUT_OF_HEARTS` | Hearts = 0. Session paused, not ended. |
| `INTERRUPTED` | User quit mid-session. Progress discarded. |

---

## Question Screen Lifecycle

```
Question loads
    → timer starts (8s default, 5s belt test)
    → user taps answer OR timer expires
        → if tapped: record answer, record time_ms
        → if expired: record wrong, time_ms = timer_limit
    → show feedback (correct / wrong) for 1.5s
    → load next question OR end session
```

### Timer behaviour
- Timer is a circular SVG ring draining clockwise
- Color: amber (#f59e0b) at full, transitions to red below 3s
- On expiry: auto-submit as wrong, brief red flash on screen
- No pause button (by design — real BJJ has no pause)

---

## Feedback Screen Timing

| Event | Duration |
|-------|----------|
| Correct answer feedback | 1.5s auto-advance OR tap to skip |
| Wrong answer feedback | 2.5s auto-advance OR tap to skip |
| Coach moment interrupt | Tap to dismiss (no auto) |
| Session summary | Stays until user taps Continue |

**Coach moments** trigger at:
- After question 3 of 10 (mid-session check-in)
- After a wrong answer streak of 3+ (encouragement)
- First time a new tag is introduced

---

## Question Format Routing

Each question has a `format` field. The session router loads the correct screen:

| Format | Screen | Timer | Notes |
|--------|--------|-------|-------|
| `mcq2` | micro-round | 8s | 2 options, most common |
| `mcq4` | round-4choice | 6s | 4 options, harder |
| `truefalse` | round-truefalse | 5s | Fast fire |
| `sequence` | round-sequence | 15s | Drag to order, longer timer |
| `tapzone` | round-tap-zone | 10s | Tap body part on diagram |
| `fill` | round-fill-rule | 12s | Word bank fill-in |
| `spotmistake` | round-spot-mistake | 8s | Identify error in position |

**Format mix per session (10 questions):**
- 4 × mcq2
- 2 × mcq4
- 1 × truefalse
- 1 × sequence OR fill
- 1 × tapzone OR spotmistake
- 1 × coach moment (not a question — inserted between questions 3 and 4)

**Belt test format mix (16 questions):**
- 10 × mcq2
- 4 × mcq4
- 2 × truefalse
- No sequence / fill / tapzone (cognitive load too high under strict timer)

---

## Session Result Calculation

At session end:

```typescript
type SessionResult = {
  total_questions: number       // e.g. 10
  correct: number               // e.g. 7
  accuracy: number              // 70%
  avg_time_ms: number           // e.g. 4200
  xp_earned: number             // see XP formula below
  hearts_remaining: number
  tags_affected: TagDelta[]     // which tags moved how much
  coach_insight: string | null  // from Claude API (post-session)
}

type TagDelta = {
  tag: string
  old_mastery: number
  new_mastery: number
  delta: number   // positive = improved, negative = regressed
}
```

**XP formula:**
```
base = correct * 10
first_try_bonus = first_try_correct * 5  (only for first_try_correct answers)
speed_bonus = answers_under_3s * 5
session_bonus = (accuracy == 100%) ? 50 : 20
streak_bonus = min(streak_days, 7) * 10
total_xp = base + first_try_bonus + speed_bonus + session_bonus + streak_bonus
```

---

## Mid-Session State Persistence

If app is backgrounded or killed mid-session:
- Current question index saved to local storage
- Timer state NOT saved (resets on return — by design)
- On app return: session resumes from current question with fresh timer
- If app killed and cold-started: session discarded, user returned to home

**Why discard on cold start:** BJJ training doesn't pause. A session that stale is meaningless.

---

## Out of Hearts Handling

When hearts reach 0 during a session:

1. Current question is marked wrong
2. Session immediately enters `OUT_OF_HEARTS` state
3. Show "Out of Hearts" screen with:
   - Current progress so far (X/10 questions answered)
   - Time until next heart refills
   - Option: "Practice mode" (continue with no hearts/XP, just to finish learning)
   - Option: "Go home" (session data partially saved — no XP)
4. If user chooses Practice mode: continue session, no hearts consumed, no XP earned

**Partial session saves:**
- Tag mastery is updated even for incomplete sessions (wrong answers still count)
- XP is NOT awarded for incomplete sessions
- Streak is NOT extended for incomplete sessions (must complete min 5 questions)

---

## Belt Test Special Rules

1. **No hints** — no explanation shown after wrong answer during test (only correct answer revealed, no coach note)
2. **Strict timer** — 5s, no exceptions
3. **Heart depletion = test fail** — running out of hearts ends the test as a fail
4. **Tag scoring:**
   ```
   tag_pass = (correct_in_tag / questions_in_tag) >= 0.75
   test_pass = all required tags pass
   ```
5. **Fail result:** Shows which tags passed and which failed. User can:
   - Re-train only the failed tags (units unlock for practice)
   - No full retake until failed tags are re-practiced (min 1 session each)
6. **Pass result:** Stripe ceremony, XP bonus, next units unlock

---

## Session Question Bank Cache

Questions loaded locally at session start to avoid latency:
- Pre-fetch 15 questions (session needs 10, buffer for filtering)
- Questions tagged with current user belt + stripe + weakest tags
- Cache valid for 24h
- On cache miss: show loading spinner max 2s, then fallback to recent cached set

---

## Difficulty Ramp Within Session

Questions within a session are ordered:
1. Start with difficulty 1 (warm-up, familiar tag)
2. Questions 4–7: difficulty 2 (main challenge)
3. Questions 8–9: difficulty 2–3 (push)
4. Question 10: difficulty 1–2 (finish on a win where possible)

This creates the feel of a training session — warm up, work hard, cool down.
