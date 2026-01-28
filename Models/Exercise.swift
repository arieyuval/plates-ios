//
//  Exercise.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var exerciseType: ExerciseType
    var defaultPRReps: Int
    var isBase: Bool
    var usesBodyWeight: Bool
    var pinnedNote: String?
    var goalWeight: Double?
    var goalReps: Int?
    var createdAt: Date?
    var userPRReps: Int? // User's custom PR reps override

    enum CodingKeys: String, CodingKey {
        case id, name
        case muscleGroup = "muscle_group"
        case exerciseType = "exercise_type"
        case defaultPRReps = "default_pr_reps"
        case isBase = "is_base"
        case usesBodyWeight = "uses_body_weight"
        case pinnedNote = "pinned_note"
        case goalWeight = "goal_weight"
        case goalReps = "goal_reps"
        case createdAt = "created_at"
        case userPRReps = "user_pr_reps"
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        exerciseType: ExerciseType = .strength,
        defaultPRReps: Int = 1,
        isBase: Bool = false,
        usesBodyWeight: Bool = false,
        pinnedNote: String? = nil,
        goalWeight: Double? = nil,
        goalReps: Int? = nil,
        createdAt: Date? = nil,
        userPRReps: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.exerciseType = exerciseType
        self.defaultPRReps = defaultPRReps
        self.isBase = isBase
        self.usesBodyWeight = usesBodyWeight
        self.pinnedNote = pinnedNote
        self.goalWeight = goalWeight
        self.goalReps = goalReps
        self.createdAt = createdAt
        self.userPRReps = userPRReps
    }
    
    /// Get the effective PR reps to use (user's custom value or default)
    var effectivePRReps: Int {
        userPRReps ?? defaultPRReps
    }
    
    // MARK: - Helper Methods
    
    /// Format weight for display based on whether exercise uses body weight
    func formatWeight(_ weight: Double) -> String {
        if !usesBodyWeight {
            return "\(Int(weight)) lbs"
        }
        return weight > 0 ? "BW + \(Int(weight)) lbs" : "BW"
    }
    
    /// Check if exercise matches search text (searches name and muscle group)
    func matches(searchText: String) -> Bool {
        if searchText.isEmpty { return true }
        
        let lowercasedSearch = searchText.lowercased()
        
        // Search in exercise name
        if name.lowercased().contains(lowercasedSearch) {
            return true
        }
        
        // Search in muscle group
        if muscleGroup.displayName.lowercased().contains(lowercasedSearch) {
            return true
        }
        
        // Also check raw value in case it differs
        if muscleGroup.rawValue.lowercased().contains(lowercasedSearch) {
            return true
        }
        
        return false
    }
}
