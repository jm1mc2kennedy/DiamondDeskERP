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
    let id: CKRecord.ID
    var title: String
    var description: String
    var category: String
    var status: TicketStatus
    var priority: TicketPriority
    var department: String
    var storeCodes: [String]
    var createdByRef: CKRecord.Reference
    var assignedUserRef: CKRecord.Reference?
    var watchers: [CKRecord.Reference]
    var confidentialFlags: [String]
    var slaOpenedAt: Date?
    var lastResponseAt: Date?
    var responseDeltas: [Double] // SLA metrics array
    var attachments: [String] // AssetRefs
    var createdAt: Date
    var updatedAt: Date
    
    init?(record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let description = record["description"] as? String,
            let category = record["category"] as? String,
            let statusRaw = record["status"] as? String,
            let status = TicketStatus(rawValue: statusRaw),
            let priorityRaw = record["priority"] as? String,
            let priority = TicketPriority(rawValue: priorityRaw),
            let department = record["department"] as? String,
            let storeCodes = record["storeCodes"] as? [String],
            let createdByRef = record["createdByRef"] as? CKRecord.Reference,
            let confidentialFlags = record["confidentialFlags"] as? [String],
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID
        self.title = title
        self.description = description
        self.category = category
        self.status = status
        self.priority = priority
        self.department = department
        self.storeCodes = storeCodes
        self.createdByRef = createdByRef
        self.confidentialFlags = confidentialFlags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Optional fields
        self.assignedUserRef = record["assignedUserRef"] as? CKRecord.Reference
        self.watchers = record["watchers"] as? [CKRecord.Reference] ?? []
        self.slaOpenedAt = record["slaOpenedAt"] as? Date
        self.lastResponseAt = record["lastResponseAt"] as? Date
        self.responseDeltas = record["responseDeltas"] as? [Double] ?? []
        self.attachments = record["attachments"] as? [String] ?? []
    }
    
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Ticket", recordID: id)
        
        record["title"] = title as CKRecordValue
        record["description"] = description as CKRecordValue
        record["category"] = category as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["priority"] = priority.rawValue as CKRecordValue
        record["department"] = department as CKRecordValue
        record["storeCodes"] = storeCodes as CKRecordValue
        record["createdByRef"] = createdByRef as CKRecordValue
        record["confidentialFlags"] = confidentialFlags as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        // Optional fields
        if let assignedUserRef = assignedUserRef {
            record["assignedUserRef"] = assignedUserRef as CKRecordValue
        }
        if !watchers.isEmpty {
            record["watchers"] = watchers as CKRecordValue
        }
        if let slaOpenedAt = slaOpenedAt {
            record["slaOpenedAt"] = slaOpenedAt as CKRecordValue
        }
        if let lastResponseAt = lastResponseAt {
            record["lastResponseAt"] = lastResponseAt as CKRecordValue
        }
        if !responseDeltas.isEmpty {
            record["responseDeltas"] = responseDeltas as CKRecordValue
        }
        if !attachments.isEmpty {
            record["attachments"] = attachments as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> TicketModel? {
        return TicketModel(record: record)
    }
    
    // MARK: - Computed Properties
    
    var isOverdue: Bool {
        guard let slaOpenedAt = slaOpenedAt else { return false }
        // Define SLA threshold (e.g., 24 hours for most tickets)
        let slaThreshold: TimeInterval = 24 * 60 * 60 // 24 hours
        return Date().timeIntervalSince(slaOpenedAt) > slaThreshold
    }
    
    var isConfidential: Bool {
        return confidentialFlags.contains("HR") || confidentialFlags.contains("LP")
    }
    
    var averageResponseTime: Double {
        guard !responseDeltas.isEmpty else { return 0 }
        return responseDeltas.reduce(0, +) / Double(responseDeltas.count)
    }
}
