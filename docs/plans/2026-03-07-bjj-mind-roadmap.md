# BJJ Mind — Full Product Roadmap

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Duolingo-style BJJ decision-making trainer with gamified progression, AI coaching, and 3D position visualizations.

**Architecture:** React Native + Expo frontend, Supabase backend (auth + DB + realtime), Claude API for coach insights, Babylon.js for 3D BJJ scenes.

**Tech Stack:** React Native, Expo, Supabase, Claude API, Babylon.js, ElevenLabs (voice), Lottie (animations), i18next (EN/ES/PT)

---

## Phase 1: Design & UX — Screens (current)

**Goal:** All 13 screens polished, all states covered, ready for handoff.

### Task 1.1: Refine micro-round screen
**Files:** `figma-screens/micro-round.html`

- Replace stick figure SVG with cleaner position illustration (use labeled shapes + position name overlay)
- Add timer ring (SVG circle animation) instead of plain number
- Ensure A/B buttons are clearly tappable and styled consistently

**Done when:** Timer is a ring, position scene reads clearly, fits 390x844 without scroll.

---

### Task 1.2: Refine feedback screens (correct + wrong)
**Files:** `figma-screens/feedback-correct.html`, `figma-screens/feedback-wrong.html`

- Add Gi Ghost reaction face placeholder (happy / sad) — use emoji or image block with "CHARACTER ART HERE" label
- Ensure coach explanation text is readable and punchy
- Make the rule card feel like a learning moment, not a punishment

**Done when:** Both screens have mascot placeholder, rule explanation, and clear CTA.

---

### Task 1.3: Onboarding Screen 3 — Aha Moment
**Files:** `figma-screens/aha-moment.html` (new)

- Shown after problem-select, before first gameplay card
- Purpose: bridge from "I selected my problem" to "here's how we solve it"
- Content: show one example situation → two choices → reveal correct answer
- Should feel exciting, not informational
- Add to `index.html` and `backlog.md`

**Done when:** User understands the gameplay loop from this screen alone.

---

### Task 1.4: New gameplay format screens (10 screens)

**New files (all in `figma-screens/`):**
- `round-4choice.html` — 4-option MCQ, tighter timer
- `round-sequence.html` — tap to reorder steps
- `round-tap-zone.html` — tap body part on the BJJ diagram
- `round-truefalse.html` — swipe left/right or tap yes/no
- `round-spot-mistake.html` — identify the error in the position
- `round-fill-rule.html` — word bank fill-in-the-blank
- `coach-moment.html` — mid-session character coaching card (Marco / Old Chen)
- `match-vs-kat.html` — turn-based match UI vs Kat character
- `belt-test-active.html` — belt test in progress (strict 5s timer, no hints)
- `tournament-match.html` — tournament bracket + current match view

**Done when:** All 10 screens visible in index.html.

---

### Task 1.5: Clickable prototype navigation

Add `<a href>` links between screens so the full user journey is walkable:
- Welcome → Belt Select → Problem Select → Aha Moment → Micro Round → Feedback → Summary
- Home → Train → Belt Test Gate → Belt Test Active → Summary
- Home → Compete → vs Kat Match → Summary
- Home → Compete → Tournament → Tournament Match → Summary

**Done when:** Full flow can be clicked through in a browser without dead ends.

---

### Task 1.6: Missing states
For each main screen, add a "empty state" or "first time" variant if needed:

- `train.html` — locked state (belt not unlocked yet) visual
- `compete.html` — "no tournament running" empty state
- `home.html` — Day 1 state (no streak, no progress yet)

**Done when:** Each screen has its edge case handled.

---

## Phase 2: Characters & Visual Identity

**Goal:** 5 characters with 5 expressions each, ready for Nano Banana production.

### Task 2.1: Finalize character briefs
**File:** `docs/characters/character-prompts.md` (exists, verify completeness)

