//
//  EditSetView.swift
//  Plates
//
//  Created on 1/25/26.
//

import SwiftUI

struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: EditSetViewModel
    let onSave: (UUID, Double?, Int?, Double?, Int?, String?) async -> Void
    
    init(set: WorkoutSet, exercise: Exercise, onSave: @escaping (UUID, Double?, Int?, Double?, Int?, String?) async -> Void) {
        _viewModel = State(wrappedValue: EditSetViewModel(set: set, exercise: exercise))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Strength fields
                if viewModel.exercise.exerciseType == .strength {
                    Section {
                        if !viewModel.exercise.usesBodyWeight {
                            HStack {
                                Text("Weight")
                                    .foregroundStyle(.white.opacity(0.6))
                                Spacer()
                                TextField("", value: $viewModel.weight, format: .number, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(width: 100)
                                Text("lbs")
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        } else {
                            HStack {
                                Text("Added Weight")
                                    .foregroundStyle(.white.opacity(0.6))
                                Spacer()
                                TextField("", value: $viewModel.weight, format: .number, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(width: 100)
                                Text("lbs")
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        
                        HStack {
                            Text("Reps")
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            TextField("", value: $viewModel.reps, format: .number, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 100)
                        }
                    } header: {
                        Text("Set Details")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.statBoxDark)
                }
                
                // Cardio fields
                if viewModel.exercise.exerciseType == .cardio {
                    Section {
                        HStack {
                            Text("Distance")
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            TextField("", value: $viewModel.distance, format: .number, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 100)
                            Text("mi")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Duration")
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            TextField("", value: $viewModel.duration, format: .number, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 100)
                            Text("min")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } header: {
                        Text("Session Details")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.statBoxDark)
                }
                
                // Notes field (for both types)
                Section {
                    TextField("", text: $viewModel.notes, prompt: Text("Add notes...").foregroundStyle(.white.opacity(0.5)), axis: .vertical)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.statBoxDark)
                
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
            .navigationTitle("Edit Set")
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
                            await viewModel.save(onSave: onSave)
                            if viewModel.error == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
    }
}

@MainActor
@Observable
final class EditSetViewModel {
    let set: WorkoutSet
    let exercise: Exercise
    
    var weight: Double?
    var reps: Int?
    var distance: Double?
    var duration: Int?
    var notes: String
    var error: String?
    var isSaving = false
    
    init(set: WorkoutSet, exercise: Exercise) {
        self.set = set
        self.exercise = exercise
        self.weight = set.weight
        self.reps = set.reps
        self.distance = set.distance
        self.duration = set.duration
        self.notes = set.notes ?? ""
    }
    
    var isValid: Bool {
        if exercise.exerciseType == .strength {
            if exercise.usesBodyWeight {
                // For body weight exercises, weight can be 0 or nil, but reps is required
                return reps != nil && reps! > 0
            } else {
                // For regular strength exercises, both weight and reps are required
                return weight != nil && weight! > 0 && reps != nil && reps! > 0
            }
        } else {
            // For cardio, both distance and duration are required
            return distance != nil && distance! > 0 && duration != nil && duration! > 0
        }
    }
    
    func save(onSave: (UUID, Double?, Int?, Double?, Int?, String?) async -> Void) async {
        isSaving = true
        error = nil
        
        // Validate based on exercise type
        if exercise.exerciseType == .strength {
            if exercise.usesBodyWeight {
                guard reps != nil && reps! > 0 else {
                    error = "Reps must be greater than 0"
                    isSaving = false
                    return
                }
            } else {
                guard weight != nil && weight! > 0 else {
                    error = "Weight must be greater than 0"
                    isSaving = false
                    return
                }
                guard reps != nil && reps! > 0 else {
                    error = "Reps must be greater than 0"
                    isSaving = false
                    return
                }
            }
        } else {
            guard distance != nil && distance! > 0 else {
                error = "Distance must be greater than 0"
                isSaving = false
                return
            }
            guard duration != nil && duration! > 0 else {
                error = "Duration must be greater than 0"
                isSaving = false
                return
            }
        }
        
        let notesToSave = notes.isEmpty ? nil : notes
        
        await onSave(set.id, weight, reps, distance, duration, notesToSave)
        
        isSaving = false
    }
}
