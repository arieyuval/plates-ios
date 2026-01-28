//
//  WorkoutDataStore.swift
//  Plates
//
//  Created on 1/25/26.
//

import Foundation
import SwiftUI
import Combine

/// Global data store that caches workout data and implements latency reduction strategies:
/// 1. Global context cache - data persists across navigation
/// 2. Bulk fetch - single request for all sets (avoids N+1)
/// 3. Staleness threshold - 30-second TTL
/// 4. Request deduplication - prevents concurrent duplicate fetches
/// 5. Selective refresh - update only what changed
/// 6. Visibility-based refresh - refresh only when needed
@MainActor
class WorkoutDataStore: ObservableObject {
    static let shared = WorkoutDataStore()
    
    // MARK: - Published State
    @Published var exercises: [Exercise] = []
    @Published var setsByExercise: [UUID: [WorkoutSet]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Cache Management
    private var lastFetched: Date?
    private let staleThreshold: TimeInterval = 30 // 30 seconds
    private var fetchInProgress = false
    
    private let supabase = SupabaseManager.shared
    
    // MARK: - Computed Properties
    
    /// Check if cached data is stale
    var isStale: Bool {
        guard let last = lastFetched else { return true }
        return Date().timeIntervalSince(last) > staleThreshold
    }
    
    /// Get all sets flattened
    var allSets: [WorkoutSet] {
        setsByExercise.values.flatMap { $0 }
    }
    
    /// Get exercises dictionary for quick lookup
    var exerciseDict: [UUID: Exercise] {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }
    
    // MARK: - Main Data Fetching
    
    /// Fetch all data with parallel requests and caching
    /// - Parameter force: If true, bypasses cache and staleness check
    func fetchAllData(force: Bool = false) async {
        // Check staleness
        guard force || isStale else {
            print("📦 Using cached data (age: \(Date().timeIntervalSince(lastFetched ?? Date()))s)")
            return
        }
        
        // Prevent duplicate concurrent fetches
        guard !fetchInProgress else {
            print("⏳ Fetch already in progress, skipping")
            return
        }
        
        fetchInProgress = true
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Fetching all workout data...")
            let startTime = Date()
            
            // Parallel fetch: exercises + all sets
            async let exercisesTask = supabase.fetchExercises()
            async let setsTask = supabase.fetchAllSets()
            
            let (fetchedExercises, fetchedSets) = try await (exercisesTask, setsTask)
            
            // Update state
            exercises = fetchedExercises
            
            // Group sets by exercise
            setsByExercise = Dictionary(grouping: fetchedSets) { $0.exerciseId }
                .mapValues { $0.sorted { $0.date > $1.date } }
            
            // Update cache timestamp
            lastFetched = Date()
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Fetched \(exercises.count) exercises and \(fetchedSets.count) sets in \(String(format: "%.2f", duration))s")
            
        } catch {
            errorMessage = "Failed to load workout data: \(error.localizedDescription)"
            print("❌ Error fetching data: \(error)")
        }
        
        isLoading = false
        fetchInProgress = false
    }
    
    // MARK: - Selective Refresh
    
    /// Refresh sets for a specific exercise only
    /// - Parameter exerciseId: The exercise to refresh
    func refreshExerciseSets(_ exerciseId: UUID) async {
        do {
            print("🔄 Refreshing sets for exercise \(exerciseId)...")
            let updatedSets = try await supabase.fetchSets(for: exerciseId)
            setsByExercise[exerciseId] = updatedSets.sorted { $0.date > $1.date }
            print("✅ Refreshed \(updatedSets.count) sets for exercise")
        } catch {
            errorMessage = "Failed to refresh exercise sets: \(error.localizedDescription)"
            print("❌ Error refreshing exercise sets: \(error)")
        }
    }
    
    /// Refresh exercises list only (lightweight)
    func refreshExercises() async {
        do {
            print("🔄 Refreshing exercises list...")
            exercises = try await supabase.fetchExercises()
            print("✅ Refreshed \(exercises.count) exercises")
        } catch {
            errorMessage = "Failed to refresh exercises: \(error.localizedDescription)"
            print("❌ Error refreshing exercises: \(error)")
        }
    }
    
    // MARK: - Data Access Helpers
    
