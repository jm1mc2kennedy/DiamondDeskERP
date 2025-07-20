//
//  ProjectService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

@MainActor
class ProjectService {
    static let shared = ProjectService()
    private init() {}

    /// Fetch all projects from CloudKit
    func fetchProjects() async throws -> [Project] {
        let repo = ProjectRepository()
        return try await repo.fetchAllProjects()
    }

    func fetchProject(by id: UUID) async throws -> Project? {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = try await CKContainer.default().privateCloudDatabase.record(for: recordID)
        return Project.fromCloudKitRecord(record)
    }

    func saveProject(_ project: Project) async throws {
        let record = project.toCloudKitRecord()
        try await CKContainer.default().privateCloudDatabase.save(record)
    }

    func deleteProject(_ project: Project) async throws {
        let recordID = CKRecord.ID(recordName: project.id.uuidString)
        try await CKContainer.default().privateCloudDatabase.deleteRecord(withID: recordID)
    }
}
