//
//  ExerciseDetailViewModel.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ExerciseDetailViewModel: ObservableObject {
    @Published var exercise: Exercise
    @Published var selectedRepTarget = 1
    @Published var pinnedNote = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataStore = WorkoutDataStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property that reads from global store
    var sets: [WorkoutSet] {
        dataStore.getSets(for: exercise.id)
    }
    
    init(exercise: Exercise) {
        self.exercise = exercise
        self.selectedRepTarget = exercise.defaultPRReps
        self.pinnedNote = exercise.pinnedNote ?? ""
        
        // Subscribe to data store changes
        dataStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    func loadSets() async {
        // Use cached data if available and fresh, otherwise fetch
        if dataStore.exercises.isEmpty || dataStore.isStale {
            await dataStore.fetchAllData(force: false)
        } else {
            // Data is already cached and fresh
            print("📦 Using cached data for exercise detail")
        }
    }
    
    func forceRefresh() async {
        await dataStore.refreshExerciseSets(exercise.id)
    }
    
    func logSet(weight: Double?, reps: Int?, distance: Double?, duration: Int?, notes: String?) async {
        do {
            try await dataStore.logSet(
                exerciseId: exercise.id,
                weight: weight,
                reps: reps,
                distance: distance,
                duration: duration,
                notes: notes
            )
        } catch {
            errorMessage = "Failed to log set: \(error.localizedDescription)"
        }
    }
    
    func deleteSet(_ setId: UUID) async {
        do {
            try await dataStore.deleteSet(setId, exerciseId: exercise.id)
        } catch {
            errorMessage = "Failed to delete set: \(error.localizedDescription)"
        }
    }
    
    func updateSet(_ setId: UUID, weight: Double?, reps: Int?, distance: Double?, duration: Int?, notes: String?) async {
        do {
            try await dataStore.updateSet(
                setId,
                exerciseId: exercise.id,
                weight: weight,
                reps: reps,
                distance: distance,
                duration: duration,
                notes: notes
            )
        } catch {
            errorMessage = "Failed to update set: \(error.localizedDescription)"
        }
    }
    
    func savePinnedNote() async {
        do {
            let noteToSave = pinnedNote.isEmpty ? nil : pinnedNote
            try await dataStore.updatePinnedNote(exerciseId: exercise.id, note: noteToSave)
            exercise.pinnedNote = noteToSave
        } catch {
            errorMessage = "Failed to save note: \(error.localizedDescription)"
        }
    }
    
    func updateGoalWeight(_ goalWeight: Double?) async {
        print("🟦 ExerciseDetailViewModel.updateGoalWeight called")
        print("   Goal Weight: \(goalWeight?.description ?? "nil")")
        print("   Exercise: \(exercise.name) (\(exercise.id))")
        
        do {
            try await SupabaseManager.shared.updateGoalWeight(
                exerciseId: exercise.id,
                goalWeight: goalWeight
            )
            
            print("🟢 SupabaseManager.updateGoalWeight succeeded")
            
            // Update local exercise object immediately
            exercise.goalWeight = goalWeight
            print("🟢 Local exercise.goalWeight updated to: \(goalWeight?.description ?? "nil")")
            
            // Force refresh exercises to get updated data from database
            print("🔄 Forcing data refresh...")
            await dataStore.fetchAllData(force: true)
            
            // Update our local exercise reference with the fresh data
            if let updatedExercise = dataStore.getExercise(exercise.id) {
                exercise = updatedExercise
                print("🟢 Local exercise updated from dataStore")
                print("   Fresh goalWeight from DB: \(updatedExercise.goalWeight?.description ?? "nil")")
            } else {
                print("⚠️ Could not find exercise in dataStore after refresh")
            }
            
        } catch {
            print("🔴 Error in updateGoalWeight: \(error)")
            print("🔴 Error type: \(type(of: error))")
            print("🔴 Error localized: \(error.localizedDescription)")
            errorMessage = "Failed to update goal weight: \(error.localizedDescription)"
        }
    }
    
    func updateGoalReps(_ goalReps: Int?) async {
        do {
            try await SupabaseManager.shared.updateGoalReps(
                exerciseId: exercise.id,
                goalReps: goalReps
            )
            
            // Update local exercise object immediately
            exercise.goalReps = goalReps
            
            // Force refresh exercises to get updated data from database
            await dataStore.fetchAllData(force: true)
            
            // Update our local exercise reference with the fresh data
            if let updatedExercise = dataStore.getExercise(exercise.id) {
                exercise = updatedExercise
            }
            
        } catch {
            errorMessage = "Failed to update goal reps: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var currentMaxWeight: Double? {
        // Get the maximum weight from sets that meet or exceed the default PR reps
        let filtered = sets.filter { ($0.reps ?? 0) >= exercise.defaultPRReps }
        return filtered.compactMap { $0.weight }.max()
    }
    
    var currentMaxReps: Int? {
        // Get the maximum reps from all sets (for body weight exercises)
        return sets.compactMap { $0.reps }.max()
    }
    
    var lastSet: WorkoutSet? {
        WorkoutCalculations.getLastSet(sets: sets)
    }
    
    var personalRecords: [PersonalRecord] {
        WorkoutCalculations.calculatePRs(for: sets)
    }
    
    var currentPR: PersonalRecord? {
        WorkoutCalculations.getPR(for: sets, repTarget: selectedRepTarget)
    }
    
    var bestPace: CardioBestPace? {
        // Find the best pace (lowest minutes per mile) from all cardio sets
        let cardioSets = sets.filter { $0.isCardio }
        
        guard let bestSet = cardioSets.min(by: { set1, set2 in
            guard let distance1 = set1.distance, let duration1 = set1.duration,
                  let distance2 = set2.distance, let duration2 = set2.duration,
                  distance1 > 0, distance2 > 0 else {
                return false
            }
            let pace1 = Double(duration1) / distance1
            let pace2 = Double(duration2) / distance2
            return pace1 < pace2
        }),
        let distance = bestSet.distance,
        let duration = bestSet.duration,
        distance > 0 else {
            return nil
        }
        
        let pace = Double(duration) / distance
        return CardioBestPace(pace: pace, distance: distance, duration: duration, date: bestSet.date)
    }
    
    func chartData(repFilter: Int) -> [(date: Date, weight: Double)] {
        WorkoutCalculations.prepareChartData(sets: sets, repFilter: repFilter)
    }
    
    func bodyWeightChartData() -> [(date: Date, reps: Int)] {
        WorkoutCalculations.prepareBodyWeightExerciseChartData(sets: sets)
    }
    
    func cardioChartData() -> [(date: Date, pace: Double)] {
        // Calculate average pace (minutes per mile) for cardio exercises
        let grouped = Dictionary(grouping: sets.filter { $0.isCardio }) {
            Calendar.current.startOfDay(for: $0.date)
        }
        
        return grouped.compactMap { date, daySets in
            // Calculate average pace for the day
            let totalDistance = daySets.compactMap { $0.distance }.reduce(0, +)
            let totalDuration = daySets.compactMap { $0.duration }.reduce(0, +)
            
            guard totalDistance > 0 else { return nil }
            let averagePace = Double(totalDuration) / totalDistance // minutes per mile
            
            return (date: date, pace: averagePace)
        }
        .sorted { $0.date < $1.date }
    }
    
    var groupedSetsByDate: [(date: Date, sets: [WorkoutSet])] {
        let grouped = Dictionary(grouping: sets) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped.map { (date: $0.key, sets: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
