//
//  DocumentModel.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

/// Core document model for the Enterprise Document Management System
/// Provides comprehensive document metadata, versioning, and access control
struct DocumentModel: Identifiable, Codable, Hashable {
    
    // MARK: - Core Properties
    
    let id: CKRecord.ID
    var title: String
    var fileName: String
    var fileType: DocumentFileType
    var fileSize: Int64
    var mimeType: String
    
    // MARK: - Version Control
    
    var version: String
    var versionNumber: Int
    var isLatestVersion: Bool
    var parentDocumentId: String?
    var versionHistory: [DocumentVersionSummary]
    
    // MARK: - Metadata
    
    var description: String?
    var tags: [String]
    var category: DocumentCategory
    var language: String
    
    // MARK: - Access Control
    
    var accessLevel: DocumentAccessLevel
    var departmentRestrictions: [String]
    var roleRestrictions: [String]
    var locationRestrictions: [String]
    var ownerUserId: String
    var collaboratorUserIds: [String]
    
    // MARK: - File References
    
    var documentAssetRecordName: String?
    var thumbnailAssetRecordName: String?
    var documentPath: String
    var thumbnailPath: String?
    
    // MARK: - Status & Workflow
    
    var status: DocumentStatus
    var approvalStatus: DocumentApprovalStatus
    var workflowStage: String?
    var approvalRequired: Bool
    var approvalChain: [DocumentApprovalStep]
    
    // MARK: - Checkout & Collaboration
    
    var checkedOutBy: String?
    var checkedOutAt: Date?
    var lockExpiration: Date?
    var allowConcurrentEditing: Bool
    
    // MARK: - Retention & Compliance
    
    var retentionPolicy: DocumentRetentionPolicy
    var retentionDate: Date?
    var complianceFlags: [String]
    var legalHoldFlag: Bool
    var encryptionRequired: Bool
    
    // MARK: - Timestamps & Audit
    
    var createdBy: String
    var createdAt: Date
    var modifiedBy: String
    var modifiedAt: Date
    var lastAccessedAt: Date?
    var lastAccessedBy: String?
    
    // MARK: - Search & Discovery
    
    var searchableContent: String?
    var documentHash: String?
    var ocrExtractedText: String?
    var aiGeneratedSummary: String?
    
    // MARK: - Integration
    
    var externalSystemId: String?
    var sourceApplication: String?
    var migrationMetadata: [String: String]?
    
    // MARK: - Initializer
    
    init(
        id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
        title: String,
        fileName: String,
        fileType: DocumentFileType,
        fileSize: Int64,
        mimeType: String,
        category: DocumentCategory = .general,
        accessLevel: DocumentAccessLevel = .internal,
        ownerUserId: String,
        createdBy: String
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.fileType = fileType
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.version = "1.0"
        self.versionNumber = 1
        self.isLatestVersion = true
        self.parentDocumentId = nil
        self.versionHistory = []
        
        self.description = nil
        self.tags = []
        self.category = category
        self.language = "en"
        
        self.accessLevel = accessLevel
        self.departmentRestrictions = []
        self.roleRestrictions = []
        self.locationRestrictions = []
        self.ownerUserId = ownerUserId
        self.collaboratorUserIds = []
        
        self.documentAssetRecordName = nil
        self.thumbnailAssetRecordName = nil
        self.documentPath = ""
        self.thumbnailPath = nil
        
        self.status = .active
        self.approvalStatus = .approved
        self.workflowStage = nil
        self.approvalRequired = false
        self.approvalChain = []
        
        self.checkedOutBy = nil
        self.checkedOutAt = nil
        self.lockExpiration = nil
        self.allowConcurrentEditing = true
        
        self.retentionPolicy = .standard
        self.retentionDate = nil
        self.complianceFlags = []
        self.legalHoldFlag = false
        self.encryptionRequired = false
        
        self.createdBy = createdBy
        self.createdAt = Date()
        self.modifiedBy = createdBy
        self.modifiedAt = Date()
        self.lastAccessedAt = nil
        self.lastAccessedBy = nil
        
        self.searchableContent = nil
        self.documentHash = nil
        self.ocrExtractedText = nil
        self.aiGeneratedSummary = nil
        
        self.externalSystemId = nil
        self.sourceApplication = nil
        self.migrationMetadata = nil
    }
}

// MARK: - Document File Type

