//
//  PinnedNoteSection.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct PinnedNoteSection: View {
    @Binding var note: String
    let onSave: () -> Void
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.white.opacity(0.7))
                Text("Pinned Note")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                Spacer()
                
                if isEditing {
                    Button("Save") {
                        isEditing = false
                        isFocused = false
                        onSave()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                } else {
                    Button {
                        isEditing = true
                        isFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            
            if isEditing {
                TextEditor(text: $note)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.cardDark)
                    .foregroundStyle(.white.opacity(0.9))
                    .cornerRadius(8)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
            } else if !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardDark)
                    .cornerRadius(8)
            } else {
                Text("Tap to add a note...")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.4))
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardDark)
                    .cornerRadius(8)
                    .onTapGesture {
                        isEditing = true
                        isFocused = true
                    }
            }
        }
        .padding(.horizontal)
    }
}
