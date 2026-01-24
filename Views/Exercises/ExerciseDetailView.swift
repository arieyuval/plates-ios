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
            // Muscle group badge
            HStack {
                Text(viewModel.exercise.muscleGroup.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.backgroundNavy)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding(.horizontal)
                
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
                
                // PR Selector and Display
                PRSelectorView(
                    exercise: viewModel.exercise,
                    selectedRepTarget: $viewModel.selectedRepTarget,
                    currentPR: viewModel.currentPR
                )
                
                // Progress Chart
                if !viewModel.sets.isEmpty {
                    if viewModel.exercise.exerciseType == .strength {
                        if viewModel.exercise.usesBodyWeight {
                            // Body weight exercises show reps progression
                            BodyWeightExerciseChartView(
                                chartData: viewModel.bodyWeightChartData()
                            )
                        } else {
                            // Regular strength exercises show weight progression
                            ProgressChartView(
                                chartData: viewModel.chartData(repFilter: viewModel.selectedRepTarget),
                                repFilter: viewModel.selectedRepTarget
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
                    exercise: viewModel.exercise
                ) { setId in
                    Task {
                        await viewModel.deleteSet(setId)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.backgroundNavy)
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadSets()
        }
        .refreshable {
            await viewModel.loadSets()
        }
    }
}
