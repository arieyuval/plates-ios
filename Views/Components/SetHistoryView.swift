//
//  SetHistoryView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct SetHistoryView: View {
    let groupedSets: [(date: Date, sets: [WorkoutSet])]
    let exercise: Exercise
    let onDelete: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set History")
                .font(.headline)
                .padding(.horizontal)
            
            if groupedSets.isEmpty {
                Text("No sets logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ForEach(groupedSets, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Date header
                        Text(group.date, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        // Sets for this date
                        ForEach(group.sets) { set in
                            SetRowView(set: set, exercise: exercise)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        onDelete(set.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}

struct SetRowView: View {
    let set: WorkoutSet
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(set.displayText)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let notes = set.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(set.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
