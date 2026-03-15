#!/usr/bin/env python3
"""Generate battle-mode questions for BJJ Mind.

Battle positions with both top and bottom perspectives:
  closed_guard, half_guard, side_control, mount, back_control, open_guard

Target: 40 questions per position+perspective bucket = 480 total
Format: mcq3 (3 options, one correct) — battle-specific format
Style: urgent, situational — "You're in X, opponent does Y. What do you do?"

ID format: q-{pos_short}-{persp_short}-{index:03d}
  e.g. q-cg-top-001, q-hg-bot-001
"""

import json
import os
import sys
import urllib.request
import urllib.error
import urllib.parse
import anthropic

# ── Config ───────────────────────────────────────────────────────────────────
ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W")
BASE = os.environ.get("SUPABASE_URL", "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1")

HEADERS = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Content-Type": "application/json",
}

TARGET_PER_BUCKET = 40

# ── Battle position config ────────────────────────────────────────────────────

BATTLE_POSITIONS = [
    {
        "position": "closed_guard",
        "id_short": "cg",
        "top": {
            "description": "you are on top in your opponent's closed guard, trying to pass or survive",
            "context": "You are on top, opponent has closed guard around your waist. Your goal is to pass or stay safe.",
            "scenarios": "posture up, grip fighting, guard opening attempts, defending sweeps, starting a pass, weight distribution, elbow positioning",
        },
        "bottom": {
            "description": "you are on bottom with closed guard locked around opponent's waist, attacking or maintaining",
            "context": "You are on your back with legs locked around opponent's waist in closed guard.",
            "scenarios": "breaking posture, sweep setups (scissor, hip bump), submission entries (triangle, armbar, kimura), maintaining guard when opponent stands",
        },
    },
    {
        "position": "half_guard",
        "id_short": "hg",
        "top": {
            "description": "you are on top in half guard (one leg trapped), working to pass",
            "context": "You are on top, opponent has trapped one of your legs in half guard. You want to flatten them and pass.",
            "scenarios": "crossface and underhook battle, whizzer counter, flattening the opponent, hip switch pass, underhook recovery, tripod pressure",
        },
        "bottom": {
            "description": "you are on bottom in half guard (one leg trapped), sweeping or recovering full guard",
            "context": "You are on bottom in half guard — one of opponent's legs trapped. You want to sweep or recover guard.",
            "scenarios": "fighting for underhook, knee shield, deep half guard entry, old school sweep, lockdown, getting to turtle, recovering full guard",
        },
    },
    {
        "position": "side_control",
        "id_short": "sc",
        "top": {
            "description": "you are on top in side control, maintaining or transitioning",
            "context": "You are on top in side control, perpendicular to opponent. You want to maintain and attack.",
            "scenarios": "cross-face and near arm control, transitioning to mount or north-south, kimura from side control, responding to opponent's frame or bridge, weight distribution",
        },
        "bottom": {
            "description": "you are on bottom under side control, escaping or surviving",
            "context": "You are on bottom, pinned under opponent's side control. You want to escape.",
            "scenarios": "framing at hip and neck, shrimping to recover guard, bridging and rolling, turning in to shoot single, getting to turtle, preventing mount transition",
        },
    },
    {
        "position": "mount",
        "id_short": "mt",
        "top": {
            "description": "you are on top in mount, maintaining or attacking",
            "context": "You are on top in mount (sitting on opponent's torso). You want to maintain and submit.",
            "scenarios": "responding to upa bridge, responding to elbow-knee escape, advancing to high mount, arm triangle setup, armbar from mount, grapevine hooks, cross-face in mount",
        },
        "bottom": {
            "description": "you are on bottom under mount, escaping",
            "context": "You are on bottom, opponent is in mount on top of you. You must escape.",
            "scenarios": "upa escape timing (trap arm and leg), elbow-knee escape direction, dealing with high mount, when to upa vs elbow-knee, preventing armbar when escaping, creating space",
        },
    },
    {
        "position": "back_control",
        "id_short": "bc",
        "top": {
            "description": "you have taken the back with hooks, attacking",
            "context": "You have your opponent's back with hooks in and seatbelt grip. You want to finish.",
            "scenarios": "seatbelt grip, hook positioning (inside thighs), rear naked choke setup, defending when opponent grabs your arm, maintaining hooks when they try to turn, body triangle option",
        },
        "bottom": {
            "description": "you are defending back control, escaping",
            "context": "Opponent has your back with hooks and seatbelt. You must escape without getting choked.",
            "scenarios": "protecting the neck (chin tuck, two hands), turning toward the choking arm, removing hooks, sliding to half guard, sitting out escape, dealing with body triangle",
        },
    },
    {
        "position": "open_guard",
        "id_short": "og",
        "top": {
            "description": "you are on top passing open guard",
            "context": "You are on top trying to pass your opponent's open guard (spider, collar sleeve, lasso, etc.).",
            "scenarios": "grip stripping, toreando pass mechanics, leg weave pass (smash pass), dealing with leg extensions, posture management, stacking the guard player",
        },
        "bottom": {
            "description": "you are playing open guard, sweeping or attacking",
            "context": "You are on bottom playing open guard — trying to sweep, submit, or maintain guard.",
            "scenarios": "grip creation (collar sleeve, spider), maintaining distance with feet on hips, sweep entries, getting back to closed guard, recovering when they break grips, lasso guard entry",
        },
    },
]


