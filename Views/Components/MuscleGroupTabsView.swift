//
//  MuscleGroupTabsView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct MuscleGroupTabsView: View {
    @Binding var selectedGroup: MuscleGroup
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    MuscleGroupTab(
                        group: group,
                        isSelected: selectedGroup == group,
                        colorScheme: colorScheme
                    ) {
                        withAnimation {
                            selectedGroup = group
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MuscleGroupTab: View {
    let group: MuscleGroup
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(group.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? group.color(for: colorScheme)
                        : Color(.systemGray6)
                )
                .foregroundStyle(
                    isSelected
                        ? .white
                        : .primary
                )
                .cornerRadius(20)
        }
    }
}
