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
                        // TODO: Additional target metadata
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
