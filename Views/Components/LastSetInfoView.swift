//
//  LastSetInfoView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct LastSetInfoView: View {
    let set: WorkoutSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Set")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.displayText)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(set.date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}
