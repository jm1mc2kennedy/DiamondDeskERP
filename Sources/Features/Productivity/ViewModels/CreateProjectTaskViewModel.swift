//
//  CreateProjectTaskViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import Combine
import CloudKit

@MainActor
class CreateProjectTaskViewModel: ObservableObject {
    @Published var availableAssignees: [TeamMember] = []
    @Published var availableTasks: [ProjectTask] = []
    @Published var availableTags: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productivityService: ProductivityService
    private let projectTaskService: ProjectTaskService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        productivityService: ProductivityService = ProductivityService.shared,
        projectTaskService: ProjectTaskService = ProjectTaskService.shared
    ) {
        self.productivityService = productivityService
        self.projectTaskService = projectTaskService
    }
    
    func createProjectTask(_ task: ProjectTask) async throws {
        try await projectTaskService.createTask(task)
    }
    
    func loadAvailableData(for projectBoardId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        async let assignees = loadAvailableAssignees(for: projectBoardId)
        async let tasks = loadAvailableTasks(for: projectBoardId)
        async let tags = loadAvailableTags(for: projectBoardId)
        
        do {
            let (loadedAssignees, loadedTasks, loadedTags) = try await (assignees, tasks, tags)
            self.availableAssignees = loadedAssignees
            self.availableTasks = loadedTasks
            self.availableTags = loadedTags
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }
    
    private func loadAvailableAssignees(for projectBoardId: String) async throws -> [TeamMember] {
        // In real implementation, fetch board members
        return [
            TeamMember(id: "user1", name: "John Doe", email: "john@company.com", role: .editor),
            TeamMember(id: "user2", name: "Jane Smith", email: "jane@company.com", role: .viewer),
            TeamMember(id: "user3", name: "Mike Johnson", email: "mike@company.com", role: .editor)
        ]
    }
    
    private func loadAvailableTasks(for projectBoardId: String) async throws -> [ProjectTask] {
        // Fetch existing tasks for dependency selection
        return try await projectTaskService.getTasksForBoard(projectBoardId)
    }
    
    private func loadAvailableTags(for projectBoardId: String) async throws -> [String] {
        // In real implementation, fetch commonly used tags
        return ["Frontend", "Backend", "Design", "Testing", "Documentation", "Bug", "Feature", "Urgent"]
    }
}
