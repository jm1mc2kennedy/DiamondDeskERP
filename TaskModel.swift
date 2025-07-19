// TaskModel.swift
// Diamond Desk ERP
// Domain model and CloudKit mapping for Task

import Foundation
import CloudKit

struct TaskModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var title: String
    var detail: String
    var dueDate: Date
    var status: String
    var isGroupTask: Bool
    var assignedUserRefs: [String]
    var completedUserRefs: [String]
    var storeCodes: [String]
    var departments: [String]
    var createdByRef: String
    var createdAt: Date
    var requiresAck: Bool
    var ackUserRefs: [String]
}

extension TaskModel {
    init?(record: CKRecord) {
        guard let title = record["title"] as? String,
              let dueDate = record["dueDate"] as? Date,
              let status = record["status"] as? String,
              let isGroupTask = record["isGroupTask"] as? Bool,
              let assignedUserRefs = record["assignedUserRefs"] as? [String],
              let completedUserRefs = record["completedUserRefs"] as? [String],
              let storeCodes = record["storeCodes"] as? [String],
              let departments = record["departments"] as? [String],
              let createdByRef = record["createdByRef"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let requiresAck = record["requiresAck"] as? Bool,
              let ackUserRefs = record["ackUserRefs"] as? [String]
        else { return nil }
        self.id = record.recordID
        self.title = title
        self.detail = record["detail"] as? String ?? ""
        self.dueDate = dueDate
        self.status = status
        self.isGroupTask = isGroupTask
        self.assignedUserRefs = assignedUserRefs
        self.completedUserRefs = completedUserRefs
        self.storeCodes = storeCodes
        self.departments = departments
        self.createdByRef = createdByRef
        self.createdAt = createdAt
        self.requiresAck = requiresAck
        self.ackUserRefs = ackUserRefs
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "Task", recordID: id)
        rec["title"] = title as CKRecordValue
        rec["detail"] = detail as CKRecordValue
        rec["dueDate"] = dueDate as CKRecordValue
        rec["status"] = status as CKRecordValue
        rec["isGroupTask"] = isGroupTask as CKRecordValue
        rec["assignedUserRefs"] = assignedUserRefs as CKRecordValue
        rec["completedUserRefs"] = completedUserRefs as CKRecordValue
        rec["storeCodes"] = storeCodes as CKRecordValue
        rec["departments"] = departments as CKRecordValue
        rec["createdByRef"] = createdByRef as CKRecordValue
        rec["createdAt"] = createdAt as CKRecordValue
        rec["requiresAck"] = requiresAck as CKRecordValue
        rec["ackUserRefs"] = ackUserRefs as CKRecordValue
        return rec
    }
}
