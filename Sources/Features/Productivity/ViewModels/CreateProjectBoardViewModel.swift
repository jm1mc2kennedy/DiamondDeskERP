//
//  CreateProjectBoardViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import Combine
import CloudKit

@MainActor
class CreateProjectBoardViewModel: ObservableObject {
    @Published var availableMembers: [TeamMember] = []
    @Published var availableTemplates: [ProjectTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productivityService: ProductivityService
    private var cancellables = Set<AnyCancellable>()
    
    init(productivityService: ProductivityService = ProductivityService.shared) {
        self.productivityService = productivityService
    }
    
    func createProjectBoard(_ board: ProjectBoard, fromTemplate templateId: String? = nil) async throws {
        try await productivityService.createProjectBoard(board, fromTemplate: templateId)
    }
    
    func loadAvailableMembers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In a real implementation, this would fetch from your user/team service
            availableMembers = try await fetchTeamMembers()
        } catch {
            errorMessage = "Failed to load team members: \(error.localizedDescription)"
        }
    }
    
    func loadAvailableTemplates() async {
        do {
            availableTemplates = try await fetchProjectTemplates()
        } catch {
            errorMessage = "Failed to load templates: \(error.localizedDescription)"
        }
    }
    
    private func fetchTeamMembers() async throws -> [TeamMember] {
        // Mock implementation - replace with actual service call
        return [
            TeamMember(id: "user1", name: "John Doe", email: "john@company.com", role: .editor),
            TeamMember(id: "user2", name: "Jane Smith", email: "jane@company.com", role: .viewer),
            TeamMember(id: "user3", name: "Mike Johnson", email: "mike@company.com", role: .editor)
        ]
    }
    
    private func fetchProjectTemplates() async throws -> [ProjectTemplate] {
        // Mock implementation - replace with actual service call
        return [
            ProjectTemplate(id: "template1", name: "Software Development", description: "Standard sprint-based development"),
            ProjectTemplate(id: "template2", name: "Marketing Campaign", description: "Campaign planning and execution"),
            ProjectTemplate(id: "template3", name: "Product Launch", description: "Complete product launch workflow")
        ]
    }
}

// MARK: - Supporting Models

struct TeamMember: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let role: ProjectMemberRole
    let avatarUrl: String?
    
    init(id: String, name: String, email: String, role: ProjectMemberRole, avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.avatarUrl = avatarUrl
    }
}

struct ProjectTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let estimatedDuration: TimeInterval
    let taskCount: Int
    let previewImageUrl: String?
    
    init(id: String, name: String, description: String, category: String = "General", estimatedDuration: TimeInterval = 0, taskCount: Int = 0, previewImageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.taskCount = taskCount
        self.previewImageUrl = previewImageUrl
    }
}
