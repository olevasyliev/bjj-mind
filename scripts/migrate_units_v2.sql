-- BJJ Mind — Units Migration v2
-- Replaces 31-unit structure with 4-cycle White Belt curriculum (74 nodes incl. mini-theory)
-- Safe to re-run: uses IF NOT EXISTS for DDL, clears data before insert

-- ── A. ALTER UNITS TABLE ───────────────────────────────────────────────────────

ALTER TABLE units
  ADD COLUMN IF NOT EXISTS cycle_number INTEGER,
  ADD COLUMN IF NOT EXISTS is_boss BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS mini_theory_content JSONB;

-- ── B. CREATE UNIT_TRANSLATIONS TABLE ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS unit_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id TEXT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  locale TEXT NOT NULL CHECK (locale IN ('en', 'es', 'pt')),
  title TEXT NOT NULL,
  description TEXT,
  mini_theory_content JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(unit_id, locale)
);

-- ── C. CLEAR OLD DATA ─────────────────────────────────────────────────────────

DELETE FROM unit_progress;
DELETE FROM units;

-- ── D. INSERT NEW 4-CYCLE STRUCTURE ───────────────────────────────────────────

-- ════════════════════════════════════════════════════════════════════════════
-- CYCLE 1 — Closed Guard
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO units (id, belt, order_index, title, description, tags, kind, is_belt_test, topic, cycle_number, is_boss, mini_theory_content) VALUES
(
  'wb-c1-mt0', 'white', 0,
  'Closed Guard',
  'Closed Guard',
  '{}', 'miniTheory', false, 'closed_guard', 1, false,
  $${
    "type": "cycleIntro",
    "screens": [
      {
        "title": "Welcome to Closed Guard",
        "body": "Closed guard is your fortress from the bottom. Your legs are locked around your partner — they can't stand, they can't pass. From here, you control the tempo of the entire match.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "Why It Matters",
        "body": "For a white belt, closed guard is your most powerful weapon. It limits your opponent's options, protects you from strikes in self-defense, and gives you access to sweeps, submissions, and back takes.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "What's Coming",
        "body": "10 lessons covering grips, posture breaking, hip control, sweeps, and submissions. Two boss fights at the end. This is where your BJJ journey begins.",
        "coachLine": "Guard isn't just survival. It's a weapon. Let's learn to use it.",
        "show3D": false
      }
    ],
    "buttonLabel": "Start Lessons →"
  }$$
),
(
  'wb-c1-mt1', 'white', 1,
  'Positional Control',
  'Positional Control',
  '{}', 'miniTheory', false, 'closed_guard', 1, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Control Before Attacks",
        "body": "The biggest beginner mistake: rushing for submissions without breaking posture first. An opponent with good posture can defend everything. Your first job in closed guard is to control their structure — grips, head, and hips — before hunting for attacks.",
        "coachLine": "Control the frame, then control the fight.",
        "show3D": false
      }
    ],
    "buttonLabel": "Let's Go →"
  }$$
),

