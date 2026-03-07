# BJJ Mind — Prototype Progress

## Status: Clickable HTML prototype, 25 screens ✅

Deployed at GitHub Pages (olevasyliev/bjj-mind).

---

## Screens done ✅

### Onboarding (3 screens)
- `welcome.html` — Gi Ghost + CTA
- `belt-select.html` — Belt selection (White / Blue / Purple)
- `problem-select.html` — Problem tags (takedowns, guard, escapes...)
- `aha-moment.html` — "Here's how it works" — Onboarding step 3

### Core App (5 screens)
- `home.html` — **Duolingo-style belt path map** (zigzag track, nodes, active unit, belt test gate, locked future)
- `train.html` — Belt path (unit list, active/locked, exam gate)
- `compete.html` — Tournament Run, vs Kat, League
- `progress.html` — Belt + stripes, tag mastery bars
- `profile.html` — Gi Ghost, titles, gym stats

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
- `feedback-wrong.html` — Gi Ghost sad (red, correct answer reveal)

### Special Modes (4 screens)
- `coach-moment.html` — Marco interrupts with tip/story
- `match-vs-kat.html` — Turn-based match vs Kat (dark theme)
- `belt-test.html` — Belt Test Gate (rules, tags to pass, start CTA)
- `belt-test-active.html` — Belt test in progress (strict timer, no hints)
- `tournament-match.html` — Bracket strip + in-match question (dark theme)

### End of Session (1 screen)
- `summary.html` — XP earned, accuracy, coach insight, streak

---

## Up next 📋

### Content & Art
- [ ] Character art from Nano Banana (Gi Ghost: happy/sad/excited expressions)
- [ ] Marco, Old Chen, Kat character art
- [ ] Real BJJ position illustrations (replace SVG placeholders)
- [ ] App name brainstorm (BJJ Mind is placeholder)

### Missing states
- [ ] `home.html` — Streak lost state (0 day, broken heart)
- [ ] `home.html` — All units complete → belt test unlocked
- [ ] `feedback-wrong.html` — heart lost animation
- [ ] Tournament: win screen, lose screen

### Next prototype screens
- [ ] `league.html` — League standings / weekly leaderboard
- [ ] `store.html` — Hearts refill, streak freeze, power-ups

---

## Locked decisions 🔒
- 5-heart lives system (like Duolingo)
- LLM-based async rival for vs-Kat matches
- GrappleMap for 3D position scenes (Phase 5)
- Free: White Belt Stripe 1. Subscription from Stripe 2+
- Promo codes for friends & partners (free subscription)
- iOS-first (React Native + Expo)
- Stack: React Native, Babylon.js, Supabase, Claude API
