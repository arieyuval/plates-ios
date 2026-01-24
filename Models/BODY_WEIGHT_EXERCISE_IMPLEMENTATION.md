# Body Weight Exercise Support Implementation

## Overview
Implemented comprehensive support for body weight exercises (pull-ups, dips, chin-ups, etc.) throughout the Plates app. Body weight exercises use the `usesBodyWeight: Boolean` field in the Exercise model.

---

## Key Differences from Regular Strength Exercises

### 1. Weight Display Format
- **Regular exercise**: "225 lbs"
- **Body weight exercise**:
  - Weight = 0: "BW" (bodyweight only)
  - Weight > 0: "BW + 25 lbs" (added weight)

### 2. Quick Log Form
- **Regular**: Weight field + Reps field
- **Body weight**: Reps field ONLY (weight field hidden)
- When logging with no weight input, sends weight = 0

### 3. Validation
- **Regular**: Weight > 0 AND Reps > 0
- **Body weight**: Reps > 0 (weight can be 0 or greater)

### 4. Progress Chart
- **Regular**: Weight progression over time with rep filter
- **Body weight**: Reps progression over time (max reps per day)

---

## Files Modified

### 1. Exercise.swift
**Added helper method:**
```swift
func formatWeight(_ weight: Double) -> String {
    if !usesBodyWeight {
        return "\(Int(weight)) lbs"
    }
    return weight > 0 ? "BW + \(Int(weight)) lbs" : "BW"
}
```

**Purpose**: Centralized weight formatting logic for body weight exercises.

---

### 2. WorkoutSet.swift
**Added new method:**
```swift
func displayText(usesBodyWeight: Bool) -> String {
    if isStrength, let weight = weight, let reps = reps {
        if usesBodyWeight {
            let weightStr = weight > 0 ? "BW + \(Int(weight))" : "BW"
            return "\(weightStr) × \(reps)"
        } else {
            return "\(Int(weight)) lbs × \(reps)"
        }
    }
    // ... cardio handling
}
```

**Purpose**: Display sets with proper body weight formatting.

**Examples**:
- Regular: "225 lbs × 5"
- Body weight only: "BW × 12"
- Weighted body weight: "BW + 25 × 8"

---

### 3. ExerciseCardView.swift

**Updated Stats Display:**
- Last Session, Last Set, and PR now use `displayText(usesBodyWeight:)` method
- PR box uses `exercise.formatWeight(currentPR.weight)`

**Updated Quick Log Form:**
- Weight field is HIDDEN for body weight exercises
- Only shows Reps input field
- Validation updated: disabled only if reps empty (for body weight exercises)

**Updated Logging Logic:**
```swift
private func logStrengthSet() {
    if exercise.usesBodyWeight {
        weightValue = weight.isEmpty ? 0 : Double(weight)
        repsValue = Int(reps)
    } else {
        // Regular validation
    }
    // ...
}
```

**UI Example for Pull-ups:**
```
[Pull-ups]
Back

Last Session | Last Set | 8RM PR
BW + 10 × 12 | BW × 15  | BW + 25 lbs

[   Reps   ] [+ Add]  ← Only reps input
```

---

### 4. LogSetFormView.swift

**Updated Weight Field Label:**
- Regular: "Weight (lbs)"
- Body weight: "Added Weight (optional)"

**Updated Placeholder:**
- Regular: "0"
- Body weight: "0 for bodyweight only"

**Auto-fill Behavior:**
- Body weight exercises pre-fill weight field with "0" on appear
- Resets to "0" after logging (instead of empty)

**Updated Validation:**
```swift
private var isValid: Bool {
    if exercise.exerciseType == .strength {
        if exercise.usesBodyWeight {
            return !reps.isEmpty && Int(reps) != nil && Int(reps)! > 0
        }
        return !weight.isEmpty && !reps.isEmpty
    }
    // ...
}
```

---

### 5. PRSelectorView.swift

**Added Exercise Parameter:**
```swift
struct PRSelectorView: View {
    let exercise: Exercise  // ← NEW
    @Binding var selectedRepTarget: Int
    let currentPR: PersonalRecord?
    // ...
}
```

**Updated PR Display:**
```swift
Text(exercise.formatWeight(pr.weight))
```

**Examples:**
- Regular 1RM: "225 lbs"
- Body weight 8RM: "BW" or "BW + 25 lbs"

---

### 6. LastSetInfoView.swift

**Added Exercise Parameter:**
```swift
struct LastSetInfoView: View {
    let set: WorkoutSet
    let exercise: Exercise  // ← NEW
}
```

**Updated Display:**
```swift
Text(set.displayText(usesBodyWeight: exercise.usesBodyWeight))
```

---

### 7. SetHistoryView.swift

**Updated Set Display:**
- Both top set and remaining sets use `displayText(usesBodyWeight: exercise.usesBodyWeight)`
- Properly formats "BW × 12" or "BW + 25 × 8" in history

---

### 8. WorkoutCalculations.swift

