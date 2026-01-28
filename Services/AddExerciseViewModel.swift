//
//  AddExerciseViewModel.swift
//  Plates
//
//  Created on 1/25/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AddExerciseViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var exerciseName: String = ""
    @Published var exerciseType: ExerciseType = .strength
    @Published var muscleGroup: MuscleGroup = .chest
    @Published var defaultPRReps: Int? = 3
    @Published var usesBodyWeight: Bool = false
    
    // Initial PR/Session fields
    @Published var prReps: Int? = nil
    @Published var prWeight: Double? = nil
    @Published var prDistance: Double? = nil
    @Published var prDuration: Int? = nil
    
    // Autocomplete
    @Published var allExercises: [Exercise] = []
    @Published var suggestions: [Exercise] = []
    @Published var showSuggestions: Bool = false
    
    // State
    @Published var isSubmitting: Bool = false
    @Published var error: String? = nil
    
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Set up autocomplete
        $exerciseName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSuggestions()
            }
            .store(in: &cancellables)
        
        // Load all exercises for autocomplete
        Task {
            await fetchAllExercises()
        }
    }
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        // Name is required
        guard !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        // Validate default PR reps if provided
        if let prReps = defaultPRReps, (prReps < 1 || prReps > 50) {
            return false
        }
        
        // Validate initial PR fields (both or neither)
        if exerciseType == .strength {
            let hasReps = prReps != nil && prReps! > 0
            let hasWeight = prWeight != nil && prWeight! >= 0
            
            // If one is filled, both must be filled
            if hasReps != hasWeight {
                return false
            }
        }
        
        // Validate initial session fields (both or neither)
        if exerciseType == .cardio {
            let hasDistance = prDistance != nil && prDistance! > 0
            let hasDuration = prDuration != nil && prDuration! > 0
            
            // If one is filled, both must be filled
            if hasDistance != hasDuration {
                return false
            }
        }
        
        return true
    }
    
    var strengthMuscleGroups: [MuscleGroup] {
        // Don't include .arms - users must choose biceps or triceps
        [.chest, .back, .legs, .shoulders, .biceps, .triceps, .core]
    }
    
    // MARK: - Methods
    
    func fetchAllExercises() async {
        do {
            allExercises = try await supabase.fetchAllExercises()
        } catch {
            print("Failed to fetch exercises: \(error)")
        }
    }
    
    func updateSuggestions() {
        guard exerciseName.count >= 2 else {
            suggestions = []
            showSuggestions = false
            return
        }
        
        let searchTerm = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Filter and sort suggestions
        suggestions = allExercises
            .filter { exercise in
                let nameMatch = exercise.name.lowercased().contains(searchTerm)
                let muscleMatch = exercise.muscleGroup.rawValue.lowercased().contains(searchTerm)
                return nameMatch || muscleMatch
            }
            .sorted { exercise1, exercise2 in
                // Prioritize exact prefix matches
                let name1Lower = exercise1.name.lowercased()
                let name2Lower = exercise2.name.lowercased()
                let starts1 = name1Lower.hasPrefix(searchTerm)
                let starts2 = name2Lower.hasPrefix(searchTerm)
                
                if starts1 && !starts2 { return true }
                if !starts1 && starts2 { return false }
                
                // Then alphabetically
                return name1Lower < name2Lower
            }
            .prefix(8)
            .map { $0 }
        
        showSuggestions = !suggestions.isEmpty
    }
    
    func selectSuggestion(_ exercise: Exercise) {
        exerciseName = exercise.name
        exerciseType = exercise.exerciseType
        
        if exercise.exerciseType == .strength {
            muscleGroup = exercise.muscleGroup
            defaultPRReps = exercise.defaultPRReps
            usesBodyWeight = exercise.usesBodyWeight
        }
        
        showSuggestions = false
    }
    
    func submit() async -> Bool {
        guard isValid else { return false }
        
        isSubmitting = true
        error = nil
        
        do {
            // Step 1: Create/find exercise
            let exercise = try await supabase.addExercise(
                name: exerciseName.trimmingCharacters(in: .whitespaces),
                muscleGroup: exerciseType == .cardio ? .cardio : muscleGroup,
                exerciseType: exerciseType,
                defaultPRReps: exerciseType == .strength ? (defaultPRReps ?? 3) : 1,
                usesBodyWeight: exerciseType == .strength ? usesBodyWeight : false
            )
            
            print("✅ Exercise added/linked successfully: \(exercise.name)")
            
            // Step 2: Create initial set if provided
            if exerciseType == .strength, let weight = prWeight, let reps = prReps, reps > 0 {
                try await supabase.logSet(
                    exerciseId: exercise.id,
                    weight: weight,
                    reps: reps,
                    distance: nil,
                    duration: nil,
                    notes: nil
                )
                print("✅ Initial PR set logged")
            } else if exerciseType == .cardio, let distance = prDistance, let duration = prDuration, distance > 0, duration > 0 {
                try await supabase.logSet(
                    exerciseId: exercise.id,
                    weight: nil,
                    reps: nil,
                    distance: distance,
                    duration: duration,
                    notes: nil
                )
                print("✅ Initial cardio session logged")
            }
            
            isSubmitting = false
            return true
            
        } catch {
            self.error = "Failed to add exercise: \(error.localizedDescription)"
            print("❌ Failed to add exercise: \(error)")
            isSubmitting = false
            return false
        }
    }
}
