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
                .foregroundStyle(.white.opacity(0.95))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.displayText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.95))
                    
                    Text(set.date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.cardDark)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}
