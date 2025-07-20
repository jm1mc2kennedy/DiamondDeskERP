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
                        // Additional project details
                        VStack(alignment: .leading, spacing: 8) {
                            if let manager = project.managerId {
                                HStack {
                                    Text("Manager:")
                                        .fontWeight(.semibold)
                                    Text(manager)
                                }
                            }
                            if !project.stakeholderIds.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Stakeholders:")
                                        .fontWeight(.semibold)
                                    ForEach(project.stakeholderIds, id: \.self) { id in
                                        Text(id)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            if !project.tasks.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Tasks:")
                                        .fontWeight(.semibold)
                                    ForEach(project.tasks, id: \.self) { taskId in
                                        Text(taskId)
                                            .font(.caption)
                                    }
                                }
                            }
                            if !project.milestoneIds.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Milestones:")
                                        .fontWeight(.semibold)
                                    ForEach(project.milestoneIds, id: \.self) { mid in
                                        Text(mid)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
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
