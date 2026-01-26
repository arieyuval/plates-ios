//
//  HistoryViewModel.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    private let dataStore = WorkoutDataStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    struct WorkoutDay: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let sets: [WorkoutSet]
    }
    
    // Computed properties that read from global store
    var allSets: [WorkoutSet] {
        dataStore.allSets
    }
    
    var exercises: [UUID: Exercise] {
        dataStore.exerciseDict
    }
    
    var isLoading: Bool {
        dataStore.isLoading
    }
    
    var errorMessage: String? {
        dataStore.errorMessage
    }
    
    var groupedWorkouts: [WorkoutDay] {
        let grouped = Dictionary(grouping: allSets) {
            Calendar.current.startOfDay(for: $0.date)
        }
        
        return grouped.map { date, sets in
            let exercisesWorked = sets.compactMap { set -> (name: String, muscleGroup: MuscleGroup)? in
                guard let exercise = exercises[set.exerciseId] else { return nil }
                return (name: exercise.name, muscleGroup: exercise.muscleGroup)
            }
            
            let label = WorkoutCalculations.determineWorkoutLabel(exercises: exercisesWorked)
            
            return WorkoutDay(date: date, label: label, sets: sets.sorted { $0.date > $1.date })
        }
        .sorted { $0.date > $1.date }
    }
    
    init() {
        // Subscribe to data store changes
        dataStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    func loadData() async {
        await dataStore.fetchAllData(force: false)
    }
    
    func forceRefresh() async {
        await dataStore.fetchAllData(force: true)
    }
    
    func deleteSet(_ setId: UUID) async {
        // Find which exercise this set belongs to
        guard let exerciseId = allSets.first(where: { $0.id == setId })?.exerciseId else {
            return
        }
        
        do {
            try await dataStore.deleteSet(setId, exerciseId: exerciseId)
        } catch {
            print("Failed to delete set: \(error)")
        }
    }
    
    func exerciseName(for exerciseId: UUID) -> String {
        exercises[exerciseId]?.name ?? "Unknown Exercise"
    }
    
    func getExercise(for exerciseId: UUID) -> Exercise? {
        exercises[exerciseId]
    }
    
    func updateSet(_ setId: UUID, weight: Double?, reps: Int?, distance: Double?, duration: Int?, notes: String?) async {
        // Find which exercise this set belongs to
        guard let exerciseId = allSets.first(where: { $0.id == setId })?.exerciseId else {
            return
        }
        
        do {
            try await dataStore.updateSet(
                setId,
                exerciseId: exerciseId,
                weight: weight,
                reps: reps,
                distance: distance,
                duration: duration,
                notes: notes
            )
        } catch {
            print("Failed to update set: \(error)")
        }
    }
}