Characters needed:
- **Gi Ghost** — mascot, 5 expressions: neutral, happy, sad, surprised, celebrating
- **Marco** — AI coach, calm mentor energy, 3 expressions: neutral, encouraging, serious
- **Old Chen** — wise sensei, 3 expressions: neutral, proud, disappointed
- **Kat** — rival, competitive girl, 3 expressions: neutral, smirking, defeated
- **Rex** — rival, big guy, 3 expressions: neutral, aggressive, frustrated

Each brief must include: body type, color palette, gi color, personality notes, style ref.

**Done when:** Nano Banana can start production without asking questions.

---

### Task 2.2: Animation spec per character
**File:** `docs/characters/animation-spec.md` (new)

For each character, define:
- Idle animation (loop, ~2s)
- Reaction animations: correct answer, wrong answer, win, lose
- Entrance animation (bounce in)
- Format: description + timing + keyframes in plain English (for animator)

**Done when:** Animator has a clear brief for each animation state.

---

### Task 2.3: Gi Ghost in-app integration plan
**File:** `docs/characters/integration-notes.md` (new)

- Specify which screens show Gi Ghost and which expression
- Specify trigger: on load? on answer? on streak milestone?
- Lottie vs PNG sprite sheet decision

**Done when:** Dev knows exactly when/where each expression appears.

---

## Phase 3: Business Logic & User Flow

**Goal:** Complete spec document that a developer can implement without guessing.

### Task 3.1: User flow diagram
**File:** `docs/logic/user-flow.md` (new)

Map every possible user path:
- First launch → onboarding → first session → summary
- Return user → home → session → belt test → stripe earned
- Return user → home → compete → tournament → win/lose
- Streak broken → recovery flow

Use text-based flowchart (Mermaid syntax).

---

### Task 3.2: XP & progression system
**File:** `docs/logic/progression-system.md` (new)

Define precisely:

```
XP Sources:
- Correct answer: +10 XP (base)
- Correct on first try: +15 XP
- Speed bonus (<3s): +5 XP
- Session complete: +20 XP
- Perfect session (10/10): +50 XP
- Daily streak bonus: +10 XP × streak_day (cap at ×7)

Belt progression:
- White Belt: 0–680 XP, 4 stripes
  - Stripe 1: 0–160 XP, tags: Frames + Grip Control
  - Stripe 2: 161–320 XP, tags: Escapes + Timing
  - Stripe 3: 321–500 XP, tags: Decisions + Submissions
  - Stripe 4: 501–680 XP, tags: all tags ≥ 70%
- Blue Belt: 681–2000 XP, 4 stripes
  ...

Tag mastery formula:
- mastery% = correct_answers / total_attempts (last 20 attempts per tag)
- Tag unlocked at 60%, mastered at 80%
```

---

### Task 3.3: Session logic spec
**File:** `docs/logic/session-logic.md` (new)

Define:
- How questions are selected (spaced repetition? weighted random by weakness?)
- Session length (10 questions default, belt test = 16)
- Timer rules: normal = 8s, belt test = 5s
- Hearts / lives system or unlimited?
- What happens if user quits mid-session?

---

### Task 3.4: Compete system spec
**File:** `docs/logic/compete-system.md` (new)

Define:
- League tiers: Bronze → Silver → Gold → Platinum → Diamond
- Promotion/demotion rules (weekly reset)
- vs Kat: async challenge, 5 questions, higher score wins
- Tournament Run: 5 sequential matches, resources carry, bracket logic
- Leaderboard: real players or NPCs? (MVP: NPCs with names)

---

### Task 3.5: Titles & achievements spec
**File:** `docs/logic/achievements.md` (new)

List all 20+ titles with unlock conditions:
```
Frame Builder — answer 10 Frame questions correctly in one session
Escape Artist — escape from bottom 5 times correctly
Quick Reactor — answer 20 questions under 3 seconds
Tournament Vet — complete 3 tournament runs
...
```

---

## Phase 4: Educational Content

**Goal:** Full question bank for White Belt (MVP), structured for future belts.

