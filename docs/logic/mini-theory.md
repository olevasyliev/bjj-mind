# BJJ Mind — Mini-Theory System
> Status: PLANNED — not yet implemented.

---

## What It Is

Mini-theory is NOT a lesson. It's an introductory screen before a series of lessons. Takes 2–4 minutes, no testing, no scoring. Gives context only.

**Principle:** Mini-theory never explains what lessons should reveal themselves. It gives the principle — lessons give details through mistakes and correct answers. The user doesn't read technique — they discover it through practice. Theory only directs where to look.

---

## Three Placement Types

### Type 1 — Before first lesson of a new cycle (Cycle Intro)
Most complete. Opens when user starts a new position.

**4 screens, ~3 minutes:**

**Screen 1 — "What it is and why"**
One paragraph. Not history of technique — practical meaning of the position.
> *"Closed guard — your fortress from the bottom. While your partner is inside and can't stand — you control the game. The goal is not to hold the position forever, but to find the moment for a sweep or submission."*

**Screen 2 — 3D position** *(Phase 5 — placeholder for now)*
Interactive model from Grappling Base. User rotates, zooms, sees angles impossible to see in video. One button — "see the transition" — shows animation of entering the position.

**Screen 3 — Key principles**
Three points maximum. Not techniques — principles.
> 1. Control the head and posture
> 2. Without breaking posture, attack doesn't work
> 3. Hips are the main tool

**Screen 4 — What's coming in lessons**
Short preview. User understands what to expect.
> *"10 lessons. We'll start with positional control, end with submissions. At the end — the first boss."*

Coach closing line:
> *"You can read forever. Let's check what you understood."*

Button: **Start Lessons →**

---

### Type 2 — Before each lesson block within a cycle (Block Intro)
Shorter. 1–2 screens. Appears before each sub-topic block.

**1 screen, ~30–60 seconds:**
Text + one illustration or short animation (not interactive 3D).

> *"A sweep works not through strength — timing and angle. You're not pushing your partner — you're removing their base at the moment they shift weight."*

Coach line:
> *"Angle beats strength. Remember this before the next lessons."*

Button: **Lesson 4 →**

---

### Type 3 — Before boss fight or tournament (Tactical Brief)
Tactical. Doesn't explain position — prepares for specific opponent.

**1 screen, ~20–30 seconds. Text only. No 3D.**

Before boss — opponent scouting:
> *"The Wall doesn't attack first. He waits for your mistake. If you're passive — he's passive. Initiative must be yours. Create pressure — he'll start making errors."*

Before tournament — series approach:
> *"Five fights in a row. The first is easy — don't relax. The finalist uses everything you learned. If you get there — you're ready."*

Button: **Let's Fight →**

---

## Full Cycle Structure (Cycle 1 — Closed Guard)

```
CYCLE 1 — Closed Guard
│
├── [MINI-THEORY 1] What is closed guard (4 screens, ~3 min)       ← Type 1
│
├── Block 1: Positional Control
│   ├── [MINI-THEORY 2] Positional control (1 screen, ~45 sec)     ← Type 2
│   ├── Lesson 1
│   ├── Lesson 2
│   └── Lesson 3
│
├── Block 2: Sweeps
│   ├── [MINI-THEORY 3] Sweep mechanics (1 screen, ~45 sec)        ← Type 2
│   ├── Lesson 4
│   ├── Lesson 5
│   └── Lesson 6
│
├── Block 3: Submissions
│   ├── [MINI-THEORY 4] Submissions from CG (1 screen, ~45 sec)    ← Type 2
│   ├── Lesson 7
│   ├── Lesson 8
│   └── Lesson 9
│
├── Block 4: Mistakes
│   ├── [MINI-THEORY 5] Top mistakes (1 screen, ~30 sec)           ← Type 2
│   └── Lesson 10
│
├── [MINI-THEORY 6] Boss scouting (1 screen, ~20 sec)              ← Type 3
├── Boss: The Wall
├── Boss: The Posture Machine
│
└── ★ Stripe 1
```

---

## Data Model (planned)

```swift
enum MiniTheoryType: String, Codable {
    case cycleIntro   // Type 1 — full 4-screen intro
    case blockIntro   // Type 2 — single screen block intro
    case bossPrep     // Type 3 — tactical brief before boss/tournament
}

struct MiniTheoryScreen: Codable {
    let title: String?
    let body: String         // main text
    let coachLine: String?   // Marco's closing line
    let show3D: Bool         // Screen 2 only — Phase 5 placeholder
    let illustrationName: String?  // asset name
}

struct MiniTheoryData: Codable {
    let type: MiniTheoryType
    let screens: [MiniTheoryScreen]
    let buttonLabel: String  // "Start Lessons →", "Let's Fight →", etc.
}
```

`Unit` with `kind: .miniTheory` carries `miniTheoryData: MiniTheoryData?`.

---

## UI Behavior

- No hearts consumed
- No XP awarded
- No timer
- Progress: dots at bottom (one per screen)
- Swipe or tap Next to advance
- Can skip (tap X) — goes straight to next unit
- Completed = tapped through all screens OR skipped
- Revisitable from unit node (replays from screen 1)
