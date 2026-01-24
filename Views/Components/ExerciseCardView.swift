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
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.95))
                        
                        // Muscle group badge
                        Text(exercise.muscleGroup.displayName)
                            .font(.subheadline)
                            .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                // Stats Row
                HStack(spacing: 8) {
                    // Last Session
                    if let lastSession = lastSession {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Session")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                            Text(lastSession.displayText)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.95))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.statBoxDark)
                        .cornerRadius(10)
                    }
                    
                    // Last Set
                    if let lastSet = lastSet {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Set")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                            Text(lastSet.displayText)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.95))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.statBoxDark)
                        .cornerRadius(10)
                    }
                    
                    // PR Box with accent color
                    if let currentPR = currentPR {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(exercise.defaultPRReps)RM PR")
                                .font(.caption2)
                                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme).opacity(0.8))
                            Text("\(Int(currentPR.weight)) lbs")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(exercise.muscleGroup.color(for: colorScheme).opacity(0.15))
                        .cornerRadius(10)
                    }
                }
                
                // Quick log form
                if exercise.exerciseType == .strength {
                    HStack(spacing: 10) {
                        TextField("", text: $weight, prompt: Text("Wt").foregroundStyle(.white.opacity(0.6)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 70)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.statBoxDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("×")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.callout)
                        
                        TextField("", text: $reps, prompt: Text("Reps").foregroundStyle(.white.opacity(0.6)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 70)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.statBoxDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        Spacer()
                        
                        if showSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Button {
                                logSet()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(weight.isEmpty || reps.isEmpty)
                            .opacity(weight.isEmpty || reps.isEmpty ? 0.5 : 1.0)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.cardDark)
            .cornerRadius(12)
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
