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
                        .background(viewModel.exercise.muscleGroup.color(for: colorScheme))
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
                
                // Last Set Info
                if let lastSet = viewModel.lastSet {
                    LastSetInfoView(set: lastSet)
                }
                
                // PR Selector and Display
                PRSelectorView(
                    selectedRepTarget: $viewModel.selectedRepTarget,
                    currentPR: viewModel.currentPR
                )
                
                // Log Set Form
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
                
                // Personal Records Table
                PersonalRecordsTableView(prs: viewModel.personalRecords)
                
                // Progress Chart
                if !viewModel.sets.isEmpty && viewModel.exercise.exerciseType == .strength {
                    ProgressChartView(
                        chartData: viewModel.chartData(repFilter: viewModel.selectedRepTarget),
                        repFilter: viewModel.selectedRepTarget
                    )
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
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSets()
        }
        .refreshable {
            await viewModel.loadSets()
        }
    }
}
