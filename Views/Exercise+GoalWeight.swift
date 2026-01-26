//
//  Exercise+GoalWeight.swift
//  Plates
//
//  Code snippets for adding goal weight support
//  Created on 1/26/26.
//
//  ⚠️ THIS IS A REFERENCE FILE - NOT ACTUAL CODE
//  Copy the snippets below into the appropriate files
//

/*
 ============================================
 EXERCISE MODEL UPDATE
 ============================================
 
 Add this property to your Exercise struct:
 
 In Exercise.swift, add to the struct properties:
     let goalWeight: Double?

 In Exercise.swift CodingKeys enum, add:
     case goalWeight = "goal_weight"

 Example complete struct (adjust based on your actual Exercise struct):
 
 struct Exercise: Codable, Identifiable {
     let id: UUID
     let name: String
     let muscleGroup: MuscleGroup
     let exerciseType: ExerciseType
     let isBase: Bool
     let defaultPRReps: Int
     let usesBodyWeight: Bool
     let pinnedNote: String?
     let goalWeight: Double?  // ← ADD THIS
     
     enum CodingKeys: String, CodingKey {
         case id
         case name
         case muscleGroup = "muscle_group"
         case exerciseType = "exercise_type"
         case isBase = "is_base"
         case defaultPRReps = "default_pr_reps"
         case usesBodyWeight = "uses_body_weight"
         case pinnedNote = "pinned_note"
         case goalWeight = "goal_weight"  // ← ADD THIS
     }
 }
 */

/*
 ============================================
 EXERCISE DETAIL VIEW MODEL UPDATE
 ============================================
 
 Add these to your ExerciseDetailViewModel:

 1. Make sure exercise is published (so UI updates when goal changes)
     @Published var exercise: Exercise

 2. Add computed property for current max weight
     var currentMaxWeight: Double? {
         // Get the maximum weight from sets that meet the default PR rep requirement
         let filtered = sets.filter { ($0.reps ?? 0) >= exercise.defaultPRReps }
         return filtered.compactMap { $0.weight }.max()
     }

 3. Add method to update goal weight
     func updateGoalWeight(_ goalWeight: Double?) async {
         do {
             try await SupabaseManager.shared.updateGoalWeight(
                 exerciseId: exercise.id,
                 goalWeight: goalWeight
             )
             
             // Refresh the exercise data by reloading
             await loadSets()
             
         } catch {
             print("Error updating goal weight: \(error.localizedDescription)")
             // TODO: Show error alert to user
         }
     }
 */

/*
 ============================================
 ALTERNATIVE: If exercise is not @Published
 ============================================
 
 If your exercise property is not @Published (e.g., it's passed in init and stored as let),
 you'll need to make it @Published and mutable:
 
 class ExerciseDetailViewModel: ObservableObject {
     @Published var exercise: Exercise
     
     init(exercise: Exercise) {
         self.exercise = exercise
     }
     
     func updateGoalWeight(_ goalWeight: Double?) async {
         do {
             try await SupabaseManager.shared.updateGoalWeight(
                 exerciseId: exercise.id,
                 goalWeight: goalWeight
             )
             
             // Manually update the exercise object
             // Note: You may need to fetch fresh data or reconstruct the Exercise
             // This approach depends on your Exercise struct implementation
             
             // Option A: Reload everything
             await loadSets()
             
             // Option B: Update just the exercise (requires fetching)
             if let updatedExercise = try? await fetchExercise(id: exercise.id) {
                 self.exercise = updatedExercise
             }
             
         } catch {
             print("Error updating goal weight: \(error.localizedDescription)")
         }
     }
 }
 */

/*
 ============================================
 DATABASE MIGRATION
 ============================================
 
 Run this SQL in your Supabase SQL Editor:

-- Add goal_weight column to exercises table
ALTER TABLE exercises 
ADD COLUMN IF NOT EXISTS goal_weight DECIMAL(10, 2) NULL;

-- Optional: Add comment for documentation
COMMENT ON COLUMN exercises.goal_weight IS 'Target weight goal for the exercise in pounds';

-- Optional: Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_exercises_goal_weight 
ON exercises(goal_weight) 
WHERE goal_weight IS NOT NULL;

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'exercises' 
AND column_name = 'goal_weight';
*/

/*
 ============================================
 TESTING
 ============================================
 
 After implementing the above changes, test the following:
 
 1. ✅ Set a goal weight on an exercise
 2. ✅ Verify it saves to the database
 3. ✅ Verify it displays on the exercise card
 4. ✅ Verify the goal line appears on the chart
 5. ✅ Log sets that reach/exceed the goal
 6. ✅ Verify the goal line turns green and solid
 7. ✅ Verify the goal card text turns green
 8. ✅ Edit the goal weight
 9. ✅ Remove the goal weight (set to nil)
 10. ✅ Verify chart extends Y-axis to include goal
 */
