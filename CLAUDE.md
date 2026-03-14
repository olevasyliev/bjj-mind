# BJJ Mind — Project Context for Claude

## What This Is

BJJ Mind is a Duolingo-style iOS app for Brazilian Jiu-Jitsu. It trains decision-making and pattern recognition — not technique names, but **what to do from a given position**. Core differentiator: "Not BJJ trivia. BJJ thinking."

Target: White and Blue Belt practitioners (1–4 years), English/Spanish/Portuguese markets.

---

## Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift 6.0, SwiftUI, iOS 16+ |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
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
- `LanguageManager` — singleton, runtime bundle switch, persists in UserDefaults("appLanguage")
- `L10n` enum — type-safe localized strings via LanguageManager.bundle
- `QuestionProvider` — locale-aware unit selection (en/es/pt)

**45 tests, all green** (as of V0.3-i18n)

---

## Completed Versions

- ✅ **V0.1** — Onboarding (Welcome → BeltSelect → ProblemSelect → AhaMoment) + HomeView + SessionFlow
- ✅ **V0.2** — Unit Progression (completeUnit, unlock chain) + Belt Test (gate, pass/fail, 24h retry)
- ✅ **V0.3-i18n** — EN/ES localization: L10n enum, Localizable.strings, SampleData_ES, LanguageManager, language switcher

---

## Locked Decisions

- **Localization:** EN + ES + PT mandatory. i18n architecture from day 1, strings never hardcoded.
- **Lives:** 5 hearts per session (Duolingo model)
- **vs Kat:** Async LLM rival powered by Claude API
- **Monetization:** Free = White Belt Stripe 1. Pro subscription (price TBD) = all belts. No ads.
- **3D:** GrappleMap → Babylon.js (Phase 5, not MVP)
- **Platform:** iOS only — Swift/SwiftUI. Android not planned.

---

## Project Structure

```
BJJMind/              ← Xcode project (Swift source)
characters-graphics/  ← Character art assets
docs/
  backlog.md          ← Active backlog + upcoming screens
  spec.md             ← Full product & technical spec
  roadmap.md          ← Phased implementation plan
  characters/         ← Character briefs + prompts
  curriculum/         ← BJJ curriculum documents
  content/            ← Question bank structure
  logic/              ← Game systems specs
  3d/                 ← GrappleMap + Babylon.js research
  plans/              ← Historical dated planning docs
figma-screens/        ← HTML clickable prototype (31 screens)
  index.html          ← Prototype navigation hub
CLAUDE.md             ← This file
```

---

## Key Characters

- **Gi Ghost** — mascot, appears in feedback and rewards
- **Marco** — AI coach (calm black belt), gives tips and post-session insights
- **Kat** — AI rival (competitive blue belt), async matches via Claude API
- **Old Chen** — wise sensei character
- **Rex** — big rival character

---

## Competitor Context

**Beyond The Mat** (beyondthemat.app) — direct competitor, launched March 2026. Belgian company (Beyond Sports B.V.). Also Duolingo-style with 3D clay renders. Their questions: "name this technique." Our angle: "what do you DO here." They have no AI features. We have vs Kat + adaptive curriculum.

---

## Next Up

See `docs/backlog.md` for full backlog.

Immediate: V0.3 Rich Learning Path — 15 units, Coach Marco moments, FillBlank/Sequence question formats.
