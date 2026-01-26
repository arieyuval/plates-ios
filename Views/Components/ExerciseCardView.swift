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
    let onQuickLogStrength: ((Double, Int) -> Void)?
    let onQuickLogCardio: ((Double, Int) -> Void)?
    
    @State private var weight = ""
    @State private var reps = ""
    @State private var distance = ""
    @State private var duration = ""
    @State private var showSuccess = false
    @Environment(\.colorScheme) var colorScheme
    
    // Convenience initializer for strength exercises
    init(
        exercise: Exercise,
        lastSession: WorkoutSet?,
        lastSet: WorkoutSet?,
        currentPR: PersonalRecord?,
        onQuickLog: @escaping (Double, Int) -> Void
    ) {
        self.exercise = exercise
        self.lastSession = lastSession
        self.lastSet = lastSet
        self.currentPR = currentPR
        self.onQuickLogStrength = exercise.exerciseType == .strength ? onQuickLog : nil
        self.onQuickLogCardio = exercise.exerciseType == .cardio ? onQuickLog : nil
    }
    
    // Compute which note to display based on priority
    private var displayNote: String? {
        // Priority 1: Pinned note
        if let pinnedNote = exercise.pinnedNote, !pinnedNote.isEmpty {
            return pinnedNote
        }
        
        // Priority 2: Last set note (from last session)
        if let lastSetNote = lastSet?.notes, !lastSetNote.isEmpty {
            return lastSetNote
        }
        
        return nil
    }
    
    var body: some View {
        NavigationLink {
            ExerciseDetailView(exercise: exercise)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(exercise.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.95))
                            
                            // Goal weight badge
                            if let goalWeight = exercise.goalWeight {
                                Text("Goal: \(exercise.formatWeight(goalWeight))")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.3))
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Muscle group badge and note
                        HStack(spacing: 8) {
                            Text(exercise.muscleGroup.displayName)
                                .font(.subheadline)
                                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
                            
                            if let note = displayNote {
                                Text(note)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(exercise.muscleGroup.color(for: colorScheme).opacity(0.8))
                                    .cornerRadius(6)
                                    .lineLimit(1)
                            }
                        }
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
                            Text(lastSession.displayText(usesBodyWeight: exercise.usesBodyWeight))
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
                            Text(lastSet.displayText(usesBodyWeight: exercise.usesBodyWeight))
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
                            Text(exercise.formatWeight(currentPR.weight))
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
                        // Only show weight field for non-bodyweight exercises
                        if !exercise.usesBodyWeight {
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
                        }
                        
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
                                logStrengthSet()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(reps.isEmpty || (!exercise.usesBodyWeight && weight.isEmpty))
                            .opacity((reps.isEmpty || (!exercise.usesBodyWeight && weight.isEmpty)) ? 0.5 : 1.0)
                        }
                    }
                } else if exercise.exerciseType == .cardio {
                    HStack(spacing: 10) {
                        TextField("", text: $distance, prompt: Text("Dist").foregroundStyle(.white.opacity(0.6)))
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
                        
                        TextField("", text: $duration, prompt: Text("Time").foregroundStyle(.white.opacity(0.6)))
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
                                logCardioSet()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(distance.isEmpty || duration.isEmpty)
                            .opacity(distance.isEmpty || duration.isEmpty ? 0.5 : 1.0)
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
    
    private func logStrengthSet() {
        let repsValue: Int?
        let weightValue: Double?
        
        // For body weight exercises, use 0 if no weight entered
        if exercise.usesBodyWeight {
            weightValue = weight.isEmpty ? 0 : Double(weight)
            repsValue = Int(reps)
        } else {
            // Regular exercises require both weight and reps
            guard let w = Double(weight), let r = Int(reps) else {
                return
            }
            weightValue = w
            repsValue = r
        }
        
        guard let w = weightValue, let r = repsValue,
              let quickLog = onQuickLogStrength else {
            return
        }
        
        quickLog(w, r)
        
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
    
    private func logCardioSet() {
        guard let distanceValue = Double(distance),
              let durationValue = Int(duration),
              let quickLog = onQuickLogCardio else {
            return
        }
        
        quickLog(distanceValue, durationValue)
        
        // Show success animation
        withAnimation {
            showSuccess = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
                distance = ""
                duration = ""
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
