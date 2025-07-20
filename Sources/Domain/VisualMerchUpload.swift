import Foundation
import CloudKit

/// Visual merchandising photo upload for compliance verification
public struct VisualMerchUpload: Identifiable, Codable {
    public let id: CKRecord.ID
    public let taskId: CKRecord.Reference
    public let storeCode: String
    public let uploadedBy: CKRecord.Reference
    public let fileName: String
    public let fileSize: Int64
    public let mimeType: String
    public let assetReference: CKAsset?
    public let thumbnailAsset: CKAsset?
    public let uploadedAt: Date
    public let location: UploadLocation?
    public let notes: String?
    public let status: UploadStatus
    public let reviewedBy: CKRecord.Reference?
    public let reviewedAt: Date?
    public let reviewNotes: String?
    public let approvedByRef: CKRecord.Reference? // Approval tracking field per buildout plan
    public let approvedAt: Date? // Approval timestamp per buildout plan
    public let metadata: UploadMetadata?
    public let isRetake: Bool
    public let originalUploadId: CKRecord.Reference?
    public let sequenceNumber: Int
    public let category: VisualMerchCategory?
    
    public struct UploadLocation: Codable {
        public let latitude: Double
        public let longitude: Double
        public let timestamp: Date
        public let accuracy: Double?
        public let address: String?
        
        public init(latitude: Double, longitude: Double, timestamp: Date, accuracy: Double? = nil, address: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.timestamp = timestamp
            self.accuracy = accuracy
            self.address = address
        }
    }
    
    public struct UploadMetadata: Codable {
        public let deviceModel: String?
        public let osVersion: String?
        public let appVersion: String?
        public let imageWidth: Int?
        public let imageHeight: Int?
        public let flashUsed: Bool?
        public let cameraPosition: String? // front/back
        public let orientation: Int?
        public let capturedAt: Date?
        
        public init(
            deviceModel: String? = nil,
            osVersion: String? = nil,
            appVersion: String? = nil,
            imageWidth: Int? = nil,
            imageHeight: Int? = nil,
            flashUsed: Bool? = nil,
            cameraPosition: String? = nil,
            orientation: Int? = nil,
            capturedAt: Date? = nil
        ) {
            self.deviceModel = deviceModel
            self.osVersion = osVersion
            self.appVersion = appVersion
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
            self.flashUsed = flashUsed
            self.cameraPosition = cameraPosition
            self.orientation = orientation
            self.capturedAt = capturedAt
        }
    }
    
    public enum UploadStatus: String, CaseIterable, Codable {
        case uploading = "uploading"
        case uploaded = "uploaded"
        case processing = "processing"
        case approved = "approved"
        case rejected = "rejected"
        case failed = "failed"
        case deleted = "deleted"
        
        public var displayName: String {
            switch self {
            case .uploading: return "Uploading"
            case .uploaded: return "Uploaded"
            case .processing: return "Processing"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            case .failed: return "Failed"
            case .deleted: return "Deleted"
            }
        }
        
        public var isProcessing: Bool {
            return self == .uploading || self == .processing
        }
        
        public var needsReview: Bool {
            return self == .uploaded
        }
        
        public var isApproved: Bool {
            return self == .approved
        }
    }
    
    public enum VisualMerchCategory: String, CaseIterable, Codable {
        case windowDisplay = "window_display"
        case storeLayout = "store_layout"
        case merchandising = "merchandising"
        case signage = "signage"
        case cleanliness = "cleanliness"
        case stockDisplay = "stock_display"
        case customerExperience = "customer_experience"
        case seasonal = "seasonal"
        case compliance = "compliance"
        case before = "before"
        case after = "after"
        case issue = "issue"
        case resolved = "resolved"
        
        public var displayName: String {
            switch self {
            case .windowDisplay: return "Window Display"
            case .storeLayout: return "Store Layout"
            case .merchandising: return "Merchandising"
            case .signage: return "Signage"
            case .cleanliness: return "Cleanliness"
            case .stockDisplay: return "Stock Display"
            case .customerExperience: return "Customer Experience"
            case .seasonal: return "Seasonal"
            case .compliance: return "Compliance"
            case .before: return "Before"
            case .after: return "After"
            case .issue: return "Issue"
            case .resolved: return "Resolved"
            }
        }
    }
    
