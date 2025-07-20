// KPIModel.swift
// Diamond Desk ERP
// Domain model and CloudKit mapping for KPI (KPIRecord)

import Foundation
import CloudKit

struct KPIModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var date: Date
    var storeCode: String
    var metrics: [String: Double]
}

extension KPIModel {
    init?(record: CKRecord) {
        guard let date = record["date"] as? Date,
              let storeCode = record["storeCode"] as? String,
              let metricsData = record["metrics"] as? Data,
              let metrics = try? JSONDecoder().decode([String: Double].self, from: metricsData)
        else { return nil }
        self.id = record.recordID
        self.date = date
        self.storeCode = storeCode
        self.metrics = metrics
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "KPIRecord", recordID: id)
        rec["date"] = date as CKRecordValue
        rec["storeCode"] = storeCode as CKRecordValue
        let metricsData = try? JSONEncoder().encode(metrics)
        rec["metrics"] = metricsData as CKRecordValue?
        return rec
    }
}
