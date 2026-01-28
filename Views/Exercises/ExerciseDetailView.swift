//
//  ExerciseDetailView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    @StateObject private var viewModel: ExerciseDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    
    init(exercise: Exercise) {
        _viewModel = StateObject(wrappedValue: ExerciseDetailViewModel(exercise: exercise))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pinned Note
                PinnedNoteSection(
                    note: $viewModel.pinnedNote,
                    onSave: {
                        Task {
                            await viewModel.savePinnedNote()
                        }
                    }
                )
                
                // Log Set Form (MOVED UP)
                LogSetFormView(exercise: viewModel.exercise) { weight, reps, distance, duration, notes in
                    Task {
                        await viewModel.logSet(
                            weight: weight,
                            reps: reps,
                            distance: distance,
                            duration: duration,
                            notes: notes
                        )
                    }
                }
                
                // Last Set Info
                if let lastSet = viewModel.lastSet {
                    LastSetInfoView(set: lastSet, exercise: viewModel.exercise)
                }
                
                // PR Selector and Display (only for strength exercises)
                if viewModel.exercise.exerciseType == .strength {
                    PRSelectorView(
                        exercise: viewModel.exercise,
                        selectedRepTarget: $viewModel.selectedRepTarget,
                        currentPR: viewModel.currentPR
                    )
                }
                
                // Best Pace (only for cardio exercises)
                if viewModel.exercise.exerciseType == .cardio {
                    BestPaceView(bestPace: viewModel.bestPace)
                }
                
                // Goal Weight/Reps Card (only for strength exercises)
                if viewModel.exercise.exerciseType == .strength {
                    if viewModel.exercise.usesBodyWeight {
                        // Goal Reps Card for body weight exercises
                        GoalRepsCardView(
                            exercise: viewModel.exercise,
                            currentMax: viewModel.currentMaxReps,
                            onSave: { goalReps in
                                Task {
                                    await viewModel.updateGoalReps(goalReps)
                                }
                            }
                        )
                    } else {
                        // Goal Weight Card for regular strength exercises
                        GoalWeightCardView(
                            exercise: viewModel.exercise,
                            currentMax: viewModel.currentMaxWeight,
                            onSave: { goalWeight in
                                Task {
                                    await viewModel.updateGoalWeight(goalWeight)
                                }
                            }
                        )
                    }
                }
                
                // Progress Chart
                if !viewModel.sets.isEmpty {
                    if viewModel.exercise.exerciseType == .strength {
                        if viewModel.exercise.usesBodyWeight {
                            // Body weight exercises show reps progression
                            BodyWeightExerciseChartView(
                                chartData: viewModel.bodyWeightChartData(),
                                goalReps: viewModel.exercise.goalReps
                            )
                        } else {
                            // Regular strength exercises show weight progression
                            ProgressChartView(
                                chartData: viewModel.chartData(repFilter: viewModel.selectedRepTarget),
                                repFilter: viewModel.selectedRepTarget,
                                goalWeight: viewModel.exercise.goalWeight
                            )
                        }
                    } else if viewModel.exercise.exerciseType == .cardio {
                        CardioProgressChartView(
                            chartData: viewModel.cardioChartData()
                        )
                    }
                }
                
                // Set History
                SetHistoryView(
                    groupedSets: viewModel.groupedSetsByDate,
                    exercise: viewModel.exercise,
                    onDelete: { setId in
                        Task {
                            await viewModel.deleteSet(setId)
                        }
                    },
                    onEdit: { setId, weight, reps, distance, duration, notes in
                        await viewModel.updateSet(setId, weight: weight, reps: reps, distance: distance, duration: duration, notes: notes)
                    }
                )
            }
            .padding(.vertical)
        }
        .background(Color.backgroundNavy)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text(viewModel.exercise.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(viewModel.exercise.muscleGroup.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.exercise.muscleGroup.color(for: colorScheme))
                }
            }
        }
        .task {
            await viewModel.loadSets()
        }
        .refreshable {
            await viewModel.forceRefresh()
        }
    }
}
