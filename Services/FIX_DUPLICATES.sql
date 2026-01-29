-- ============================================
-- Fix Duplicate user_exercises Rows
-- ============================================

-- Step 1: Find duplicates
SELECT 
    user_id, 
    exercise_id, 
    COUNT(*) as duplicate_count
FROM user_exercises
GROUP BY user_id, exercise_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 2: Keep only the newest row for each user/exercise pair
-- This will delete older duplicate rows
WITH ranked_exercises AS (
    SELECT 
        id,
        user_id,
        exercise_id,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, exercise_id 
            ORDER BY 
                CASE WHEN pinned_note IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN goal_weight IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN goal_reps IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN user_pr_reps IS NOT NULL THEN 1 ELSE 0 END DESC
        ) as rn
    FROM user_exercises
)
DELETE FROM user_exercises
WHERE id IN (
    SELECT id FROM ranked_exercises WHERE rn > 1
);

-- Step 3: Verify no duplicates remain
SELECT 
    user_id, 
    exercise_id, 
    COUNT(*) as count
FROM user_exercises
GROUP BY user_id, exercise_id
HAVING COUNT(*) > 1;
-- Expected: No rows (all duplicates removed)

-- Step 4: Ensure unique constraint exists
ALTER TABLE user_exercises
DROP CONSTRAINT IF EXISTS user_exercises_user_id_exercise_id_key;

ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);

-- Step 5: Verify
SELECT 
    conname, 
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'user_exercises'::regclass 
AND contype = 'u';

-- Expected: user_exercises_user_id_exercise_id_key | UNIQUE (user_id, exercise_id)
