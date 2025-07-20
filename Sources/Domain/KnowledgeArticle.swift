import Foundation
import CloudKit

/// Represents a knowledge base article for documentation and reference
struct KnowledgeArticle: Identifiable, Hashable {
    let id: CKRecord.ID
    var title: String
    var body: String // Markdown content
    var tags: [String]
    var version: Int
    var authorRef: CKRecord.Reference
    var updatedAt: Date
    var visibilityRoles: [String] // Role-based access
    var category: String
    var isPublished: Bool
    var publishedAt: Date?
    var slug: String // URL-friendly identifier
    var viewCount: Int
    var lastViewedAt: Date?
    var createdAt: Date
    
    init?(record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let body = record["body"] as? String,
            let tags = record["tags"] as? [String],
            let version = record["version"] as? Int,
            let authorRef = record["authorRef"] as? CKRecord.Reference,
            let updatedAt = record["updatedAt"] as? Date,
            let visibilityRoles = record["visibilityRoles"] as? [String],
            let category = record["category"] as? String,
            let isPublished = record["isPublished"] as? Bool,
            let slug = record["slug"] as? String,
            let viewCount = record["viewCount"] as? Int,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.title = title
        self.body = body
        self.tags = tags
        self.version = version
        self.authorRef = authorRef
        self.updatedAt = updatedAt
        self.visibilityRoles = visibilityRoles
        self.category = category
        self.isPublished = isPublished
        self.slug = slug
        self.viewCount = viewCount
        self.createdAt = createdAt
        
        // Optional fields
        self.publishedAt = record["publishedAt"] as? Date
        self.lastViewedAt = record["lastViewedAt"] as? Date
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "KnowledgeArticle", recordID: id)
        record["title"] = title as CKRecordValue
        record["body"] = body as CKRecordValue
        record["tags"] = tags as CKRecordValue
        record["version"] = version as CKRecordValue
        record["authorRef"] = authorRef as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["visibilityRoles"] = visibilityRoles as CKRecordValue
        record["category"] = category as CKRecordValue
        record["isPublished"] = isPublished as CKRecordValue
        record["slug"] = slug as CKRecordValue
        record["viewCount"] = viewCount as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        
        if let publishedAt = publishedAt {
            record["publishedAt"] = publishedAt as CKRecordValue
        }
        if let lastViewedAt = lastViewedAt {
            record["lastViewedAt"] = lastViewedAt as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> KnowledgeArticle? {
        return KnowledgeArticle(record: record)
    }
    
    // MARK: - Factory Methods
    
    static func create(
        title: String,
        body: String,
        authorRef: CKRecord.Reference,
        category: String,
        tags: [String] = [],
        visibilityRoles: [String] = ["Admin", "AreaDirector", "StoreDirector"]
    ) -> KnowledgeArticle {
        let id = CKRecord.ID(recordName: UUID().uuidString)
        let now = Date()
        let slug = title.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        
        return KnowledgeArticle(
            id: id,
            title: title,
            body: body,
            tags: tags,
            version: 1,
            authorRef: authorRef,
            updatedAt: now,
            visibilityRoles: visibilityRoles,
            category: category,
            isPublished: false,
            publishedAt: nil,
            slug: slug,
            viewCount: 0,
            lastViewedAt: nil,
            createdAt: now
        )
    }
    
    // MARK: - Helper Methods
    
    mutating func publish() {
        isPublished = true
        publishedAt = Date()
        updatedAt = Date()
    }
    
    mutating func unpublish() {
        isPublished = false
        publishedAt = nil
        updatedAt = Date()
    }
    
    mutating func incrementViewCount() {
        viewCount += 1
        lastViewedAt = Date()
    }
    
    mutating func updateContent(title: String? = nil, body: String? = nil, tags: [String]? = nil) {
        if let title = title { self.title = title }
        if let body = body { self.body = body }
        if let tags = tags { self.tags = tags }
        
        version += 1
        updatedAt = Date()
    }
    
    var isVisible: Bool {
        return isPublished
    }
    
    var hasBeenViewed: Bool {
        return viewCount > 0
    }
}

// MARK: - Convenience Initializer

extension KnowledgeArticle {
    init(
        id: CKRecord.ID,
        title: String,
        body: String,
        tags: [String],
        version: Int,
        authorRef: CKRecord.Reference,
        updatedAt: Date,
        visibilityRoles: [String],
        category: String,
        isPublished: Bool,
        publishedAt: Date?,
        slug: String,
        viewCount: Int,
        lastViewedAt: Date?,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
        self.version = version
        self.authorRef = authorRef
        self.updatedAt = updatedAt
        self.visibilityRoles = visibilityRoles
        self.category = category
        self.isPublished = isPublished
        self.publishedAt = publishedAt
        self.slug = slug
        self.viewCount = viewCount
        self.lastViewedAt = lastViewedAt
        self.createdAt = createdAt
    }
}
