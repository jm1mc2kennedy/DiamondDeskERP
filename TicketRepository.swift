// TicketRepository.swift
// Diamond Desk ERP
// CRUD abstraction and implementation for CloudKit Ticket operations

import Foundation
import CloudKit

protocol TicketRepository {
    func fetchAssigned(to userRef: String) async throws -> [TicketModel]
    func save(_ ticket: TicketModel) async throws
}

class CloudKitTicketRepository: TicketRepository {
    let db = CKContainer.default().publicCloudDatabase

    func fetchAssigned(to userRef: String) async throws -> [TicketModel] {
        let pred = NSPredicate(format: "assignedUserRef == %@", userRef)
        let query = CKQuery(recordType: "Ticket", predicate: pred)
        let (results, _) = try await db.records(matching: query)
        return results.compactMap { TicketModel(record: $0) }
    }

    func save(_ ticket: TicketModel) async throws {
        let record = ticket.toRecord()
        _ = try await db.save(record)
    }
}
