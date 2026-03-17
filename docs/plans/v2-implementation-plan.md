# BJJ Mind v2 — Implementation Plan

**Date:** 2026-03-16
**Status:** Approved for implementation
**Scope:** Curriculum restructure + session algorithm + inline theory cards + localization + developer testing mode

---

## Overview

v2 is a refactor of the session learning engine and curriculum structure. The UI shell (HomeView, SessionView) stays largely intact; what changes is how sessions are composed, how progress is tracked per-question, and what the curriculum node structure looks like.

**What is NOT changing in v2:**
- Battle system (BattleEngine, BattleScale, BattleView, TournamentBracketView) - stays as-is
- Onboarding flow - stays as-is
- Auth / device ID mechanism - stays as-is
- Supabase REST API pattern (URLSession, no SPM) - stays as-is

---

## Section 1: Database Schema Changes

### 1.1 Table: `user_question_stats`

**Current state:** `user_id`, `question_id`, `times_seen`, `times_wrong`, `updated_at`

**Changes needed:**

```sql
-- Add strength column to user_question_stats
ALTER TABLE user_question_stats
ADD COLUMN strength INTEGER NOT NULL DEFAULT 0
    CHECK (strength >= 0 AND strength <= 100);

-- Add last_seen timestamp (for time decay)
ALTER TABLE user_question_stats
ADD COLUMN last_seen TIMESTAMPTZ;

-- Backfill last_seen from updated_at for existing rows
UPDATE user_question_stats SET last_seen = updated_at WHERE last_seen IS NULL;

-- Index for decay queries (fetch all questions for user where last_seen is old)
CREATE INDEX IF NOT EXISTS idx_uqs_user_last_seen
    ON user_question_stats (user_id, last_seen);

-- Index for strength-based queries (fetch weak questions)
CREATE INDEX IF NOT EXISTS idx_uqs_user_strength
    ON user_question_stats (user_id, strength);
```

**Migration strategy for existing users:**
- Existing rows keep `times_seen` and `times_wrong` as-is.
- `strength` is calculated from existing stats on first read: `strength = max(0, 50 - (times_wrong * 15))`. This gives users with clean records a starting strength of 50, users who struggled start lower.
- A one-time migration script runs on app launch if `strength = 0 AND times_seen > 0`.

### 1.2 Table: `questions`

**Current state:** `id`, `unit_id`, `format`, `prompt`, `options`, `correct_answer`, `explanation`, `tags`, `difficulty`, `topic`, `belt_level`, `perspective`, `coach_note`

**Changes needed:**

```sql
-- unit_id becomes nullable (v2 questions are topic-level, not unit-level)
ALTER TABLE questions ALTER COLUMN unit_id DROP NOT NULL;

-- Add sub_topic column for grouping within a topic
ALTER TABLE questions
ADD COLUMN sub_topic TEXT;

-- Add technique_ref column (links back to PSBJJA technique number: "#58", "#70" etc.)
ALTER TABLE questions
ADD COLUMN technique_ref TEXT;

-- Add language column (default 'en'; future: 'es', 'pt')
ALTER TABLE questions
ADD COLUMN language TEXT NOT NULL DEFAULT 'en';

-- Index for session composition queries
CREATE INDEX IF NOT EXISTS idx_questions_topic_subtopic
    ON questions (topic, sub_topic, belt_level, language)
    WHERE unit_id IS NULL;

-- Index for new-question fetching (unseen by user)
CREATE INDEX IF NOT EXISTS idx_questions_topic_language
    ON questions (topic, belt_level, language);
```

**Existing questions (v1):** All current questions have `unit_id` set. They remain valid. The session algorithm falls back to topic-wide pool when `unit_id IS NULL` questions aren't enough.

### 1.3 Table: `units`

**No structural changes needed.** The curriculum restructure is purely a data change (delete old rows, insert new rows). The `units` table schema supports the new 4-cycle structure already.

Fields already present that v2 uses:
- `cycle_number` (INT) - which cycle (1-4)
- `topic` (TEXT) - slug like `"closed_guard"`, `"guard_passing"`
- `kind` (TEXT) - `"miniTheory"`, `"bossFight"`, `"intermediateTournament"`, `"finalTournament"`
- `is_boss` (BOOL)
- `mini_theory_content` (JSONB)

**New column needed for sub-topic progress tracking:**

```sql
-- Add sub_topics column: ordered list of sub-topic slugs in this cycle
-- Used by HomeView to render progress bars
ALTER TABLE units
ADD COLUMN sub_topics TEXT[] DEFAULT '{}';
```

Example value for the Closed Guard cycle node:
`ARRAY['posture_defense', 'guard_attacks', 'sweeps', 'guard_breaks']`

### 1.4 Table: `unit_translations`

**Current state:** `unit_id`, `locale`, `title`, `description`, `mini_theory_content`

**No schema changes.** The new cycles add new rows for EN base content. ES translations are generated via existing `generate_es_translations.py` script.

### 1.5 New RPC: `increment_question_strength`

Replace (or extend) the existing `increment_question_stats` RPC to also update `strength` and `last_seen`:

```sql
CREATE OR REPLACE FUNCTION increment_question_strength(
    p_user_id UUID,
    p_question_id TEXT,
    p_was_wrong BOOLEAN,
    p_first_attempt BOOLEAN DEFAULT TRUE
) RETURNS VOID AS $$
BEGIN
    INSERT INTO user_question_stats (user_id, question_id, times_seen, times_wrong, strength, last_seen)
    VALUES (
        p_user_id,
        p_question_id,
        1,
        CASE WHEN p_was_wrong THEN 1 ELSE 0 END,
        CASE
            WHEN NOT p_was_wrong AND p_first_attempt THEN 20
            WHEN NOT p_was_wrong AND NOT p_first_attempt THEN 10
            ELSE 0
        END,
        NOW()
    )
    ON CONFLICT (user_id, question_id) DO UPDATE SET
        times_seen  = user_question_stats.times_seen + 1,
        times_wrong = user_question_stats.times_wrong + CASE WHEN p_was_wrong THEN 1 ELSE 0 END,
        strength    = GREATEST(0, LEAST(100,
            user_question_stats.strength +
            CASE
                WHEN NOT p_was_wrong AND p_first_attempt THEN 20
                WHEN NOT p_was_wrong AND NOT p_first_attempt THEN 10
                ELSE -30
            END
        )),
        last_seen   = NOW(),
        updated_at  = NOW();
END;
$$ LANGUAGE plpgsql;
```

### 1.6 New RPC: `apply_strength_decay`

Called once per app launch, applies time-based decay to questions not seen recently:

```sql
CREATE OR REPLACE FUNCTION apply_strength_decay(
    p_user_id UUID,
    p_decay_per_3_days INTEGER DEFAULT 5
) RETURNS VOID AS $$
BEGIN
    UPDATE user_question_stats
    SET
        strength   = GREATEST(0, strength - (p_decay_per_3_days * FLOOR(EXTRACT(EPOCH FROM (NOW() - last_seen)) / (3 * 86400))::INTEGER)),
        updated_at = NOW()
    WHERE
        user_id  = p_user_id
        AND last_seen IS NOT NULL
        AND last_seen < NOW() - INTERVAL '3 days'
        AND strength > 0;
END;
$$ LANGUAGE plpgsql;
```

### 1.7 New RPC: `fetch_session_questions`

The session composition algorithm runs server-side for efficiency. Three-bucket query returning up to N questions:

