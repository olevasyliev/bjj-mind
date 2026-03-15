# BJJ Mind — XP & Progression System
> ⚠️ [PLANNED] — XP is displayed in app but not wired to stripe/belt progression. Streak shown but not persisted. See backlog.md for implementation priorities.

---

## XP Sources

| Action | XP | Notes |
|--------|----|-------|
| Correct answer (base) | +10 | Any format |
| Correct on first try | +15 | Instead of base +10 |
| Speed bonus (answer < 3s) | +5 | Stacks with above |
| Session complete | +20 | Flat bonus |
| Perfect session (all correct) | +50 | Replaces session complete bonus |
| Daily streak bonus | +10 × day | Cap at day 7 (+70 max) |
| Belt test passed | +200 | One-time per stripe |
| vs Kat match win | +80 | |
| vs Kat match loss | +20 | Consolation |
| Tournament win (final) | +300 | |
| Tournament runner-up | +150 | |
| Tournament eliminated early | +30–80 | Based on round reached |

**XP is never removed.** Wrong answers, lost hearts, streak breaks — none of these deduct XP.

---

## Belt & Stripe Progression

```
WHITE BELT
├── Stripe 0 (start)       0 XP
├── Stripe 1               160 XP   ← free tier ceiling
├── Stripe 2               360 XP   ← subscription required
├── Stripe 3               600 XP
├── Stripe 4               880 XP
└── Blue Belt Test         880 XP + all tags ≥ 70% mastery

BLUE BELT
├── Stripe 1               1200 XP
├── Stripe 2               1600 XP
├── Stripe 3               2100 XP
├── Stripe 4               2700 XP
└── Purple Belt Test       2700 XP + all tags ≥ 75% mastery

PURPLE BELT
├── Stripe 1               3500 XP
...
```

**Important:** XP alone does not unlock a stripe. Both conditions must be met:
1. XP threshold reached
2. All required tags for that stripe at mastery threshold

---

## Tag Mastery System

### Tags (White Belt)
`frames` | `escapes` | `grips` | `timing` | `sweeps` | `submissions` | `control` | `base` | `transitions`

### Mastery Formula
```
mastery% = correct_last_20 / 20

Where correct_last_20 = correct answers in the last 20 attempts for that tag.
Minimum 5 attempts before mastery% is shown.
```

### Mastery Thresholds
| Level | % | Effect |
|-------|----|--------|
| Weak | 0–39% | Tag shown in red on Progress screen |
| Learning | 40–59% | Tag shown in yellow |
| Solid | 60–79% | Tag shown in green |
| Mastered | 80–100% | Tag shows ✅, counts toward belt test unlock |

### Stripe Tag Requirements

| Stripe | Required Tags at Mastered (≥80%) |
|--------|----------------------------------|
| Stripe 1 | `frames` + `base` |
| Stripe 2 | `escapes` + `grips` |
| Stripe 3 | `timing` + `submissions` + `control` |
| Stripe 4 | `sweeps` + `transitions` + all previous ≥ 60% |
| Blue Belt Test | All 9 tags ≥ 70% |

---

## Question Selection Algorithm

Sessions are not random. Questions are selected by weighted priority:

```
Priority score per question =
  base_weight
  + weakness_bonus     (if tag mastery < 60%: +3)
  + new_bonus          (if never seen: +5)
  + review_due_bonus   (if spaced repetition due: +4)
  - recent_penalty     (if seen in last 3 sessions: -3)
```

**Session composition (10 questions default):**
- 3 questions from weakest tag
- 3 questions from current unit focus
- 2 review questions (seen before, due for repetition)
- 1 new question from upcoming unit (preview)
- 1 wildcard (any tag, slightly harder difficulty)

**Belt test (16 questions):**
- 4 questions per required tag
- Shuffled order
- No repetition within the test

---

## Spaced Repetition Schedule

For each question, after answering:

| Result | Next appearance |
|--------|----------------|
| Correct (1st time) | After 2 sessions |
| Correct (2nd time) | After 5 sessions |
| Correct (3rd time) | After 10 sessions |
| Correct (4th+ time) | After 20 sessions (near-retired) |
| Wrong | Next session (high priority) |
| Wrong twice in a row | Current session (repeat at end) |

---

## Session Types

| Type | Questions | Timer | Hearts used | XP |
|------|-----------|-------|-------------|-----|
| Daily session | 10 | 8s | Yes | Full |
| Belt test | 16 | 5s | Yes | Bonus on pass |
| Practice mode | Unlimited | None | No | No XP |
| vs Kat match | 5 | 8s | Yes | Match XP |
| Tournament match | 5 | 8s | Yes (carried) | Tournament XP |
| Review session | 10 | None | No | Half XP |

---

## Hearts / Lives System

- Max hearts: **5**
- Lost: 1 heart per wrong answer
- Refill rate: **1 heart per 4 hours** (real time)
- Full refill at: midnight local time OR after winning a vs Kat match
- Subscription perk: instant refill once per day

**Hearts in belt test:**
- Hearts carry from your current count into the test
- If you run out mid-test, test ends (fail state)
- Remaining hearts at end of test are preserved

**Hearts in tournament:**
- Hearts pool carries between matches
- Losing a heart in match 2 means you have fewer in match 3
- Tournament win fully restores hearts

---

## Streak System

- Streak increments once per calendar day (midnight local time)
- Any completed session (min 5 questions) counts
- Streak freeze: available for subscription users (max 2 active at once)
- Streak freeze auto-activates on first missed day, then consumed

**Streak milestones (display only, no mechanical effect):**
3 days → 7 days → 14 days → 30 days → 60 days → 100 days → 365 days

---

## Free vs Subscription

| Feature | Free | Subscription |
|---------|------|-------------|
| White Belt Stripe 1 | ✅ Full access | ✅ |
| White Belt Stripe 2-4 | ❌ Locked | ✅ |
| Blue Belt+ | ❌ Locked | ✅ |
| Hearts refill rate | 4h per heart | 4h per heart + 1 instant/day |
| Streak freeze | ❌ | ✅ 2 active max |
| Practice mode | ❌ | ✅ Unlimited |
| vs Kat matches | 1/day | Unlimited |
| Tournament | 1/week | Unlimited |

**Promo codes:** Grant full subscription access, no expiry. For gym partners and friends.

---

## Level Display

The app displays progress as a path, not a number. But internally:

```
display_rank = belt_name + " · Stripe " + stripe_number
example: "White Belt · Stripe 2"

next_milestone = next_tag_to_master OR next_xp_threshold (whichever comes first)
```

Progress bar on home screen = XP toward next stripe threshold (not tag mastery).
Tag mastery shown separately on Progress tab.
