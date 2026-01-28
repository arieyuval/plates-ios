//
//  ProfileView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI
import Auth

struct ProfileView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var showingSignOutAlert = false
    @State private var isSigningOut = false
    @State private var showBugReport = false
    @State private var showDeleteAccountSheet = false
    @State private var deleteConfirmationText = ""
    @State private var isDeletingAccount = false
    @State private var showDeleteError = false
    @State private var deleteError: String = ""
    
    var isDeleteEnabled: Bool {
        deleteConfirmationText == "DELETE"
    }
    
    var body: some View {
        NavigationStack {
            List {
            Section {
                if let user = supabase.currentUser {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.email ?? "User")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text("Plates Member")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: { showBugReport = true }) {
                        Label("Report a Bug", systemImage: "ladybug")
                            .foregroundStyle(.white)
                    }
                }
            }
            .listRowBackground(Color.cardDark)
            
            Section("App") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Link(destination: URL(string: "https://www.freeprivacypolicy.com/live/e6964847-38bb-483c-8865-6c6685ac96b4")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .foregroundStyle(.white)
                }
            }
            .listRowBackground(Color.cardDark)
            
            Section {
                Button(role: .destructive) {
                    showingSignOutAlert = true
                } label: {
                    if isSigningOut {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
                .disabled(isSigningOut)
            }
            .listRowBackground(Color.cardDark)
            
            Section {
                Button(role: .destructive) {
                    showDeleteAccountSheet = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("This will permanently delete your account, email, and all data. You will NOT be able to sign in again with this email. This action cannot be undone.")
            }
            .listRowBackground(Color.cardDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundNavy)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError)
            }
            .sheet(isPresented: $showBugReport) {
                BugReportView()
            }
            .sheet(isPresented: $showDeleteAccountSheet) {
                DeleteAccountConfirmationView(
                    confirmationText: $deleteConfirmationText,
                    isDeleting: $isDeletingAccount,
                    isDeleteEnabled: isDeleteEnabled,
                    onDelete: deleteAccount,
                    onCancel: {
                        showDeleteAccountSheet = false
                        deleteConfirmationText = ""
                    }
                )
            }
        }
    }
    
    private func signOut() {
        isSigningOut = true
        
        Task {
            do {
                try await supabase.signOut()
            } catch {
                print("Error signing out: \(error)")
            }
            isSigningOut = false
        }
    }
    
    private func deleteAccount() {
        isDeletingAccount = true
        
        Task {
            do {
                try await supabase.deleteAllUserData()
                // User is automatically signed out after deletion
                await MainActor.run {
                    showDeleteAccountSheet = false
                    deleteConfirmationText = ""
                }
            } catch {
                print("Error deleting account: \(error)")
                await MainActor.run {
                    deleteError = error.localizedDescription
                    showDeleteError = true
                    showDeleteAccountSheet = false
                }
            }
            await MainActor.run {
                isDeletingAccount = false
            }
        }
    }
}

// MARK: - Delete Account Confirmation View

struct DeleteAccountConfirmationView: View {
    @Binding var confirmationText: String
    @Binding var isDeleting: Bool
    let isDeleteEnabled: Bool
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Warning Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                        .padding(.top, 40)
                    
                    // Warning Text
                    VStack(spacing: 12) {
                        Text("Delete Account")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("This will permanently delete:")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Your account and email", systemImage: "person.crop.circle.badge.xmark")
                            Label("All workout sets and exercise history", systemImage: "figure.strengthtraining.traditional")
                            Label("All body weight logs", systemImage: "scalemass")
                            Label("Your custom exercises", systemImage: "dumbbell")
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.subheadline)
                        .padding()
                        .background(Color.cardDark)
                        .cornerRadius(12)
                        
                        Text("⚠️ You will NOT be able to sign in again with this email address.")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Confirmation Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type DELETE to confirm")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        TextField("DELETE", text: $confirmationText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            if isDeleting {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Deleting...")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.5))
                                .cornerRadius(12)
                            } else {
                                Text("Delete Everything")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isDeleteEnabled ? Color.red : Color.red.opacity(0.3))
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(!isDeleteEnabled || isDeleting)
                        
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cardDark)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isDeleting)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ProfileView()
        .environmentObject(SupabaseManager.shared)
}
