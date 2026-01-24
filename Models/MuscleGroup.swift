//
//  MuscleGroup.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI

enum MuscleGroup: String, Codable, CaseIterable {
    case all = "All"
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case cardio = "Cardio"
    
    var displayName: String {
        rawValue
    }
    
    // MARK: - Color Coding
    
    func lightModeColor() -> Color {
        switch self {
        case .all:
            return .blue
        case .chest:
            return Color(red: 190/255, green: 18/255, blue: 60/255) // Rose-700
        case .back:
            return Color(red: 37/255, green: 99/255, blue: 235/255) // Blue-600
        case .legs:
            return Color(red: 21/255, green: 128/255, blue: 61/255) // Green-700
        case .shoulders:
            return Color(red: 180/255, green: 83/255, blue: 9/255) // Amber-700
        case .arms:
            return Color(red: 147/255, green: 51/255, blue: 234/255) // Purple-600
        case .biceps:
            return Color(red: 124/255, green: 58/255, blue: 237/255) // Violet-600
        case .triceps:
            return Color(red: 192/255, green: 38/255, blue: 211/255) // Fuchsia-600
        case .core:
            return Color(red: 161/255, green: 98/255, blue: 7/255) // Yellow-700
        case .cardio:
            return Color(red: 13/255, green: 148/255, blue: 136/255) // Teal-600
        }
    }
    
    func darkModeColor() -> Color {
        switch self {
        case .all:
            return .blue
        case .chest:
            return Color(red: 253/255, green: 164/255, blue: 175/255) // Rose-300
        case .back:
            return Color(red: 96/255, green: 165/255, blue: 250/255) // Blue-400
        case .legs:
            return Color(red: 134/255, green: 239/255, blue: 172/255) // Green-300
        case .shoulders:
            return Color(red: 252/255, green: 211/255, blue: 77/255) // Amber-300
        case .arms:
            return Color(red: 192/255, green: 132/255, blue: 252/255) // Purple-400
        case .biceps:
            return Color(red: 167/255, green: 139/255, blue: 250/255) // Violet-400
        case .triceps:
            return Color(red: 232/255, green: 121/255, blue: 249/255) // Fuchsia-400
        case .core:
            return Color(red: 253/255, green: 224/255, blue: 71/255) // Yellow-300
        case .cardio:
            return Color(red: 45/255, green: 212/255, blue: 191/255) // Teal-400
        }
    }
    
    func color(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkModeColor() : lightModeColor()
    }
}
