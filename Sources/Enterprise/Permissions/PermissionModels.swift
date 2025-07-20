import Foundation
import CloudKit

// MARK: - Unified Permissions Framework Models

/// Defines a permission or role within the system
struct Permission: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String? 
    var scopes: [String] // e.g. module names or actions
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, description: String? = nil, scopes: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.scopes = scopes
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}

extension Permission {
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "Permission", recordID: CKRecord.ID(recordName: id.uuidString))
        record["name"] = name
        record["description"] = description
        record["scopes"] = scopes
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }

    static func fromCloudKitRecord(_ record: CKRecord) -> Permission? {
        guard let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let description = record["description"] as? String
        let scopes = record["scopes"] as? [String] ?? []
        var perm = Permission(id: id, name: name, description: description, scopes: scopes)
        perm.createdAt = createdAt
        perm.updatedAt = updatedAt
        return perm
    }
}
