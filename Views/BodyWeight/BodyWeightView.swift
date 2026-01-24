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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundNavy
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
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
                                    goalWeight: viewModel.goalWeight
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
                                }
                            )
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Body Weight")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $viewModel.showingAddLog) {
                AddBodyWeightLogView { weight, date, notes in
                    Task {
                        await viewModel.logWeight(weight: weight, date: date, notes: notes)
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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                if let starting = startingWeight {
                    StatCard(title: "Starting", value: "\(Int(starting)) lbs", color: .gray)
                }
                
                if let change = totalChange {
                    StatCard(
                        title: "Total Change",
                        value: "\(change > 0 ? "+" : "")\(Int(change)) lbs",
                        color: change > 0 ? .green : .red
                    )
                }
                
                if let current = currentWeight {
                    StatCard(title: "Current", value: "\(Int(current)) lbs", color: .blue)
                }
                
                if let goal = goalWeight {
                    Button {
                        onEditGoal()
                    } label: {
                        StatCard(title: "Goal", value: "\(Int(goal)) lbs", color: .purple)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            Chart {
                // Weight line
                ForEach(chartData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.weight)
                    )
                    .foregroundStyle(Color.blue)
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.weight)
                    )
                    .foregroundStyle(Color.blue)
                }
                
                // Goal line
                if let goal = goalWeight {
                    RuleMark(y: .value("Goal", goal))
                        .foregroundStyle(Color.purple.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .frame(height: 250)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(Int(weight))")
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(Color.cardDark)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct WeightHistoryView: View {
    let logs: [BodyWeightLog]
    let onDelete: (UUID) -> Void
    
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
                    }
                    .padding()
                    .background(Color.cardDark)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete(log.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BodyWeightView()
        .environmentObject(SupabaseManager.shared)
}