```sql
CREATE OR REPLACE FUNCTION fetch_session_questions(
    p_user_id       UUID,
    p_topic         TEXT,
    p_belt_level    TEXT,
    p_language      TEXT DEFAULT 'en',
    p_session_size  INTEGER DEFAULT 9,
    p_new_pct       NUMERIC DEFAULT 0.60,
    p_weak_pct      NUMERIC DEFAULT 0.25,
    p_refresh_pct   NUMERIC DEFAULT 0.15
) RETURNS SETOF questions AS $$
DECLARE
    v_new_count     INTEGER := ROUND(p_session_size * p_new_pct);
    v_weak_count    INTEGER := ROUND(p_session_size * p_weak_pct);
    v_refresh_count INTEGER := p_session_size - v_new_count - v_weak_count;
BEGIN
    -- Bucket 1: New questions from current topic (never seen by user)
    RETURN QUERY
        SELECT q.* FROM questions q
        WHERE q.topic     = p_topic
          AND q.belt_level = p_belt_level
          AND q.language  = p_language
          AND q.format    != 'mcq3'
          AND NOT EXISTS (
              SELECT 1 FROM user_question_stats s
              WHERE s.user_id = p_user_id AND s.question_id = q.id
          )
        ORDER BY q.difficulty ASC, RANDOM()
        LIMIT v_new_count;

    -- Bucket 2: Weak questions from current topic (strength < 50)
    RETURN QUERY
        SELECT q.* FROM questions q
        JOIN user_question_stats s ON s.question_id = q.id
        WHERE q.topic      = p_topic
          AND q.belt_level = p_belt_level
          AND q.language   = p_language
          AND q.format     != 'mcq3'
          AND s.user_id    = p_user_id
          AND s.strength   < 50
        ORDER BY s.strength ASC, q.difficulty ASC
        LIMIT v_weak_count;

    -- Bucket 3: Refresh questions from any past topic (random, not current)
    RETURN QUERY
        SELECT q.* FROM questions q
        JOIN user_question_stats s ON s.question_id = q.id
        WHERE q.belt_level = p_belt_level
          AND q.language   = p_language
          AND q.topic      != p_topic
          AND q.format     != 'mcq3'
          AND s.user_id    = p_user_id
          AND s.strength   >= 50
        ORDER BY s.last_seen ASC, RANDOM()
        LIMIT v_refresh_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

**Migration note:** The `increment_question_stats` RPC can stay in place temporarily (battle system uses it). Add the new RPC alongside it. After v2 is stable, remove the old one.

---

## Section 2: Curriculum Restructure

### 2.1 New Cycle Structure (White Belt)

The v1 structure (CG -> Half Guard -> Side Control -> Back Control) is replaced with:

**v2: CG -> Guard Passing -> Side Control + Mount -> Back Control**

This aligns with the PSBJJA curriculum where a student first learns to survive from guard (Closed Guard attacks/sweeps), then learns to pass guard, then learns to dominate from top positions, then back attacks.

### 2.2 Cycle Definitions

Each cycle = 1 stripe. The belt has 4 cycles + 1 intermediate tournament (after cycle 2) + 1 final tournament.

---

#### Cycle 1 - Closed Guard (Stripe 1)

**Topic slug:** `closed_guard`
**PSBJJA Techniques covered:** #58-72 (Sections 13-16)
**Unit IDs (new):** `wh-c1-theory`, `wh-c1-boss`

Sub-topics and technique mapping:

| Sub-topic slug | Sub-topic title | PSBJJA # | Tags |
|---|---|---|---|
| `posture_defense` | Posture and Defense | #58, #59, #60, #61, #62, #62b | `control`, `frames`, `grips` |
| `guard_attacks` | Attacks from Guard | #63, #64, #65, #66, #67 | `submissions`, `grips`, `timing` |
| `sweeps` | Guard Sweeps | #70, #71, #72 + Hip Bump (BJJFanatics) | `sweeps`, `timing`, `base` |
| `guard_breaks` | Guard Breaks and Passes | #68, #69, Toreando (BJJFanatics) | `control`, `transitions`, `timing` |

**Questions per sub-topic:** 18-20 each = ~72-80 questions total for Cycle 1.

**Node structure in `units` table:**

| order_index | id | kind | title | cycle_number | sub_topics |
|---|---|---|---|---|---|
| 100 | `wh-c1-theory` | miniTheory | Closed Guard | 1 | `{}` |
| 199 | `wh-c1-boss` | bossFight | The Wall | 1 | `{}` |

Note: The miniTheory node is the entry point for the cycle. There are no fixed lesson nodes - sessions are algorithm-composed. Sub-topic progress bars on HomeView replace lesson node chain.

---

#### Cycle 2 - Guard Passing (Stripe 2)

**Topic slug:** `guard_passing`
**PSBJJA Techniques:** #58-69 (passing angles), Toreando, Knee Slice (supplementary)
**Unit IDs:** `wh-c2-theory`, `wh-c2-boss`

Sub-topics:

| Sub-topic slug | Sub-topic title | PSBJJA # | Tags |
|---|---|---|---|
| `posture_in_guard` | Posture in Guard | #58, #59, #60, #61, #62 | `control`, `frames`, `grips` |
| `kneeling_pass` | Kneeling Guard Pass | #68 | `control`, `transitions` |
| `standing_pass` | Standing Guard Pass | #69 | `control`, `transitions`, `timing` |
| `open_guard_passing` | Passing Open Guard | Toreando, Knee Slice | `control`, `transitions`, `base` |

**Questions per sub-topic:** 16-20 = ~65-75 questions total for Cycle 2.

**Unlock gate for guard_breaks sub-topic in Cycle 1:** avg strength of `posture_defense` + `guard_attacks` >= 60% before `sweeps` unlocks. This ensures users understand the guard-top perspective before learning to pass.

---

#### Cycle 3 - Side Control and Mount (Stripe 3)

**Topic slug:** `side_control_mount`
**PSBJJA Techniques:** #31-52 (Sections 6-10)
**Unit IDs:** `wh-c3-theory`, `wh-c3-boss`

Sub-topics:

| Sub-topic slug | Sub-topic title | PSBJJA # | Tags |
|---|---|---|---|
| `side_control_defense` | Defending Side Control | #31, #32, #33, #34, #35, #36, #37 | `escapes`, `frames`, `timing` |
| `side_control_attacks` | Attacking from Side Control | #38, #39, #40, #41, #42 | `submissions`, `control`, `grips` |
| `mount_transitions` | Getting to Mount | #43, #44, #45 | `transitions`, `control` |
| `mount_defense` | Mount Escapes | #46, #47, #48 | `escapes`, `base`, `timing` |
| `mount_attacks` | Attacking from Mount | #49, #49b, #49c, #50, #51, #52 | `submissions`, `control`, `grips` |

**Questions per sub-topic:** 12-16 = ~65-75 questions total for Cycle 3.

---

#### Cycle 4 - Back Control (Stripe 4)

**Topic slug:** `back_control`
**PSBJJA Techniques:** #53-57 (Sections 11-12) + supplementary
**Unit IDs:** `wh-c4-theory`, `wh-c4-boss`

Sub-topics:

| Sub-topic slug | Sub-topic title | PSBJJA # | Tags |
|---|---|---|---|
| `back_defense` | Escaping Back Control | #53, #54 | `escapes`, `grips`, `timing` |
| `back_control_maintain` | Maintaining Back Control | #55 | `control`, `grips` |
| `back_submissions` | Back Submissions | #56, #57, Bow and Arrow | `submissions`, `grips`, `timing` |
| `back_combinations` | Back Control Combinations | all of above combined | `control`, `submissions`, `transitions` |

**Questions per sub-topic:** 14-18 = ~60-70 questions total for Cycle 4.

---

### 2.3 Tournament and Boss Placement

**Intermediate Tournament** - after Cycle 2 (between cycle 2 boss completion and cycle 3 theory unlock)

| order_index | id | kind | title |
|---|---|---|---|
| 299 | `wh-intermediate-tournament` | intermediateTournament | White Belt Tournament - Round 1 |

Covers topics: `closed_guard` + `guard_passing`
Opponents: Marcus (1/4), Diego (1/2), Yuki (Final)

**Boss fights per cycle:**

| Cycle | Boss ID | Boss title | Opponent profile ID |
|---|---|---|---|
| 1 | `wh-c1-boss` | The Wall | `marcus` (adapted - boss difficulty) |
| 2 | `wh-c2-boss` | The Passer | `diego` |
| 3 | `wh-c3-boss` | The Chain Passer | `yuki` |
| 4 | `wh-c4-boss` | The Pressure Player | `andre` |

**Final Tournament** - after Cycle 4 boss

| order_index | id | kind | title |
|---|---|---|---|
| 499 | `wh-final-tournament` | finalTournament | White Belt Championship |

Covers all 4 topics. Opponents: Marcus -> Diego -> Yuki -> Andre -> Coach Santos

### 2.4 Full `units` Table Row Ordering (White Belt v2)

```
order_index 100: wh-c1-theory        (miniTheory)
order_index 199: wh-c1-boss          (bossFight)
order_index 200: wh-c2-theory        (miniTheory)
order_index 299: wh-c2-boss          (bossFight)
order_index 300: wh-intermediate-tournament (intermediateTournament)
order_index 400: wh-c3-theory        (miniTheory)
order_index 499: wh-c3-boss          (bossFight)
order_index 500: wh-c4-theory        (miniTheory)
order_index 599: wh-c4-boss          (bossFight)
order_index 600: wh-final-tournament (finalTournament)
```

Total unit rows for White Belt: 10 (down from 74 in v1). The learning content is no longer split into 10-lesson nodes -- it lives as questions tagged by topic + sub_topic in the `questions` table.

### 2.5 Migration from v1 to v2

**Old unit rows to delete:**
- All unit rows with `cycle_number IN (1,2,3,4)` and `kind = 'lesson'`
- All `kind = 'mixedReview'` and `kind = 'miniExam'` rows
- Keep: `kind = 'bossFight'`, `kind = 'intermediateTournament'`, `kind = 'finalTournament'`, `kind = 'miniTheory'`

**User progress handling:**
- `unit_progress` rows for deleted lesson units: mark as migrated (set a `migrated_to_v2 = true` flag, or simply delete)
- Existing `user_question_stats`: kept as-is, `strength` added via migration (Section 1.1)
- Users who completed Cycle 1 in v1: their `closed_guard` questions have stats, adaptive algorithm will treat those as "seen" and pull from weak/refresh buckets

**Migration SQL:**

```sql
-- Backup before running
CREATE TABLE units_v1_backup AS SELECT * FROM units;
CREATE TABLE unit_progress_v1_backup AS SELECT * FROM unit_progress;

