# Step-by-Step Debugging Guide: Goal Weight Not Saving

## Current Status
- Pinned notes ARE working ✅
- Goal weights are NOT saving ❌

Since pinned notes work, we know:
- ✅ Database connection works
- ✅ User authentication works
- ✅ The columns exist
- ✅ Basic upsert functionality works

So the issue is likely specific to the goal_weight operation.

## Step 1: Check Xcode Console Logs

After you press "Save" on a goal weight, look in the Xcode console for these log messages:

### Expected Flow:
```
🟦 ExerciseDetailViewModel.updateGoalWeight called
   Goal Weight: 225.0
   Exercise: Bench Press (...)
🔵 updateGoalWeight called
   User ID: ...
   Exercise ID: ...
   Goal Weight: 225.0
✅ Upsert response status: 201 (or 200)
✅ Updated goal weight for exercise ...
✅ Verified: goal_weight in DB = 225.0
🟢 SupabaseManager.updateGoalWeight succeeded
🟢 Local exercise.goalWeight updated to: 225.0
🔄 Forcing data refresh...
🟢 Local exercise updated from dataStore
   Fresh goalWeight from DB: 225.0
```

### What to look for:

**If you see `❌ Error in updateGoalWeight`:**
- Note the exact error message
- This means the database operation failed

**If you see `⚠️ No record found after upsert!`:**
- The upsert succeeded but no row exists
- This means RLS (Row Level Security) is blocking the read

**If you see `⚠️ Could not find exercise in dataStore after refresh`:**
- The save worked but the exercise isn't being fetched
- Check if `fetchExercises()` is filtering it out

**If you see nothing at all:**
- The function might not be getting called
- Check that the button action is wired up correctly

## Step 2: Run Diagnostic Queries

Open `diagnostic_goal_weight.sql` and run queries 1-7 in Supabase SQL Editor.

### Critical Check: Query #2 (Unique Constraint)

Run this:
```sql
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'user_exercises'::regclass 
AND contype = 'u';
```

**If it returns no rows**: The unique constraint is MISSING. This is likely the problem!

**Fix:**
```sql
ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);
```

### Check Query #6 (RLS Status)

```sql
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'user_exercises';
```

**If `rowsecurity` is `true`**: RLS is enabled. Check policies in Query #7.

**Required policies for RLS:**
```sql
-- Check if this exists
SELECT policyname FROM pg_policies WHERE tablename = 'user_exercises';
```

**If no policies or wrong policies**, add:
```sql
-- Drop old policies
DROP POLICY IF EXISTS "Users can manage own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can view own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can insert own exercise links" ON user_exercises;
DROP POLICY IF EXISTS "Users can update own exercise links" ON user_exercises;

-- Add comprehensive policy
CREATE POLICY "Users can manage own exercise links"
ON user_exercises FOR ALL
USING (auth.uid()::uuid = user_id)
WITH CHECK (auth.uid()::uuid = user_id);
```

## Step 3: Manual Test in Supabase

Get your IDs:
```sql
-- Your user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- An exercise ID
SELECT id, name FROM exercises WHERE name = 'Bench Press';
```

Try manual upsert (replace the UUIDs):
```sql
INSERT INTO user_exercises (user_id, exercise_id, goal_weight)
VALUES (
    'YOUR-USER-ID-HERE',
    'YOUR-EXERCISE-ID-HERE',
    225.0
)
ON CONFLICT (user_id, exercise_id) 
DO UPDATE SET goal_weight = 225.0
RETURNING *;
```

### If this fails with "there is no unique or exclusion constraint":
You're missing the unique constraint. Run:
```sql
ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);
```

### If this succeeds:
The database is working. The issue is in the app code or RLS.

## Step 4: Check for Stale Data in App

The issue might be that the app is showing cached data. Try:

1. **Force quit the app** (swipe up from app switcher)
2. **Relaunch the app**
3. Navigate to an exercise
4. Set a goal weight
5. **Close and reopen the exercise detail**
6. Does the goal weight appear now?

If YES → Caching issue
If NO → Database save issue

## Step 5: Verify with Direct Database Query

While the app is running, after you press Save:

```sql
SELECT 
    ue.user_id,
    ue.exercise_id,
    e.name,
    ue.goal_weight
FROM user_exercises ue
JOIN exercises e ON e.id = ue.exercise_id
WHERE e.name = 'Bench Press'  -- or whatever exercise you're testing
ORDER BY ue.user_id;
```

**If `goal_weight` is NULL**: The save didn't work
**If `goal_weight` has a value**: The save worked, but the app isn't fetching it

## Step 6: Check fetchExercises() is Including goal_weight

The issue might be in how we fetch the data. Check this in SupabaseManager.swift around line 260:

```swift
let userExercisesResponse: [UserExerciseWithPreferences] = try await client.from("user_exercises")
    .select("exercise_id, exercises(*), pinned_note, goal_weight, goal_reps, user_pr_reps")
    //                                                  ^^^^^^^^^^^ - Make sure this is here
    .eq("user_id", value: userId.uuidString)
    .execute()
    .value
```

## Step 7: Most Likely Causes (In Order)

### 1. Missing Unique Constraint (90% likely)
**Symptom**: Manual INSERT in SQL also fails with "no unique constraint"
**Fix**: Run the ALTER TABLE ADD CONSTRAINT command from migration

### 2. RLS Blocking (5% likely)
**Symptom**: Manual INSERT works, but SELECT returns nothing when using `auth.uid()`
**Fix**: Add proper RLS policies

### 3. Incorrect upsert syntax (3% likely)  
**Symptom**: Logs show successful save, but data not in DB
**Fix**: Check that struct includes ALL required fields

### 4. Wrong table/column names (1% likely)
**Symptom**: Error like "column does not exist"
**Fix**: Verify column exists with diagnostic query #1

### 5. Caching issue (1% likely)
**Symptom**: Data IS in database but not showing in UI
**Fix**: Force refresh or restart app

## Quick Test Sequence

Run these in order. Stop when one fails:

1. ✅ Run diagnostic query #1 → Columns exist?
2. ✅ Run diagnostic query #2 → Unique constraint exists? **← MOST LIKELY ISSUE**
3. ✅ Run manual INSERT from Step 3 → Works?
4. ✅ Check Xcode console → See error messages?
5. ✅ Query database after app save → Data there?
6. ✅ Force quit and reopen app → Shows up now?

## Expected Solution

Most likely you need to:

```sql
-- Add the unique constraint
ALTER TABLE user_exercises
ADD CONSTRAINT user_exercises_user_id_exercise_id_key 
UNIQUE (user_id, exercise_id);

-- If RLS is enabled, ensure policy exists
CREATE POLICY "Users can manage own exercise links"
ON user_exercises FOR ALL
USING (auth.uid()::uuid = user_id)
WITH CHECK (auth.uid()::uuid = user_id);
```

Then restart your app and try again.

## Report Back

After following these steps, report:
1. What do the Xcode console logs show?
2. Does the manual INSERT in SQL work?
3. Does the unique constraint exist?
4. Is the data in the database after you press Save?
