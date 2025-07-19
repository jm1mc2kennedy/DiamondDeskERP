// TicketModel.swift
// Diamond Desk ERP
// Domain model and CloudKit mapping for Ticket

import Foundation
import CloudKit

struct TicketModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var title: String
    var description: String
    var status: String
    var storeCode: String
    var department: String
    var createdByRef: String
    var assignedUserRef: String?
    var confidentialFlags: [String]
    var createdAt: Date
}

extension TicketModel {
    init?(record: CKRecord) {
        guard let title = record["title"] as? String,
              let description = record["description"] as? String,
              let status = record["status"] as? String,
              let storeCode = record["storeCode"] as? String,
              let department = record["department"] as? String,
              let createdByRef = record["createdByRef"] as? String,
              let confidentialFlags = record["confidentialFlags"] as? [String],
              let createdAt = record["createdAt"] as? Date
        else { return nil }
        self.id = record.recordID
        self.title = title
        self.description = description
        self.status = status
        self.storeCode = storeCode
        self.department = department
        self.createdByRef = createdByRef
        self.assignedUserRef = record["assignedUserRef"] as? String
        self.confidentialFlags = confidentialFlags
        self.createdAt = createdAt
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "Ticket", recordID: id)
        rec["title"] = title as CKRecordValue
        rec["description"] = description as CKRecordValue
        rec["status"] = status as CKRecordValue
        rec["storeCode"] = storeCode as CKRecordValue
        rec["department"] = department as CKRecordValue
        rec["createdByRef"] = createdByRef as CKRecordValue
        if let assignedUserRef = assignedUserRef {
            rec["assignedUserRef"] = assignedUserRef as CKRecordValue
        } else {
            rec["assignedUserRef"] = nil
        }
        rec["confidentialFlags"] = confidentialFlags as CKRecordValue
        rec["createdAt"] = createdAt as CKRecordValue
        return rec
    }
}
