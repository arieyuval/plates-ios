//
//  ExerciseType.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation

enum ExerciseType: String, Codable {
    case strength = "strength"
    case cardio = "cardio"
    
    var displayName: String {
        rawValue.capitalized
    }
}
