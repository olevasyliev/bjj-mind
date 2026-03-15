# BJJ Mind — Backlog
**Last updated: 2026-03-15**

---

## 🔥 Current priorities

### 1. XP system — wire to mechanics
XP is currently calculated and shown but not connected to anything.

- [ ] Implement XP formula: `(correct × 10 + first-try bonus + speed bonus) × streak_multiplier`
- [ ] Save `xp_total` to Supabase `user_profiles`
- [ ] Streak multiplier: daily streak up to +30%, weekly consistency up to +50%, take best of two
- [ ] Show XP progress toward next stripe on HomeView
- [ ] Belt/stripe unlock when XP threshold reached (gate: XP + tag mastery both required)

### 2. Streak system — persist and calculate
Streak is shown in session summary but not saved between sessions.

- [ ] Save `streak_days` and `last_session_date` to Supabase
- [ ] Increment streak if first session of the day
- [ ] Break streak if no session yesterday (check on app open)
- [ ] Weekly consistency tracker: count sessions per week, streak in weeks
- [ ] Streak freeze: free for everyone, no limits (by design)
- [ ] Show streak on HomeView (fire icon + count)

### 3. Progress tab
Currently "Coming Soon".

- [ ] Tag mastery bars (frames, escapes, grips, timing, sweeps, submissions, control, base, transitions)
- [ ] Mastery formula: correct answers in last 20 attempts per tag
- [ ] Visual: Weak (red) / Learning (yellow) / Solid (green) / Mastered (✅)
- [ ] Belt progress: XP bar toward next stripe + which tags still need work

### 4. Compete tab — vs Kat
Currently "Coming Soon". Core feature of the product.

- [ ] Kat intro screen (already in onboarding — reuse her personality)
- [ ] Match: 5 questions, 8s timer, Kat "plays" same questions via Claude API
- [ ] Kat accuracy varies by topic (85% on submissions, 55% on timing — she has gaps)
- [ ] Win/lose screen with XP reward
- [ ] 1 match per day (free), unlimited (subscription)

---

## 📋 Next up

### Tag mastery tracking
- [ ] When saving session stats, also tag each question with its `tags[]`
- [ ] `tag_mastery` table or computed from `user_question_stats` + question tags
- [ ] Feeds into: Progress tab, adaptive question weighting, stripe unlock gate

### Belt test unlock gate
- [ ] Currently belt test is always available after completing all lesson nodes
- [ ] Add gate: XP threshold AND all required tags at Mastered (≥80%)
- [ ] Show which tags are blocking the test

### Onboarding — minor fixes
- [ ] Club autocomplete (currently free text) — seed top 200 academies
- [ ] Location detect button actually wires to CoreLocation (stub exists)

---

## 🗂️ Future (not in current sprint)

### P2P — реальные соперники онлайн
- Бои в реальном времени против других игроков (тот же движок, другой соперник)
- Онлайн турниры с живой сеткой из реальных игроков
- Рейтинговая система

### Брендированные турниры и соперники (маркетинг / бизнес)
- Партнёрство с академиями и организациями (IBJJF, AJP, known gyms)
- Специальные соперники с брендом партнёра
- Брендированные турниры как маркетинговый инструмент

### vs Kat — full system
- League (Bronze → Diamond, weekly reset)
- Tournament Run (5 sequential matches, resources carry)
- Leaderboard within belt tier

### Subscription / Monetization
- StoreKit 2 integration
- Free: White Belt Stripe 1 only
- Pro: all content, all belts
- Paywall screen on locked nodes
- Promo codes (full access, no expiry)

### Achievements & Titles
- 20+ badges (see `docs/logic/achievements.md` for full list)
- Profile display, top 3 highlighted

### 3D position scenes (Phase 5)
- GrappleMap parser → Babylon.js renderer
- 20 unique scenes for White Belt
- Replace current placeholder illustrations

### Additional content
- Portuguese (PT) localization
- Blue → Purple curriculum (PSBJJA source)
- Self-defense track (separate from belt progression)

### Polish
- Lottie animations (Gi Ghost expressions)
- Haptic feedback (correct/wrong/unlock)
- Sound design
- Character art from Nano Banana (currently PNG placeholders)

---

## ✅ Done

- Onboarding (7 steps): Welcome → BeltSelect → SkillAssessment → Struggles → ClubInfo → AhaMoment → KatIntro
- HomeView with 31-node belt path map
- SessionFlow with 5 hearts, MCQ2/MCQ4/TrueFalse/FillBlank formats
- UnitKind system (.lesson / .characterMoment / .mixedReview / .miniExam / .beltTest)
- Belt Test: pass/fail, 80% accuracy threshold, 24h retry cooldown
- EN/ES localization with runtime switching
- Supabase sync: user profile, unit progress, session results
- Adaptive question bank: 297 questions, topic-based fetching, unseen→weak→rest ordering
- Per-question mistake tracking via `increment_question_stats` RPC
- Character illustrations on all onboarding screens (Kat typewriter animation)
- App icon (1024px + all sizes)
- GitHub: olevasyliev/bjj-mind, v1.1.1 (build 4), 110 tests green
