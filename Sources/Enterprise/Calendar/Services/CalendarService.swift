import Foundation
import CloudKit

public protocol CalendarServiceProtocol {
    func fetchEvents(start: Date?, end: Date?) async throws -> [CalendarEvent]
    func createEvent(_ event: CalendarEvent) async throws -> CalendarEvent
    func updateEvent(_ event: CalendarEvent) async throws -> CalendarEvent
    func deleteEvent(_ eventID: UUID) async throws
    func fetchEventChanges(since date: Date) async throws -> [CalendarEvent]
}

public final class CalendarService: CalendarServiceProtocol {
    private let privateDB: CKDatabase

    public init(container: CKContainer = .default()) {
        self.privateDB = container.privateCloudDatabase
    }

    public func fetchEvents(start: Date? = nil, end: Date? = nil) async throws -> [CalendarEvent] {
        var predicate: NSPredicate
        if let s = start, let e = end {
            predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@", s as CVarArg, e as CVarArg)
        } else {
            predicate = NSPredicate(value: true)
        }
        let query = CKQuery(recordType: "CalendarEvent", predicate: predicate)
        let (results, _) = try await privateDB.records(matching: query)
        return results.compactMap { _, record in
            CalendarEvent(record: record)
        }
    }

    public func createEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        let record = event.record
        let savedRecord = try await privateDB.save(record)
        guard let savedEvent = CalendarEvent(record: savedRecord) else {
            throw CalendarServiceError.parsingError
        }
        return savedEvent
    }

    public func updateEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        let record = event.record
        let savedRecord = try await privateDB.modifyRecords(saving: [record], deleting: []).first
            ?? record
        guard let updatedEvent = CalendarEvent(record: savedRecord) else {
            throw CalendarServiceError.parsingError
        }
        return updatedEvent
    }

    public func deleteEvent(_ eventID: UUID) async throws {
        let recordID = CKRecord.ID(recordName: eventID.uuidString)
        _ = try await privateDB.deleteRecord(withID: recordID)
    }

    public func fetchEventChanges(since date: Date) async throws -> [CalendarEvent] {
        let predicate = NSPredicate(format: "modificationDate >= %@", date as CVarArg)
        let query = CKQuery(recordType: "CalendarEvent", predicate: predicate)
        let (results, _) = try await privateDB.records(matching: query)
        return results.compactMap { _, record in
            CalendarEvent(record: record)
        }
    }
}

public enum CalendarServiceError: Error {
    case parsingError
}
