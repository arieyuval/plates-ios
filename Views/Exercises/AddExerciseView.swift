//
//  AddExerciseView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var supabase: SupabaseManager
    
    let onComplete: (Exercise) -> Void
    
    @State private var name = ""
    @State private var selectedMuscleGroup: MuscleGroup = .chest
    @State private var selectedExerciseType: ExerciseType = .strength
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(MuscleGroup.allCases.filter { $0 != .all }, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    
                    Picker("Type", selection: $selectedExerciseType) {
                        Text("Strength").tag(ExerciseType.strength)
                        Text("Cardio").tag(ExerciseType.cardio)
                    }
                    .pickerStyle(.segmented)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        createExercise()
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Exercise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createExercise() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let exercise = try await supabase.createExercise(
                    name: name,
                    muscleGroup: selectedMuscleGroup,
                    exerciseType: selectedExerciseType
                )
                
                onComplete(exercise)
                dismiss()
            } catch {
                errorMessage = "Failed to create exercise: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
