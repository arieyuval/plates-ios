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
    
    @State private var expandedDates: Set<Date> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set History")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
                .padding(.horizontal)
            
            if groupedSets.isEmpty {
                Text("No sets logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ForEach(groupedSets, id: \.date) { group in
                    CollapsibleDayGroup(
                        date: group.date,
                        sets: group.sets,
                        exercise: exercise,
                        isExpanded: expandedDates.contains(group.date),
                        onToggle: {
                            if expandedDates.contains(group.date) {
                                expandedDates.remove(group.date)
                            } else {
                                expandedDates.insert(group.date)
                            }
                        },
                        onDelete: onDelete
                    )
                }
            }
        }
    }
}

struct CollapsibleDayGroup: View {
    let date: Date
    let sets: [WorkoutSet]
    let exercise: Exercise
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: (UUID) -> Void
    
    // Get the top set for the day (heaviest for strength, longest distance for cardio)
    private var topSet: WorkoutSet? {
        if exercise.exerciseType == .strength {
            return sets.max { set1, set2 in
                guard let w1 = set1.weight, let w2 = set2.weight else { return false }
                return w1 < w2
            }
        } else {
            return sets.max { set1, set2 in
                guard let d1 = set1.distance, let d2 = set2.distance else { return false }
                return d1 < d2
            }
        }
    }
    
    // Get remaining sets (excluding the top set)
    private var remainingSets: [WorkoutSet] {
        guard let top = topSet else { return sets }
        return sets.filter { $0.id != top.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top set row with new layout: date | notes | set info | arrow
            if let topSet = topSet {
                Button(action: {
                    if !remainingSets.isEmpty {
                        onToggle()
                    }
                }) {
                    HStack(alignment: .center, spacing: 12) {
                        // Date on the left
                        Text(topSet.date.toLocalTime(), style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 60, alignment: .leading)
                        
                        // Notes in the middle (or placeholder)
                        if let notes = topSet.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Set info on the right
                        Text(topSet.displayText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.95))
                            .frame(alignment: .trailing)
                        
                        // Arrow (only if there are more sets)
                        if !remainingSets.isEmpty {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 20)
                        } else {
                            Color.clear.frame(width: 20)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.cardDark)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDelete(topSet.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            // Remaining sets (collapsible) with same layout
            if isExpanded {
                ForEach(remainingSets) { set in
                    HStack(alignment: .center, spacing: 12) {
                        // Date on the left
                        Text(set.date.toLocalTime(), style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 60, alignment: .leading)
                        
                        // Notes in the middle (or placeholder)
                        if let notes = set.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Set info on the right
                        Text(set.displayText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(alignment: .trailing)
                        
                        Color.clear.frame(width: 20)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.cardDark.opacity(0.7))
                    .padding(.horizontal)
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