-- Remove old lesson-type units
DELETE FROM units
WHERE kind IN ('lesson', 'mixedReview', 'miniExam', 'characterMoment')
  AND belt = 'white';

-- Update existing boss/tournament/theory units to new order_index values
UPDATE units SET order_index = 100 WHERE id = 'wh-c1-theory';
UPDATE units SET order_index = 199 WHERE id = 'wh-c1-boss';
-- etc. for each kept unit

-- Clean up unit_progress for deleted units
DELETE FROM unit_progress
WHERE unit_id NOT IN (SELECT id FROM units);
```

---

## Section 3: Question Generation Plan

### 3.1 Target Question Counts

| Topic | Sub-topics | Questions each | Total |
|---|---|---|---|
| `closed_guard` | 4 | 18-20 | ~75 |
| `guard_passing` | 4 | 16-18 | ~67 |
| `side_control_mount` | 5 | 13-15 | ~70 |
| `back_control` | 4 | 14-16 | ~60 |
| **Total new questions** | | | **~272** |

Existing questions in DB that have `topic` set: ~723. Many of these are `mcq3` (battle questions). The v2 session algorithm excludes `mcq3`, so the effective pool per topic is smaller. The 272 new questions supplement this.

### 3.2 Format Distribution per Topic (target)

| Format | % of questions | Notes |
|---|---|---|
| `mcq4` | 45% | Primary format for technique decisions |
| `mcq2` | 25% | Yes/no situational judgment |
| `trueFalse` | 20% | Principle-based statements |
| `fillBlank` | 10% | Key terminology and cues |

Difficulty distribution: 40% difficulty-1, 40% difficulty-2, 20% difficulty-3.

### 3.3 Technique Coverage per Cycle

**Cycle 1 (closed_guard) - Key techniques to generate questions for:**

| Sub-topic | PSBJJA # | Question examples |
|---|---|---|
| posture_defense | 58: Posture in Guard | "Opponent is posting their hand on your stomach and sitting tall. What's the most important thing to disrupt?" [break their posture / go for submission / hold guard / bridge] |
| posture_defense | 59: Choke Protection | "You're in closed guard top. Opponent grabs your collar with both hands. First priority?" |
| guard_attacks | 63: Cross Choke | "You set your first grip on the far collar. Before you finish the cross choke, you must _____" |
| guard_attacks | 65: Triangle | "You attempt a triangle. Opponent stacks you. What saved the submission?" |
| sweeps | 70: Scissor Sweep | "You attempt a scissor sweep but opponent doesn't fall. Most likely reason:" |
| guard_breaks | 68: Kneeling Pass | "You're kneeling in opponent's guard. Your elbows should be:" |

### 3.4 Generation Approach

Use `scripts/generate_questions.py` (Claude API) with this prompt template per sub-topic:

```
Topic: {sub_topic_title}
Techniques: {psbjja_technique_list}
Key cues: {key_cues_from_curriculum}
Common mistakes: {common_mistakes_list}

