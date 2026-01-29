-- ============================================
-- QUICK FIX: Run this entire script
-- ============================================
-- This script will fix the most common issues with goal_weight not saving

-- Step 1: Ensure columns exist
ALTER TABLE user_exercises 
ADD COLUMN IF NOT EXISTS pinned_note TEXT NULL,
ADD COLUMN IF NOT EXISTS goal_weight DECIMAL(10, 2) NULL,
ADD COLUMN IF NOT EXISTS goal_reps INTEGER NULL,
ADD COLUMN IF NOT EXISTS user_pr_reps INTEGER NULL;

-- Step 2: Add unique constraint (CRITICAL for upsert to work!)
ALTER TABLE user_exercises
DROP CONSTRAINT IF EXISTS user_exercises_user_id_exercise_id_key;

ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);

-- Step 3: Fix RLS policies if enabled
-- First, drop any conflicting policies
DROP POLICY IF EXISTS "Users can view own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can insert own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can update own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can delete own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can manage own exercise links" ON user_exercises;

-- Create a single comprehensive policy for all operations
CREATE POLICY "Users can manage own exercise links"
ON user_exercises FOR ALL
USING (auth.uid()::uuid = user_id)
WITH CHECK (auth.uid()::uuid = user_id);

-- Step 4: Verify the setup
SELECT 
    '✅ Columns exist' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'user_exercises' 
AND column_name IN ('pinned_note', 'goal_weight', 'goal_reps', 'user_pr_reps')
HAVING COUNT(*) = 4

UNION ALL

SELECT 
    '✅ Unique constraint exists' as status,
    COUNT(*) as count
FROM pg_constraint 
WHERE conrelid = 'user_exercises'::regclass 
AND contype = 'u'
AND conname = 'user_exercises_user_id_exercise_id_key'
HAVING COUNT(*) = 1

UNION ALL

SELECT 
    '✅ RLS policy exists' as status,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'user_exercises'
AND policyname = 'Users can manage own exercise links'
HAVING COUNT(*) = 1;

-- If all three checks show up, you're good to go!
-- Expected output:
-- ✅ Columns exist | 4
-- ✅ Unique constraint exists | 1
-- ✅ RLS policy exists | 1
