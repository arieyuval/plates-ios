//
//  HistoryView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI
import Combine

// MARK: - Date Extension for Timezone Conversion
extension Date {
    /// Converts UTC date to user's local timezone
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        
        let sourceOffset = TimeZone(identifier: "UTC")?.secondsFromGMT(for: self) ?? 0
        let destinationOffset = timezone.secondsFromGMT(for: self)
        let timeInterval = TimeInterval(destinationOffset - sourceOffset)
        
        return Date(timeInterval: timeInterval, since: self)
    }
}

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var editingSetInfo: EditingSetInfo?
    @State private var navigationPath = NavigationPath()
    
    struct EditingSetInfo: Identifiable {
        let id: UUID
        let set: WorkoutSet
        let exercise: Exercise
        
        init(set: WorkoutSet, exercise: Exercise) {
            self.id = set.id
            self.set = set
            self.exercise = exercise
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                    },
                                    onEdit: { set in
                                        // Find the exercise for this set
                                        if let exercise = viewModel.getExercise(for: set.exerciseId) {
                                            editingSetInfo = EditingSetInfo(set: set, exercise: exercise)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.backgroundNavy)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(item: $editingSetInfo) { info in
                EditSetView(set: info.set, exercise: info.exercise) { setId, weight, reps, distance, duration, notes in
                    await viewModel.updateSet(setId, weight: weight, reps: reps, distance: distance, duration: duration, notes: notes)
                }
            }
        }
    }
}

struct WorkoutDayCard: View {
    let workout: HistoryViewModel.WorkoutDay
    let exerciseName: (UUID) -> String
    let onDelete: (UUID) -> Void
    let onEdit: (WorkoutSet) -> Void
    
    @State private var isExpanded = false
    @State private var expandedExercises: Set<UUID> = []
    
    // Group sets by exercise
    private var groupedByExercise: [(exerciseId: UUID, sets: [WorkoutSet])] {
        let grouped = Dictionary(grouping: workout.sets) { $0.exerciseId }
        return grouped.map { (exerciseId: $0.key, sets: $0.value.sorted { $0.date > $1.date }) }
            .sorted { lhs, rhs in
                // Sort by the time of the first set (most recent first)
                guard let lhsDate = lhs.sets.first?.date,
                      let rhsDate = rhs.sets.first?.date else { return false }
                return lhsDate > rhsDate
            }
    }
    
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
            
            // Expanded content - grouped by exercise
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                ForEach(groupedByExercise, id: \.exerciseId) { group in
                    ExerciseGroupView(
                        exerciseId: group.exerciseId,
                        exerciseName: exerciseName(group.exerciseId),
                        sets: group.sets,
                        isExpanded: expandedExercises.contains(group.exerciseId),
                        onToggle: {
                            if expandedExercises.contains(group.exerciseId) {
                                expandedExercises.remove(group.exerciseId)
                            } else {
                                expandedExercises.insert(group.exerciseId)
                            }
                        },
                        onDelete: onDelete,
                        onEdit: onEdit
                    )
                }
            }
        }
        .background(Color.cardDark)
        .cornerRadius(12)
    }
}

struct ExerciseGroupView: View {
    let exerciseId: UUID
    let exerciseName: String
    let sets: [WorkoutSet]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: (UUID) -> Void
    let onEdit: (WorkoutSet) -> Void
    
    // Get the top set for the exercise (heaviest for strength, longest distance for cardio)
    private var topSet: WorkoutSet? {
        // Check if strength or cardio by looking at first set
        if let first = sets.first {
            if first.isStrength {
                return sets.max { set1, set2 in
                    guard let w1 = set1.weight, let w2 = set2.weight else { return false }
                    return w1 < w2
                }
            } else if first.isCardio {
                return sets.max { set1, set2 in
                    guard let d1 = set1.distance, let d2 = set2.distance else { return false }
                    return d1 < d2
                }
            }
        }
        return sets.first
    }
    
    // Get remaining sets (excluding the top set)
    private var remainingSets: [WorkoutSet] {
        guard let top = topSet else { return sets }
        return sets.filter { $0.id != top.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Exercise name header
            NavigationLink(destination: ExerciseDetailViewFromHistory(exerciseId: exerciseId)) {
                Text(exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .underline()
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            
            // Top set (always visible) with new layout: date | notes | set info | edit | delete | arrow
            if let topSet = topSet {
                HStack(alignment: .center, spacing: 8) {
                    // Date on the left
                    Text(topSet.date.toLocalTime(), style: .time)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 50, alignment: .leading)
                    
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
                        .foregroundStyle(.white.opacity(0.85))
                    
                    // Edit button
                    Button {
                        onEdit(topSet)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 24, height: 24)
                    }
                    
                    // Delete button
                    Button {
                        onDelete(topSet.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(width: 24, height: 24)
                    }
                    
                    // Arrow (only if there are more sets)
                    if !remainingSets.isEmpty {
                        Button {
                            onToggle()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 16)
                        }
                    } else {
                        Color.clear.frame(width: 16)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            
            // Remaining sets (collapsible) with same layout
            if isExpanded {
                ForEach(remainingSets) { set in
                    HStack(alignment: .center, spacing: 8) {
                        // Date on the left
                        Text(set.date.toLocalTime(), style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 50, alignment: .leading)
                        
                        // Notes in the middle (or placeholder)
                        if let notes = set.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.2))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Set info on the right
                        Text(set.displayText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        // Edit button
                        Button {
                            onEdit(set)
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .frame(width: 24, height: 24)
                        }
                        
                        // Delete button
                        Button {
                            onDelete(set.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(width: 24, height: 24)
                        }
                        
                        Color.clear.frame(width: 16)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

// Helper view to navigate to exercise detail from history
struct ExerciseDetailViewFromHistory: View {
    let exerciseId: UUID
    @StateObject private var viewModel = ExerciseDetailViewFromHistoryViewModel()
    
    var body: some View {
        Group {
            if let exercise = viewModel.exercise {
                ExerciseDetailView(exercise: exercise)
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                Text("Exercise not found")
            }
        }
        .task {
            await viewModel.loadExercise(exerciseId)
        }
    }
}

class ExerciseDetailViewFromHistoryViewModel: ObservableObject {
    @Published var exercise: Exercise?
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    func loadExercise(_ exerciseId: UUID) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let exercises = try await supabase.fetchExercises()
            await MainActor.run {
                exercise = exercises.first { $0.id == exerciseId }
            }
        } catch {
            print("Failed to load exercise: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(SupabaseManager.shared)
}
