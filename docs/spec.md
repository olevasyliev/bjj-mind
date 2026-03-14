# BJJ Mind — Product & Technical Specification

**Version:** 1.0
**Date:** 2026-03-11
**Status:** Draft

---

## 1. Business Overview

### 1.1 Problem

BJJ practitioners (especially White and Blue Belts) have no structured way to study technique between mat sessions. YouTube is passive, books are dry, and there is no gamified system that rewards consistent mental practice.

### 1.2 Solution

BJJ Mind is a Duolingo-style iOS app for Brazilian Jiu-Jitsu. It turns BJJ theory into short daily training sessions — questions, decisions, position recognition — built around a progressive belt curriculum.

### 1.3 Target Audience

- **Primary:** White and Blue Belt BJJ practitioners (1–4 years of training)
- **Secondary:** Purple and Brown Belts wanting to reinforce fundamentals
- **Geography:** English-speaking markets (US, UK, Australia) + Brazil + Spanish-speaking LatAm
- **Profile:** 18–40, trains 2–4x per week, uses smartphone daily

### 1.4 Market

- 10M+ BJJ practitioners worldwide (growing ~15% YoY)
- No direct competitor with gamified belt-progression learning
- Adjacent: Duolingo ($5B+), BJJ Fanatics (content), Flow BJJ (drilling app)

### 1.5 Business Model

| Tier | Price | Content |
|------|-------|---------|
| Free | $0 | White Belt Stripe 1 (full access) |
| Pro | TBD | All belts, all stripes, tournaments, vs Kat |
| Promo | Free Pro | Codes for gym partners, affiliates |

> **Note:** Pro pricing TBD. Consider competitive landscape (Beyond The Mat at €2/mo) and perceived value. Decide before Phase 2 launch.

**Monetization levers:**
- Subscription (primary)
- Gems in-app currency (hearts refill, streak freeze, cosmetics)
- Gym partnerships (bulk subscriptions for academy members)

### 1.6 Success Metrics

- D7 retention > 30%
- Daily streak > 3 days average (first month)
- Trial → Pro conversion > 5%
- Session length 5–12 min
- Outcome metric: user-reported improvement in rolling (quarterly survey)

---

## 2. Product Specification

### 2.1 Core Loop

```
Open app → See home (belt path) → Start unit →
Answer 5–8 questions → Summary → XP/streak update →
Home (progress visible)
```

Session duration: 5–12 minutes.

### 2.2 Onboarding Flow

1. **Welcome** — Gi Ghost mascot, single CTA "Start Training"
2. **Belt Select** — White / Blue / Purple (sets starting curriculum)
3. **Problem Tags** — user picks weak areas (takedowns, guard, escapes, submissions...)
4. **Aha Moment** — how the app works (belt path, XP, hearts)

### 2.3 Belt Path (Home Screen)

Duolingo-style zigzag track:
- Units = nodes on path (locked / active / completed)
- Active unit glows, tappable
- Belt Test Gate appears after all units in a belt section done
- Locked future units grayed out

**Content structure:**
- White Belt → Blue Belt: ~40 units, ~5 stripes
- Blue Belt → Purple Belt: ~40 units (Phase 2)
- Each unit: 1 technique or concept, 5–8 questions, multiple formats

### 2.4 Question Formats

| Format | Description | Timer |
|--------|-------------|-------|
| MCQ (2 options) | Main format, SVG position scene | 8s |
| MCQ (4 options) | Harder, grid layout | 5s |
| True / False | Quick recall | 4s |
| Sequence | Order the steps (word chips) | 12s |
| Tap Zone | Tap correct zone on SVG diagram | 8s |
| Fill in the Blank | Complete the rule/principle | 10s |
| Spot the Mistake | Find what's wrong in the position | 10s |

### 2.5 Lives & Progression

