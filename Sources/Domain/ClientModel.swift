import Foundation
import CloudKit

struct ClientModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var guestAcctNumber: String?
    var guestName: String
    var partnerName: String?
    var dob: Date?
    var partnerDob: Date?
    var address: String?
    var contactPreference: [String]
    var accountType: [String]
    var ringSizes: String?
    var importantDates: [String: Date]
    var jewelryPreferences: String?
    var wishList: String?
    var purchaseHistory: String?
    var contactHistory: String?
    var notes: String?
    var assignedUserRef: CKRecord.Reference
    var preferredStoreCode: String
    var createdByRef: CKRecord.Reference?
    var createdAt: Date?
    var lastInteraction: Date?

    init?(record: CKRecord) {
        guard
            let guestName = record["guestName"] as? String,
            let contactPreference = record["contactPreference"] as? [String],
            let assignedUserRef = record["assignedUserRef"] as? CKRecord.Reference,
            let preferredStoreCode = record["preferredStoreCode"] as? String,
            let accountType = record["accountType"] as? [String]
        else {
            return nil
        }

        self.id = record.recordID
        self.guestAcctNumber = record["guestAcctNumber"] as? String
        self.guestName = guestName
        self.partnerName = record["partnerName"] as? String
        self.dob = record["dob"] as? Date
        self.partnerDob = record["partnerDob"] as? Date
        self.address = record["address"] as? String
        self.contactPreference = contactPreference
        self.accountType = accountType
        self.ringSizes = record["ringSizes"] as? String
        
        // Decode JSON for complex fields
        if let importantDatesData = record["importantDates"] as? Data,
           let importantDates = try? JSONDecoder().decode([String: Date].self, from: importantDatesData) {
            self.importantDates = importantDates
        } else {
            self.importantDates = [:]
        }
        
        self.jewelryPreferences = record["jewelryPreferences"] as? String
        self.wishList = record["wishList"] as? String
        self.purchaseHistory = record["purchaseHistory"] as? String
        self.contactHistory = record["contactHistory"] as? String
        self.notes = record["notes"] as? String
        self.assignedUserRef = assignedUserRef
        self.preferredStoreCode = preferredStoreCode
        self.createdByRef = record["createdByRef"] as? CKRecord.Reference
        self.createdAt = record["createdAt"] as? Date
        self.lastInteraction = record["lastInteraction"] as? Date
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Client", recordID: id)
        
        record["guestAcctNumber"] = guestAcctNumber as CKRecordValue?
        record["guestName"] = guestName as CKRecordValue
        record["partnerName"] = partnerName as CKRecordValue?
        record["dob"] = dob as CKRecordValue?
        record["partnerDob"] = partnerDob as CKRecordValue?
        record["address"] = address as CKRecordValue?
        record["contactPreference"] = contactPreference as CKRecordValue
        record["accountType"] = accountType as CKRecordValue
        record["ringSizes"] = ringSizes as CKRecordValue?
        
        // Encode JSON for complex fields
        if let importantDatesData = try? JSONEncoder().encode(importantDates) {
            record["importantDates"] = importantDatesData as CKRecordValue
        }
        
        record["jewelryPreferences"] = jewelryPreferences as CKRecordValue?
        record["wishList"] = wishList as CKRecordValue?
        record["purchaseHistory"] = purchaseHistory as CKRecordValue?
        record["contactHistory"] = contactHistory as CKRecordValue?
        record["notes"] = notes as CKRecordValue?
        record["assignedUserRef"] = assignedUserRef as CKRecordValue
        record["preferredStoreCode"] = preferredStoreCode as CKRecordValue
        record["createdByRef"] = createdByRef as CKRecordValue?
        record["createdAt"] = createdAt as CKRecordValue?
        record["lastInteraction"] = lastInteraction as CKRecordValue?
        
        return record
    }
    
    static func from(record: CKRecord) -> ClientModel? {
        return ClientModel(record: record)
    }
}
