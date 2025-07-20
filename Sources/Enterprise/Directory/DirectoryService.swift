//
//  DirectoryService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

@MainActor
class DirectoryService {
    static let shared = DirectoryService()
    private init() {}

    /// Fetch employees matching criteria
    func fetchEmployees(criteria: DirectorySearchCriteria) async throws -> [Employee] {
        // Use repository to query employees
        let repo = DirectoryRepository()
        return try await repo.queryEmployees(criteria)
    }

    /// Fetch single employee by ID
    func fetchEmployee(by id: UUID) async throws -> Employee? {
        let repo = DirectoryRepository()
        let recordID = CKRecord.ID(recordName: id.uuidString)
        return try await repo.fetchEmployeeRecord(id: recordID)
    }

    /// Save or update an employee profile
    func saveEmployee(_ employee: Employee) async throws {
        let record = employee.toCloudKitRecord()
        try await CKContainer.default().privateCloudDatabase.save(record)
    }
}
