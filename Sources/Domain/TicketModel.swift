import Foundation
import CloudKit
import SwiftUI

enum TicketStatus: String, Codable, CaseIterable, Identifiable {
    case open = "open"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case resolved = "resolved"
    case closed = "closed"
    case pending = "pending"

    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .onHold: return "On Hold"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        case .pending: return "Pending"
        }
    }
}

enum TicketPriority: String, Codable, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    case critical = "critical"

    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .urgent: return .red
        case .critical: return .purple
        }
    }
}

struct TicketModel: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var description: String
    var priority: TicketPriority
    var status: TicketStatus
    var category: String
    var estimatedResolutionTime: TimeInterval
    var assignee: User?
    var reporter: User
    var watchers: [User]
    var responseDeltas: [TimeInterval]
    var attachments: [String] // Asset URLs
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        title: String,
        description: String,
        priority: TicketPriority,
        status: TicketStatus,
        category: String,
        estimatedResolutionTime: TimeInterval,
        assignee: User?,
        reporter: User,
        watchers: [User] = [],
        responseDeltas: [TimeInterval] = [],
        attachments: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.status = status
        self.category = category
        self.estimatedResolutionTime = estimatedResolutionTime
        self.assignee = assignee
        self.reporter = reporter
        self.watchers = watchers
        self.responseDeltas = responseDeltas
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // CloudKit integration
    init?(record: CKRecord) {
        guard
            let id = record["id"] as? String,
            let title = record["title"] as? String,
            let description = record["description"] as? String,
            let priorityRaw = record["priority"] as? String,
            let priority = TicketPriority(rawValue: priorityRaw),
            let statusRaw = record["status"] as? String,
            let status = TicketStatus(rawValue: statusRaw),
            let category = record["category"] as? String,
            let estimatedResolutionTime = record["estimatedResolutionTime"] as? Double,
            let reporterData = record["reporter"] as? Data,
            let reporter = try? JSONDecoder().decode(User.self, from: reporterData),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.status = status
        self.category = category
        self.estimatedResolutionTime = estimatedResolutionTime
        self.reporter = reporter
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Optional fields
        if let assigneeData = record["assignee"] as? Data,
           let assignee = try? JSONDecoder().decode(User.self, from: assigneeData) {
            self.assignee = assignee
        } else {
            self.assignee = nil
        }
        
        if let watchersData = record["watchers"] as? Data,
           let watchers = try? JSONDecoder().decode([User].self, from: watchersData) {
            self.watchers = watchers
        } else {
            self.watchers = []
        }
        
        self.responseDeltas = record["responseDeltas"] as? [Double] ?? []
        self.attachments = record["attachments"] as? [String] ?? []
    }
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "Ticket", recordID: CKRecord.ID(recordName: id))
        
        record["id"] = id
        record["title"] = title
        record["description"] = description
        record["priority"] = priority.rawValue
        record["status"] = status.rawValue
        record["category"] = category
        record["estimatedResolutionTime"] = estimatedResolutionTime
        record["reporter"] = try JSONEncoder().encode(reporter)
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        if let assignee = assignee {
            record["assignee"] = try JSONEncoder().encode(assignee)
        }
        
        if !watchers.isEmpty {
            record["watchers"] = try JSONEncoder().encode(watchers)
        }
        
        if !responseDeltas.isEmpty {
            record["responseDeltas"] = responseDeltas
        }
        
        if !attachments.isEmpty {
            record["attachments"] = attachments
        }
        
        return record
    }
}
