//
//  SupabaseManager.swift
//  Plates
//
//  Created on 1/23/26.
//

import Foundation
import Supabase
import Combine

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // MARK: - Configuration
        // Credentials are stored in Config.swift
        guard let supabaseURL = URL(string: Config.supabaseURL) else {
            fatalError("Invalid Supabase URL in Config.swift")
        }
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: Config.supabaseAnonKey
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
            metadata["initial_weight"] = .double(initialWeight)
        }
        
        if let goalWeight = goalWeight {
            metadata["goal_weight"] = .double(goalWeight)
        }
        
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        
        self.currentUser = response.user
        self.isAuthenticated = true
        
        // Create user profile
        let userId = response.user.id
        try await createUserProfile(userId: userId, initialWeight: initialWeight, goalWeight: goalWeight)
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
        // Create a properly typed struct for the insert
        struct UserProfileInsert: Encodable {
            let user_id: String
            let current_weight: Double?
            let goal_weight: Double?
        }
        
        let profile = UserProfileInsert(
            user_id: userId.uuidString,
            current_weight: initialWeight,
            goal_weight: goalWeight
        )
        
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
        
        struct GoalWeightUpdate: Encodable {
            let goal_weight: Double
        }
        
        try await client.from("user_profiles")
            .update(GoalWeightUpdate(goal_weight: goalWeight))
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
        
        // Create a properly typed struct for the exercise insert
        struct ExerciseInsert: Encodable {
            let name: String
            let muscle_group: String
            let exercise_type: String
            let is_base: Bool
            let default_pr_reps: Int
            let uses_body_weight: Bool
        }
        
        let exerciseData = ExerciseInsert(
            name: name,
            muscle_group: muscleGroup.rawValue,
            exercise_type: exerciseType.rawValue,
            is_base: false,
            default_pr_reps: 1,
            uses_body_weight: false
        )
        
        let exercise: Exercise = try await client.from("exercises")
            .insert(exerciseData)
            .select()
            .single()
            .execute()
            .value
        
        // Link to user
        struct UserExerciseLink: Encodable {
            let user_id: String
            let exercise_id: String
        }
        
        let linkData = UserExerciseLink(
            user_id: userId.uuidString,
            exercise_id: exercise.id.uuidString
        )
        
        try await client.from("user_exercises")
            .insert(linkData)
            .execute()
        
        return exercise
    }
    
    /// Fetch all exercises for autocomplete
    func fetchAllExercises() async throws -> [Exercise] {
        let exercises: [Exercise] = try await client.from("exercises")
            .select()
            .execute()
            .value
        
        return exercises
    }
    
    /// Add exercise (create new or link existing) with full configuration
    func addExercise(
        name: String,
        muscleGroup: MuscleGroup,
        exerciseType: ExerciseType,
        defaultPRReps: Int,
        usesBodyWeight: Bool
    ) async throws -> Exercise {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Step 1: Check if exercise with same name and muscle group exists
        let existingExercises: [Exercise] = try await client.from("exercises")
            .select()
            .eq("name", value: name)
            .eq("muscle_group", value: muscleGroup.rawValue)
            .execute()
            .value
        
        let exercise: Exercise
        
        if let existing = existingExercises.first {
            // Exercise exists, use it
            exercise = existing
        } else {
            // Create new exercise
            struct ExerciseInsert: Encodable {
                let name: String
                let muscle_group: String
                let exercise_type: String
                let is_base: Bool
                let default_pr_reps: Int
                let uses_body_weight: Bool
            }
            
            let exerciseData = ExerciseInsert(
                name: name,
                muscle_group: muscleGroup.rawValue,
                exercise_type: exerciseType.rawValue,
                is_base: false,
                default_pr_reps: defaultPRReps,
                uses_body_weight: usesBodyWeight
            )
            
            exercise = try await client.from("exercises")
                .insert(exerciseData)
                .select()
                .single()
                .execute()
                .value
        }
        
        // Step 2: Link to user (upsert to avoid duplicates)
        struct UserExerciseLink: Encodable {
            let user_id: String
            let exercise_id: String
        }
        
        let linkData = UserExerciseLink(
            user_id: userId.uuidString,
            exercise_id: exercise.id.uuidString
        )
        
        try await client.from("user_exercises")
            .upsert(linkData)
            .execute()
        
        return exercise
    }

    
    func updatePinnedNote(exerciseId: UUID, note: String?) async throws {
        struct PinnedNoteUpdate: Encodable {
            let pinned_note: String?
        }
        
        try await client.from("exercises")
            .update(PinnedNoteUpdate(pinned_note: note))
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
        
        // Create a properly typed struct for the set insert
        struct SetInsert: Encodable {
            let exercise_id: String
            let user_id: String
            let date: String
            let weight: Double?
            let reps: Int?
            let distance: Double?
            let duration: Int?
            let notes: String?
        }
        
        let setData = SetInsert(
            exercise_id: exerciseId.uuidString,
            user_id: userId.uuidString,
            date: iso8601Date,
            weight: weight,
            reps: reps,
            distance: distance,
            duration: duration,
            notes: notes?.isEmpty == false ? notes : nil
        )
        
        try await client.from("sets")
            .insert(setData)
            .execute()
    }
    
    func updateSet(_ setId: UUID, weight: Double? = nil, reps: Int? = nil, distance: Double? = nil, duration: Int? = nil, notes: String? = nil) async throws {
        // Create a properly typed struct for the set update
        struct SetUpdate: Encodable {
            let weight: Double?
            let reps: Int?
            let distance: Double?
            let duration: Int?
            let notes: String?
        }
        
        let updateData = SetUpdate(
            weight: weight,
            reps: reps,
            distance: distance,
            duration: duration,
            notes: notes
        )
        
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
        
        // Create a properly typed struct for the body weight log insert
        struct BodyWeightLogInsert: Encodable {
            let user_id: String
            let weight: Double
            let date: String
            let notes: String?
        }
        
        let logData = BodyWeightLogInsert(
            user_id: userId.uuidString,
            weight: weight,
            date: iso8601Date,
            notes: notes?.isEmpty == false ? notes : nil
        )
        
        // Insert log
        try await client.from("body_weight_logs")
            .insert(logData)
            .execute()
        
        // Update profile
        struct ProfileWeightUpdate: Encodable {
            let current_weight: Double
            let updated_at: String
        }
        
        try await client.from("user_profiles")
            .update(ProfileWeightUpdate(current_weight: weight, updated_at: "now()"))
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
