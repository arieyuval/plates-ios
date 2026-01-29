//
//  AddExerciseView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AddExerciseViewModel()
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Exercise Name with Autocomplete
                Section {
                    TextField("", text: $viewModel.exerciseName, prompt: Text("e.g., Bench Press").foregroundStyle(.white.opacity(0.5)))
                        .autocapitalization(.words)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    if viewModel.showSuggestions {
                        ForEach(viewModel.suggestions) { exercise in
                            Button {
                                viewModel.selectSuggestion(exercise)
                            } label: {
                                ExerciseSuggestionRow(exercise: exercise)
                            }
                        }
                    }
                } header: {
                    Text("Exercise Name")
                        .foregroundStyle(.white.opacity(0.6))
                } footer: {
                    if viewModel.showSuggestions {
                        Text("Suggestions based on existing exercises")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .listRowBackground(Color.statBoxDark)
                
                // Exercise Type
                Section {
                    Picker("Type", selection: $viewModel.exerciseType) {
                        Text("Strength Training").tag(ExerciseType.strength)
                        Text("Cardio").tag(ExerciseType.cardio)
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.statBoxDark)
                
                // Strength-specific fields
                if viewModel.exerciseType == .strength {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Muscle Groups")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            // Muscle group chips
                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.strengthMuscleGroups, id: \.self) { group in
                                    MuscleGroupChip(
                                        group: group,
                                        isSelected: viewModel.selectedMuscleGroups.contains(group),
                                        isPrimary: viewModel.muscleGroup == group,
                                        onTap: {
                                            viewModel.toggleMuscleGroup(group)
                                        },
                                        onLongPress: {
                                            viewModel.setPrimaryMuscleGroup(group)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } footer: {
                        Text("Tap to select muscle groups. Long press to set as primary (shown under \"All\" tab).")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.statBoxDark)
                    
                    Section {
                        TextField("", value: $viewModel.defaultPRReps, format: .number, prompt: Text("3").foregroundStyle(.white.opacity(0.5)))
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white.opacity(0.9))
                    } header: {
                        Text("Default PR Reps")
                            .foregroundStyle(.white.opacity(0.6))
                    } footer: {
                        Text("The rep max to display on the card (defaults to 3)")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.statBoxDark)
                    
                    Section {
                        Toggle("Uses body weight", isOn: $viewModel.usesBodyWeight)
                            .foregroundStyle(.white.opacity(0.9))
                    } footer: {
                        Text("For exercises like pull-ups or dips where you add weight to body weight")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.statBoxDark)
                    
                    Section {
                        HStack {
                            TextField("", value: $viewModel.prReps, format: .number, prompt: Text("Reps").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.numberPad)
                                .foregroundStyle(.white.opacity(0.9))
                            Text("×")
                                .foregroundStyle(.white.opacity(0.5))
                            TextField("", value: $viewModel.prWeight, format: .number, prompt: Text("Weight").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.decimalPad)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    } header: {
                        Text("Initial PR (Optional)")
                            .foregroundStyle(.white.opacity(0.6))
                    } footer: {
                        Text("Add your current PR if you know it (e.g., 5 reps × 225 lbs)")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.statBoxDark)
                }
                
                // Cardio-specific fields
                if viewModel.exerciseType == .cardio {
                    Section {
                        HStack {
                            TextField("", value: $viewModel.prDistance, format: .number, prompt: Text("Distance").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.decimalPad)
                                .foregroundStyle(.white.opacity(0.9))
                            Text("/")
                                .foregroundStyle(.white.opacity(0.5))
                            TextField("", value: $viewModel.prDuration, format: .number, prompt: Text("Minutes").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.numberPad)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    } header: {
                        Text("Initial Session (Optional)")
                            .foregroundStyle(.white.opacity(0.6))
                    } footer: {
                        Text("Add your initial session if you would like (e.g., 3.5 miles / 30 minutes)")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.statBoxDark)
                }
                
                // Error message
                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color.statBoxDark)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundNavy)
            .navigationTitle("Add New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let success = await viewModel.submit()
                            if success {
                                // Success - call completion and dismiss
                                onComplete()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Add", systemImage: "plus")
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
        }
    }
}

struct ExerciseSuggestionRow: View {
    let exercise: Exercise
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: exercise.exerciseType == .cardio ? "figure.run" : "dumbbell.fill")
                .font(.callout)
                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                // Show all muscle groups
                Text(exercise.muscleGroups.map { $0.rawValue }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
            }
            
            Spacer()
            
            // Indicator that this exercise already exists
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}
struct MuscleGroupChip: View {
    let group: MuscleGroup
    let isSelected: Bool
    let isPrimary: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Text(group.rawValue)
                .font(.subheadline)
                .fontWeight(isPrimary ? .bold : .medium)
            
            if isPrimary {
                Image(systemName: "star.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? group.color(for: colorScheme) : Color.white.opacity(0.1))
        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isPrimary ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
        }
    }
}

// Simple flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}


