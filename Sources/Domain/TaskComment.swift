import Foundation
import CloudKit

struct TaskComment: Identifiable, Hashable {
    let id: CKRecord.ID
    var taskRef: CKRecord.Reference
    var authorRef: CKRecord.Reference
    var body: String
    var createdAt: Date

    init?(record: CKRecord) {
        guard
            let taskRef = record["taskRef"] as? CKRecord.Reference,
            let authorRef = record["authorRef"] as? CKRecord.Reference,
            let body = record["body"] as? String,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID
        self.taskRef = taskRef
        self.authorRef = authorRef
        self.body = body
        self.createdAt = createdAt
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "TaskComment", recordID: id)
        record["taskRef"] = taskRef as CKRecordValue
        record["authorRef"] = authorRef as CKRecordValue
        record["body"] = body as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        return record
    }
    
    static func from(record: CKRecord) -> TaskComment? {
        return TaskComment(record: record)
    }
}
