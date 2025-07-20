//
//  DirectoryRepository.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

class DirectoryRepository {
    private let database = CKContainer.default().privateCloudDatabase

    /// Perform advanced queries for directory
    func queryEmployees(_ criteria: DirectorySearchCriteria) async throws -> [Employee] {
        // For now, fetch all employees; criteria filtering to be added
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Employee", predicate: predicate)
        // Execute query and collect results
        let matchResults = try await database.records(matching: query)
        var employees: [Employee] = []
        for (_, result) in matchResults.matchResults {
            switch result {
            case .success(let record):
                if let employee = Employee.fromCloudKitRecord(record) {
                    employees.append(employee)
                }
            case .failure(let error):
                print("DirectoryRepository: error fetching employee record: \(error)")
            }
        }
        return employees
    }

    /// Fetch employee by record ID
    func fetchEmployeeRecord(id: CKRecord.ID) async throws -> Employee? {
        let record = try await database.record(for: id)
        return Employee.fromCloudKitRecord(record)
    }

    /// Save or update record
    func saveEmployeeRecord(_ employee: Employee) async throws {
        let record = employee.toCloudKitRecord()
        try await database.save(record)
    }

    /// Delete employee record
    func deleteEmployeeRecord(id: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: id)
    }
}
