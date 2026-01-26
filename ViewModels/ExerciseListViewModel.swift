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
    
    // Computed properties that read from the global store
    var exercises: [Exercise] {
        dataStore.exercises
    }
    
    var isLoading: Bool {
        dataStore.isLoading
    }
    
    var errorMessage: String? {
        dataStore.errorMessage
    }
    
    var filteredExercises: [Exercise] {
        var result = exercises
        
        // Filter by muscle group
        if selectedMuscleGroup != .all {
            if selectedMuscleGroup == .arms {
                // When Arms is selected, include Arms, Biceps, and Triceps
                result = result.filter { 
                    $0.muscleGroup == .arms || 
                    $0.muscleGroup == .biceps || 
                    $0.muscleGroup == .triceps 
                }
            } else {
                result = result.filter { $0.muscleGroup == selectedMuscleGroup }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    init() {
        // Subscribe to data store changes to trigger UI updates
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
    
    func getLastSession(for exerciseId: UUID) -> WorkoutSet? {
        dataStore.getLastSession(for: exerciseId)
    }
    
    func getLastSet(for exerciseId: UUID) -> WorkoutSet? {
        dataStore.getLastSet(for: exerciseId)
    }
    
    func getCurrentPR(for exerciseId: UUID, exercise: Exercise) -> PersonalRecord? {
        dataStore.getCurrentPR(for: exerciseId, repTarget: exercise.defaultPRReps)
    }
    
    func quickLogSet(exerciseId: UUID, weight: Double, reps: Int) async {
        do {
            try await dataStore.logSet(exerciseId: exerciseId, weight: weight, reps: reps)
        } catch {
            // Error is already set in dataStore
            print("Failed to log set: \(error)")
        }
    }
}
