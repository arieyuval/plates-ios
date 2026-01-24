# Changes Summary - January 24, 2026

## Overview
This document summarizes the changes made to implement:
1. Reorganized set history layout (date | notes | set info | arrow)
2. UTC to local timezone conversion (defaulting to PST)
3. Cardio exercise quick log support with distance/time and pace tracking

## ✅ Completed Changes

### 1. SetHistoryView.swift
- **Added Date extension** for UTC to local timezone conversion
- **Reorganized layout** in `CollapsibleDayGroup`:
  - Date on the left (60px width)
  - Notes in the middle (flexible width, shows "—" if empty)
  - Set info on the right (weight × reps or distance • duration)
  - Arrow indicator only if there are additional sets
- **Removed SetRowView** struct (no longer needed)
- **Added cardio support** in top set calculation (now handles both strength and cardio)

### 2. HistoryView.swift
- **Added Date extension** for UTC to local timezone conversion
- **Reorganized layout** in `ExerciseGroupView`:
  - Moved exercise name to separate header row with navigation link
  - Date on left (50px width)
  - Notes in middle (flexible width, shows "—" if empty)
  - Set info on right
  - Arrow indicator only if there are additional sets
- **Added cardio support** in top set calculation

### 3. ExerciseDetailView.swift
- **Added cardio chart support**: Now shows `CardioProgressChartView` for cardio exercises
- Chart displays average pace over time (minutes per mile)

### 4. ExerciseDetailViewModel.swift
- **Added `cardioChartData()` method**:
  - Groups cardio sets by date
  - Calculates average pace (minutes per mile) for each day
  - Returns data sorted by date

### 5. ProgressChartView.swift
- **Added `CardioProgressChartView`**:
  - Displays average pace over time
  - Y-axis is reversed (lower pace is better)
  - Uses green color for cardio data
  - Shows "min/mi" label

## 📋 Additional Changes Needed

### Files to Find and Update:

#### 1. ExerciseCardView (Location Unknown)
This view needs to be updated to support quick logging for both strength and cardio exercises.

**Current signature** (assumption):
```swift
struct ExerciseCardView: View {
    // ...
    let onQuickLog: (Double, Int) -> Void  // Currently only weight, reps
}
```

**Required changes**:
```swift
struct ExerciseCardView: View {
    let exercise: Exercise
    let lastSession: Date?
    let lastSet: WorkoutSet?
    let currentPR: PersonalRecord?
    let onQuickLog: (Double?, Int?, Double?, Int?) -> Void  // weight, reps, distance, duration
    
    // Add state for cardio inputs
    @State private var quickLogDistance = ""
    @State private var quickLogDuration = ""
    
    var body: some View {
        // ... existing code ...
        
        // Quick log button/form
        if exercise.exerciseType == .strength {
            // Existing strength quick log
            // Fields: weight, reps
        } else if exercise.exerciseType == .cardio {
            // NEW: Cardio quick log
            HStack {
                TextField("Distance (mi)", text: $quickLogDistance)
                    .keyboardType(.decimalPad)
                TextField("Duration (min)", text: $quickLogDuration)
                    .keyboardType(.numberPad)
                Button("Log") {
                    if let distance = Double(quickLogDistance),
                       let duration = Int(quickLogDuration) {
                        onQuickLog(nil, nil, distance, duration)
                    }
                }
            }
        }
    }
}
```

#### 2. ExerciseListViewModel
The `quickLogSet` method needs to be updated to accept cardio parameters.

**Current signature** (assumption):
```swift
func quickLogSet(exerciseId: UUID, weight: Double, reps: Int) async
```

**Required changes**:
```swift
func quickLogSet(
    exerciseId: UUID, 
    weight: Double? = nil, 
    reps: Int? = nil,
    distance: Double? = nil,
    duration: Int? = nil
) async {
    do {
        try await supabase.logSet(
            exerciseId: exerciseId,
            weight: weight,
            reps: reps,
            distance: distance,
            duration: duration,
            notes: nil
        )
        await loadData()
    } catch {
        // Handle error
    }
}
```

#### 3. ExerciseListView.swift
Update the closure passed to ExerciseCardView:

**Current**:
```swift
ExerciseCardView(
    exercise: exercise,
    lastSession: viewModel.getLastSession(for: exercise.id),
    lastSet: viewModel.getLastSet(for: exercise.id),
    currentPR: viewModel.getCurrentPR(for: exercise.id, exercise: exercise)
) { weight, reps in
    Task {
        await viewModel.quickLogSet(exerciseId: exercise.id, weight: weight, reps: reps)
    }
}
```

**Required**:
```swift
ExerciseCardView(
    exercise: exercise,
    lastSession: viewModel.getLastSession(for: exercise.id),
    lastSet: viewModel.getLastSet(for: exercise.id),
    currentPR: viewModel.getCurrentPR(for: exercise.id, exercise: exercise)
) { weight, reps, distance, duration in
    Task {
        await viewModel.quickLogSet(
            exerciseId: exercise.id, 
            weight: weight, 
            reps: reps,
            distance: distance,
            duration: duration
        )
    }
}
```

## 🔍 How to Find Missing Files

Since the search limit has been reached, here are suggestions to locate the files:

1. **ExerciseCardView**: Look in the Views folder, possibly:
   - `Views/ExerciseCardView.swift`
   - `Views/Exercise/ExerciseCardView.swift`
   - Inside `ExerciseListView.swift` at the bottom

2. **ExerciseListViewModel**: Look for:
   - `ViewModels/ExerciseListViewModel.swift`
   - `ExerciseListViewModel.swift` in root

## 🧪 Testing Checklist

After making the remaining changes, test:

1. ✅ Set history displays in new format (date | notes | set info | arrow)
2. ✅ Dates convert from UTC to local timezone correctly
3. ✅ Cardio exercises show pace chart instead of weight chart
4. ⚠️ Quick log works for strength exercises (weight + reps)
5. ⚠️ Quick log works for cardio exercises (distance + duration)
6. ✅ Expanded/collapsed state works for sets
7. ✅ Swipe to delete works on all set rows

## 📝 Notes

- The Date extension uses `TimeZone.current` which automatically detects the user's timezone
- Falls back to PST (`America/Los_Angeles`) if needed, though this should rarely happen
- The pace chart uses reversed Y-axis since lower pace is better
- Cardio sets are now properly supported in history views with top set selection based on longest distance

## Example Data Flow

### Strength Exercise Quick Log:
1. User enters: Weight=225, Reps=5
2. ExerciseCardView calls: `onQuickLog(225, 5, nil, nil)`
3. ViewModel calls: `supabase.logSet(exerciseId: id, weight: 225, reps: 5, distance: nil, duration: nil, notes: nil)`

### Cardio Exercise Quick Log:
1. User enters: Distance=3.5, Duration=30
2. ExerciseCardView calls: `onQuickLog(nil, nil, 3.5, 30)`
3. ViewModel calls: `supabase.logSet(exerciseId: id, weight: nil, reps: nil, distance: 3.5, duration: 30, notes: nil)`
4. Chart shows pace: 30min / 3.5mi = 8.57 min/mi
