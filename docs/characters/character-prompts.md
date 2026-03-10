# BJJ Mind — Character Bible & Nano Banana Prompts

---

## Visual Style (all characters)

- **Style:** Chibi / rounded cartoon. Large head (≈55% of total height), small body, stubby limbs.
- **Line weight:** Clean, consistent 3–4px outline. No sketchy lines.
- **Shading:** Flat cel-shading — one highlight pass, one shadow pass. No gradients except gi fabric.
- **Eyes:** Large, round, expressive. White with colored iris + black pupil. Shine dot top-left.
- **Palette:** Warm, saturated. Each character has a signature color (see individual specs).
- **Delivery format:** Transparent PNG, 800×800px, character centered with 10% breathing room.
- **Pose:** Slight 3/4 turn, default facing right (except Kat — faces left, she's the opponent).
- **Reference anchor:** `figma-screens/image 1.png` — Gi Ghost neutral. Match this energy.

---

## 1. Gi Ghost — The Mascot

### Legend

Nobody knows exactly what Gi Ghost is. He appeared on the mat one day — friendly, enthusiastic, wearing a pristine white gi — and nobody questioned it. He's been there ever since.

The working theory is that he was a BJJ practitioner so absorbed in the sport that when his body stopped, his mind stayed on the mat. He doesn't remember his name or belt rank. He just knows techniques and wants to share them.

He's the player's constant companion: cheers when they get something right, slumps when they don't, floats alongside them through every session. Not a teacher exactly — more like an enthusiastic training partner who happens to know everything and can't tap out.

**Personality:** Endlessly optimistic. Gets genuinely excited by good technique. Takes wrong answers personally ("no no NO — the HIP!"). Occasionally dramatic. Secretly competitive even though he'd never admit it. Loyal above everything.

**Voice (in-app copy):** Short, energetic, uses exclamation marks genuinely. "Yes! Hip frame first." / "Oof. That's the mistake everyone makes." / "You've got this. I believe in you. Probably."

**App role:** Primary mascot. Appears on feedback screens (correct/wrong reactions), welcome screen, session summary, belt test results. His expression communicates the emotional tone of every moment.

---

### Visual Spec

**Body:** Round, soft oval body. No legs — floats ≈15px off the ground. Arms: stubby, expressive, can hold them in different positions. Slight translucency hint in the gi fabric (he's a ghost — the gi fabric looks slightly ethereal, like thin cotton with a faint glow).

**Face:** Large round head. Huge black round eyes with white shine dot. Tiny oval nose. Mouth: flexible — from wide grin to deep frown. Eyebrows: think but expressive, float slightly above eyes.

**Gi details:**
- Color: Pure white (#FFFFFF) with very light blue-grey shadow (#E8EAF0)
- Collar: V-neck, slight lapel visible
- Belt: **No belt visible by default** (nobody knows his rank — this is a running gag)
- Subtle texture: faint parallel weave lines on chest panel

**Signature color:** Soft lilac glow (#C4B5FD) — subtle aura around the base of the body, like he's slightly hovering

---

### Expression Variants

**1. Neutral** ← already exists (`image 1.png`). Use as style reference.

**2. Happy / Celebrating**
- Eyes: crescents (^_^ shape), thick happy arcs
- Mouth: huge open grin, small teeth visible
- Arms: both raised above head, slight tilt left-right (like he's doing a happy wiggle)
- Aura: brighter lilac glow
- Optional: small sparkle/star shapes floating around him (2–3 small ★)

**3. Sad / Wrong answer**
- Eyes: heavy drooping lids, pupils small and looking down
- Mouth: downward curve, small, tight
- Head: tilted slightly forward and down, like a head-drop
- Arms: hanging limp at sides
- Body: slightly deflated/smaller silhouette than neutral
- Aura: dim, barely visible

**4. Thinking / Focused**
- Eyes: one slightly narrowed, both looking up-right
- Mouth: small pursed expression, like he's concentrating
- One arm raised, tiny ghost finger near the side of his head (not chin — he has no chin)
- Slight tilt of head to the right

**5. Determined / Game mode**
- Eyes: sharp, narrowed — the "I mean business" look. Small pupils, intense.
- Mouth: straight line, slightly set jaw
- Arms: both forward in small fists, slightly raised (fight stance energy)
- Body: leaning slightly forward
- Aura: pulsing, slightly brighter

---

### Nano Banana Prompt

> **Character:** Gi Ghost — floating ghost wearing a white BJJ gi (kimono). Chibi proportions: large round head approximately 55% of total character height, stubby body, no legs. He floats about 15 pixels above ground level. The gi is crisp white (#FFFFFF) with light blue-grey shadows on the fabric folds (#E8EAF0). Faint weave texture lines on the chest. No belt visible (intentional). Large black round eyes with a white shine dot in the upper left of each eye. Small oval nose. Soft lilac aura glow underneath the body (#C4B5FD, subtle). Slight translucency hint in the gi fabric to suggest he's a ghost — not fully opaque, more like very sheer cotton. 3/4 view facing right. Transparent background. Flat cel-shading with one highlight pass and one shadow pass. Clean 3–4px black outline. App theme purple: #7C3AED.
>
> **Deliver 5 variants:** neutral (reference), celebrating (arms up, crescent eyes, open grin), sad (drooping eyes, limp arms, deflated posture), thinking (one arm raised, finger to side of head, head tilted), determined (fists forward, sharp narrowed eyes, leaning in).

---

---

## 2. Marco — The Senior Training Partner

### Legend

Marco Ferreira is 29. Born in Porto Alegre, raised in Barcelona. His grandfather immigrated from Brazil in the 80s and opened a gym that Marco grew up in. He started BJJ at 7 — not because he loved it, but because it was just there, like the smell of mat cleaner and the sound of tapping.

He didn't love it until he was 16 and got submitted by a 50-year-old man for the first time. Something about that humiliation unlocked something. He's been obsessed ever since.

Now he trains 5 days a week, coaches white belts on Tuesday and Thursday evenings, and has a very strong opinion about people who cross-collar choke without setting the second grip first. He's a purple belt but trains like he's chasing brown. He will probably never stop chasing.

He's not soft with the player. He doesn't baby them. But he's never cruel either. He points out the mistake, explains why it matters, then moves on. He treats you like someone who can handle the truth — which is the highest compliment he knows how to give.

**Personality:** Direct, warm, slightly competitive even when coaching. Gets genuinely excited when students click on a concept. Uses "okay but listen—" a lot. Never lets a wrong answer go without explaining the real mechanics. Has a short memory for mistakes — corrects it, forgets it, moves on.

**Voice (in-app copy):** Medium sentences. Specific, not abstract. "Hip frame before you shrimp — always. The shrimp means nothing without space." / "Good. Now do it when it's not practice." / "Every loss is data. What did you learn?"

**App role:** Post-session coach insights (Claude API), belt test feedback, coach moment cards mid-session, tournament defeat consolation message.

---

### Visual Spec

**Body:** Chibi proportions — big head, shorter body, slight athletic build visible in shoulders (broader than Gi Ghost). He stands planted, confident posture. Not hunched, not stiff — relaxed but ready.

**Hair:** Short, slightly messy dark brown hair. Small amount of stubble on jaw (indicates shadow, not full beard — 2–3 days growth).

**Face:** Strong jaw line for chibi (still rounded, not sharp). Warm brown eyes, slight natural squint (he spends a lot of time thinking). Default expression: calm half-smile — not grinning, not serious. Just present.

**Gi:**
- Color: Blue gi (#2563EB body, #1D4ED8 shadows, white highlights)
- Belt: Purple (#7C3AED) with visible knot
- Gi collar: rolled/settled, slightly open
- Slight wear marks on the lapels (barely visible — this gi has been rolled in)

**Signature color:** Blue (#2563EB) — his gi anchors his palette

---

### Expression Variants

**1. Default / Talking**
- Calm, neutral-positive expression. Half-smile. Arms relaxed at sides or one slightly raised (mid-explanation).

**2. Proud / Thumbs up**
- Wider genuine smile (not showing teeth — contained pride). One arm extended forward, solid thumbs up.
- Eyes slightly narrowed in a warm "yeah, you got it" expression.

**3. Giving a tip / Teaching**
- One finger raised (index finger up — "listen to this part"). Eyebrow slightly raised.
- Slight tilt of the head. Expression: focused, intense but not unfriendly.
- Mouth: small, slightly pursed — he's thinking about how to say the thing correctly.

---

### Nano Banana Prompt

> **Character:** Marco — male BJJ coach character, chibi proportions with a slight athletic build visible in the shoulders. Short messy dark brown hair, subtle jaw stubble (shadow only, not full beard). Warm brown eyes with a natural slight squint. Calm half-smile expression — not grinning, just present and confident. Wearing a blue BJJ gi (#2563EB) with visible fabric fold shadows (#1D4ED8) and a purple belt tied at the waist (#7C3AED) with a clear knot. Gi collar slightly settled and open. Faint wear marks on lapels. 3/4 view facing right. Transparent background. Flat cel-shading. Clean 3–4px black outline. Chibi proportions — large head approximately 55% of total height, shorter body, stubby limbs.
>
> **Deliver 3 variants:** default/talking (calm half-smile, one arm slightly raised), proud/thumbs up (genuine contained smile, solid thumbs up extended), giving tip (index finger raised, eyebrow up, focused expression, head slightly tilted).

---

---

## 3. Old Chen — The Quiet Veteran

### Legend

Chen Weiming is 67. He retired from 40 years of running a dry-cleaning business in Barcelona's Raval neighborhood, and was bored within a week. His grandson dragged him to a free trial BJJ class as a joke. Chen submitted the grandson in week 4.

He has a white belt because nobody gave him the test yet. He's never asked for it.

He doesn't train to compete. He trains because it's the first physical practice he's ever done that requires actual thought — not strength, not size, not youth. He finds this philosophically interesting. He trains at the pace of someone who has decided there's no rush.

He is, objectively, the most technically correct person in the room most of the time. He just doesn't broadcast it.

His wisdom in the app isn't martial arts clichés — it's the real thing. He says things like "You're using your shoulder when you should be using your position" and "Slow is smooth. Smooth is fast. You're skipping smooth." He'll sit out a round and watch, then tell you exactly what you did wrong from the sideline.

**Personality:** Still, observant, unhurried. Zero ego. Finds humor in the gap between what beginners think and what's actually happening. Will give a correction and then immediately change the subject, like it's done. Doesn't repeat himself — says it once, perfectly.

**Voice (in-app copy):** Short sentences. Ancient-proverb energy but grounded. "You moved before you were ready. Again." / "The mistake was earlier than you think." / "Less. Do less." / "Good. Rest. Think about it."

**App role:** Appears occasionally as an alternative coach voice — specifically for timing, control, and base concepts. His coach moments feel different from Marco's — quieter, more philosophical, slightly surprising.

---

### Visual Spec

**Body:** Slightly smaller than Marco — he's compact, not imposing. Relaxed posture, never tense. Could be standing with hands loosely behind his back, or arms lightly crossed.

**Hair:** White, short, neatly kept. No beard — clean-shaven. Warm wrinkles around the eyes (crow's feet, subtle forehead lines). These should read as kind wrinkles, not harsh ones.

**Face:** Warm, gentle dark eyes. Very subtle smile — the corners of his mouth are slightly up, always, even at rest. It's his default face. Looks like someone who has seen many things and found most of them amusing.

**Gi:**
- Color: Very clean white gi (#FAFAFA), slightly off-white to distinguish from Gi Ghost. Shadow: (#E2E5EB)
- Belt: White (#E2E5EB with subtle #BBBFC7 shadow) — same rank as the player
- Gi is immaculately pressed. This man irons his gi.

**Signature color:** Warm grey-white — his whole palette is calm and settled

---

### Expression Variants

**1. Default / Talking calmly**
- Near-neutral expression. Subtle closed-mouth smile. Eyes warm, slightly narrowed (natural squint of someone used to thinking). Arms slightly behind back or loosely crossed.

**2. Giving etiquette tip / Respectful**
- Slight forward bow of the head. Eyes closed or looking down during the bow. Hands together or one hand raised in a calm gesture. Expression: serene, sincere.

---

### Nano Banana Prompt

> **Character:** Old Chen — elderly male BJJ character, 67 years old, chibi proportions. Compact frame, slightly smaller than Marco. White short neat hair, clean-shaven. Warm kind wrinkles around the eyes (crow's feet, slight forehead lines — gentle, not harsh). Very subtle closed-mouth smile at rest — corners of mouth just slightly up. Dark warm eyes, naturally slightly narrowed. Wearing an immaculately clean white gi (#FAFAFA, shadow #E2E5EB) — pressed and tidy, no wear marks. White belt (#E2E5EB). Relaxed posture — hands lightly behind back or loosely crossed. 3/4 view facing right. Transparent background. Flat cel-shading. Clean 3–4px black outline. Chibi proportions.
>
> **Deliver 2 variants:** default/talking (subtle smile, calm eyes, arms loosely behind back or crossed), etiquette bow (slight forward head bow, eyes closed or down, hands together, serene expression).

---

---

## 4. Kat — The Rival

### Legend

Kat's full name is Katherine Santos. She's 22, half-Japanese half-Brazilian, grew up in Osaka, moved to Barcelona two years ago for university. She started BJJ eight months ago, purely because a friend bet her she wouldn't last a month.

She lasted. She's been there every class since.

She's not naturally gifted. She's methodical. She films herself after every class and watches the footage. She keeps a notebook. She's the kind of person who, when told a technique, immediately asks "what breaks this?" — not to argue, but because she wants to know the counter before she's caught by it.

She's technically ahead of where most people are at eight months. Not because of talent — because of attention. She pays more attention than anyone in the room.

She doesn't talk much at training. Not because she's cold or unfriendly — she's just in a different mode when she's on the mat. When she's off it, she's completely normal. But nobody in the app sees her off the mat.

The player chases Kat through all of white belt. She's always slightly ahead. The app uses her as the benchmark — she represents what "consistent training looks like." The player will eventually catch her. Maybe.

**Personality:** Internally competitive (with herself, mainly). Focused. Has a dry sense of humor that comes out in unexpected one-liners. Respects effort, respects technique, has no patience for excuses. Her "defeat" lines in the vs Kat screen are genuinely respectful — she's not a villain.

**Voice (in-app copy — defeat):** "You earned it." / "Good timing. You've been working on that." / "Nice. Don't stop training." (Win lines are less friendly — not mean, just economical: "Again?" / "Not today." / "Keep going.")

**App role:** vs Kat match screen (primary character), league leaderboard (she appears near the top), tournament final (she's the final opponent in some tournament runs).

---

### Visual Spec

**Body:** Athletic, compact. Stands very square, weight balanced. The poster child of "ready position." Slightly narrower build than Marco, slightly taller energy.

**Hair:** Short dark hair, undercut style — longer on top, very short on the sides. Could have a small section tucked behind one ear.

**Face:** Clean, precise features for chibi. Her default expression is neutral-focused — not a frown, not a smile. Just present and locked in. Sharp dark eyes, very attentive. No readable emotion at rest — this is intentional.

**Gi:**
- Color: White gi (#FAFAFA) — same belt level as player
- Belt: White (#E2E5EB)
- But: her gi has competition patches on the shoulder (small color squares — suggests she's already registered for her first tournament)

**Facing:** She faces **left** (toward the player) — she's always looking at you.

**Signature color:** Clean white + black — minimal, precise, no extra elements

---

### Expression Variants

**1. Default / Neutral stance**
- Completely neutral expression. Arms slightly crossed or at sides in a relaxed ready position. Eyes forward, attentive.

**2. Victory pose**
- Arms crossed at chest, chin slightly raised. The faintest hint of a nod — like a contained acknowledgment. Not gloating. More like "as expected."
- Still no smile — just composed satisfaction.

---

### Nano Banana Prompt

> **Character:** Kat — young female BJJ character, 22 years old, chibi proportions. Athletic compact build, stands very square and balanced — "ready position" energy. Short dark hair, undercut style (longer on top, very short on the sides, small section tucked behind one ear). Clean precise chibi features. Default expression is completely neutral-focused — not frowning, not smiling, just present and locked in. Sharp dark eyes, very attentive. Wearing a clean white gi (#FAFAFA, shadow #E2E5EB) with a white belt. Small rectangular competition patch detail on the left shoulder (simple color squares — suggests tournament registration). **She faces LEFT** (toward the viewer/player). 3/4 view facing left. Transparent background. Flat cel-shading. Clean 3–4px black outline. Chibi proportions.
>
> **Deliver 2 variants:** default/neutral stance (neutral focused expression, arms relaxed at sides or lightly crossed), victory pose (arms crossed at chest, chin slightly raised, the very faintest nod of contained satisfaction — no smile).

---

---

## 5. Rex — The Training Buddy

### Legend

Rexford Williams — he goes by Rex, and if you call him Rexford, he'll pretend he doesn't hear you. He's 26, American (Georgia originally), been in Barcelona for two years working remotely as a developer. His roommate signed him up for BJJ as a birthday "joke." He showed up to that first class 40 pounds heavier than most people in the room, fully expecting his size to handle it.

It did not handle it.

A 140-pound woman submitted him in 45 seconds. He paid for a year upfront that same day.

Rex is the training buddy — the one who texts you at 6pm "bro you training tonight?" even when he's tired. He makes the same mistakes the player makes, sometimes worse, but he's joyfully aware of his own limitations in a way that makes it easier to accept your own.

He's still figuring out that strength isn't technique. He intellectually understands this. Applying it in real time is a different story — he still occasionally tries to muscle out of a submission instead of tapping, and has the sore shoulder to show for it.

He celebrates the player's wins more than his own. When you earn a stripe, Rex acts like he earned it.

**Personality:** Loud enthusiasm, short attention span for theory, huge heart. Gets frustrated with himself but never with others. Makes self-deprecating jokes to defuse tension. Genuinely just happy to be there, most of the time.

**Voice (in-app copy):** Casual, uses incomplete sentences. "Okay okay okay I'm getting this." / "Wait no — is it the hip first or the—" / "BRO you got it! Yes!" / "Okay fine I tapped. Again. It's fine. I'm fine."

**App role:** Tutorial companion (intro screens, aha moment), occasional coach moment as a "wrong answer exemplar" — the question shows what Rex did and asks what went wrong. Appears in session summary as a friend celebrating with you.

---

### Visual Spec

**Body:** The largest build of all characters — wide, round, stocky. Not flabby — strong, but bigger than most. His head is even larger proportionally than the others (chibi pushed further). The gi visibly fits a bit small across the shoulders.

**Hair:** Spiky, going slightly in all directions — like he got dressed fast and didn't check a mirror. Warm medium-brown color.

**Face:** Big round cheeks, wide genuine smile as default. Large round eyes that read as warm and slightly dopey in the best possible way. One tooth slightly more prominent in his smile (not a gap — just one tooth that's a little bigger, gives character). Expressive eyebrows — his whole face moves.

**Gi:**
- Color: White gi (#FAFAFA)
- Belt: White, but tied a bit unevenly — slightly askew, one end longer than the other
- Gi appears slightly stretched across the shoulders — subtle suggestion it's one size too small
- Minor detail: gi collar slightly rumpled, like he's been in class a few minutes already

**Signature color:** Warm amber-yellow (#F59E0B) — his energy

---

### Expression Variants

**1. Default / Grinning**
- Wide open grin, eyes slightly squinted from the smile. Both arms at sides. Warm, relaxed, happy to be alive.

**2. Confused / Scratching head**
- Eyebrows up and together (confused V shape). Mouth slightly open, like he's about to ask a question. One hand raised to the back of his head, scratching. Eyes looking up-sideways — thinking, but slowly.

**3. Excited / Pointing**
- One arm extended, pointing forward (at something off-screen or at the player). Eyes wide open, mouth in a big surprised grin. Other arm slightly raised for balance. The energy of someone who just understood something and needs everyone to know.

---

### Nano Banana Prompt

> **Character:** Rex — large male BJJ character, 26 years old, chibi proportions pushed further — even larger head proportionally, wide stocky round body, stubby limbs. Biggest build of the character set — not flabby, strong but big. Spiky messy warm medium-brown hair going in multiple directions. Wide genuine open smile as default. Large round eyes, warm and slightly dopey-expressive. One tooth slightly more prominent in the smile (gives character — not a gap). Very expressive eyebrows. Wearing a white gi (#FAFAFA) that appears slightly stretched across the shoulders (one size too small). Belt tied slightly unevenly — one end longer than the other. Gi collar slightly rumpled. 3/4 view facing right. Transparent background. Flat cel-shading. Clean 3–4px black outline. Chibi proportions — exaggerated even beyond the other characters.
>
> **Deliver 3 variants:** default/grinning (wide open smile, warm eyes, arms relaxed), confused/scratching head (eyebrows up in confused V, mouth slightly open, one hand at back of head, eyes looking sideways), excited/pointing (one arm extended pointing, wide surprised grin, eyes wide open, other arm slightly raised).

---

---

## Delivery Summary

| Character | Variants | Total assets |
|-----------|----------|-------------|
| Gi Ghost | 5 | 5 PNGs |
| Marco | 3 | 3 PNGs |
| Old Chen | 2 | 2 PNGs |
| Kat | 2 | 2 PNGs |
| Rex | 3 | 3 PNGs |
| **Total** | | **15 PNGs** |

All at 800×800px, transparent background, ready for iOS @3x (scale down to 267×267 for @1x base).

---

## Style Consistency Notes for Animator

- All characters must feel like they exist in the same world. Test by putting all 5 at the same scale on one canvas — they should look like a team, not 5 separate commissions.
- Gi Ghost is the anchor — his style sets the baseline for all others.
- Chibi scale is flexible per character (Rex is more chibi, Kat is slightly less) but the art language must stay consistent.
- No photorealism, no anime-style screentone or speed lines. Clean, app-friendly vector-ish style.
- White gis must be distinguishable between characters. Use subtle differences in fabric texture detail, belt tying, and posture.
