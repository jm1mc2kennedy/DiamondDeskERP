// StoreReportModel.swift
// Diamond Desk ERP
// Domain model and CloudKit mapping for StoreReport

import Foundation
import CloudKit

struct StoreReportModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var storeCode: String
    var date: Date
    var totalSales: Double
    var totalTransactions: Int
    var totalItems: Int
    var upt: Double
    var ads: Double
    var ccpPct: Double
    var gpPct: Double
}

extension StoreReportModel {
    init?(record: CKRecord) {
        guard let storeCode = record["storeCode"] as? String,
              let date = record["date"] as? Date,
              let totalSales = record["totalSales"] as? Double,
              let totalTransactions = record["totalTransactions"] as? Int,
              let totalItems = record["totalItems"] as? Int,
              let upt = record["upt"] as? Double,
              let ads = record["ads"] as? Double,
              let ccpPct = record["ccpPct"] as? Double,
              let gpPct = record["gpPct"] as? Double
        else { return nil }
        self.id = record.recordID
        self.storeCode = storeCode
        self.date = date
        self.totalSales = totalSales
        self.totalTransactions = totalTransactions
        self.totalItems = totalItems
        self.upt = upt
        self.ads = ads
        self.ccpPct = ccpPct
        self.gpPct = gpPct
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "StoreReport", recordID: id)
        rec["storeCode"] = storeCode as CKRecordValue
        rec["date"] = date as CKRecordValue
        rec["totalSales"] = totalSales as CKRecordValue
        rec["totalTransactions"] = totalTransactions as CKRecordValue
        rec["totalItems"] = totalItems as CKRecordValue
        rec["upt"] = upt as CKRecordValue
        rec["ads"] = ads as CKRecordValue
        rec["ccpPct"] = ccpPct as CKRecordValue
        rec["gpPct"] = gpPct as CKRecordValue
        return rec
    }
}
