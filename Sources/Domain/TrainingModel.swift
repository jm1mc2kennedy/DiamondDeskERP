import Foundation
import CloudKit

enum TrainingStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case expired = "expired"
    case failed = "failed"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .expired: return "Expired"
        case .failed: return "Failed"
        }
    }
}

enum TrainingDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
}

struct TrainingCourse: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var description: String
    var category: String
    var difficulty: TrainingDifficulty
    var estimatedDuration: TimeInterval // in seconds
    var prerequisites: [String] // Course IDs
    var tags: [String]
    var contentUrl: String? // URL to training content
    var thumbnailUrl: String? // Course thumbnail
    var isActive: Bool
    var createdBy: User
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        title: String,
        description: String,
        category: String,
        difficulty: TrainingDifficulty,
        estimatedDuration: TimeInterval,
        prerequisites: [String] = [],
        tags: [String] = [],
        contentUrl: String? = nil,
        thumbnailUrl: String? = nil,
        isActive: Bool = true,
        createdBy: User,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.prerequisites = prerequisites
        self.tags = tags
        self.contentUrl = contentUrl
        self.thumbnailUrl = thumbnailUrl
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // CloudKit integration
    init?(record: CKRecord) {
        guard
            let id = record["id"] as? String,
            let title = record["title"] as? String,
            let description = record["description"] as? String,
            let category = record["category"] as? String,
            let difficultyRaw = record["difficulty"] as? String,
            let difficulty = TrainingDifficulty(rawValue: difficultyRaw),
            let estimatedDuration = record["estimatedDuration"] as? Double,
            let isActive = record["isActive"] as? Bool,
            let createdByData = record["createdBy"] as? Data,
            let createdBy = try? JSONDecoder().decode(User.self, from: createdByData),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Optional fields
        self.prerequisites = record["prerequisites"] as? [String] ?? []
        self.tags = record["tags"] as? [String] ?? []
        self.contentUrl = record["contentUrl"] as? String
        self.thumbnailUrl = record["thumbnailUrl"] as? String
    }
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "TrainingCourse", recordID: CKRecord.ID(recordName: id))
        
        record["id"] = id
        record["title"] = title
        record["description"] = description
        record["category"] = category
        record["difficulty"] = difficulty.rawValue
        record["estimatedDuration"] = estimatedDuration
        record["isActive"] = isActive
        record["createdBy"] = try JSONEncoder().encode(createdBy)
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        if !prerequisites.isEmpty {
            record["prerequisites"] = prerequisites
        }
        
        if !tags.isEmpty {
            record["tags"] = tags
        }
        
        if let contentUrl = contentUrl {
            record["contentUrl"] = contentUrl
        }
        
        if let thumbnailUrl = thumbnailUrl {
            record["thumbnailUrl"] = thumbnailUrl
        }
        
        return record
    }
}

struct TrainingProgress: Identifiable, Hashable, Codable {
    let id: String
    var courseId: String
    var userId: String
    var status: TrainingStatus
    var progressPercentage: Double // 0.0 to 1.0
    var completedSections: [String]
    var timeSpent: TimeInterval // in seconds
    var lastAccessedAt: Date?
    var completedAt: Date?
    var certificateUrl: String? // Certificate download URL
    var score: Double? // Final score if applicable
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        courseId: String,
        userId: String,
        status: TrainingStatus = .notStarted,
        progressPercentage: Double = 0.0,
        completedSections: [String] = [],
        timeSpent: TimeInterval = 0,
        lastAccessedAt: Date? = nil,
        completedAt: Date? = nil,
        certificateUrl: String? = nil,
        score: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.courseId = courseId
        self.userId = userId
        self.status = status
        self.progressPercentage = progressPercentage
        self.completedSections = completedSections
        self.timeSpent = timeSpent
        self.lastAccessedAt = lastAccessedAt
        self.completedAt = completedAt
        self.certificateUrl = certificateUrl
        self.score = score
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // CloudKit integration
    init?(record: CKRecord) {
        guard
            let id = record["id"] as? String,
            let courseId = record["courseId"] as? String,
            let userId = record["userId"] as? String,
            let statusRaw = record["status"] as? String,
            let status = TrainingStatus(rawValue: statusRaw),
            let progressPercentage = record["progressPercentage"] as? Double,
            let timeSpent = record["timeSpent"] as? Double,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.courseId = courseId
        self.userId = userId
        self.status = status
        self.progressPercentage = progressPercentage
        self.timeSpent = timeSpent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Optional fields
        self.completedSections = record["completedSections"] as? [String] ?? []
        self.lastAccessedAt = record["lastAccessedAt"] as? Date
        self.completedAt = record["completedAt"] as? Date
        self.certificateUrl = record["certificateUrl"] as? String
        self.score = record["score"] as? Double
    }
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "TrainingProgress", recordID: CKRecord.ID(recordName: id))
        
        record["id"] = id
        record["courseId"] = courseId
        record["userId"] = userId
        record["status"] = status.rawValue
        record["progressPercentage"] = progressPercentage
        record["timeSpent"] = timeSpent
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        if !completedSections.isEmpty {
            record["completedSections"] = completedSections
        }
        
        if let lastAccessedAt = lastAccessedAt {
            record["lastAccessedAt"] = lastAccessedAt
        }
        
        if let completedAt = completedAt {
            record["completedAt"] = completedAt
        }
        
        if let certificateUrl = certificateUrl {
            record["certificateUrl"] = certificateUrl
        }
        
        if let score = score {
            record["score"] = score
        }
        
        return record
    }
}
