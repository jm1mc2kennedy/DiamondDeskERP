//
//  PerformanceTargetDetailView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct PerformanceTargetDetailView: View {
    let targetId: String
    @StateObject private var viewModel = PerformanceTargetsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Target...")
            } else if let target = viewModel.targets.first(where: { $0.id.uuidString == targetId }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(target.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\(target.metricType.rawValue): \(target.targetValue, specifier: "%.1f") \(target.unit)")
                            .font(.headline)
                        Text(target.description ?? "No description.")
                            .foregroundColor(.secondary)
                        // Additional target metadata
                        HStack {
                            Text("Period:")
                                .fontWeight(.semibold)
                            Text(target.period.rawValue)
                        }
                        HStack {
                            Text("Recurrence:")
                                .fontWeight(.semibold)
                            Text(target.recurrence.rawValue)
                        }
                        if !target.assignedTo.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Assigned To:")
                                    .fontWeight(.semibold)
                                ForEach(target.assignedTo, id: \ .self) { id in
                                    Text(id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("Performance target not found.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Target Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadTargets()
        }
    }
}

#Preview {
    PerformanceTargetDetailView(targetId: UUID().uuidString)
}
