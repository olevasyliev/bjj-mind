# BJJ Mind — GrappleMap 3D Research

**Task 5.1 — Evaluate 3D visualization options for BJJ positions**

---

## What is GrappleMap?

GrappleMap is an open-source BJJ/grappling position graph created by Eelis van der Weegen.

- **GitHub:** github.com/Eelis/GrappleMap
- **Web viewer:** grapplemaps.com
- **License:** Open source (check repo for specifics)
- **Written in:** C++

### Data Structure

GrappleMap stores positions as a directed graph:

- **Nodes:** Named BJJ positions (side control, mount, guard, etc.)
- **Edges:** Transitions between positions (escapes, attacks, passes)
- **Position data:** Joint coordinates for two players (x, y, z per joint)
- **Joint count:** ~17 joints per player (head, neck, shoulders, elbows, wrists, hips, knees, ankles, feet)
- **Total dataset:** ~600+ named positions, ~1000+ transitions
- **Format:** Custom plaintext `.txt` format

### Example position entry (simplified):
```
position "Side Control" {
  player1 {
    head { 0.12 0.68 0.23 }
    neck { 0.10 0.55 0.20 }
    ... (17 joints)
  }
  player2 {
    head { -0.30 0.12 0.08 }
    ... (17 joints)
  }
}
```

---

## Option 1: GrappleMap Data + Babylon.js

### How it would work

1. Parse GrappleMap `.txt` position file at build time
2. Convert joint coordinates to Babylon.js skeleton/bone system
3. Create a humanoid mesh (GLTF from Mixamo or custom)
4. Apply joint positions to the skeleton
5. Render in scene

### Pros

- ✅ 600+ positions already mapped — massive head start
- ✅ BJJ-accurate (community-validated positions)
- ✅ Transition animations possible (interpolate between position nodes)
- ✅ White Belt positions (side control, mount, guard) are all in the dataset

### Cons

- ❌ C++ parser needs to be rewritten in JS/TS
- ❌ Custom plaintext format — not standard JSON/GLTF
- ❌ Joint coordinate system may not match standard skeleton rigs
- ❌ No bone hierarchy — raw joint positions require inverse kinematics or manual mapping
- ❌ No Gi/clothing data — bare humanoid only

### Estimated effort

- Parser rewrite: 2–3 days (JS)
- Skeleton mapping: 3–5 days
- MVP scene rendering: 1–2 days
- **Total: ~8–10 days for first working scene**

---

## Option 2: Custom Rigged Models (Mixamo + Manual Positioning)

### How it would work

1. Download free BJJ gi character from Mixamo or Sketchfab (CC0 license)
2. Export as GLTF with skeleton
3. Manually position each humanoid per scene in Blender
4. Export each position as separate GLTF file
5. Load in Babylon.js, switch between pre-baked positions

### Pros

- ✅ Full visual control — gi, colors, style
- ✅ Standard GLTF format — direct Babylon.js import
- ✅ No coordinate system mismatch issues
- ✅ Pre-baked animations possible (FBX → GLTF from Mixamo)

### Cons

- ❌ Manual positioning of 20 scenes = ~20 hours in Blender
- ❌ Requires Blender skills (or animator)
- ❌ Not data-driven — adding new positions requires new 3D work
- ❌ File size: 20 GLTF scenes × ~1–2MB = ~20–40MB

### Estimated effort

- Model sourcing and setup: 1 day
- Per-scene positioning: 1–2h each × 20 = 20–40 hours
- **Total: ~5–7 days for 20 scenes**

---

## Option 3: Illustrated Scenes (SVG/2D Top-Down)

### How it would work

Replace 3D with high-quality flat illustration:
- Top-down or isometric view
- Two color-coded humanoid silhouettes
- Key body parts labeled
- Designed by illustrator (or Figma)

### Pros

- ✅ Fastest to implement (no 3D)
- ✅ Lightest bundle size
- ✅ Clear and readable — possibly better UX than 3D
- ✅ No engine dependency
- ✅ Can be done in Figma/SVG

### Cons

- ❌ Static — no transition animations
- ❌ Less impressive visually
- ❌ Manual illustration work for 20 scenes

### Estimated effort

- Per scene: 30–60 min in Figma
- 20 scenes × 45 min = ~15 hours
- **Total: 2–3 days for 20 scenes**

---

## Comparison Matrix

| | GrappleMap + Babylon.js | Custom GLTF + Babylon.js | Illustrated SVG |
|--|--|--|--|
| **Effort** | High (8–10 days) | Medium (5–7 days) | Low (2–3 days) |
| **Visual quality** | High (3D) | High (3D) | Medium (flat) |
| **BJJ accuracy** | Highest (validated dataset) | Depends on artist | Depends on artist |
| **Animation** | Yes (interpolation) | Yes (pre-baked) | No |
| **Bundle size** | Small (data) | Large (GLTF) | Tiny (SVG) |
| **Scalability** | Very high | Low (manual) | Low (manual) |
| **Risk** | Medium (parser complexity) | Low | Very low |

---

## Recommendation

### Phase 5 MVP: Hybrid approach

**Stage A (now):** Illustrated SVG scenes
- Build 20 scenes as clean SVG illustrations in Figma
- Ship in prototype/beta — gives real user feedback
- Zero blocking risk

**Stage B (after validation):** GrappleMap integration
- Parse GrappleMap data → JSON position library
- Render with Babylon.js + procedurally generated humanoid meshes (no GLTF dependency)
- Use the 600+ positions dataset to unlock future content expansion automatically

**Why not Option 2 (custom GLTF)?**
Manual Blender work doesn't scale. GrappleMap already has 600+ validated positions — building on that gives the app a permanent competitive advantage in visual accuracy.

---

## GrappleMap Integration Plan (Stage B)

### Step 1: Parse GrappleMap positions to JSON

```typescript
// Input: GrappleMap .txt position file
// Output: positions.json

type GrappleMapJoint = { x: number; y: number; z: number };
type GrappleMapPlayer = { joints: Record<JointName, GrappleMapJoint> };
type GrappleMapPosition = {
  id: string;
  name: string;
  player1: GrappleMapPlayer;
  player2: GrappleMapPlayer;
};
```

Run as a build-time script (`scripts/parse-grapplemap.ts`).

### Step 2: Map GrappleMap positions to app scene IDs

| App scene_id | GrappleMap position name |
|---|---|
| `side-ctrl-bottom-01` | "Side Control" |
| `mount-top-01` | "Mount" |
| `guard-bottom-01` | "Closed Guard" |
| `back-ctrl-top-01` | "Back Mount" |
| ... | ... |

### Step 3: Render in Babylon.js

```typescript
// Procedural humanoid from joint positions
function renderPosition(scene: BABYLON.Scene, pos: GrappleMapPosition) {
  createHumanoidFromJoints(scene, pos.player1, BLUE_GI_COLOR);
  createHumanoidFromJoints(scene, pos.player2, WHITE_GI_COLOR);
  addGroundPlane(scene);
  positionCamera(scene, "top-angle");
}
```

### Step 4: Highlight target body part

Each question's `highlight_target` (from position library) drives a glow layer on the specific mesh.

---

## Next Steps

1. ✅ GrappleMap research complete (this document)
2. ✅ Position library spec (see `position-library.md`)
3. ✅ Babylon.js MVP prototype (see `scene-prototype.html`)
4. ⏳ SVG illustration set — 20 scenes (after prototype validated)
5. ⏳ GrappleMap parser (Stage B, post-validation)