    // Computed properties
    public var fileSizeFormatted: String {
        let bytes = Double(fileSize)
        let kilobyte = 1024.0
        let megabyte = kilobyte * 1024.0
        let gigabyte = megabyte * 1024.0
        
        if bytes < kilobyte {
            return "\(Int(bytes)) B"
        } else if bytes < megabyte {
            return String(format: "%.1f KB", bytes / kilobyte)
        } else if bytes < gigabyte {
            return String(format: "%.1f MB", bytes / megabyte)
        } else {
            return String(format: "%.1f GB", bytes / gigabyte)
        }
    }
    
    public var isImage: Bool {
        return mimeType.hasPrefix("image/")
    }
    
    public var isVideo: Bool {
        return mimeType.hasPrefix("video/")
    }
    
    public var fileExtension: String {
        return (fileName as NSString).pathExtension.lowercased()
    }
    
    public var hasLocation: Bool {
        return location != nil
    }
    
    public var isHighResolution: Bool {
        guard let metadata = metadata,
              let width = metadata.imageWidth,
              let height = metadata.imageHeight else {
            return false
        }
        return width >= 1920 && height >= 1080
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let taskId = record["taskId"] as? CKRecord.Reference,
              let storeCode = record["storeCode"] as? String,
              let uploadedBy = record["uploadedBy"] as? CKRecord.Reference,
              let fileName = record["fileName"] as? String,
              let fileSize = record["fileSize"] as? Int64,
              let mimeType = record["mimeType"] as? String,
              let uploadedAt = record["uploadedAt"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = UploadStatus(rawValue: statusRaw),
              let isRetake = record["isRetake"] as? Bool,
              let sequenceNumber = record["sequenceNumber"] as? Int else {
            return nil
        }
        
        self.id = record.recordID
        self.taskId = taskId
        self.storeCode = storeCode
        self.uploadedBy = uploadedBy
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.assetReference = record["assetReference"] as? CKAsset
        self.thumbnailAsset = record["thumbnailAsset"] as? CKAsset
        self.uploadedAt = uploadedAt
        self.notes = record["notes"] as? String
        self.status = status
        self.reviewedBy = record["reviewedBy"] as? CKRecord.Reference
        self.reviewedAt = record["reviewedAt"] as? Date
        self.reviewNotes = record["reviewNotes"] as? String
        self.approvedByRef = record["approvedByRef"] as? CKRecord.Reference
        self.approvedAt = record["approvedAt"] as? Date
        self.isRetake = isRetake
        self.originalUploadId = record["originalUploadId"] as? CKRecord.Reference
        self.sequenceNumber = sequenceNumber
        
        // Decode category
        if let categoryRaw = record["category"] as? String {
            self.category = VisualMerchCategory(rawValue: categoryRaw)
        } else {
            self.category = nil
        }
        
        // Decode location from JSON
        if let locationData = record["location"] as? Data {
            self.location = try? JSONDecoder().decode(UploadLocation.self, from: locationData)
        } else {
            self.location = nil
        }
        
        // Decode metadata from JSON
        if let metadataData = record["metadata"] as? Data {
            self.metadata = try? JSONDecoder().decode(UploadMetadata.self, from: metadataData)
        } else {
            self.metadata = nil
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "VisualMerchUpload", recordID: id)
        
        record["taskId"] = taskId
        record["storeCode"] = storeCode
        record["uploadedBy"] = uploadedBy
        record["fileName"] = fileName
        record["fileSize"] = fileSize
        record["mimeType"] = mimeType
        record["assetReference"] = assetReference
        record["thumbnailAsset"] = thumbnailAsset
        record["uploadedAt"] = uploadedAt
        record["notes"] = notes
        record["status"] = status.rawValue
        record["reviewedBy"] = reviewedBy
        record["reviewedAt"] = reviewedAt
        record["reviewNotes"] = reviewNotes
        record["approvedByRef"] = approvedByRef
        record["approvedAt"] = approvedAt
        record["isRetake"] = isRetake
        record["originalUploadId"] = originalUploadId
        record["sequenceNumber"] = sequenceNumber
        record["category"] = category?.rawValue
        
        // Encode location as JSON
        if let location = location,
           let locationData = try? JSONEncoder().encode(location) {
            record["location"] = locationData
        }
        
        // Encode metadata as JSON
        if let metadata = metadata,
           let metadataData = try? JSONEncoder().encode(metadata) {
            record["metadata"] = metadataData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> VisualMerchUpload? {
        return VisualMerchUpload(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        taskId: CKRecord.Reference,
        storeCode: String,
        uploadedBy: CKRecord.Reference,
        fileName: String,
        fileSize: Int64,
        mimeType: String,
        assetReference: CKAsset? = nil,
        thumbnailAsset: CKAsset? = nil,
        location: UploadLocation? = nil,
        notes: String? = nil,
        category: VisualMerchCategory? = nil,
        isRetake: Bool = false,
        originalUploadId: CKRecord.Reference? = nil,
        sequenceNumber: Int = 1,
        metadata: UploadMetadata? = nil
    ) -> VisualMerchUpload {
        return VisualMerchUpload(
            id: CKRecord.ID(recordName: UUID().uuidString),
            taskId: taskId,
            storeCode: storeCode,
            uploadedBy: uploadedBy,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            assetReference: assetReference,
            thumbnailAsset: thumbnailAsset,
            uploadedAt: Date(),
            location: location,
            notes: notes,
            status: assetReference != nil ? .uploaded : .uploading,
            reviewedBy: nil,
            reviewedAt: nil,
            reviewNotes: nil,
            approvedByRef: nil,
            approvedAt: nil,
            metadata: metadata,
            isRetake: isRetake,
            originalUploadId: originalUploadId,
            sequenceNumber: sequenceNumber,
            category: category
        )
    }
    
    // MARK: - Helper Methods
    
    public func withStatus(_ newStatus: UploadStatus) -> VisualMerchUpload {
        return VisualMerchUpload(
            id: id,
            taskId: taskId,
            storeCode: storeCode,
            uploadedBy: uploadedBy,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            assetReference: assetReference,
            thumbnailAsset: thumbnailAsset,
            uploadedAt: uploadedAt,
            location: location,
            notes: notes,
            status: newStatus,
            reviewedBy: reviewedBy,
            reviewedAt: reviewedAt,
            reviewNotes: reviewNotes,
            approvedByRef: approvedByRef,
            approvedAt: approvedAt,
            metadata: metadata,
            isRetake: isRetake,
            originalUploadId: originalUploadId,
            sequenceNumber: sequenceNumber,
            category: category
        )
    }
    
    public func withAsset(_ asset: CKAsset, thumbnail: CKAsset? = nil) -> VisualMerchUpload {
        return VisualMerchUpload(
            id: id,
            taskId: taskId,
            storeCode: storeCode,
            uploadedBy: uploadedBy,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            assetReference: asset,
            thumbnailAsset: thumbnail,
            uploadedAt: uploadedAt,
            location: location,
            notes: notes,
            status: .uploaded,
            reviewedBy: reviewedBy,
            reviewedAt: reviewedAt,
            reviewNotes: reviewNotes,
            approvedByRef: approvedByRef,
            approvedAt: approvedAt,
            metadata: metadata,
            isRetake: isRetake,
            originalUploadId: originalUploadId,
            sequenceNumber: sequenceNumber,
            category: category
        )
    }
    
    public func withReview(reviewedBy: CKRecord.Reference, approved: Bool, notes: String? = nil) -> VisualMerchUpload {
        return VisualMerchUpload(
            id: id,
            taskId: taskId,
            storeCode: storeCode,
            uploadedBy: uploadedBy,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            assetReference: assetReference,
            thumbnailAsset: thumbnailAsset,
            uploadedAt: uploadedAt,
            location: location,
            notes: self.notes,
            status: approved ? .approved : .rejected,
            reviewedBy: reviewedBy,
            reviewedAt: Date(),
            reviewNotes: notes,
            approvedByRef: approved ? reviewedBy : nil,
            approvedAt: approved ? Date() : nil,
            metadata: metadata,
            isRetake: isRetake,
            originalUploadId: originalUploadId,
            sequenceNumber: sequenceNumber,
            category: category
        )
    }
    
    public func createRetake(newSequenceNumber: Int) -> VisualMerchUpload {
        return VisualMerchUpload(
            id: CKRecord.ID(recordName: UUID().uuidString),
            taskId: taskId,
            storeCode: storeCode,
            uploadedBy: uploadedBy,
            fileName: fileName,
            fileSize: 0, // Will be updated when actual file is uploaded
            mimeType: mimeType,
            assetReference: nil,
            thumbnailAsset: nil,
            uploadedAt: Date(),
            location: nil,
            notes: nil,
            status: .uploading,
            reviewedBy: nil,
            reviewedAt: nil,
            reviewNotes: nil,
            approvedByRef: nil,
            approvedAt: nil,
            metadata: nil,
            isRetake: true,
            originalUploadId: CKRecord.Reference(recordID: id, action: .none),
            sequenceNumber: newSequenceNumber,
            category: category
        )
    }
}
