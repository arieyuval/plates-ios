# Cardio Quick Log & Body Weight Updates

## Summary
This document outlines the updates made to support cardio quick logging and body weight page improvements.

## Changes Made

### 1. Body Weight Page - Removed "Total Change" Stat
**File:** `BodyWeightView.swift`

- Removed the "Total Change" card from the stats carousel in `StatsCardsView`
- Stats now show: Starting → Current → Goal (in that order)
- This simplifies the UI and focuses on the most important metrics

### 2. Body Weight Chart - Goal Achievement Indicator
**File:** `BodyWeightView.swift`

The chart already had logic implemented to:
- Turn both lines **green** when the user reaches their goal weight
- Change the goal line from **dotted** to **solid** when goal is achieved
- Uses a tolerance of 0.1 lbs to determine if goal is reached

**Implementation details:**
```swift
private var isAtGoal: Bool {
    guard let goal = goalWeight,
          let currentWeight = chartData.first?.weight else {
        return false
    }
    return abs(currentWeight - goal) < 0.1
}
```

### 3. Cardio Quick Log on Exercise Cards
**File:** `ExerciseCardView.swift`

Added the ability to log cardio sets directly from exercise cards, similar to strength exercises.

#### Changes:
- Added state variables for cardio: `@State private var distance = ""` and `@State private var duration = ""`
- Updated initializer to support both strength and cardio exercises
- Changed `onQuickLog` to two separate closures:
  - `onQuickLogStrength: ((Double, Int) -> Void)?` - for weight × reps
  - `onQuickLogCardio: ((Double, Int) -> Void)?` - for distance × time
  
#### New Quick Log UI for Cardio:
- **Distance field** with "Mi" (miles) placeholder
- **Duration field** with "Min" (minutes) placeholder  
- Uses same styling as strength exercises (70pt width, dark background)
- Same success animation (green checkmark) after logging
- Same haptic feedback on successful log

#### Usage:
```swift
ExerciseCardView(
    exercise: cardioExercise,
    lastSession: lastSession,
    lastSet: lastSet,
    currentPR: nil,
    onQuickLog: { distance, duration in
        // distance is Double (miles)
        // duration is Int (minutes)
    }
)
```

The initializer automatically determines if it's a cardio or strength exercise based on `exercise.exerciseType` and assigns the closure to the appropriate handler.

## User Experience Improvements

1. **Body Weight Tracking:**
   - Cleaner stats display without redundant "Total Change" metric
   - Visual feedback when goal is reached (green solid lines)
   
2. **Cardio Logging:**
   - Faster cardio logging without navigating to detail view
   - Consistent UI pattern with strength exercises
   - Intuitive "distance × time" format matching the data display

## Technical Notes

- Cardio quick log uses `Double` for distance (miles with decimals supported)
- Duration uses `Int` for whole minutes
- The exercise card automatically shows the correct quick log form based on `exercise.exerciseType`
- All validation and success animations work the same for both cardio and strength