# ── Supabase helpers ──────────────────────────────────────────────────────────

def rest_count_bucket(position: str, perspective: str) -> int:
    """Count existing questions for a specific position+perspective bucket."""
    url = f"{BASE}/questions?select=id&topic=eq.{urllib.parse.quote(position)}&perspective=eq.{perspective}"
    req = urllib.request.Request(url, headers=HEADERS)
    req.add_header("Prefer", "count=exact")
    with urllib.request.urlopen(req) as resp:
        cr = resp.headers.get("Content-Range", "0/0")
        return int(cr.split("/")[-1]) if "/" in cr else 0


def rest_upsert(table: str, rows: list):
    url = f"{BASE}/{table}"
    data = json.dumps(rows).encode()
    req = urllib.request.Request(url, data=data, method="POST", headers=HEADERS)
    req.add_header("Prefer", "resolution=merge-duplicates,return=minimal")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        body = e.read()
        raise Exception(f"UPSERT {table} failed {e.code}: {body[:500]}")


def rest_count_total() -> int:
    url = f"{BASE}/questions?select=id"
    req = urllib.request.Request(url, headers=HEADERS)
    req.add_header("Prefer", "count=exact")
    with urllib.request.urlopen(req) as resp:
        cr = resp.headers.get("Content-Range", "0/0")
        return int(cr.split("/")[-1]) if "/" in cr else 0


# ── Existing ID tracking ──────────────────────────────────────────────────────

def get_existing_ids_for_bucket(position: str, perspective: str) -> set:
    """Get existing question IDs for a bucket to determine next index."""
    url = f"{BASE}/questions?select=id&topic=eq.{urllib.parse.quote(position)}&perspective=eq.{perspective}&limit=1000"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        rows = json.loads(resp.read())
    return {r["id"] for r in rows}


# ── Claude generation ────────────────────────────────────────────────────────

def build_battle_prompt(position_cfg: dict, perspective: str, count: int) -> str:
    pos = position_cfg["position"]
    persp_cfg = position_cfg[perspective]
    perspective_label = "TOP (dominant/attacking)" if perspective == "top" else "BOTTOM (defending/attacking from guard)"

    return f"""You are a BJJ curriculum designer creating battle-mode quiz questions for a mobile app.

POSITION: {pos.replace("_", " ").upper()}
PERSPECTIVE: {perspective_label}
DESCRIPTION: {persp_cfg['description']}
SCENARIO CONTEXT: {persp_cfg['context']}
KEY SCENARIOS TO COVER: {persp_cfg['scenarios']}

Generate exactly {count} BJJ quiz questions for WHITE BELT level.

CRITICAL STYLE RULES:
1. Questions MUST be situational and urgent — "You're in X, opponent does Y. What do you do?"
2. NOT conceptual/trivia — NOT "What is the principle of..." or "Which technique is named..."
3. Frame from the player's perspective based on the role above
4. Test DECISIONS in the moment, not memorization
5. White belt level — no leg locks, no advanced concepts
6. All questions use mcq3 format: exactly 3 options, exactly one correct
7. Distractors must be plausible but wrong for that specific situation
8. Difficulty: 1 (obvious decision), 2 (requires some understanding), 3 (timing/nuance)
9. Explanation: 1-2 sentences WHY that answer is correct
10. coach_note: short tip or null

Return ONLY a valid JSON array with exactly {count} objects. No markdown, no explanation.

Each object must have ALL these fields:
{{
  "format": "mcq3",
  "prompt": "Situational question text",
  "options": ["option1", "option2", "option3"],
  "correct_answer": "must match one option exactly",
  "explanation": "1-2 sentence explanation",
  "difficulty": 1 | 2 | 3,
  "coach_note": "short tip or null"
}}

Example ({pos.replace("_", " ")} {perspective}):
{{"format":"mcq3","prompt":"You're in {pos.replace("_", " ")} {'top — opponent frames their forearm into your neck and starts to turn in.' if perspective == 'top' else 'bottom — opponent is flattening you and pinning your near arm.'} What do you do?","options":["{_example_option_a(pos, perspective)}","{_example_option_b(pos, perspective)}","{_example_option_c(pos, perspective)}"],"correct_answer":"{_example_correct(pos, perspective)}","explanation":"Short tactical explanation for white belt.","difficulty":2,"coach_note":null}}
"""


