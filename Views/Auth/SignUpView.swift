//
//  SignUpView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var initialWeight = ""
    @State private var goalWeight = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark grey background
                Color.primaryDark
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Large Logo at top
                        VStack(spacing: 16) {
                            Image("plates-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                            
                            Text("Join Plates")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 40)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Account Information")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                TextField("Name", text: $name)
                                    .textContentType(.name)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                                
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                                
                                SecureField("Password", text: $password)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Body Weight (Optional)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                TextField("Current Weight (lbs)", text: $initialWeight)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                                
                                TextField("Goal Weight (lbs)", text: $goalWeight)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                            }
                            
                            Button {
                                signUp()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                            .disabled(isLoading || !isValid)
                            .opacity(isValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && !name.isEmpty && password == confirmPassword
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let initial = Double(initialWeight)
                let goal = Double(goalWeight)
                
                try await supabase.signUp(
                    email: email,
                    password: password,
                    name: name,
                    initialWeight: initial,
                    goalWeight: goal
                )
                
                dismiss()
            } catch {
                errorMessage = "Sign up failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(SupabaseManager.shared)
}
