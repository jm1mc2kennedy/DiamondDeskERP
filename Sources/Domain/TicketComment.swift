import Foundation
import CloudKit

struct TicketComment: Identifiable, Hashable {
    let id: CKRecord.ID
    var ticketRef: CKRecord.Reference
    var authorRef: CKRecord.Reference
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var attachments: [String] // Asset URLs/CKAsset references
    var isEdited: Bool
    var editedAt: Date?
    var isInternal: Bool // Internal comments vs customer-facing

    init?(record: CKRecord) {
        guard
            let ticketRef = record["ticketRef"] as? CKRecord.Reference,
            let authorRef = record["authorRef"] as? CKRecord.Reference,
            let body = record["body"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date,
            let isEdited = record["isEdited"] as? Bool,
            let isInternal = record["isInternal"] as? Bool
        else {
            return nil
        }

        self.id = record.recordID
        self.ticketRef = ticketRef
        self.authorRef = authorRef
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isEdited = isEdited
        self.isInternal = isInternal
        
        // Optional fields
        self.attachments = record["attachments"] as? [String] ?? []
        self.editedAt = record["editedAt"] as? Date
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "TicketComment", recordID: id)
        record["ticketRef"] = ticketRef as CKRecordValue
        record["authorRef"] = authorRef as CKRecordValue
        record["body"] = body as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["isEdited"] = isEdited as CKRecordValue
        record["isInternal"] = isInternal as CKRecordValue
        
        if !attachments.isEmpty {
            record["attachments"] = attachments as CKRecordValue
        }
        if let editedAt = editedAt {
            record["editedAt"] = editedAt as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> TicketComment? {
        return TicketComment(record: record)
    }
    
    // MARK: - Helper Methods
    
    mutating func editComment(newBody: String) {
        body = newBody
        isEdited = true
        editedAt = Date()
        updatedAt = Date()
    }
    
    var hasAttachments: Bool {
        return !attachments.isEmpty
    }
    
    var isCustomerFacing: Bool {
        return !isInternal
    }
}
