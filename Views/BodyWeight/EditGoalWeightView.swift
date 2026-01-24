//
//  EditGoalWeightView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct EditGoalWeightView: View {
    @Environment(\.dismiss) var dismiss
    
    let currentGoal: Double?
    let onComplete: (Double) -> Void
    
    @State private var goalWeight = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Weight") {
                    TextField("Weight (lbs)", text: $goalWeight)
                        .keyboardType(.decimalPad)
                }
                
                if let current = currentGoal {
                    Section {
                        HStack {
                            Text("Current Goal")
                            Spacer()
                            Text("\(Int(current)) lbs")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        updateGoal()
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Update Goal")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(goalWeight.isEmpty || isLoading)
                }
            }
            .navigationTitle("Edit Goal Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let current = currentGoal {
                    goalWeight = "\(Int(current))"
                }
            }
        }
    }
    
    private func updateGoal() {
        guard let goalValue = Double(goalWeight) else { return }
        
        isLoading = true
        onComplete(goalValue)
        
        dismiss()
    }
}
