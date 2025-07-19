// ClientModel.swift
// Diamond Desk ERP
// Domain model and CloudKit mapping for Client

import Foundation
import CloudKit

struct ClientModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var guestAcctNumber: String
    var guestName: String
    var assignedUserRef: CKRecord.Reference?
    var storeCode: String
    var followUpDate: Date?
    var createdAt: Date
}

extension ClientModel {
    init?(record: CKRecord) {
        guard let guestAcctNumber = record["guestAcctNumber"] as? String,
              let guestName = record["guestName"] as? String,
              let storeCode = record["storeCode"] as? String,
              let createdAt = record["createdAt"] as? Date
        else { return nil }
        self.id = record.recordID
        self.guestAcctNumber = guestAcctNumber
        self.guestName = guestName
        self.assignedUserRef = record["assignedUserRef"] as? CKRecord.Reference
        self.storeCode = storeCode
        self.followUpDate = record["followUpDate"] as? Date
        self.createdAt = createdAt
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "Client", recordID: id)
        rec["guestAcctNumber"] = guestAcctNumber as CKRecordValue
        rec["guestName"] = guestName as CKRecordValue
        rec["assignedUserRef"] = assignedUserRef
        rec["storeCode"] = storeCode as CKRecordValue
        rec["followUpDate"] = followUpDate as CKRecordValue?
        rec["createdAt"] = createdAt as CKRecordValue
        return rec
    }
}
