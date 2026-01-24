//
//  BodyWeightLog.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

struct BodyWeightLog: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var weight: Double
    var date: Date
    var notes: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weight, date, notes
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        weight: Double,
        date: Date = Date(),
        notes: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.weight = weight
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
    }
}
