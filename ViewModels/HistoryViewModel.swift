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
    @Published var allSets: [WorkoutSet] = []
    @Published var exercises: [UUID: Exercise] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    
    struct WorkoutDay: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let sets: [WorkoutSet]
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
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allSets = try await supabase.fetchAllSets()
            
            // Load exercise details
            let exerciseList = try await supabase.fetchExercises()
            exercises = Dictionary(uniqueKeysWithValues: exerciseList.map { ($0.id, $0) })
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteSet(_ setId: UUID) async {
        do {
            try await supabase.deleteSet(setId)
            await loadData()
        } catch {
            errorMessage = "Failed to delete set: \(error.localizedDescription)"
        }
    }
    
    func exerciseName(for exerciseId: UUID) -> String {
        exercises[exerciseId]?.name ?? "Unknown Exercise"
    }
    
    func getExercise(for exerciseId: UUID) -> Exercise? {
        exercises[exerciseId]
    }
    
    func updateSet(_ setId: UUID, weight: Double?, reps: Int?, distance: Double?, duration: Int?, notes: String?) async {
        do {
            try await supabase.updateSet(setId, weight: weight, reps: reps, distance: distance, duration: duration, notes: notes)
            await loadData()
        } catch {
            errorMessage = "Failed to update set: \(error.localizedDescription)"
        }
    }
}