### Task 4.1: Content structure spec
**File:** `docs/content/content-structure.md` (new)

Define question format:
```json
{
  "id": "wb-frames-001",
  "belt": "white",
  "tag": "frames",
  "position": "side-control-bottom",
  "situation": "Opponent has side control. Their weight is on your chest. You have one arm free.",
  "options": [
    { "id": "a", "text": "Push their hip with your free hand", "correct": true },
    { "id": "b", "text": "Try to sit up immediately", "correct": false }
  ],
  "explanation": "Hip frame creates space and stops their weight transfer. Sitting up without a frame gets you flattened.",
  "coach_note": "Think: create space FIRST, then move.",
  "difficulty": 1,
  "scene_id": "side-control-bottom-001"
}
```

---

### Task 4.2: White Belt question bank — Frames (25 questions)
**File:** `docs/content/white-belt/frames.json` (new)

25 situations testing frame recognition and application.
Positions: guard, side control bottom, mount bottom, back defense.

---

### Task 4.3: White Belt question bank — Escapes (25 questions)
**File:** `docs/content/white-belt/escapes.json` (new)

25 situations: upa, elbow-knee escape, shrimping, guard recovery.

---

### Task 4.4: White Belt question bank — Grip Control (20 questions)
**File:** `docs/content/white-belt/grip-control.json` (new)

---

### Task 4.5: White Belt question bank — Timing (20 questions)
**File:** `docs/content/white-belt/timing.json` (new)

---

### Task 4.6: White Belt question bank — Decisions (20 questions)
**File:** `docs/content/white-belt/decisions.json` (new)

High-level position decisions: when to guard pull, when to shoot, when to disengage.

---

## Phase 5: 3D Scene Prototypes

**Goal:** Replace red/blue silhouettes with readable 3D BJJ position visualizations.

### Task 5.1: GrappleMap data integration research
**File:** `docs/3d/grapplemap-research.md` (new)

- Evaluate GrappleMap dataset (open source BJJ positions)
- Can we extract position coordinates and render in Babylon.js?
- Alternative: custom rigged models from Mixamo + manual positioning

**Decision needed:** GrappleMap data vs custom models vs illustrated scenes.

---

### Task 5.2: Position library spec (White Belt scenes)
**File:** `docs/3d/position-library.md` (new)

For each question, define the 3D scene:
- Camera angle (always top-down? slight angle?)
- Player A position + Player B position
- Key body part to highlight (the frame, the grip, etc.)
- Gi colors: Player A = blue gi, Player B = white gi

Minimum: 20 unique scenes for White Belt MVP.

---

### Task 5.3: Babylon.js prototype
**File:** `figma-screens/scene-prototype.html` (new)

Build one working 3D scene in Babylon.js:
- Two humanoid meshes in side control position
- Top-down camera
- Highlight target body part with glow
- Fits in the 390×300 scene area of micro-round screen

**Done when:** One scene renders correctly in browser, looks better than current SVG.

---

### Task 5.4: Animation sequences (per position)
For White Belt MVP, 20 scenes × 2 animations each:
- **Correct path animation:** shows the right movement (0.5s)
- **Wrong path animation:** shows what goes wrong (0.5s)

Format: Babylon.js keyframe animations or pre-baked GLTF.

---

## Phase 6: App Development

**Goal:** Working iOS/Android app with core gameplay loop, progression, and auth.

### Task 6.1: Project setup
- `npx create-expo-app bjj-mind --template blank-typescript`
- Configure: ESLint, Prettier, path aliases, Husky pre-commit
- Add: React Navigation, Zustand (state), React Query (server state)
- Add: i18next + EN/ES/PT locale files scaffolded

---

