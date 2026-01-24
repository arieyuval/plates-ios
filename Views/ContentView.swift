//
//  ContentView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var supabase: SupabaseManager
    
    var body: some View {
        Group {
            if supabase.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SupabaseManager.shared)
}
