#!/usr/bin/env python3
"""
Generate 8 unit-specific BJJ questions per lesson unit and upload to Supabase.

Questions are tagged with unit_id so each lesson gets its own question pool.
This fixes the bug where all lessons in a cycle shared the same generic questions.
"""

import json
import os
import re
import sys
import time
import requests

# ── Credentials ───────────────────────────────────────────────────────────────
SUPABASE_URL = os.environ["SUPABASE_URL"]
ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
SECRET_KEY = os.environ["SUPABASE_SECRET_KEY"]
ANTHROPIC_API_KEY = os.environ["ANTHROPIC_API_KEY"]
ANTHROPIC_MODEL = "claude-haiku-4-5-20251001"

BASE = f"{SUPABASE_URL}/rest/v1"

# ── Supabase helpers ───────────────────────────────────────────────────────────

def fetch_lesson_units():
    url = f"{BASE}/units?kind=eq.lesson&select=id,title,topic,order_index&order=order_index"
    resp = requests.get(url, headers={"apikey": ANON_KEY, "Authorization": f"Bearer {ANON_KEY}"})
    resp.raise_for_status()
    return resp.json()


def upsert_questions(rows: list):
    url = f"{BASE}/questions"
    resp = requests.post(
        url,
        headers={
            "apikey": SECRET_KEY,
            "Authorization": f"Bearer {SECRET_KEY}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
        json=rows,
    )
    if resp.status_code not in (200, 201, 204):
        raise Exception(f"Upsert failed {resp.status_code}: {resp.text[:500]}")


def existing_unit_question_count(unit_id: str) -> int:
    url = f"{BASE}/questions?unit_id=eq.{unit_id}&select=id&format=neq.mcq3"
    resp = requests.get(url, headers={
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {ANON_KEY}",
        "Prefer": "count=exact",
    })
    cr = resp.headers.get("Content-Range", "0/0")
    return int(cr.split("/")[-1]) if "/" in cr else 0


# ── Claude API ─────────────────────────────────────────────────────────────────

def call_claude(prompt: str) -> str:
    url = "https://api.anthropic.com/v1/messages"
    headers = {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    body = {
        "model": ANTHROPIC_MODEL,
        "max_tokens": 4096,
        "messages": [{"role": "user", "content": prompt}],
    }
    resp = requests.post(url, headers=headers, json=body)
    resp.raise_for_status()
    return resp.json()["content"][0]["text"].strip()


def extract_json(raw: str) -> str:
    match = re.search(r'```(?:json)?\s*([\s\S]*?)```', raw)
    if match:
        return match.group(1).strip()
    return raw.strip()


# ── Question generation ────────────────────────────────────────────────────────

TOPIC_CONTEXT = {
    "closed_guard": "Player is on their back with legs locked around opponent's waist (closed guard).",
    "half_guard": "Player is on their back with one of opponent's legs trapped between their legs (half guard).",
    "side_control": "Player is in top or bottom side control / mount position.",
    "back_control": "Player is attacking or defending from back control, or working open guard.",
}

def build_prompt(unit: dict, count: int = 8) -> str:
    topic_context = TOPIC_CONTEXT.get(unit["topic"], "BJJ grappling scenario.")
    return f"""You are a BJJ curriculum designer for a Duolingo-style app.

LESSON: {unit['title']}
TOPIC CONTEXT: {topic_context}
FOCUS: Generate questions specifically about the techniques and decisions in "{unit['title']}". Every question must be directly relevant to this specific lesson — not generic BJJ.

Generate exactly {count} BJJ quiz questions for WHITE BELT level.

RULES:
1. Questions must test DECISIONS, not memorization. "What should you do?" not "What is this called?"
2. All questions must be SPECIFIC to "{unit['title']}" — no generic closed guard / half guard questions
3. White belt level only — fundamental concepts, no leg locks or advanced techniques
4. Mix formats: mcq4 ({count//2}x), mcq2 (1x), trueFalse (2x), fillBlank (1x)
5. For mcq4: exactly 4 options, one correct
6. For mcq2: exactly 2 options, one correct
7. For trueFalse: options must be exactly ["True", "False"]
8. For fillBlank: prompt has a ___ blank, options has 4 choices including the correct word/phrase
9. correct_answer must match one of the options EXACTLY
10. Explanation: 1-2 sentences explaining WHY that answer is correct
11. Difficulty: 1 (easy/concept), 2 (application), 3 (timing/nuance)
12. coach_note: optional short tip — only if genuinely useful, otherwise null

Return ONLY a valid JSON array with exactly {count} objects. No markdown, no explanation.

Each object must have ALL these fields:
{{"format":"mcq4","prompt":"...","options":["..."],"correct_answer":"...","explanation":"...","difficulty":1,"coach_note":null}}"""


def generate_questions(unit: dict, count: int = 8) -> list:
    prompt = build_prompt(unit, count)
    for attempt in range(2):
        try:
            raw = call_claude(prompt)
            questions = json.loads(extract_json(raw))
            if not isinstance(questions, list):
                raise ValueError("Expected JSON array")

            required = {"format", "prompt", "options", "correct_answer", "explanation", "difficulty"}
            valid = []
            for q in questions:
                if not isinstance(q, dict):
                    continue
                missing = required - set(q.keys())
                if missing:
                    print(f"    Warning: missing fields {missing}, skipping")
                    continue
                if q["correct_answer"] not in q["options"]:
                    print(f"    Warning: correct_answer not in options, skipping")
                    continue
                valid.append(q)

            if len(valid) < count - 2:
                raise ValueError(f"Only got {len(valid)} valid questions")

            return valid[:count]

        except Exception as e:
            if attempt == 0:
                print(f"    Attempt 1 failed: {e}. Retrying...")
                time.sleep(2)
            else:
                print(f"    Attempt 2 failed: {e}. Skipping unit.")
                return []
    return []


def assign_ids(unit_id: str, questions: list) -> list:
    """Assign DB-ready fields to each generated question."""
    # Use unit_id as ID prefix, e.g. wb-c1-l4 → q-wb-c1-l4-01
    prefix = f"q-{unit_id}"
    result = []
    for i, q in enumerate(questions, start=1):
        result.append({
            "id": f"{prefix}-{i:02d}",
            "unit_id": unit_id,
            "topic": None,       # topic-based pool not used for unit-specific questions
            "belt_level": "white",
            "format": q["format"],
            "prompt": q["prompt"],
            "options": q["options"],
            "correct_answer": q["correct_answer"],
            "explanation": q["explanation"],
            "difficulty": int(q["difficulty"]),
            "coach_note": q.get("coach_note"),
            "tags": [],
            "perspective": None,
        })
    return result


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Fetching lesson units from Supabase...")
    units = fetch_lesson_units()
    total = len(units)
    print(f"Found {total} lesson units.\n")

    skip_if_exists = "--force" not in sys.argv
    if skip_if_exists:
        print("(use --force to regenerate existing unit questions)\n")

    success_count = 0
    skipped_count = 0
    error_count = 0

    for i, unit in enumerate(units, start=1):
        unit_id = unit["id"]
        title = unit["title"]

        # Skip if unit already has questions (unless --force)
        if skip_if_exists:
            existing = existing_unit_question_count(unit_id)
            if existing > 0:
                print(f"[{i}/{total}] {unit_id} — skip ({existing} questions exist)")
                skipped_count += 1
                continue

        print(f"[{i}/{total}] {unit_id}: {title}...", end=" ", flush=True)
        questions = generate_questions(unit, count=8)

        if not questions:
            print("FAILED")
            error_count += 1
            continue

        rows = assign_ids(unit_id, questions)

        try:
            upsert_questions(rows)
            print(f"generated {len(rows)} ✓")
            success_count += 1
        except Exception as e:
            print(f"UPLOAD ERROR: {e}")
            error_count += 1

        time.sleep(0.5)  # Rate limit

    print(f"\nDone. {success_count} generated, {skipped_count} skipped, {error_count} failed out of {total} units.")


if __name__ == "__main__":
    main()
