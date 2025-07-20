import Foundation
import CloudKit

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case manual = "manual"
    case policy = "policy"
    case procedure = "procedure"
    case form = "form"
    case template = "template"
    case report = "report"
    case specification = "specification"
    case other = "other"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .policy: return "Policy"
        case .procedure: return "Procedure"
        case .form: return "Form"
        case .template: return "Template"
        case .report: return "Report"
        case .specification: return "Specification"
        case .other: return "Other"
        }
    }
}

enum DocumentStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "draft"
    case review = "review"
    case approved = "approved"
    case published = "published"
    case archived = "archived"
    case deprecated = "deprecated"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .review: return "Under Review"
        case .approved: return "Approved"
        case .published: return "Published"
        case .archived: return "Archived"
        case .deprecated: return "Deprecated"
        }
    }
}

struct Document: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var description: String
    var type: DocumentType
    var status: DocumentStatus
    var category: String
    var tags: [String]
    var version: String
    var fileUrl: String? // URL to document file
    var thumbnailUrl: String? // Document thumbnail
    var fileSize: Int64 // in bytes
    var mimeType: String
    var department: String?
    var accessLevel: String // public, internal, confidential, restricted
    var author: User
    var approvedBy: User?
    var approvedAt: Date?
    var expiresAt: Date?
    var downloadCount: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        title: String,
        description: String,
        type: DocumentType,
        status: DocumentStatus = .draft,
        category: String,
        tags: [String] = [],
        version: String = "1.0",
        fileUrl: String? = nil,
        thumbnailUrl: String? = nil,
        fileSize: Int64 = 0,
        mimeType: String = "application/pdf",
        department: String? = nil,
        accessLevel: String = "internal",
        author: User,
        approvedBy: User? = nil,
        approvedAt: Date? = nil,
        expiresAt: Date? = nil,
        downloadCount: Int = 0,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.status = status
        self.category = category
        self.tags = tags
        self.version = version
        self.fileUrl = fileUrl
        self.thumbnailUrl = thumbnailUrl
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.department = department
        self.accessLevel = accessLevel
        self.author = author
        self.approvedBy = approvedBy
        self.approvedAt = approvedAt
        self.expiresAt = expiresAt
        self.downloadCount = downloadCount
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // CloudKit integration
    init?(record: CKRecord) {
        guard
            let id = record["id"] as? String,
            let title = record["title"] as? String,
            let description = record["description"] as? String,
            let typeRaw = record["type"] as? String,
            let type = DocumentType(rawValue: typeRaw),
            let statusRaw = record["status"] as? String,
            let status = DocumentStatus(rawValue: statusRaw),
            let category = record["category"] as? String,
            let version = record["version"] as? String,
            let fileSize = record["fileSize"] as? Int64,
            let mimeType = record["mimeType"] as? String,
            let accessLevel = record["accessLevel"] as? String,
            let authorData = record["author"] as? Data,
            let author = try? JSONDecoder().decode(User.self, from: authorData),
            let downloadCount = record["downloadCount"] as? Int,
            let isActive = record["isActive"] as? Bool,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.status = status
        self.category = category
        self.version = version
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.accessLevel = accessLevel
        self.author = author
        self.downloadCount = downloadCount
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Optional fields
        self.tags = record["tags"] as? [String] ?? []
        self.fileUrl = record["fileUrl"] as? String
        self.thumbnailUrl = record["thumbnailUrl"] as? String
        self.department = record["department"] as? String
        
        if let approvedByData = record["approvedBy"] as? Data,
           let approvedBy = try? JSONDecoder().decode(User.self, from: approvedByData) {
            self.approvedBy = approvedBy
        } else {
            self.approvedBy = nil
        }
        
        self.approvedAt = record["approvedAt"] as? Date
        self.expiresAt = record["expiresAt"] as? Date
    }
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "Document", recordID: CKRecord.ID(recordName: id))
        
        record["id"] = id
        record["title"] = title
        record["description"] = description
        record["type"] = type.rawValue
        record["status"] = status.rawValue
        record["category"] = category
        record["version"] = version
        record["fileSize"] = fileSize
        record["mimeType"] = mimeType
        record["accessLevel"] = accessLevel
        record["author"] = try JSONEncoder().encode(author)
        record["downloadCount"] = downloadCount
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        if !tags.isEmpty {
            record["tags"] = tags
        }
        
        if let fileUrl = fileUrl {
            record["fileUrl"] = fileUrl
        }
        
        if let thumbnailUrl = thumbnailUrl {
            record["thumbnailUrl"] = thumbnailUrl
        }
        
        if let department = department {
            record["department"] = department
        }
        
        if let approvedBy = approvedBy {
            record["approvedBy"] = try JSONEncoder().encode(approvedBy)
        }
        
        if let approvedAt = approvedAt {
            record["approvedAt"] = approvedAt
        }
        
        if let expiresAt = expiresAt {
            record["expiresAt"] = expiresAt
        }
        
        return record
    }
    
    // Convenience computed properties
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var canBeDownloaded: Bool {
        return status == .published && isActive && !isExpired && fileUrl != nil
    }
}