- **5 hearts** per session (like Duolingo)
- Wrong answer = -1 heart
- 0 hearts = session ends, wait or spend gems to refill
- **Streak:** daily training keeps streak alive; Streak Freeze consumable item

### 2.6 Special Modes

**Coach Moment (Marco)**
- Interrupts mid-session with a tip, story, or principle
- No question — just knowledge injection
- Appears ~1x per 3 sessions

**vs Kat (LLM Rival)**
- Turn-based async match against AI opponent
- Kat has a defined personality (aggressive, cocky, consistent)
- Player and Kat answer same questions; score compared
- Powered by Claude API

**Belt Test**
- Unlocks after all units in a section complete
- Strict rules: no hints, timer halved, 3 hearts max
- Pass = stripe awarded + celebration screen
- Fail = weak areas highlighted, retry after 24h

**Tournaments**
- Weekly bracket events
- 4–8 players (real or AI fill)
- 3 rounds, questions same format as regular
- Winner gets gems + league points

**Leagues**
- Bronze / Silver / Gold / Diamond
- Weekly leaderboard, top 3 promoted, bottom 3 relegated
- Pro-only feature

### 2.7 Store (Gems Currency)

| Item | Cost |
|------|------|
| Hearts Refill (full) | 350 gems |
| Streak Freeze | 200 gems |
| XP Boost (2x, 1 session) | 100 gems |
| Gi Ghost Skin | 500 gems |

Gems earned: daily login (10), correct streak (+5/question), achievements.
Gems purchased: IAP bundles ($1.99 → 500 gems, $4.99 → 1500 gems, etc.)

### 2.8 Progress & Profile

- Belt visualization + stripe count
- Tag mastery bars (per topic: guard, escapes, submissions...)
- Total XP, longest streak, accuracy %
- Titles/badges earned

### 2.9 Notifications

- Daily streak reminder (configurable time)
- League reset warning (Sunday evening)
- Coach tip of the day
- vs Kat match result

---

## 3. Technical Specification

### 3.1 Platform & Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift 5.9+, SwiftUI |
| 3D Scenes (Phase 5) | Babylon.js in WKWebView |
| Backend / DB | Supabase (PostgreSQL + Auth + Realtime) |
| AI (vs Kat, Coach) | Claude API (claude-sonnet-4-6) |
| Payments | StoreKit 2 (IAP + subscriptions) |
| Analytics | PostHog or Mixpanel |
| Push Notifications | APNs via Supabase Edge Functions |

**iOS minimum:** iOS 16+
**Devices:** iPhone only (portrait, 9:16)

### 3.2 Architecture

```
App (SwiftUI)
├── Onboarding Module
├── Home Module (belt path)
├── Session Module (question engine)
│   ├── QuestionRenderer (format-aware)
│   ├── HeartManager
│   ├── TimerEngine
│   └── SessionScorer
├── Compete Module (vs Kat, Tournaments, Leagues)
├── Store Module (gems, IAP)
├── Progress Module
├── Profile Module
└── Settings Module

Supabase
├── users
├── user_progress (belt, stripe, xp, streak)
├── user_answers (history per question)
├── questions (static curriculum)
├── matches (vs Kat state)
├── leagues (weekly rankings)
└── purchases

Claude API
├── kat_move() → generates Kat's answer + commentary
├── coach_tip() → generates Marco tip relevant to user's weak tags
└── answer_explanation() → explains why an answer is correct (on request)
```

### 3.3 Data Model (key tables)

**users**
```
id, email, display_name, created_at, belt, stripe, xp_total, streak_current, streak_longest, hearts, gems
```

**questions**
```
id, belt, unit_id, format, content (JSON), correct_answer, tags[], difficulty (1-5)
```

**user_progress**
```
user_id, unit_id, completed_at, accuracy, weak_tags[]
```

**matches**
```
id, user_id, kat_personality, round, user_score, kat_score, status, created_at
```

### 3.4 Content Database (White → Blue Belt)

