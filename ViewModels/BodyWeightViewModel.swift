//
//  BodyWeightViewModel.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BodyWeightViewModel: ObservableObject {
    @Published var logs: [BodyWeightLog] = []
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddLog = false
    @Published var showingEditGoal = false
    
    private let supabase = SupabaseManager.shared
    
    var startingWeight: Double? {
        logs.last?.weight
    }
    
    var currentWeight: Double? {
        logs.first?.weight
    }
    
    var totalChange: Double? {
        guard let starting = startingWeight, let current = currentWeight else { return nil }
        return current - starting
    }
    
    var goalWeight: Double? {
        userProfile?.goalWeight
    }
    
    var chartData: [(date: Date, weight: Double)] {
        WorkoutCalculations.prepareBodyWeightChartData(logs: logs)
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            logs = try await supabase.fetchBodyWeightLogs()
            userProfile = try await supabase.fetchUserProfile()
        } catch {
            errorMessage = "Failed to load body weight data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func logWeight(weight: Double, date: Date, notes: String?) async {
        do {
            try await supabase.logBodyWeight(weight: weight, date: date, notes: notes)
            await loadData()
        } catch {
            errorMessage = "Failed to log weight: \(error.localizedDescription)"
        }
    }
    
    func deleteLog(_ logId: UUID) async {
        do {
            try await supabase.deleteBodyWeightLog(logId)
            await loadData()
        } catch {
            errorMessage = "Failed to delete log: \(error.localizedDescription)"
        }
    }
    
    func updateGoalWeight(_ goalWeight: Double?) async {
        do {
            try await supabase.updateGoalWeight(goalWeight)
            await loadData()
        } catch {
            errorMessage = "Failed to update goal weight: \(error.localizedDescription)"
        }
    }
}
