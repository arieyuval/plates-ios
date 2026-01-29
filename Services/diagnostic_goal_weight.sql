-- ============================================
-- Diagnostic Queries for Goal Weight Issue
-- ============================================
-- Run these queries in Supabase SQL Editor to diagnose the problem

-- 1. Check if the columns exist in user_exercises
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_exercises' 
AND column_name IN ('pinned_note', 'goal_weight', 'goal_reps', 'user_pr_reps');
-- Expected: 4 rows showing these columns exist

-- 2. Check for unique constraint (CRITICAL for upsert!)
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'user_exercises'::regclass 
AND contype = 'u';
-- Expected: Should show user_exercises_user_id_exercise_id_key UNIQUE (user_id, exercise_id)

-- 3. Check if primary key exists
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'user_exercises'::regclass 
AND contype = 'p';
-- Expected: Primary key on id column

-- 4. View current user_exercises structure
SELECT 
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    (SELECT COUNT(*) FROM user_exercises) as total_rows
FROM information_schema.columns c
WHERE c.table_name = 'user_exercises'
ORDER BY c.ordinal_position;

-- 5. Check existing user_exercises data
SELECT 
    ue.user_id,
    ue.exercise_id,
    e.name as exercise_name,
    ue.pinned_note,
    ue.goal_weight,
    ue.goal_reps,
    ue.user_pr_reps
FROM user_exercises ue
LEFT JOIN exercises e ON e.id = ue.exercise_id
ORDER BY ue.user_id, e.name
LIMIT 20;

-- 6. Check Row Level Security status
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'user_exercises';

-- 7. Check RLS policies if enabled
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'user_exercises';

-- 8. Try a manual upsert (replace with your actual IDs)
-- First, get your user_id:
SELECT id as user_id, email FROM auth.users LIMIT 1;

-- Then get an exercise_id (e.g., Bench Press):
SELECT id as exercise_id, name FROM exercises WHERE name LIKE '%Bench%' LIMIT 1;

-- Now try to upsert with your actual values:
-- REPLACE 'your-user-id' and 'your-exercise-id' with values from above
/*
INSERT INTO user_exercises (user_id, exercise_id, goal_weight)
VALUES ('your-user-id', 'your-exercise-id', 225.0)
ON CONFLICT (user_id, exercise_id) 
DO UPDATE SET goal_weight = 225.0
RETURNING *;
*/

-- 9. If the above INSERT fails, it means the unique constraint is missing. Add it:
/*
ALTER TABLE user_exercises
DROP CONSTRAINT IF EXISTS user_exercises_user_id_exercise_id_key;

ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);
*/

-- 10. Check if there are any triggers on user_exercises that might interfere
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'user_exercises';

-- ============================================
-- Common Issues and Solutions
-- ============================================

-- ISSUE 1: No unique constraint
-- SOLUTION: Run query #9 above to add the constraint

-- ISSUE 2: RLS blocking the insert/update
-- SOLUTION: Check query #7 for policies. You need policies like:
/*
CREATE POLICY "Users can manage own exercise links"
ON user_exercises FOR ALL
USING (auth.uid()::uuid = user_id)
WITH CHECK (auth.uid()::uuid = user_id);
*/

-- ISSUE 3: Columns don't exist
-- SOLUTION: Run the migration again:
/*
ALTER TABLE user_exercises 
ADD COLUMN IF NOT EXISTS goal_weight DECIMAL(10, 2) NULL;
*/

-- ISSUE 4: Wrong data types
-- SOLUTION: Check query #4 for column types. goal_weight should be numeric/decimal
