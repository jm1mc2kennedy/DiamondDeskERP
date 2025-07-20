import Foundation
import CloudKit

/// Audit execution model for conducting store audits based on templates
public struct Audit: Identifiable, Codable {
    public let id: CKRecord.ID
    public let templateRef: CKRecord.Reference
    public let templateTitle: String
    public let storeCode: String
    public let storeName: String?
    public let status: AuditStatus
    public let startedBy: CKRecord.Reference
    public let startedByName: String
    public let startedAt: Date
    public let finishedAt: Date?
    public let pausedAt: Date?
    public let resumedAt: Date?
    public let score: Double?
    public let maxScore: Double?
    public let percentage: Double?
    public let passCount: Int
    public let failCount: Int
    public let naCount: Int
    public let totalQuestions: Int
    public let responses: [AuditResponse]
    public let photoAssets: [AuditPhoto]
    public let comments: String?
    public let signature: AuditSignature?
    public let reviewedBy: CKRecord.Reference?
    public let reviewedByName: String?
    public let reviewedAt: Date?
    public let reviewComments: String?
    public let flags: [AuditFlag]
    public let createdTickets: [CKRecord.Reference]
    public let duration: TimeInterval?
    public let isSubmitted: Bool
    public let submittedAt: Date?
    public let metadata: AuditMetadata?
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum AuditStatus: String, CaseIterable, Codable {
        case draft = "draft"
        case inProgress = "in_progress"
        case paused = "paused"
        case completed = "completed"
        case submitted = "submitted"
        case underReview = "under_review"
        case approved = "approved"
        case rejected = "rejected"
        case cancelled = "cancelled"
        
        public var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .inProgress: return "In Progress"
            case .paused: return "Paused"
            case .completed: return "Completed"
            case .submitted: return "Submitted"
            case .underReview: return "Under Review"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            case .cancelled: return "Cancelled"
            }
        }
        
        public var canEdit: Bool {
            switch self {
            case .draft, .inProgress, .paused:
                return true
            case .completed, .submitted, .underReview, .approved, .rejected, .cancelled:
                return false
            }
        }
        
        public var isComplete: Bool {
            switch self {
            case .completed, .submitted, .approved:
                return true
            case .draft, .inProgress, .paused, .underReview, .rejected, .cancelled:
                return false
            }
        }
    }
    
    public struct AuditResponse: Codable, Identifiable {
        public let id: UUID
        public let questionId: UUID
        public let sectionId: UUID
        public let questionText: String
        public let answerType: AnswerType
        public let answer: String
        public let points: Double?
        public let maxPoints: Double
        public let isPassing: Bool
        public let photos: [String] // Asset references
        public let comments: String?
        public let timestamp: Date
        public let location: ResponseLocation?
        public let metadata: [String: String]
        
        public enum AnswerType: String, CaseIterable, Codable {
            case pass = "pass"
            case fail = "fail"
            case na = "na"
            case yes = "yes"
            case no = "no"
            case text = "text"
            case numeric = "numeric"
            case multipleChoice = "multiple_choice"
            case rating = "rating"
            case checklist = "checklist"
            
            public var displayName: String {
                switch self {
                case .pass: return "Pass"
                case .fail: return "Fail"
                case .na: return "N/A"
                case .yes: return "Yes"
                case .no: return "No"
                case .text: return "Text"
                case .numeric: return "Numeric"
                case .multipleChoice: return "Multiple Choice"
                case .rating: return "Rating"
                case .checklist: return "Checklist"
                }
            }
        }
        
        public struct ResponseLocation: Codable {
            public let latitude: Double
            public let longitude: Double
            public let accuracy: Double?
            public let timestamp: Date
        }
        
        public init(
            id: UUID = UUID(),
            questionId: UUID,
            sectionId: UUID,
            questionText: String,
            answerType: AnswerType,
            answer: String,
            points: Double? = nil,
            maxPoints: Double,
            isPassing: Bool = true,
            photos: [String] = [],
            comments: String? = nil,
            timestamp: Date = Date(),
            location: ResponseLocation? = nil,
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.questionId = questionId
            self.sectionId = sectionId
            self.questionText = questionText
            self.answerType = answerType
            self.answer = answer
            self.points = points
            self.maxPoints = maxPoints
            self.isPassing = isPassing
            self.photos = photos
            self.comments = comments
            self.timestamp = timestamp
            self.location = location
            self.metadata = metadata
        }
    }
    
    public struct AuditPhoto: Codable, Identifiable {
        public let id: UUID
        public let questionId: UUID?
        public let sectionId: UUID?
        public let assetReference: String // CKAsset reference
        public let thumbnailReference: String?
        public let caption: String?
        public let location: PhotoLocation?
        public let timestamp: Date
        public let fileSize: Int64
        public let mimeType: String
        public let isRequired: Bool
        public let uploadedBy: CKRecord.Reference
        
        public struct PhotoLocation: Codable {
            public let latitude: Double
            public let longitude: Double
            public let accuracy: Double?
            public let address: String?
        }
        
        public init(
            id: UUID = UUID(),
            questionId: UUID? = nil,
            sectionId: UUID? = nil,
            assetReference: String,
            thumbnailReference: String? = nil,
            caption: String? = nil,
            location: PhotoLocation? = nil,
            timestamp: Date = Date(),
            fileSize: Int64,
            mimeType: String,
            isRequired: Bool = false,
            uploadedBy: CKRecord.Reference
        ) {
            self.id = id
            self.questionId = questionId
            self.sectionId = sectionId
            self.assetReference = assetReference
            self.thumbnailReference = thumbnailReference
            self.caption = caption
            self.location = location
            self.timestamp = timestamp
            self.fileSize = fileSize
            self.mimeType = mimeType
            self.isRequired = isRequired
            self.uploadedBy = uploadedBy
        }
    }
    
    public struct AuditSignature: Codable {
        public let signatureImageData: Data
        public let signerName: String
        public let signerRole: String
        public let timestamp: Date
        public let location: SignatureLocation?
        
        public struct SignatureLocation: Codable {
            public let latitude: Double
            public let longitude: Double
        }
    }
    
    public struct AuditFlag: Codable, Identifiable {
        public let id: UUID
        public let type: FlagType
        public let severity: FlagSeverity
        public let title: String
        public let description: String
        public let questionId: UUID?
        public let sectionId: UUID?
        public let triggeredBy: String // Rule or condition
        public let actionTaken: String?
        public let resolvedAt: Date?
        public let resolvedBy: CKRecord.Reference?
        public let timestamp: Date
        
        public enum FlagType: String, CaseIterable, Codable {
            case safety = "safety"
            case compliance = "compliance"
            case quality = "quality"
            case process = "process"
            case training = "training"
            case equipment = "equipment"
            case documentation = "documentation"
            case custom = "custom"
            
            public var displayName: String {
                switch self {
                case .safety: return "Safety"
                case .compliance: return "Compliance"
                case .quality: return "Quality"
                case .process: return "Process"
                case .training: return "Training"
                case .equipment: return "Equipment"
                case .documentation: return "Documentation"
                case .custom: return "Custom"
                }
            }
        }
        
        public enum FlagSeverity: String, CaseIterable, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
            
            public var displayName: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .critical: return "Critical"
                }
            }
            
            public var color: String {
                switch self {
                case .low: return "green"
                case .medium: return "yellow"
                case .high: return "orange"
                case .critical: return "red"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            type: FlagType,
            severity: FlagSeverity,
            title: String,
            description: String,
            questionId: UUID? = nil,
            sectionId: UUID? = nil,
            triggeredBy: String,
            actionTaken: String? = nil,
            resolvedAt: Date? = nil,
            resolvedBy: CKRecord.Reference? = nil,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.type = type
            self.severity = severity
            self.title = title
            self.description = description
            self.questionId = questionId
            self.sectionId = sectionId
            self.triggeredBy = triggeredBy
            self.actionTaken = actionTaken
            self.resolvedAt = resolvedAt
            self.resolvedBy = resolvedBy
            self.timestamp = timestamp
        }
    }
    
    public struct AuditMetadata: Codable {
        public let deviceInfo: DeviceInfo
        public let appVersion: String
        public let startLocation: MetadataLocation?
        public let endLocation: MetadataLocation?
        public let networkCondition: String?
        public let batteryLevel: Double?
        public let interruptionCount: Int
        public let pauseDuration: TimeInterval?
        
        public struct DeviceInfo: Codable {
            public let model: String
            public let osVersion: String
            public let screenSize: String?
            public let orientation: String?
        }
        
        public struct MetadataLocation: Codable {
            public let latitude: Double
            public let longitude: Double
            public let accuracy: Double?
            public let timestamp: Date
        }
    }
    
    // Computed properties
    public var completionPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return (Double(responses.count) / Double(totalQuestions)) * 100
    }
    
    public var passingPercentage: Double {
        guard percentage != nil else {
            let answeredQuestions = passCount + failCount
            guard answeredQuestions > 0 else { return 0 }
            return (Double(passCount) / Double(answeredQuestions)) * 100
        }
        return percentage!
    }
    
    public var isOverdue: Bool {
        // Would need audit template time limit and start time
        return false
    }
    
    public var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    public var criticalFlags: [AuditFlag] {
        return flags.filter { $0.severity == .critical }
    }
    
    public var unresolvedFlags: [AuditFlag] {
        return flags.filter { $0.resolvedAt == nil }
    }
    
    public var photoCount: Int {
        return photoAssets.count
    }
    
    public var requiredPhotosCount: Int {
        return photoAssets.filter { $0.isRequired }.count
    }
    
    public var hasSignature: Bool {
        return signature != nil
    }
    
    public var sectionCompletionStatus: [UUID: Double] {
        let sectionGroups = Dictionary(grouping: responses) { $0.sectionId }
        var status: [UUID: Double] = [:]
        
        for (sectionId, sectionResponses) in sectionGroups {
            // This would need section question counts from template
            status[sectionId] = 100.0 // Simplified
        }
        
        return status
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let templateRef = record["templateRef"] as? CKRecord.Reference,
              let templateTitle = record["templateTitle"] as? String,
              let storeCode = record["storeCode"] as? String,
              let statusRaw = record["status"] as? String,
              let status = AuditStatus(rawValue: statusRaw),
              let startedBy = record["startedBy"] as? CKRecord.Reference,
              let startedByName = record["startedByName"] as? String,
              let startedAt = record["startedAt"] as? Date,
              let passCount = record["passCount"] as? Int,
              let failCount = record["failCount"] as? Int,
              let naCount = record["naCount"] as? Int,
              let totalQuestions = record["totalQuestions"] as? Int,
              let isSubmitted = record["isSubmitted"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.templateRef = templateRef
        self.templateTitle = templateTitle
        self.storeCode = storeCode
        self.storeName = record["storeName"] as? String
        self.status = status
        self.startedBy = startedBy
        self.startedByName = startedByName
        self.startedAt = startedAt
        self.finishedAt = record["finishedAt"] as? Date
        self.pausedAt = record["pausedAt"] as? Date
        self.resumedAt = record["resumedAt"] as? Date
        self.score = record["score"] as? Double
        self.maxScore = record["maxScore"] as? Double
        self.percentage = record["percentage"] as? Double
        self.passCount = passCount
        self.failCount = failCount
        self.naCount = naCount
        self.totalQuestions = totalQuestions
        self.comments = record["comments"] as? String
        self.reviewedBy = record["reviewedBy"] as? CKRecord.Reference
        self.reviewedByName = record["reviewedByName"] as? String
        self.reviewedAt = record["reviewedAt"] as? Date
        self.reviewComments = record["reviewComments"] as? String
        self.duration = record["duration"] as? TimeInterval
        self.isSubmitted = isSubmitted
        self.submittedAt = record["submittedAt"] as? Date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON
        if let responsesData = record["responses"] as? Data,
           let decodedResponses = try? JSONDecoder().decode([AuditResponse].self, from: responsesData) {
            self.responses = decodedResponses
        } else {
            self.responses = []
        }
        
        if let photosData = record["photoAssets"] as? Data,
           let decodedPhotos = try? JSONDecoder().decode([AuditPhoto].self, from: photosData) {
            self.photoAssets = decodedPhotos
        } else {
            self.photoAssets = []
        }
        
        if let signatureData = record["signature"] as? Data,
           let decodedSignature = try? JSONDecoder().decode(AuditSignature.self, from: signatureData) {
            self.signature = decodedSignature
        } else {
            self.signature = nil
        }
        
        if let flagsData = record["flags"] as? Data,
           let decodedFlags = try? JSONDecoder().decode([AuditFlag].self, from: flagsData) {
            self.flags = decodedFlags
        } else {
            self.flags = []
        }
        
        if let ticketsData = record["createdTickets"] as? Data,
           let decodedTickets = try? JSONDecoder().decode([CKRecord.Reference].self, from: ticketsData) {
            self.createdTickets = decodedTickets
        } else {
            self.createdTickets = []
        }
        
        if let metadataData = record["metadata"] as? Data,
           let decodedMetadata = try? JSONDecoder().decode(AuditMetadata.self, from: metadataData) {
            self.metadata = decodedMetadata
        } else {
            self.metadata = nil
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Audit", recordID: id)
        
        record["templateRef"] = templateRef
        record["templateTitle"] = templateTitle
        record["storeCode"] = storeCode
        record["storeName"] = storeName
        record["status"] = status.rawValue
        record["startedBy"] = startedBy
        record["startedByName"] = startedByName
        record["startedAt"] = startedAt
        record["finishedAt"] = finishedAt
        record["pausedAt"] = pausedAt
        record["resumedAt"] = resumedAt
        record["score"] = score
        record["maxScore"] = maxScore
        record["percentage"] = percentage
        record["passCount"] = passCount
        record["failCount"] = failCount
        record["naCount"] = naCount
        record["totalQuestions"] = totalQuestions
        record["comments"] = comments
        record["reviewedBy"] = reviewedBy
        record["reviewedByName"] = reviewedByName
        record["reviewedAt"] = reviewedAt
        record["reviewComments"] = reviewComments
        record["duration"] = duration
        record["isSubmitted"] = isSubmitted
        record["submittedAt"] = submittedAt
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex data as JSON
        if !responses.isEmpty,
           let responsesData = try? JSONEncoder().encode(responses) {
            record["responses"] = responsesData
        }
        
        if !photoAssets.isEmpty,
           let photosData = try? JSONEncoder().encode(photoAssets) {
            record["photoAssets"] = photosData
        }
        
        if let signature = signature,
           let signatureData = try? JSONEncoder().encode(signature) {
            record["signature"] = signatureData
        }
        
        if !flags.isEmpty,
           let flagsData = try? JSONEncoder().encode(flags) {
            record["flags"] = flagsData
        }
        
        if !createdTickets.isEmpty,
           let ticketsData = try? JSONEncoder().encode(createdTickets) {
            record["createdTickets"] = ticketsData
        }
        
        if let metadata = metadata,
           let metadataData = try? JSONEncoder().encode(metadata) {
            record["metadata"] = metadataData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> Audit? {
        return Audit(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        templateRef: CKRecord.Reference,
        templateTitle: String,
        storeCode: String,
        storeName: String? = nil,
        startedBy: CKRecord.Reference,
        startedByName: String,
        totalQuestions: Int
    ) -> Audit {
        let now = Date()
        
        return Audit(
            id: CKRecord.ID(recordName: UUID().uuidString),
            templateRef: templateRef,
            templateTitle: templateTitle,
            storeCode: storeCode,
            storeName: storeName,
            status: .draft,
            startedBy: startedBy,
            startedByName: startedByName,
            startedAt: now,
            finishedAt: nil,
            pausedAt: nil,
            resumedAt: nil,
            score: nil,
            maxScore: nil,
            percentage: nil,
            passCount: 0,
            failCount: 0,
            naCount: 0,
            totalQuestions: totalQuestions,
            responses: [],
            photoAssets: [],
            comments: nil,
            signature: nil,
            reviewedBy: nil,
            reviewedByName: nil,
            reviewedAt: nil,
            reviewComments: nil,
            flags: [],
            createdTickets: [],
            duration: nil,
            isSubmitted: false,
            submittedAt: nil,
            metadata: nil,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // MARK: - Helper Methods
    
    public func addResponse(_ response: AuditResponse) -> Audit {
        var newResponses = responses.filter { $0.questionId != response.questionId }
        newResponses.append(response)
        
        let newPassCount = newResponses.filter { $0.answerType == .pass }.count
        let newFailCount = newResponses.filter { $0.answerType == .fail }.count
        let newNACount = newResponses.filter { $0.answerType == .na }.count
        
        return Audit(
            id: id,
            templateRef: templateRef,
            templateTitle: templateTitle,
            storeCode: storeCode,
            storeName: storeName,
            status: status,
            startedBy: startedBy,
            startedByName: startedByName,
            startedAt: startedAt,
            finishedAt: finishedAt,
            pausedAt: pausedAt,
            resumedAt: resumedAt,
            score: score,
            maxScore: maxScore,
            percentage: percentage,
            passCount: newPassCount,
            failCount: newFailCount,
            naCount: newNACount,
            totalQuestions: totalQuestions,
            responses: newResponses,
            photoAssets: photoAssets,
            comments: comments,
            signature: signature,
            reviewedBy: reviewedBy,
            reviewedByName: reviewedByName,
            reviewedAt: reviewedAt,
            reviewComments: reviewComments,
            flags: flags,
            createdTickets: createdTickets,
            duration: duration,
            isSubmitted: isSubmitted,
            submittedAt: submittedAt,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    public func complete(finalScore: Double, maxScore: Double) -> Audit {
        let percentage = (finalScore / maxScore) * 100
        let now = Date()
        let totalDuration = now.timeIntervalSince(startedAt)
        
        return Audit(
            id: id,
            templateRef: templateRef,
            templateTitle: templateTitle,
            storeCode: storeCode,
            storeName: storeName,
            status: .completed,
            startedBy: startedBy,
            startedByName: startedByName,
            startedAt: startedAt,
            finishedAt: now,
            pausedAt: pausedAt,
            resumedAt: resumedAt,
            score: finalScore,
            maxScore: maxScore,
            percentage: percentage,
            passCount: passCount,
            failCount: failCount,
            naCount: naCount,
            totalQuestions: totalQuestions,
            responses: responses,
            photoAssets: photoAssets,
            comments: comments,
            signature: signature,
            reviewedBy: reviewedBy,
            reviewedByName: reviewedByName,
            reviewedAt: reviewedAt,
            reviewComments: reviewComments,
            flags: flags,
            createdTickets: createdTickets,
            duration: totalDuration,
            isSubmitted: false,
            submittedAt: nil,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: now
        )
    }
    
    public func submit() -> Audit {
        let now = Date()
        
        return Audit(
            id: id,
            templateRef: templateRef,
            templateTitle: templateTitle,
            storeCode: storeCode,
            storeName: storeName,
            status: .submitted,
            startedBy: startedBy,
            startedByName: startedByName,
            startedAt: startedAt,
            finishedAt: finishedAt ?? now,
            pausedAt: pausedAt,
            resumedAt: resumedAt,
            score: score,
            maxScore: maxScore,
            percentage: percentage,
            passCount: passCount,
            failCount: failCount,
            naCount: naCount,
            totalQuestions: totalQuestions,
            responses: responses,
            photoAssets: photoAssets,
            comments: comments,
            signature: signature,
            reviewedBy: reviewedBy,
            reviewedByName: reviewedByName,
            reviewedAt: reviewedAt,
            reviewComments: reviewComments,
            flags: flags,
            createdTickets: createdTickets,
            duration: duration ?? now.timeIntervalSince(startedAt),
            isSubmitted: true,
            submittedAt: now,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: now
        )
    }
}