**Phase 1 (launch):**
- ~200 questions across 40 units
- Tags: guard passing, closed guard, escapes, side control, mount, back control, submissions, takedowns
- Source: Pedro Sauer White→Blue curriculum
- Format: static JSON, loaded on first app launch, cached locally

**Phase 2:**
- Blue→Purple (88 techniques, ~200 questions)
- Self-Defense Track (~30 questions)
- Source: PSBJJA Blue→Purple curriculum

### 3.5 AI Integration (Claude API)

**vs Kat:**
```
System prompt: "You are Kat, a competitive BJJ Blue Belt...
[question] + [4 options] → return: chosen_option + short trash_talk_line"
```

**Coach Moment (Marco):**
```
System prompt: "You are Marco, a calm BJJ Black Belt coach...
[user weak tags] → return: short tip or story (max 60 words)"
```

**Answer Explanation (on tap):**
```
[question + correct_answer] → return: why this is correct, max 80 words
```

Calls: ~2–5 per session for Pro users. Estimated cost: ~$0.01–0.03/user/day.

### 3.6 Subscription & IAP (StoreKit 2)

Products:
- `bjjmind.pro.monthly` — $9.99/month
- `bjjmind.pro.yearly` — $59.99/year
- `bjjmind.gems.500` — $1.99
- `bjjmind.gems.1500` — $4.99
- `bjjmind.gems.3500` — $9.99

Promo codes: via App Store Offer Codes (no backend needed).

### 3.7 Offline Support

- Full curriculum cached locally (Core Data or SQLite)
- Sessions work offline; sync to Supabase on reconnect
- AI features (vs Kat, Coach) require connectivity — graceful degradation shown

### 3.8 Security

- Auth: Supabase Auth (email/Apple Sign In)
- API keys (Claude, Supabase) never in client — routed via Supabase Edge Functions
- Receipt validation server-side via App Store Server API

---

## 4. Development Phases

### Phase 1 — MVP (White Belt Stripe 1, Free)
- Onboarding (4 screens)
- Home belt path (White Belt units 1–8)
- Session engine (MCQ, True/False formats)
- Hearts + streak system
- Basic profile + progress
- Supabase auth + progress sync
- **Goal:** TestFlight, 50 beta testers

### Phase 2 — Pro Launch
- All White→Blue content (40 units)
- All 7 question formats
- Belt Test + stripe system
- StoreKit 2 subscription
- Push notifications
- **Goal:** App Store launch

### Phase 3 — Compete
- vs Kat (Claude API)
- Tournaments
- Leagues
- Store + gems
- **Goal:** D7 retention > 30%

### Phase 4 — Growth
- Blue→Purple curriculum
- Self-Defense Track
- Gym partnerships / bulk codes
- Android consideration

### Phase 5 — AI + 3D
- GrappleMap 3D scenes (Babylon.js)
- Adaptive curriculum (AI decides question order)
- Coach Marco live tips

---

## 5. Open Questions

- [ ] Final app name (BJJ Mind is placeholder)
- [ ] Character art style + artist (Gi Ghost, Marco, Kat, Old Chen)
- [ ] Pedro Sauer curriculum — licensing/copyright considerations
- [ ] Monetization: gems-only IAP launch vs subscription-first?
- [ ] App Store category: Education or Sports?
- [ ] **Localization strategy** — EN, ES, PT are mandatory at launch (not afterthought). Plan i18n architecture from Phase 1, strings externalized from day 1.
- [ ] **Gym owner value proposition** — Beyond The Mat offers free club management tools. We need a different angle. Options to explore: homework assignments (coach sends specific units to students), class prep tool (coach builds lesson plan around app units), progress visibility (coach sees student weak areas). Not admin software — pedagogical tool.
- [ ] **Kid character** — Add a child character (alongside Gi Ghost / Marco / Kat) for the kids curriculum track. To be developed in coordination with athlete partner's kids content. Target Phase 4 alongside gym partnerships.
