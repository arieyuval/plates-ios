//
//  ExerciseListView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct ExerciseListView: View {
    @StateObject private var viewModel = ExerciseListViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Muscle group tabs
                    MuscleGroupTabsView(selectedGroup: $viewModel.selectedMuscleGroup)
                        .padding(.vertical, 8)
                    
                    // Exercise list
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.filteredExercises.isEmpty {
                        Spacer()
                        Text("No exercises found")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredExercises) { exercise in
                                    ExerciseCardView(
                                        exercise: exercise,
                                        lastSession: viewModel.getLastSession(for: exercise.id),
                                        lastSet: viewModel.getLastSet(for: exercise.id),
                                        currentPR: viewModel.getCurrentPR(for: exercise.id, exercise: exercise)
                                    ) { weight, reps in
                                        Task {
                                            await viewModel.quickLogSet(exerciseId: exercise.id, weight: weight, reps: reps)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddExercise) {
                AddExerciseView { exercise in
                    Task {
                        await viewModel.loadData()
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
}

#Preview {
    ExerciseListView()
        .environmentObject(SupabaseManager.shared)
}
