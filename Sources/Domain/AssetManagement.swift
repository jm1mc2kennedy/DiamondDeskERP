import Foundation
import CloudKit

// MARK: - Asset Management Models (Phase 4.12+ Implementation)

public struct Asset: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var type: AssetType
    public var category: String?
    public var tags: [String]
    public var uploadedBy: String
    public var uploadDate: Date
    public var storagePath: String
    public var accessRoles: [String]
    public var fileSize: Int64
    public var mimeType: String
    public var usageCount: Int
    public var lastAccessed: Date?
    public var metadata: AssetMetadata
    public var versions: [AssetVersion]
    public var thumbnailPath: String?
    public var isPublic: Bool
    public var expirationDate: Date?
    public var checksumHash: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: AssetType,
        category: String? = nil,
        tags: [String] = [],
        uploadedBy: String,
        uploadDate: Date = Date(),
        storagePath: String,
        accessRoles: [String] = [],
        fileSize: Int64,
        mimeType: String,
        usageCount: Int = 0,
        lastAccessed: Date? = nil,
        metadata: AssetMetadata = AssetMetadata(),
        versions: [AssetVersion] = [],
        thumbnailPath: String? = nil,
        isPublic: Bool = false,
        expirationDate: Date? = nil,
        checksumHash: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.tags = tags
        self.uploadedBy = uploadedBy
        self.uploadDate = uploadDate
        self.storagePath = storagePath
        self.accessRoles = accessRoles
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.usageCount = usageCount
        self.lastAccessed = lastAccessed
        self.metadata = metadata
        self.versions = versions
        self.thumbnailPath = thumbnailPath
        self.isPublic = isPublic
        self.expirationDate = expirationDate
        self.checksumHash = checksumHash
    }
}

public enum AssetType: String, CaseIterable, Codable, Identifiable {
    case image = "IMAGE"
    case document = "DOCUMENT"
    case video = "VIDEO"
    case audio = "AUDIO"
    case archive = "ARCHIVE"
    case spreadsheet = "SPREADSHEET"
    case presentation = "PRESENTATION"
    case code = "CODE"
    case other = "OTHER"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .image: return "Image"
        case .document: return "Document"
        case .video: return "Video"
        case .audio: return "Audio"
        case .archive: return "Archive"
        case .spreadsheet: return "Spreadsheet"
        case .presentation: return "Presentation"
        case .code: return "Code"
        case .other: return "Other"
        }
    }
    
    public var allowedMimeTypes: [String] {
        switch self {
        case .image:
            return ["image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"]
        case .document:
            return ["application/pdf", "text/plain", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
        case .video:
            return ["video/mp4", "video/avi", "video/mov", "video/wmv", "video/webm"]
        case .audio:
            return ["audio/mp3", "audio/wav", "audio/ogg", "audio/aac", "audio/flac"]
        case .archive:
            return ["application/zip", "application/x-tar", "application/gzip", "application/x-rar-compressed"]
        case .spreadsheet:
            return ["application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "text/csv"]
        case .presentation:
            return ["application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation"]
        case .code:
            return ["text/plain", "application/json", "application/xml", "text/html", "text/css", "application/javascript"]
        case .other:
            return []
        }
    }
}

public struct AssetMetadata: Codable, Hashable {
    public var width: Int?
    public var height: Int?
    public var duration: TimeInterval?
    public var frameRate: Double?
    public var bitRate: Int64?
    public var colorSpace: String?
    public var compressionType: String?
    public var customProperties: [String: String]
    
    public init(
        width: Int? = nil,
        height: Int? = nil,
        duration: TimeInterval? = nil,
        frameRate: Double? = nil,
        bitRate: Int64? = nil,
        colorSpace: String? = nil,
        compressionType: String? = nil,
        customProperties: [String: String] = [:]
    ) {
        self.width = width
        self.height = height
        self.duration = duration
        self.frameRate = frameRate
        self.bitRate = bitRate
        self.colorSpace = colorSpace
        self.compressionType = compressionType
        self.customProperties = customProperties
    }
}

public struct AssetVersion: Identifiable, Codable, Hashable {
    public let id: String
    public var version: Int
    public var uploadedBy: String
    public var uploadDate: Date
    public var fileSize: Int64
    public var storagePath: String
    public var changeDescription: String?
    public var checksumHash: String?
    
    public init(
        id: String = UUID().uuidString,
        version: Int,
        uploadedBy: String,
        uploadDate: Date = Date(),
        fileSize: Int64,
        storagePath: String,
        changeDescription: String? = nil,
        checksumHash: String? = nil
    ) {
        self.id = id
        self.version = version
        self.uploadedBy = uploadedBy
        self.uploadDate = uploadDate
        self.fileSize = fileSize
        self.storagePath = storagePath
        self.changeDescription = changeDescription
        self.checksumHash = checksumHash
    }
}

public struct AssetCategory: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var parentId: String?
    public var description: String?
    public var color: String
    public var icon: String?
    public var sortOrder: Int
    public var isSystemCategory: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        parentId: String? = nil,
        description: String? = nil,
        color: String = "#007AFF",
        icon: String? = nil,
        sortOrder: Int = 0,
        isSystemCategory: Bool = false
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.description = description
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.isSystemCategory = isSystemCategory
    }
}