    /// Get sets for a specific exercise
    func getSets(for exerciseId: UUID) -> [WorkoutSet] {
        setsByExercise[exerciseId] ?? []
    }
    
    /// Get last session top set for an exercise
    func getLastSession(for exerciseId: UUID) -> WorkoutSet? {
        let sets = getSets(for: exerciseId)
        return WorkoutCalculations.getLastSessionTopSet(sets: sets)
    }
    
    /// Get last set for an exercise
    func getLastSet(for exerciseId: UUID) -> WorkoutSet? {
        let sets = getSets(for: exerciseId)
        return WorkoutCalculations.getLastSet(sets: sets)
    }
    
    /// Get current PR for an exercise
    func getCurrentPR(for exerciseId: UUID, repTarget: Int) -> PersonalRecord? {
        let sets = getSets(for: exerciseId)
        return WorkoutCalculations.getPR(for: sets, repTarget: repTarget)
    }
    
    /// Get best distance for a cardio exercise
    func getBestDistance(for exerciseId: UUID) -> Double? {
        let sets = getSets(for: exerciseId)
        return sets
            .compactMap { $0.distance }
            .max()
    }
    
    /// Get exercise by ID
    func getExercise(_ exerciseId: UUID) -> Exercise? {
        exercises.first { $0.id == exerciseId }
    }
    
    // MARK: - Data Mutations
    
    /// Log a set and refresh only that exercise's data
    func logSet(
        exerciseId: UUID,
        weight: Double? = nil,
        reps: Int? = nil,
        distance: Double? = nil,
        duration: Int? = nil,
        notes: String? = nil
    ) async throws {
        // Log the set
        try await supabase.logSet(
            exerciseId: exerciseId,
            weight: weight,
            reps: reps,
            distance: distance,
            duration: duration,
            notes: notes
        )
        
        // Selective refresh - only this exercise
        await refreshExerciseSets(exerciseId)
    }
    
    /// Update a set and refresh only that exercise's data
    func updateSet(
        _ setId: UUID,
        exerciseId: UUID,
        weight: Double?,
        reps: Int?,
        distance: Double?,
        duration: Int?,
        notes: String?
    ) async throws {
        try await supabase.updateSet(
            setId,
            weight: weight,
            reps: reps,
            distance: distance,
            duration: duration,
            notes: notes
        )
        
        // Selective refresh
        await refreshExerciseSets(exerciseId)
    }
    
    /// Delete a set and refresh only that exercise's data
    func deleteSet(_ setId: UUID, exerciseId: UUID) async throws {
        try await supabase.deleteSet(setId)
        
        // Selective refresh
        await refreshExerciseSets(exerciseId)
    }
    
    /// Add a new exercise and refresh exercises list
    func addExercise(
        name: String,
        muscleGroup: MuscleGroup,
        exerciseType: ExerciseType,
        defaultPRReps: Int,
        usesBodyWeight: Bool
    ) async throws -> Exercise {
        let exercise = try await supabase.addExercise(
            name: name,
            muscleGroup: muscleGroup,
            exerciseType: exerciseType,
            defaultPRReps: defaultPRReps,
            usesBodyWeight: usesBodyWeight
        )
        
        // Refresh exercises list only
        await refreshExercises()
        
        return exercise
    }
    
    /// Update pinned note for an exercise
    func updatePinnedNote(exerciseId: UUID, note: String?) async throws {
        try await supabase.updatePinnedNote(exerciseId: exerciseId, note: note)
        
        // Update local cache
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].pinnedNote = note
        }
    }
    
    /// Update user's custom PR reps for an exercise
    func updateUserPRReps(exerciseId: UUID, userPRReps: Int?) async throws {
        try await supabase.updateUserPRReps(exerciseId: exerciseId, userPRReps: userPRReps)
        
        // Update local cache
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].userPRReps = userPRReps
        }
    }
    
    // MARK: - Cache Management
    
    /// Force invalidate cache (useful for pull-to-refresh)
    func invalidateCache() {
        lastFetched = nil
    }
    
    /// Check and refresh if stale (for visibility-based refresh)
    func refreshIfStale() async {
        if isStale {
            await fetchAllData(force: false)
        }
    }
}
