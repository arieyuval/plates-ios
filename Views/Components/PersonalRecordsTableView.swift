//
//  PersonalRecordsTableView.swift
//  Plates
//
//  Created on 1/23/26.
//

import SwiftUI

struct PersonalRecordsTableView: View {
    let prs: [PersonalRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Personal Records")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            if prs.isEmpty {
                Text("No personal records yet. Start logging sets!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardDark)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(prs) { pr in
                        HStack {
                            Text("\(pr.reps)RM")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.95))
                                .frame(width: 50, alignment: .leading)
                            
                            Text("\(Int(pr.weight)) lbs")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.95))
                            
                            Spacer()
                            
                            Text(pr.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        
                        if pr.id != prs.last?.id {
                            Divider()
                                .background(.white.opacity(0.1))
                        }
                    }
                }
                .background(Color.cardDark)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}
