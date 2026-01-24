//
//  ExerciseListViewModel.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI

@MainActor
class ExerciseListViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var allSets: [UUID: [WorkoutSet]] = [:]
    @Published var selectedMuscleGroup: MuscleGroup = .all
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddExercise = false
    
    private let supabase = SupabaseManager.shared
    
    var filteredExercises: [Exercise] {
        var result = exercises
        
        // Filter by muscle group
        if selectedMuscleGroup != .all {
            result = result.filter { $0.muscleGroup == selectedMuscleGroup }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load exercises
            exercises = try await supabase.fetchExercises()
            
            // Load sets for each exercise
            for exercise in exercises {
                let sets = try await supabase.fetchSets(for: exercise.id)
                allSets[exercise.id] = sets
            }
        } catch {
            errorMessage = "Failed to load exercises: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func getSets(for exerciseId: UUID) -> [WorkoutSet] {
        allSets[exerciseId] ?? []
    }
    
    func getLastSession(for exerciseId: UUID) -> WorkoutSet? {
        let sets = getSets(for: exerciseId)
        return WorkoutCalculations.getLastSessionTopSet(sets: sets)
    }
    
    func getLastSet(for exerciseId: UUID) -> WorkoutSet? {
        let sets = getSets(for: exerciseId)
        return WorkoutCalculations.getLastSet(sets: sets)
    }
    
    func getCurrentPR(for exerciseId: UUID, exercise: Exercise) -> PersonalRecord? {
        let sets = getSets(for: exerciseId)
        return WorkoutCalculations.getPR(for: sets, repTarget: exercise.defaultPRReps)
    }
    
    func quickLogSet(exerciseId: UUID, weight: Double, reps: Int) async {
        do {
            try await supabase.logSet(exerciseId: exerciseId, weight: weight, reps: reps)
            
            // Refresh sets for this exercise
            let updatedSets = try await supabase.fetchSets(for: exerciseId)
            allSets[exerciseId] = updatedSets
        } catch {
            errorMessage = "Failed to log set: \(error.localizedDescription)"
        }
    }
}
