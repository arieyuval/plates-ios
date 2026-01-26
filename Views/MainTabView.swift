//
//  MainTabView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        // Configure tab bar appearance to be consistent
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.backgroundNavy)
        
        // Set icon colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        
        // Set title colors
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            BodyWeightView()
                .tabItem {
                    Label("Weight", systemImage: "scale.3d")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(3)
        }
        .tint(.white)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SupabaseManager.shared)
}