(
  'wb-c1-l1', 'white', 2,
  'Closed Guard: Grips & Frame',
  'How to establish and maintain effective grips from closed guard.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),
(
  'wb-c1-l2', 'white', 3,
  'Closed Guard: Breaking Posture',
  'Techniques to break your opponent''s posture and control their head.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),
(
  'wb-c1-l3', 'white', 4,
  'Closed Guard: Hip Control',
  'Using your hips to off-balance and control from closed guard.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),

(
  'wb-c1-mt2', 'white', 5,
  'Sweeps',
  'Sweeps',
  '{}', 'miniTheory', false, 'closed_guard', 1, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Reversals from the Bottom",
        "body": "A sweep ends the match — you go from bottom to top position, scoring 2 points. The key insight: sweeps work because your opponent shifts their weight to defend submissions. When they lean forward to escape your triangle, you hip bump. When they push back against your armbar, you scissor. Read the reaction, use their momentum.",
        "coachLine": "They try to escape. You turn that escape into a reversal.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn the Sweeps →"
  }$$
),

(
  'wb-c1-l4', 'white', 6,
  'Closed Guard: Hip Bump Sweep',
  'Execute the hip bump sweep to reverse your opponent.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),
(
  'wb-c1-l5', 'white', 7,
  'Closed Guard: Scissor Sweep',
  'The scissor sweep: using your legs like a scissors to off-balance.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),
(
  'wb-c1-l6', 'white', 8,
  'Closed Guard: Flower Sweep',
  'Flower sweep mechanics and when to use it.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),

(
  'wb-c1-mt3', 'white', 9,
  'Submissions',
  'Submissions',
  '{}', 'miniTheory', false, 'closed_guard', 1, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Finishing from Closed Guard",
        "body": "Closed guard offers three fundamental submissions that every white belt must understand: the armbar (isolating one arm against your hips), the triangle (choking with your legs), and the kimura (shoulder lock using two hands vs one). Each requires broken posture first. Each is connected — defending one opens the other.",
        "coachLine": "One submission sets up the next. Chain them.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn Submissions →"
  }$$
),

(
  'wb-c1-l7', 'white', 10,
  'Closed Guard: Armbar',
  'The armbar from closed guard: mechanics, setup, and finish.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),
(
  'wb-c1-l8', 'white', 11,
  'Closed Guard: Triangle',
  'Triangle choke setup, locking the angle, and finishing.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),
(
  'wb-c1-l9', 'white', 12,
  'Closed Guard: Kimura',
  'The kimura grip from guard: control, sweep, and submission options.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),

(
  'wb-c1-mt4', 'white', 13,
  'Common Mistakes',
  'Common Mistakes',
  '{}', 'miniTheory', false, 'closed_guard', 1, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "What White Belts Get Wrong",
        "body": "The three most common closed guard errors: (1) Keeping straight legs — crossed ankles are stronger than crossed feet. (2) Attacking without breaking posture — you're submitting yourself to frustration. (3) Holding on when you should transition — if your guard opens, fight for half guard, don't panic.",
        "coachLine": "Awareness of your own mistakes is half the fix.",
        "show3D": false
      }
    ],
    "buttonLabel": "Understood →"
  }$$
),

(
  'wb-c1-l10', 'white', 14,
  'Closed Guard: Mistakes & Transitions',
  'Identifying and correcting the most common closed guard errors.',
  '{}', 'lesson', false, 'closed_guard', 1, false, NULL
),

(
  'wb-c1-mt5', 'white', 15,
  'Know Your Enemy',
  'Know Your Enemy',
  '{}', 'miniTheory', false, 'closed_guard', 1, false,
  $${
    "type": "bossPrep",
    "screens": [
      {
        "title": "Meet Your First Bosses",
        "body": "Boss 1: The Wall — a defensive opponent who sits back, breaks your grips, and waits you out. You need to be active and varied. Boss 2: The Posture Machine — they maintain perfect posture, making your sweeps and submissions nearly impossible. The lesson: break the structure first, then attack.",
        "coachLine": "Knowing how they think is half the battle. Ready?",
        "show3D": false
      }
    ],
    "buttonLabel": "Face the Boss →"
  }$$
),

(
  'wb-c1-boss1', 'white', 16,
  'Boss: The Wall',
  'Face The Wall — a passive, defensive opponent who waits out your guard.',
  '{}', 'bossFight', false, 'closed_guard', 1, true, NULL
),
(
  'wb-c1-boss2', 'white', 17,
  'Boss: The Posture Machine',
  'Face The Posture Machine — an opponent with iron posture who shuts down your attacks.',
  '{}', 'bossFight', false, 'closed_guard', 1, true, NULL
);


-- ════════════════════════════════════════════════════════════════════════════
-- CYCLE 2 — Half Guard
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO units (id, belt, order_index, title, description, tags, kind, is_belt_test, topic, cycle_number, is_boss, mini_theory_content) VALUES
(
  'wb-c2-mt0', 'white', 18,
  'Half Guard',
  'Half Guard',
  '{}', 'miniTheory', false, 'half_guard', 2, false,
  $${
    "type": "cycleIntro",
    "screens": [
      {
        "title": "Half Guard: Between Two Worlds",
        "body": "Half guard is where most scrambles end up. You have one of their legs trapped — not full guard, not fully passed. It's a dynamic position used at every level of BJJ, from white to black belt.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "Bottom vs Top",
        "body": "From the bottom, half guard is a launchpad for sweeps and back takes. From the top, it's a transitional position you want to pass. The battle is fought in the middle — over the underhook.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "What's Coming",
        "body": "10 lessons: establishing position, the underhook war, sweeps from bottom, and how to escape when things go wrong. One boss fight. Then a combined review of everything you've learned.",
        "coachLine": "Half guard is misunderstood. Let's change that.",
        "show3D": false
      }
    ],
    "buttonLabel": "Start Lessons →"
  }$$
),

(
  'wb-c2-mt1', 'white', 19,
  'Underhook Battle',
  'Underhook Battle',
  '{}', 'miniTheory', false, 'half_guard', 2, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "The War Under the Armpit",
        "body": "In half guard, the underhook is everything. If you're on the bottom and you get the underhook — you can sweep, take the back, or come up to your knees. If your opponent gets it — they flatten you, crossface you, and pass. Every drill, every principle in this block comes back to one question: who has the underhook?",
        "coachLine": "Win the underhook, win the position.",
        "show3D": false
      }
    ],
    "buttonLabel": "Let's Go →"
  }$$
),

(
  'wb-c2-l1', 'white', 20,
  'Half Guard: Establishing Position',
  'How to get to half guard and immediately fight for control.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),
(
  'wb-c2-l2', 'white', 21,
  'Half Guard: Underhook Control',
  'Winning the underhook and what to do once you have it.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),
(
  'wb-c2-l3', 'white', 22,
  'Half Guard: Head Position',
  'Head position in half guard and how it affects sweeps and defense.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),

(
  'wb-c2-mt2', 'white', 23,
  'Half Guard Sweeps',
  'Half Guard Sweeps',
  '{}', 'miniTheory', false, 'half_guard', 2, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Reversals from Half Guard",
        "body": "Half guard sweeps all share the same DNA: get the underhook, get off your back, take their balance. The deep half is aggressive and high-percentage. The old school is simple and reliable. The back take is the highest-value option when your opponent bases out wide. All three work together as a system.",
        "coachLine": "Don't pick one sweep. Threaten all three.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn the Sweeps →"
  }$$
),

(
  'wb-c2-l4', 'white', 24,
  'Half Guard: Deep Half Entry',
  'Entering deep half guard and using it to sweep or attack.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),
(
  'wb-c2-l5', 'white', 25,
  'Half Guard: Back Take',
  'Taking the back from half guard when the opponent bases out.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),
(
  'wb-c2-l6', 'white', 26,
  'Half Guard: Old School Sweep',
  'The old school sweep: simple, reliable, and always available.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),

(
  'wb-c2-mt3', 'white', 27,
  'Half Guard Escapes',
  'Half Guard Escapes',
  '{}', 'miniTheory', false, 'half_guard', 2, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "When They're Passing",
        "body": "Sometimes you end up in a bad half guard — flat on your back, crossfaced, underhook gone. Panic is the worst response. These three lessons cover your survival tools: recovering full guard by shrimping, using a knee shield to prevent the flatten, and reframing with your arms when you're stuck.",
        "coachLine": "Bad position doesn't mean lost position. Work the escape.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn the Escapes →"
  }$$
),

(
  'wb-c2-l7', 'white', 28,
  'Half Guard: Escape to Full Guard',
  'Recovering full guard from bottom half guard using hip escapes.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),
(
  'wb-c2-l8', 'white', 29,
  'Half Guard: Knee Shield',
  'Using the knee shield to create frames and prevent being flattened.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),
(
  'wb-c2-l9', 'white', 30,
  'Half Guard: Frame & Recover',
  'Creating frames with your arms to recover when the underhook is gone.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),

(
  'wb-c2-mt4', 'white', 31,
  'When It Goes Wrong',
  'When It Goes Wrong',
  '{}', 'miniTheory', false, 'half_guard', 2, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Diagnosing Your Half Guard Problems",
        "body": "If you keep getting passed: your hips are probably flat and your underhook is dead. If you can't sweep: you're attacking when your base is compromised. Most half guard problems trace back to one moment — the instant you didn't fight for the underhook. Fix that moment, and the rest gets easier.",
        "coachLine": "Losing is data. Use it.",
        "show3D": false
      }
    ],
    "buttonLabel": "Got It →"
  }$$
),

(
  'wb-c2-l10', 'white', 32,
  'Half Guard: Common Mistakes',
  'The most frequent half guard errors and how to correct them.',
  '{}', 'lesson', false, 'half_guard', 2, false, NULL
),

(
  'wb-c2-mr', 'white', 33,
  'Closed Guard + Half Guard Review',
  'Mixed review combining Closed Guard and Half Guard concepts.',
  '{}', 'mixedReview', false, 'half_guard', 2, false, NULL
),

(
  'wb-c2-mt5', 'white', 34,
  'Know Your Enemy',
  'Know Your Enemy',
  '{}', 'miniTheory', false, 'half_guard', 2, false,
  $${
    "type": "bossPrep",
    "screens": [
      {
        "title": "Meet The Passer",
        "body": "The Passer is relentless from the top. They crossface immediately, kill your underhook, and flatten you before you can react. To beat them: you need to be explosive off your back, fight for the underhook in the first second, and have your knee shield ready before they settle in.",
        "coachLine": "You have one second to act. Make it count.",
        "show3D": false
      }
    ],
    "buttonLabel": "Face the Boss →"
  }$$
),

(
  'wb-c2-boss', 'white', 35,
  'Boss: The Passer',
  'Face The Passer — a top player who immediately kills your underhook and flattens you out.',
  '{}', 'bossFight', false, 'half_guard', 2, true, NULL
),

(
  'wb-c2-tour', 'white', 36,
  'Intermediate Tournament',
  'Your first tournament bracket — three fights using Closed Guard and Half Guard skills.',
  '{}', 'intermediateTournament', false, 'half_guard', 2, false, NULL
);


-- ════════════════════════════════════════════════════════════════════════════
-- CYCLE 3 — Top Game (Side Control + Mount)
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO units (id, belt, order_index, title, description, tags, kind, is_belt_test, topic, cycle_number, is_boss, mini_theory_content) VALUES
(
  'wb-c3-mt0', 'white', 37,
  'Top Game',
  'Top Game',
  '{}', 'miniTheory', false, 'side_control', 3, false,
  $${
    "type": "cycleIntro",
    "screens": [
      {
        "title": "Playing from the Top",
        "body": "The first two cycles trained your guard game. Now we flip the script. Top game is about applying pressure, controlling your opponent's movement, and creating paths to submissions. Side control and mount are the two most dominant positions in BJJ.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "Pressure Is a Skill",
        "body": "Bad top game players just lie on their opponent. Good top game players use weight distribution, chest-to-chest contact, and cross-face pressure to make their opponent feel like they can't breathe — let alone escape.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "What's Coming",
        "body": "Side control principles and mount mechanics, transitions between dominant positions, escapes from both sides (so you understand the defender's logic), and one boss fight.",
        "coachLine": "Top game isn't about sitting still. It's controlled aggression.",
        "show3D": false
      }
    ],
    "buttonLabel": "Start Lessons →"
  }$$
),

(
  'wb-c3-mt1', 'white', 38,
  'Side Control',
  'Side Control',
  '{}', 'miniTheory', false, 'side_control', 3, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "The Foundation of Top Game",
        "body": "Side control is where most passes end up — and where most white belts lose their advantage. The principles here are: chest-to-chest, cross-face pressure to turn their head away, and hip-to-hip contact to remove their frame. Master this, and mount and back takes become natural next steps.",
        "coachLine": "Side control done right feels inescapable. That's the goal.",
        "show3D": false
      }
    ],
    "buttonLabel": "Let's Go →"
  }$$
),

(
  'wb-c3-l1', 'white', 39,
  'Side Control: Pinning Principles',
  'The three contact points that make side control inescapable.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),
(
  'wb-c3-l2', 'white', 40,
  'Side Control: Weight Distribution',
  'How to distribute your weight to flatten the bottom player and kill their escapes.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),
(
  'wb-c3-l3', 'white', 41,
  'Side Control: Transitions',
  'Moving from side control to mount, north-south, and knee-on-belly.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),

(
  'wb-c3-mt2', 'white', 42,
  'Mount',
  'Mount',
  '{}', 'miniTheory', false, 'side_control', 3, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "The Highest Ground",
        "body": "Mount is 4 points in competition and psychologically crushing for the person on the bottom. The challenge: staying there. Beginners get bucked off because they sit too high or base incorrectly. The key is a low, tight mount with hooks under the hips — control the pelvis, control the person.",
        "coachLine": "Mount isn't about sitting on someone. It's about suffocating their options.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn Mount →"
  }$$
),

(
  'wb-c3-l4', 'white', 43,
  'Mount: Establishing & Maintaining',
  'How to achieve mount and stay there when your opponent bucks and bridges.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),
(
  'wb-c3-l5', 'white', 44,
  'Mount: Attacks from Mount',
  'Submission entries from mount: armbar, cross choke, arm triangle.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),
(
  'wb-c3-l6', 'white', 45,
  'Mount: Escaping Mount',
  'The elbow-knee escape and bridge-and-roll from bottom mount — understand both sides.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),

(
  'wb-c3-mt3', 'white', 46,
  'Escapes',
  'Escapes',
  '{}', 'miniTheory', false, 'side_control', 3, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Fighting from the Bottom",
        "body": "Understanding escapes makes you a better top player. The two core escapes from side control — elbow-knee (shrimping out) and bridge-and-roll (upa) — create movement that your opponent has to counter. Knowing both sides of the equation means you can predict reactions and stay one step ahead.",
        "coachLine": "The best guard player knows how to pass. The best passer knows how to escape.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn Escapes →"
  }$$
),

(
  'wb-c3-l7', 'white', 47,
  'Side Control: Elbow-Knee Escape',
  'The elbow-knee (shrimp) escape from bottom side control.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),
(
  'wb-c3-l8', 'white', 48,
  'Side Control: Bridge & Roll',
  'The bridge-and-roll (upa) escape to reverse side control.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),
(
  'wb-c3-l9', 'white', 49,
  'Top Game: Transitions',
  'Linking side control, knee-on-belly, north-south, and mount into a seamless top game.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),

(
  'wb-c3-mt4', 'white', 50,
  'Pressure & Patience',
  'Pressure & Patience',
  '{}', 'miniTheory', false, 'side_control', 3, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "The Mental Game on Top",
        "body": "Top game is won as much in the mind as the body. The urge to rush submissions leads to sloppy escapes by your opponent. Great top players apply steady pressure, wait for the right opening, and punish movement — they don't chase, they react. Patience on top is pressure.",
        "coachLine": "Don't attack the position. Let the position create the attack.",
        "show3D": false
      }
    ],
    "buttonLabel": "Understood →"
  }$$
),

(
  'wb-c3-l10', 'white', 51,
  'Top Game: Mistakes & Fixes',
  'The most common top game errors and the corrections that make them permanent.',
  '{}', 'lesson', false, 'side_control', 3, false, NULL
),

(
  'wb-c3-mr', 'white', 52,
  'Top Game Review',
  'Mixed review covering Side Control, Mount, and Top Game principles.',
  '{}', 'mixedReview', false, 'side_control', 3, false, NULL
),

(
  'wb-c3-mt5', 'white', 53,
  'Know Your Enemy',
  'Know Your Enemy',
  '{}', 'miniTheory', false, 'side_control', 3, false,
  $${
    "type": "bossPrep",
    "screens": [
      {
        "title": "Meet The Chain Passer",
        "body": "The Chain Passer never stays in one place. The moment you start your escape, they transition — side control to knee-on-belly to mount to back. They're always one step ahead. To beat them: you need to interrupt the chain early, before they settle, and make space the instant you feel them shift.",
        "coachLine": "React before they settle. Your window is small.",
        "show3D": false
      }
    ],
    "buttonLabel": "Face the Boss →"
  }$$
),

(
  'wb-c3-boss', 'white', 54,
  'Boss: The Chain Passer',
  'Face The Chain Passer — a top player who transitions relentlessly and punishes every escape attempt.',
  '{}', 'bossFight', false, 'side_control', 3, true, NULL
);


-- ════════════════════════════════════════════════════════════════════════════
-- CYCLE 4 — Finishing (Back Control + Open Guard)
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO units (id, belt, order_index, title, description, tags, kind, is_belt_test, topic, cycle_number, is_boss, mini_theory_content) VALUES
(
  'wb-c4-mt0', 'white', 55,
  'Back Control & Finishing',
  'Back Control & Finishing',
  '{}', 'miniTheory', false, 'back_control', 4, false,
  $${
    "type": "cycleIntro",
    "screens": [
      {
        "title": "The Final Frontier",
        "body": "Back control is the highest value position in BJJ — 4 points in competition, and near-impossible to escape if taken correctly. Combined with open guard fundamentals and a choke arsenal, Cycle 4 turns you into a finisher.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "Why Chokes Win Fights",
        "body": "Unlike joint locks, chokes work regardless of size, flexibility, or strength. The rear naked choke, bow and arrow, and cross collar choke are your three essential finishes. Each is available from different positions and requires a different grip system.",
        "coachLine": null,
        "show3D": false
      },
      {
        "title": "What's Coming",
        "body": "Back control mechanics, open guard fundamentals, three essential chokes, and a final boss fight. After this, you'll sit for the White Belt Final Tournament — the capstone of your journey.",
        "coachLine": "This is where white belts become dangerous. Let's finish it.",
        "show3D": false
      }
    ],
    "buttonLabel": "Start Lessons →"
  }$$
),

(
  'wb-c4-mt1', 'white', 56,
  'Back Control',
  'Back Control',
  '{}', 'miniTheory', false, 'back_control', 4, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Behind Them, In Control",
        "body": "Back control means you're behind your opponent with your hooks in — one hook inside each hip. The seatbelt grip (one arm over the shoulder, one under the armpit) keeps you attached. From here, your opponent can't see you, can't grab you, and can't use their legs against you. It's the most dangerous position in grappling.",
        "coachLine": "The back is the endgame. Learn to hold it.",
        "show3D": false
      }
    ],
    "buttonLabel": "Let's Go →"
  }$$
),

(
  'wb-c4-l1', 'white', 57,
  'Back Control: Seatbelt Grip',
  'Establishing and maintaining the seatbelt grip from back control.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),
(
  'wb-c4-l2', 'white', 58,
  'Back Control: Body Triangle',
  'Using the body triangle as an alternative to hooks — and when to switch.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),
(
  'wb-c4-l3', 'white', 59,
  'Back Control: Escaping the Back',
  'The defender''s perspective — how to escape back control before the choke lands.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),

(
  'wb-c4-mt2', 'white', 60,
  'Open Guard',
  'Open Guard',
  '{}', 'miniTheory', false, 'back_control', 4, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Guard Without the Lock",
        "body": "Open guard is a family of guard positions where your legs aren't locked around your opponent — collar-sleeve, De La Riva, lasso, spider, and more. The power of open guard is range management: you use your feet on their hips and grips on their sleeves to keep distance and create sweep opportunities.",
        "coachLine": "Open guard is the most creative position in BJJ. Start simple.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn Open Guard →"
  }$$
),

(
  'wb-c4-l4', 'white', 61,
  'Open Guard: Collar-Sleeve',
  'Collar-sleeve guard: grip structure, distance management, and attacks.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),
(
  'wb-c4-l5', 'white', 62,
  'Open Guard: De La Riva Entry',
  'De La Riva guard: hooking the lead leg and controlling distance.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),
(
  'wb-c4-l6', 'white', 63,
  'Open Guard: Passing Open Guard',
  'How to pass open guard — understanding the top player''s toolkit.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),

(
  'wb-c4-mt3', 'white', 64,
  'Chokes',
  'Chokes',
  '{}', 'miniTheory', false, 'back_control', 4, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Your Three Finishing Chokes",
        "body": "The rear naked choke (RNC) is available from back control — it squeezes both carotids simultaneously. The bow and arrow choke uses the gi collar for maximum leverage and is one of the highest-percentage chokes in competition. The cross collar choke works from mount or guard and requires patience and good grips. All three produce unconsciousness in seconds when applied correctly.",
        "coachLine": "These aren't just techniques. These are match-enders.",
        "show3D": false
      }
    ],
    "buttonLabel": "Learn the Chokes →"
  }$$
),

(
  'wb-c4-l7', 'white', 65,
  'Rear Naked Choke',
  'The rear naked choke: blade of the arm, squeeze mechanics, and the tap.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),
(
  'wb-c4-l8', 'white', 66,
  'Bow & Arrow Choke',
  'The bow and arrow choke: collar grip, leg hook, and finishing extension.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),
(
  'wb-c4-l9', 'white', 67,
  'Cross Collar Choke',
  'The cross collar choke from mount and guard: grips and the pull-push finish.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),

(
  'wb-c4-mt4', 'white', 68,
  'The Final Push',
  'The Final Push',
  '{}', 'miniTheory', false, 'back_control', 4, false,
  $${
    "type": "blockIntro",
    "screens": [
      {
        "title": "Bringing It All Together",
        "body": "You've trained guard, top game, and finishing. This final lesson is about integration — how all four cycles flow into each other. Closed guard breaks posture → submission or sweep. Sweep leads to top game. Back take from half guard leads to choke. Every technique you've learned has connective tissue. This lesson shows the map.",
        "coachLine": "You're not learning moves. You're learning a language. This is the grammar.",
        "show3D": false
      }
    ],
    "buttonLabel": "Final Lesson →"
  }$$
),

(
  'wb-c4-l10', 'white', 69,
  'Putting It All Together',
  'How all four cycles connect — the full picture of White Belt BJJ.',
  '{}', 'lesson', false, 'back_control', 4, false, NULL
),

(
  'wb-c4-mr', 'white', 70,
  'Full White Belt Review',
  'Comprehensive mixed review covering all four cycles of the White Belt curriculum.',
  '{}', 'mixedReview', false, 'back_control', 4, false, NULL
),

(
  'wb-c4-mt5', 'white', 71,
  'Know Your Enemy',
  'Know Your Enemy',
  '{}', 'miniTheory', false, 'back_control', 4, false,
  $${
    "type": "bossPrep",
    "screens": [
      {
        "title": "Meet The Pressure Player",
        "body": "The Pressure Player is the final boss of White Belt. They pass guard with weight and aggression, establish side control and mount systematically, and wait for submission openings. They've seen every escape. To beat them, you need everything: guard retention, smart escapes, and when you get top — the patience to finish.",
        "coachLine": "This is your graduation exam. Show everything you've learned.",
        "show3D": false
      }
    ],
    "buttonLabel": "Face the Final Boss →"
  }$$
),

(
  'wb-c4-boss', 'white', 72,
  'Boss: The Pressure Player',
  'The final boss of White Belt — a complete grappler who tests everything you''ve learned.',
  '{}', 'bossFight', false, 'back_control', 4, true, NULL
),

(
  'wb-final', 'white', 73,
  'White Belt Final Tournament',
  'Five-fight tournament bracket. Complete this to earn your White Belt Stripe.',
  '{}', 'finalTournament', false, 'back_control', 4, false, NULL
);
