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

// MARK: - EventAttendee Model (PT3VS1 Compliance)
public struct EventAttendee: Identifiable, Codable, Hashable {
    public let id: String
    public var eventId: String
    public var userId: String
    public var status: AttendeeStatus
    public var responseDate: Date?
    public var role: AttendeeRole
    public var isOptional: Bool
    public var email: String?
    public var displayName: String?
    public var invitedAt: Date
    public var lastModified: Date
    
    public init(
        id: String = UUID().uuidString,
        eventId: String,
        userId: String,
        status: AttendeeStatus = .pending,
        responseDate: Date? = nil,
        role: AttendeeRole = .attendee,
        isOptional: Bool = false,
        email: String? = nil,
        displayName: String? = nil,
        invitedAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.status = status
        self.responseDate = responseDate
        self.role = role
        self.isOptional = isOptional
        self.email = email
        self.displayName = displayName
        self.invitedAt = invitedAt
        self.lastModified = lastModified
    }
}

public enum AttendeeStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    case tentative = "TENTATIVE"
    case noResponse = "NO_RESPONSE"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .tentative: return "Tentative"
        case .noResponse: return "No Response"
        }
    }
}

public enum AttendeeRole: String, CaseIterable, Codable, Identifiable {
    case organizer = "ORGANIZER"
    case attendee = "ATTENDEE"
    case presenter = "PRESENTER"
    case moderator = "MODERATOR"
    case optional = "OPTIONAL"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .organizer: return "Organizer"
        case .attendee: return "Attendee"
        case .presenter: return "Presenter"
        case .moderator: return "Moderator"
        case .optional: return "Optional"
        }
    }
}

// MARK: - CalendarGroup Model (PT3VS1 Compliance)
public struct CalendarGroup: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var ownerId: String
    public var members: [String]
    public var isPublic: Bool
    public var permissions: [CalendarPermission]
    public var color: String?
    public var timezone: String
    public var defaultVisibility: EventVisibility
    public var allowMemberInvites: Bool
    public var requireApproval: Bool
    public var tags: [String]
    public var createdAt: Date
    public var modifiedAt: Date
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        ownerId: String,
        members: [String] = [],
        isPublic: Bool = false,
        permissions: [CalendarPermission] = [],
        color: String? = nil,
        timezone: String = TimeZone.current.identifier,
        defaultVisibility: EventVisibility = .private,
        allowMemberInvites: Bool = true,
        requireApproval: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.members = members
        self.isPublic = isPublic
        self.permissions = permissions
        self.color = color
        self.timezone = timezone
        self.defaultVisibility = defaultVisibility
        self.allowMemberInvites = allowMemberInvites
        self.requireApproval = requireApproval
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isActive = isActive
    }
}

public struct CalendarPermission: Identifiable, Codable, Hashable {
    public let id: String
    public var userId: String
    public var permission: PermissionLevel
    public var grantedBy: String
    public var grantedAt: Date
    public var expiresAt: Date?
    public var conditions: [String]
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        permission: PermissionLevel,
        grantedBy: String,
        grantedAt: Date = Date(),
        expiresAt: Date? = nil,
        conditions: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.permission = permission
        self.grantedBy = grantedBy
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.conditions = conditions
    }
}

public enum PermissionLevel: String, CaseIterable, Codable, Identifiable {
    case owner = "OWNER"
    case admin = "ADMIN"
    case editor = "EDITOR"
    case contributor = "CONTRIBUTOR"
    case viewer = "VIEWER"
    case invited = "INVITED"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Administrator"
        case .editor: return "Editor"
        case .contributor: return "Contributor"
        case .viewer: return "Viewer"
        case .invited: return "Invited"
        }
    }
    
    public var canEdit: Bool {
        switch self {
        case .owner, .admin, .editor, .contributor: return true
        case .viewer, .invited: return false
        }
    }
    
    public var canInvite: Bool {
        switch self {
        case .owner, .admin, .editor: return true
        case .contributor, .viewer, .invited: return false
        }
    }
}

// MARK: - CloudKit Extensions for New Models
extension EventAttendee {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "EventAttendee", recordID: CKRecord.ID(recordName: id))
        record["eventId"] = eventId
        record["userId"] = userId
        record["status"] = status.rawValue
        record["responseDate"] = responseDate
        record["role"] = role.rawValue
        record["isOptional"] = isOptional ? 1 : 0
        record["email"] = email
        record["displayName"] = displayName
        record["invitedAt"] = invitedAt
        record["lastModified"] = lastModified
        return record
    }
    
    public static func from(record: CKRecord) -> EventAttendee? {
        guard let eventId = record["eventId"] as? String,
              let userId = record["userId"] as? String else {
            return nil
        }
        
        let status = AttendeeStatus(rawValue: record["status"] as? String ?? "PENDING") ?? .pending
        let role = AttendeeRole(rawValue: record["role"] as? String ?? "ATTENDEE") ?? .attendee
        let isOptional = (record["isOptional"] as? Int) == 1
        
        return EventAttendee(
            id: record.recordID.recordName,
            eventId: eventId,
            userId: userId,
            status: status,
            responseDate: record["responseDate"] as? Date,
            role: role,
            isOptional: isOptional,
            email: record["email"] as? String,
            displayName: record["displayName"] as? String,
            invitedAt: record["invitedAt"] as? Date ?? Date(),
            lastModified: record["lastModified"] as? Date ?? Date()
        )
    }
}

extension CalendarGroup {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CalendarGroup", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["ownerId"] = ownerId
        record["members"] = members
        record["isPublic"] = isPublic ? 1 : 0
        record["color"] = color
        record["timezone"] = timezone
        record["defaultVisibility"] = defaultVisibility.rawValue
        record["allowMemberInvites"] = allowMemberInvites ? 1 : 0
        record["requireApproval"] = requireApproval ? 1 : 0
        record["tags"] = tags
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["isActive"] = isActive ? 1 : 0
        
        // Store permissions as JSON
        if let data = try? JSONEncoder().encode(permissions) {
            record["permissions"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CalendarGroup? {
        guard let name = record["name"] as? String,
              let ownerId = record["ownerId"] as? String else {
            return nil
        }
        
        let isPublic = (record["isPublic"] as? Int) == 1
        let allowMemberInvites = (record["allowMemberInvites"] as? Int) == 1
        let requireApproval = (record["requireApproval"] as? Int) == 1
        let isActive = (record["isActive"] as? Int) ?? 1 == 1
        let defaultVisibility = EventVisibility(rawValue: record["defaultVisibility"] as? String ?? "PRIVATE") ?? .private
        
        var permissions: [CalendarPermission] = []
        if let permissionsData = record["permissions"] as? String,
           let data = permissionsData.data(using: .utf8) {
            permissions = (try? JSONDecoder().decode([CalendarPermission].self, from: data)) ?? []
        }
        
        return CalendarGroup(
            id: record.recordID.recordName,
            name: name,
            description: record["description"] as? String,
            ownerId: ownerId,
            members: record["members"] as? [String] ?? [],
            isPublic: isPublic,
            permissions: permissions,
            color: record["color"] as? String,
            timezone: record["timezone"] as? String ?? TimeZone.current.identifier,
            defaultVisibility: defaultVisibility,
            allowMemberInvites: allowMemberInvites,
            requireApproval: requireApproval,
            tags: record["tags"] as? [String] ?? [],
            createdAt: record["createdAt"] as? Date ?? Date(),
            modifiedAt: record["modifiedAt"] as? Date ?? Date(),
            isActive: isActive
        )
    }
}
