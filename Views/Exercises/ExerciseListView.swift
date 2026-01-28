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
                                    currentPR: viewModel.getCurrentPR(for: exercise.id, exercise: exercise),
                                    bestDistance: viewModel.getBestDistance(for: exercise.id)
                                ) { value1, value2 in
                                    Task {
                                        if exercise.exerciseType == .strength {
                                            // value1 = weight, value2 = reps
                                            await viewModel.quickLogSet(
                                                exerciseId: exercise.id,
                                                weight: value1,
                                                reps: value2,
                                                distance: nil,
                                                duration: nil
                                            )
                                        } else {
                                            // value1 = distance, value2 = duration
                                            await viewModel.quickLogSet(
                                                exerciseId: exercise.id,
                                                weight: nil,
                                                reps: nil,
                                                distance: value1,
                                                duration: value2
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.backgroundNavy)
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
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
                AddExerciseView {
                    Task {
                        await viewModel.forceRefresh()
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.forceRefresh()
            }
            .onAppear {
                // Visibility-based refresh: only refresh if data is stale
                Task {
                    await WorkoutDataStore.shared.refreshIfStale()
                }
            }
        }
    }
}

#Preview {
    ExerciseListView()
        .environmentObject(SupabaseManager.shared)
}
