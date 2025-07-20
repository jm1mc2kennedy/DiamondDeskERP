//
//  PersonalTodo.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit

/// Personal to-do model for lightweight task management
/// Separate from project tasks, focused on individual productivity
struct PersonalTodo: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: String
    var title: String
    var notes: String?
    var dueDate: Date?
    var reminderDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var isRecurring: Bool
    var recurringPattern: RecurringPattern?
    var hasReminder: Bool
    var reminderOffset: Int // Minutes before due date
    var tags: [String]
    var priority: TaskPriority
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var parentBoardId: UUID? // Optional link to project board
    var parentTaskId: UUID? // Optional link to project task
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isRecurring: Bool = false,
        recurringPattern: RecurringPattern? = nil,
        hasReminder: Bool = false,
        reminderOffset: Int = 15, // 15 minutes default
        tags: [String] = [],
        priority: TaskPriority = .medium,
        estimatedMinutes: Int? = nil,
        actualMinutes: Int? = nil,
        parentBoardId: UUID? = nil,
        parentTaskId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isRecurring = isRecurring
        self.recurringPattern = recurringPattern
        self.hasReminder = hasReminder
        self.reminderOffset = reminderOffset
        self.tags = tags
        self.priority = priority
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = actualMinutes
        self.parentBoardId = parentBoardId
        self.parentTaskId = parentTaskId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Recurring Pattern

struct RecurringPattern: Codable, Hashable {
    let type: RecurrenceType
    let interval: Int // Every N days/weeks/months
    let daysOfWeek: [DayOfWeek]? // For weekly recurrence
    let dayOfMonth: Int? // For monthly recurrence
    let endDate: Date? // When to stop recurring
    let maxOccurrences: Int? // Alternative to end date
    
    init(
        type: RecurrenceType,
        interval: Int = 1,
        daysOfWeek: [DayOfWeek]? = nil,
        dayOfMonth: Int? = nil,
        endDate: Date? = nil,
        maxOccurrences: Int? = nil
    ) {
        self.type = type
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endDate = endDate
        self.maxOccurrences = maxOccurrences
    }
    
    // Predefined patterns
    static let daily = RecurringPattern(type: .daily)
    static let weekly = RecurringPattern(type: .weekly)
    static let monthly = RecurringPattern(type: .monthly)
    static let weekdays = RecurringPattern(
        type: .weekly,
        daysOfWeek: [.monday, .tuesday, .wednesday, .thursday, .friday]
    )
    static let weekends = RecurringPattern(
        type: .weekly,
        daysOfWeek: [.saturday, .sunday]
    )
}

enum RecurrenceType: String, Codable, CaseIterable, Identifiable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "clock"
        case .weekly: return "calendar.day.timeline.left"
        case .monthly: return "calendar"
        case .yearly: return "calendar.circle"
        }
    }
}

enum DayOfWeek: String, Codable, CaseIterable, Identifiable {
    case sunday = "SUNDAY"
    case monday = "MONDAY"
    case tuesday = "TUESDAY"
    case wednesday = "WEDNESDAY"
    case thursday = "THURSDAY"
    case friday = "FRIDAY"
    case saturday = "SATURDAY"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var weekdayNumber: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

// MARK: - Personal To-Do Extensions

extension PersonalTodo {
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }
    
