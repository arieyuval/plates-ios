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
                                
                                Text("Plates Member")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("App") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
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
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
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
}

#Preview {
    ProfileView()
        .environmentObject(SupabaseManager.shared)
}
