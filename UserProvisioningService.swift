// UserProvisioningService.swift
// Diamond Desk ERP
// Fetches or creates the current User record on launch

import Foundation
import CloudKit

final class UserProvisioningService {
    static let shared = UserProvisioningService()
    private init() {}

    // Returns the current (or newly created) user ID string
    func fetchOrCreateUserId() async throws -> String {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        let userRecordID = try await container.userRecordID()
        let userId = userRecordID.recordName

        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "userId == %@", userId))
        let (results, _) = try await db.records(matching: query)
        if results.isEmpty {
            // Create new user record
            let rec = CKRecord(recordType: "User")
            rec["userId"] = userId as CKRecordValue
            rec["displayName"] = "New User" as CKRecordValue // Optionally use discoverUserIdentity
            rec["role"] = "Associate" as CKRecordValue
            rec["isActive"] = true as CKRecordValue
            rec["createdAt"] = Date() as CKRecordValue
            _ = try await db.save(rec)
        }
        return userId
    }
}
