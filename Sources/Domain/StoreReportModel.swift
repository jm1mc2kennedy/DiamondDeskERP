import Foundation
import CloudKit

struct StoreReportModel: Identifiable {
    let id: CKRecord.ID
    let storeCode: String
    let date: Date
    let totalSales: Double
    let totalTransactions: Int
    let totalItems: Int
    let upt: Double // Units Per Transaction
    let ads: Double // Average Dollar Sale
    let ccpPct: Double // Credit Card Penetration Percentage
    let gpPct: Double // Gross Profit Percentage

    init?(record: CKRecord) {
        guard
            let storeCode = record["storeCode"] as? String,
            let date = record["date"] as? Date,
            let totalSales = record["totalSales"] as? Double,
            let totalTransactions = record["totalTransactions"] as? Int,
            let totalItems = record["totalItems"] as? Int,
            let upt = record["upt"] as? Double,
            let ads = record["ads"] as? Double,
            let ccpPct = record["ccpPct"] as? Double,
            let gpPct = record["gpPct"] as? Double
        else {
            return nil
        }

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
}
