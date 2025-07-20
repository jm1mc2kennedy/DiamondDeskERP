import Foundation
import CloudKit

enum TicketStatus: String, Codable, CaseIterable, Identifiable {
    case open = "Open"
    case inProgress = "In Progress"
    case onHold = "On Hold"
    case resolved = "Resolved"
    case closed = "Closed"

    var id: String { self.rawValue }
}

enum TicketPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var id: String { self.rawValue }
}

struct TicketModel: Identifiable, Hashable {
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
    var responseDeltas: [Double]
    var attachments: [CKRecord.Reference]
    var createdAt: Date

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
            let watchers = record["watchers"] as? [CKRecord.Reference],
            let confidentialFlags = record["confidentialFlags"] as? [String],
            let responseDeltas = record["responseDeltas"] as? [Double],
            let attachments = record["attachments"] as? [CKRecord.Reference],
            let createdAt = record["createdAt"] as? Date
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
        self.assignedUserRef = record["assignedUserRef"] as? CKRecord.Reference
        self.watchers = watchers
        self.confidentialFlags = confidentialFlags
        self.slaOpenedAt = record["slaOpenedAt"] as? Date
        self.lastResponseAt = record["lastResponseAt"] as? Date
        self.responseDeltas = responseDeltas
        self.attachments = attachments
        self.createdAt = createdAt
        self.lastResponseAt = record["lastResponseAt"] as? Date
    }
}