Generate {N} questions about this sub-topic.
- Format distribution: {format_distribution}
- Difficulty: {difficulty_distribution}
- Each question must test decision-making, NOT technique name recall
- Focus on: "what do you do here" not "what is this called"
- Include technique_ref: "#58", "#70" etc. in each question JSON
- Include sub_topic: "{sub_topic_slug}"
- All questions in English (language: "en")
```

### 3.5 Quality Verification

Before inserting generated questions:
1. Automated check: no duplicate prompts within same sub-topic (cosine similarity > 0.85 = reject)
2. Manual review: sample 20% of each batch
3. Format check: all `mcq4` have exactly 4 options, all `trueFalse` have no options array
4. Answer sanity: run Claude on each question to verify `correct_answer` is actually correct

---

## Section 4: Session Algorithm

### 4.1 Strength Calculation

Strength is a value from 0-100 representing how well the user knows a specific question.

**Initial value:** 0 (never seen)

**Changes per answer event:**
- Correct answer, first attempt: `strength += 20`
- Correct answer, second attempt (after a hint or re-show): `strength += 10`
- Wrong answer: `strength -= 30`
- Floor at 0, ceiling at 100

**Time decay (passive):**
- Applied once per app open via `apply_strength_decay` RPC
- Every 3 days without seeing a question: `strength -= 5`
- Only decays questions with `strength > 0`
- Never decays below 0
- Example: a question at strength 60 not seen for 9 days drops to 45

**Sub-topic average strength:**
- Computed client-side: average `strength` of all questions in that sub-topic that the user has seen at least once
- Questions never seen contribute 0 to the average only when computing unlock gates
- Sub-topic unlock gate: previous sub-topic avg strength >= 60

### 4.2 Session Composition Logic

A session is 8-10 questions (default 9) composed from three buckets:

```
Bucket 1 (60% = ~5 questions): New questions from current active sub-topic
Bucket 2 (25% = ~2-3 questions): Questions with strength < 50, any sub-topic in current topic
Bucket 3 (15% = ~1-2 questions): Refresh from past topics (strength >= 50, ordered by oldest last_seen)
```

**What is "current active sub-topic":**
- The first sub-topic in the cycle where avg strength < 60
- If all sub-topics >= 60: the one with lowest avg strength (reinforcement before boss)
- If boss is unlocked (all >= 70): bucket 1 becomes all sub-topics, focus is refresh

**Edge cases:**
- Not enough new questions (sub-topic exhausted): fill remainder from Bucket 2
- Not enough weak questions: fill from more new questions or reduce session size to 6 minimum
- First session ever (no stats): 100% new questions, all from sub-topic 1

**Algorithm returns ordered list:** Bucket 1 questions first, interspersed with Bucket 2, Bucket 3 at end. The client shuffles within each bucket but keeps bucket ordering.

### 4.3 Theory Card Trigger Logic

Theory cards appear inline during sessions when the user first encounters a new sub-topic in their current session.

**Trigger condition:** A question from `sub_topic = X` appears in the session, AND the user has never seen any question from sub-topic X before (based on stats).

**Trigger point:** Before the first question from that sub-topic in the session.

**Theory card content:** From `MiniTheoryData` stored in a separate `mini_theory_cards` table (or as JSONB on a `sub_topic_theory` column in a new table). One theory card per sub-topic.

**New table `sub_topic_theory`:**

```sql
CREATE TABLE sub_topic_theory (
    id          TEXT PRIMARY KEY,    -- e.g. "cg-sweeps-theory"
    topic       TEXT NOT NULL,
    sub_topic   TEXT NOT NULL,
    belt_level  TEXT NOT NULL DEFAULT 'white',
    screens     JSONB NOT NULL,      -- array of MiniTheoryScreen objects
    button_label TEXT NOT NULL DEFAULT 'Got it',
    UNIQUE (topic, sub_topic, belt_level)
);
```

**Swift side:** `SessionComposition` includes an ordered list of `SessionItem`, where each item is either `.question(Question)` or `.theoryCard(MiniTheoryData)`. The `SessionEngine` renders them in order.

**Only shown once:** After the user taps through a theory card, mark `sub_topic_seen` in UserDefaults (keyed by `"theory_seen_\(topic)_\(subTopic)"`). On subsequent sessions, the theory card is skipped even if the sub-topic appears again.

### 4.4 Sub-topic Unlock Logic

Within a cycle, sub-topics unlock sequentially:

- Sub-topic 1: always unlocked when cycle starts
- Sub-topic N+1 unlocks when sub-topic N avg strength >= 60
- Boss unlocks when ALL sub-topics in the cycle have avg strength >= 70
- Boss "locks" again (temporarily) if any sub-topic drops below 50 (user must refresh)

**Client-side unlock evaluation:**

```swift
func subTopicUnlockState(for cycle: CycleProgress) -> [SubTopicState] {
    // Returns array where each element is .locked / .active / .mastered
    // Based on avg strength per sub-topic
}
```

**Boss unlock:**

```swift
func isBossUnlocked(cycleProgress: CycleProgress) -> Bool {
    cycleProgress.subTopics.allSatisfy { $0.avgStrength >= 70 }
}
```

### 4.5 First-Attempt Tracking

For the `+20` vs `+10` strength delta, the `SessionEngine` must track whether a question was answered correctly on the first attempt within the session.

Current `SessionEngine` tracks `answeredQuestions: [(questionId, wasWrong)]`. Extend this to:
`answeredQuestions: [(questionId: String, wasWrong: Bool, wasFirstAttempt: Bool)]`

The `first_attempt` flag is always `true` for the standard session flow (one attempt per question). It becomes `false` only if a future feature allows re-attempting within a session.

---

## Section 5: iOS Code Changes

### Task A: Database/Models

**Complexity: S**
**Depends on:** Nothing (pure model changes)

**Changes:**

**A1. `QuestionStat` struct** (in `AdaptiveQuestionSelector.swift`):
```swift
struct QuestionStat {
    let questionId: String
    let timesSeen: Int
    let timesWrong: Int
    let strength: Int        // NEW: 0-100
    let lastSeen: Date?      // NEW: for decay display
}
```

**A2. `RemoteQuestionStat` DTO** (in `SupabaseService.swift`):
```swift
struct RemoteQuestionStat: Decodable {
    let questionId: String
    let timesSeen: Int
    let timesWrong: Int
    let strength: Int        // NEW
    let lastSeen: Date?      // NEW

    enum CodingKeys: String, CodingKey {
        case questionId  = "question_id"
        case timesSeen   = "times_seen"
        case timesWrong  = "times_wrong"
        case strength
        case lastSeen    = "last_seen"
    }
}
```

**A3. New `SessionComposition` model** (new file `Core/SessionComposition.swift`):
```swift
struct SubTopicProgress {
    let slug: String           // "posture_defense"
    let title: String          // "Posture and Defense"
    let avgStrength: Int       // 0-100, computed from question stats
    let questionsSeen: Int
    let totalQuestions: Int
    let isUnlocked: Bool
    let isMastered: Bool       // avgStrength >= 70
}

struct CycleProgress {
    let cycleNumber: Int
    let topic: String
    let subTopics: [SubTopicProgress]
    var isBossUnlocked: Bool { subTopics.allSatisfy { $0.avgStrength >= 70 } }
    var isBossLocked: Bool { subTopics.any { $0.avgStrength < 50 } }
    var avgStrength: Int { subTopics.map(\.avgStrength).average }
}

enum SessionItem {
    case question(Question)
    case theoryCard(MiniTheoryData, subTopic: String)
}

