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
    
    let repTargets = [1, 3, 5, 8, 10]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Record")
                .font(.headline)
            
            // Segmented control
            Picker("Rep Target", selection: $selectedRepTarget) {
                ForEach(repTargets, id: \.self) { target in
                    Text("\(target)RM")
                        .tag(target)
                }
            }
            .pickerStyle(.segmented)
            
            // Current PR display
            if let pr = currentPR {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(pr.weight)) lbs")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Achieved \(pr.date, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            } else {
                Text("No PR for \(selectedRepTarget) reps yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}
