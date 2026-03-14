#!/usr/bin/env python3
"""Generate 20 additional BJJ questions per topic using Claude API and upload to Supabase.

Topics: closed_guard, closed_guard_attacks, guard_passing, side_control_top,
        side_control_escape, mount_control, mount_escape, back_control,
        submissions, takedowns

Each topic already has 8 questions (q-xx-01 to q-xx-08).
This script generates q-xx-09 to q-xx-28 (20 more per topic = 200 total).
"""

import json
import os
import sys
import urllib.request
import urllib.error
import anthropic

# ── Supabase config ──────────────────────────────────────────────────────────
ANON_KEY = "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W"
BASE = "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1"

HEADERS = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Content-Type": "application/json",
}

# ── Topic config ─────────────────────────────────────────────────────────────
TOPICS = [
    {
        "slug": "closed_guard",
        "id_prefix": "q-cg",
        "start_index": 9,
        "description": "controlling the opponent in closed guard, breaking posture, maintaining guard",
        "context": "Player is on their back with legs locked around opponent's waist (closed guard).",
    },
    {
        "slug": "closed_guard_attacks",
        "id_prefix": "q-cga",
        "start_index": 9,
        "description": "attacks from closed guard: triangles, armbars, sweeps (hip bump, scissor), omoplatas",
        "context": "Player has closed guard and is looking to attack or sweep.",
    },
    {
        "slug": "guard_passing",
        "id_prefix": "q-gp",
        "start_index": 9,
        "description": "breaking open and passing the closed guard from the top position",
        "context": "Player is on top, trying to pass their opponent's closed guard.",
    },
    {
        "slug": "side_control_top",
        "id_prefix": "q-sc",
        "start_index": 9,
        "description": "maintaining side control from the top, applying pressure, transitioning",
        "context": "Player is on top in side control (perpendicular to opponent).",
    },
    {
        "slug": "side_control_escape",
        "id_prefix": "q-sce",
        "start_index": 9,
        "description": "escaping from bottom side control using frames, shrimping, bridging",
        "context": "Player is on the bottom, trapped under opponent's side control.",
    },
    {
        "slug": "mount_control",
        "id_prefix": "q-mc",
        "start_index": 9,
        "description": "maintaining and advancing from mount position on top",
        "context": "Player is on top in mount (sitting on opponent's torso).",
    },
    {
        "slug": "mount_escape",
        "id_prefix": "q-me",
        "start_index": 9,
        "description": "escaping from the bottom of mount using upa (bridge and roll) and elbow-knee",
        "context": "Player is on the bottom, trapped under opponent's mount.",
    },
    {
        "slug": "back_control",
        "id_prefix": "q-bc",
        "start_index": 9,
        "description": "taking and keeping the back, hooks, seatbelt, rear naked choke setup",
        "context": "Player has their opponent's back with hooks in (or is working to establish them).",
    },
    {
        "slug": "submissions",
        "id_prefix": "q-sub",
        "start_index": 9,
        "description": "basic submissions: armbar, triangle, kimura, rear naked choke, guillotine",
        "context": "Player is setting up or finishing a submission from a controlling position.",
    },
    {
        "slug": "takedowns",
        "id_prefix": "q-td",
        "start_index": 9,
        "description": "standup wrestling: double-leg, single-leg, sprawl defense, grip fighting",
        "context": "Match starts standing — players are working to get the fight to the ground.",
    },
]

FORMATS = ["mcq4", "mcq4", "mcq4", "mcq4", "mcq4", "mcq2", "mcq2", "trueFalse", "trueFalse", "fillBlank",
           "mcq4", "mcq4", "mcq4", "mcq2", "mcq2", "trueFalse", "trueFalse", "fillBlank", "mcq4", "mcq2"]

# ── Supabase helpers ─────────────────────────────────────────────────────────

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


def rest_count(table: str) -> int:
    url = f"{BASE}/{table}?select=id"
    req = urllib.request.Request(url, headers=HEADERS)
    req.add_header("Prefer", "count=exact")
    with urllib.request.urlopen(req) as resp:
        cr = resp.headers.get("Content-Range", "0/0")
        return int(cr.split("/")[-1]) if "/" in cr else 0


# ── Claude generation ────────────────────────────────────────────────────────