struct SessionComposition {
    let items: [SessionItem]
    let topic: String
    let subTopic: String      // Primary sub-topic for this session
    var questions: [Question] { items.compactMap { if case .question(let q) = $0 { return q } else { return nil } } }
}
```

**Acceptance criteria:**
- `SessionComposition.questions` returns only question items (no theory cards)
- `CycleProgress.isBossUnlocked` returns true iff all sub-topics have avgStrength >= 70
- All new types are Sendable (Swift 6 concurrency)

---

### Task B: SupabaseService

**Complexity: M**
**Depends on:** Task A

**Changes:**

**B1. New method `fetchSessionComposition`:**
```swift
func fetchSessionComposition(
    userId: UUID,
    topic: String,
    beltLevel: String,
    language: String = "en",
    sessionSize: Int = 9
) async throws -> [Question]
```
Calls the `fetch_session_questions` RPC and returns the ordered question list. Handles the case where the RPC returns fewer than `sessionSize` questions (min 6).

**B2. New method `updateQuestionStrength`:**
```swift
func updateQuestionStrength(
    userId: UUID,
    questionId: String,
    wasWrong: Bool,
    firstAttempt: Bool = true
) async throws
```
Calls the `increment_question_strength` RPC. Replaces `upsertQuestionStats` for regular session questions. Keep `upsertQuestionStats` for battle questions (battle system unchanged).

**B3. New method `fetchSubTopicProgress`:**
```swift
func fetchSubTopicProgress(
    userId: UUID,
    topic: String,
    subTopics: [String],
    beltLevel: String
) async throws -> [String: Int]  // subTopic -> avgStrength
```
Fetches all `user_question_stats` for the given topic and computes avg strength per sub-topic using the `sub_topic` column on questions.

**B4. New method `fetchSubTopicTheory`:**
```swift
func fetchSubTopicTheory(
    topic: String,
    subTopic: String,
    beltLevel: String
) async throws -> MiniTheoryData?
```
Fetches from the new `sub_topic_theory` table.

**B5. `applyStrengthDecay` call on app launch:**
```swift
func triggerStrengthDecay(userId: UUID) async throws
```
Calls the `apply_strength_decay` RPC. Called once per app launch from `AppState.syncWithSupabase()`.

**Acceptance criteria:**
- `fetchSessionComposition` returns 6-9 questions, never empty if the topic has any questions in DB
- Fallback: if RPC fails, falls back to current `fetchQuestionsForSession` behavior (backward compat)
- All methods are actor-isolated (existing `actor SupabaseService` pattern maintained)

---

### Task C: SessionEngine Refactor

**Complexity: M**
**Depends on:** Task A, Task B

**Changes:**

**C1. Accept `[SessionItem]` instead of `[Question]`:**
```swift
init(items: [SessionItem], isBeltTest: Bool = false, coachIntro: String? = nil, streak: Int = 0)
```
Backward-compatible convenience init that wraps `[Question]` into `.question` items (for belt test, battle, etc.).

**C2. Theory card state:**
```swift
enum State: Equatable {
    case showingIntro
    case showingTheoryCard(MiniTheoryData, subTopic: String)  // NEW
    case answering
    case showingFeedback
    case completed
    case gameOver
}
```

**C3. Theory card advancement:**
```swift
func dismissTheoryCard() {
    guard case .showingTheoryCard = state else { return }
    // Mark this sub-topic theory as seen in UserDefaults
    UserDefaults.standard.set(true, forKey: "theory_seen_\(currentSubTopicSlug)")
    advanceToNextItem()
}
```

**C4. Strength-aware answer tracking:**
```swift
private(set) var answeredQuestions: [(questionId: String, wasWrong: Bool, firstAttempt: Bool)] = []
```

**C5. `currentItem` computed property:**
```swift
var currentItem: SessionItem? {
    guard currentIndex < items.count else { return nil }
    return items[currentIndex]
}
// Keep currentQuestion for backward compat:
var currentQuestion: Question? {
    if case .question(let q) = currentItem { return q }
    return nil
}
```

**C6. `progress` computed property updates:**
- Progress bar should advance only on question completion, not theory cards
- `answeredCount` counts only questions, not theory cards shown

**Acceptance criteria:**
- Existing belt test flow (passing `[Question]` array) still compiles and works
- Theory card appears when `SessionItem.theoryCard` encountered in item list
- `advance()` skips theory cards that were already seen (UserDefaults check)
- `answeredQuestions` only contains question entries, not theory card entries

---

### Task D: AppState

**Complexity: M**
**Depends on:** Task B, Task C

**Changes:**

**D1. New published property for cycle progress:**
```swift
@Published private(set) var cycleProgress: [CycleProgress] = []
```

**D2. New method `fetchSessionForTopic`:**
```swift
func fetchSessionForTopic(_ topic: String) async -> SessionComposition
```
- Calls `SupabaseService.fetchSessionComposition`
- Inserts theory cards at the right positions
- Checks UserDefaults for already-seen theory cards (skip if seen)
- Returns `SessionComposition` with interleaved theory cards
- Fallback: if no remote data, return empty composition (HomeView shows offline state)

**D3. New method `fetchCycleProgress`:**
```swift
func fetchCycleProgress() async
```
- Fetches sub-topic stats for all 4 topics
- Computes `CycleProgress` array
- Sets `self.cycleProgress`
- Called on app launch and after each session completes

**D4. Update `applySessionResult` to call strength update:**
```swift
func applySessionResult(_ result: SessionResult, answers: [(questionId: String, wasWrong: Bool, firstAttempt: Bool)]) {
    // Existing XP + hearts logic unchanged
    // NEW: call updateQuestionStrength for each answer
    guard let userId = remoteUserId else { return }
    Task {
        for answer in answers {
            try? await SupabaseService.shared.updateQuestionStrength(
                userId: userId,
                questionId: answer.questionId,
                wasWrong: answer.wasWrong,
                firstAttempt: answer.firstAttempt
            )
        }
        // After stats updated, refresh cycle progress
        await fetchCycleProgress()
    }
}
```

**D5. Boss unlock check (replaces unit-chain lock logic for cycle topics):**
```swift
func isBossAccessible(cycleNumber: Int) -> Bool {
    guard let cycle = cycleProgress.first(where: { $0.cycleNumber == cycleNumber }) else { return false }
    return cycle.isBossUnlocked
}
```

**D6. Strength decay on launch:**
In `syncWithSupabase()`, after ensuring remote user:
```swift
if let userId = remoteUserId {
    try? await SupabaseService.shared.triggerStrengthDecay(userId: userId)
}
```

**D7. Developer testing mode properties:**
```swift
#if DEBUG
var devModeEnabled: Bool {
    get { defaults.bool(forKey: "devModeEnabled") }
    set { defaults.set(newValue, forKey: "devModeEnabled") }
}
func devJumpToCycle(_ cycle: Int) { /* set cycleProgress to show cycle as unlocked */ }
func devSetStrength(_ strength: Int, forTopic topic: String) async { /* write stats to Supabase */ }
func devResetTopicProgress(_ topic: String) async { /* delete stats from Supabase */ }
#endif
```

**Acceptance criteria:**
- `cycleProgress` is populated after `syncWithSupabase` completes
- `applySessionResult` triggers strength updates and then refreshes `cycleProgress`
- Boss unit's `isLocked` state is driven by `isBossAccessible(cycleNumber:)` not by the old chain logic
- All `@Published` changes happen on `@MainActor`

---

### Task E: HomeView

**Complexity: M**
**Depends on:** Task D

**Changes:**

**E1. Sub-topic progress bars:**

Replace the 74-node vertical scroll with a compact cycle view:

```
CLOSED GUARD                           [Cycle 1 header]
  Posture & Defense   ████████░░  80%
  Guard Attacks       █████░░░░░  50%  <- current
  Sweeps              ███░░░░░░░  30%
  Guard Breaks        [LOCKED]    --

  [START SESSION] button

  [THE WALL]  <- boss node, locked/unlocked based on isBossUnlocked
```

Each cycle section collapses/expands. Current active cycle is expanded by default.

**E2. Session start button:**

The "Start Session" button replaces tapping a specific lesson node. It calls `AppState.fetchSessionForTopic(cycle.topic)` and presents `SessionView` with the composed session.

**E3. Boss node tap:**

Boss node tap checks `AppState.isBossAccessible(cycleNumber:)`. If accessible, presents `BattlePreviewView` (existing). If locked, shows a tooltip: "Reach 70% in all sub-topics to unlock The Wall."

**E4. Tournament node placement:**

After Cycle 2 boss, show the intermediate tournament node. After Cycle 4 boss, show the final tournament node. These are existing unit rows; the HomeView just needs to render them in their correct position between cycles.

**E5. Developer mode button (DEBUG only):**

Hidden button accessible via long-press on the belt icon in the header. Opens a `DevModeSheet` (see Task G for detail).

**Acceptance criteria:**
- Progress bars update after each session without requiring full app restart
- Boss node is visually distinct when locked vs unlocked
- Tapping "Start Session" on an exhausted topic (all questions seen, all strength >= 70) still works (algorithm falls back to weak/refresh buckets)
- Tournament node appears between the correct cycles

---

### Task F: Inline Theory Cards

**Complexity: S**
**Depends on:** Task C

**Changes:**

**F1. `InlineTheoryCardView`** (new view, `Session/InlineTheoryCardView.swift`):

Reuses the existing `MiniTheoryScreen` model. Renders identically to `MiniTheoryView` (swipeable screens) but is shown inline within `SessionView` as a full-screen overlay.

```swift
struct InlineTheoryCardView: View {
    let data: MiniTheoryData
    let subTopicSlug: String
    let onDismiss: () -> Void
    // Multi-screen swipe: currentScreen: Int, PageView-style
}
```

**F2. `SessionView` updates:**

`SessionView` observes `engine.state`. Add a new branch:
```swift
case .showingTheoryCard(let data, let subTopic):
    InlineTheoryCardView(data: data, subTopic: subTopic) {
        engine.dismissTheoryCard()
    }
