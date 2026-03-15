# BJJ Mind — Project Context for Claude

## What This Is

BJJ Mind is a Duolingo-style iOS app for Brazilian Jiu-Jitsu. It trains decision-making and pattern recognition — not technique names, but **what to do from a given position**. Core differentiator: "Not BJJ trivia. BJJ thinking."

Target: White and Blue Belt practitioners (1–4 years), English/Spanish/Portuguese markets.

---

## Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift 6.0, SwiftUI, iOS 16+ |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| AI | Claude API (claude-sonnet-4-6) — vs Kat, Coach Marco |
| Payments | StoreKit 2 |
| 3D (Phase 5) | Babylon.js in WKWebView |
| Project setup | xcodegen |
| Tests | XCTest (TDD) |

iOS only. iPhone portrait (9:16). No React Native, no Expo.

---

## Architecture

- `AppState` — @MainActor, @EnvironmentObject, UserDefaults persistence
- `SessionEngine` — state machine: answering → showingFeedback → completed | gameOver
- `AdaptiveQuestionSelector` — pure function, sorts: unseen → weak (timesWrong≥2) → rest
- `LanguageManager` — singleton, runtime bundle switch, persists in UserDefaults("appLanguage")
- `L10n` enum — type-safe localized strings via LanguageManager.bundle
- `SupabaseService` — URLSession (no SPM), REST API, adaptive question fetching + stat tracking

**110 tests, all green** — v1.1.1 (build 4)

---

## Completed Versions

- ✅ **V0.1** — Onboarding + HomeView (belt path) + SessionFlow
- ✅ **V0.2** — Unit Progression (completeUnit, unlock chain) + Belt Test (gate, pass/fail, 24h retry)
- ✅ **V0.3-i18n** — EN/ES localization: L10n enum, Localizable.strings, SampleData_ES, LanguageManager
- ✅ **V0.3 Rich Learning Path** — 31 nodes, Coach Marco moments, fillBlank format, character moments
- ✅ **V0.4 Lesson Structure** — UnitKind enum (.lesson/.characterMoment/.mixedReview/.miniExam/.beltTest), 31-node catalog
- ✅ **Supabase integration** — user profile + unit progress + session results sync, URLSession-based
- ✅ **Onboarding redesign** — characters on all screens, Kat typewriter speech bubble, belt-personalized messages
- ✅ **Adaptive question bank** — 297 questions in Supabase (80 seed + 197 AI-generated), AdaptiveQuestionSelector, per-question stats via RPC

---

## Current State (2026-03-15)

### What works end-to-end
- Onboarding (7 steps) → Home → Session → Summary
- Adaptive question fetching from Supabase (topic + belt filtered, unseen-first ordering)
- Per-question mistake tracking → feeds back into adaptive selection next session
- Belt Test with pass/fail and 24h retry cooldown
- EN/ES localization with runtime switching

### What is displayed but not yet wired to mechanics
- **XP** — shown in session summary, not connected to progression/stripes
- **Streak** — shown in summary, not persisted between sessions
- **Compete tab** — "Coming Soon" placeholder
- **Progress tab** — "Coming Soon" placeholder

---

## Locked Decisions

- **Localization:** EN + ES + PT mandatory. Strings never hardcoded.
- **Lives:** 5 hearts per session (Duolingo model)
- **vs Kat:** Async LLM rival powered by Claude API
- **Monetization:** Free = White Belt Stripe 1. Pro subscription (price TBD). No ads. Streak freeze = free for everyone.
- **3D:** GrappleMap → Babylon.js (Phase 5, not MVP)
- **Platform:** iOS only — Swift/SwiftUI. Android not planned.

---

## Project Structure

```
BJJMind/              ← Xcode project (Swift 6.0)
  Sources/BJJMind/
    Core/             ← AppState, SessionEngine, AdaptiveQuestionSelector, SupabaseService
    Models/           ← Question, Unit, Belt, UserProfile
    Onboarding/       ← 7-step onboarding flow
    Home/             ← HomeView, belt path map
    Session/          ← SessionView, SessionEngine, question format views
  Tests/BJJMindTests/ ← 110 tests, TDD
characters-graphics/  ← Character PNG assets
scripts/
  migrate_db.py       ← Supabase seed data migration
  generate_questions.py ← Claude API question generator
  schema.sql          ← DB schema DDL
  increment_question_stats.sql ← RPC function for atomic stat increment
docs/
  business-logic-2026-03-14.md ← Authoritative current state snapshot
  backlog.md          ← Current priorities
  spec.md             ← Full product spec (some sections planned, not implemented)
  logic/              ← Game system specs (mix of implemented + planned)
  characters/         ← Character briefs + Nano Banana prompts
  curriculum/         ← BJJ curriculum documents
  content/            ← Question bank structure
  3d/                 ← GrappleMap + Babylon.js research (Phase 5)
  plans/archive/      ← Completed implementation plans
figma-screens/        ← HTML clickable prototype
CLAUDE.md             ← This file
```

---

## Key Characters

- **Gi Ghost** — mascot, AhaMoment screen, feedback animations
- **Marco** — coach, SkillAssessment screen + CharacterMoment nodes
- **Kat** — rival, KatIntro screen (onboarding) + Compete tab (not yet built)
- **Old Chen** — CharacterMoment nodes
- **Rex** — CharacterMoment nodes

---

## Competitor Context

**Beyond The Mat** (beyondthemat.app) — direct competitor, launched March 2026. Belgian company. Also Duolingo-style with 3D clay renders. Their questions: "name this technique." Our angle: "what do you DO here." They have no AI features. We have vs Kat + adaptive curriculum.

---

## Development Rules

### After every `git push` to GitHub — update these docs:
1. **`CLAUDE.md`** — version, test count, completed versions, current state
2. **`docs/business-logic-2026-03-14.md`** (or create new dated snapshot) — what works end-to-end
3. **`docs/backlog.md`** — mark done items, add new priorities

### Pipeline for every feature
**Tests → Code → Run tests → Code review → Push → Update docs**
Code review cannot be skipped.

### SourceKit false positives
"Cannot find type in scope" errors in SourceKit are cross-file indexing artifacts — not real compile errors. Code compiles fine. Ignore them.
