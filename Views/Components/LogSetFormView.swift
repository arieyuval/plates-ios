//
//  LogSetFormView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct LogSetFormView: View {
    let exercise: Exercise
    let onSubmit: (Double?, Int?, Double?, Int?, String?) -> Void
    
    @State private var weight = ""
    @State private var reps = ""
    @State private var distance = ""
    @State private var duration = ""
    @State private var notes = ""
    @State private var showSuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Set")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            VStack(spacing: 12) {
                if exercise.exerciseType == .strength {
                    // Strength inputs
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight (lbs)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            TextField("", text: $weight, prompt: Text("0").foregroundStyle(.white.opacity(0.6)))
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color.statBoxDark)
                                .foregroundStyle(.white.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            TextField("", text: $reps, prompt: Text("0").foregroundStyle(.white.opacity(0.6)))
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.statBoxDark)
                                .foregroundStyle(.white.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                } else {
                    // Cardio inputs
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Distance (mi)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            TextField("", text: $distance, prompt: Text("0.0").foregroundStyle(.white.opacity(0.6)))
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color.statBoxDark)
                                .foregroundStyle(.white.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration (min)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            TextField("", text: $duration, prompt: Text("0").foregroundStyle(.white.opacity(0.6)))
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.statBoxDark)
                                .foregroundStyle(.white.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes (optional)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    TextField("", text: $notes, prompt: Text("Add notes...").foregroundStyle(.white.opacity(0.6)), axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(Color.statBoxDark)
                        .foregroundStyle(.white.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Submit button
                Button {
                    logSet()
                } label: {
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Logged!")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    } else {
                        Text("Log Set")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(!isValid || showSuccess)
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var isValid: Bool {
        if exercise.exerciseType == .strength {
            return !weight.isEmpty && !reps.isEmpty
        } else {
            return !distance.isEmpty && !duration.isEmpty
        }
    }
    
    private func logSet() {
        let weightValue = Double(weight)
        let repsValue = Int(reps)
        let distanceValue = Double(distance)
        let durationValue = Int(duration)
        let notesValue = notes.isEmpty ? nil : notes
        
        onSubmit(weightValue, repsValue, distanceValue, durationValue, notesValue)
        
        // Show success
        withAnimation {
            showSuccess = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
                weight = ""
                reps = ""
                distance = ""
                duration = ""
                notes = ""
            }
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