```

This is a full-screen overlay (`.fullScreenCover` or `.overlay` with z-index) that appears over the question area.

**F3. Theory card "only once" guarantee:**

`SessionEngine.dismissTheoryCard()` writes to UserDefaults before advancing. `SessionEngine.advanceToNextItem()` checks UserDefaults before stopping on a theory card:
```swift
private func advanceToNextItem() {
    currentIndex += 1
    while currentIndex < items.count {
        if case .theoryCard(_, let slug) = items[currentIndex] {
            if UserDefaults.standard.bool(forKey: "theory_seen_\(slug)") {
                currentIndex += 1  // skip already-seen theory
                continue
            }
        }
        break
    }
    // Update state based on new currentItem
}
```

**Acceptance criteria:**
- Theory card appears the first time a new sub-topic is encountered in a session
- Theory card is skipped if sub-topic was already introduced in a prior session
- Tapping "Got it" on the theory card transitions to the first question of that sub-topic
- Theory card does not appear in belt test sessions (belt test uses `[Question]` array directly)

---

### Task G: Developer Testing Mode

**Complexity: S**
**Depends on:** Task D, Task E

**Changes:**

`DevModeSheet.swift` (DEBUG only, excluded from release via `#if DEBUG`):

```swift
#if DEBUG
struct DevModeSheet: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        // Toggle dev mode on/off
        // Jump to cycle (1/2/3/4)
        // Jump to boss fight for any cycle
        // Jump to intermediate tournament
        // Jump to final tournament
        // Set topic strength (slider: 0-100, applies to all questions in topic)
        // Reset topic progress (delete all stats for a topic)
        // Force theory card to re-appear (clear UserDefaults key)
        // Show raw cycle progress data (debug dump)
    }
}
#endif
```

**DevMode actions and their implementations:**

| Action | Implementation |
|---|---|
| Jump to cycle N | `appState.devJumpToCycle(N)` - sets fake cycleProgress that shows cycles 1..N-1 as completed |
| Set topic strength | `appState.devSetStrength(value, forTopic:)` - bulk-updates all user_question_stats for topic |
| Reset topic | `appState.devResetTopicProgress(topic:)` - DELETE from user_question_stats WHERE topic = X |
| Force theory | `UserDefaults.standard.removeObject(forKey: "theory_seen_\(topic)_\(subTopic)")` |
| Skip to belt test | Sets all cycles to completed in `cycleProgress` |

**Access:** Long-press (2 seconds) on the belt icon in HomeView header. Only visible in `DEBUG` builds.

**Acceptance criteria:**
- DevModeSheet only appears in DEBUG builds (compile-time exclusion)
- "Jump to cycle" shows the correct cycle as active in HomeView without completing all prior questions
- "Reset topic" causes the next session to contain all-new questions from that topic
- DevMode state does not persist between app launches (resets to real Supabase state on next sync)

---

### Task H: Localization

**Complexity: M**
**Depends on:** Task E, Task F

**Changes:**

**H1. New L10n keys needed:**

```swift
// MARK: Home (v2 additions)
enum Home {
    // existing keys stay
    static var startSession: String       { l("home.start_session") }
    static var strengthLabel: String      { l("home.strength_label") }  // "Strength"
    static var lockedSubTopic: String     { l("home.locked") }
    static var bossLockedHint: String     { l("home.boss_locked_hint") }   // "Reach 70% in all topics to unlock"
    static var bossUnlocked: String       { l("home.boss_unlocked") }
    static func cycleTitle(_ n: Int) -> String { lf("home.cycle_title", n) }
}

// MARK: Cycle titles
enum CycleTitle {
    static var closedGuard: String     { l("cycle.closed_guard") }
    static var guardPassing: String    { l("cycle.guard_passing") }
    static var sideControlMount: String { l("cycle.side_control_mount") }
    static var backControl: String     { l("cycle.back_control") }
}

// MARK: Sub-topic titles
enum SubTopicTitle {
    // Closed Guard
    static var postureDefense: String  { l("subtopic.posture_defense") }
    static var guardAttacks: String    { l("subtopic.guard_attacks") }
    static var sweeps: String          { l("subtopic.sweeps") }
    static var guardBreaks: String     { l("subtopic.guard_breaks") }
    // Guard Passing
    static var postureInGuard: String  { l("subtopic.posture_in_guard") }
    static var kneelingPass: String    { l("subtopic.kneeling_pass") }
    static var standingPass: String    { l("subtopic.standing_pass") }
    static var openGuardPassing: String { l("subtopic.open_guard_passing") }
    // Side Control + Mount
    static var sideControlDefense: String  { l("subtopic.side_control_defense") }
    static var sideControlAttacks: String  { l("subtopic.side_control_attacks") }
    static var mountTransitions: String    { l("subtopic.mount_transitions") }
    static var mountDefense: String        { l("subtopic.mount_defense") }
    static var mountAttacks: String        { l("subtopic.mount_attacks") }
    // Back Control
    static var backDefense: String         { l("subtopic.back_defense") }
    static var backControlMaintain: String { l("subtopic.back_control_maintain") }
    static var backSubmissions: String     { l("subtopic.back_submissions") }
    static var backCombinations: String    { l("subtopic.back_combinations") }
}

// MARK: Theory Card
enum TheoryCard {
    static var dismissButton: String    { l("theory_card.got_it") }
    static var swipeHint: String        { l("theory_card.swipe_hint") }
}

// MARK: Session (v2 additions)
enum Session {
    // existing keys stay
    static var newTopicLabel: String    { l("session.new_topic") }     // "New topic unlocked"
    static var strengthGained: String   { l("session.strength_gained") } // "+20 strength"
    static var weakQuestion: String     { l("session.weak_question") }  // "Reinforcing weak area"
}
```

**H2. Localizable.strings (EN):**

```
"home.start_session" = "Start Session";
"home.strength_label" = "Strength";
"home.locked" = "Locked";
"home.boss_locked_hint" = "Reach 70%% in all topics to unlock";
"home.boss_unlocked" = "Challenge the Boss";
"home.cycle_title" = "Cycle %d";
"cycle.closed_guard" = "Closed Guard";
"cycle.guard_passing" = "Guard Passing";
"cycle.side_control_mount" = "Side Control & Mount";
"cycle.back_control" = "Back Control";
"subtopic.posture_defense" = "Posture & Defense";
"subtopic.guard_attacks" = "Guard Attacks";
"subtopic.sweeps" = "Sweeps";
"subtopic.guard_breaks" = "Guard Breaks";
"subtopic.posture_in_guard" = "Posture in Guard";
"subtopic.kneeling_pass" = "Kneeling Pass";
"subtopic.standing_pass" = "Standing Pass";
"subtopic.open_guard_passing" = "Open Guard Passing";
"subtopic.side_control_defense" = "Side Control Defense";
"subtopic.side_control_attacks" = "Side Control Attacks";
"subtopic.mount_transitions" = "Getting to Mount";
"subtopic.mount_defense" = "Mount Escapes";
"subtopic.mount_attacks" = "Mount Attacks";
"subtopic.back_defense" = "Back Escape";
"subtopic.back_control_maintain" = "Maintaining Back";
"subtopic.back_submissions" = "Back Submissions";
"subtopic.back_combinations" = "Combinations";
"theory_card.got_it" = "Got it";
"theory_card.swipe_hint" = "Swipe to continue";
"session.new_topic" = "New topic";
"session.strength_gained" = "+%d strength";
"session.weak_question" = "Reinforcing";
```

