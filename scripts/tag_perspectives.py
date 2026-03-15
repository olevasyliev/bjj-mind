#!/usr/bin/env python3
"""Tag existing questions with perspective (top/bottom/neutral) using Claude API.

Fetches all questions with perspective=null, determines perspective per question,
and updates them in Supabase via PATCH.

Rules:
- top: attacker/dominant position (guard passing, side control top, mount top, back control top)
- bottom: defender/bottom position (guard retention, escapes, sweeps from bottom)
- neutral: standing/both sides equally

Topic-based shortcuts (no need to call Claude):
- guard_passing       → top
- side_control_top    → top
- mount_control       → top
- back_control        → top
- closed_guard        → bottom
- closed_guard_attacks → bottom
- side_control_escape → bottom
- mount_escape        → bottom
- submissions         → use Claude (varies by question)
- takedowns           → use Claude (varies by question)
"""

import json
import os
import sys
import urllib.request
import urllib.error
import anthropic

# ── Config ───────────────────────────────────────────────────────────────────
ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W")
BASE = os.environ.get("SUPABASE_URL", "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1")

HEADERS = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Content-Type": "application/json",
}

# Topics where perspective can be determined without Claude
TOPIC_PERSPECTIVE_MAP = {
    "guard_passing": "top",
    "side_control_top": "top",
    "mount_control": "top",
    "back_control": "top",
    "closed_guard": "bottom",
    "closed_guard_attacks": "bottom",
    "side_control_escape": "bottom",
    "mount_escape": "bottom",
}

BATCH_SIZE = 50


# ── Supabase helpers ──────────────────────────────────────────────────────────

def rest_fetch_null_perspective() -> list:
    """Fetch all questions where perspective IS NULL."""
    all_rows = []
    offset = 0
    limit = 1000
    while True:
        url = f"{BASE}/questions?select=id,topic,prompt&perspective=is.null&limit={limit}&offset={offset}"
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req) as resp:
            batch = json.loads(resp.read())
        if not batch:
            break
        all_rows.extend(batch)
        if len(batch) < limit:
            break
        offset += limit
    return all_rows


def rest_patch_perspective(question_id: str, perspective: str):
    """PATCH a single question's perspective."""
    url = f"{BASE}/questions?id=eq.{urllib.parse.quote(question_id)}"
    data = json.dumps({"perspective": perspective}).encode()
    req = urllib.request.Request(url, data=data, method="PATCH", headers=HEADERS)
    req.add_header("Prefer", "return=minimal")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        body = e.read()
        raise Exception(f"PATCH questions/{question_id} failed {e.code}: {body[:300]}")


def rest_patch_batch(updates: list[dict]):
    """Update perspectives in batch — one request per question."""
    for item in updates:
        rest_patch_perspective(item["id"], item["perspective"])


# ── Claude tagging ────────────────────────────────────────────────────────────

CLAUDE_PROMPT_TEMPLATE = """You are a BJJ expert. For each question below, determine the player's perspective:
- "top" = attacker/dominant position (guard passing, side control top, mount top, back control)
- "bottom" = defender/bottom position (guard retention, escapes, sweeps from bottom guard)
- "neutral" = standing/both sides equally (takedowns, standup, general principles applying to both)

For submissions: determine from the question context — if it's clearly about applying from top, say "top"; if from guard (bottom), say "bottom"; if ambiguous, say "neutral".

Return ONLY a JSON array where each object has "id" and "perspective" fields.
No markdown, no explanation, just the JSON array.

Questions:
{questions_json}
"""


def tag_with_claude(client: anthropic.Anthropic, questions: list) -> dict:
    """Call Claude to tag perspectives. Returns dict id→perspective."""
    questions_json = json.dumps([{"id": q["id"], "topic": q["topic"], "prompt": q["prompt"]} for q in questions])
    prompt = CLAUDE_PROMPT_TEMPLATE.format(questions_json=questions_json)

    for attempt in range(2):
        try:
            message = client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=4000,
                messages=[{"role": "user", "content": prompt}],
            )
            raw = message.content[0].text.strip()
            if raw.startswith("```"):
                lines = raw.split("\n")
                raw = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
            results = json.loads(raw)
            return {r["id"]: r["perspective"] for r in results}
        except Exception as e:
            if attempt == 0:
                print(f"  Claude attempt 1 failed: {e}. Retrying...")
            else:
                print(f"  Claude attempt 2 failed: {e}. These questions will be skipped.")
                return {}
    return {}


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
    # Load .env files
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

    # Fix urllib.parse import
    import urllib.parse

    print("Fetching questions with perspective=null...")
    questions = rest_fetch_null_perspective()
    print(f"Found {len(questions)} questions to tag.\n")

    if not questions:
        print("Nothing to do.")
        return

    # Split into rule-based and Claude-based
    rule_based = []   # can be determined by topic
    claude_based = []  # need Claude

    for q in questions:
        topic = q.get("topic", "")
        if topic in TOPIC_PERSPECTIVE_MAP:
            rule_based.append({"id": q["id"], "perspective": TOPIC_PERSPECTIVE_MAP[topic]})
        else:
            claude_based.append(q)

    print(f"  Rule-based (topic shortcut): {len(rule_based)}")
    print(f"  Needs Claude (submissions/takedowns/other): {len(claude_based)}\n")

    # Tag rule-based in batches of BATCH_SIZE
    if rule_based:
        print(f"Updating {len(rule_based)} rule-based questions...")
        for i in range(0, len(rule_based), BATCH_SIZE):
            batch = rule_based[i:i + BATCH_SIZE]
            for item in batch:
                rest_patch_perspective(item["id"], item["perspective"])
            print(f"  Batch {i // BATCH_SIZE + 1}: updated {len(batch)} questions")
        print(f"  Done.\n")

    # Tag Claude-based in batches of BATCH_SIZE
    if claude_based:
        print(f"Tagging {len(claude_based)} questions with Claude...")
        tagged = 0
        for i in range(0, len(claude_based), BATCH_SIZE):
            batch = claude_based[i:i + BATCH_SIZE]
            print(f"  Batch {i // BATCH_SIZE + 1}: calling Claude for {len(batch)} questions...", end=" ", flush=True)
            id_to_perspective = tag_with_claude(client, batch)

            if not id_to_perspective:
                print(f"FAILED — skipping this batch")
                continue

            # Update each
            failed = 0
            for q in batch:
                perspective = id_to_perspective.get(q["id"])
                if not perspective:
                    print(f"\n  Warning: no perspective for {q['id']}, skipping")
                    failed += 1
                    continue
                if perspective not in ("top", "bottom", "neutral"):
                    print(f"\n  Warning: invalid perspective '{perspective}' for {q['id']}, skipping")
                    failed += 1
                    continue
                try:
                    rest_patch_perspective(q["id"], perspective)
                    tagged += 1
                except Exception as e:
                    print(f"\n  Error updating {q['id']}: {e}")
                    failed += 1

            print(f"tagged {len(batch) - failed}/{len(batch)}")

        print(f"\n  Done. Tagged {tagged} Claude-based questions.\n")

    # Final verification
    remaining = rest_fetch_null_perspective()
    print(f"--- Summary ---")
    print(f"Questions processed: {len(questions)}")
    print(f"Remaining null perspective: {len(remaining)}")
    if remaining:
        print(f"Still null: {[q['id'] for q in remaining[:20]]}")
    else:
        print("All questions tagged successfully.")


# Fix: import urllib.parse at module level
import urllib.parse

if __name__ == "__main__":
    main()
