//
//  PRSelectorView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct PRSelectorView: View {
    @Binding var selectedRepTarget: Int
    let currentPR: PersonalRecord?
    
    @State private var repInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Record")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            // Rep input field
            HStack(spacing: 12) {
                TextField("Reps", text: $repInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.statBoxDark)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 80)
                    .focused($isInputFocused)
                    .onChange(of: repInput) { oldValue, newValue in
                        // Update selectedRepTarget when user types
                        if let value = Int(newValue), value > 0 {
                            selectedRepTarget = value
                        }
                    }
                
                Text("RM")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
            }
            .onAppear {
                // Initialize text field with current selection
                repInput = "\(selectedRepTarget)"
            }
            
            // Current PR display
            if let pr = currentPR {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(pr.weight)) lbs")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.95))
                        
                        Text("Achieved \(pr.date, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.25), Color.blue.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            } else {
                Text("No PR for \(selectedRepTarget) reps yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isInputFocused = false
        }
    }
}