**H3. Localizable.strings (ES):**

Generated via existing `scripts/generate_es_translations.py`. The script takes the EN file as input and outputs ES. All new keys above are added to the EN file first, then the ES file is regenerated.

**H4. `unit_translations` table:**

New rows needed for the 10 new unit nodes (in ES, PT future):

```sql
-- Example for one unit (wh-c1-theory, Spanish)
INSERT INTO unit_translations (unit_id, locale, title, description, mini_theory_content)
VALUES (
    'wh-c1-theory',
    'es',
    'Guardia Cerrada',
    'Aprende a dominar desde la guardia cerrada.',
    '{"type": "cycleIntro", "screens": [...], "buttonLabel": "Entendido"}'
);
```

**H5. Adding a new language (future PT/FR):**

Steps to add Portuguese in the future:
1. Copy `en.lproj/Localizable.strings` to `pt.lproj/Localizable.strings`
2. Run `generate_es_translations.py --lang pt` (adjust target language)
3. Add `unit_translations` rows with `locale = 'pt'` for all unit IDs
4. Add `language = 'pt'` rows in `questions` table (or generate via script)
5. In `LanguageManager`, add `"pt"` to supported codes list
6. Done - app auto-picks up new language at runtime

---

## Section 6: Testing Plan

### 6.1 Unit Tests

**File: `AdaptiveQuestionSelectorTests.swift` (extend existing)**

```swift
// Test strength-based selection
func test_selectPrioritizesWeakOverSeen() {
    // Given: questions with varying strength values
    // When: select called
    // Then: questions with strength < 50 come before strength >= 50
}

func test_selectExcludesCorrectStrengthBucket() {
    // Confirm bucket 1 is from unseen, bucket 2 from weak, bucket 3 from refresh
}
```

**File: `SessionCompositionTests.swift` (new)**

```swift
func test_compositionRespects60_25_15Split() {
    // Given: 20 new questions, 10 weak, 10 refresh available
    // When: compose 9-question session
    // Then: ~5 new, ~2 weak, ~2 refresh (allow +/-1 rounding)
}

func test_compositionFallsBackWhenInsufficientNew() {
    // Given: 2 new questions available, 10 weak
    // When: compose 9-question session
    // Then: 2 new + fill from weak = 9 total (or minimum 6)
}

func test_compositionHandlesFirstEverSession() {
    // Given: user has no stats (empty user_question_stats)
    // When: compose session
    // Then: all questions are from bucket 1 (new)
}
```

**File: `CycleProgressTests.swift` (new)**

```swift
func test_bossUnlockRequires70PercentAllSubTopics() {
    let progress = CycleProgress(
        cycleNumber: 1,
        topic: "closed_guard",
        subTopics: [
            SubTopicProgress(slug: "posture_defense", avgStrength: 75, ...),
            SubTopicProgress(slug: "guard_attacks", avgStrength: 65, ...),  // < 70
        ]
    )
    XCTAssertFalse(progress.isBossUnlocked)
}

func test_subTopicUnlockAt60() {
    // Given: posture_defense avgStrength = 60
    // Then: guard_attacks.isUnlocked = true
}

func test_strengthDecayFormula() {
    // strength = 60, days_without_seeing = 9 (3 decay periods)
    // Expected: 60 - (5 * 3) = 45
}
```

**File: `SessionEngineTests.swift` (extend existing)**

```swift
func test_engineAdvancesPastTheoryCard() {
    // Given: session with [theoryCard, question, question]
    // When: engine starts
    // Then: state is .showingTheoryCard (not .answering)
}

func test_engineSkipsSeenTheoryCard() {
    // Given: UserDefaults has "theory_seen_cg_sweeps" = true
    // And: session has [theoryCard(subTopic: "cg_sweeps"), question]
    // When: engine initializes
    // Then: engine starts at the question, theory card is skipped
}

func test_engineTracksFirstAttemptFlag() {
    // Given: standard session
    // When: submitAnswer called
    // Then: answeredQuestions contains firstAttempt: true
}
```

### 6.2 Integration Tests

**File: `SupabaseSessionIntegrationTests.swift` (new, requires test Supabase instance)**

```swift
func test_fetchSessionCompositionReturnsMixedBuckets() async throws {
    // Requires: test user with some question stats seeded
    // When: fetchSessionComposition called
    // Then: result contains a mix of new and previously-seen questions
}

func test_strengthUpdatePersistsCorrectly() async throws {
    // When: updateQuestionStrength called with wasWrong: false
    // Then: user_question_stats.strength increases by 20
}

func test_languageSwitchAppliesCorrectly() async throws {
    // When: fetchSubTopicTheory called with language: "es"
    // Then: returned MiniTheoryData has Spanish text
}
```

### 6.3 Developer Testing Shortcuts (Manual QA)

All accessible via `DevModeSheet` (long-press belt icon, DEBUG only):

| Test scenario | DevMode action | Expected result |
|---|---|---|
| First session ever | Reset all topic progress | All questions appear as new, theory card shown |
| Boss unlock | Set all sub-topic strength to 75 | Boss node unlocks immediately |
| Boss relocking | Set any sub-topic strength to 45 | Boss node becomes inaccessible |
| Theory card re-show | "Force theory card" for sub-topic | Theory card appears again on next session |
| Intermediate tournament | Jump to post-cycle-2 | Tournament node is accessible |
| Final tournament | Jump to post-cycle-4 | Final tournament node is accessible |
| Full decay | Set last_seen to 30 days ago (manual SQL) | strength drops significantly next launch |
| Language switch | Switch to ES in profile | All new cycle/sub-topic titles appear in Spanish |

---

## Section 7: Localization Plan

### 7.1 Complete L10n Key Table

| Key | EN value | Notes |
|---|---|---|
| `home.start_session` | "Start Session" | CTA button in HomeView |
| `home.locked` | "Locked" | Locked sub-topic label |
| `home.boss_locked_hint` | "Reach Solid in all topics to unlock" | Tooltip on locked boss |
| `home.boss_unlocked` | "Challenge the Boss" | CTA on unlocked boss node |
| `strength.weak` | "Weak" | strength 0-49% |
| `strength.learning` | "Learning" | strength 50-69% |
| `strength.solid` | "Solid" | strength 70-89% |
| `strength.mastered` | "Mastered" | strength 90-100% |
| `cycle.closed_guard` | "Closed Guard" | Cycle 1 header |
| `cycle.guard_passing` | "Guard Passing" | Cycle 2 header |
| `cycle.side_control_mount` | "Side Control & Mount" | Cycle 3 header |
| `cycle.back_control` | "Back Control" | Cycle 4 header |
| `subtopic.posture_defense` | "Posture & Defense" | |
| `subtopic.guard_attacks` | "Guard Attacks" | |
| `subtopic.sweeps` | "Sweeps" | |
| `subtopic.guard_breaks` | "Guard Breaks" | |
| `subtopic.posture_in_guard` | "Posture in Guard" | |
| `subtopic.kneeling_pass` | "Kneeling Pass" | |
| `subtopic.standing_pass` | "Standing Pass" | |
| `subtopic.open_guard_passing` | "Open Guard Passing" | |
| `subtopic.side_control_defense` | "Side Control Defense" | |
| `subtopic.side_control_attacks` | "Side Control Attacks" | |
| `subtopic.mount_transitions` | "Getting to Mount" | |
| `subtopic.mount_defense` | "Mount Escapes" | |
| `subtopic.mount_attacks` | "Mount Attacks" | |
| `subtopic.back_defense` | "Back Escape" | |
| `subtopic.back_control_maintain` | "Maintaining Back" | |
| `subtopic.back_submissions` | "Back Submissions" | |
| `subtopic.back_combinations` | "Combinations" | |
| `theory_card.got_it` | "Got it" | Theory card dismiss button |
| `theory_card.swipe_hint` | "Swipe to continue" | Multi-screen hint |
| `session.strength_gained` | "+%d strength" | String format with Int |
| `session.weak_question` | "Reinforcing" | Badge on weak-bucket questions |
| `session.new_topic` | "New topic" | Badge on first question of new sub-topic |

