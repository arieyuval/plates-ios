//
//  GoalWeightCardView.swift
//  Plates
//
//  Created on 1/26/26.
//

import SwiftUI

struct GoalWeightCardView: View {
    let exercise: Exercise
    let currentMax: Double?
    let onSave: (Double?) -> Void
    
    @State private var isEditing = false
    @State private var goalText = ""
    @Environment(\.colorScheme) var colorScheme
    
    private var goalReached: Bool {
        guard let goal = exercise.goalWeight,
              let max = currentMax else {
            return false
        }
        return max >= goal
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
                        goalText = exercise.goalWeight.map { String(format: "%.1f", $0) } ?? ""
                    } label: {
                        Text(exercise.goalWeight != nil ? "Edit" : "Set")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if isEditing {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Goal Weight", text: $goalText)
                            .keyboardType(.decimalPad)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                        
                        Text("lbs")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 12) {
                        Button("Save") {
                            saveGoal()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(goalText.isEmpty && exercise.goalWeight == nil ? Color.blue.opacity(0.3) : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                        .disabled(goalText.isEmpty && exercise.goalWeight == nil)
                        
                        Button("Cancel") {
                            isEditing = false
                            goalText = ""
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                }
            } else {
                if let goal = exercise.goalWeight {
                    HStack {
                        Text(exercise.formatWeight(goal))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(goalReached ? Color.green : .white.opacity(0.95))
                        
                        if goalReached {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                        }
                        
                        Spacer()
                        
                        if let max = currentMax {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Current Max")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(exercise.formatWeight(max))
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
        } else if let value = Double(goalText) {
            goalValue = value
        } else {
            return // Invalid input
        }
        
        onSave(goalValue)
        isEditing = false
        goalText = ""
    }
}
