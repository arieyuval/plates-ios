# FINAL FIX: Goal Weight Creating Duplicate Rows

## The Problem

Every time you set a goal weight or pinned note, it was creating a **NEW row** instead of updating the existing row in `user_exercises`. This led to:
- ❌ Duplicate rows for the same user/exercise
- ❌ Goal weights not appearing (wrong row being read)
- ❌ The error: "the ID occurs multiple times"

## Root Cause

The `upsert()` method needs to be told which columns define uniqueness. Without the `onConflict` parameter, it just inserts a new row every time.

## The Fix

### Part 1: Update Code (DONE ✅)

**File: `SupabaseManager.swift`**

Changed all upsert calls from:
```swift
.upsert(upsertData)
```

To:
```swift
.upsert(upsertData, onConflict: "user_id,exercise_id")
```

This affects these methods:
- ✅ `updatePinnedNote()`
- ✅ `updateGoalWeight()`
- ✅ `updateGoalReps()`
- ✅ `updateUserPRReps()`

### Part 2: Clean Up Database (DO THIS NOW)

**Run `CLEANUP_DUPLICATES.sql` in Supabase SQL Editor**

This will:
1. Show you the duplicates
2. Delete duplicate rows (keeps the one with the most data)
3. Add the unique constraint
4. Verify everything is clean

### Part 3: Test

After running the SQL:
1. Restart your app
2. Go to an exercise
3. Set a goal weight
4. **Close and reopen the exercise**
5. Goal weight should persist!

## What Changed

### Before (Broken):
```swift
.upsert(upsertData)  // Creates new row every time
```
**Result:** Multiple rows with same user_id + exercise_id

### After (Fixed):
```swift
.upsert(upsertData, onConflict: "user_id,exercise_id")  // Updates existing row
```
**Result:** Single row per user/exercise, properly updated

## Verification

After running CLEANUP_DUPLICATES.sql, you should see:

```
total_user_exercises | unique_combinations
20                   | 20
```

If these match, you're good!

If they don't match, you still have duplicates.

## Why This Happened

1. Initially, upsert was called without `onConflict`
2. Each call created a new row
3. Rows piled up: same user_id + exercise_id, multiple times
4. When fetching, app got confused (which row to use?)
5. SwiftUI complained about duplicate IDs

## Prevention

The unique constraint prevents future duplicates:
```sql
UNIQUE (user_id, exercise_id)
```

Now, even if code breaks, database won't allow duplicates.

## Expected Behavior After Fix

✅ Set goal weight → Updates existing row  
✅ Set pinned note → Updates existing row  
✅ Close and reopen exercise → Data persists  
✅ No duplicate ID errors  
✅ Only one row per user/exercise in database  

## If It Still Doesn't Work

Check in Supabase after setting a goal:

```sql
SELECT 
    COUNT(*) as row_count,
    goal_weight
FROM user_exercises
WHERE user_id = 'YOUR-USER-ID'
AND exercise_id = 'YOUR-EXERCISE-ID'
GROUP BY goal_weight;
```

**If row_count > 1:** Duplicates still exist - run CLEANUP_DUPLICATES.sql again  
**If goal_weight is NULL:** onConflict might not be working - check code  
**If row_count = 0:** Row doesn't exist - check if it's a base exercise  
