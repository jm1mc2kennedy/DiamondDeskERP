import Foundation
import CloudKit

/// Represents an individual message within a conversation thread
struct Message: Identifiable, Hashable {
    let id: CKRecord.ID
    var threadRef: CKRecord.Reference
    var authorRef: CKRecord.Reference
    var body: String
    var sentAt: Date
    var readBy: [String] // User IDs who have read this message
    var messageType: MessageType
    var attachments: [String] // Asset URLs
    var isEdited: Bool
    var editedAt: Date?
    var replyToMessageId: String? // For threading replies
    
    enum MessageType: String, Codable, CaseIterable {
        case text = "text"
        case image = "image"
        case file = "file"
        case system = "system" // System announcements
    }
    
    init?(record: CKRecord) {
        guard
            let threadRef = record["threadRef"] as? CKRecord.Reference,
            let authorRef = record["authorRef"] as? CKRecord.Reference,
            let body = record["body"] as? String,
            let sentAt = record["sentAt"] as? Date,
            let readBy = record["readBy"] as? [String],
            let messageTypeRaw = record["messageType"] as? String,
            let messageType = MessageType(rawValue: messageTypeRaw),
            let isEdited = record["isEdited"] as? Bool
        else {
            return nil
        }
        
        self.id = record.recordID
        self.threadRef = threadRef
        self.authorRef = authorRef
        self.body = body
        self.sentAt = sentAt
        self.readBy = readBy
        self.messageType = messageType
        self.isEdited = isEdited
        
        // Optional fields
        self.attachments = record["attachments"] as? [String] ?? []
        self.editedAt = record["editedAt"] as? Date
        self.replyToMessageId = record["replyToMessageId"] as? String
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Message", recordID: id)
        record["threadRef"] = threadRef as CKRecordValue
        record["authorRef"] = authorRef as CKRecordValue
        record["body"] = body as CKRecordValue
        record["sentAt"] = sentAt as CKRecordValue
        record["readBy"] = readBy as CKRecordValue
        record["messageType"] = messageType.rawValue as CKRecordValue
        record["isEdited"] = isEdited as CKRecordValue
        
        if !attachments.isEmpty {
            record["attachments"] = attachments as CKRecordValue
        }
        if let editedAt = editedAt {
            record["editedAt"] = editedAt as CKRecordValue
        }
        if let replyToMessageId = replyToMessageId {
            record["replyToMessageId"] = replyToMessageId as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> Message? {
        return Message(record: record)
    }
    
    // MARK: - Factory Methods
    
    static func create(
        threadRef: CKRecord.Reference,
        authorRef: CKRecord.Reference,
        body: String,
        messageType: MessageType = .text,
        replyToMessageId: String? = nil
    ) -> Message {
        let id = CKRecord.ID(recordName: UUID().uuidString)
        
        return Message(
            id: id,
            threadRef: threadRef,
            authorRef: authorRef,
            body: body,
            sentAt: Date(),
            readBy: [], // Will be populated as users read
            messageType: messageType,
            attachments: [],
            isEdited: false,
            editedAt: nil,
            replyToMessageId: replyToMessageId
        )
    }
    
    // MARK: - Helper Methods
    
    mutating func markAsRead(by userId: String) {
        if !readBy.contains(userId) {
            readBy.append(userId)
        }
    }
    
    mutating func editMessage(newBody: String) {
        body = newBody
        isEdited = true
        editedAt = Date()
    }
    
    var isReply: Bool {
        return replyToMessageId != nil
    }
    
    var hasAttachments: Bool {
        return !attachments.isEmpty
    }
}

// MARK: - Convenience Initializer

extension Message {
    init(
        id: CKRecord.ID,
        threadRef: CKRecord.Reference,
        authorRef: CKRecord.Reference,
        body: String,
        sentAt: Date,
        readBy: [String],
        messageType: MessageType,
        attachments: [String],
        isEdited: Bool,
        editedAt: Date?,
        replyToMessageId: String?
    ) {
        self.id = id
        self.threadRef = threadRef
        self.authorRef = authorRef
        self.body = body
        self.sentAt = sentAt
        self.readBy = readBy
        self.messageType = messageType
        self.attachments = attachments
        self.isEdited = isEdited
        self.editedAt = editedAt
        self.replyToMessageId = replyToMessageId
    }
}
