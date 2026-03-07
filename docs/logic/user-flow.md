# BJJ Mind — User Flow
> Complete map of every possible user path through the app.

---

## First Launch Flow

```mermaid
flowchart TD
    A([App Open]) --> B[Welcome Screen]
    B -->|Get Started| C[Belt Select]
    B -->|I have account| AUTH[Login]
    AUTH --> HOME

    C --> D[Problem Select]
    D --> E[Aha Moment]
    E --> F[First Micro-Round]
    F --> G{Answer}
    G -->|Correct| H[Feedback Correct]
    G -->|Wrong| I[Feedback Wrong]
    H --> J{More questions?}
    I --> J
    J -->|Yes| F
    J -->|No| K[Session Summary]
    K --> HOME[Home Screen]
```

---

## Return User — Daily Session

```mermaid
flowchart TD
    HOME[Home Screen] -->|Tap active node / Start| SESSION

    subgraph SESSION [Session Loop]
        Q[Question Screen] --> ANS{Answer}
        ANS -->|Correct| FC[Feedback Correct]
        ANS -->|Wrong + hearts left| FW[Feedback Wrong]
        ANS -->|Wrong + no hearts| OOH[Out of Hearts]
        FC --> NEXT{More?}
        FW --> NEXT
        NEXT -->|Yes| Q
        NEXT -->|No| SUMMARY
    end

    OOH -->|Wait / Practice| HOME
    SUMMARY[Session Summary] --> XP_ANIM[XP Animation]
    XP_ANIM --> STRIPE_CHECK{Stripe progress?}
    STRIPE_CHECK -->|Stripe unlocked| STRIPE_ANIM[Stripe Celebration]
    STRIPE_CHECK -->|No| HOME
    STRIPE_ANIM --> HOME
```

---

## Belt Test Flow

```mermaid
flowchart TD
    HOME --> TRAIN[Train Tab]
    TRAIN -->|All units complete| GATE[Belt Test Gate Screen]
    GATE -->|Start Test| TEST

    subgraph TEST [Belt Test — 16 questions, 5s timer, no hints]
        TQ[Question] --> TANS{Answer}
        TANS -->|Correct| TFC[Correct — no celebration, keep going]
        TANS -->|Wrong| TFW[Wrong — show answer]
        TFC --> TNEXT{More?}
        TFW --> TNEXT
        TNEXT -->|Yes| TQ
        TNEXT -->|No| TRESULT
    end

    TRESULT{Pass all 4 tags?}
    TRESULT -->|Yes| BELT_UP[Belt/Stripe Ceremony Screen]
    TRESULT -->|No| FAIL[Test Failed Screen]
    BELT_UP --> HOME
    FAIL -->|Shows failed tags| TRAIN
    FAIL -->|Retry failed tags only| TRAIN
```

---

## Compete — vs Kat Match

```mermaid
flowchart TD
    HOME --> COMPETE[Compete Tab]
    COMPETE -->|Fight Kat| KAT_BRIEF[vs Kat Intro]
    KAT_BRIEF --> MATCH

    subgraph MATCH [Match — 5 questions, 8s timer]
        MQ[Question + Kat is thinking...] --> MANS{Answer}
        MANS -->|Correct| MFC[+1 point you]
        MANS -->|Wrong| MFW[+1 point Kat]
        MFC --> MNEXT{More?}
        MFW --> MNEXT
        MNEXT -->|Yes| MQ
        MNEXT -->|No| MRESULT
    end

    MRESULT{Who won?}
    MRESULT -->|You| WIN[Win Screen — XP + League points]
    MRESULT -->|Kat| LOSE[Lose Screen — lose heart, small XP]
    WIN --> COMPETE
    LOSE --> COMPETE
```

---

## Compete — Tournament Run

```mermaid
flowchart TD
    COMPETE -->|Tournament Run| T_BRIEF[Tournament Intro — 5 matches, bracket shown]
    T_BRIEF --> M1[Match 1 vs NPC]
    M1 -->|Win| M2[Match 2 vs NPC]
    M1 -->|Lose| T_ELIM[Eliminated — consolation XP]
    M2 -->|Win| M3[Match 3 vs NPC]
    M2 -->|Lose| T_ELIM
    M3 -->|Win| M4[Match 4]
    M3 -->|Lose| T_ELIM
    M4 -->|Win| FINAL[Final Match]
    M4 -->|Lose| T_ELIM
    FINAL -->|Win| TROPHY[Tournament Trophy — big XP + title]
    FINAL -->|Lose| RUNNER[Runner Up — good XP]
    T_ELIM --> COMPETE
    TROPHY --> COMPETE
    RUNNER --> COMPETE
```

---

## Streak Flow

```mermaid
flowchart TD
    SESSION_DONE[Session Complete] --> STREAK_CHECK{Trained today?}
    STREAK_CHECK -->|First session today| STREAK_INC[streak_days + 1]
    STREAK_CHECK -->|Already trained today| STREAK_SAME[streak unchanged]
    STREAK_INC --> MILESTONE{Streak milestone?}
    MILESTONE -->|7 / 14 / 30 / 100 days| STREAK_BADGE[Streak Achievement]
    MILESTONE -->|No| HOME

    subgraph BROKEN [Next day, no session]
        NEXT_DAY[User opens app] --> STREAK_BROKEN{Last session > 24h ago?}
        STREAK_BROKEN -->|Yes, streak freeze active| FREEZE_USED[Use streak freeze — streak saved]
        STREAK_BROKEN -->|Yes, no freeze| RESET[streak = 0, show broken heart]
        RESET --> RECOVERY[Recovery prompt: Start a session to rebuild]
    end
```

---

## Hearts / Lives Flow

```mermaid
flowchart TD
    WRONG[Wrong Answer] --> LOSE_HEART[hearts - 1]
    LOSE_HEART --> HEARTS_CHECK{hearts > 0?}
    HEARTS_CHECK -->|Yes| CONTINUE[Continue session]
    HEARTS_CHECK -->|No| OUT[Out of Hearts Screen]
    OUT -->|Wait 4h| REFILL[1 heart refilled]
    OUT -->|Practice mode| PRACTICE[Unlimited practice — no XP, no hearts used]
    OUT -->|Subscription| INSTANT[Instant refill]

    REFILL_FULL[5 hearts when?]
    REFILL_FULL --> FULL_REFILL[After 20h OR midnight reset OR competition win]
```

---

## Subscription / Paywall Flow

```mermaid
flowchart TD
    FREE[Free User — Stripe 1 complete] --> LOCKED_NODE[Tap locked Stripe 2 node]
    LOCKED_NODE --> PAYWALL[Paywall Screen]
    PAYWALL -->|Subscribe| SUB[Subscription active]
    PAYWALL -->|Promo Code| CODE[Enter code → full access]
    PAYWALL -->|Not now| HOME
    SUB --> UNLOCK[All content unlocked]
    CODE --> UNLOCK
```

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| User quits mid-session | Progress lost, no XP, hearts not spent |
| Timer runs out | Auto-submit = wrong answer |
| Belt test failed | Only failed tags re-unlocked for practice, no full retake |
| All hearts lost in belt test | Test ends, must wait / practice to retry |
| First day (no data) | Home shows Day 1 state, no streak counter |
| Streak freeze | Available to subscription users, max 2 per week |
| Offline | Cached questions available, sync on reconnect |
