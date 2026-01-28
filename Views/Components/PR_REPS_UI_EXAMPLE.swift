//
//  PR_REPS_UI_EXAMPLE.swift
//  Example code for adding UI to customize PR reps
//
//  Add this to ExerciseDetailView or create a settings section
//

import SwiftUI

// MARK: - Example 1: Simple Picker in ExerciseDetailView

struct PRRepsSettingView: View {
    let exercise: Exercise
    @State private var selectedPRReps: Int
    @State private var isSaving = false
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _selectedPRReps = State(initialValue: exercise.effectivePRReps)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PR Rep Target")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            Picker("PR Reps", selection: $selectedPRReps) {
                ForEach([1, 3, 5, 8, 10, 12, 15], id: \.self) { reps in
                    Text("\(reps) RM")
                        .tag(reps)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPRReps) { _, newValue in
                Task {
                    await savePRReps(newValue)
                }
            }
            
            Text("Your PR will be calculated for sets of \(selectedPRReps) reps")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding()
        .background(Color.cardDark)
        .cornerRadius(12)
    }
    
    private func savePRReps(_ reps: Int) async {
        isSaving = true
        
        do {
            // Save custom PR reps (or nil to use default)
            let valueToSave = (reps == exercise.defaultPRReps) ? nil : reps
            
            try await WorkoutDataStore.shared.updateUserPRReps(
                exerciseId: exercise.id,
                userPRReps: valueToSave
            )
            
            print("✅ Updated PR reps to \(reps)")
        } catch {
            print("❌ Failed to update PR reps: \(error)")
        }
        
        isSaving = false
    }
}

// MARK: - Example 2: Stepper-based UI

struct PRRepsStepperView: View {
    let exercise: Exercise
    @State private var selectedPRReps: Int
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _selectedPRReps = State(initialValue: exercise.effectivePRReps)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PR Rep Target")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("Calculate PR for sets of this many reps")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Stepper(
                value: $selectedPRReps,
                in: 1...20,
                step: 1
            ) {
                Text("\(selectedPRReps) RM")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .onChange(of: selectedPRReps) { _, newValue in
                Task {
                    try? await WorkoutDataStore.shared.updateUserPRReps(
                        exerciseId: exercise.id,
                        userPRReps: newValue == exercise.defaultPRReps ? nil : newValue
                    )
                }
            }
        }
        .padding()
        .background(Color.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Example 3: Settings Sheet

struct ExerciseSettingsSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    
    @State private var prReps: Int
    @State private var isSaving = false
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _prReps = State(initialValue: exercise.effectivePRReps)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("PR Rep Target", selection: $prReps) {
                        ForEach(1...20, id: \.self) { reps in
                            Text("\(reps) RM")
                                .tag(reps)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    if prReps != exercise.defaultPRReps {
                        HStack {
                            Text("Default for this exercise")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(exercise.defaultPRReps) RM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Personal Record Settings")
                } footer: {
                    Text("Your PR will be tracked for sets of \(prReps) reps. You can change this anytime.")
                }
            }
            .navigationTitle("Exercise Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func save() async {
        isSaving = true
        
        do {
            let valueToSave = (prReps == exercise.defaultPRReps) ? nil : prReps
            
            try await WorkoutDataStore.shared.updateUserPRReps(
                exerciseId: exercise.id,
                userPRReps: valueToSave
            )
            
            dismiss()
        } catch {
            print("❌ Failed to save: \(error)")
        }
        
        isSaving = false
    }
}

// MARK: - Example 4: Inline in ExerciseDetailView

/*
 Add this section to ExerciseDetailView.swift:
 
 // PR Settings Section
 VStack(alignment: .leading, spacing: 12) {
     Text("PR Settings")
         .font(.headline)
         .foregroundStyle(.white)
     
     PRRepsSettingView(exercise: viewModel.exercise)
 }
 .padding(.horizontal)
 
 */

// MARK: - Usage in ExerciseDetailView

/*
 Option 1: Add as a section in the ScrollView
 
 In ExerciseDetailView.swift, add this section after PinnedNoteSection:
 
 // PR Settings
 PRRepsSettingView(exercise: viewModel.exercise)
     .padding(.horizontal)
 
 
 Option 2: Add as a button that shows a sheet
 
 @State private var showingSettings = false
 
 // In toolbar:
 .toolbar {
     ToolbarItem(placement: .primaryAction) {
         Button {
             showingSettings = true
         } label: {
             Image(systemName: "gear")
                 .foregroundStyle(.white)
         }
     }
 }
 .sheet(isPresented: $showingSettings) {
     ExerciseSettingsSheet(exercise: viewModel.exercise)
 }
 */
