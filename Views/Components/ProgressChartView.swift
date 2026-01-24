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
                }
                .frame(height: 200)
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

