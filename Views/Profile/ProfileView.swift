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
                                .foregroundStyle(.white)
                            
                            Text("Plates Member")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 8)
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
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundNavy)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.backgroundNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
