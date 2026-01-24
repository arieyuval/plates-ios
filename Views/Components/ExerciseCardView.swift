//
//  ExerciseCardView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    let lastSession: WorkoutSet?
    let lastSet: WorkoutSet?
    let currentPR: PersonalRecord?
    let onQuickLog: (Double, Int) -> Void
    
    @State private var weight = ""
    @State private var reps = ""
    @State private var showSuccess = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink {
            ExerciseDetailView(exercise: exercise)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Text(exercise.muscleGroup.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(exercise.muscleGroup.color(for: colorScheme))
                                .foregroundStyle(.white)
                                .cornerRadius(4)
                            
                            if exercise.pinnedNote != nil {
                                Image(systemName: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Stats
                HStack(spacing: 16) {
                    if let lastSession = lastSession {
                        StatView(title: "Last Session", value: lastSession.displayText)
                    }
                    
                    if let lastSet = lastSet {
                        StatView(title: "Last Set", value: lastSet.displayText)
                    }
                    
                    if let currentPR = currentPR {
                        StatView(
                            title: "Current \(exercise.defaultPRReps)RM",
                            value: "\(Int(currentPR.weight)) lbs"
                        )
                    }
                }
                
                // Quick log form
                if exercise.exerciseType == .strength {
                    HStack(spacing: 8) {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 80)
                        
                        Text("×")
                            .foregroundStyle(.secondary)
                        
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 60)
                        
                        Spacer()
                        
                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Done")
                                    .foregroundStyle(.green)
                                    .font(.subheadline)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Button {
                                logSet()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(weight.isEmpty || reps.isEmpty)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func logSet() {
        guard let weightValue = Double(weight),
              let repsValue = Int(reps) else {
            return
        }
        
        onQuickLog(weightValue, repsValue)
        
        // Show success animation
        withAnimation {
            showSuccess = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
                weight = ""
                reps = ""
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
}
