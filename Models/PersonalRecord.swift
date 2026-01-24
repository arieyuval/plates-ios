//
//  PersonalRecord.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

struct PersonalRecord: Identifiable, Hashable {
    var id: String { "\(reps)RM" }
    let reps: Int
    let weight: Double
    let date: Date
    
    var displayText: String {
        "\(reps)RM: \(Int(weight)) lbs"
    }
}
