-- BJJ Mind — Adaptive Question Bank Schema Migration
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- This file handles DDL only; data migration is done via migrate_db.py

-- ── 1. ALTER TABLE questions ─────────────────────────────────────────────────

ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS topic TEXT,
    ADD COLUMN IF NOT EXISTS belt_level TEXT DEFAULT 'white';

-- Make unit_id nullable (questions may exist outside a specific unit in the future)
ALTER TABLE questions
    ALTER COLUMN unit_id DROP NOT NULL;

-- ── 2. ALTER TABLE units ─────────────────────────────────────────────────────

ALTER TABLE units
    ADD COLUMN IF NOT EXISTS topic TEXT;

-- ── 3. CREATE TABLE user_question_stats ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_question_stats (
    id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id       UUID        NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    question_id   TEXT        NOT NULL,
    times_seen    INTEGER     DEFAULT 0 NOT NULL,
    times_wrong   INTEGER     DEFAULT 0 NOT NULL,
    last_seen_at  TIMESTAMPTZ,
    UNIQUE (user_id, question_id)
);

-- Enable Row Level Security
ALTER TABLE user_question_stats ENABLE ROW LEVEL SECURITY;

-- RLS policy: users can only read and write their own stats
CREATE POLICY "Users can read own question stats"
    ON user_question_stats
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own question stats"
    ON user_question_stats
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own question stats"
    ON user_question_stats
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own question stats"
    ON user_question_stats
    FOR DELETE
    USING (auth.uid() = user_id);
