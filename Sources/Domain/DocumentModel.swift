import Foundation
import CloudKit

/// Version history entry for document tracking
public struct DocumentVersionEntry: Codable, Identifiable {
    public let id: UUID
    public let version: Int
    public let author: CKRecord.Reference
    public let authorName: String
    public let timestamp: Date
    public let changeSummary: String
    public let changeLog: String?
    public let fileSize: Int64?
    public let checksum: String?
    
    public init(
        id: UUID = UUID(),
        version: Int,
        author: CKRecord.Reference,
        authorName: String,
        timestamp: Date = Date(),
        changeSummary: String,
        changeLog: String? = nil,
        fileSize: Int64? = nil,
        checksum: String? = nil
    ) {
        self.id = id
        self.version = version
        self.author = author
        self.authorName = authorName
        self.timestamp = timestamp
        self.changeSummary = changeSummary
        self.changeLog = changeLog
        self.fileSize = fileSize
        self.checksum = checksum
    }
}

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
    var version: Int
    var fileUrl: String? // URL to document file
    var thumbnailUrl: String? // Document thumbnail
    var fileSize: Int64 // in bytes
    var mimeType: String
    var department: String?
    var storeScope: [String]? // Stores this document applies to
    var departmentScope: [String]? // Departments this document applies to
    var accessLevel: String // public, internal, confidential, restricted
    var author: CKRecord.Reference
    var authorName: String
    var approvedBy: CKRecord.Reference?
    var approvedByName: String?
    var approvedAt: Date?
    var expiresAt: Date?
    var downloadCount: Int
    var viewCount: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var updatedBy: CKRecord.Reference
    var updatedByName: String
    var changeLog: String?
    var versionHistory: [DocumentVersionEntry]
    var checksum: String?
    var contentHash: String?
    
    init(
        id: String,
        title: String,
        description: String,
        type: DocumentType,
        status: DocumentStatus = .draft,
        category: String,
        tags: [String] = [],
        version: Int = 1,
        fileUrl: String? = nil,
        thumbnailUrl: String? = nil,
        fileSize: Int64 = 0,
        mimeType: String = "application/pdf",
        department: String? = nil,
        storeScope: [String]? = nil,
        departmentScope: [String]? = nil,
        accessLevel: String = "internal",
        author: CKRecord.Reference,
        authorName: String,
        approvedBy: CKRecord.Reference? = nil,
        approvedByName: String? = nil,
        approvedAt: Date? = nil,
        expiresAt: Date? = nil,
        downloadCount: Int = 0,
        viewCount: Int = 0,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        updatedBy: CKRecord.Reference,
        updatedByName: String,
        changeLog: String? = nil,
        versionHistory: [DocumentVersionEntry] = [],
        checksum: String? = nil,
        contentHash: String? = nil
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
        self.storeScope = storeScope
        self.departmentScope = departmentScope
        self.accessLevel = accessLevel
        self.author = author
        self.authorName = authorName
        self.approvedBy = approvedBy
        self.approvedByName = approvedByName
        self.approvedAt = approvedAt
        self.expiresAt = expiresAt
        self.downloadCount = downloadCount
        self.viewCount = viewCount
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
        self.updatedByName = updatedByName
        self.changeLog = changeLog
        self.versionHistory = versionHistory
        self.checksum = checksum
        self.contentHash = contentHash
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
            let version = record["version"] as? Int,
            let fileSize = record["fileSize"] as? Int64,
            let mimeType = record["mimeType"] as? String,
            let accessLevel = record["accessLevel"] as? String,
            let author = record["author"] as? CKRecord.Reference,
            let authorName = record["authorName"] as? String,
            let downloadCount = record["downloadCount"] as? Int,
            let viewCount = record["viewCount"] as? Int,
            let isActive = record["isActive"] as? Bool,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date,
            let updatedBy = record["updatedBy"] as? CKRecord.Reference,
            let updatedByName = record["updatedByName"] as? String
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
        self.authorName = authorName
        self.downloadCount = downloadCount
        self.viewCount = viewCount
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
        self.updatedByName = updatedByName
        
        // Optional fields
        self.tags = record["tags"] as? [String] ?? []
        self.fileUrl = record["fileUrl"] as? String
        self.thumbnailUrl = record["thumbnailUrl"] as? String
        self.department = record["department"] as? String
        self.storeScope = record["storeScope"] as? [String]
        self.departmentScope = record["departmentScope"] as? [String]
        self.approvedBy = record["approvedBy"] as? CKRecord.Reference
        self.approvedByName = record["approvedByName"] as? String
        self.approvedAt = record["approvedAt"] as? Date
        self.expiresAt = record["expiresAt"] as? Date
        self.changeLog = record["changeLog"] as? String
        self.checksum = record["checksum"] as? String
        self.contentHash = record["contentHash"] as? String
        
        // Decode version history from JSON
        if let versionHistoryData = record["versionHistory"] as? Data,
           let decodedHistory = try? JSONDecoder().decode([DocumentVersionEntry].self, from: versionHistoryData) {
            self.versionHistory = decodedHistory
        } else {
            self.versionHistory = []
        }
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
        record["author"] = author
        record["authorName"] = authorName
        record["downloadCount"] = downloadCount
        record["viewCount"] = viewCount
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["updatedBy"] = updatedBy
        record["updatedByName"] = updatedByName
        
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
        
        if let storeScope = storeScope, !storeScope.isEmpty {
            record["storeScope"] = storeScope
        }
        
        if let departmentScope = departmentScope, !departmentScope.isEmpty {
            record["departmentScope"] = departmentScope
        }
        
        if let approvedBy = approvedBy {
            record["approvedBy"] = approvedBy
        }
        
        if let approvedByName = approvedByName {
            record["approvedByName"] = approvedByName
        }
        
        if let approvedAt = approvedAt {
            record["approvedAt"] = approvedAt
        }
        
        if let expiresAt = expiresAt {
            record["expiresAt"] = expiresAt
        }
        
        if let changeLog = changeLog {
            record["changeLog"] = changeLog
        }
        
        if let checksum = checksum {
            record["checksum"] = checksum
        }
        
        if let contentHash = contentHash {
            record["contentHash"] = contentHash
        }
        
        // Encode version history as JSON
        if !versionHistory.isEmpty,
           let versionHistoryData = try? JSONEncoder().encode(versionHistory) {
            record["versionHistory"] = versionHistoryData
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
    
    var currentVersionEntry: DocumentVersionEntry? {
        return versionHistory.first { $0.version == version }
    }
    
    var latestVersion: Int {
        return versionHistory.map { $0.version }.max() ?? version
    }
    
    var hasVersionHistory: Bool {
        return !versionHistory.isEmpty
    }
    
    var sortedVersionHistory: [DocumentVersionEntry] {
        return versionHistory.sorted { $0.version > $1.version }
    }
    
    var previousVersion: DocumentVersionEntry? {
        let sorted = sortedVersionHistory
        guard sorted.count > 1 else { return nil }
        return sorted[1]
    }
    
    var isLatestVersion: Bool {
        return version == latestVersion
    }
    
    var totalViews: Int {
        return viewCount + downloadCount
    }
    
    var scopeDescription: String {
        var scopes: [String] = []
        
        if let storeScope = storeScope, !storeScope.isEmpty {
            scopes.append("Stores: \(storeScope.joined(separator: ", "))")
        }
        
        if let departmentScope = departmentScope, !departmentScope.isEmpty {
            scopes.append("Departments: \(departmentScope.joined(separator: ", "))")
        }
        
        return scopes.isEmpty ? "All locations" : scopes.joined(separator: " | ")
    }
    
    // MARK: - Version Management Methods
    
    func createNewVersion(
        updatedBy: CKRecord.Reference,
        updatedByName: String,
        changeSummary: String,
        changeLog: String? = nil,
        newFileSize: Int64? = nil,
        newChecksum: String? = nil
    ) -> Document {
        let newVersion = version + 1
        let now = Date()
        
        // Create version entry for the current state before updating
        let versionEntry = DocumentVersionEntry(
            version: version,
            author: self.updatedBy,
            authorName: self.updatedByName,
            timestamp: self.updatedAt,
            changeSummary: changeSummary,
            changeLog: changeLog,
            fileSize: newFileSize ?? self.fileSize,
            checksum: newChecksum ?? self.checksum
        )
        
        var newHistory = versionHistory
        newHistory.append(versionEntry)
        
        return Document(
            id: id,
            title: title,
            description: description,
            type: type,
            status: status,
            category: category,
            tags: tags,
            version: newVersion,
            fileUrl: fileUrl,
            thumbnailUrl: thumbnailUrl,
            fileSize: newFileSize ?? fileSize,
            mimeType: mimeType,
            department: department,
            storeScope: storeScope,
            departmentScope: departmentScope,
            accessLevel: accessLevel,
            author: author,
            authorName: authorName,
            approvedBy: approvedBy,
            approvedByName: approvedByName,
            approvedAt: approvedAt,
            expiresAt: expiresAt,
            downloadCount: downloadCount,
            viewCount: viewCount,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: now,
            updatedBy: updatedBy,
            updatedByName: updatedByName,
            changeLog: changeLog,
            versionHistory: newHistory,
            checksum: newChecksum ?? checksum,
            contentHash: contentHash
        )
    }
    
    func incrementDownloadCount() -> Document {
        return Document(
            id: id,
            title: title,
            description: description,
            type: type,
            status: status,
            category: category,
            tags: tags,
            version: version,
            fileUrl: fileUrl,
            thumbnailUrl: thumbnailUrl,
            fileSize: fileSize,
            mimeType: mimeType,
            department: department,
            storeScope: storeScope,
            departmentScope: departmentScope,
            accessLevel: accessLevel,
            author: author,
            authorName: authorName,
            approvedBy: approvedBy,
            approvedByName: approvedByName,
            approvedAt: approvedAt,
            expiresAt: expiresAt,
            downloadCount: downloadCount + 1,
            viewCount: viewCount,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date(),
            updatedBy: updatedBy,
            updatedByName: updatedByName,
            changeLog: changeLog,
            versionHistory: versionHistory,
            checksum: checksum,
            contentHash: contentHash
        )
    }
    
    func incrementViewCount() -> Document {
        return Document(
            id: id,
            title: title,
            description: description,
            type: type,
            status: status,
            category: category,
            tags: tags,
            version: version,
            fileUrl: fileUrl,
            thumbnailUrl: thumbnailUrl,
            fileSize: fileSize,
            mimeType: mimeType,
            department: department,
            storeScope: storeScope,
            departmentScope: departmentScope,
            accessLevel: accessLevel,
            author: author,
            authorName: authorName,
            approvedBy: approvedBy,
            approvedByName: approvedByName,
            approvedAt: approvedAt,
            expiresAt: expiresAt,
            downloadCount: downloadCount,
            viewCount: viewCount + 1,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date(),
            updatedBy: updatedBy,
            updatedByName: updatedByName,
            changeLog: changeLog,
            versionHistory: versionHistory,
            checksum: checksum,
            contentHash: contentHash
        )
    }
    
    func updateScope(
        storeScope: [String]? = nil,
        departmentScope: [String]? = nil,
        updatedBy: CKRecord.Reference,
        updatedByName: String
    ) -> Document {
        return Document(
            id: id,
            title: title,
            description: description,
            type: type,
            status: status,
            category: category,
            tags: tags,
            version: version,
            fileUrl: fileUrl,
            thumbnailUrl: thumbnailUrl,
            fileSize: fileSize,
            mimeType: mimeType,
            department: department,
            storeScope: storeScope ?? self.storeScope,
            departmentScope: departmentScope ?? self.departmentScope,
            accessLevel: accessLevel,
            author: author,
            authorName: authorName,
            approvedBy: approvedBy,
            approvedByName: approvedByName,
            approvedAt: approvedAt,
            expiresAt: expiresAt,
            downloadCount: downloadCount,
            viewCount: viewCount,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date(),
            updatedBy: updatedBy,
            updatedByName: updatedByName,
            changeLog: changeLog,
            versionHistory: versionHistory,
            checksum: checksum,
            contentHash: contentHash
        )
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        title: String,
        description: String,
        type: DocumentType,
        category: String,
        department: String? = nil,
        storeScope: [String]? = nil,
        departmentScope: [String]? = nil,
        accessLevel: String = "internal",
        author: CKRecord.Reference,
        authorName: String,
        tags: [String] = [],
        expiresAt: Date? = nil
    ) -> Document {
        let now = Date()
        let id = UUID().uuidString
        
        return Document(
            id: id,
            title: title,
            description: description,
            type: type,
            status: .draft,
            category: category,
            tags: tags,
            version: 1,
            fileUrl: nil,
            thumbnailUrl: nil,
            fileSize: 0,
            mimeType: "application/pdf",
            department: department,
            storeScope: storeScope,
            departmentScope: departmentScope,
            accessLevel: accessLevel,
            author: author,
            authorName: authorName,
            approvedBy: nil,
            approvedByName: nil,
            approvedAt: nil,
            expiresAt: expiresAt,
            downloadCount: 0,
            viewCount: 0,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            updatedBy: author,
            updatedByName: authorName,
            changeLog: "Initial document creation",
            versionHistory: [],
            checksum: nil,
            contentHash: nil
        )
    }
}
