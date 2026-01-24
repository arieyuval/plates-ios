//
//  SearchBar.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(.blue)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(10)
        .background(Color.cardDark)
        .cornerRadius(10)
    }
}
