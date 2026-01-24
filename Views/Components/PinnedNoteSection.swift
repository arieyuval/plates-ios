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
                    .foregroundStyle(.secondary)
                Text("Pinned Note")
                    .font(.headline)
                Spacer()
                
                if isEditing {
                    Button("Save") {
                        isEditing = false
                        isFocused = false
                        onSave()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                } else {
                    Button {
                        isEditing = true
                        isFocused = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            
            if isEditing {
                TextEditor(text: $note)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
            } else if !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text("Tap to add a note...")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
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
