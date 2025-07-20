//
//  ProjectTask.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit

/// Enhanced project task model with comprehensive project management features
/// Replaces the previous TaskModel with expanded functionality
struct ProjectTask: Identifiable, Codable, Hashable {
    let id: UUID
    let boardId: UUID
    var title: String
    var description: String?
    var status: TaskStatus
    var priority: TaskPriority
    var assignedTo: [String]
    var storeCode: String?
    var departmentId: String?
    var dueDate: Date?
    var startDate: Date?
    var estimatedHours: Double?
    var actualHours: Double?
    var tags: [String]
    var checklist: [ChecklistItem]
    var customFields: [String: String] // Custom column values
    var position: Int // For ordering within status columns
    var parentTaskId: UUID? // For subtasks
    let createdBy: String
    let createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var attachments: [TaskAttachment] = []
    var comments: [TaskComment] = []
    var dependencies: [TaskDependency] = []
    var subtasks: [ProjectTask] = []
    
    init(
        id: UUID = UUID(),
        boardId: UUID,
        title: String,
        description: String? = nil,
        status: TaskStatus = .notStarted,
        priority: TaskPriority = .medium,
        assignedTo: [String] = [],
        storeCode: String? = nil,
        departmentId: String? = nil,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        estimatedHours: Double? = nil,
        actualHours: Double? = nil,
        tags: [String] = [],
        checklist: [ChecklistItem] = [],
        customFields: [String: String] = [:],
        position: Int = 0,
        parentTaskId: UUID? = nil,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.boardId = boardId
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.assignedTo = assignedTo
        self.storeCode = storeCode
        self.departmentId = departmentId
        self.dueDate = dueDate
        self.startDate = startDate
        self.estimatedHours = estimatedHours
        self.actualHours = actualHours
        self.tags = tags
        self.checklist = checklist
        self.customFields = customFields
        self.position = position
        self.parentTaskId = parentTaskId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Task Status

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case blocked = "BLOCKED"
    case cancelled = "CANCELLED"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .blocked: return "Blocked"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle.fill"
        case .blocked: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .blocked: return "orange"
        case .cancelled: return "red"
        }
    }
    
    var isCompleted: Bool {
        return self == .completed
    }
    
    var isActive: Bool {
        return self == .inProgress || self == .notStarted
    }
}

// MARK: - Task Priority

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case urgent = "URGENT"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Checklist Item

struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    let taskId: UUID
    var title: String
    var isCompleted: Bool
    var completedBy: String?
    var completedAt: Date?
    var position: Int
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        title: String,
        isCompleted: Bool = false,
        completedBy: String? = nil,
        completedAt: Date? = nil,
        position: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.title = title
        self.isCompleted = isCompleted
        self.completedBy = completedBy
        self.completedAt = completedAt
        self.position = position
        self.createdAt = createdAt
    }
    
    mutating func complete(by userId: String) {
        isCompleted = true
        completedBy = userId
        completedAt = Date()
    }
    
    mutating func uncomplete() {
        isCompleted = false
        completedBy = nil
        completedAt = nil
    }
}

// MARK: - Task Attachment

struct TaskAttachment: Identifiable, Codable, Hashable {
    let id: UUID
    let taskId: UUID
    let fileName: String
    let fileSize: Int
    let mimeType: String
    let url: String
    let uploadedBy: String
    let uploadedAt: Date
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        fileName: String,
        fileSize: Int,
        mimeType: String,
        url: String,
        uploadedBy: String,
        uploadedAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.url = url
        self.uploadedBy = uploadedBy
        self.uploadedAt = uploadedAt
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    var isImage: Bool {
        return mimeType.hasPrefix("image/")
    }
    
    var isDocument: Bool {
        return mimeType.hasPrefix("application/") || mimeType.hasPrefix("text/")
    }
    
    var fileIcon: String {
        if isImage {
            return "photo"
        } else if isDocument {
            return "doc"
        } else {
            return "paperclip"
        }
    }
}

// MARK: - Task Comment

struct TaskComment: Identifiable, Codable, Hashable {
    let id: UUID
    let taskId: UUID
    let authorId: String
    var content: String
    var mentions: [String]
    let createdAt: Date
    var updatedAt: Date?
    
