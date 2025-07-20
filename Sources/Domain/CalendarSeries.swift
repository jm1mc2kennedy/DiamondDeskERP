import Foundation
import CloudKit

// MARK: - Calendar Event Series Model
public struct CalendarEventSeries: Identifiable, Codable, Hashable {
    public let id: String
    public var masterEventId: String
    public var seriesTitle: String
    public var seriesDescription: String?
    public var originalStartDate: Date
    public var originalEndDate: Date
    public var recurrenceRule: RecurrenceRule
    public var exceptions: [SeriesException]
    public var modifications: [SeriesModification]
    public var calendarId: String
    public var organizerId: String
    public var isActive: Bool
    public var lastUpdated: Date
    public var createdAt: Date
    public var createdBy: String
    
    public init(
        id: String = UUID().uuidString,
        masterEventId: String,
        seriesTitle: String,
        seriesDescription: String? = nil,
        originalStartDate: Date,
        originalEndDate: Date,
        recurrenceRule: RecurrenceRule,
        exceptions: [SeriesException] = [],
        modifications: [SeriesModification] = [],
        calendarId: String,
        organizerId: String,
        isActive: Bool = true,
        lastUpdated: Date = Date(),
        createdAt: Date = Date(),
        createdBy: String
    ) {
        self.id = id
        self.masterEventId = masterEventId
        self.seriesTitle = seriesTitle
        self.seriesDescription = seriesDescription
        self.originalStartDate = originalStartDate
        self.originalEndDate = originalEndDate
        self.recurrenceRule = recurrenceRule
        self.exceptions = exceptions
        self.modifications = modifications
        self.calendarId = calendarId
        self.organizerId = organizerId
        self.isActive = isActive
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
}

// MARK: - Supporting Structures
public struct SeriesException: Identifiable, Codable, Hashable {
    public let id: String
    public var exceptionDate: Date
    public var exceptionType: ExceptionType
    public var reason: String?
    public var createdBy: String
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        exceptionDate: Date,
        exceptionType: ExceptionType,
        reason: String? = nil,
        createdBy: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.exceptionDate = exceptionDate
        self.exceptionType = exceptionType
        self.reason = reason
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

public enum ExceptionType: String, CaseIterable, Codable, Identifiable {
    case deleted = "DELETED"
    case modified = "MODIFIED"
    case postponed = "POSTPONED"
    case cancelled = "CANCELLED"
    
    public var id: String { rawValue }
}

public struct SeriesModification: Identifiable, Codable, Hashable {
    public let id: String
    public var modificationDate: Date
    public var modifiedEventId: String
    public var changes: [ModificationChange]
    public var modifiedBy: String
    public var modifiedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        modificationDate: Date,
        modifiedEventId: String,
        changes: [ModificationChange] = [],
        modifiedBy: String,
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.modificationDate = modificationDate
        self.modifiedEventId = modifiedEventId
        self.changes = changes
        self.modifiedBy = modifiedBy
        self.modifiedAt = modifiedAt
    }
}

public struct ModificationChange: Codable, Hashable {
    public var fieldName: String
    public var oldValue: String?
    public var newValue: String?
    public var changeType: ChangeType
    
    public init(
        fieldName: String,
        oldValue: String? = nil,
        newValue: String? = nil,
        changeType: ChangeType
    ) {
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
        self.changeType = changeType
    }
}

public enum ChangeType: String, CaseIterable, Codable {
    case updated = "UPDATED"
    case added = "ADDED"
    case removed = "REMOVED"
}

// MARK: - Calendar Resource Model
public struct CalendarResource: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var resourceType: ResourceType
    public var capacity: Int?
    public var location: String?
    public var availability: [AvailabilitySlot]
    public var equipment: [String]
    public var requirements: [String]
    public var bookingRules: BookingRules
    public var isActive: Bool
    public var managedBy: String
    public var cost: ResourceCost?
    public var tags: [String]
    public var lastUpdated: Date
    public var createdAt: Date
    public var createdBy: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        resourceType: ResourceType,
        capacity: Int? = nil,
        location: String? = nil,
        availability: [AvailabilitySlot] = [],
        equipment: [String] = [],
        requirements: [String] = [],
        bookingRules: BookingRules = BookingRules(),
        isActive: Bool = true,
        managedBy: String,
        cost: ResourceCost? = nil,
        tags: [String] = [],
        lastUpdated: Date = Date(),
        createdAt: Date = Date(),
        createdBy: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.resourceType = resourceType
        self.capacity = capacity
        self.location = location
        self.availability = availability
        self.equipment = equipment
        self.requirements = requirements
        self.bookingRules = bookingRules
        self.isActive = isActive
        self.managedBy = managedBy
        self.cost = cost
        self.tags = tags
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
}

