import Foundation
import CloudKit

// MARK: - Calendar Event Models
public struct CalendarEvent: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var description: String?
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var location: String?
    public var attendees: [String]
    public var organizerId: String
    public var calendarId: String
    public var eventType: EventType
    public var recurrenceRule: RecurrenceRule?
    public var reminders: [EventReminder]
    public var visibility: EventVisibility
    public var status: EventStatus
    public var priority: EventPriority
    public var tags: [String]
    public var attachments: [String]
    public var externalEventId: String?
    public var source: EventSource
    public var lastModified: Date
    public var createdAt: Date
    public var createdBy: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        location: String? = nil,
        attendees: [String] = [],
        organizerId: String,
        calendarId: String,
        eventType: EventType = .meeting,
        recurrenceRule: RecurrenceRule? = nil,
        reminders: [EventReminder] = [],
        visibility: EventVisibility = .private,
        status: EventStatus = .confirmed,
        priority: EventPriority = .normal,
        tags: [String] = [],
        attachments: [String] = [],
        externalEventId: String? = nil,
        source: EventSource = .manual,
        lastModified: Date = Date(),
        createdAt: Date = Date(),
        createdBy: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.attendees = attendees
        self.organizerId = organizerId
        self.calendarId = calendarId
        self.eventType = eventType
        self.recurrenceRule = recurrenceRule
        self.reminders = reminders
        self.visibility = visibility
        self.status = status
        self.priority = priority
        self.tags = tags
        self.attachments = attachments
        self.externalEventId = externalEventId
        self.source = source
        self.lastModified = lastModified
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
}

// MARK: - Calendar Event Enums
public enum EventType: String, CaseIterable, Codable, Identifiable {
    case meeting = "MEETING"
    case appointment = "APPOINTMENT"
    case reminder = "REMINDER"
    case deadline = "DEADLINE"
    case milestone = "MILESTONE"
    case conference = "CONFERENCE"
    case interview = "INTERVIEW"
    case training = "TRAINING"
    case personal = "PERSONAL"
    case holiday = "HOLIDAY"
    case maintenance = "MAINTENANCE"
    case other = "OTHER"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .meeting: return "Meeting"
        case .appointment: return "Appointment"
        case .reminder: return "Reminder"
        case .deadline: return "Deadline"
        case .milestone: return "Milestone"
        case .conference: return "Conference"
        case .interview: return "Interview"
        case .training: return "Training"
        case .personal: return "Personal"
        case .holiday: return "Holiday"
        case .maintenance: return "Maintenance"
        case .other: return "Other"
        }
    }
}

public enum EventVisibility: String, CaseIterable, Codable, Identifiable {
    case `private` = "PRIVATE"
    case `public` = "PUBLIC"
    case confidential = "CONFIDENTIAL"
    case internal = "INTERNAL"
    
    public var id: String { rawValue }
}

public enum EventStatus: String, CaseIterable, Codable, Identifiable {
    case confirmed = "CONFIRMED"
    case tentative = "TENTATIVE"
    case cancelled = "CANCELLED"
    case postponed = "POSTPONED"
    case completed = "COMPLETED"
    
    public var id: String { rawValue }
}

public enum EventPriority: String, CaseIterable, Codable, Identifiable {
    case low = "LOW"
    case normal = "NORMAL"
    case high = "HIGH"
    case urgent = "URGENT"
    
    public var id: String { rawValue }
}

public enum EventSource: String, CaseIterable, Codable, Identifiable {
    case manual = "MANUAL"
    case outlook = "OUTLOOK"
    case google = "GOOGLE"
    case apple = "APPLE"
    case exchange = "EXCHANGE"
    case caldav = "CALDAV"
    case imported = "IMPORTED"
    
    public var id: String { rawValue }
}

// MARK: - Supporting Structures
public struct RecurrenceRule: Codable, Hashable {
    public var frequency: RecurrenceFrequency
    public var interval: Int
    public var count: Int?
    public var until: Date?
    public var byWeekDay: [WeekDay]
    public var byMonthDay: [Int]
    public var byMonth: [Int]
    public var byYearDay: [Int]
    
    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        count: Int? = nil,
        until: Date? = nil,
        byWeekDay: [WeekDay] = [],
        byMonthDay: [Int] = [],
        byMonth: [Int] = [],
        byYearDay: [Int] = []
    ) {
        self.frequency = frequency
        self.interval = interval
        self.count = count
        self.until = until
        self.byWeekDay = byWeekDay
        self.byMonthDay = byMonthDay
        self.byMonth = byMonth
        self.byYearDay = byYearDay
    }
}

