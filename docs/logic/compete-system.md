# BJJ Mind — Compete System Spec

---

## Overview

Three competitive modes, available from the Compete tab:

| Mode | Description | Frequency |
|------|-------------|-----------|
| **vs Kat** | Async challenge against LLM rival | Free: 1/day, Sub: unlimited |
| **Tournament Run** | 5-match single-elimination bracket | Free: 1/week, Sub: unlimited |
| **League** | Weekly XP-based leaderboard standings | All users, auto-enrolled |

---

## Mode 1: vs Kat (Async LLM Match)

### Concept
Kat is an LLM-powered rival. When you start a match:
1. You answer 5 questions (normal timer, hearts active)
2. Kat "answers" the same 5 questions (LLM call, simulated with personality-based accuracy)
3. Scores compared → winner decided
4. Result screen shows question-by-question breakdown

### Kat's Personality (LLM prompt parameters)
```
Kat is a sharp, competitive Blue Belt student. She's good at:
- Guard attacks (submissions from guard): 85% accuracy
- Escapes: 75% accuracy
- Weak at: Timing (55%), Transitions (50%)
She answers in 2–6 seconds (simulated).
Occasionally she makes a "muscle memory" mistake under pressure.
```

**Accuracy by tag:**
| Tag | Kat accuracy |
|-----|-------------|
| `submissions` | 85% |
| `escapes` | 78% |
| `grips` | 80% |
| `frames` | 65% |
| `timing` | 55% |
| `control` | 72% |
| `sweeps` | 70% |
| `base` | 68% |
| `transitions` | 50% |

Kat's "accuracy" is rolled per question at runtime. This creates natural variance — she won't always score the same.

### Match Flow
```
1. Intro screen: "vs Kat — Match" — shows Kat avatar, hearts you're bringing in
2. Question 1–5: normal gameplay (timer, hearts active)
3. After each answer: brief "Kat is thinking..." moment (0.5–1.5s fake delay)
4. After question 5: cut to result screen
5. Result: head-to-head score, question breakdown, XP
```

### Scoring
- 1 point per correct answer
- Max 5 points each
- Tie = replay question (one sudden-death question, no timer — first to answer wins)
- If tie on sudden death: Kat wins (she trains more than you)

### Result XP
| Outcome | XP |
|---------|----|
| Win 5–0 | +100 |
| Win 4–1 | +85 |
| Win 3–2 | +70 |
| Lose 2–3 | +25 |
| Lose 1–4 | +20 |
| Lose 0–5 | +15 |

Win also restores 1 heart (not full refill).

### Kat's Lines (for result screen)
**Win:** "Nice work. Don't get used to it." / "You're getting better. I'll be ready next time."
**Lose:** "Was that your best? Come back when you're ready." / "You froze on the timing questions. Train more."

---

## Mode 2: Tournament Run

### Bracket Structure
5 matches, single elimination:
```
Match 1 → Match 2 → Match 3 → Match 4 → FINAL
  NPC1      NPC2      NPC3      NPC4     NPC5
```

Each NPC has a name, rank, and signature style (shown on opponent card before match).

### NPC Roster (White Belt tournament)

| NPC | Rank | Style | Accuracy |
|-----|------|-------|---------|
| Jake | White Belt #4 | Brawler — good base, weak submissions | 50% avg |
| Mia | White Belt #3 | Technical — good frames, weak timing | 58% avg |
| Rex | White Belt #2 | Aggressive — good control, weak escapes | 65% avg |
| Sam | Blue Belt #5 | Veteran — balanced | 72% avg |
| Kat | Blue Belt #2 | Sharp — see vs Kat profile | 75% avg |

Opponents get harder each round. Final is always hardest.

### Resource Carry Mechanic
Hearts and XP earned **carry between matches**:
- Start tournament with current hearts
- Wrong answers in match 1 cost hearts that stay lost for match 2
- Win bonus: +1 heart after each match win (max 5)
- Lose a match → eliminated, carry back nothing from that match

This creates genuine tension: "I have 2 hearts left going into the final."

### Match Flow
Same as vs Kat: 5 questions per match, 8s timer.

### Tournament XP
| Finish | XP |
|--------|-----|
| Eliminated in match 1 | +30 |
| Eliminated in match 2 | +60 |
| Eliminated in match 3 | +90 |
| Runner up (match 4 loss) | +150 |
| Champion | +300 + Tournament Trophy title |

### Tournament Cooldown
- Free users: 1 tournament per week (resets Monday midnight)
- Subscription: unlimited
- Partial tournaments: if you quit, it counts as your weekly run

---

## Mode 3: League System

### Tiers
```
Bronze → Silver → Gold → Platinum → Diamond
```

All new users start in Bronze.

### Weekly Cycle
- Week runs Monday 00:00 → Sunday 23:59 (UTC)
- On Monday reset: top 20% of tier promoted, bottom 20% demoted
- XP earned during the week = league score

### Leaderboard
- Shows top 10 in your current tier
- Your position always visible (even if outside top 10)
- Mix of real users + seeded NPCs (to keep leaderboard active for new users)

### NPC seeding
When a user has fewer than 10 real opponents in their tier, NPCs fill the gaps:
- NPCs have names generated from a list (real-sounding BJJ student names)
- NPC weekly XP is rolled at Monday reset (Gaussian distribution around tier median)
- NPCs are indistinguishable from real players by design

### Tier XP medians (weekly)
| Tier | Median weekly XP | Promotion threshold |
|------|-----------------|---------------------|
| Bronze | 200 XP | 400+ XP |
| Silver | 400 XP | 700+ XP |
| Gold | 700 XP | 1100+ XP |
| Platinum | 1100 XP | 1600+ XP |
| Diamond | 1600+ XP | Top 20 stay |

### Demotion protection
- New users: no demotion from Bronze for first 2 weeks
- Subscription users: no demotion (streak freeze equivalent for league)
- If user doesn't train at all in a week: 1 tier demotion (except Bronze)

---

## Compete Tab — Screen States

| State | What user sees |
|-------|---------------|
| Default | vs Kat card, Tournament card, League standings |
| Kat on cooldown | Kat card greyed, timer "Available in Xh" |
| Tournament in progress | Bracket showing current position, Resume button |
| Tournament cooldown | Tournament card greyed, "Available Monday" |
| League top 3 | Small celebration banner at top of Compete tab |

---

## Anti-Cheat / Fairness Notes

- Timer is enforced server-side for vs Kat and Tournament (client timer is UI only)
- Answers submitted after timer window are rejected as wrong
- Suspicious speed (< 300ms answer time) flagged as potential tap spam
- League XP cap: 500 XP/day counted toward league (no grinding exploits)