    var isUpcoming: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return dueDate <= threeDaysFromNow && dueDate >= Date()
    }
    
    var dueDateStatus: DueDateStatus {
        guard let dueDate = dueDate, !isCompleted else { return .none }
        
        let calendar = Calendar.current
        let now = Date()
        
        if now > dueDate {
            return .overdue
        } else if calendar.isDateInToday(dueDate) {
            return .today
        } else if calendar.isDateInTomorrow(dueDate) {
            return .tomorrow
        } else if dueDate <= calendar.date(byAdding: .day, value: 7, to: now) ?? now {
            return .thisWeek
        } else {
            return .future
        }
    }
    
    var estimatedVsActualMinutesVariance: Int? {
        guard let estimated = estimatedMinutes, let actual = actualMinutes else { return nil }
        return actual - estimated
    }
    
    var shouldShowReminder: Bool {
        guard hasReminder, let reminderDate = reminderDate, !isCompleted else { return false }
        return Date() >= reminderDate
    }
    
    var nextReminderDate: Date? {
        guard hasReminder, let dueDate = dueDate else { return nil }
        return Calendar.current.date(byAdding: .minute, value: -reminderOffset, to: dueDate)
    }
    
    // Completion management
    mutating func complete() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
        
        // Create next occurrence if recurring
        if isRecurring, let pattern = recurringPattern {
            // This would typically be handled by a service that creates the next occurrence
        }
    }
    
    mutating func uncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
    
    // Tag management
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            updatedAt = Date()
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        updatedAt = Date()
    }
    
    // Time tracking
    mutating func startTimer() {
        // This would be used with a timer service
        updatedAt = Date()
    }
    
    mutating func stopTimer(elapsedMinutes: Int) {
        if let current = actualMinutes {
            actualMinutes = current + elapsedMinutes
        } else {
            actualMinutes = elapsedMinutes
        }
        updatedAt = Date()
    }
    
    // Recurring task management
    func generateNextOccurrence() -> PersonalTodo? {
        guard isRecurring, let pattern = recurringPattern, let dueDate = dueDate else { return nil }
        
        let calendar = Calendar.current
        var nextDueDate: Date?
        
        switch pattern.type {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: pattern.interval, to: dueDate)
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: pattern.interval, to: dueDate)
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: pattern.interval, to: dueDate)
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: pattern.interval, to: dueDate)
        }
        
        guard let nextDate = nextDueDate else { return nil }
        
        // Check if we should stop recurring
        if let endDate = pattern.endDate, nextDate > endDate {
            return nil
        }
        
        var nextTodo = self
        nextTodo.id = UUID()
        nextTodo.dueDate = nextDate
        nextTodo.reminderDate = nextTodo.nextReminderDate
        nextTodo.isCompleted = false
        nextTodo.completedAt = nil
        nextTodo.createdAt = Date()
        nextTodo.updatedAt = Date()
        
        return nextTodo
    }
}

enum DueDateStatus: String, Codable, CaseIterable {
    case none = "NONE"
    case overdue = "OVERDUE"
    case today = "TODAY"
    case tomorrow = "TOMORROW"
    case thisWeek = "THIS_WEEK"
    case future = "FUTURE"
    
    var displayName: String {
        switch self {
        case .none: return "No Due Date"
        case .overdue: return "Overdue"
        case .today: return "Due Today"
        case .tomorrow: return "Due Tomorrow"
        case .thisWeek: return "Due This Week"
        case .future: return "Future"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "gray"
        case .overdue: return "red"
        case .today: return "orange"
        case .tomorrow: return "yellow"
        case .thisWeek: return "blue"
        case .future: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "clock.badge"
        case .overdue: return "exclamationmark.triangle.fill"
        case .today: return "clock.fill"
        case .tomorrow: return "sun.max.fill"
        case .thisWeek: return "calendar"
        case .future: return "calendar.badge.plus"
        }
    }
}

// MARK: - CloudKit Integration

extension PersonalTodo {
    
    static let recordType = "PersonalTodo"
    