public enum RecurrenceFrequency: String, CaseIterable, Codable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

public enum WeekDay: String, CaseIterable, Codable {
    case sunday = "SUNDAY"
    case monday = "MONDAY"
    case tuesday = "TUESDAY"
    case wednesday = "WEDNESDAY"
    case thursday = "THURSDAY"
    case friday = "FRIDAY"
    case saturday = "SATURDAY"
}

public struct EventReminder: Identifiable, Codable, Hashable {
    public let id: String
    public var minutesBefore: Int
    public var reminderType: ReminderType
    public var isEnabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        minutesBefore: Int,
        reminderType: ReminderType = .notification,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.minutesBefore = minutesBefore
        self.reminderType = reminderType
        self.isEnabled = isEnabled
    }
}

public enum ReminderType: String, CaseIterable, Codable {
    case notification = "NOTIFICATION"
    case email = "EMAIL"
    case popup = "POPUP"
    case sound = "SOUND"
}

// MARK: - CloudKit Extensions
extension CalendarEvent {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CalendarEvent", recordID: CKRecord.ID(recordName: id))
        record["title"] = title
        record["description"] = description
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["isAllDay"] = isAllDay ? 1 : 0
        record["location"] = location
        record["attendees"] = attendees
        record["organizerId"] = organizerId
        record["calendarId"] = calendarId
        record["eventType"] = eventType.rawValue
        record["visibility"] = visibility.rawValue
        record["status"] = status.rawValue
        record["priority"] = priority.rawValue
        record["tags"] = tags
        record["attachments"] = attachments
        record["externalEventId"] = externalEventId
        record["source"] = source.rawValue
        record["lastModified"] = lastModified
        record["createdAt"] = createdAt
        record["createdBy"] = createdBy
        
        // Store recurrence rule as JSON
        if let recurrenceRule = recurrenceRule,
           let data = try? JSONEncoder().encode(recurrenceRule) {
            record["recurrenceRule"] = String(data: data, encoding: .utf8)
        }
        
        // Store reminders as JSON
        if let data = try? JSONEncoder().encode(reminders) {
            record["reminders"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CalendarEvent? {
        guard let title = record["title"] as? String,
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let organizerId = record["organizerId"] as? String,
              let calendarId = record["calendarId"] as? String,
              let createdBy = record["createdBy"] as? String else {
            return nil
        }
        
        let isAllDay = (record["isAllDay"] as? Int) == 1
        let eventType = EventType(rawValue: record["eventType"] as? String ?? "MEETING") ?? .meeting
        let visibility = EventVisibility(rawValue: record["visibility"] as? String ?? "PRIVATE") ?? .private
        let status = EventStatus(rawValue: record["status"] as? String ?? "CONFIRMED") ?? .confirmed
        let priority = EventPriority(rawValue: record["priority"] as? String ?? "NORMAL") ?? .normal
        let source = EventSource(rawValue: record["source"] as? String ?? "MANUAL") ?? .manual
        
        var recurrenceRule: RecurrenceRule?
        if let recurrenceData = record["recurrenceRule"] as? String,
           let data = recurrenceData.data(using: .utf8) {
            recurrenceRule = try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        
        var reminders: [EventReminder] = []
        if let remindersData = record["reminders"] as? String,
           let data = remindersData.data(using: .utf8) {
            reminders = (try? JSONDecoder().decode([EventReminder].self, from: data)) ?? []
        }
        
        return CalendarEvent(
            id: record.recordID.recordName,
            title: title,
            description: record["description"] as? String,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: record["location"] as? String,
            attendees: record["attendees"] as? [String] ?? [],
            organizerId: organizerId,
            calendarId: calendarId,
            eventType: eventType,
            recurrenceRule: recurrenceRule,
            reminders: reminders,
            visibility: visibility,
            status: status,
            priority: priority,
            tags: record["tags"] as? [String] ?? [],
            attachments: record["attachments"] as? [String] ?? [],
            externalEventId: record["externalEventId"] as? String,
            source: source,
            lastModified: record["lastModified"] as? Date ?? Date(),
            createdAt: record["createdAt"] as? Date ?? Date(),
            createdBy: createdBy
        )
    }
}
