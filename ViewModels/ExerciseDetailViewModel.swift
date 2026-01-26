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
    
    // MARK: - Computed Properties
    
    var lastSet: WorkoutSet? {
        WorkoutCalculations.getLastSet(sets: sets)
    }
    
    var personalRecords: [PersonalRecord] {
        WorkoutCalculations.calculatePRs(for: sets)
    }
    
    var currentPR: PersonalRecord? {
        WorkoutCalculations.getPR(for: sets, repTarget: selectedRepTarget)
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
