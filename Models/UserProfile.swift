//
//  UserProfile.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var currentWeight: Double?
    var goalWeight: Double?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentWeight = "current_weight"
        case goalWeight = "goal_weight"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        currentWeight: Double? = nil,
        goalWeight: Double? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.currentWeight = currentWeight
        self.goalWeight = goalWeight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
