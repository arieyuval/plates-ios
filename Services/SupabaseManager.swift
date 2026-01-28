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
    
    /// Delete all user data from the database AND delete the auth account
    /// This will permanently delete:
    /// - All workout sets
    /// - All body weight logs
    /// - User-exercise associations
    /// - User profile
    /// - User authentication account (email will be removed from system)
    /// After deletion, the user will NOT be able to sign in with the same email
    /// unless they create a completely new account.
    func deleteAllUserData() async throws {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get the current session token for authorization
        let session: Session
        do {
            session = try await client.auth.session
        } catch {
            print("❌ Failed to get session: \(error)")
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Session expired. Please sign out and sign back in."])
        }
        
        // Call the Edge Function to delete everything including the auth account
        let urlString = "\(Config.supabaseURL)/functions/v1/delete-account"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🗑️ Calling delete-account function...")
        print("📍 URL: \(urlString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Use a custom header to bypass Supabase's automatic JWT verification
        request.setValue(session.accessToken, forHTTPHeaderField: "x-user-token")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response Body: \(responseString)")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Try to parse error message
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorDict["message"] as? String ?? errorDict["error"] as? String {
                print("❌ Delete failed: \(errorMessage)")
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            // If we can't parse the error, show raw response
            if let responseString = String(data: data, encoding: .utf8) {
                throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete account: \(responseString)"])
            }
            
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete account"])
        }
        
        print("✅ Account deleted successfully")
        
        // Clear local session
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
    
    func updateGoalWeight(_ goalWeight: Double?) async throws {
        guard let userId = currentUser?.id else { return }
        
        struct GoalWeightUpdate: Encodable {
            let goal_weight: Double?
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
        
        // Fetch usage counts for sorting
        struct UsageCount: Codable {
            let exerciseId: UUID
            let count: Int
            
            enum CodingKeys: String, CodingKey {
                case exerciseId = "exercise_id"
                case count
            }
        }
        
        // Get usage counts from sets table
        let usageCounts: [UsageCount]
        do {
            usageCounts = try await client.from("sets")
                .select("exercise_id, count:exercise_id.count()")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
        } catch {
            print("⚠️ Failed to fetch usage counts: \(error)")
            usageCounts = []
        }
        
        // Create usage dictionary
        let usageDict = Dictionary(uniqueKeysWithValues: usageCounts.map { ($0.exerciseId, $0.count) })
        
        // Sort by usage (most used first), then by name
        return allExercises.sorted { exercise1, exercise2 in
            let usage1 = usageDict[exercise1.id] ?? 0
            let usage2 = usageDict[exercise2.id] ?? 0
            
            if usage1 != usage2 {
                return usage1 > usage2
            }
            return exercise1.name < exercise2.name
        }
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
        
        print("🔍 Adding exercise for user: \(userId.uuidString)")
        
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
            print("✓ Exercise already exists: \(existing.name) (\(existing.id))")
            exercise = existing
        } else {
            // Create new exercise
            print("→ Creating new exercise: \(name)")
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
            
            print("✓ Exercise created: \(exercise.name) (\(exercise.id))")
        }
        
        // Step 2: Link to user (upsert to avoid duplicates)
        print("→ Linking exercise to user...")
        print("   user_id: \(userId.uuidString)")
        print("   exercise_id: \(exercise.id.uuidString)")
        
        struct UserExerciseLink: Encodable {
            let user_id: String
            let exercise_id: String
        }
        
        let linkData = UserExerciseLink(
            user_id: userId.uuidString,
            exercise_id: exercise.id.uuidString
        )
        
        do {
            try await client.from("user_exercises")
                .upsert(linkData)
                .execute()
            print("✓ Exercise linked to user successfully")
        } catch {
            print("❌ Failed to link exercise to user: \(error)")
            print("   This usually means the user_id doesn't exist in auth.users table")
            print("   Current user: \(String(describing: currentUser))")
            throw error
        }
        
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
    
    func updateGoalWeight(exerciseId: UUID, goalWeight: Double?) async throws {
        struct GoalWeightUpdate: Encodable {
            let goal_weight: Double?
        }
        
        try await client.from("exercises")
            .update(GoalWeightUpdate(goal_weight: goalWeight))
            .eq("id", value: exerciseId.uuidString)
            .execute()
    }
    
    func updateGoalReps(exerciseId: UUID, goalReps: Int?) async throws {
        struct GoalRepsUpdate: Encodable {
            let goal_reps: Int?
        }
        
        try await client.from("exercises")
            .update(GoalRepsUpdate(goal_reps: goalReps))
            .eq("id", value: exerciseId.uuidString)
            .execute()
    }
    
    func updateUserPRReps(exerciseId: UUID, userPRReps: Int?) async throws {
        guard let userId = currentUser?.id else { return }
        
        // Note: This function is currently disabled because user_pr_reps column
        // doesn't exist in the user_exercises table. If you want per-user PR reps
        // customization, you'll need to add this column to your database.
        print("⚠️ updateUserPRReps called but user_pr_reps column doesn't exist in database")
        
        // TODO: When you add the user_pr_reps column to user_exercises table, uncomment this:
        /*
        struct UserPRRepsUpdate: Encodable {
            let user_id: String
            let exercise_id: String
            let user_pr_reps: Int?
        }
        
        let updateData = UserPRRepsUpdate(
            user_id: userId.uuidString,
            exercise_id: exerciseId.uuidString,
            user_pr_reps: userPRReps
        )
        
        // Upsert to user_exercises table
        try await client.from("user_exercises")
            .upsert(updateData)
            .execute()
        */
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
    
    func updateBodyWeightLog(_ logId: UUID, weight: Double, date: Date, notes: String?) async throws {
        let iso8601Date = ISO8601DateFormatter().string(from: date)
        
        struct BodyWeightLogUpdate: Encodable {
            let weight: Double
            let date: String
            let notes: String?
        }
        
        let updateData = BodyWeightLogUpdate(
            weight: weight,
            date: iso8601Date,
            notes: notes?.isEmpty == false ? notes : nil
        )
        
        try await client.from("body_weight_logs")
            .update(updateData)
            .eq("id", value: logId.uuidString)
            .execute()
    }
}
