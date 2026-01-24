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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        // Muscle group badge
                        Text(exercise.muscleGroup.displayName)
                            .font(.subheadline)
                            .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                // Stats Row
                HStack(spacing: 12) {
                    // Last Session
                    if let lastSession = lastSession {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Session")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(lastSession.displayText)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.statBoxDark)
                        .cornerRadius(12)
                    }
                    
                    // Last Set
                    if let lastSet = lastSet {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Set")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(lastSet.displayText)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.statBoxDark)
                        .cornerRadius(12)
                    }
                    
                    // PR Box with accent color
                    if let currentPR = currentPR {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(exercise.defaultPRReps)RM PR")
                                .font(.caption)
                                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme).opacity(0.8))
                            Text("\(Int(currentPR.weight)) lbs")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(exercise.muscleGroup.color(for: colorScheme).opacity(0.15))
                        .cornerRadius(12)
                    }
                }
                
                // Quick log form
                if exercise.exerciseType == .strength {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        Text("Quick Log")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Spacer()
                        
                        TextField("Wt", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .frame(width: 80)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.statBoxDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text("×")
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.title3)
                        
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .frame(width: 80)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.statBoxDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        if showSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Button {
                                logSet()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(weight.isEmpty || reps.isEmpty)
                            .opacity(weight.isEmpty || reps.isEmpty ? 0.5 : 1.0)
                        }
                    }
                }
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(16)
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
