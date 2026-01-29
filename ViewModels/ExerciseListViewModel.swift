//
//  ExerciseListViewModel.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ExerciseListViewModel: ObservableObject {
    @Published var selectedMuscleGroup: MuscleGroup = .all
    @Published var searchText = ""
    @Published var showingAddExercise = false
    
    private let dataStore = WorkoutDataStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties that mirror the data store
    @Published private(set) var exercises: [Exercise] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    var filteredExercises: [Exercise] {
        var result = exercises
        
        // Filter by muscle group
        if selectedMuscleGroup != .all {
            if selectedMuscleGroup == .arms {
                // When Arms is selected, include exercises that target Arms, Biceps, or Triceps
                result = result.filter { exercise in
                    exercise.muscleGroups.contains(.arms) ||
                    exercise.muscleGroups.contains(.biceps) ||
                    exercise.muscleGroups.contains(.triceps)
                }
            } else {
                // Filter by exercises that include the selected muscle group
                result = result.filter { exercise in
                    exercise.muscleGroups.contains(selectedMuscleGroup)
                }
            }
        }
        
        // Filter by search text (searches both name and muscle groups)
        if !searchText.isEmpty {
            result = result.filter { $0.matches(searchText: searchText) }
        }
        
        // Sort with priority:
        // 1. Name matches (e.g., "Chest Supported Row" when searching "chest")
        // 2. Muscle group matches (e.g., "Bench Press" with chest muscle group)
        // 3. Within each category, sort by usage count (most used first)
        // 4. Then alphabetically as final tiebreaker
        result = result.sorted { exercise1, exercise2 in
            let lowercasedSearch = searchText.lowercased()
            let name1HasMatch = exercise1.name.lowercased().contains(lowercasedSearch)
            let name2HasMatch = exercise2.name.lowercased().contains(lowercasedSearch)
            
            // If one has name match and other doesn't, prioritize name match
            if name1HasMatch != name2HasMatch {
                return name1HasMatch
            }
            
            // Both have same type of match (both name or both muscle group)
            // Sort by usage count
            let count1 = dataStore.getSets(for: exercise1.id).count
            let count2 = dataStore.getSets(for: exercise2.id).count
            
            if count1 != count2 {
                return count1 > count2 // More sets = higher priority
            } else {
                return exercise1.name < exercise2.name // Alphabetical as tiebreaker
            }
        }
        
        return result
    }
    
    init() {
        // Sync initial state
        self.exercises = dataStore.exercises
        self.isLoading = dataStore.isLoading
        self.errorMessage = dataStore.errorMessage
        
        // Subscribe to individual property changes
        dataStore.$exercises
            .assign(to: &$exercises)
        
        dataStore.$isLoading
            .assign(to: &$isLoading)
        
        dataStore.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    func loadData() async {
        await dataStore.fetchAllData(force: false)
    }
    
    func forceRefresh() async {
        await dataStore.fetchAllData(force: true)
    }
    
    func getLastSession(for exerciseId: UUID) -> WorkoutSet? {
        dataStore.getLastSession(for: exerciseId)
    }
    
    func getLastSet(for exerciseId: UUID) -> WorkoutSet? {
        dataStore.getLastSet(for: exerciseId)
    }
    
    func getCurrentPR(for exerciseId: UUID, exercise: Exercise) -> PersonalRecord? {
        dataStore.getCurrentPR(for: exerciseId, repTarget: exercise.defaultPRReps)
    }
    
    func getBestDistance(for exerciseId: UUID) -> Double? {
        dataStore.getBestDistance(for: exerciseId)
    }
    
    func quickLogSet(exerciseId: UUID, weight: Double?, reps: Int?, distance: Double?, duration: Int?) async {
        do {
            if let weight = weight, let reps = reps {
                // Strength exercise
                try await dataStore.logSet(exerciseId: exerciseId, weight: weight, reps: reps)
            } else if let distance = distance, let duration = duration {
                // Cardio exercise
                try await dataStore.logSet(exerciseId: exerciseId, distance: distance, duration: duration)
            }
        } catch {
            // Error is already set in dataStore
            print("Failed to log set: \(error)")
        }
    }
}
