//
//  GoalRepsCardView.swift
//  Plates
//
//  Created on 1/26/26.
//

import SwiftUI

struct GoalRepsCardView: View {
    let exercise: Exercise
    let currentMax: Int?
    let onSave: (Int?) -> Void
    
    @State private var isEditing = false
    @State private var goalText = ""
    @Environment(\.colorScheme) var colorScheme
    
    private var goalReached: Bool {
        guard let goal = exercise.goalReps,
              let max = currentMax else {
            return false
        }
        return max >= goal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Goal Reps", systemImage: "target")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                
                Spacer()
                
                if !isEditing {
                    Button {
                        isEditing = true
                        goalText = exercise.goalReps.map { String($0) } ?? ""
                    } label: {
                        Text(exercise.goalReps != nil ? "Edit" : "Set")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if isEditing {
                HStack(spacing: 12) {
                    TextField("Goal Reps", text: $goalText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        saveGoal()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(goalText.isEmpty && exercise.goalReps == nil)
                    
                    Button("Cancel") {
                        isEditing = false
                        goalText = ""
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                if let goal = exercise.goalReps {
                    HStack {
                        Text("\(goal) reps")
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
                                Text("\(max) reps")
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
        let goalValue: Int?
        
        if goalText.isEmpty {
            goalValue = nil
        } else if let value = Int(goalText), value > 0 {
            goalValue = value
        } else {
            return // Invalid input
        }
        
        onSave(goalValue)
        isEditing = false
        goalText = ""
    }
}
