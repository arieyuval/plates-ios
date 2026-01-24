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
                Color.backgroundNavy
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.groupedWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("No workout history yet")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Start logging sets to see your history")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                            .foregroundStyle(.white)
                        
                        Text(workout.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(workout.sets.count) sets")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                ForEach(workout.sets) { set in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exerciseName(set.exerciseId))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                            
                            Text(set.displayText)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            if let notes = set.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        Text(set.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
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
        .background(Color.cardDark)
        .cornerRadius(12)
    }
}

#Preview {
    HistoryView()
        .environmentObject(SupabaseManager.shared)
}
