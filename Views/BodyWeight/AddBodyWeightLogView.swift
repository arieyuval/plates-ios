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
                Section("Weight Entry") {
                    TextField("", text: $weight, prompt: Text("Weight (lbs)").foregroundStyle(.white.opacity(0.6)))
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Notes (Optional)") {
                    TextField("", text: $notes, prompt: Text("Add notes...").foregroundStyle(.white.opacity(0.6)), axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button {
                        logWeight()
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Log Weight")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(weight.isEmpty || isLoading)
                }
            }
            .navigationTitle("Log Weight")
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
