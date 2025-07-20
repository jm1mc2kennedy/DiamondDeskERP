//
//  ProjectListView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct ProjectListView: View {
    @StateObject var viewModel: ProjectListViewModel

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Projects...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else if viewModel.projects.isEmpty {
                    Text("No projects found.")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.projects) { project in
                        Button(action: {
                            NavigationRouter.shared.selectedProject = project
                            NavigationRouter.shared.dashboardPath.append(.projectDetail(project.id.uuidString))
                        }) {
                            VStack(alignment: .leading) {
                                Text(project.name)
                                    .font(.headline)
                                Text(project.status.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                Button(action: {
                    NavigationRouter.shared.dashboardPath.append(.projectCreation)
                }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .task {
                await viewModel.loadProjects()
            }
        }
    }
}

#Preview {
    ProjectListView(viewModel: ProjectListViewModel())
}
