# BJJ Mind — 3D Position Library

**Task 5.2 — 20 unique scenes for White Belt MVP**

---

## Overview

Each scene defines:
- **scene_id** — unique identifier (used in `questions.json`)
- **camera** — angle and framing
- **player_a** — bottom/defending player (blue gi)
- **player_b** — top/attacking player (white gi)
- **highlight_target** — which body part glows to focus the question
- **grapplemap_position** — closest GrappleMap position name (for Stage B integration)
- **used_in** — which question IDs use this scene

---

## Camera Standards

All scenes use consistent camera conventions:

| Setting | Value |
|---------|-------|
| View angle | 55° from horizontal (not top-down, not eye-level) |
| Camera target | Center of both bodies |
| Rotation | Fixed per scene (no spin) |
| Player A color | Blue (#2563EB) |
| Player B color | White/light gray (#E5E7EB) |
| Mat color | Dark olive (#2D3320) |
| Highlight glow | Amber (#F59E0B) |

---

## Scene Definitions

---

### 1. `bottom-pressure-01`
**Name:** On Back — Side Pressure

Player A (blue) lies flat on back, facing up. Player B (white) is kneeling beside them, pressing into their shoulder.

| Field | Value |
|-------|-------|
| Camera | Slight angle from foot of Player A |
| Player A | Flat on back, arms slightly raised |
| Player B | Kneeling at Player A's side, pressing shoulder |
| Highlight | Player A's hip (where shrimp initiates) |
| GrappleMap | "Side Control" (approximation) |
| Used in | q-1-01 |

---

### 2. `mount-bottom-01`
**Name:** Mount — Bottom View

Player A (blue) lies flat on back. Player B (white) sits mounted on Player A's hips/chest, upright.

| Field | Value |
|-------|-------|
| Camera | Slight angle from Player A's head |
| Player A | Flat on back, arms at sides |
| Player B | Seated mount, hands on knees or chest |
| Highlight | Player A's hips (Upa/bridge initiation point) |
| GrappleMap | "Mount" |
| Used in | q-1-02, q-2-04, q-2-05, q-2-06, q-5-01 to q-5-07 |

---

### 3. `bottom-generic-01`
**Name:** Ground — Bottom Generic

Player A (blue) alone on ground demonstrating solo movement. Used for fundamentals (shrimp, teeter totter, four points).

| Field | Value |
|-------|-------|
| Camera | Overhead-ish, slight angle |
| Player A | Solo position on mat |
| Player B | Not present |
| Highlight | Player A's hips (movement origin) |
| GrappleMap | N/A (solo) |
| Used in | q-1-03, q-1-05, q-1-07 |

---

### 4. `standing-01`
**Name:** Standing — Self Defense

Both players standing. Player A (blue) in base stance. Player B (white) standing opposite.

| Field | Value |
|-------|-------|
| Camera | Eye level, slight angle |
| Player A | Feet shoulder-width, slight base |
| Player B | Standing, facing Player A |
| Highlight | Player A's lead arm (blocking position) |
| GrappleMap | "Clinch" (approximation) |
| Used in | q-1-04, q-2-03, q-3-01, q-3-02, q-6-08 |

---

### 5. `side-ctrl-bottom-01`
**Name:** Side Control — Bottom

Player A (blue) on back. Player B (white) in classic side control on top — perpendicular, chest on chest, crossface applied.

| Field | Value |
|-------|-------|
| Camera | Overhead-angled, from Player A's feet |
| Player A | On back, arms across chest (framing attempt) |
| Player B | Perpendicular on top, weight on chest |
| Highlight | Player A's near arm (frame position) |
| GrappleMap | "Side Control" |
| Used in | q-2-01, q-2-02, q-2-07, q-2-08, q-4-01, q-4-07, q-5-05 |

---

### 6. `side-ctrl-top-01`
**Name:** Side Control — Top

Player A (blue) on bottom in side control. Player B (white) on top — crossface, hip control, distributed base.

| Field | Value |
|-------|-------|
| Camera | Overhead-angled, from feet |
| Player A | On back, framing attempt |
| Player B | Side control on top, showing control points |
| Highlight | Player B's crossface arm (control mechanism) |
| GrappleMap | "Side Control" |
| Used in | q-3-05, q-3-06, q-7-01 to q-7-07, q-s-03, q-s-04 |

---

### 7. `mount-top-01`
**Name:** Mount — Top View

Player B (white) mounted on Player A (blue). High mount with hands available for attacks.

| Field | Value |
|-------|-------|
| Camera | Overhead-angled, from Player B's back |
| Player A | Flat on back, hands defending |
| Player B | High mount, hands free |
| Highlight | Player B's near arm (attack initiation) |
| GrappleMap | "Mount" |
| Used in | q-8-01 to q-8-06 |

---

### 8. `back-ctrl-top-01`
**Name:** Back Mount

Player B (white) has Player A's (blue) back. Seatbelt grip. Hooks in.

| Field | Value |
|-------|-------|
| Camera | Slight angle from Player B's side |
| Player A | Seated, leaning back |
| Player B | Behind Player A, seatbelt grip, hooks visible |
| Highlight | Player B's feet/hooks (control mechanism) |
| GrappleMap | "Back Mount" |
| Used in | q-3-03, q-3-04, q-9-01 to q-9-06 |

---

### 9. `guard-top-01`
**Name:** In Closed Guard — Top

Player A (blue) is on top, inside Player B's (white) closed guard. Player A postured up.

| Field | Value |
|-------|-------|
| Camera | Slight angle from Player A's back |
| Player A | Kneeling, postured up, one arm posted |
| Player B | On back, legs wrapped around Player A |
| Highlight | Player A's spine (posture line) |
| GrappleMap | "Closed Guard" |
| Used in | q-3-07, q-3-08, q-6-04, q-12-01 to q-12-07, q-s-05, q-s-06 |

---

### 10. `guard-bottom-01`
**Name:** Attacking from Closed Guard — Bottom

Player B (white) is in Player A's (blue) closed guard. Player A attacking from bottom.

| Field | Value |
|-------|-------|
| Camera | Slight angle from Player A's feet |
| Player A | On back, guard closed, hands reaching for collar |
| Player B | Kneeling inside guard, hands visible |
| Highlight | Player A's grip on Player B's collar |
| GrappleMap | "Closed Guard" |
| Used in | q-6-05, q-10-01 to q-10-07, q-11-01 to q-11-06, q-s-01, q-s-02 |

---

### 11. `side-headlock-bottom-01`
**Name:** Side Headlock — Bottom

Player B (white) has Player A (blue) in a side headlock — arm around Player A's neck from side.

| Field | Value |
|-------|-------|
| Camera | From Player A's feet, slight angle |
| Player A | On side on the mat, head trapped |
| Player B | Side-on, arm around neck, body against Player A |
| Highlight | Player B's arm (the lock) / Player A's elbow (escape point) |
| GrappleMap | "Scarf Hold" (approximation) |
| Used in | q-4-02, q-4-03, q-4-04, q-4-05, q-4-06, q-6-07 |

---

### 12. `standing-guillotine-01`
**Name:** Standing Guillotine

Player B (white) has Player A (blue) in a standing guillotine — arm around neck, standing.

| Field | Value |
|-------|-------|
| Camera | Eye level, from Player B's side |
| Player A | Head down, neck in crook of Player B's arm |
| Player B | Standing, arm guillotine, hips back |
| Highlight | Player A's neck / Player A's knee (reap target) |
| GrappleMap | "Guillotine" (approximation) |
| Used in | q-6-02, q-6-03 |

---

### 13. `standing-rear-01`
**Name:** Standing — Rear Attack

Player B (white) behind Player A (blue), arms around Player A's neck from behind.

| Field | Value |
|-------|-------|
| Camera | From Player A's side |
| Player A | Standing, being held from behind |
| Player B | Standing behind Player A, arms around neck |
| Highlight | Player A's elbow (defense initiation) |
| GrappleMap | "Rear Standing" (approximation) |
| Used in | q-6-01, q-6-06 |

---

### 14. `mount-bottom-choke-01`
**Name:** Mount — Choke Defense Variant

Player B (white) mounted with cross-collar choke attempt. Player A (blue) defending.

| Field | Value |
|-------|-------|
| Camera | Overhead-angled |
| Player A | On back, hands at collar/lapel |
| Player B | Mount, hands gripping collar |
| Highlight | Player A's hand on lapel (choke break) |
| GrappleMap | "Mount" |
| Used in | q-5-02, q-5-07 |

---

### 15. `guard-bottom-armbar-01`
**Name:** Guard Armbar Setup

Player A (blue) in guard, attacking with armbar — angled out, one arm extended.

| Field | Value |
|-------|-------|
| Camera | From Player B's side |
| Player A | On back, guard open, angled out, arm extended for lock |
| Player B | Arm extended, caught in armbar setup |
| Highlight | Player A's hips (hip raise = lever) |
| GrappleMap | "Closed Guard" |
| Used in | q-10-04, q-10-06 |

---

### 16. `guard-bottom-triangle-01`
**Name:** Triangle Choke Setup

Player A (blue) setting up triangle — one arm pushed across, angling out.

| Field | Value |
|-------|-------|
| Camera | From Player A's head |
| Player A | On back, angled 45° to side, legs positioning |
| Player B | One arm pushed across chest, off-balance |
| Highlight | Player A's hip angle (the key position) |
| GrappleMap | "Triangle" |
| Used in | q-10-02 |

---

### 17. `guard-bottom-kimura-01`
**Name:** Guard Kimura Setup

Player A (blue) isolating Player B's arm for Kimura — figure four grip, hips scooted away.

| Field | Value |
|-------|-------|
| Camera | Overhead-angled |
| Player A | On back, figure four grip, hips offset |
| Player B | Arm isolated, bent at 90° |
| Highlight | Player A's figure four grip |
| GrappleMap | "Kimura" |
| Used in | q-10-03, q-10-07 |

---

### 18. `guard-bottom-sweep-01`
**Name:** Guard Sweep — Scissor Position

Player A (blue) in scissor sweep position — legs scissored, controlling Player B.

| Field | Value |
|-------|-------|
| Camera | From Player A's side |
| Player A | On side, one leg on Player B's waist, one on knee |
| Player B | Kneeling, being controlled |
| Highlight | Player A's legs (scissor mechanism) |
| GrappleMap | "Closed Guard" → "Scissor Sweep" |
| Used in | q-11-01, q-11-05 |

---

### 19. `guard-top-passing-01`
**Name:** Guard Pass — Kneeling

Player A (white/B) kneeling, attempting guard pass — knee to centerline, leg on shoulder.

| Field | Value |
|-------|-------|
| Camera | From Player B's side |
| Player A | Kneeling, one leg on shoulder, passing to side control |
| Player B | On back, guard being passed |
| Highlight | Player A's knee (centerline position) |
| GrappleMap | "Knee Slide" (approximation) |
| Used in | q-12-04, q-12-06 |

---

### 20. `guard-top-toreando-01`
**Name:** Toreando Pass

Player B (white) standing, gripping Player A's (blue) ankles, redirecting legs to one side.

| Field | Value |
|-------|-------|
| Camera | From Player B's side, slight overhead |
| Player A | On back, legs up, feet redirected |
| Player B | Standing, both hands on ankles, stepping around |
| Highlight | Player A's ankles / Player B's step direction |
| GrappleMap | "Toreando" |
| Used in | q-s-05, q-s-06 |

---

## Usage Summary

| Scene ID | Questions using it |
|----------|--------------------|
| `bottom-pressure-01` | 1 |
| `mount-bottom-01` | 7 |
| `bottom-generic-01` | 3 |
| `standing-01` | 5 |
| `side-ctrl-bottom-01` | 7 |
| `side-ctrl-top-01` | 11 |
| `mount-top-01` | 6 |
| `back-ctrl-top-01` | 8 |
| `guard-top-01` | 10 |
| `guard-bottom-01` | 15 |
| `side-headlock-bottom-01` | 6 |
| `standing-guillotine-01` | 2 |
| `standing-rear-01` | 2 |
| `mount-bottom-choke-01` | 2 |
| `guard-bottom-armbar-01` | 2 |
| `guard-bottom-triangle-01` | 1 |
| `guard-bottom-kimura-01` | 2 |
| `guard-bottom-sweep-01` | 2 |
| `guard-top-passing-01` | 2 |
| `guard-top-toreando-01` | 2 |

**Total: 20 unique scenes covering all 90 questions**

---

## Implementation Priority

For the MVP prototype, implement in this order:

1. `side-ctrl-bottom-01` — most questions + iconic position (11 questions)
2. `guard-bottom-01` — largest set (15 questions)
3. `guard-top-01` — second largest (10 questions)
4. `mount-bottom-01` — high usage (7 questions)
5. `mount-top-01` — (6 questions)
6. All others — fill in as dev cycles allow