def _example_option_a(pos: str, perspective: str) -> str:
    examples = {
        ("closed_guard", "top"): "Posture up and work to open the guard",
        ("closed_guard", "bottom"): "Break their posture and pull them close",
        ("half_guard", "top"): "Fight for the crossface and flatten them",
        ("half_guard", "bottom"): "Fight for the underhook and go to deep half",
        ("side_control", "top"): "Re-establish cross-face and lower your hips",
        ("side_control", "bottom"): "Frame at hip and neck, then shrimp",
        ("mount", "top"): "Post your arm out and follow the bridge",
        ("mount", "bottom"): "Trap their arm and leg, then bridge",
        ("back_control", "top"): "Tighten seatbelt and switch to collar choke",
        ("back_control", "bottom"): "Protect your neck and turn toward their choking arm",
        ("open_guard", "top"): "Strip their grips and pass around",
        ("open_guard", "bottom"): "Replace feet on hips and reset grips",
    }
    return examples.get((pos, perspective), "Make the correct adjustment")


def _example_option_b(pos: str, perspective: str) -> str:
    examples = {
        ("closed_guard", "top"): "Immediately try to stand up",
        ("closed_guard", "bottom"): "Open guard and push them away",
        ("half_guard", "top"): "Pull your leg out forcefully",
        ("half_guard", "bottom"): "Immediately try to stand up",
        ("side_control", "top"): "Back away and re-establish from standing",
        ("side_control", "bottom"): "Push their head away",
        ("mount", "top"): "Squeeze knees and lean forward with all weight",
        ("mount", "bottom"): "Push straight up with both hands",
        ("back_control", "top"): "Release hooks and reset",
        ("back_control", "bottom"): "Try to roll them over your head",
        ("open_guard", "top"): "Dive in to try a quick submission",
        ("open_guard", "bottom"): "Let grips go and play closed guard",
    }
    return examples.get((pos, perspective), "Take a less effective approach")


def _example_option_c(pos: str, perspective: str) -> str:
    examples = {
        ("closed_guard", "top"): "Drop your hips to the mat and wait",
        ("closed_guard", "bottom"): "Let them posture up and conserve energy",
        ("half_guard", "top"): "Switch to the other side immediately",
        ("half_guard", "bottom"): "Flatten out and accept bad position",
        ("side_control", "top"): "Immediately transition to north-south",
        ("side_control", "bottom"): "Turn away from them",
        ("mount", "top"): "Abandon mount and take side control",
        ("mount", "bottom"): "Turn your head to one side and wait",
        ("back_control", "top"): "Let them turn and re-establish from front",
        ("back_control", "bottom"): "Roll forward immediately",
        ("open_guard", "top"): "Back away and wait for them to close guard",
        ("open_guard", "bottom"): "Sit up and try to shoot a takedown",
    }
    return examples.get((pos, perspective), "Do nothing and stall")


def _example_correct(pos: str, perspective: str) -> str:
    return _example_option_a(pos, perspective)


def parse_battle_questions(raw: str) -> list:
    """Parse Claude's JSON response for battle questions."""
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.split("\n")
        raw = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
    raw = raw.strip()

    questions = json.loads(raw)
    if not isinstance(questions, list):
        raise ValueError("Expected JSON array")

    required_fields = {"format", "prompt", "options", "correct_answer", "explanation", "difficulty"}
    valid = []
    for q in questions:
        if not isinstance(q, dict):
            continue
        missing = required_fields - set(q.keys())
        if missing:
            print(f"  Warning: question missing fields {missing}, skipping")
            continue
        if q.get("format") != "mcq3":
            q["format"] = "mcq3"  # enforce
        if len(q.get("options", [])) != 3:
            print(f"  Warning: expected 3 options, got {len(q.get('options', []))}, skipping")
            continue
        if q["correct_answer"] not in q["options"]:
            print(f"  Warning: correct_answer not in options for '{q['prompt'][:50]}...', skipping")
            continue
        valid.append(q)
    return valid


