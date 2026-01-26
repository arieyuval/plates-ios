//
//  WorkoutSet.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

struct WorkoutSet: Identifiable, Codable, Hashable {
    let id: UUID
    var exerciseId: UUID
    var userId: UUID?

    // Strength fields
    var weight: Double?
    var reps: Int?

    // Cardio fields
    var distance: Double?
    var duration: Int?

    var date: Date
    var notes: String?
    var createdAt: Date?

    // MARK: - Computed Properties
    
    var isStrength: Bool { 
        weight != nil && reps != nil 
    }
    
    var isCardio: Bool { 
        distance != nil && duration != nil 
    }
    
    var displayText: String {
        if isStrength, let weight = weight, let reps = reps {
            return "\(Int(weight)) lbs × \(reps)"
        } else if isCardio, let distance = distance, let duration = duration {
            return "\(String(format: "%.2f", distance)) mi • \(duration) min"
        }
        return "Invalid set"
    }
    
    /// Format set display text with body weight support
    func displayText(usesBodyWeight: Bool) -> String {
        if isStrength, let weight = weight, let reps = reps {
            let weightText = formatWeight(weight, usesBodyWeight: usesBodyWeight)
            return "\(weightText) × \(reps)"
        } else if isCardio, let distance = distance, let duration = duration {
            return "\(String(format: "%.2f", distance)) mi • \(duration) min"
        }
        return "Invalid set"
    }
    
    /// Format weight for display
    private func formatWeight(_ weight: Double, usesBodyWeight: Bool) -> String {
        if !usesBodyWeight {
            return "\(Int(weight)) lbs"
        }
        return weight > 0 ? "BW + \(Int(weight)) lbs" : "BW"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case userId = "user_id"
        case weight, reps, distance, duration, date, notes
        case createdAt = "created_at"
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        userId: UUID? = nil,
        weight: Double? = nil,
        reps: Int? = nil,
        distance: Double? = nil,
        duration: Int? = nil,
        date: Date = Date(),
        notes: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.userId = userId
        self.weight = weight
        self.reps = reps
        self.distance = distance
        self.duration = duration
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
    }
}
