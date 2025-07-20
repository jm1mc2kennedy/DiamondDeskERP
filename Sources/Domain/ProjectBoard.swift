//
//  ProjectBoard.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit

/// Project board model for comprehensive project management
/// Supports multiple view types: Kanban, Table, Calendar, Timeline
struct ProjectBoard: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    let ownerId: String
    var viewType: BoardViewType
    var storeCode: String?
    var departmentId: String?
    var isArchived: Bool
    var customColumns: [CustomColumn]
    var createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var permissions: [BoardPermission] = []
    var tasks: [ProjectTask] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        ownerId: String,
        viewType: BoardViewType = .kanban,
        storeCode: String? = nil,
        departmentId: String? = nil,
        isArchived: Bool = false,
        customColumns: [CustomColumn] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.viewType = viewType
        self.storeCode = storeCode
        self.departmentId = departmentId
        self.isArchived = isArchived
        self.customColumns = customColumns.isEmpty ? CustomColumn.defaultColumns : customColumns
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Board View Types

enum BoardViewType: String, Codable, CaseIterable, Identifiable {
    case kanban = "KANBAN"
    case table = "TABLE"
    case calendar = "CALENDAR"
    case timeline = "TIMELINE"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .kanban: return "Kanban Board"
        case .table: return "Table View"
        case .calendar: return "Calendar View"
        case .timeline: return "Timeline View"
        }
    }
    
    var icon: String {
        switch self {
        case .kanban: return "rectangle.split.3x1"
        case .table: return "tablecells"
        case .calendar: return "calendar"
        case .timeline: return "chart.bar.xaxis"
        }
    }
    
    var description: String {
        switch self {
        case .kanban: return "Visual workflow with drag-and-drop cards"
        case .table: return "Spreadsheet-style rows and columns"
        case .calendar: return "Timeline view with due dates"
        case .timeline: return "Gantt chart with dependencies"
        }
    }
}

// MARK: - Custom Columns

struct CustomColumn: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: ColumnType
    var position: Int
    var isRequired: Bool
    var options: String? // JSON string for select options, etc.
    
    init(
        id: UUID = UUID(),
        name: String,
        type: ColumnType,
        position: Int,
        isRequired: Bool = false,
        options: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.position = position
        self.isRequired = isRequired
        self.options = options
    }
    
    static let defaultColumns: [CustomColumn] = [
        CustomColumn(name: "Status", type: .status, position: 0, isRequired: true),
        CustomColumn(name: "Priority", type: .priority, position: 1, isRequired: true),
        CustomColumn(name: "Assignee", type: .user, position: 2),
        CustomColumn(name: "Due Date", type: .date, position: 3),
        CustomColumn(name: "Tags", type: .multiSelect, position: 4)
    ]
}

enum ColumnType: String, Codable, CaseIterable, Identifiable {
    case text = "TEXT"
    case number = "NUMBER"
    case date = "DATE"
    case select = "SELECT"
    case multiSelect = "MULTI_SELECT"
    case checkbox = "CHECKBOX"
    case user = "USER"
    case status = "STATUS"
    case priority = "PRIORITY"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .date: return "Date"
        case .select: return "Single Select"
        case .multiSelect: return "Multi Select"
        case .checkbox: return "Checkbox"
        case .user: return "User"
        case .status: return "Status"
        case .priority: return "Priority"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "textformat"
        case .number: return "number"
        case .date: return "calendar"
        case .select: return "list.bullet"
        case .multiSelect: return "list.bullet.below.rectangle"
        case .checkbox: return "checkmark.square"
        case .user: return "person"
        case .status: return "flag"
        case .priority: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Board Permissions

struct BoardPermission: Identifiable, Codable, Hashable {
    let id: UUID
    let boardId: UUID
    let userId: String
    var permissionLevel: PermissionLevel
    let grantedBy: String
    let grantedAt: Date
    
