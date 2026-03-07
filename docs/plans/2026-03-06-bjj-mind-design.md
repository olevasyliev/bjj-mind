# BJJ Mind — Product Design

## Section 1: Concept

**Working title:** BJJ Mind

**One-liner:** A mobile decision-making trainer for BJJ — train your brain between sessions, not watch videos.

**Platform:** iOS/Android (solo + AI development)

**Target persona:** Alex, white belt, 4 months in. Mind is chaos. Gets dominated in sparring. Video courses don't stick.

**Core mechanic:**
3D position scene (GrappleMap engine) → timer → A/B/C choice → feedback + rule → XP

**Visual engine:** GrappleMap (public domain, 725 positions, 1485 transitions, Babylon.js). Characters styled for the product (gi, colors, camera angle).

**Habit loop:** Duolingo model — XP per session, streak as XP bonus (not punishment for missing). More practice = faster progress, but can't grind a belt in a weekend.

**v1.0 success (by priority):**
1. Mechanics work — people come back
2. Retention — 7-day return rate
3. First paying users

**Monetization:** Freemium (not implemented in v1.0, but designed for it).

**Full path:** White → Blue → Purple → Brown → Black belt. v1.0 launches with white belt only, but the system is designed for the full journey.

---

## Section 2: Progression and Content Structure

**Level architecture:**
```
Belt (5) → Stripe (4) → Unit (2-3) → Session (5-10 min)
```

**White Belt — Survival:**
- Stripe 1: Bottom Positions (Side Control, Mount, Back)
- Stripe 2: Frames & Escapes
- Stripe 3: Guard Recovery
- Stripe 4: Finishing → Belt Test

**Blue Belt — Control:**
- Stripe 1: Passing Guards
- Stripe 2: Submissions (basic chains)
- Stripe 3: Guard Play
- Stripe 4: Tournament Run → Belt Test

**Purple Belt — Systems:** attack chains, counters, guard game
**Brown Belt — Mastery:** details, counter-attacks, systematic thinking
**Black Belt — Open Game:** master content, open challenges

**8 session formats:**

| # | Format | Description |
|---|--------|-------------|
| A | Reaction Drill | Choose a response to opponent's action |
| B | Sequence Drill | Chain of 3-5 correct decisions |
| C | Spot the Mistake | Find the error in someone else's decision |
| D | Risk vs Reward | Safe or risky move — see consequences |
| E | Pressure Timer | 5 cards in 15 seconds, automation |
| F | Review | Spaced repetition on mistakes |
| G | Coach Challenge | All tasks built around one principle |
| H | Warm-up Scan | 3 questions to open the session |

**Typical session:**
`Warm-up Scan → Reaction Drill → Sequence or Risk/Reward → Summary Card`

White belt = mostly A + H. Formats B, C, D, E added as belts progress. G and F introduced from blue belt.

---

## Section 3: Exams, Competition, and Rating

**Two types of final events:**

**Belt Test** — closes each stripe
- 12-20 situations, 4-6 sec timer, minimal hints
- Pass/fail by mastery tags (Frames / Escapes / Grip / Timing), not total score
- Failed a tag → train that tag specifically, don't retake everything
- Reward: stripe on belt + next unit unlocked

**Tournament Run** — weekly, closes each belt
- 5 matches in a row, resources (stamina, health) carry between matches
- Each match = 6-10 decisions
- Between matches: choose "recover" (lose tempo) or "press" (risk)
- Result: league placement + badge + XP boost

**Full Match (competition mode)** — 2-3 minutes of game time
- Your turn → opponent's turn → your turn — turn-based reaction
- Starts from neutral position
- Ends by submission or time (control points)
- Kat adapts — makes mistakes at white belt, not at blue

**Asynchronous PvP** (from blue belt)
- Play through a fixed "seed" — set of situations
- Another player of same belt plays the same seed
- Comparison by time + decision quality
- No live play — simple technically, fair, no ping issues

**Leagues:**
```
Bronze → Silver → Gold → Platinum → Black Belt League
```
- Weekly cycle, promotion/demotion by Tournament XP
- Leaderboard only within your belt — no toxic comparison with advanced players
- Personal Best always visible — competing with yourself is the priority

---

## Section 3b: White Belt — Easy Entry

**Core principle: every session ends with a feeling of victory.**

**Days 1-3 — Tutorial Arc:**
- Format A only (Reaction Drill), 4-6 cards
- Soft timer — 6-8 seconds (light pressure, not stress)
- Only 2 answer options (A/B), not three
- Correct answer always explained in one line + visual
- First session designed so player makes max 1 mistake — aha-moment without humiliation

**Days 4-14 — Confidence Building:**
- Timer gradually tightens to 5-6 seconds
- Third answer option introduced
- Warm-up Scan added before session
- First Sequence Drill — only 2 steps

**Difficulty principle:**
Player should be wrong ~25-30% of the time — enough to learn, not enough to get frustrated. Algorithm auto-adjusts to this corridor.

**Not on white belt:**
- Pressure Timer (E) — too stressful
- Asynchronous PvP — too early
- Coach Challenge (G) — terminology not yet familiar

---

## Section 4: Retention, Notifications, and Rewards

**XP loop:**
- Base XP per session
- Streak bonus: +20% XP for 3 days in a row, +50% for 7 days
- Streak Freeze — rare item (reward, not purchase)
- No penalty for missing — just lose the bonus

**3 progress rings (Today Card):**
```
Mastery        — how well you're solving tasks
Consistency    — regularity over last 7 days
Tournament Readiness — readiness for weekly Run
```
Give sense of growth even without tournaments or streaks.

**Notifications — contextual only, never "come play":**