def build_prompt(topic: dict, count: int = 20) -> str:
    format_list = ", ".join(set(FORMATS))
    return f"""You are a BJJ curriculum designer creating quiz questions for a Duolingo-style BJJ app.

TOPIC: {topic['slug']}
DESCRIPTION: {topic['description']}
SCENARIO CONTEXT: {topic['context']}

Generate exactly {count} BJJ quiz questions for WHITE BELT level. Focus on practical decision-making ("what do you do when..."), not technique name trivia.

RULES:
1. Questions must test DECISIONS, not memorization. Ask "what should you do?" not "what is this called?"
2. White belt level only — fundamental concepts, no leg locks or advanced techniques
3. Mix formats evenly: use mcq4 (8x), mcq2 (4x), trueFalse (5x), fillBlank (3x)
4. For mcq4: exactly 4 options, one correct
5. For mcq2: exactly 2 options, one correct
6. For trueFalse: options must be exactly ["True", "False"]
7. For fillBlank: prompt has a ___ blank, options has 4 choices including the correct word/phrase
8. correct_answer must match one of the options EXACTLY (same capitalization, same text)
9. Explanation: 1-2 sentences max explaining WHY that answer is correct
10. Difficulty: 1 (easy/concept), 2 (application), 3 (timing/nuance)
11. coach_note: optional short tip (can be null) — only add if genuinely useful
12. Do NOT duplicate these common ideas already covered: posture breaking, frame creation, hooks position, tapping when caught — vary the scenarios

Return ONLY a valid JSON array with exactly {count} objects. No markdown, no explanation, just the JSON array.

Each object must have ALL these fields:
{{
  "format": "mcq4" | "mcq2" | "trueFalse" | "fillBlank",
  "prompt": "question text",
  "options": ["option1", "option2", ...],
  "correct_answer": "must match one option exactly",
  "explanation": "1-2 sentence explanation",
  "difficulty": 1 | 2 | 3,
  "coach_note": "short tip or null"
}}

Example mcq4:
{{"format":"mcq4","prompt":"Your opponent plants their elbow on your hip from your closed guard. What should you do?","options":["Break the elbow down and pull them forward","Open guard immediately","Attempt a triangle right away","Push their head back"],"correct_answer":"Break the elbow down and pull them forward","explanation":"Removing their elbow base prevents them from posturing up. Pull them into you immediately after.","difficulty":2,"coach_note":"An elbow on the hip is their first step to standing — kill it early."}}

Example fillBlank:
{{"format":"fillBlank","prompt":"After bridging in the upa escape, roll to the ___ side.","options":["trapped","open","left","right"],"correct_answer":"trapped","explanation":"You roll toward the side where you've trapped their arm and leg — that's the path of least resistance.","difficulty":2,"coach_note":null}}
"""


def parse_questions(raw: str, topic: dict) -> list:
    """Parse Claude's JSON response and add required fields."""
    # Strip any accidental markdown
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
        if q["correct_answer"] not in q["options"]:
            print(f"  Warning: correct_answer not in options for prompt '{q['prompt'][:50]}...', skipping")
            continue
        valid.append(q)

    return valid


def generate_for_topic(client: anthropic.Anthropic, topic: dict) -> list:
    """Call Claude and return list of question dicts with IDs assigned."""
    prompt = build_prompt(topic, count=20)

    for attempt in range(2):
        try:
            message = client.messages.create(
                model="claude-haiku-4-5-20251001",
                max_tokens=8000,
                messages=[{"role": "user", "content": prompt}],
            )
            raw = message.content[0].text
            questions = parse_questions(raw, topic)

            if len(questions) < 15:
                raise ValueError(f"Only got {len(questions)} valid questions, expected ~20")

            # Assign IDs and required DB fields
            result = []
            for i, q in enumerate(questions[:20]):
                idx = topic["start_index"] + i
                q_id = f"{topic['id_prefix']}-{idx:02d}"
                result.append({
                    "id": q_id,
                    "topic": topic["slug"],
                    "belt_level": "white",
                    "unit_id": None,
                    "format": q["format"],
                    "prompt": q["prompt"],
                    "options": q["options"],
                    "correct_answer": q["correct_answer"],
                    "explanation": q["explanation"],
                    "difficulty": int(q["difficulty"]),
                    "coach_note": q.get("coach_note"),
                    "tags": [topic["slug"].replace("_", " ")],
                })
            return result

        except Exception as e:
            if attempt == 0:
                print(f"  Attempt 1 failed: {e}. Retrying...")
            else:
                print(f"  Attempt 2 failed: {e}. Skipping topic.")
                return []

    return []


# ── Main ─────────────────────────────────────────────────────────────────────

def load_env_file(path: str):
    """Load key=value pairs from a .env file into os.environ."""
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
    # Try to load from .env files if env var not already set
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
        print("Set it in your shell or create a .env file with ANTHROPIC_API_KEY=sk-ant-...")
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    print(f"Starting question generation for {len(TOPICS)} topics...")
    print(f"Questions before: {rest_count('questions')}")
    print()

    all_generated = []
    failed_topics = []

    for i, topic in enumerate(TOPICS, 1):
        print(f"Topic {i}/{len(TOPICS)}: {topic['slug']}...", end=" ", flush=True)
        questions = generate_for_topic(client, topic)

        if not questions:
            failed_topics.append(topic["slug"])
            print(f"FAILED")
            continue

        print(f"generated {len(questions)} questions", end=" ")

        # Upload to Supabase
        try:
            rest_upsert("questions", questions)
            print(f"— uploaded OK")
            all_generated.extend(questions)
        except Exception as e:
            print(f"— UPLOAD FAILED: {e}")
            failed_topics.append(topic["slug"])
            # Still save to backup even if upload fails
            all_generated.extend(questions)

    # Save backup JSON
    backup_path = os.path.join(os.path.dirname(__file__), "generated_questions.json")
    with open(backup_path, "w") as f:
        json.dump(all_generated, f, indent=2)
    print(f"\nBackup saved to: {backup_path}")

    # Final count
    total = rest_count("questions")
    print(f"\n--- Summary ---")
    print(f"Topics processed: {len(TOPICS) - len(failed_topics)}/{len(TOPICS)}")
    print(f"Questions generated: {len(all_generated)}")
    print(f"Total questions in DB: {total}")
    if failed_topics:
        print(f"Failed topics: {', '.join(failed_topics)}")
    else:
        print("All topics succeeded.")


if __name__ == "__main__":
    main()
