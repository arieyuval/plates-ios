//
//  HistoryView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.groupedWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No workout history yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Start logging sets to see your history")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.groupedWorkouts) { workout in
                                WorkoutDayCard(
                                    workout: workout,
                                    exerciseName: viewModel.exerciseName,
                                    onDelete: { setId in
                                        Task {
                                            await viewModel.deleteSet(setId)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
}

struct WorkoutDayCard: View {
    let workout: HistoryViewModel.WorkoutDay
    let exerciseName: (UUID) -> String
    let onDelete: (UUID) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.label)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(workout.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(workout.sets.count) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                Divider()
                
                ForEach(workout.sets) { set in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exerciseName(set.exerciseId))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(set.displayText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let notes = set.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        Text(set.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    HistoryView()
        .environmentObject(SupabaseManager.shared)
}