    init?(record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let userId = record["userId"] as? String,
            let title = record["title"] as? String,
            let isCompleted = record["isCompleted"] as? Bool,
            let isRecurring = record["isRecurring"] as? Bool,
            let hasReminder = record["hasReminder"] as? Bool,
            let reminderOffset = record["reminderOffset"] as? Int,
            let tags = record["tags"] as? [String],
            let priorityRaw = record["priority"] as? String,
            let priority = TaskPriority(rawValue: priorityRaw),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.title = title
        self.notes = record["notes"] as? String
        self.dueDate = record["dueDate"] as? Date
        self.reminderDate = record["reminderDate"] as? Date
        self.isCompleted = isCompleted
        self.completedAt = record["completedAt"] as? Date
        self.isRecurring = isRecurring
        self.hasReminder = hasReminder
        self.reminderOffset = reminderOffset
        self.tags = tags
        self.priority = priority
        self.estimatedMinutes = record["estimatedMinutes"] as? Int
        self.actualMinutes = record["actualMinutes"] as? Int
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode recurring pattern from JSON
        if let recurringPatternData = record["recurringPattern"] as? Data,
           let decodedPattern = try? JSONDecoder().decode(RecurringPattern.self, from: recurringPatternData) {
            self.recurringPattern = decodedPattern
        } else {
            self.recurringPattern = nil
        }
        
        // Handle parent references
        if let parentBoardIdString = record["parentBoardId"] as? String {
            self.parentBoardId = UUID(uuidString: parentBoardIdString)
        } else {
            self.parentBoardId = nil
        }
        
        if let parentTaskIdString = record["parentTaskId"] as? String {
            self.parentTaskId = UUID(uuidString: parentTaskIdString)
        } else {
            self.parentTaskId = nil
        }
    }
    
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["id"] = id.uuidString
        record["userId"] = userId
        record["title"] = title
        record["notes"] = notes
        record["dueDate"] = dueDate
        record["reminderDate"] = reminderDate
        record["isCompleted"] = isCompleted
        record["completedAt"] = completedAt
        record["isRecurring"] = isRecurring
        record["hasReminder"] = hasReminder
        record["reminderOffset"] = reminderOffset
        record["tags"] = tags
        record["priority"] = priority.rawValue
        record["estimatedMinutes"] = estimatedMinutes
        record["actualMinutes"] = actualMinutes
        record["parentBoardId"] = parentBoardId?.uuidString
        record["parentTaskId"] = parentTaskId?.uuidString
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode recurring pattern as JSON
        if let pattern = recurringPattern,
           let patternData = try? JSONEncoder().encode(pattern) {
            record["recurringPattern"] = patternData
        }
        
        return record
    }
}

// MARK: - Todo Filters

struct TodoFilters: Codable {
    var isCompleted: Bool?
    var dueDateRange: ClosedRange<Date>?
    var priority: [TaskPriority]?
    var tags: [String]?
    var searchText: String?
    var showOverdue: Bool?
    var showToday: Bool?
    var showUpcoming: Bool?
    
    init() {
        // Default empty filters
    }
    
    func matches(_ todo: PersonalTodo) -> Bool {
        // Completion filter
        if let completedFilter = isCompleted {
            if todo.isCompleted != completedFilter {
                return false
            }
        }
        
        // Due date range filter
        if let dateRange = dueDateRange {
            guard let todoDueDate = todo.dueDate else { return false }
            if !dateRange.contains(todoDueDate) {
                return false
            }
        }
        
        // Priority filter
        if let priorityFilter = priority, !priorityFilter.isEmpty {
            if !priorityFilter.contains(todo.priority) {
                return false
            }
        }
        
        // Tags filter
        if let tagsFilter = tags, !tagsFilter.isEmpty {
            if !todo.tags.contains(where: tagsFilter.contains) {
                return false
            }
        }
        
        // Overdue filter
        if let overdueFilter = showOverdue, overdueFilter {
            if !todo.isOverdue {
                return false
            }
        }
        
        // Today filter
        if let todayFilter = showToday, todayFilter {
            if !todo.isDueToday {
                return false
            }
        }
        
        // Upcoming filter
        if let upcomingFilter = showUpcoming, upcomingFilter {
            if !todo.isUpcoming {
                return false
            }
        }
        
        // Search text filter
        if let searchText = searchText, !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            let titleMatch = todo.title.lowercased().contains(lowercaseSearch)
            let notesMatch = todo.notes?.lowercased().contains(lowercaseSearch) ?? false
            let tagMatch = todo.tags.contains { $0.lowercased().contains(lowercaseSearch) }
            
            if !titleMatch && !notesMatch && !tagMatch {
                return false
            }
        }
        
        return true
    }
}
