import Foundation
import CloudKit

/// Represents a conversation thread between multiple participants
struct MessageThread: Identifiable, Hashable {
    let id: CKRecord.ID
    var participants: [CKRecord.Reference] // User references
    var title: String?
    var category: String
    var lastMessageAt: Date
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var lastMessagePreview: String?
    
    init?(record: CKRecord) {
        guard
            let participants = record["participants"] as? [CKRecord.Reference],
            let category = record["category"] as? String,
            let lastMessageAt = record["lastMessageAt"] as? Date,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date,
            let isArchived = record["isArchived"] as? Bool
        else {
            return nil
        }
        
        self.id = record.recordID
        self.participants = participants
        self.category = category
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        
        // Optional fields
        self.title = record["title"] as? String
        self.lastMessagePreview = record["lastMessagePreview"] as? String
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "MessageThread", recordID: id)
        record["participants"] = participants as CKRecordValue
        record["category"] = category as CKRecordValue
        record["lastMessageAt"] = lastMessageAt as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["isArchived"] = isArchived as CKRecordValue
        
        if let title = title {
            record["title"] = title as CKRecordValue
        }
        if let lastMessagePreview = lastMessagePreview {
            record["lastMessagePreview"] = lastMessagePreview as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> MessageThread? {
        return MessageThread(record: record)
    }
    
    // MARK: - Factory Methods
    
    static func create(
        participants: [CKRecord.Reference],
        title: String? = nil,
        category: String = "general"
    ) -> MessageThread {
        let id = CKRecord.ID(recordName: UUID().uuidString)
        let now = Date()
        
        return MessageThread(
            id: id,
            participants: participants,
            title: title,
            category: category,
            lastMessageAt: now,
            createdAt: now,
            updatedAt: now,
            isArchived: false,
            lastMessagePreview: nil
        )
    }
    
    // MARK: - Computed Properties
    
    var participantCount: Int {
        return participants.count
    }
    
    var isGroupThread: Bool {
        return participants.count > 2
    }
}

// MARK: - Convenience Initializer

extension MessageThread {
    init(
        id: CKRecord.ID,
        participants: [CKRecord.Reference],
        title: String?,
        category: String,
        lastMessageAt: Date,
        createdAt: Date,
        updatedAt: Date,
        isArchived: Bool,
        lastMessagePreview: String?
    ) {
        self.id = id
        self.participants = participants
        self.title = title
        self.category = category
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.lastMessagePreview = lastMessagePreview
    }
}
