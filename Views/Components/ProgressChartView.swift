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
            
            if chartData.isEmpty {
                Text("No data for \(repFilter)+ reps")
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

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
struct CardioProgressChartView: View {
    let chartData: [(date: Date, pace: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Pace Progress")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            if chartData.isEmpty {
                Text("No cardio data yet")
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
                        .foregroundStyle(Color.green)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Pace", dataPoint.pace)
                        )
                        .foregroundStyle(Color.green)
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
            
            if chartData.isEmpty {
                Text("No data yet")
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
