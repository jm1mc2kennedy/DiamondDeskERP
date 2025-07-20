import Foundation
import CloudKit

/// Visual merchandising task for store photo compliance and approval workflow
public struct VisualMerchTask: Identifiable, Codable {
    public let id: CKRecord.ID
    public let storeCode: String
    public let title: String
    public let description: String
    public let category: VisualMerchCategory
    public let priority: TaskPriority
    public let assignedTo: CKRecord.Reference?
    public let createdBy: CKRecord.Reference
    public let dueDate: Date
    public let createdAt: Date
    public let updatedAt: Date
    public let status: VisualMerchStatus
    public let completedAt: Date?
    public let approvalRequired: Bool
    public let approvedBy: CKRecord.Reference?
    public let approvedAt: Date?
    public let rejectionReason: String?
    public let uploadCount: Int
    public let requiredPhotos: Int
    public let instructions: String?
    public let tags: [String]
    
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
            }
        }
    }
    
    public enum VisualMerchStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case submitted = "submitted"
        case underReview = "under_review"
        case approved = "approved"
        case rejected = "rejected"
        case completed = "completed"
        
        public var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .inProgress: return "In Progress"
            case .submitted: return "Submitted"
            case .underReview: return "Under Review"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            case .completed: return "Completed"
            }
        }
        
        public var requiresAction: Bool {
            switch self {
            case .pending, .inProgress, .rejected:
                return true
            case .submitted, .underReview, .approved, .completed:
                return false
            }
        }
    }
    
    public enum TaskPriority: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
        
        public var sortOrder: Int {
            switch self {
            case .urgent: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
        
        public var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
    }
    
    // Computed properties
    public var isOverdue: Bool {
        guard status.requiresAction else { return false }
        return Date() > dueDate
    }
    
    public var isCompleted: Bool {
        return status == .completed || status == .approved
    }
    
    public var needsApproval: Bool {
        return approvalRequired && status == .submitted
    }
    
    public var completionPercentage: Double {
        guard requiredPhotos > 0 else { return 0.0 }
        return min(Double(uploadCount) / Double(requiredPhotos), 1.0) * 100
    }
    
    public var daysSinceDue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let storeCode = record["storeCode"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let categoryRaw = record["category"] as? String,
              let category = VisualMerchCategory(rawValue: categoryRaw),
              let priorityRaw = record["priority"] as? String,
              let priority = TaskPriority(rawValue: priorityRaw),
              let createdBy = record["createdBy"] as? CKRecord.Reference,
              let dueDate = record["dueDate"] as? Date,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = VisualMerchStatus(rawValue: statusRaw),
              let approvalRequired = record["approvalRequired"] as? Bool,
              let uploadCount = record["uploadCount"] as? Int,
              let requiredPhotos = record["requiredPhotos"] as? Int else {
            return nil
        }
        
        self.id = record.recordID
        self.storeCode = storeCode
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.assignedTo = record["assignedTo"] as? CKRecord.Reference
        self.createdBy = createdBy
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.completedAt = record["completedAt"] as? Date
        self.approvalRequired = approvalRequired
        self.approvedBy = record["approvedBy"] as? CKRecord.Reference
        self.approvedAt = record["approvedAt"] as? Date
        self.rejectionReason = record["rejectionReason"] as? String
        self.uploadCount = uploadCount
        self.requiredPhotos = requiredPhotos
        self.instructions = record["instructions"] as? String
        
        // Decode tags from JSON
        if let tagsData = record["tags"] as? Data,
           let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
            self.tags = decodedTags
        } else {
            self.tags = []
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "VisualMerchTask", recordID: id)
        
        record["storeCode"] = storeCode
        record["title"] = title
        record["description"] = description
        record["category"] = category.rawValue
        record["priority"] = priority.rawValue
        record["assignedTo"] = assignedTo
        record["createdBy"] = createdBy
        record["dueDate"] = dueDate
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["status"] = status.rawValue
        record["completedAt"] = completedAt
        record["approvalRequired"] = approvalRequired
        record["approvedBy"] = approvedBy
        record["approvedAt"] = approvedAt
        record["rejectionReason"] = rejectionReason
        record["uploadCount"] = uploadCount
        record["requiredPhotos"] = requiredPhotos
        record["instructions"] = instructions
        
        // Encode tags as JSON
        if let tagsData = try? JSONEncoder().encode(tags) {
            record["tags"] = tagsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> VisualMerchTask? {
        return VisualMerchTask(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        storeCode: String,
        title: String,
        description: String,
        category: VisualMerchCategory,
        priority: TaskPriority = .medium,
        assignedTo: CKRecord.Reference? = nil,
        createdBy: CKRecord.Reference,
        dueDate: Date,
        requiredPhotos: Int = 1,
        approvalRequired: Bool = true,
        instructions: String? = nil,
        tags: [String] = []
    ) -> VisualMerchTask {
        let now = Date()
        return VisualMerchTask(
            id: CKRecord.ID(recordName: UUID().uuidString),
            storeCode: storeCode,
            title: title,
            description: description,
            category: category,
            priority: priority,
            assignedTo: assignedTo,
            createdBy: createdBy,
            dueDate: dueDate,
            createdAt: now,
            updatedAt: now,
            status: .pending,
            completedAt: nil,
            approvalRequired: approvalRequired,
            approvedBy: nil,
            approvedAt: nil,
            rejectionReason: nil,
            uploadCount: 0,
            requiredPhotos: requiredPhotos,
            instructions: instructions,
            tags: tags
        )
    }
    
    // MARK: - Helper Methods
    
    public func withStatus(_ newStatus: VisualMerchStatus) -> VisualMerchTask {
        let completedAt = (newStatus == .completed || newStatus == .approved) ? Date() : nil
        
        return VisualMerchTask(
            id: id,
            storeCode: storeCode,
            title: title,
            description: description,
            category: category,
            priority: priority,
            assignedTo: assignedTo,
            createdBy: createdBy,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: Date(),
            status: newStatus,
            completedAt: completedAt,
            approvalRequired: approvalRequired,
            approvedBy: approvedBy,
            approvedAt: approvedAt,
            rejectionReason: rejectionReason,
            uploadCount: uploadCount,
            requiredPhotos: requiredPhotos,
            instructions: instructions,
            tags: tags
        )
    }
    
    public func withApproval(approvedBy: CKRecord.Reference) -> VisualMerchTask {
        return VisualMerchTask(
            id: id,
            storeCode: storeCode,
            title: title,
            description: description,
            category: category,
            priority: priority,
            assignedTo: assignedTo,
            createdBy: createdBy,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: Date(),
            status: .approved,
            completedAt: Date(),
            approvalRequired: approvalRequired,
            approvedBy: approvedBy,
            approvedAt: Date(),
            rejectionReason: nil,
            uploadCount: uploadCount,
            requiredPhotos: requiredPhotos,
            instructions: instructions,
            tags: tags
        )
    }
    
    public func withRejection(reason: String) -> VisualMerchTask {
        return VisualMerchTask(
            id: id,
            storeCode: storeCode,
            title: title,
            description: description,
            category: category,
            priority: priority,
            assignedTo: assignedTo,
            createdBy: createdBy,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: Date(),
            status: .rejected,
            completedAt: nil,
            approvalRequired: approvalRequired,
            approvedBy: nil,
            approvedAt: nil,
            rejectionReason: reason,
            uploadCount: uploadCount,
            requiredPhotos: requiredPhotos,
            instructions: instructions,
            tags: tags
        )
    }
    
    public func withUploadCount(_ count: Int) -> VisualMerchTask {
        let newStatus: VisualMerchStatus = {
            if count >= requiredPhotos && status == .inProgress {
                return approvalRequired ? .submitted : .completed
            }
            return status
        }()
        
        return VisualMerchTask(
            id: id,
            storeCode: storeCode,
            title: title,
            description: description,
            category: category,
            priority: priority,
            assignedTo: assignedTo,
            createdBy: createdBy,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: Date(),
            status: newStatus,
            completedAt: newStatus == .completed ? Date() : completedAt,
            approvalRequired: approvalRequired,
            approvedBy: approvedBy,
            approvedAt: approvedAt,
            rejectionReason: rejectionReason,
            uploadCount: count,
            requiredPhotos: requiredPhotos,
            instructions: instructions,
            tags: tags
        )
    }
}