| Type | Text |
|------|------|
| Streak save | "You're one day from a 7-day streak. 3 minutes and you're done." |
| Coach insight | "You gave up your arm 4 times in Side Control. Today — 2 min on Frames." |
| Tournament | "Your weekly run is ready. 5 minutes. New league badge." |
| Milestone | "One session + mini-test away from your next stripe." |
| Comeback | "Let's get back on track: 2-minute recovery session." |

**Rewards:**
- Streak Freeze — protect your streak (rare, prize only)
- Second Chance — one mistake doesn't break the run
- Coach Token — one smart hint in a session
- Titles — "Calm Under Pressure", "Frame Builder", "Escape Artist"
- Gi Cosmetics — belt color, patches, gi color on your character

---

## Section 5: Personalization and AI Layer

**Without AI — already works:**
- Review pack auto-built from your mistakes (spaced repetition)
- Timer and difficulty auto-adjust to 25-30% error corridor
- "Weakness of the week" — most-missed tag shown on home screen
- Coach Challenge takes your weak tag and builds the whole session around it

**With LLM (template-based only, no hallucination risk):**
- Coach Notes — personal insight after session: "You react fast under pressure but lose focus in Sequences. Work on planning."
- Explanations adapt to belt level — white belt gets "don't push the chest", brown belt gets "you're creating lever on the shoulder joint"
- Drill variations generated from GrappleMap position templates — infinite content without manual card authoring

**Gi Ghost — your character:**
Grows with you through the belts:
- White belt — plain gi, no patches
- Blue belt — color appears, first patch for Tournament win
- Purple belt+ — gi customization, facial expressions, effects on correct answers

Gi Ghost = emotional attachment to progress. Not cosmetics for cosmetics' sake — visual embodiment of your journey.

---

## Section 6: Characters and Narrative

**The gym: "The Garage"** — neighborhood academy, worn mats, motivational posters on the walls, everyone knows each other.

**Characters:**

**Marco** — senior training partner, blue/purple belt
Coach clips, advice, occasional light ribbing.
_"Listen, I did the same thing for the first six months. Then I stopped. You'll figure it out."_
Appears: daily card (15 sec) + after Belt Test

**Old Chen** — white belt, 67 years old, started after retiring
Tips on hygiene, etiquette, gym philosophy. Never in a hurry.
_"Cut your nails. It's respect, not a rule."_
Appears: between units (45 sec)

**Kat** — rival at your level, always one step ahead
Appears in competition mode as the main weekly opponent. Silent, technically clean.
Creates a narrative: you spend all of white belt chasing her.

**Rex** — big, good-natured guy, white belt same as you
Appears in tutorial, makes the same mistakes you do. Learning together.
_"I picked A too. We both got put in an Armbar. Let's try B?"_

**Character clip formats:**
- Daily card (Marco, 15 sec) — before session, skippable
- Between units (Old Chen, 45 sec) — reward for completing a block
- After Belt Test (Marco, emotional) — "you passed, I knew you would"
- In competition (Kat) — silent opponent with personality

**Tech for clips:** 2D animation via Lottie — lightweight, consistent style, works alongside 3D engine.

---

## Section 7: UI Components and Screens

**Main navigation:**
```
Home → Train → Compete → Progress → Profile
```

**Home:**
- Today Card (3 rings: Mastery / Consistency / Tournament Readiness)
- Streak + weekly XP
- "Start Session" button — large, primary CTA
- Daily card from Marco (15 sec, skippable)

**Train:**
- Belt Path — vertical unit track (Duolingo-style)
- Current unit highlighted, locked ones dimmed
- Mastery bar on each unit
- Exam Gate — visually distinct from regular units

**Compete:**
- Weekly Tournament Run (available once a week)
- Quick Match vs Kat (full match, 2-3 min)
- Async PvP — challenge from another player of same belt
- League Ladder — your position + N points to promotion

**Progress:**
- Belt + stripes visual
- Mastery by tags (Frames / Escapes / Grip / Timing) — radar chart
- Personal Best cards
- Match history

**Profile:**
- Gi Ghost with cosmetics
- Titles
- Gym stats ("you've played 47 matches against Kat")

**Key UI components:**
- Micro-round Card — 3D scene + timer + answer options
- Feedback Toast — one-line rule + visual arrow
- Summary Card — 2 insights after session + Review button
- Coach Clip Player — character animation player
- Tournament Entry Card + Run Results
- Rewards Drawer — tokens, cosmetics, titles

---

## Section 8: Technical Stack

**Visual engine:**
- GrappleMap (public domain) — position and transition data
- Babylon.js — already in GrappleMap, renders 3D
- Custom renderer on top — camera angle, gi style, colors, lighting
- Gi Ghost evolution: v1 colors/materials → v2 textures → v3 custom meshes

**Mobile app:**
- React Native — single codebase for iOS and Android
- Expo — fast start, OTA updates without App Store review
- Babylon.js runs via WebView inside RN for 3D scenes

**Backend (minimal for v1.0):**
- Supabase — auth, database, realtime for async PvP
- Edge Functions — match logic, XP, mastery calculations
- LLM for Coach Notes — Claude API on templates, no free generation

**Content pipeline:**
- GrappleMap data → parse positions by tags
- LLM generates explanations by template → you validate
- Character clips — 2D animation (Lottie) alongside 3D engine

---

## v1.0 Scope

What we build first:

1. White belt complete (4 stripes)
2. Formats A, H, F (Reaction, Warm-up, Review)
3. Marco + Old Chen (first 5 clips each)
4. Belt Test for stripe 1
5. No PvP, no Tournament — Train + Progress only
