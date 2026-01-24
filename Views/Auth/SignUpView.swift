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
                // Dark navy background
                Color.backgroundNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header and Logo at top
                        VStack(spacing: 20) {
                            // Tagline
                            Text("The easiest way to track your lifts and achieve progressive overload")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            // App Name
                            Text("Plates")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.white)
                            
                            // Logo
                            Image("plates-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                            
                            Text("Join the Lifter's Database")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.top, 40)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Account Information")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                TextField("", text: $name, prompt: Text("Name").foregroundStyle(.white.opacity(0.6)))
                                    .textContentType(.name)
                                    .padding()
                                    .background(Color.cardDark)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                                
                                TextField("", text: $email, prompt: Text("Email").foregroundStyle(.white.opacity(0.6)))
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color.cardDark)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                                
                                SecureField("", text: $password, prompt: Text("Password").foregroundStyle(.white.opacity(0.6)))
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.cardDark)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                                
                                SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundStyle(.white.opacity(0.6)))
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.cardDark)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Body Weight (Optional)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                TextField("", text: $initialWeight, prompt: Text("Current Weight (lbs)").foregroundStyle(.white.opacity(0.6)))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.cardDark)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                                
                                TextField("", text: $goalWeight, prompt: Text("Goal Weight (lbs)").foregroundStyle(.white.opacity(0.6)))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.cardDark)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.cardDark)
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
