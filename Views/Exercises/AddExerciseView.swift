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
    let onComplete: (Exercise) -> Void
    
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
                        Picker("Muscle Group", selection: $viewModel.muscleGroup) {
                            ForEach(viewModel.strengthMuscleGroups, id: \.self) { group in
                                Text(group.rawValue).tag(group)
                            }
                        }
                        .foregroundStyle(.white.opacity(0.9))
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
                            await viewModel.submit()
                            if viewModel.error == nil {
                                // Success - dismiss modal
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
        HStack {
            Text(exercise.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(exercise.muscleGroup.rawValue)
                .font(.caption)
                .foregroundStyle(exercise.muscleGroup.color(for: colorScheme))
        }
    }
}
