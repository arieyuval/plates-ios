# Personal Records UI Update

## Summary
Replaced the segmented picker for PR selection with a free-form text input field, and removed the "All Personal Records" table to show only the user's selected PR.

## Changes Made

### 1. PRSelectorView.swift - Text Input Instead of Segmented Picker

**Before:**
- Segmented picker with fixed options: 1RM, 3RM, 5RM, 8RM, 10RM
- Users could only select from these predefined rep targets

**After:**
- Free-form text field where users can enter any rep count
- Updates the selected PR as the user types
- Shows "RM" label next to the input field
- Maintains the same PR display card below

**New Features:**
- `TextField` with number pad keyboard for rep input
- `@FocusState` to manage keyboard focus
- Automatic updating of `selectedRepTarget` when user types
- Input validation (only positive integers)
- Keyboard dismissal when tapping outside the field
- Text field initialized with current selection on appear

**UI Layout:**
```
Personal Record
┌────────┐
│   5    │ RM
└────────┘

┌─────────────────────────────┐
│ 225 lbs                     │
│ Achieved Jan 20, 2026       │
└─────────────────────────────┘
```

### 2. ExerciseDetailView.swift - Removed Personal Records Table

**Removed:**
```swift
PersonalRecordsTableView(prs: viewModel.personalRecords)
```

**Reason:**
- Users now focus on one specific PR at a time
- Reduces clutter on the exercise detail page
- Aligns with the new text input approach where users pick what they want to see

**Updated Layout Order:**
1. Muscle group badge
2. Pinned note
3. Last set info
4. **PR Selector** (with text input)
5. Log set form
6. Progress chart (filtered by selected rep target)
7. Set history

### 3. PersonalRecordsTableView.swift - No Longer Used

This file is no longer displayed in the UI but remains in the codebase in case it's needed in the future.

## User Experience Improvements

### Before:
- ❌ Limited to 5 preset rep targets (1, 3, 5, 8, 10)
- ❌ Had to view all PRs in a separate table
- ❌ Couldn't check PRs for custom rep ranges (e.g., 6RM, 12RM)

### After:
- ✅ Can enter **any** rep count they want
- ✅ Immediately see just that specific PR
- ✅ Cleaner UI with less scrolling
- ✅ More flexible for different training styles
- ✅ Chart below updates to show progress for that exact rep range

## Technical Details

### Text Input Validation
```swift
.onChange(of: repInput) { oldValue, newValue in
    if let value = Int(newValue), value > 0 {
        selectedRepTarget = value
    }
}
```
- Only accepts valid positive integers
- Updates `selectedRepTarget` binding in real-time
- Invalid input won't update the selection

### Keyboard Management
- `.keyboardType(.numberPad)` - Only numbers shown
- `@FocusState` tracks when field is active
- Tap outside to dismiss keyboard

### PR Calculation
The PR calculation logic remains unchanged:
- `WorkoutCalculations.getPR(for: sets, repTarget: selectedRepTarget)`
- Finds the heaviest weight achieved for the specified rep count
- Returns `nil` if no sets match that rep count

## Example Use Cases

**Powerlifter:**
- Enter "1" to see their 1RM
- Track max single-rep strength

**Bodybuilder:**
- Enter "12" to see their 12RM
- Focus on hypertrophy rep ranges

**General Fitness:**
- Enter "5" for a balanced strength PR
- Or any custom rep count for their program

## Backward Compatibility

- The default rep target is still set from `exercise.defaultPRReps`
- Progress chart still filters by selected rep target
- All existing PR calculation logic unchanged
- Only the UI for selection and display has changed
