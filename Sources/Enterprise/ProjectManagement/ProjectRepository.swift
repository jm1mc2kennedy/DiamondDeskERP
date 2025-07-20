//
//  ProjectRepository.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

class ProjectRepository {
    private let database = CKContainer.default().privateCloudDatabase

    func fetchAllProjects() async throws -> [Project] {
        // TODO: Build CKQuery to fetch all Project records
        return []
    }

    func fetchProjectRecord(id: CKRecord.ID) async throws -> Project? {
        let record = try await database.record(for: id)
        return Project.fromCloudKitRecord(record)
    }

    func saveProjectRecord(_ project: Project) async throws {
        let record = project.toCloudKitRecord()
        try await database.save(record)
    }

    func deleteProjectRecord(id: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: id)
    }
}