enum DocumentFileType: String, CaseIterable, Codable {
    case pdf = "PDF"
    case word = "WORD"
    case excel = "EXCEL"
    case powerpoint = "POWERPOINT"
    case text = "TEXT"
    case markdown = "MARKDOWN"
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case archive = "ARCHIVE"
    case code = "CODE"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF Document"
        case .word: return "Word Document"
        case .excel: return "Excel Spreadsheet"
        case .powerpoint: return "PowerPoint Presentation"
        case .text: return "Text Document"
        case .markdown: return "Markdown Document"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .archive: return "Archive"
        case .code: return "Source Code"
        case .other: return "Other"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pdf: return "doc.text.fill"
        case .word: return "doc.text"
        case .excel: return "tablecells"
        case .powerpoint: return "rectangle.stack.fill"
        case .text: return "doc.plaintext"
        case .markdown: return "doc.richtext"
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .archive: return "archivebox"
        case .code: return "curlybraces"
        case .other: return "doc"
        }
    }
    
    static func from(mimeType: String) -> DocumentFileType {
        switch mimeType.lowercased() {
        case "application/pdf":
            return .pdf
        case let type where type.contains("word") || type.contains("msword"):
            return .word
        case let type where type.contains("excel") || type.contains("sheet"):
            return .excel
        case let type where type.contains("powerpoint") || type.contains("presentation"):
            return .powerpoint
        case let type where type.hasPrefix("text/"):
            return .text
        case let type where type.hasPrefix("image/"):
            return .image
        case let type where type.hasPrefix("video/"):
            return .video
        case let type where type.hasPrefix("audio/"):
            return .audio
        case let type where type.contains("zip") || type.contains("archive"):
            return .archive
        default:
            return .other
        }
    }
}

// MARK: - Document Category

enum DocumentCategory: String, CaseIterable, Codable {
    case general = "GENERAL"
    case policy = "POLICY"
    case procedure = "PROCEDURE"
    case training = "TRAINING"
    case compliance = "COMPLIANCE"
    case hr = "HR"
    case finance = "FINANCE"
    case marketing = "MARKETING"
    case operations = "OPERATIONS"
    case audit = "AUDIT"
    case contract = "CONTRACT"
    case report = "REPORT"
    case template = "TEMPLATE"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .policy: return "Policy"
        case .procedure: return "Procedure"
        case .training: return "Training"
        case .compliance: return "Compliance"
        case .hr: return "Human Resources"
        case .finance: return "Finance"
        case .marketing: return "Marketing"
        case .operations: return "Operations"
        case .audit: return "Audit"
        case .contract: return "Contract"
        case .report: return "Report"
        case .template: return "Template"
        }
    }
    
    var systemImage: String {
        switch self {
        case .general: return "folder"
        case .policy: return "shield.checkered"
        case .procedure: return "list.clipboard"
        case .training: return "graduationcap"
        case .compliance: return "checkmark.seal"
        case .hr: return "person.2"
        case .finance: return "dollarsign.circle"
        case .marketing: return "megaphone"
        case .operations: return "gearshape.2"
        case .audit: return "magnifyingglass"
        case .contract: return "doc.text.magnifyingglass"
        case .report: return "chart.bar.doc.horizontal"
        case .template: return "doc.badge.plus"
        }
    }
}

// MARK: - Document Access Level

enum DocumentAccessLevel: String, CaseIterable, Codable {
    case `public` = "PUBLIC"
    case `internal` = "INTERNAL"
    case confidential = "CONFIDENTIAL"
    case restricted = "RESTRICTED"
    case topSecret = "TOP_SECRET"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .internal: return "Internal"
        case .confidential: return "Confidential"
        case .restricted: return "Restricted"
        case .topSecret: return "Top Secret"
        }
    }
    
    var color: String {
        switch self {
        case .public: return "green"
        case .internal: return "blue"
        case .confidential: return "orange"
        case .restricted: return "red"
        case .topSecret: return "purple"
        }
    }
    
    var requiresSpecialHandling: Bool {
        return self == .restricted || self == .topSecret
    }
}

// MARK: - Document Status

enum DocumentStatus: String, CaseIterable, Codable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case archived = "ARCHIVED"
    case deprecated = "DEPRECATED"
    case deleted = "DELETED"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .archived: return "Archived"
        case .deprecated: return "Deprecated"
        case .deleted: return "Deleted"
        }
    }
    
    var systemImage: String {
        switch self {
        case .draft: return "pencil.circle"
        case .active: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        case .deprecated: return "exclamationmark.triangle"
        case .deleted: return "trash"
        }
    }
}

// MARK: - Document Approval Status

enum DocumentApprovalStatus: String, CaseIterable, Codable {
    case draft = "DRAFT"
    case pendingReview = "PENDING_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case revisionRequired = "REVISION_REQUIRED"
    case withdrawn = "WITHDRAWN"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .pendingReview: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .revisionRequired: return "Revision Required"
        case .withdrawn: return "Withdrawn"
        }
    }
    
    var systemImage: String {
        switch self {
        case .draft: return "pencil.circle"
        case .pendingReview: return "clock.circle"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .revisionRequired: return "arrow.clockwise.circle"
        case .withdrawn: return "minus.circle"
        }
    }
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .pendingReview: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .revisionRequired: return "yellow"
        case .withdrawn: return "gray"
        }
    }
}

