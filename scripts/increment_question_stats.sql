-- Run this in Supabase SQL Editor
CREATE OR REPLACE FUNCTION increment_question_stats(
    p_user_id uuid,
    p_question_id text,
    p_was_wrong boolean
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO user_question_stats (user_id, question_id, times_seen, times_wrong, last_seen_at)
    VALUES (p_user_id, p_question_id, 1, CASE WHEN p_was_wrong THEN 1 ELSE 0 END, now())
    ON CONFLICT (user_id, question_id) DO UPDATE SET
        times_seen    = user_question_stats.times_seen + 1,
        times_wrong   = user_question_stats.times_wrong + (CASE WHEN p_was_wrong THEN 1 ELSE 0 END),
        last_seen_at  = now();
END;
$$;
