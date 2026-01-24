//
//  WorkoutCalculations.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

struct WorkoutCalculations {
    
    // MARK: - Personal Records
    
    static func calculatePRs(for sets: [WorkoutSet]) -> [PersonalRecord] {
        let repTargets = [1, 3, 5, 8, 10]
        var prs: [PersonalRecord] = []
        
        for target in repTargets {
            // Find all sets with at least 'target' reps
            let validSets = sets.filter { ($0.reps ?? 0) >= target }
            
            // Get the one with highest weight
            if let best = validSets.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }),
               let weight = best.weight {
                prs.append(PersonalRecord(reps: target, weight: weight, date: best.date))
            }
        }
        
        return prs
    }
    
    static func getPR(for sets: [WorkoutSet], repTarget: Int) -> PersonalRecord? {
        let validSets = sets.filter { ($0.reps ?? 0) >= repTarget }
        
        guard let best = validSets.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }),
              let weight = best.weight else {
            return nil
        }
        
        return PersonalRecord(reps: repTarget, weight: weight, date: best.date)
    }
    
    // MARK: - Last Session & Last Set
    
    static func getLastSessionTopSet(sets: [WorkoutSet]) -> WorkoutSet? {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        // Get sets before today
        let previousSets = sets.filter { $0.date < startOfToday }
        
        // Group by date
        let grouped = Dictionary(grouping: previousSets) {
            Calendar.current.startOfDay(for: $0.date)
        }
        
        // Get most recent date
        guard let lastSessionDate = grouped.keys.max(),
              let lastSessionSets = grouped[lastSessionDate] else {
            return nil
        }
        
        // Return heaviest set from that session
        return lastSessionSets.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) })
    }
    
    static func getLastSet(sets: [WorkoutSet]) -> WorkoutSet? {
        return sets.max(by: { $0.date < $1.date })
    }
    
    // MARK: - Current Max
    
    static func getCurrentMax(sets: [WorkoutSet], minReps: Int) -> Double? {
        let validSets = sets.filter { ($0.reps ?? 0) >= minReps }
        return validSets.compactMap { $0.weight }.max()
    }
    
    // MARK: - Chart Data
    
    static func prepareChartData(sets: [WorkoutSet], repFilter: Int) -> [(date: Date, weight: Double)] {
        // Filter by rep count
        let filtered = sets.filter { ($0.reps ?? 0) >= repFilter }
        
        // Group by day
        let grouped = Dictionary(grouping: filtered) {
            Calendar.current.startOfDay(for: $0.date)
        }
        
        // Get max weight per day
        let dataPoints = grouped.compactMap { (date, daySets) -> (Date, Double)? in
            guard let maxWeight = daySets.compactMap({ $0.weight }).max() else {
                return nil
            }
            return (date, maxWeight)
        }
        
        // Sort by date (oldest first for chart)
        return dataPoints.sorted { $0.0 < $1.0 }
    }
    
    static func prepareBodyWeightChartData(logs: [BodyWeightLog]) -> [(date: Date, weight: Double)] {
        let dataPoints = logs.map { (Calendar.current.startOfDay(for: $0.date), $0.weight) }
        return dataPoints.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Body Weight Exercise Chart Data (Reps Progression)
    
    /// Prepare chart data for body weight exercises showing max reps per day
    static func prepareBodyWeightExerciseChartData(sets: [WorkoutSet]) -> [(date: Date, reps: Int)] {
        // Group sets by day
        var byDay: [Date: WorkoutSet] = [:]
        
        for set in sets {
            guard let reps = set.reps, reps > 0 else { continue }
            let dayStart = Calendar.current.startOfDay(for: set.date)
            
            if let existing = byDay[dayStart] {
                // Keep the set with more reps
                if reps > (existing.reps ?? 0) {
                    byDay[dayStart] = set
                }
            } else {
                byDay[dayStart] = set
            }
        }
        
        // Sort by date (oldest first for chart)
        return byDay
            .map { (date: $0.key, reps: $0.value.reps ?? 0) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Workout Labels
    
    static func determineWorkoutLabel(exercises: [(name: String, muscleGroup: MuscleGroup)]) -> String {
        let muscleGroups = exercises.map { $0.muscleGroup }
        let uniqueGroups = Set(muscleGroups)
        
        // Push: Chest + (Shoulders or Triceps)
        if uniqueGroups.contains(.chest) && (uniqueGroups.contains(.shoulders) || uniqueGroups.contains(.triceps)) {
            return "Push"
        }
        
        // Pull: Back + Biceps (allow max 1 Shoulder exercise)
        if uniqueGroups.contains(.back) && uniqueGroups.contains(.biceps) {
            let shoulderCount = muscleGroups.filter { $0 == .shoulders }.count
            if shoulderCount <= 1 {
                return "Pull"
            }
        }
        
        // Sharms: Shoulders + Arms
        if uniqueGroups.contains(.shoulders) && uniqueGroups.contains(.arms) {
            return "Sharms"
        }
        
        // Legs: Only leg exercises
        if uniqueGroups.count == 1 && uniqueGroups.contains(.legs) {
            return "Legs"
        }
        
        // Otherwise: "MuscleGroup1 & MuscleGroup2"
        let sortedGroups = Array(uniqueGroups).sorted { $0.rawValue < $1.rawValue }
        if sortedGroups.count == 1 {
            return sortedGroups[0].rawValue
        } else if sortedGroups.count == 2 {
            return "\(sortedGroups[0].rawValue) & \(sortedGroups[1].rawValue)"
        } else {
            return "Mixed"
        }
    }
    
    // MARK: - Body Weight Display
    
    static func formatWeightForDisplay(weight: Double, usesBodyWeight: Bool) -> String {
        if usesBodyWeight {
            if weight == 0 {
                return "BW"
            } else {
                return "BW + \(Int(weight)) lbs"
            }
        } else {
            return "\(Int(weight)) lbs"
        }
    }
}
