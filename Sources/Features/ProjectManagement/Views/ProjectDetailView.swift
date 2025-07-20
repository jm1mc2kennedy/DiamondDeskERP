//
//  ProjectDetailView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct ProjectDetailView: View {
    let projectId: String
    @StateObject private var viewModel = ProjectListViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Project...")
            } else if let project = viewModel.projects.first(where: { $0.id.uuidString == projectId }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(project.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(project.status.rawValue)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(project.description ?? "No description provided.")
                            .foregroundColor(.secondary)
                        // TODO: Additional project details, tasks, milestones
                    }
                    .padding()
                }
            } else {
                Text("Project not found.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Project Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProjects()
        }
    }
}

#Preview {
    ProjectDetailView(projectId: UUID().uuidString)
}
