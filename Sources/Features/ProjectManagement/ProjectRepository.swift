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

    func fetchAllProjects() async throws -> [Project] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Project", predicate: predicate)
        let (matchResults, _) = try await database.records(matching: query)
        var projects: [Project] = []
        for result in matchResults {
            switch result {
            case .success(_, let record):
                if let project = Project.fromCloudKitRecord(record) {
                    projects.append(project)
                }
            case .failure(let error, _):
                throw error
            }
        }
        return projects
    }
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
