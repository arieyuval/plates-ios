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
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case muscleGroup = "muscle_group"
        case exerciseType = "exercise_type"
        case defaultPRReps = "default_pr_reps"
        case isBase = "is_base"
        case usesBodyWeight = "uses_body_weight"
        case pinnedNote = "pinned_note"
        case createdAt = "created_at"
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
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.exerciseType = exerciseType
        self.defaultPRReps = defaultPRReps
        self.isBase = isBase
        self.usesBodyWeight = usesBodyWeight
        self.pinnedNote = pinnedNote
        self.createdAt = createdAt
    }
}