    // Computed properties
    var attachments: [TaskAttachment] = []
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        authorId: String,
        content: String,
        mentions: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.authorId = authorId
        self.content = content
        self.mentions = mentions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    mutating func update(content: String) {
        self.content = content
        self.updatedAt = Date()
    }
    
    var isEdited: Bool {
        return updatedAt != nil
    }
}

// MARK: - Task Dependency

struct TaskDependency: Identifiable, Codable, Hashable {
    let id: UUID
    let taskId: UUID
    let dependsOnTaskId: UUID
    let dependencyType: DependencyType
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        dependsOnTaskId: UUID,
        dependencyType: DependencyType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.dependsOnTaskId = dependsOnTaskId
        self.dependencyType = dependencyType
        self.createdAt = createdAt
    }
}

enum DependencyType: String, Codable, CaseIterable, Identifiable {
    case blocks = "BLOCKS"
    case blockedBy = "BLOCKED_BY"
    case relatesTo = "RELATES_TO"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blocks: return "Blocks"
        case .blockedBy: return "Blocked By"
        case .relatesTo: return "Relates To"
        }
    }
    
    var icon: String {
        switch self {
        case .blocks: return "stop.circle"
        case .blockedBy: return "exclamationmark.triangle"
        case .relatesTo: return "link"
        }
    }
    
    var color: String {
        switch self {
        case .blocks: return "red"
        case .blockedBy: return "orange"
        case .relatesTo: return "blue"
        }
    }
}

// MARK: - Task Extensions

extension ProjectTask {
    
    // Progress calculation
    var checklistProgress: Double {
        guard !checklist.isEmpty else { return 0.0 }
        let completedCount = checklist.filter(\.isCompleted).count
        return Double(completedCount) / Double(checklist.count)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !status.isCompleted else { return false }
        return Date() > dueDate
    }
    
    var isUpcoming: Bool {
        guard let dueDate = dueDate, !status.isCompleted else { return false }
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return dueDate <= threeDaysFromNow && dueDate >= Date()
    }
    
    var estimatedVsActualHoursVariance: Double? {
        guard let estimated = estimatedHours, let actual = actualHours else { return nil }
        return actual - estimated
    }
    
    var isAssignedTo(_ userId: String) -> Bool {
        return assignedTo.contains(userId)
    }
    
    var hasSubtasks: Bool {
        return !subtasks.isEmpty
    }
    
    var isSubtask: Bool {
        return parentTaskId != nil
    }
    
    // Task completion
    mutating func complete(by userId: String) {
        status = .completed
        updatedAt = Date()
        if actualHours == nil && estimatedHours != nil {
            actualHours = estimatedHours
        }
    }
    
    mutating func markInProgress() {
        status = .inProgress
        updatedAt = Date()
        if startDate == nil {
            startDate = Date()
        }
    }
    
    mutating func block() {
        status = .blocked
        updatedAt = Date()
    }
    
    mutating func cancel() {
        status = .cancelled
        updatedAt = Date()
    }
    
    // Assignment management
    mutating func assign(to userIds: [String]) {
        assignedTo = userIds
        updatedAt = Date()
    }
    
    mutating func addAssignee(_ userId: String) {
        if !assignedTo.contains(userId) {
            assignedTo.append(userId)
            updatedAt = Date()
        }
    }
    
    mutating func removeAssignee(_ userId: String) {
        assignedTo.removeAll { $0 == userId }
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
    
    // Custom field management
    mutating func setCustomField(_ key: String, value: String) {
        customFields[key] = value
        updatedAt = Date()
    }
    
    mutating func removeCustomField(_ key: String) {
        customFields.removeValue(forKey: key)
        updatedAt = Date()
    }
}

// MARK: - CloudKit Integration

extension ProjectTask {
    
    static let recordType = "ProjectTask"
    
