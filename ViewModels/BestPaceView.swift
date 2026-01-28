//
//  BestPaceView.swift
//  Plates
//
//  Created on 1/28/26.
//

import SwiftUI

struct BestPaceView: View {
    let bestPace: CardioBestPace?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Pace Overall")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            // Best pace display
            if let pace = bestPace {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            // Pace display
                            Text(formatPace(pace.pace))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.95))
                            
                            Text("min/mi")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.top, 8)
                        }
                        
                        // Distance and duration
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text(formatDistance(pace.distance))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("mi")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            Text("•")
                                .foregroundStyle(.white.opacity(0.5))
                            
                            HStack(spacing: 4) {
                                Text("\(pace.duration)")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("min")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        
                        Text("Achieved \(pace.date, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.25), Color.blue.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            } else {
                Text("No pace data yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(distance))"
        } else {
            return String(format: "%.1f", distance)
        }
    }
}

struct CardioBestPace {
    let pace: Double // minutes per mile
    let distance: Double
    let duration: Int
    let date: Date
}
