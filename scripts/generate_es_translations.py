#!/usr/bin/env python3
"""
Generate Spanish translations for all 74 BJJ Mind units
and upsert them into Supabase unit_translations table.
"""

import json
import re
import time
import requests

# ── Credentials (set via environment variables) ───────────────────────────────
import os
SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
SUPABASE_SECRET_KEY = os.environ["SUPABASE_SECRET_KEY"]
ANTHROPIC_API_KEY = os.environ["ANTHROPIC_API_KEY"]
ANTHROPIC_MODEL = "claude-sonnet-4-6"
LOCALE = "es"


# ── Supabase helpers ──────────────────────────────────────────────────────────
def fetch_units():
    url = f"{SUPABASE_URL}/rest/v1/units?select=id,title,description,kind,mini_theory_content&order=order_index"
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    }
    resp = requests.get(url, headers=headers)
    resp.raise_for_status()
    return resp.json()


def upsert_translation(unit_id, locale, title, description, mini_theory_content):
    """
    Upsert strategy:
    - Try POST (insert). If 409 conflict, PATCH the existing row by (unit_id, locale).
    """
    base_url = f"{SUPABASE_URL}/rest/v1/unit_translations"
    headers = {
        "apikey": SUPABASE_SECRET_KEY,
        "Authorization": f"Bearer {SUPABASE_SECRET_KEY}",
        "Content-Type": "application/json",
    }
    data = {
        "unit_id": unit_id,
        "locale": locale,
        "title": title,
        "description": description,
        "mini_theory_content": mini_theory_content,
    }

    # Try INSERT first
    resp = requests.post(base_url, headers=headers, json=data)
    if resp.status_code == 409:
        # Row exists — do PATCH (update) by filtering on (unit_id, locale)
        patch_url = f"{base_url}?unit_id=eq.{unit_id}&locale=eq.{locale}"
        patch_data = {
            "title": title,
            "description": description,
            "mini_theory_content": mini_theory_content,
        }
        resp = requests.patch(patch_url, headers=headers, json=patch_data)

    return resp.status_code, resp.text


# ── Claude API helper ─────────────────────────────────────────────────────────
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


# ── JSON extraction ───────────────────────────────────────────────────────────
def extract_json(raw: str) -> str:
    """Extract JSON from Claude response, handling markdown code fences."""
    # Try to find JSON in code fence
    match = re.search(r'```(?:json)?\s*([\s\S]*?)```', raw)
    if match:
        return match.group(1).strip()
    # No fence — return as-is (might be raw JSON)
    return raw.strip()


# ── Translation helpers ───────────────────────────────────────────────────────
def translate_title_description(title: str, description: str) -> dict:
    prompt = f"""You are a BJJ instructor translating app content to Spanish for Latin American audiences.
Translate naturally and idiomatically — not word-for-word. Keep BJJ terminology in English
(e.g. guard, sweep, submission, mount, kimura, armbar, triangle).
Keep the tone energetic and coaching-like.

Translate this BJJ app unit title and description to Spanish:
Title: {title}
Description: {description}

Respond with JSON only, no extra text: {{"title": "...", "description": "..."}}"""
    raw = call_claude(prompt)
    return json.loads(extract_json(raw))


def translate_mini_theory(content: dict) -> dict:
    content_json = json.dumps(content, ensure_ascii=False, indent=2)
    prompt = f"""Translate this BJJ app mini-theory content to Spanish. Keep BJJ terms in English (guard, sweep, submission, mount, kimura, armbar, triangle, etc.).
Preserve the JSON structure exactly — only translate text values (title, body, coachLine, buttonLabel).
Do NOT translate keys, boolean values, numbers, or null values.
Return valid JSON only, no extra text or markdown fences.

{content_json}"""
    raw = call_claude(prompt)
    return json.loads(extract_json(raw))


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("Fetching units from Supabase...")
    units = fetch_units()
    total = len(units)
    print(f"Found {total} units.\n")

    success_count = 0
    error_count = 0

    for i, unit in enumerate(units, start=1):
        unit_id = unit["id"]
        title = unit["title"] or ""
        description = unit["description"] or ""
        mini_theory_content = unit.get("mini_theory_content")

        try:
            # Translate title + description
            td = translate_title_description(title, description)
            es_title = td["title"]
            es_description = td["description"]
            time.sleep(0.3)

            # Translate mini_theory_content if present
            es_mini_theory = None
            if mini_theory_content:
                es_mini_theory = translate_mini_theory(mini_theory_content)
                time.sleep(0.3)

            # Upsert into Supabase
            status, resp_text = upsert_translation(
                unit_id=unit_id,
                locale=LOCALE,
                title=es_title,
                description=es_description,
                mini_theory_content=es_mini_theory,
            )

            if status in (200, 201, 204):
                print(f"Translated {i}/{total}: {unit_id} ✓")
                success_count += 1
            else:
                print(f"Translated {i}/{total}: {unit_id} — UPSERT ERROR {status}: {resp_text}")
                error_count += 1

        except Exception as e:
            print(f"Translated {i}/{total}: {unit_id} — ERROR: {e}")
            error_count += 1
            time.sleep(1)  # back off a bit on error

    print(f"\nDone. {success_count} succeeded, {error_count} failed out of {total} units.")


if __name__ == "__main__":
    main()
