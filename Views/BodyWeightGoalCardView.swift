//
//  BodyWeightGoalCardView.swift
//  Plates
//
//  Created on 1/26/26.
//

import SwiftUI

struct BodyWeightGoalCardView: View {
    let currentWeight: Double?
    let goalWeight: Double?
    let startingWeight: Double?
    let onSave: (Double?) -> Void
    
    @State private var isEditing = false
    @State private var goalText = ""
    @Environment(\.colorScheme) var colorScheme
    
    private var goalReached: Bool {
        guard let goal = goalWeight,
              let current = currentWeight,
              let starting = startingWeight else {
            return false
        }
        
        // Determine if user is trying to lose or gain weight
        let isLosingWeight = goal < starting
        
        if isLosingWeight {
            // Goal reached if current weight is at or below goal
            return current <= goal
        } else {
            // Goal reached if current weight is at or above goal
            return current >= goal
        }
    }
    
    private var remainingProgress: String {
        guard let goal = goalWeight,
              let current = currentWeight else {
            return ""
        }
        
        let difference = abs(current - goal)
        let direction = current > goal ? "to lose" : "to gain"
        
        if goalReached {
            return "Goal reached!"
        } else {
            return "\(Int(difference)) lbs \(direction)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Goal Weight", systemImage: "target")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                
                Spacer()
                
                if !isEditing {
                    Button {
                        isEditing = true
                        goalText = goalWeight.map { String(format: "%.1f", $0) } ?? ""
                    } label: {
                        Text(goalWeight != nil ? "Edit" : "Set")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if isEditing {
                HStack(spacing: 12) {
                    TextField("Goal Weight", text: $goalText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        saveGoal()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(goalText.isEmpty && goalWeight == nil)
                    
                    Button("Cancel") {
                        isEditing = false
                        goalText = ""
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                if let goal = goalWeight {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(goal)) lbs")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(goalReached ? Color.green : .white.opacity(0.95))
                            
                            Text(remainingProgress)
                                .font(.caption)
                                .foregroundStyle(goalReached ? Color.green : .white.opacity(0.7))
                        }
                        
                        if goalReached {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        if let current = currentWeight {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Current")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                                Text("\(Int(current)) lbs")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                    }
                } else {
                    Text("Set a goal to track your progress")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .italic()
                }
            }
        }
        .padding()
        .background(Color.cardDark)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func saveGoal() {
        let goalValue: Double?
        
        if goalText.isEmpty {
            goalValue = nil
        } else if let value = Double(goalText), value > 0 {
            goalValue = value
        } else {
            return // Invalid input
        }
        
        onSave(goalValue)
        isEditing = false
        goalText = ""
    }
}