### Task 6.2: Supabase schema
Tables:
```sql
users (id, email, display_name, created_at)
user_progress (user_id, belt, stripe, xp_total, streak_days, last_session_at)
sessions (id, user_id, started_at, completed_at, score, xp_earned)
answers (id, session_id, question_id, chosen_option, correct, time_ms)
tag_mastery (user_id, tag, correct_count, total_count, updated_at)
achievements (user_id, achievement_id, earned_at)
league_standings (user_id, league_tier, weekly_xp, week_start)
```

RLS policies: users can only read/write their own data.

---

### Task 6.3: Core gameplay — TDD
For each feature, write failing test first:

- Question selector (weighted by weakness)
- Timer logic (countdown, auto-submit on 0)
- XP calculator (base + bonuses)
- Session state machine (idle → active → complete)
- Belt/stripe unlock checker
- Streak tracker (timezone-aware)

Test framework: Jest + Testing Library for React Native.

---

### Task 6.4: Screen implementation order
Implement in this order (each screen = one PR):
1. Onboarding (welcome → belt-select → problem-select → aha-moment)
2. Home screen
3. Micro-round + feedback screens (core loop)
4. Session summary
5. Train (belt path)
6. Progress
7. Profile
8. Compete
9. Belt test

---

### Task 6.5: Localization
- All user-facing strings in `i18n/en.json`, `i18n/es.json`, `i18n/pt.json`
- No hardcoded text anywhere in components
- Question bank: separate JSON per language per belt
- Date/number formats: use `Intl` API

---

### Task 6.6: Claude API integration (Marco coach)
- Post-session: send user's wrong answers → Claude returns personalized insight
- Daily tip: Claude generates tip based on user's weakest tag
- Prompt templates in `src/ai/prompts.ts`
- Rate limit: max 2 Claude calls per session

---

## Phase 7: Polish

**Goal:** App feels alive. Sounds, haptics, transitions.

### Task 7.1: Lottie animations
- Gi Ghost reactions (correct/wrong/celebrate) — Lottie JSON from animator
- XP counter increment animation
- Belt/stripe unlock celebration
- Streak fire animation

### Task 7.2: Sound design
- Correct answer: soft chime
- Wrong answer: low thud
- XP earned: coin sound
- Belt test pass: triumphant short fanfare
- Session complete: completion sound
- Use `expo-av` or `react-native-sound`

### Task 7.3: Haptic feedback
- Correct answer: light impact
- Wrong answer: medium impact + warning
- Belt unlock: heavy success pattern
- Button presses: selection feedback
- Use `expo-haptics`

### Task 7.4: Micro-interactions
- Tab bar icons: scale on press
- Cards: spring animation on mount
- Progress bars: animated fill on screen load
- Streak number: count-up animation

---

## Milestones Summary

| # | Milestone | Deliverable | Priority |
|---|-----------|-------------|----------|
| 1 | Design complete | All 13 screens + aha-moment polished in Figma | NOW |
| 2 | Characters ready | Nano Banana briefs for all 5 characters | NOW |
| 3 | Logic spec done | 5 spec docs covering all game systems | NEXT |
| 4 | Content done | 110 questions for White Belt | NEXT |
| 5 | 3D prototype | 20 scenes in Babylon.js | AFTER |
| 6 | MVP app | Working iOS app, core loop, EN only | AFTER |
| 7 | Localization | ES + PT added | AFTER |
| 8 | Polish | Sounds, haptics, animations | LAST |

---

## Decisions (locked)

1. **Hearts system** — Yes, limited lives like Duolingo. Lose a heart per wrong answer, refill over time or via practice.
2. **vs Kat / multiplayer** — Real async match against LLM opponent. User submits answers, LLM "plays" the same session with slight randomness, results compared. Feels like a real rival.
3. **3D approach** — GrappleMap data. Parse open-source position graph, render in Babylon.js. Custom rigging on top.
4. **Monetization** — Free tier: White Belt Stripe 1 only (enough to understand the loop and get hooked). Subscription unlocks Stripe 2+ and all belts. Promo codes for friends and gym partners (full access, no expiry). No ads ever.
5. **Platforms** — iOS native first (React Native). Android after MVP validated.