public struct AssetTag: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var color: String
    public var description: String?
    public var usageCount: Int
    public var createdBy: String
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        color: String = "#007AFF",
        description: String? = nil,
        usageCount: Int = 0,
        createdBy: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.description = description
        self.usageCount = usageCount
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

public struct AssetUsageLog: Identifiable, Codable, Hashable {
    public let id: String
    public var assetId: String
    public var userId: String
    public var action: AssetAction
    public var timestamp: Date
    public var context: String?
    public var ipAddress: String?
    public var userAgent: String?
    public var sessionId: String?
    
    public init(
        id: String = UUID().uuidString,
        assetId: String,
        userId: String,
        action: AssetAction,
        timestamp: Date = Date(),
        context: String? = nil,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        sessionId: String? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.userId = userId
        self.action = action
        self.timestamp = timestamp
        self.context = context
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.sessionId = sessionId
    }
}

public enum AssetAction: String, CaseIterable, Codable, Identifiable {
    case viewed = "VIEWED"
    case downloaded = "DOWNLOADED"
    case uploaded = "UPLOADED"
    case updated = "UPDATED"
    case deleted = "DELETED"
    case shared = "SHARED"
    case copied = "COPIED"
    case moved = "MOVED"
    case renamed = "RENAMED"
    case tagged = "TAGGED"
    case untagged = "UNTAGGED"
    case versionCreated = "VERSION_CREATED"
    case permissionChanged = "PERMISSION_CHANGED"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .viewed: return "Viewed"
        case .downloaded: return "Downloaded"
        case .uploaded: return "Uploaded"
        case .updated: return "Updated"
        case .deleted: return "Deleted"
        case .shared: return "Shared"
        case .copied: return "Copied"
        case .moved: return "Moved"
        case .renamed: return "Renamed"
        case .tagged: return "Tagged"
        case .untagged: return "Untagged"
        case .versionCreated: return "Version Created"
        case .permissionChanged: return "Permission Changed"
        }
    }
}

public struct AssetSearchFilter: Codable, Hashable {
    public var name: String?
    public var type: AssetType?
    public var category: String?
    public var tags: [String]
    public var uploadedBy: String?
    public var uploadDateRange: DateInterval?
    public var fileSizeRange: ClosedRange<Int64>?
    public var mimeTypes: [String]
    public var accessRoles: [String]
    public var isPublic: Bool?
    
    public init(
        name: String? = nil,
        type: AssetType? = nil,
        category: String? = nil,
        tags: [String] = [],
        uploadedBy: String? = nil,
        uploadDateRange: DateInterval? = nil,
        fileSizeRange: ClosedRange<Int64>? = nil,
        mimeTypes: [String] = [],
        accessRoles: [String] = [],
        isPublic: Bool? = nil
    ) {
        self.name = name
        self.type = type
        self.category = category
        self.tags = tags
        self.uploadedBy = uploadedBy
        self.uploadDateRange = uploadDateRange
        self.fileSizeRange = fileSizeRange
        self.mimeTypes = mimeTypes
        self.accessRoles = accessRoles
        self.isPublic = isPublic
    }
}