// MARK: - Document Retention Policy

enum DocumentRetentionPolicy: String, CaseIterable, Codable {
    case standard = "STANDARD"       // 7 years
    case short = "SHORT"             // 1 year
    case medium = "MEDIUM"           // 3 years
    case long = "LONG"               // 10 years
    case permanent = "PERMANENT"     // Never delete
    case custom = "CUSTOM"           // Custom retention period
    
    var displayName: String {
        switch self {
        case .standard: return "Standard (7 years)"
        case .short: return "Short (1 year)"
        case .medium: return "Medium (3 years)"
        case .long: return "Long (10 years)"
        case .permanent: return "Permanent"
        case .custom: return "Custom"
        }
    }
    
    var retentionYears: Int? {
        switch self {
        case .standard: return 7
        case .short: return 1
        case .medium: return 3
        case .long: return 10
        case .permanent: return nil
        case .custom: return nil
        }
    }
}

// MARK: - Supporting Models

struct DocumentVersionSummary: Identifiable, Codable {
    let id: String
    let version: String
    let versionNumber: Int
    let createdBy: String
    let createdAt: Date
    let changeDescription: String
    let fileSize: Int64
    let isMinorUpdate: Bool
}

struct DocumentApprovalStep: Identifiable, Codable {
    let id: String
    let approverUserId: String
    let approverRole: String
    let stepOrder: Int
    let status: DocumentApprovalStatus
    let approvedAt: Date?
    let comments: String?
    let isRequired: Bool
}

// MARK: - CloudKit Extensions

extension DocumentModel {
    
    /// CloudKit record type identifier
    static let recordType = "Document"
    