    init(
        id: UUID = UUID(),
        boardId: UUID,
        userId: String,
        permissionLevel: PermissionLevel,
        grantedBy: String,
        grantedAt: Date = Date()
    ) {
        self.id = id
        self.boardId = boardId
        self.userId = userId
        self.permissionLevel = permissionLevel
        self.grantedBy = grantedBy
        self.grantedAt = grantedAt
    }
}

enum PermissionLevel: String, Codable, CaseIterable, Identifiable {
    case owner = "OWNER"
    case editor = "EDITOR"
    case viewer = "VIEWER"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .editor: return "Editor"
        case .viewer: return "Viewer"
        }
    }
    
    var description: String {
        switch self {
        case .owner: return "Full control including board deletion and permission management"
        case .editor: return "Can create, edit, and manage tasks and board settings"
        case .viewer: return "Read-only access to view board and tasks"
        }
    }
    
    var icon: String {
        switch self {
        case .owner: return "crown"
        case .editor: return "pencil"
        case .viewer: return "eye"
        }
    }
    
    var color: String {
        switch self {
        case .owner: return "orange"
        case .editor: return "blue"
        case .viewer: return "gray"
        }
    }
    
    // Permission capabilities
    var canEditBoard: Bool {
        switch self {
        case .owner, .editor: return true
        case .viewer: return false
        }
    }
    
    var canManagePermissions: Bool {
        switch self {
        case .owner: return true
        case .editor, .viewer: return false
        }
    }
    
    var canDeleteBoard: Bool {
        switch self {
        case .owner: return true
        case .editor, .viewer: return false
        }
    }
    
    var canCreateTasks: Bool {
        switch self {
        case .owner, .editor: return true
        case .viewer: return false
        }
    }
    
    var canEditTasks: Bool {
        switch self {
        case .owner, .editor: return true
        case .viewer: return false
        }
    }
    
    var canDeleteTasks: Bool {
        switch self {
        case .owner, .editor: return true
        case .viewer: return false
        }
    }
}

// MARK: - CloudKit Integration

extension ProjectBoard {
    
    static let recordType = "ProjectBoard"
    
    init?(record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let name = record["name"] as? String,
            let ownerId = record["ownerId"] as? String,
            let viewTypeRaw = record["viewType"] as? String,
            let viewType = BoardViewType(rawValue: viewTypeRaw),
            let isArchived = record["isArchived"] as? Bool,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.description = record["description"] as? String
        self.ownerId = ownerId
        self.viewType = viewType
        self.storeCode = record["storeCode"] as? String
        self.departmentId = record["departmentId"] as? String
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode custom columns from JSON
        if let customColumnsData = record["customColumns"] as? Data,
           let decodedColumns = try? JSONDecoder().decode([CustomColumn].self, from: customColumnsData) {
            self.customColumns = decodedColumns
        } else {
            self.customColumns = CustomColumn.defaultColumns
        }
    }
    
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["id"] = id.uuidString
        record["name"] = name
        record["description"] = description
        record["ownerId"] = ownerId
        record["viewType"] = viewType.rawValue
        record["storeCode"] = storeCode
        record["departmentId"] = departmentId
        record["isArchived"] = isArchived
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode custom columns as JSON
        if let customColumnsData = try? JSONEncoder().encode(customColumns) {
            record["customColumns"] = customColumnsData
        }
        
        return record
    }
}

// MARK: - Board Analytics

struct BoardAnalytics: Identifiable, Codable {
    let id: UUID
    let boardId: UUID
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let tasksInProgress: Int
    let averageCompletionTime: Double // In hours
    let productivityTrend: [DailyProductivity]
    let userContributions: [UserContribution]
    let statusDistribution: [StatusCount]
    let burndownData: [BurndownPoint]
    let generatedAt: Date
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks) * 100
    }
    
    var overdueRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(overdueTasks) / Double(totalTasks) * 100
    }
}

struct DailyProductivity: Identifiable, Codable {
    let id: UUID
    let date: Date
    let tasksCompleted: Int
    let tasksCreated: Int
    let averageTime: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        tasksCompleted: Int,
        tasksCreated: Int,
        averageTime: Double
    ) {
        self.id = id
        self.date = date
        self.tasksCompleted = tasksCompleted
        self.tasksCreated = tasksCreated
        self.averageTime = averageTime
    }
}

struct UserContribution: Identifiable, Codable {
    let id: UUID
    let userId: String
    let tasksAssigned: Int
    let tasksCompleted: Int
    let averageCompletionTime: Double
    let productivityScore: Double
    
    init(
        id: UUID = UUID(),
        userId: String,
        tasksAssigned: Int,
        tasksCompleted: Int,
        averageCompletionTime: Double,
        productivityScore: Double
    ) {
        self.id = id
        self.userId = userId
        self.tasksAssigned = tasksAssigned
        self.tasksCompleted = tasksCompleted
        self.averageCompletionTime = averageCompletionTime
        self.productivityScore = productivityScore
    }
}

struct StatusCount: Identifiable, Codable {
    let id: UUID
    let status: TaskStatus
    let count: Int
    let percentage: Double
    
    init(
        id: UUID = UUID(),
        status: TaskStatus,
        count: Int,
        percentage: Double
    ) {
        self.id = id
        self.status = status
        self.count = count
        self.percentage = percentage
    }
}

struct BurndownPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let remainingTasks: Int
    let completedTasks: Int
    let projectedCompletion: Date?
    
    init(
        id: UUID = UUID(),
        date: Date,
        remainingTasks: Int,
        completedTasks: Int,
        projectedCompletion: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.remainingTasks = remainingTasks
        self.completedTasks = completedTasks
        self.projectedCompletion = projectedCompletion
    }
}
