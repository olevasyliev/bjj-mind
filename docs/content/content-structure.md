# BJJ Mind — Content Structure Spec

---

## Overview

All educational content is stored as structured JSON in `docs/content/`:

- Questions: `docs/content/{belt}/questions.json`
- Coach moments: `docs/content/{belt}/coach-moments.json`
- Units metadata: `docs/content/{belt}/units.json`

---

## Question Schema

Each question is a JSON object. All formats share a common base, plus format-specific fields.

### Common fields (all formats)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Unique ID — `"q-{unit}-{seq}"` or `"q-s-{seq}"` for supplementary |
| `unit` | number | ✅ | Unit number (1–12 for white belt) |
| `stripe` | number | ✅ | Stripe number (1–4) |
| `belt` | string | ✅ | Belt color — `"white"` |
| `format` | string | ✅ | Question format (see formats below) |
| `tags` | string[] | ✅ | Concept tags — 1 to 3 from canonical set |
| `difficulty` | number | ✅ | 1 = beginner, 2 = intermediate, 3 = advanced |
| `situation` | string | — | Optional position context shown above the question |
| `question` | string | ✅ | The question text |
| `explanation` | string | ✅ | Shown after answer — the key learning |
| `scene_id` | string | ✅ | Links to 3D scene in `docs/3d/position-library.md` |

### Canonical tags

`frames` | `escapes` | `grips` | `timing` | `sweeps` | `submissions` | `control` | `base` | `transitions`

---

## Format-Specific Fields

### `mcq2` — 2-option multiple choice

```json
{
  "options": [
    { "id": "a", "text": "...", "correct": true },
    { "id": "b", "text": "...", "correct": false }
  ]
}
```

### `mcq4` — 4-option multiple choice

```json
{
  "options": [
    { "id": "a", "text": "...", "correct": true },
    { "id": "b", "text": "...", "correct": false },
    { "id": "c", "text": "...", "correct": false },
    { "id": "d", "text": "...", "correct": false }
  ]
}
```

### `truefalse` — true/false

```json
{
  "correct": false
}
```

No `options` field. App renders True / False buttons.

### `sequence` — drag-to-reorder

```json
{
  "steps": [
    "Step 1 (correct first)",
    "Step 2 (correct second)",
    "Step 3 (correct third)",
    "Step 4 (correct fourth)"
  ]
}
```

Steps stored in **correct order**. App shuffles them at runtime.

### `fill` — word-bank fill-in-the-blank

```json
{
  "question": "You insert your knee as a _____ between you and the opponent.",
  "word_bank": ["frame", "block", "hook", "shield"],
  "correct": "frame"
}
```

Use `_____` (5 underscores) as the blank marker in `question`.

### `spotmistake` — identify the error

Same structure as `mcq4` but always 3 options and one is the correct error diagnosis:

```json
{
  "options": [
    { "id": "a", "text": "The actual error — what Alex missed", "correct": true },
    { "id": "b", "text": "Wrong diagnosis 1", "correct": false },
    { "id": "c", "text": "Wrong diagnosis 2", "correct": false }
  ]
}
```

---

## Coach Moment Schema

```typescript
type CoachMoment = {
  id: string;              // "cm-01" through "cm-12"
  unit: number | null;     // null = shown across all units
  tags: string[];          // relevant concept tags
  character: "marco" | "old-chen";
  title: string;           // bold header line
  body: string;            // full explanation (2–4 sentences)
}
```

---

## Example Question (full)

```json
{
  "id": "q-1-01",
  "unit": 1,
  "stripe": 1,
  "belt": "white",
  "format": "mcq2",
  "tags": ["escapes", "base"],
  "difficulty": 1,
  "situation": "You're on your back. Opponent is pushing into you from the side.",
  "question": "To move your hips AWAY and create space, you use:",
  "options": [
    { "id": "a", "text": "Shrimp", "correct": true },
    { "id": "b", "text": "Upa (bridge)", "correct": false }
  ],
  "explanation": "The shrimp moves your hips away from pressure — your primary tool for creating space from the bottom. Upa reverses position by bridging under the opponent.",
  "scene_id": "bottom-pressure-01"
}
```

---

## Scene ID Reference

Scene IDs reference entries in `docs/3d/position-library.md`.

| Scene ID | Description |
|----------|-------------|
| `bottom-pressure-01` | On back, opponent pushing from side |
| `side-ctrl-bottom-01` | In side control from bottom |
| `side-ctrl-top-01` | In side control from top |
| `mount-bottom-01` | Mounted on by opponent |
| `mount-top-01` | You are mounted on opponent |
| `back-ctrl-top-01` | You have opponent's back |
| `guard-top-01` | You are in opponent's closed guard |
| `guard-bottom-01` | You are attacking from closed guard |
| `standing-01` | Standing / self-defense situation |
| `side-headlock-bottom-01` | Opponent has side headlock on you |
| `standing-guillotine-01` | Standing guillotine situation |
| `standing-rear-01` | Opponent behind you, rear attack |

---

## File Naming Convention

```
docs/content/
  white-belt/
    questions.json        — all 90 questions, flat array
    coach-moments.json    — 12 coach moments
    units.json            — unit metadata (names, tags, coach moment mapping)
  blue-belt/
    questions.json        — (future)
    ...
```

---

## App Integration Notes

- **Session question selection:** Filter `questions.json` by `unit`, then apply priority scoring (see `progression-system.md`)
- **Tag mastery tracking:** Update `tag_mastery` table in Supabase after each answer using the `tags` array
- **Spaced repetition:** Track `question_id` in `answers` table, apply schedule from `progression-system.md`
- **Scene loading:** Use `scene_id` to load the matching 3D scene before showing the question
- **Format routing:** Use `format` to determine which screen component to render