    /// Converts the model to a CloudKit record
    func toCKRecord() throws -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: id)
        
        // Core properties
        record["title"] = title
        record["fileName"] = fileName
        record["fileType"] = fileType.rawValue
        record["fileSize"] = fileSize
        record["mimeType"] = mimeType
        
        // Version control
        record["version"] = version
        record["versionNumber"] = versionNumber
        record["isLatestVersion"] = isLatestVersion
        record["parentDocumentId"] = parentDocumentId
        
        // Metadata
        record["description"] = description
        record["tags"] = tags
        record["category"] = category.rawValue
        record["language"] = language
        
        // Access control
        record["accessLevel"] = accessLevel.rawValue
        record["departmentRestrictions"] = departmentRestrictions
        record["roleRestrictions"] = roleRestrictions
        record["locationRestrictions"] = locationRestrictions
        record["ownerUserId"] = ownerUserId
        record["collaboratorUserIds"] = collaboratorUserIds
        
        // File references
        record["documentAssetRecordName"] = documentAssetRecordName
        record["thumbnailAssetRecordName"] = thumbnailAssetRecordName
        record["documentPath"] = documentPath
        record["thumbnailPath"] = thumbnailPath
        
        // Status & workflow
        record["status"] = status.rawValue
        record["approvalStatus"] = approvalStatus.rawValue
        record["workflowStage"] = workflowStage
        record["approvalRequired"] = approvalRequired
        
        // Checkout & collaboration
        record["checkedOutBy"] = checkedOutBy
        record["checkedOutAt"] = checkedOutAt
        record["lockExpiration"] = lockExpiration
        record["allowConcurrentEditing"] = allowConcurrentEditing
        
        // Retention & compliance
        record["retentionPolicy"] = retentionPolicy.rawValue
        record["retentionDate"] = retentionDate
        record["complianceFlags"] = complianceFlags
        record["legalHoldFlag"] = legalHoldFlag
        record["encryptionRequired"] = encryptionRequired
        
        // Timestamps & audit
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["modifiedBy"] = modifiedBy
        record["modifiedAt"] = modifiedAt
        record["lastAccessedAt"] = lastAccessedAt
        record["lastAccessedBy"] = lastAccessedBy
        
        // Search & discovery
        record["searchableContent"] = searchableContent
        record["documentHash"] = documentHash
        record["ocrExtractedText"] = ocrExtractedText
        record["aiGeneratedSummary"] = aiGeneratedSummary
        
        // Integration
        record["externalSystemId"] = externalSystemId
        record["sourceApplication"] = sourceApplication
        
        return record
    }
    
    /// Creates a model from a CloudKit record
    static func fromCKRecord(_ record: CKRecord) throws -> DocumentModel {
        guard let title = record["title"] as? String,
              let fileName = record["fileName"] as? String,
              let fileTypeRaw = record["fileType"] as? String,
              let fileType = DocumentFileType(rawValue: fileTypeRaw),
              let fileSize = record["fileSize"] as? Int64,
              let mimeType = record["mimeType"] as? String,
              let ownerUserId = record["ownerUserId"] as? String,
              let createdBy = record["createdBy"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let modifiedBy = record["modifiedBy"] as? String,
              let modifiedAt = record["modifiedAt"] as? Date else {
            throw DocumentError.invalidRecord("Missing required fields in CloudKit record")
        }
        
        var document = DocumentModel(
            id: record.recordID,
            title: title,
            fileName: fileName,
            fileType: fileType,
            fileSize: fileSize,
            mimeType: mimeType,
            ownerUserId: ownerUserId,
            createdBy: createdBy
        )
        
        // Update from record
        document.version = record["version"] as? String ?? "1.0"
        document.versionNumber = record["versionNumber"] as? Int ?? 1
        document.isLatestVersion = record["isLatestVersion"] as? Bool ?? true
        document.parentDocumentId = record["parentDocumentId"] as? String
        
        document.description = record["description"] as? String
        document.tags = record["tags"] as? [String] ?? []
        
        if let categoryRaw = record["category"] as? String,
           let category = DocumentCategory(rawValue: categoryRaw) {
            document.category = category
        }
        
        document.language = record["language"] as? String ?? "en"
        
        if let accessLevelRaw = record["accessLevel"] as? String,
           let accessLevel = DocumentAccessLevel(rawValue: accessLevelRaw) {
            document.accessLevel = accessLevel
        }
        
        document.departmentRestrictions = record["departmentRestrictions"] as? [String] ?? []
        document.roleRestrictions = record["roleRestrictions"] as? [String] ?? []
        document.locationRestrictions = record["locationRestrictions"] as? [String] ?? []
        document.collaboratorUserIds = record["collaboratorUserIds"] as? [String] ?? []
        
        document.documentAssetRecordName = record["documentAssetRecordName"] as? String
        document.thumbnailAssetRecordName = record["thumbnailAssetRecordName"] as? String
        document.documentPath = record["documentPath"] as? String ?? ""
        document.thumbnailPath = record["thumbnailPath"] as? String
        
        if let statusRaw = record["status"] as? String,
           let status = DocumentStatus(rawValue: statusRaw) {
            document.status = status
        }
        
        if let approvalStatusRaw = record["approvalStatus"] as? String,
           let approvalStatus = DocumentApprovalStatus(rawValue: approvalStatusRaw) {
            document.approvalStatus = approvalStatus
        }
        
        document.workflowStage = record["workflowStage"] as? String
        document.approvalRequired = record["approvalRequired"] as? Bool ?? false
        
        document.checkedOutBy = record["checkedOutBy"] as? String
        document.checkedOutAt = record["checkedOutAt"] as? Date
        document.lockExpiration = record["lockExpiration"] as? Date
        document.allowConcurrentEditing = record["allowConcurrentEditing"] as? Bool ?? true
        
        if let retentionPolicyRaw = record["retentionPolicy"] as? String,
           let retentionPolicy = DocumentRetentionPolicy(rawValue: retentionPolicyRaw) {
            document.retentionPolicy = retentionPolicy
        }
        
        document.retentionDate = record["retentionDate"] as? Date
        document.complianceFlags = record["complianceFlags"] as? [String] ?? []
        document.legalHoldFlag = record["legalHoldFlag"] as? Bool ?? false
        document.encryptionRequired = record["encryptionRequired"] as? Bool ?? false
        
        document.createdAt = createdAt
        document.modifiedBy = modifiedBy
        document.modifiedAt = modifiedAt
        document.lastAccessedAt = record["lastAccessedAt"] as? Date
        document.lastAccessedBy = record["lastAccessedBy"] as? String
        
        document.searchableContent = record["searchableContent"] as? String
        document.documentHash = record["documentHash"] as? String
        document.ocrExtractedText = record["ocrExtractedText"] as? String
        document.aiGeneratedSummary = record["aiGeneratedSummary"] as? String
        
        document.externalSystemId = record["externalSystemId"] as? String
        document.sourceApplication = record["sourceApplication"] as? String
        
        return document
    }
}

// MARK: - Errors

enum DocumentError: Error, LocalizedError {
    case invalidRecord(String)
    case accessDenied
    case documentLocked
    case versionConflict
    case quotaExceeded
    case invalidFileType
    case encryptionRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidRecord(let message):
            return "Invalid document record: \(message)"
        case .accessDenied:
            return "Access denied to this document"
        case .documentLocked:
            return "Document is currently locked by another user"
        case .versionConflict:
            return "Version conflict detected"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .invalidFileType:
            return "Invalid or unsupported file type"
        case .encryptionRequired:
            return "Document requires encryption"
        }
    }
}
