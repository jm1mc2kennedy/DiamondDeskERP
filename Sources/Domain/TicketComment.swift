import Foundation
import CloudKit

struct TicketComment: Identifiable, Hashable {
    let id: CKRecord.ID
    var ticketRef: CKRecord.Reference
    var authorRef: CKRecord.Reference
    var body: String
    var createdAt: Date
    var attachments: [CKRecord.Reference]

    init?(record: CKRecord) {
        guard
            let ticketRef = record["ticketRef"] as? CKRecord.Reference,
            let authorRef = record["authorRef"] as? CKRecord.Reference,
            let body = record["body"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let attachments = record["attachments"] as? [CKRecord.Reference]
        else {
            return nil
        }

        self.id = record.recordID
        self.ticketRef = ticketRef
        self.authorRef = authorRef
        self.body = body
        self.createdAt = createdAt
        self.attachments = attachments
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "TicketComment", recordID: id)
        record["ticketRef"] = ticketRef as CKRecordValue
        record["authorRef"] = authorRef as CKRecordValue
        record["body"] = body as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["attachments"] = attachments as CKRecordValue
        return record
    }
    
    static func from(record: CKRecord) -> TicketComment? {
        return TicketComment(record: record)
    }
}