    init?(record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let boardIdString = record["boardId"] as? String,
            let boardId = UUID(uuidString: boardIdString),
            let title = record["title"] as? String,
            let statusRaw = record["status"] as? String,
            let status = TaskStatus(rawValue: statusRaw),
            let priorityRaw = record["priority"] as? String,
            let priority = TaskPriority(rawValue: priorityRaw),
            let assignedTo = record["assignedTo"] as? [String],
            let tags = record["tags"] as? [String],
            let position = record["position"] as? Int,
            let createdBy = record["createdBy"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.boardId = boardId
        self.title = title
        self.description = record["description"] as? String
        self.status = status
        self.priority = priority
        self.assignedTo = assignedTo
        self.storeCode = record["storeCode"] as? String
        self.departmentId = record["departmentId"] as? String
        self.dueDate = record["dueDate"] as? Date
        self.startDate = record["startDate"] as? Date
        self.estimatedHours = record["estimatedHours"] as? Double
        self.actualHours = record["actualHours"] as? Double
        self.tags = tags
        self.position = position
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode checklist from JSON
        if let checklistData = record["checklist"] as? Data,
           let decodedChecklist = try? JSONDecoder().decode([ChecklistItem].self, from: checklistData) {
            self.checklist = decodedChecklist
        } else {
            self.checklist = []
        }
        
        // Decode custom fields from JSON
        if let customFieldsData = record["customFields"] as? Data,
           let decodedFields = try? JSONDecoder().decode([String: String].self, from: customFieldsData) {
            self.customFields = decodedFields
        } else {
            self.customFields = [:]
        }
        
        // Handle parent task ID
        if let parentTaskIdString = record["parentTaskId"] as? String {
            self.parentTaskId = UUID(uuidString: parentTaskIdString)
        } else {
            self.parentTaskId = nil
        }
    }
    
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["id"] = id.uuidString
        record["boardId"] = boardId.uuidString
        record["title"] = title
        record["description"] = description
        record["status"] = status.rawValue
        record["priority"] = priority.rawValue
        record["assignedTo"] = assignedTo
        record["storeCode"] = storeCode
        record["departmentId"] = departmentId
        record["dueDate"] = dueDate
        record["startDate"] = startDate
        record["estimatedHours"] = estimatedHours
        record["actualHours"] = actualHours
        record["tags"] = tags
        record["position"] = position
        record["parentTaskId"] = parentTaskId?.uuidString
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode checklist as JSON
        if let checklistData = try? JSONEncoder().encode(checklist) {
            record["checklist"] = checklistData
        }
        
        // Encode custom fields as JSON
        if let customFieldsData = try? JSONEncoder().encode(customFields) {
            record["customFields"] = customFieldsData
        }
        
        return record
    }
}

// MARK: - Task Filters

struct TaskFilters: Codable {
    var status: [TaskStatus]?
    var priority: [TaskPriority]?
    var assignedTo: [String]?
    var tags: [String]?
    var dueDateRange: ClosedRange<Date>?
    var storeCode: String?
    var departmentId: String?
    var searchText: String?
    
    init() {
        // Default empty filters
    }
    
    func matches(_ task: ProjectTask) -> Bool {
        // Status filter
        if let statusFilter = status, !statusFilter.isEmpty {
            if !statusFilter.contains(task.status) {
                return false
            }
        }
        
        // Priority filter
        if let priorityFilter = priority, !priorityFilter.isEmpty {
            if !priorityFilter.contains(task.priority) {
                return false
            }
        }
        
        // Assignee filter
        if let assigneeFilter = assignedTo, !assigneeFilter.isEmpty {
            if !task.assignedTo.contains(where: assigneeFilter.contains) {
                return false
            }
        }
        
        // Tags filter
        if let tagsFilter = tags, !tagsFilter.isEmpty {
            if !task.tags.contains(where: tagsFilter.contains) {
                return false
            }
        }
        
        // Due date range filter
        if let dateRange = dueDateRange {
            guard let taskDueDate = task.dueDate else { return false }
            if !dateRange.contains(taskDueDate) {
                return false
            }
        }
        
        // Store code filter
        if let storeFilter = storeCode, !storeFilter.isEmpty {
            if task.storeCode != storeFilter {
                return false
            }
        }
        
        // Department filter
        if let deptFilter = departmentId, !deptFilter.isEmpty {
            if task.departmentId != deptFilter {
                return false
            }
        }
        
        // Search text filter
        if let searchText = searchText, !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            let titleMatch = task.title.lowercased().contains(lowercaseSearch)
            let descriptionMatch = task.description?.lowercased().contains(lowercaseSearch) ?? false
            let tagMatch = task.tags.contains { $0.lowercased().contains(lowercaseSearch) }
            
            if !titleMatch && !descriptionMatch && !tagMatch {
                return false
            }
        }
        
        return true
    }
}
