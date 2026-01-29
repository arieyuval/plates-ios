-- ============================================
-- COMPLETE FIX: Clean Duplicates + Add onConflict
-- ============================================

-- Step 1: Find and display duplicates
SELECT 
    user_id, 
    exercise_id,
    e.name as exercise_name,
    COUNT(*) as duplicate_count
FROM user_exercises ue
LEFT JOIN exercises e ON e.id = ue.exercise_id
GROUP BY user_id, exercise_id, e.name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 2: Before deleting, let's see what data we have in duplicates
SELECT 
    ue.id,
    ue.user_id,
    ue.exercise_id,
    e.name as exercise_name,
    ue.pinned_note,
    ue.goal_weight,
    ue.goal_reps,
    ue.user_pr_reps
FROM user_exercises ue
LEFT JOIN exercises e ON e.id = ue.exercise_id
WHERE (ue.user_id, ue.exercise_id) IN (
    SELECT user_id, exercise_id
    FROM user_exercises
    GROUP BY user_id, exercise_id
    HAVING COUNT(*) > 1
)
ORDER BY ue.user_id, e.name, ue.id;

-- Step 3: Delete duplicate rows, keeping the one with the most data
WITH ranked_exercises AS (
    SELECT 
        id,
        user_id,
        exercise_id,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, exercise_id 
            ORDER BY 
                -- Prioritize rows that have data (not null)
                CASE WHEN pinned_note IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN goal_weight IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN goal_reps IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN user_pr_reps IS NOT NULL THEN 1 ELSE 0 END DESC,
                -- If all are null, keep the newest (highest id)
                id DESC
        ) as rn
    FROM user_exercises
)
DELETE FROM user_exercises
WHERE id IN (
    SELECT id FROM ranked_exercises WHERE rn > 1
);

-- Step 4: Verify no duplicates remain
SELECT 
    'After cleanup' as status,
    COUNT(*) as duplicate_count
FROM (
    SELECT user_id, exercise_id, COUNT(*) as cnt
    FROM user_exercises
    GROUP BY user_id, exercise_id
    HAVING COUNT(*) > 1
) duplicates;
-- Expected: 0 duplicates

-- Step 5: Ensure unique constraint exists
ALTER TABLE user_exercises
DROP CONSTRAINT IF EXISTS user_exercises_user_id_exercise_id_key;

ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);

-- Step 6: Verify constraint
SELECT 
    conname as constraint_name, 
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'user_exercises'::regclass 
AND contype = 'u';

-- Step 7: Final count
SELECT 
    COUNT(*) as total_user_exercises,
    COUNT(DISTINCT (user_id, exercise_id)) as unique_combinations
FROM user_exercises;
-- These two numbers should be the same!
