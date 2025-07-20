import Foundation
import CloudKit

struct Store: Identifiable, Hashable {
    let id: CKRecord.ID
    let code: String
    let name: String
    let address: String
    let status: String
    let region: String
    let createdAt: Date

    init?(record: CKRecord) {
        guard
            let code = record["code"] as? String,
            let name = record["name"] as? String,
            let address = record["address"] as? String,
            let status = record["status"] as? String,
            let region = record["region"] as? String,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID
        self.code = code
        self.name = name
        self.address = address
        self.status = status
        self.region = region
        self.createdAt = createdAt
        self.address = address
        self.status = status
        self.region = region
    }
}
