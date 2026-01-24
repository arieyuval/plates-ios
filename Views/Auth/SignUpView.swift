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
            Form {
                Section("Account Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                Section("Body Weight (Optional)") {
                    TextField("Current Weight (lbs)", text: $initialWeight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Goal Weight (lbs)", text: $goalWeight)
                        .keyboardType(.decimalPad)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        signUp()
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isLoading || !isValid)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
