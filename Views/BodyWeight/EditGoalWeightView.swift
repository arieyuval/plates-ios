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
                Section {
                    HStack {
                        Text("Goal Weight")
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        TextField("", text: $goalWeight, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 100)
                        Text("lbs")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } header: {
                    Text("New Goal")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.statBoxDark)
                
                if let current = currentGoal {
                    Section {
                        HStack {
                            Text("Current Goal")
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text("\(Int(current)) lbs")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    } header: {
                        Text("Current")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.statBoxDark)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundNavy)
            .navigationTitle("Edit Goal Weight")
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
                        updateGoal()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(goalWeight.isEmpty || isLoading)
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