### 7.2 ES Translation Strategy

1. Add all new EN keys to `en.lproj/Localizable.strings`
2. Run: `python3 scripts/generate_es_translations.py`
3. Review output (spot-check BJJ terminology: "guard" = "guardia", "sweep" = "barrida", "submission" = "sumision")
4. The script uses Claude API - provide custom glossary for BJJ terms to prevent generic translations

**BJJ terminology override list for ES:**
```
guard -> guardia
sweep -> barrida (not "barrer")
submission -> sumisión
mount -> montada
side control -> control lateral
back control -> control de espalda
posture -> postura
base -> base
```

### 7.3 Adding PT, FR in the Future

Total time estimate: 1 day per language.

Steps:
1. Create `pt.lproj/Localizable.strings` - copy EN, run generate script with `--lang pt`
2. Add `pt` to `LanguageManager.supportedCodes: [String]`
3. Run a SQL script to duplicate all `unit_translations` rows from `locale = 'es'` with `locale = 'pt'`, then bulk-translate via Claude API
4. Generate PT questions: run `generate_questions.py --lang pt` which adds `language = 'pt'` rows to `questions` table
5. Test: switch language in app, verify all strings appear in PT

No Swift code changes needed after step 2 - the architecture already supports arbitrary locales.

---

## Section 8: Rollout Order

### 8.1 Dependency Graph

```
Task A (Models)
    |
    +---> Task B (SupabaseService)
    |         |
    |         +---> Task C (SessionEngine)
    |                   |
    |                   +---> Task F (Inline Theory Cards)
    |
    +---> Task D (AppState)
              |
              +---> Task E (HomeView)
              |
              +---> Task G (Dev Testing Mode)

Task H (Localization) -- can start in parallel after Task A
```

Database changes (Section 1) must be applied before Task B is implemented.

### 8.2 Sprint Breakdown

**Sprint 0 (pre-code) - 1 day:**
- Apply all SQL migrations from Section 1 to Supabase
- Seed new unit rows (10 rows for White Belt v2)
- Run question generation for Cycle 1 (closed_guard) - enough to test
- Write `sub_topic_theory` entries for Cycle 1

**Sprint 1 (foundation) - can be done in one session:**
- Task A: Models and DTOs
- Write tests for `CycleProgress`, `SubTopicProgress`, `SessionComposition`
- Verify tests pass

**Sprint 2 (backend wiring):**
- Task B: SupabaseService methods
- Write integration tests (with Supabase test environment)
- Task C: SessionEngine refactor
- Write/extend SessionEngine tests

**Sprint 3 (UI and app layer):**
- Task D: AppState
- Task E: HomeView (sub-topic progress bars)
- Task F: Inline theory cards
- Manual testing via DevMode (Task G can be a stub at this point)

**Sprint 4 (polish and localization):**
- Task G: Full DevModeSheet
- Task H: All new L10n keys, ES generation
- Full regression test: existing belt test, battle, tournament flows unchanged

**Sprint 5 (content):**
- Generate and seed questions for Cycles 2, 3, 4
- Generate `sub_topic_theory` content for all 16 sub-topics
- Add ES translations for all new unit content

### 8.3 Complexity Estimates

| Task | Complexity | Notes |
|---|---|---|
| A: Models | S | Pure struct additions, no network |
| B: SupabaseService | M | 5 new methods, RPC calls |
| C: SessionEngine | M | State machine extension, backward compat required |
| D: AppState | M | New published props, async coordination |
| E: HomeView | M | Significant UI change, progress bar layout |
| F: Inline Theory Cards | S | Reuses existing MiniTheoryScreen model |
| G: Developer Testing | S | DEBUG-only, no production impact |
| H: Localization | M | ~25 new keys, ES generation, DB rows |
| DB migrations | S | SQL only, no Swift |
| Question generation | L | ~272 questions, quality review required |
| `sub_topic_theory` content | M | 16 theory cards, coach voice required |

### 8.4 Open Questions (Decisions Needed)

1. **Old unit_progress rows:** Should we preserve v1 `unit_progress` for users who completed Cycle 1 lessons, or reset them? Recommendation: reset - the lesson unit IDs no longer exist, and user's actual knowledge is in `user_question_stats` which persists.

2. **Session size on weak-question-only sessions:** If a user has mastered all new questions in a sub-topic but has 8 weak questions, should the session be all 8 weak? Or should it cap at the standard 8-10? Recommendation: cap at 9, accept the 60/25/15 buckets may not sum exactly.

3. **Theory card timing within a session:** If bucket 1 contains questions from two different sub-topics (first sub-topic is exhausted, algorithm pulls from next), should TWO theory cards appear? Recommendation: yes, but limit to 2 max per session. If a third sub-topic appears, skip its theory card.

4. **Strength display on HomeView:** DECIDED - use label tiers from v2 (not numeric). Four tiers: Weak (0-49%), Learning (50-69%), Solid (70-89%), Mastered (90-100%). Display the label instead of raw percentage. Add L10n keys for all four labels.

5. **Migration cutover timing:** Should v2 be a breaking update (old users see different curriculum) or gradual (v2 on new installs, v1 on existing)? Recommendation: breaking update. The curriculum change is intentional and `user_question_stats` data transfers cleanly.

6. **Cycle header localization in `units` table:** The cycle titles (Closed Guard, Guard Passing, etc.) are set in Supabase `units.title`. Should these be in English in the DB and translated via `unit_translations`? Recommendation: yes, keep DB in English, translate via existing `unit_translations` mechanism.

---

## Appendix: Files Changed Summary

| File | Change type | Task |
|---|---|---|
| `Core/AdaptiveQuestionSelector.swift` | Modify `QuestionStat` struct | A |
| `Core/Models.swift` | No changes to existing types | - |
| `Core/SessionComposition.swift` | New file | A |
| `Core/SupabaseService.swift` | Add 5 new methods | B |
| `Session/SessionEngine.swift` | Extend `State`, `init`, tracking | C |
| `Session/InlineTheoryCardView.swift` | New file | F |
| `Session/SessionView.swift` | Handle `.showingTheoryCard` state | F |
| `Core/AppState.swift` | New published props, new methods | D |
| `Home/HomeView.swift` | Replace node chain with cycle+progress bars | E |
| `Core/L10n.swift` | Add ~25 new string accessors | H |
| `en.lproj/Localizable.strings` | Add ~25 new EN strings | H |
| `es.lproj/Localizable.strings` | Add ~25 new ES strings (generated) | H |
| `DevMode/DevModeSheet.swift` | New file (DEBUG only) | G |
| `scripts/schema.sql` | Add new SQL (documentation) | - |

**Test files changed:**

| File | Change type | Task |
|---|---|---|
| `Tests/AdaptiveQuestionSelectorTests.swift` | Extend with strength tests | A |
| `Tests/SessionEngineTests.swift` | Extend with theory card tests | C |
| `Tests/SessionCompositionTests.swift` | New file | A |
| `Tests/CycleProgressTests.swift` | New file | A |
| `Tests/SupabaseSessionIntegrationTests.swift` | New file | B |
