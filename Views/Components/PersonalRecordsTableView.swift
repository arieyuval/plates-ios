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
            
            if prs.isEmpty {
                Text("No personal records yet. Start logging sets!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(prs) { pr in
                        HStack {
                            Text("\(pr.reps)RM")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 50, alignment: .leading)
                            
                            Text("\(Int(pr.weight)) lbs")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(pr.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        
                        if pr.id != prs.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}
