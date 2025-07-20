import Foundation
import CloudKit

// MARK: - Calendar Event Models

public struct CalendarEvent: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var startDate: Date
    public var endDate: Date
    public var allDay: Bool
    public var location: String?
    public var recurrenceRule: RecurrenceRule?
    public var attendees: [EventAttendee]
    public var reminders: [EventReminder]
    public var createdBy: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isCancelled: Bool
    public var metadata: EventMetadata

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        startDate: Date,
        endDate: Date,
        allDay: Bool = false,
        location: String? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        attendees: [EventAttendee] = [],
        reminders: [EventReminder] = [],
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isCancelled: Bool = false,
        metadata: EventMetadata = EventMetadata()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.allDay = allDay
        self.location = location
        self.recurrenceRule = recurrenceRule
        self.attendees = attendees
        self.reminders = reminders
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCancelled = isCancelled
        self.metadata = metadata
    }
}

public struct RecurrenceRule: Codable, Hashable {
    public var frequency: RecurrenceFrequency
    public var interval: Int
    public var daysOfWeek: [Weekday]?
    public var endDate: Date?
    public var occurrenceCount: Int?

    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Weekday]? = nil,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }
}

public enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
}

public enum Weekday: String, Codable, CaseIterable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

public struct EventAttendee: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var email: String
    public var responseStatus: AttendeeStatus

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        responseStatus: AttendeeStatus = .none
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.responseStatus = responseStatus
    }
}

public enum AttendeeStatus: String, Codable {
    case accepted, declined, tentative, none
}

public struct EventReminder: Identifiable, Codable, Hashable {
    public let id: UUID
    public var offset: TimeInterval // seconds before event start
    public var method: ReminderMethod

    public init(
        id: UUID = UUID(),
        offset: TimeInterval,
        method: ReminderMethod
    ) {
        self.id = id
        self.offset = offset
        self.method = method
    }
}

public enum ReminderMethod: String, Codable {
    case alert
    case email
    case none
}

public struct EventMetadata: Codable, Hashable {
    public var version: Int
    public var tags: [String]
    public var lastReminderSent: Date?
    public var notificationIDs: [String]

    public init(
        version: Int = 1,
        tags: [String] = [],
        lastReminderSent: Date? = nil,
        notificationIDs: [String] = []
    ) {
        self.version = version
        self.tags = tags
        self.lastReminderSent = lastReminderSent
        self.notificationIDs = notificationIDs
    }
}

// MARK: - CloudKit Record Mapping

extension CalendarEvent {
    public init?(record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let start = record["startDate"] as? Date,
            let end = record["endDate"] as? Date,
            let createdBy = record["createdBy"] as? String,
            let createdAt = record.creationDate
        else {
            return nil
        }
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.title = title
        self.notes = record["notes"] as? String
        self.startDate = start
        self.endDate = end
        self.allDay = record["allDay"] as? Bool ?? false
        self.location = record["location"] as? String
        // Recurrence, attendees, reminders mapping omitted for brevity
        self.attendees = []
        self.reminders = []
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = record.modificationDate ?? createdAt
        self.isCancelled = record["isCancelled"] as? Bool ?? false
        self.metadata = EventMetadata()
    }

    public var record: CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "CalendarEvent", recordID: recordID)
        record["title"] = title as CKRecordValue
        record["notes"] = notes as CKRecordValue?
        record["startDate"] = startDate as CKRecordValue
        record["endDate"] = endDate as CKRecordValue
        record["allDay"] = allDay as CKRecordValue
        record["location"] = location as CKRecordValue?
        record["createdBy"] = createdBy as CKRecordValue
        record["isCancelled"] = isCancelled as CKRecordValue
        // Recurrence, attendees, reminders mapping omitted for brevity
        return record
    }
}
