//
//  SupabaseManager.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // MARK: - Configuration
        // TODO: Replace with your actual Supabase credentials
        // Store these securely (Keychain or xcconfig, never hardcode in production)
        let supabaseURL = URL(string: "https://ikihabdfvjicjuatpjvd.supabase.co")!
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlraWhhYmRmdmppY2p1YXRwanZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTk1OTcsImV4cCI6MjA4Mzk5NTU5N30.2oN6Za7kYF9MmhH7mvAlHIXRe9NDWLv4ynSExT5G0Uw"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
        
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Management
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, name: String, initialWeight: Double? = nil, goalWeight: Double? = nil) async throws {
        var metadata: [String: AnyJSON] = ["name": .string(name)]
        
        if let initialWeight = initialWeight {
            metadata["initial_weight"] = .number(initialWeight)
        }
        
        if let goalWeight = goalWeight {
            metadata["goal_weight"] = .number(goalWeight)
        }
        
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        
        self.currentUser = response.user
        self.isAuthenticated = true
        
        // Create user profile
        if let userId = response.user?.id {
            try await createUserProfile(userId: userId, initialWeight: initialWeight, goalWeight: goalWeight)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        self.currentUser = session.user
        self.isAuthenticated = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - User Profile
    
    private func createUserProfile(userId: UUID, initialWeight: Double?, goalWeight: Double?) async throws {
        let profile: [String: Any] = [
            "user_id": userId.uuidString,
            "current_weight": initialWeight as Any,
            "goal_weight": goalWeight as Any
        ]
        
        try await client.from("user_profiles")
            .insert(profile)
            .execute()
    }
    
    func fetchUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.id else { return nil }
        
        let response: UserProfile = try await client.from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateGoalWeight(_ goalWeight: Double) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await client.from("user_profiles")
            .update(["goal_weight": goalWeight])
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Exercises
    
    func fetchExercises() async throws -> [Exercise] {
        guard let userId = currentUser?.id else { return [] }
        
        // Fetch base exercises
        let baseExercises: [Exercise] = try await client.from("exercises")
            .select()
            .eq("is_base", value: true)
            .execute()
            .value
        
        // Fetch user's custom exercises via junction table
        struct UserExerciseResponse: Codable {
            let exerciseId: UUID
            let exercise: Exercise
            
            enum CodingKeys: String, CodingKey {
                case exerciseId = "exercise_id"
                case exercise = "exercises"
            }
        }
        
        let userExercisesResponse: [UserExerciseResponse] = try await client.from("user_exercises")
            .select("exercise_id, exercises(*)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let userExercises = userExercisesResponse.map { $0.exercise }
        
        // Combine and remove duplicates
        var allExercises = baseExercises
        for exercise in userExercises {
            if !allExercises.contains(where: { $0.id == exercise.id }) {
                allExercises.append(exercise)
            }
        }
        
        return allExercises.sorted { $0.name < $1.name }
    }
    
    func createExercise(name: String, muscleGroup: MuscleGroup, exerciseType: ExerciseType) async throws -> Exercise {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create the exercise
        let exerciseData: [String: Any] = [
            "name": name,
            "muscle_group": muscleGroup.rawValue,
            "exercise_type": exerciseType.rawValue,
            "is_base": false,
            "default_pr_reps": 1,
            "uses_body_weight": false
        ]
        
        let exercise: Exercise = try await client.from("exercises")
            .insert(exerciseData)
            .select()
            .single()
            .execute()
            .value
        
        // Link to user
        let linkData: [String: Any] = [
            "user_id": userId.uuidString,
            "exercise_id": exercise.id.uuidString
        ]
        
        try await client.from("user_exercises")
            .insert(linkData)
            .execute()
        
        return exercise
    }
    
    func updatePinnedNote(exerciseId: UUID, note: String?) async throws {
        try await client.from("exercises")
            .update(["pinned_note": note as Any])
            .eq("id", value: exerciseId.uuidString)
            .execute()
    }
    
    // MARK: - Sets
    
    func fetchSets(for exerciseId: UUID) async throws -> [WorkoutSet] {
        guard let userId = currentUser?.id else { return [] }
        
        let sets: [WorkoutSet] = try await client.from("sets")
            .select()
            .eq("exercise_id", value: exerciseId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        
        return sets
    }
    
    func fetchAllSets() async throws -> [WorkoutSet] {
        guard let userId = currentUser?.id else { return [] }
        
        let sets: [WorkoutSet] = try await client.from("sets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        
        return sets
    }
    
    func logSet(exerciseId: UUID, weight: Double? = nil, reps: Int? = nil, distance: Double? = nil, duration: Int? = nil, notes: String? = nil, date: Date = Date()) async throws {
        guard let userId = currentUser?.id else { return }
        
        let iso8601Date = ISO8601DateFormatter().string(from: date)
        
        var setData: [String: Any] = [
            "exercise_id": exerciseId.uuidString,
            "user_id": userId.uuidString,
            "date": iso8601Date
        ]
        
        if let weight = weight {
            setData["weight"] = weight
        }
        if let reps = reps {
            setData["reps"] = reps
        }
        if let distance = distance {
            setData["distance"] = distance
        }
        if let duration = duration {
            setData["duration"] = duration
        }
        if let notes = notes, !notes.isEmpty {
            setData["notes"] = notes
        }
        
        try await client.from("sets")
            .insert(setData)
            .execute()
    }
    
    func updateSet(_ setId: UUID, weight: Double? = nil, reps: Int? = nil, distance: Double? = nil, duration: Int? = nil, notes: String? = nil) async throws {
        var updateData: [String: Any] = [:]
        
        if let weight = weight {
            updateData["weight"] = weight
        }
        if let reps = reps {
            updateData["reps"] = reps
        }
        if let distance = distance {
            updateData["distance"] = distance
        }
        if let duration = duration {
            updateData["duration"] = duration
        }
        if let notes = notes {
            updateData["notes"] = notes
        }
        
        try await client.from("sets")
            .update(updateData)
            .eq("id", value: setId.uuidString)
            .execute()
    }
    
    func deleteSet(_ setId: UUID) async throws {
        try await client.from("sets")
            .delete()
            .eq("id", value: setId.uuidString)
            .execute()
    }
    
    // MARK: - Body Weight
    
    func fetchBodyWeightLogs() async throws -> [BodyWeightLog] {
        guard let userId = currentUser?.id else { return [] }
        
        let logs: [BodyWeightLog] = try await client.from("body_weight_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        
        return logs
    }
    
    func logBodyWeight(weight: Double, date: Date = Date(), notes: String? = nil) async throws {
        guard let userId = currentUser?.id else { return }
        
        let iso8601Date = ISO8601DateFormatter().string(from: date)
        
        var logData: [String: Any] = [
            "user_id": userId.uuidString,
            "weight": weight,
            "date": iso8601Date
        ]
        
        if let notes = notes, !notes.isEmpty {
            logData["notes"] = notes
        }
        
        // Insert log
        try await client.from("body_weight_logs")
            .insert(logData)
            .execute()
        
        // Update profile
        try await client.from("user_profiles")
            .update(["current_weight": weight, "updated_at": "now()"])
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    func deleteBodyWeightLog(_ logId: UUID) async throws {
        try await client.from("body_weight_logs")
            .delete()
            .eq("id", value: logId.uuidString)
            .execute()
    }
}
