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
    var muscleGroup: MuscleGroup // Primary muscle group (first in array)
    var muscleGroups: [MuscleGroup] // All muscle groups this exercise targets
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
    
    // Custom decoding to handle both single value and array in muscle_group
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Try to decode muscle_group as array first, then as single value
        if let groupsArray = try? container.decode([MuscleGroup].self, forKey: .muscleGroup), !groupsArray.isEmpty {
            // It's already an array
            muscleGroups = groupsArray
            muscleGroup = groupsArray.first!
        } else if let singleGroup = try? container.decode(MuscleGroup.self, forKey: .muscleGroup) {
            // It's a single value (backward compatibility)
            muscleGroup = singleGroup
            muscleGroups = [singleGroup]
        } else {
            // Fallback
            muscleGroup = .chest
            muscleGroups = [.chest]
        }
        
        exerciseType = try container.decode(ExerciseType.self, forKey: .exerciseType)
        defaultPRReps = try container.decode(Int.self, forKey: .defaultPRReps)
        isBase = try container.decode(Bool.self, forKey: .isBase)
        usesBodyWeight = try container.decode(Bool.self, forKey: .usesBodyWeight)
        pinnedNote = try? container.decode(String?.self, forKey: .pinnedNote)
        goalWeight = try? container.decode(Double?.self, forKey: .goalWeight)
        goalReps = try? container.decode(Int?.self, forKey: .goalReps)
        createdAt = try? container.decode(Date?.self, forKey: .createdAt)
        userPRReps = try? container.decode(Int?.self, forKey: .userPRReps)
    }
    
    // Custom encoding - always encode as array to support multiple muscle groups
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        // Encode as array if multiple groups, single value if only one (for backward compatibility)
        if muscleGroups.count == 1 {
            try container.encode(muscleGroup, forKey: .muscleGroup)
        } else {
            try container.encode(muscleGroups, forKey: .muscleGroup)
        }
        
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encode(defaultPRReps, forKey: .defaultPRReps)
        try container.encode(isBase, forKey: .isBase)
        try container.encode(usesBodyWeight, forKey: .usesBodyWeight)
        try container.encodeIfPresent(pinnedNote, forKey: .pinnedNote)
        try container.encodeIfPresent(goalWeight, forKey: .goalWeight)
        try container.encodeIfPresent(goalReps, forKey: .goalReps)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(userPRReps, forKey: .userPRReps)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        muscleGroups: [MuscleGroup]? = nil,
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
        self.muscleGroups = muscleGroups ?? [muscleGroup]
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
    
    /// Check if exercise matches search text (searches name and muscle groups)
    func matches(searchText: String) -> Bool {
        if searchText.isEmpty { return true }
        
        let lowercasedSearch = searchText.lowercased()
        
        // Search in exercise name
        if name.lowercased().contains(lowercasedSearch) {
            return true
        }
        
        // Search in all muscle groups
        for group in muscleGroups {
            if group.displayName.lowercased().contains(lowercasedSearch) {
                return true
            }
            if group.rawValue.lowercased().contains(lowercasedSearch) {
                return true
            }
        }
        
        return false
    }
}
