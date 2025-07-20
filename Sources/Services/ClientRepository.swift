// ClientRepository.swift
// Diamond Desk ERP
// CRUD abstraction and implementation for CloudKit Client operations

import Foundation
import CloudKit

protocol ClientRepository {
    func fetchAssigned(to userRef: String) async throws -> [ClientModel]
    func save(_ client: ClientModel) async throws
}

class CloudKitClientRepository: ClientRepository {
    let db = CKContainer.default().publicCloudDatabase

    func fetchAssigned(to userRef: String) async throws -> [ClientModel] {
        let pred = NSPredicate(format: "assignedUserRef == %@", userRef)
        let query = CKQuery(recordType: "Client", predicate: pred)
        let (results, _) = try await db.records(matching: query)
        return results.compactMap { ClientModel(record: $0) }
    }

    func save(_ client: ClientModel) async throws {
        let record = client.toRecord()
        _ = try await db.save(record)
    }
}
