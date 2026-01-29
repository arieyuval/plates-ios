//
//  ProgressChartView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI
import Charts

struct ProgressChartView: View {
    let chartData: [(date: Date, weight: Double)]
    let repFilter: Int
    let goalWeight: Double?
    
    private var maxWeight: Double? {
        chartData.map(\.weight).max()
    }
    
    private var goalReached: Bool {
        guard let goal = goalWeight, let max = maxWeight else {
            return false
        }
        return max >= goal
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else {
            return 0...100
        }
        
        let dataMin = chartData.map(\.weight).min() ?? 0
        let dataMax = chartData.map(\.weight).max() ?? 100
        
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
            Text("Progress Chart (\(repFilter)+ Reps)")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            if chartData.count < 2 {
                Text(chartData.isEmpty ? "No data for \(repFilter)+ reps" : "Not enough data to graph (need 2+ data points)")
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
                    
                    // Data line and points
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
                .frame(height: 200)
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


struct CardioProgressChartView: View {
    let chartData: [(date: Date, pace: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Pace Progress")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            if chartData.count < 2 {
                Text(chartData.isEmpty ? "No cardio data yet" : "Not enough data to graph (need 2+ data points)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
            } else {
                Chart {
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Pace", dataPoint.pace)
                        )
                        .foregroundStyle(Color.blue)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Pace", dataPoint.pace)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: false, reversed: true))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel {
                            if let pace = value.as(Double.self) {
                                Text(String(format: "%.1f", pace))
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
            
            Text("Lower is better (min/mi)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal)
    }
}

struct BodyWeightExerciseChartView: View {
    let chartData: [(date: Date, reps: Int)]
    let goalReps: Int?
    
    private var maxReps: Int? {
        chartData.map(\.reps).max()
    }
    
    private var goalReached: Bool {
        guard let goal = goalReps, let max = maxReps else {
            return false
        }
        return max >= goal
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else {
            return 0...20
        }
        
        let dataMin = Double(chartData.map(\.reps).min() ?? 0)
        let dataMax = Double(chartData.map(\.reps).max() ?? 20)
        
        // Include goal reps in domain if it exists
        if let goal = goalReps {
            let goalDouble = Double(goal)
            let min = min(dataMin, goalDouble)
            let max = max(dataMax, goalDouble)
            let padding = (max - min) * 0.1
            return (min - padding)...(max + padding)
        } else {
            let padding = (dataMax - dataMin) * 0.1
            return (dataMin - padding)...(dataMax + padding)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Max Reps Progress")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            if chartData.count < 2 {
                Text(chartData.isEmpty ? "No data yet" : "Not enough data to graph (need 2+ data points)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
            } else {
                Chart {
                    // Goal reference line
                    if let goal = goalReps {
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(goalReached ? Color.green : Color(hex: "3B82F6"))
                            .lineStyle(StrokeStyle(
                                lineWidth: 2,
                                dash: goalReached ? [] : [5, 5]
                            ))
                            .annotation(position: .trailing, alignment: .trailing) {
                                Text("Goal: \(goal)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(goalReached ? .green : Color(hex: "3B82F6"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.cardDark.opacity(0.9))
                                    .cornerRadius(4)
                            }
                    }
                    
                    // Data line and points
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Reps", dataPoint.reps)
                        )
                        .foregroundStyle(goalReached ? Color.green : Color.purple)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Reps", dataPoint.reps)
                        )
                        .foregroundStyle(goalReached ? Color.green : Color.purple)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: yAxisDomain)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel {
                            if let reps = value.as(Int.self) {
                                Text("\(reps)")
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
            
            Text("Maximum reps achieved per day")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal)
    }
}