public enum ResourceType: String, CaseIterable, Codable, Identifiable {
    case room = "ROOM"
    case equipment = "EQUIPMENT"
    case vehicle = "VEHICLE"
    case person = "PERSON"
    case virtual = "VIRTUAL"
    case facility = "FACILITY"
    case other = "OTHER"
    
    public var id: String { rawValue }
}

public struct AvailabilitySlot: Codable, Hashable {
    public var dayOfWeek: WeekDay
    public var startTime: String // Format: "HH:mm"
    public var endTime: String   // Format: "HH:mm"
    public var isAvailable: Bool
    
    public init(
        dayOfWeek: WeekDay,
        startTime: String,
        endTime: String,
        isAvailable: Bool = true
    ) {
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
    }
}

public struct BookingRules: Codable, Hashable {
    public var advanceBookingDays: Int
    public var maxBookingDuration: TimeInterval
    public var minBookingDuration: TimeInterval
    public var allowRecurring: Bool
    public var requireApproval: Bool
    public var autoConfirm: Bool
    public var cancellationPolicy: String?
    
    public init(
        advanceBookingDays: Int = 30,
        maxBookingDuration: TimeInterval = 8 * 3600, // 8 hours
        minBookingDuration: TimeInterval = 0.5 * 3600, // 30 minutes
        allowRecurring: Bool = true,
        requireApproval: Bool = false,
        autoConfirm: Bool = true,
        cancellationPolicy: String? = nil
    ) {
        self.advanceBookingDays = advanceBookingDays
        self.maxBookingDuration = maxBookingDuration
        self.minBookingDuration = minBookingDuration
        self.allowRecurring = allowRecurring
        self.requireApproval = requireApproval
        self.autoConfirm = autoConfirm
        self.cancellationPolicy = cancellationPolicy
    }
}

public struct ResourceCost: Codable, Hashable {
    public var hourlyRate: Double?
    public var dailyRate: Double?
    public var weeklyRate: Double?
    public var currency: String
    public var billingType: BillingType
    
    public init(
        hourlyRate: Double? = nil,
        dailyRate: Double? = nil,
        weeklyRate: Double? = nil,
        currency: String = "USD",
        billingType: BillingType = .hourly
    ) {
        self.hourlyRate = hourlyRate
        self.dailyRate = dailyRate
        self.weeklyRate = weeklyRate
        self.currency = currency
        self.billingType = billingType
    }
}

public enum BillingType: String, CaseIterable, Codable {
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case fixed = "FIXED"
    case free = "FREE"
}

// MARK: - CloudKit Extensions
extension CalendarEventSeries {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CalendarEventSeries", recordID: CKRecord.ID(recordName: id))
        record["masterEventId"] = masterEventId
        record["seriesTitle"] = seriesTitle
        record["seriesDescription"] = seriesDescription
        record["originalStartDate"] = originalStartDate
        record["originalEndDate"] = originalEndDate
        record["calendarId"] = calendarId
        record["organizerId"] = organizerId
        record["isActive"] = isActive ? 1 : 0
        record["lastUpdated"] = lastUpdated
        record["createdAt"] = createdAt
        record["createdBy"] = createdBy
        
