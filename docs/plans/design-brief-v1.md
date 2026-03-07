# BJJ Mind — Design Brief v1
## Screens: Welcome + Exercise

---

## General

**App:** BJJ Mind — decision-making trainer for BJJ practitioners
**Platform:** iOS (iPhone 14, 390x844pt)
**Theme:** Light
**Style reference:** Duolingo (structure, UX patterns) — light theme, lavender as primary
**Deliverable:** 2 screens in Figma, auto layout, components

---

## Design System (apply to both screens)

**Colors:**

Primary palette:
- Primary (lavender): #7B5EA7
- Primary light (hover/tint): #EDE7F6
- Primary dark (pressed): #5E3D8F

Background & surfaces:
- Background: #FAFAFA (very slightly warm white)
- Surface (cards): #FFFFFF
- Surface secondary: #F3EFF9 (light lavender tint, for mat zone, highlights)
- Border: #E8E0F0

Text:
- Text primary: #1A1433 (dark purple-black)
- Text secondary: #6B6080
- Text muted: #A99DC0

Semantic colors:
- Success / XP / Correct: #58A700 (Duolingo green — keep for rewards)
- Danger / Opponent: #E03D3D (red)
- Player accent: #4A7BDB (blue)
- Warning / Timer urgent: #FF9600

Shadows:
- Card shadow: 0px 2px 8px rgba(123, 94, 167, 0.10)

**Typography:**
- Font: SF Pro Display (iOS system) or Inter as fallback
- Heading: 28-32pt, weight 800
- Subheading: 17pt, weight 600
- Body: 15pt, weight 400
- Caption: 12pt, weight 400, color Text secondary

**Corner radius:** 16px cards, 12px buttons, 8px small elements
**Spacing:** 8pt grid
**Safe area:** respect iPhone 14 top (59pt) and bottom (34pt) notch/home indicator

---

## Screen 1: Welcome

### Purpose
First impression. User opens the app for the first time.
Goal: communicate the value in 3 seconds and get them to tap "Start".

### Mood
Light, energetic, confident. Like a sports brand — clean and fresh, but with edge. Not a meditation app, not a hardcore gym app. Somewhere between Duolingo and Nike.

### Layout (top to bottom)

**Top area (illustration zone, ~45% of screen height)**
- Abstract top-down view of a BJJ mat — two silhouettes, one blue, one red
- Style: flat/geometric, not realistic. Think icons, not photography.
- Subtle lavender gradient background for this zone (#EDE7F6 → #FAFAFA)
- Mat surface: light warm beige/cream (like real tatami)

**Middle (copy)**
- Headline: "Train your brain. Win on the mat."
- Subline (muted): "Decision drills for grapplers. 5 minutes a day."

**Bottom (CTA)**
- Primary button: "Get Started" — full width, lavender (#7B5EA7), text white, height 56pt, radius 16pt
- Secondary link below button: "Already have an account? Log in" — muted text, no underline

**Bottom edge**
- Small muted text: "Used by 10,000+ grapplers" (social proof, placeholder)

### Notes for designer
- No logo needed yet, working title "BJJ Mind" can appear as wordmark at top if needed
- The illustration is the hero — invest time here
- Keep copy minimal — one headline, one subline, one button
- Reference: Duolingo welcome screen structure, but dark and athletic

---

## Screen 2: Exercise (Micro-round Card)

### Purpose
Core gameplay screen. User sees a BJJ position from above and must make a decision under time pressure.

### Context
This is the main loop. User sees it dozens of times per session. Must be:
- Instantly readable (what's happening on the mat)
- Clearly timed (urgency without panic)
- Easy to tap (no cognitive load on UI)

### Layout (top to bottom)

**Header bar**
- Left: X button (exit session) — icon only, muted
- Center: progress bar (thin, green fill, shows position in current session e.g. 3/8)
- Right: XP counter "30 XP" in green

**Timer**
- Large number, centered: "3" → "2" → "1"
- Color transitions: gray (safe) → orange (warning) → red (urgent)
- Font: 52pt, weight 800
- Below timer: small label "SIDE CONTROL · DECISION POINT" in muted caps

**Legend (3 pills in a row)**
- Blue dot + "You"
- Red dot + "Opponent"
- Faded red dot + "Danger zone"
- Style: small horizontal pills, muted, below the label

**Mat (3D scene zone, ~38% of screen height)**
- Dark green card (#121F12), radius 20pt, 1pt border (#1E2E1E)
- Background: light lavender tint (#F3EFF9), radius 20pt, 1pt border (#E8E0F0)
- Inside: 3D render of BJJ position (GrappleMap engine / Babylon.js)
- Two characters: Blue = player, Red = opponent
- Pulsing red zone marks the danger/submission threat
- Small letter labels "A" and "B" overlaid on the relevant body parts (player's arms)
- No UI chrome inside the mat — just the scene

**Prompt (below mat)**
- Line 1 (muted): "Opponent is passing to Mount."
- Line 2 (white, bold): "Where do you put your hands?"

**Answer buttons (2 options)**
- Full width, stacked vertically, gap 10pt
- Each button: white card (#FFFFFF), border 2pt, radius 14pt, height 56pt, card shadow
- Left side: large letter "A" or "B" (18pt, 700, colored — lavender for A, muted for B)
- Right side: answer text (14pt, 600, text primary #1A1433)
- Button A border color: #7B5EA7 (lavender)
- Button B border color: #E8E0F0 (neutral border)
- On tap: slight scale animation (0.97), then feedback state

**Feedback state (after tap — same screen, buttons disabled)**

Correct answer:
- Screen flashes green subtly (overlay 8% opacity)
- Correct button: green border + green checkmark icon
- Feedback card appears below buttons:
  - Green tinted card
  - Icon: checkmark
  - Bold: "Mount blocked."
  - Body: "Hip frame creates distance and stops his base from shifting."
  - Bottom: "+10 XP" in large green text

Wrong answer:
- Screen flashes red subtly
- Tapped button: red border + X icon
- Feedback card:
  - Red tinted card
  - Icon: X
  - Bold: "You gave him the Armbar."
  - Body: "Extending your arm toward his chest puts it directly in his control zone."
  - Italic muted: "No frame = no defense."
  - Button: "Try again" (secondary, muted)

### Notes for designer
- The mat zone is the hardest part — work with developer on how to frame the 3D scene
- For mockup purposes, use a flat illustration or screenshot from GrappleMap as placeholder
- Answer buttons must feel tappable — large touch targets, clear affordance
- Timer is emotional — its size and color change must feel urgent but not anxious
- Reference: Duolingo lesson card structure; Chess.com move selection; Headspace session card

---

## Deliverable Checklist
- [ ] Design System page (colors, typography, components)
- [ ] Screen 1: Welcome (default state)
- [ ] Screen 2: Exercise (question state)
- [ ] Screen 2: Exercise (correct answer state)
- [ ] Screen 2: Exercise (wrong answer state)
- [ ] All in auto layout
- [ ] Named layers