def generate_for_bucket(
    client: anthropic.Anthropic,
    position_cfg: dict,
    perspective: str,
    count: int,
    start_index: int,
) -> list:
    """Generate `count` questions for a specific position+perspective bucket."""
    if count <= 0:
        return []

    pos = position_cfg["position"]
    id_short = position_cfg["id_short"]
    persp_short = "top" if perspective == "top" else "bot"

    prompt = build_battle_prompt(position_cfg, perspective, count)

    for attempt in range(2):
        try:
            message = client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=8000,
                messages=[{"role": "user", "content": prompt}],
            )
            raw = message.content[0].text
            questions = parse_battle_questions(raw)

            if len(questions) < max(1, count - 5):
                raise ValueError(f"Only got {len(questions)} valid questions, expected ~{count}")

            result = []
            for i, q in enumerate(questions[:count]):
                idx = start_index + i
                q_id = f"q-{id_short}-{persp_short}-{idx:03d}"
                result.append({
                    "id": q_id,
                    "topic": pos,
                    "perspective": perspective,
                    "belt_level": "white",
                    "unit_id": None,
                    "format": "mcq3",
                    "prompt": q["prompt"],
                    "options": q["options"],
                    "correct_answer": q["correct_answer"],
                    "explanation": q["explanation"],
                    "difficulty": int(q["difficulty"]),
                    "coach_note": q.get("coach_note"),
                    "tags": [pos.replace("_", " "), perspective],
                })
            return result

        except Exception as e:
            if attempt == 0:
                print(f"  Attempt 1 failed: {e}. Retrying...")
            else:
                print(f"  Attempt 2 failed: {e}. Skipping bucket.")
                return []

    return []


# ── Main ─────────────────────────────────────────────────────────────────────

def load_env_file(path: str):
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, _, v = line.partition("=")
                    os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    except FileNotFoundError:
        pass


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    for env_path in [
        os.path.join(project_dir, ".env"),
        os.path.join(script_dir, ".env"),
        os.path.expanduser("~/.env"),
    ]:
        load_env_file(env_path)

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: ANTHROPIC_API_KEY environment variable not set.")
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    before_count = rest_count_total()
    print(f"Total questions before: {before_count}")
    print(f"Target per bucket: {TARGET_PER_BUCKET}")
    print()

    all_generated = []
    bucket_results = []

    for pos_cfg in BATTLE_POSITIONS:
        pos = pos_cfg["position"]
        id_short = pos_cfg["id_short"]

        for perspective in ["top", "bottom"]:
            persp_short = "top" if perspective == "top" else "bot"
            existing_count = rest_count_bucket(pos, perspective)
            existing_ids = get_existing_ids_for_bucket(pos, perspective)
            to_generate = max(0, TARGET_PER_BUCKET - existing_count)

            bucket_label = f"{pos} ({perspective})"
            print(f"Bucket: {bucket_label}")
            print(f"  Existing: {existing_count}, Need: {to_generate}", end="")

            if to_generate == 0:
                print(f" — SKIPPING (already at target)")
                bucket_results.append({
                    "bucket": bucket_label,
                    "existing": existing_count,
                    "generated": 0,
                    "final": existing_count,
                })
                continue

            print(f" — generating...")

            # Determine start index based on existing IDs
            # Find highest index among existing IDs with this prefix
            prefix = f"q-{id_short}-{persp_short}-"
            max_idx = 0
            for qid in existing_ids:
                if qid.startswith(prefix):
                    try:
                        idx = int(qid[len(prefix):])
                        max_idx = max(max_idx, idx)
                    except ValueError:
                        pass
            start_index = max_idx + 1

            questions = generate_for_bucket(client, pos_cfg, perspective, to_generate, start_index)

            if not questions:
                print(f"  FAILED — no questions generated")
                bucket_results.append({
                    "bucket": bucket_label,
                    "existing": existing_count,
                    "generated": 0,
                    "final": existing_count,
                })
                continue

            # Upload to Supabase
            try:
                # Upload in batches of 50
                for i in range(0, len(questions), 50):
                    batch = questions[i:i + 50]
                    rest_upsert("questions", batch)
                print(f"  Generated {len(questions)}, uploaded OK")
                all_generated.extend(questions)
                final_count = existing_count + len(questions)
            except Exception as e:
                print(f"  Upload FAILED: {e}")
                all_generated.extend(questions)  # still save to backup
                final_count = existing_count

            bucket_results.append({
                "bucket": bucket_label,
                "existing": existing_count,
                "generated": len(questions),
                "final": final_count,
            })

    # Save backup JSON
    backup_path = os.path.join(os.path.dirname(__file__), "battle_questions_backup.json")
    with open(backup_path, "w") as f:
        json.dump(all_generated, f, indent=2)
    print(f"\nBackup saved to: {backup_path}")

    # Final summary
    after_count = rest_count_total()
    print(f"\n--- Summary ---")
    print(f"Questions before: {before_count}")
    print(f"Questions generated: {len(all_generated)}")
    print(f"Questions after: {after_count}")
    print()
    print(f"{'Bucket':<35} {'Before':>6} {'Generated':>9} {'After':>6}")
    print("-" * 60)
    for r in bucket_results:
        print(f"{r['bucket']:<35} {r['existing']:>6} {r['generated']:>9} {r['final']:>6}")


if __name__ == "__main__":
    main()