        // Store complex objects as JSON
        if let data = try? JSONEncoder().encode(recurrenceRule) {
            record["recurrenceRule"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(exceptions) {
            record["exceptions"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(modifications) {
            record["modifications"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CalendarEventSeries? {
        guard let masterEventId = record["masterEventId"] as? String,
              let seriesTitle = record["seriesTitle"] as? String,
              let originalStartDate = record["originalStartDate"] as? Date,
              let originalEndDate = record["originalEndDate"] as? Date,
              let calendarId = record["calendarId"] as? String,
              let organizerId = record["organizerId"] as? String,
              let createdBy = record["createdBy"] as? String else {
            return nil
        }
        
        let isActive = (record["isActive"] as? Int) == 1
        
        var recurrenceRule: RecurrenceRule?
        if let recurrenceData = record["recurrenceRule"] as? String,
           let data = recurrenceData.data(using: .utf8) {
            recurrenceRule = try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        
        var exceptions: [SeriesException] = []
        if let exceptionsData = record["exceptions"] as? String,
           let data = exceptionsData.data(using: .utf8) {
            exceptions = (try? JSONDecoder().decode([SeriesException].self, from: data)) ?? []
        }
        
        var modifications: [SeriesModification] = []
        if let modificationsData = record["modifications"] as? String,
           let data = modificationsData.data(using: .utf8) {
            modifications = (try? JSONDecoder().decode([SeriesModification].self, from: data)) ?? []
        }
        
        return CalendarEventSeries(
            id: record.recordID.recordName,
            masterEventId: masterEventId,
            seriesTitle: seriesTitle,
            seriesDescription: record["seriesDescription"] as? String,
            originalStartDate: originalStartDate,
            originalEndDate: originalEndDate,
            recurrenceRule: recurrenceRule ?? RecurrenceRule(frequency: .weekly),
            exceptions: exceptions,
            modifications: modifications,
            calendarId: calendarId,
            organizerId: organizerId,
            isActive: isActive,
            lastUpdated: record["lastUpdated"] as? Date ?? Date(),
            createdAt: record["createdAt"] as? Date ?? Date(),
            createdBy: createdBy
        )
    }
}

extension CalendarResource {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CalendarResource", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["resourceType"] = resourceType.rawValue
        record["capacity"] = capacity
        record["location"] = location
        record["equipment"] = equipment
        record["requirements"] = requirements
        record["isActive"] = isActive ? 1 : 0
        record["managedBy"] = managedBy
        record["tags"] = tags
        record["lastUpdated"] = lastUpdated
        record["createdAt"] = createdAt
        record["createdBy"] = createdBy
        
        // Store complex objects as JSON
        if let data = try? JSONEncoder().encode(availability) {
            record["availability"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(bookingRules) {
            record["bookingRules"] = String(data: data, encoding: .utf8)
        }
        if let cost = cost,
           let data = try? JSONEncoder().encode(cost) {
            record["cost"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CalendarResource? {
        guard let name = record["name"] as? String,
              let resourceTypeString = record["resourceType"] as? String,
              let resourceType = ResourceType(rawValue: resourceTypeString),
              let managedBy = record["managedBy"] as? String,
              let createdBy = record["createdBy"] as? String else {
            return nil
        }
        
        let isActive = (record["isActive"] as? Int) == 1
        
        var availability: [AvailabilitySlot] = []
        if let availabilityData = record["availability"] as? String,
           let data = availabilityData.data(using: .utf8) {
            availability = (try? JSONDecoder().decode([AvailabilitySlot].self, from: data)) ?? []
        }
        
        var bookingRules = BookingRules()
        if let bookingRulesData = record["bookingRules"] as? String,
           let data = bookingRulesData.data(using: .utf8) {
            bookingRules = (try? JSONDecoder().decode(BookingRules.self, from: data)) ?? BookingRules()
        }
        
        var cost: ResourceCost?
        if let costData = record["cost"] as? String,
           let data = costData.data(using: .utf8) {
            cost = try? JSONDecoder().decode(ResourceCost.self, from: data)
        }
        
        return CalendarResource(
            id: record.recordID.recordName,
            name: name,
            description: record["description"] as? String,
            resourceType: resourceType,
            capacity: record["capacity"] as? Int,
            location: record["location"] as? String,
            availability: availability,
            equipment: record["equipment"] as? [String] ?? [],
            requirements: record["requirements"] as? [String] ?? [],
            bookingRules: bookingRules,
            isActive: isActive,
            managedBy: managedBy,
            cost: cost,
            tags: record["tags"] as? [String] ?? [],
            lastUpdated: record["lastUpdated"] as? Date ?? Date(),
            createdAt: record["createdAt"] as? Date ?? Date(),
            createdBy: createdBy
        )
    }
}