// MARK: - Asset Collection Management
public struct AssetCollection: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var ownerId: String
    public var assetIds: [String]
    public var isPublic: Bool
    public var sharedWith: [String]
    public var tags: [String]
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        ownerId: String,
        assetIds: [String] = [],
        isPublic: Bool = false,
        sharedWith: [String] = [],
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.assetIds = assetIds
        self.isPublic = isPublic
        self.sharedWith = sharedWith
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - CloudKit Extensions
extension Asset {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Asset", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["type"] = type.rawValue
        record["category"] = category
        record["tags"] = tags
        record["uploadedBy"] = uploadedBy
        record["uploadDate"] = uploadDate
        record["storagePath"] = storagePath
        record["accessRoles"] = accessRoles
        record["fileSize"] = fileSize
        record["mimeType"] = mimeType
        record["usageCount"] = usageCount
        record["lastAccessed"] = lastAccessed
        record["thumbnailPath"] = thumbnailPath
        record["isPublic"] = isPublic
        record["expirationDate"] = expirationDate
        record["checksumHash"] = checksumHash
        
        // Encode complex objects as Data
        if let metadataData = try? JSONEncoder().encode(metadata) {
            record["metadata"] = metadataData
        }
        if let versionsData = try? JSONEncoder().encode(versions) {
            record["versions"] = versionsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> Asset? {
        guard let name = record["name"] as? String,
              let typeString = record["type"] as? String,
              let type = AssetType(rawValue: typeString),
              let uploadedBy = record["uploadedBy"] as? String,
              let uploadDate = record["uploadDate"] as? Date,
              let storagePath = record["storagePath"] as? String,
              let fileSize = record["fileSize"] as? Int64,
              let mimeType = record["mimeType"] as? String,
              let usageCount = record["usageCount"] as? Int,
              let isPublic = record["isPublic"] as? Bool else {
            return nil
        }
        
        let category = record["category"] as? String
        let tags = record["tags"] as? [String] ?? []
        let accessRoles = record["accessRoles"] as? [String] ?? []
        let lastAccessed = record["lastAccessed"] as? Date
        let thumbnailPath = record["thumbnailPath"] as? String
        let expirationDate = record["expirationDate"] as? Date
        let checksumHash = record["checksumHash"] as? String
        
        // Decode complex objects
        var metadata = AssetMetadata()
        if let metadataData = record["metadata"] as? Data {
            metadata = (try? JSONDecoder().decode(AssetMetadata.self, from: metadataData)) ?? AssetMetadata()
        }
        
        var versions: [AssetVersion] = []
        if let versionsData = record["versions"] as? Data {
            versions = (try? JSONDecoder().decode([AssetVersion].self, from: versionsData)) ?? []
        }
        
        return Asset(
            id: record.recordID.recordName,
            name: name,
            type: type,
            category: category,
            tags: tags,
            uploadedBy: uploadedBy,
            uploadDate: uploadDate,
            storagePath: storagePath,
            accessRoles: accessRoles,
            fileSize: fileSize,
            mimeType: mimeType,
            usageCount: usageCount,
            lastAccessed: lastAccessed,
            metadata: metadata,
            versions: versions,
            thumbnailPath: thumbnailPath,
            isPublic: isPublic,
            expirationDate: expirationDate,
            checksumHash: checksumHash
        )
    }
}

extension AssetUsageLog {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AssetUsageLog", recordID: CKRecord.ID(recordName: id))
        record["assetId"] = assetId
        record["userId"] = userId
        record["action"] = action.rawValue
        record["timestamp"] = timestamp
        record["context"] = context
        record["ipAddress"] = ipAddress
        record["userAgent"] = userAgent
        record["sessionId"] = sessionId
        return record
    }
    
    public static func from(record: CKRecord) -> AssetUsageLog? {
        guard let assetId = record["assetId"] as? String,
              let userId = record["userId"] as? String,
              let actionString = record["action"] as? String,
              let action = AssetAction(rawValue: actionString),
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }
        
        let context = record["context"] as? String
        let ipAddress = record["ipAddress"] as? String
        let userAgent = record["userAgent"] as? String
        let sessionId = record["sessionId"] as? String
        
        return AssetUsageLog(
            id: record.recordID.recordName,
            assetId: assetId,
            userId: userId,
            action: action,
            timestamp: timestamp,
            context: context,
            ipAddress: ipAddress,
            userAgent: userAgent,
            sessionId: sessionId
        )
    }
}
