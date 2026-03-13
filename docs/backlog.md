# BJJ Mind — Prototype Progress

## Status: Clickable HTML prototype, 31 screens ✅

Deployed at GitHub Pages (olevasyliev/bjj-mind).

---

## Screens done ✅

### Onboarding (3 screens)
- `welcome.html` — Gi Ghost + CTA
- `belt-select.html` — Belt selection (White / Blue / Purple)
- `problem-select.html` — Problem tags (takedowns, guard, escapes...)
- `aha-moment.html` — "Here's how it works" — Onboarding step 3

### Core App (8 screens)
- `home.html` — **Duolingo-style belt path map** (zigzag track, nodes, active unit, belt test gate, locked future)
- `home-streak-lost.html` — Streak = 0, red banner, "Freeze 🛡️" CTA
- `home-belt-test-ready.html` — All units done, glowing belt test gate
- `train.html` — Belt path (unit list, active/locked, exam gate)
- `compete.html` — Tournament Run, vs Kat, League
- `progress.html` — Belt + stripes, tag mastery bars
- `profile.html` — Gi Ghost, titles, gym stats
- `store.html` — Gems currency, hearts refill, streak freeze, power-ups, cosmetics

### Gameplay Formats (7 screens)
- `micro-round.html` — Main MCQ format (SVG scene, timer ring, 5 hearts)
- `round-4choice.html` — 4-option grid MCQ (harder, 3s timer)
- `round-truefalse.html` — Quick true/false
- `round-sequence.html` — Order the steps (word bank chips)
- `round-tap-zone.html` — Tap the correct zone on SVG diagram
- `round-fill-rule.html` — Fill in the blank
- `round-spot-mistake.html` — Spot what's wrong in the position

### Feedback (2 screens)
- `feedback-correct.html` — Gi Ghost happy (green, XP reward)
- `feedback-wrong.html` — Gi Ghost sad (red, correct answer reveal, heart drop animation)

### Special Modes (7 screens)
- `coach-moment.html` — Marco interrupts with tip/story
- `match-vs-kat.html` — Turn-based match vs Kat (dark theme)
- `belt-test.html` — Belt Test Gate (rules, tags to pass, start CTA)
- `belt-test-active.html` — Belt test in progress (strict timer, no hints)
- `tournament-match.html` — Bracket strip + in-match question (dark theme)
- `tournament-win.html` — Victory screen (confetti, rewards, bracket)
- `tournament-lose.html` — Defeat screen (coach note, partial XP, retry)
- `league.html` — Bronze league leaderboard (promotion / danger zones)

### End of Session (1 screen)
- `summary.html` — XP earned, accuracy, coach insight, streak

---

## Up next 📋

### Onboarding redesign 🔥
- [ ] **Skill Assessment Quiz** — replace "what's your belt?" with a short 5-question diagnostic test during onboarding. User gets to *show* what they know, not just declare it. Tone: encouraging throughout — "Nice, you know that!" / "We'll make sure you nail this." Results feed directly into weak tags + curriculum starting point. Hook: first interaction feels like a game, not a form.
- [ ] **Onboarding: club info** — add step asking: "Where do you train?", "How long have you been training?", club name (autocomplete from club database). This data powers profile, social features, and future gym partnerships.
- [ ] **Club database** — parse/import club list from smoothcomp.com (https://smoothcomp.com/en/club) as autocomplete source for club name field in onboarding. Check ToS before scraping. Alternatively seed manually with top 500 academies in US/BR/ES.
- [ ] **Location auto-detect in onboarding** — "Detect my location" button in club info step. Uses CoreLocation to pre-fill country/city. Ask permission inline (not upfront). Club name still manual until club DB is ready.
- [ ] **vs Kat intro right after onboarding** — before first lesson unit, Kat appears and challenges the user. Short moment: Kat trash-talks, user accepts. This sets up emotional stakes before any learning happens. Kat becomes the reason to come back, not just the content.

### Content & Art
- [ ] Character art from Nano Banana (Gi Ghost: happy/sad/excited expressions)
- [ ] Marco, Old Chen, Kat character art
- [ ] Real BJJ position illustrations (replace SVG placeholders)
- [ ] App name brainstorm (BJJ Mind is placeholder)

### Phase 2 screens
- [ ] `belt-test-pass.html` — Belt test passed (stripe granted, celebration)
- [ ] `belt-test-fail.html` — Belt test failed (review weak areas, retry)
- [ ] `notifications.html` — Streak reminder, league reset, coach tips

---

## Future tracks (not in White Belt path) 🗂️
- [ ] **Self-Defense Track** — separate learning mode (not part of belt progression)
  - Covers techniques 1-30: striking defense, T-position throws, lapel grabs, bear hugs, headlocks
  - ~30 questions, ~40 min gameplay
  - Reason: self-defense is a different context/mindset from sport BJJ ground game

## Future belt content 📚
- [ ] **Blue→Purple curriculum**
  - Source: https://bjjmechanics.com/p/sauer-jiu-jitsu-blue-to-purple-curriculum (PSBJJA, $100 course)
  - 88 techniques covering: sweeps (spider guard, half guard, star sweep, kickover), submissions (omoplata, ankle locks, knee bars, lapel chokes), knee-on-stomach escapes, knife defenses
  - Same Pedro Sauer association — consistent with our White→Blue source

---

## Locked decisions 🔒
- 5-heart lives system (like Duolingo)
- LLM-based async rival for vs-Kat matches
- GrappleMap for 3D position scenes (Phase 5)
- Free: White Belt Stripe 1. Subscription from Stripe 2+
- Promo codes for friends & partners (free subscription)
- iOS only — Swift/SwiftUI (не React Native)
- Stack: Swift, SwiftUI, Babylon.js (WKWebView), Supabase Swift SDK, Claude API
