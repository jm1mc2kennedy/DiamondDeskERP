import Foundation
import CloudKit

// MARK: - Document Management Models

/// Represents a document in the Document Management System
struct Document: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let category: String?
    let version: Int
    let assetURL: URL?
    let createdBy: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: String? = nil,
        version: Int = 1,
        assetURL: URL? = nil,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.version = version
        self.assetURL = assetURL
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// CloudKit Integration
extension Document {
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "Document", recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["category"] = category
        record["version"] = version
        record["assetURL"] = assetURL?.absoluteString
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }

    static func fromCloudKitRecord(_ record: CKRecord) -> Document? {
        guard let title = record["title"] as? String,
              let version = record["version"] as? Int,
              let createdBy = record["createdBy"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let category = record["category"] as? String
        let assetURLString = record["assetURL"] as? String
        let assetURL = assetURLString.flatMap(URL.init)
        return Document(
            id: id,
            title: title,
            category: category,
            version: version,
            assetURL: assetURL,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