**Added New Chart Data Function:**
```swift
static func prepareBodyWeightExerciseChartData(sets: [WorkoutSet]) -> [(date: Date, reps: Int)] {
    var byDay: [Date: WorkoutSet] = [:]
    
    for set in sets {
        guard let reps = set.reps, reps > 0 else { continue }
        let dayStart = Calendar.current.startOfDay(for: set.date)
        
        if let existing = byDay[dayStart] {
            // Keep the set with more reps
            if reps > (existing.reps ?? 0) {
                byDay[dayStart] = set
            }
        } else {
            byDay[dayStart] = set
        }
    }
    
    return byDay
        .map { (date: $0.key, reps: $0.value.reps ?? 0) }
        .sorted { $0.date < $1.date }
}
```

**Purpose**: Calculate max reps per day for body weight exercise charts.

---

### 9. ProgressChartView.swift

**Added New Chart Component:**
```swift
struct BodyWeightExerciseChartView: View {
    let chartData: [(date: Date, reps: Int)]
    
    var body: some View {
        // Shows max reps progression over time
        // Purple line/points
        // Y-axis: Reps (integers)
        // X-axis: Date
    }
}
```

**Features:**
- Purple color scheme (distinct from weight = blue, cardio = green)
- Integer Y-axis for reps
- Caption: "Maximum reps achieved per day"
- No rep filter needed (always shows max reps)

---

### 10. ExerciseDetailViewModel.swift

**Added Method:**
```swift
func bodyWeightChartData() -> [(date: Date, reps: Int)] {
    WorkoutCalculations.prepareBodyWeightExerciseChartData(sets: sets)
}
```

---

### 11. ExerciseDetailView.swift

**Updated Chart Selection Logic:**
```swift
if viewModel.exercise.exerciseType == .strength {
    if viewModel.exercise.usesBodyWeight {
        // Body weight: Show reps progression
        BodyWeightExerciseChartView(
            chartData: viewModel.bodyWeightChartData()
        )
    } else {
        // Regular: Show weight progression
        ProgressChartView(
            chartData: viewModel.chartData(repFilter: viewModel.selectedRepTarget),
            repFilter: viewModel.selectedRepTarget
        )
    }
}
```

**Updated Component Calls:**
- `LastSetInfoView` now receives `exercise` parameter
- `PRSelectorView` now receives `exercise` parameter

---

## User Experience

### Regular Strength Exercise (Bench Press):
```
Last Set: 225 lbs × 5
PR: 250 lbs

[Weight] × [Reps] [+ Add]

Chart: Weight progression (filtered by reps)
```

### Body Weight Exercise (Pull-ups):
```
Last Set: BW × 12
PR: BW + 25 lbs

[Reps] [+ Add]  ← No weight field

Chart: Max reps progression
```

### Weighted Body Weight Exercise (Dips):
```
Log Set Form:
Added Weight (optional)
[25] ← Pre-filled with 0, can be changed

Reps
[8]

Result: "BW + 25 × 8"
```

---

## Validation Logic

### Quick Log (Card):
```swift
// Body weight: Only reps required
disabled: reps.isEmpty

// Regular: Both required
disabled: weight.isEmpty || reps.isEmpty
```

### Detail Log Form:
```swift
// Body weight: Only reps validation
isValid: !reps.isEmpty && Int(reps) > 0

// Regular: Both required
isValid: !weight.isEmpty && !reps.isEmpty
```

---

## Chart Behavior Summary

| Exercise Type | Chart Shows | Y-Axis | Filter | Color |
|--------------|-------------|--------|--------|-------|
| Regular Strength | Weight progression | Weight (lbs) | Rep count | Blue |
| Body Weight | Reps progression | Reps (count) | None | Purple |
| Cardio | Pace progression | Pace (min/mi) | None | Green |

---

## PR Calculation

PRs are calculated the same way for all exercises:
- Find sets with ≥ target reps
- Take maximum weight for that rep count

**Display differs:**
- Regular: "225 lbs"
- Body weight: "BW" or "BW + 25 lbs"

---

## Database Compatibility

All changes are backward compatible:
- Existing exercises without `usesBodyWeight` field default to `false`
- Weight = 0 is now valid for body weight exercises
- All existing sets display correctly with new formatting

---

## Testing Checklist

✅ Body weight exercise card hides weight field  
✅ Quick log sends weight = 0 for body weight exercises  
✅ Stats display "BW" format correctly  
✅ PR displays "BW" or "BW + X lbs" correctly  
✅ Set history shows correct format  
✅ Detail form shows "Added Weight (optional)" label  
✅ Detail form pre-fills with 0  
✅ Chart shows reps progression (not weight)  
✅ Chart is purple (distinct color)  
✅ Regular exercises still work normally  
✅ Cardio exercises unaffected  

---

## Examples of Body Weight Exercises

Common exercises that should have `usesBodyWeight = true`:
- Pull-ups
- Chin-ups  
- Dips
- Push-ups
- Muscle-ups
- Handstand push-ups

These exercises:
- Can be done with just body weight (weight = 0)
- Can have added weight (weight belt, weighted vest)
- Progress is measured primarily by reps
- PRs are still tracked by maximum weight for X reps
