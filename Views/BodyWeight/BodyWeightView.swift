//
//  BodyWeightView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI
import Charts

struct BodyWeightView: View {
    @StateObject private var viewModel = BodyWeightViewModel()
    @State private var editingLog: BodyWeightLog?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats cards
                    StatsCardsView(
                        startingWeight: viewModel.startingWeight,
                        currentWeight: viewModel.currentWeight,
                        totalChange: viewModel.totalChange,
                        goalWeight: viewModel.goalWeight,
                        onEditGoal: {
                            viewModel.showingEditGoal = true
                        }
                    )
                    
                    // Progress chart
                    if !viewModel.logs.isEmpty {
                        BodyWeightChartView(
                            chartData: viewModel.chartData,
                            goalWeight: viewModel.goalWeight,
                            startingWeight: viewModel.startingWeight
                        )
                    }
                    
                    // Add weight button
                    Button {
                        viewModel.showingAddLog = true
                    } label: {
                        Label("Log Weight", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Weight history
                    WeightHistoryView(
                        logs: viewModel.logs,
                        onDelete: { logId in
                            Task {
                                await viewModel.deleteLog(logId)
                            }
                        },
                        onEdit: { log in
                            editingLog = log
                        }
                    )
                }
                .padding(.vertical)
            }
            .background(Color.backgroundNavy)
            .navigationTitle("Body Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $viewModel.showingAddLog) {
                AddBodyWeightLogView { weight, date, notes in
                    Task {
                        await viewModel.logWeight(weight: weight, date: date, notes: notes)
                    }
                }
            }
            .sheet(item: $editingLog) { log in
                EditBodyWeightLogView(log: log) { logId, weight, date, notes in
                    Task {
                        await viewModel.updateLog(logId, weight: weight, date: date, notes: notes)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingEditGoal) {
                EditGoalWeightView(currentGoal: viewModel.goalWeight) { newGoal in
                    Task {
                        await viewModel.updateGoalWeight(newGoal)
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

struct StatsCardsView: View {
    let startingWeight: Double?
    let currentWeight: Double?
    let totalChange: Double?
    let goalWeight: Double?
    let onEditGoal: () -> Void
    
    private var goalReached: Bool {
        guard let goal = goalWeight,
              let current = currentWeight,
              let starting = startingWeight else {
            return false
        }
        
        // Determine if user is trying to lose or gain weight
        let isLosingWeight = goal < starting
        
        if isLosingWeight {
            // Goal reached if current weight is at or below goal
            return current <= goal
        } else {
            // Goal reached if current weight is at or above goal
            return current >= goal
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                if let starting = startingWeight {
                    StatCard(title: "Starting", value: "\(Int(starting)) lbs", color: .gray)
                }
                
                if let current = currentWeight {
                    StatCard(title: "Current", value: "\(Int(current)) lbs", color: goalReached ? .green : .white)
                }
                
                if let goal = goalWeight {
                    Button {
                        onEditGoal()
                    } label: {
                        StatCard(title: "Goal", value: "\(Int(goal)) lbs", color: goalReached ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding()
        .frame(minWidth: 120)
        .background(Color.cardDark)
        .cornerRadius(12)
    }
}

struct BodyWeightChartView: View {
    let chartData: [(date: Date, weight: Double)]
    let goalWeight: Double?
    let startingWeight: Double?
    
    private var currentWeight: Double? {
        chartData.first?.weight
    }
    
    private var goalReached: Bool {
        guard let goal = goalWeight,
              let current = currentWeight,
              let starting = startingWeight else {
            return false
        }
        
        // Determine if user is trying to lose or gain weight
        let isLosingWeight = goal < starting
        
        if isLosingWeight {
            // Goal reached if current weight is at or below goal
            return current <= goal
        } else {
            // Goal reached if current weight is at or above goal
            return current >= goal
        }
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else {
            return 0...200
        }
        
        let dataMin = chartData.map(\.weight).min() ?? 0
        let dataMax = chartData.map(\.weight).max() ?? 200
        
        // Include goal weight in domain if it exists
        if let goal = goalWeight {
            let min = min(dataMin, goal)
            let max = max(dataMax, goal)
            let padding = (max - min) * 0.1
            return (min - padding)...(max + padding)
        } else {
            let padding = (dataMax - dataMin) * 0.1
            return (dataMin - padding)...(dataMax + padding)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            if chartData.count < 2 {
                Text(chartData.isEmpty ? "No weight logs yet" : "Not enough data to graph (need 2+ data points)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
            } else {
                Chart {
                    // Goal reference line
                    if let goal = goalWeight {
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(goalReached ? Color.green : Color(hex: "3B82F6"))
                            .lineStyle(StrokeStyle(
                                lineWidth: 2,
                                dash: goalReached ? [] : [5, 5]
                            ))
                            .annotation(position: .trailing, alignment: .trailing) {
                                Text("Goal: \(Int(goal))")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(goalReached ? .green : Color(hex: "3B82F6"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.cardDark.opacity(0.9))
                                    .cornerRadius(4)
                            }
                    }
                    
                    // Weight line and points
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Weight", dataPoint.weight)
                        )
                        .foregroundStyle(goalReached ? Color.green : Color.blue)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Weight", dataPoint.weight)
                        )
                        .foregroundStyle(goalReached ? Color.green : Color.blue)
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: yAxisDomain)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight))")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.cardDark)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

struct WeightHistoryView: View {
    let logs: [BodyWeightLog]
    let onDelete: (UUID) -> Void
    let onEdit: (BodyWeightLog) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            if logs.isEmpty {
                Text("No weight logs yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ForEach(logs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(log.weight)) lbs")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text(log.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            if let notes = log.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button {
                                onEdit(log)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Button {
                                onDelete(log.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.red.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardDark)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    BodyWeightView()
        .environmentObject(SupabaseManager.shared)
}
