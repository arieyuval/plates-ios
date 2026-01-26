//
//  AddBodyWeightLogView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct AddBodyWeightLogView: View {
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Double, Date, String?) -> Void
    
    @State private var weight = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Weight")
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        TextField("", text: $weight, prompt: Text("0").foregroundStyle(.white.opacity(0.5)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 100)
                        Text("lbs")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundStyle(.white.opacity(0.9))
                        .tint(.blue)
                } header: {
                    Text("Weight Entry")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.statBoxDark)
                
                Section {
                    TextField("", text: $notes, prompt: Text("Add notes...").foregroundStyle(.white.opacity(0.5)), axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundStyle(.white.opacity(0.9))
                } header: {
                    Text("Notes (Optional)")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(Color.statBoxDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundNavy)
            .navigationTitle("Log Weight")
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
                        logWeight()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(weight.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func logWeight() {
        guard let weightValue = Double(weight) else { return }
        
        isLoading = true
        
        let notesValue = notes.isEmpty ? nil : notes
        onComplete(weightValue, date, notesValue)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}
