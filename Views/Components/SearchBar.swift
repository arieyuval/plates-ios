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
                .foregroundStyle(.white.opacity(0.5))
            
            TextField("", text: $text, prompt: Text("Search exercises...").foregroundStyle(.white.opacity(0.6)))
                .textFieldStyle(.plain)
                .foregroundStyle(.white.opacity(0.9))
                .tint(.blue)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.cardDark)
        .cornerRadius(10)
    }
}
