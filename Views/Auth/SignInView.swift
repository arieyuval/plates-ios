//
//  SignInView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark navy background
                Color.backgroundNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo
                    VStack(spacing: 16) {
                        Image("plates-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        
                        Text("The Lifter's Database")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                    
                    // Sign In Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.cardDark)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color.cardDark)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.cardDark)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            signIn()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                        .disabled(isLoading)
                        
                        Button {
                            showingSignUp = true
                        } label: {
                            Text("Don't have an account? **Sign Up**")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await supabase.signIn(email: email, password: password)
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(SupabaseManager.shared)
}
