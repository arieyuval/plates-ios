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
                // Dark navy background
                Color.backgroundNavy
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
                            .tint(.white)
                        Spacer()
                    } else if viewModel.filteredExercises.isEmpty {
                        Spacer()
                        Text("No exercises found")
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
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
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
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
