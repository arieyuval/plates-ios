//
//  ExerciseDetailViewModel.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI

@MainActor
class ExerciseDetailViewModel: ObservableObject {
    @Published var exercise: Exercise
    @Published var sets: [WorkoutSet] = []
    @Published var selectedRepTarget = 1
    @Published var pinnedNote = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    
    init(exercise: Exercise) {
        self.exercise = exercise
        self.selectedRepTarget = exercise.defaultPRReps
        self.pinnedNote = exercise.pinnedNote ?? ""
    }
    
    func loadSets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            sets = try await supabase.fetchSets(for: exercise.id)
        } catch {
            errorMessage = "Failed to load sets: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func logSet(weight: Double?, reps: Int?, distance: Double?, duration: Int?, notes: String?) async {
        do {
            try await supabase.logSet(
                exerciseId: exercise.id,
                weight: weight,
                reps: reps,
                distance: distance,
                duration: duration,
                notes: notes
            )
            
            await loadSets()
        } catch {
            errorMessage = "Failed to log set: \(error.localizedDescription)"
        }
    }
    
    func deleteSet(_ setId: UUID) async {
        do {
            try await supabase.deleteSet(setId)
            await loadSets()
        } catch {
            errorMessage = "Failed to delete set: \(error.localizedDescription)"
        }
    }
    
    func savePinnedNote() async {
        do {
            let noteToSave = pinnedNote.isEmpty ? nil : pinnedNote
            try await supabase.updatePinnedNote(exerciseId: exercise.id, note: noteToSave)
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
    
    var groupedSetsByDate: [(date: Date, sets: [WorkoutSet])] {
        let grouped = Dictionary(grouping: sets) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped.map { (date: $0.key, sets: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
