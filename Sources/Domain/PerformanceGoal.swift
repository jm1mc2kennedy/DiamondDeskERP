import Foundation
import CloudKit

/// Performance goal and target setting for users, stores, and departments
public struct PerformanceGoal: Identifiable, Codable {
    public let id: CKRecord.ID
    public let title: String
    public let description: String?
    public let goalType: GoalType
    public let metric: PerformanceMetric
    public let targetValue: Double
    public let currentValue: Double
    public let startDate: Date
    public let endDate: Date
    public let createdAt: Date
    public let updatedAt: Date
    public let createdBy: CKRecord.Reference
    public let assignedTo: CKRecord.Reference?
    public let storeCode: String?
    public let department: String?
    public let category: GoalCategory
    public let priority: GoalPriority
    public let status: GoalStatus
    public let isActive: Bool
    public let isRecurring: Bool
    public let recurringPeriod: RecurringPeriod?
    public let parentGoalId: CKRecord.Reference?
    public let tags: [String]
    public let milestones: [GoalMilestone]
    public let notes: String?
    public let completedAt: Date?
    
    public enum GoalType: String, CaseIterable, Codable {
        case individual = "individual"
        case store = "store"
        case department = "department"
        case company = "company"
        case team = "team"
        
        public var displayName: String {
            switch self {
            case .individual: return "Individual"
            case .store: return "Store"
            case .department: return "Department"
            case .company: return "Company"
            case .team: return "Team"
            }
        }
    }
    
    public enum PerformanceMetric: String, CaseIterable, Codable {
        case sales = "sales"
        case revenue = "revenue"
        case profit = "profit"
        case customerSatisfaction = "customer_satisfaction"
        case taskCompletion = "task_completion"
        case auditScore = "audit_score"
        case attendanceRate = "attendance_rate"
        case trainingCompletion = "training_completion"
        case visualMerchCompliance = "visual_merch_compliance"
        case ticketResolution = "ticket_resolution"
        case responseTime = "response_time"
        case callVolume = "call_volume"
        case conversionRate = "conversion_rate"
        case averageOrderValue = "average_order_value"
        case customerRetention = "customer_retention"
        case inventoryTurnover = "inventory_turnover"
        case shrinkage = "shrinkage"
        case mystery_shopper = "mystery_shopper"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
            case .sales: return "Sales"
            case .revenue: return "Revenue"
            case .profit: return "Profit"
            case .customerSatisfaction: return "Customer Satisfaction"
            case .taskCompletion: return "Task Completion"
            case .auditScore: return "Audit Score"
            case .attendanceRate: return "Attendance Rate"
            case .trainingCompletion: return "Training Completion"
            case .visualMerchCompliance: return "Visual Merch Compliance"
            case .ticketResolution: return "Ticket Resolution"
            case .responseTime: return "Response Time"
            case .callVolume: return "Call Volume"
            case .conversionRate: return "Conversion Rate"
            case .averageOrderValue: return "Average Order Value"
            case .customerRetention: return "Customer Retention"
            case .inventoryTurnover: return "Inventory Turnover"
            case .shrinkage: return "Shrinkage"
            case .mystery_shopper: return "Mystery Shopper"
            case .custom: return "Custom"
            }
        }
        
        public var unit: String {
            switch self {
            case .sales, .revenue, .profit, .averageOrderValue:
                return "$"
            case .customerSatisfaction, .auditScore, .attendanceRate, .trainingCompletion, .visualMerchCompliance, .conversionRate, .customerRetention, .mystery_shopper:
                return "%"
            case .taskCompletion, .callVolume:
                return "count"
            case .responseTime:
                return "hours"
            case .inventoryTurnover:
                return "turns"
            case .shrinkage:
                return "%"
            case .ticketResolution:
                return "tickets"
            case .custom:
                return ""
            }
        }
        
        public var isPercentage: Bool {
            return unit == "%"
        }
        
        public var isCurrency: Bool {
            return unit == "$"
        }
    }
    
    public enum GoalCategory: String, CaseIterable, Codable {
        case sales = "sales"
        case operations = "operations"
        case customerService = "customer_service"
        case compliance = "compliance"
        case training = "training"
        case quality = "quality"
        case efficiency = "efficiency"
        case growth = "growth"
        case retention = "retention"
        case satisfaction = "satisfaction"
        
        public var displayName: String {
            switch self {
            case .sales: return "Sales"
            case .operations: return "Operations"
            case .customerService: return "Customer Service"
            case .compliance: return "Compliance"
            case .training: return "Training"
            case .quality: return "Quality"
            case .efficiency: return "Efficiency"
            case .growth: return "Growth"
            case .retention: return "Retention"
            case .satisfaction: return "Satisfaction"
            }
        }
    }
    
    public enum GoalPriority: String, CaseIterable, Codable {
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
        
        public var sortOrder: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }
    
    public enum GoalStatus: String, CaseIterable, Codable {
        case draft = "draft"
        case active = "active"
        case paused = "paused"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        
        public var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .active: return "Active"
            case .paused: return "Paused"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
        
        public var isActive: Bool {
            return self == .active
        }
        
        public var isCompleted: Bool {
            return self == .completed || self == .failed
        }
    }
    
    public enum RecurringPeriod: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        
        public var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            }
        }
        
        public var calendarComponent: Calendar.Component {
            switch self {
            case .daily: return .day
            case .weekly: return .weekOfYear
            case .monthly: return .month
            case .quarterly: return .quarter
            case .yearly: return .year
            }
        }
    }
    
    public struct GoalMilestone: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let description: String?
        public let targetValue: Double
        public let targetDate: Date
        public let isCompleted: Bool
        public let completedAt: Date?
        public let notes: String?
        
        public init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            targetValue: Double,
            targetDate: Date,
            isCompleted: Bool = false,
            completedAt: Date? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.targetValue = targetValue
            self.targetDate = targetDate
            self.isCompleted = isCompleted
            self.completedAt = completedAt
            self.notes = notes
        }
    }
    
    // Computed properties
    public var progressPercentage: Double {
        guard targetValue > 0 else { return 0.0 }
        return min((currentValue / targetValue) * 100, 100.0)
    }
    
    public var remainingValue: Double {
        return max(targetValue - currentValue, 0.0)
    }
    
    public var isOverdue: Bool {
        return Date() > endDate && !status.isCompleted
    }
    
    public var isCompleted: Bool {
        return status == .completed || currentValue >= targetValue
    }
    
    public var daysRemaining: Int {
        guard !status.isCompleted else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(days, 0)
    }
    
    public var hoursRemaining: Int {
        guard !status.isCompleted else { return 0 }
        let calendar = Calendar.current
        let hours = calendar.dateComponents([.hour], from: Date(), to: endDate).hour ?? 0
        return max(hours, 0)
    }
    
    public var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    public var elapsedPercentage: Double {
        let elapsed = Date().timeIntervalSince(startDate)
        let total = duration
        guard total > 0 else { return 0.0 }
        return min((elapsed / total) * 100, 100.0)
    }
    
    public var completedMilestones: [GoalMilestone] {
        return milestones.filter { $0.isCompleted }
    }
    
    public var pendingMilestones: [GoalMilestone] {
        return milestones.filter { !$0.isCompleted }
    }
    
    public var nextMilestone: GoalMilestone? {
        return pendingMilestones.min { $0.targetDate < $1.targetDate }
    }
    
    public var formattedCurrentValue: String {
        if metric.isCurrency {
            return String(format: "$%.2f", currentValue)
        } else if metric.isPercentage {
            return String(format: "%.1f%%", currentValue)
        } else {
            return String(format: "%.0f", currentValue)
        }
    }
    
    public var formattedTargetValue: String {
        if metric.isCurrency {
            return String(format: "$%.2f", targetValue)
        } else if metric.isPercentage {
            return String(format: "%.1f%%", targetValue)
        } else {
            return String(format: "%.0f", targetValue)
        }
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let title = record["title"] as? String,
              let goalTypeRaw = record["goalType"] as? String,
              let goalType = GoalType(rawValue: goalTypeRaw),
              let metricRaw = record["metric"] as? String,
              let metric = PerformanceMetric(rawValue: metricRaw),
              let targetValue = record["targetValue"] as? Double,
              let currentValue = record["currentValue"] as? Double,
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let createdBy = record["createdBy"] as? CKRecord.Reference,
              let categoryRaw = record["category"] as? String,
              let category = GoalCategory(rawValue: categoryRaw),
              let priorityRaw = record["priority"] as? String,
              let priority = GoalPriority(rawValue: priorityRaw),
              let statusRaw = record["status"] as? String,
              let status = GoalStatus(rawValue: statusRaw),
              let isActive = record["isActive"] as? Bool,
              let isRecurring = record["isRecurring"] as? Bool else {
            return nil
        }
        
        self.id = record.recordID
        self.title = title
        self.description = record["description"] as? String
        self.goalType = goalType
        self.metric = metric
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.assignedTo = record["assignedTo"] as? CKRecord.Reference
        self.storeCode = record["storeCode"] as? String
        self.department = record["department"] as? String
        self.category = category
        self.priority = priority
        self.status = status
        self.isActive = isActive
        self.isRecurring = isRecurring
        self.parentGoalId = record["parentGoalId"] as? CKRecord.Reference
        self.notes = record["notes"] as? String
        self.completedAt = record["completedAt"] as? Date
        
        // Decode recurring period
        if let recurringPeriodRaw = record["recurringPeriod"] as? String {
            self.recurringPeriod = RecurringPeriod(rawValue: recurringPeriodRaw)
        } else {
            self.recurringPeriod = nil
        }
        
        // Decode tags from JSON
        if let tagsData = record["tags"] as? Data,
           let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
            self.tags = decodedTags
        } else {
            self.tags = []
        }
        
        // Decode milestones from JSON
        if let milestonesData = record["milestones"] as? Data,
           let decodedMilestones = try? JSONDecoder().decode([GoalMilestone].self, from: milestonesData) {
            self.milestones = decodedMilestones
        } else {
            self.milestones = []
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "PerformanceGoal", recordID: id)
        
        record["title"] = title
        record["description"] = description
        record["goalType"] = goalType.rawValue
        record["metric"] = metric.rawValue
        record["targetValue"] = targetValue
        record["currentValue"] = currentValue
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["createdBy"] = createdBy
        record["assignedTo"] = assignedTo
        record["storeCode"] = storeCode
        record["department"] = department
        record["category"] = category.rawValue
        record["priority"] = priority.rawValue
        record["status"] = status.rawValue
        record["isActive"] = isActive
        record["isRecurring"] = isRecurring
        record["recurringPeriod"] = recurringPeriod?.rawValue
        record["parentGoalId"] = parentGoalId
        record["notes"] = notes
        record["completedAt"] = completedAt
        
        // Encode tags as JSON
        if let tagsData = try? JSONEncoder().encode(tags) {
            record["tags"] = tagsData
        }
        
        // Encode milestones as JSON
        if let milestonesData = try? JSONEncoder().encode(milestones) {
            record["milestones"] = milestonesData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> PerformanceGoal? {
        return PerformanceGoal(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        title: String,
        description: String? = nil,
        goalType: GoalType,
        metric: PerformanceMetric,
        targetValue: Double,
        startDate: Date,
        endDate: Date,
        createdBy: CKRecord.Reference,
        assignedTo: CKRecord.Reference? = nil,
        storeCode: String? = nil,
        department: String? = nil,
        category: GoalCategory,
        priority: GoalPriority = .medium,
        isRecurring: Bool = false,
        recurringPeriod: RecurringPeriod? = nil,
        parentGoalId: CKRecord.Reference? = nil,
        tags: [String] = [],
        milestones: [GoalMilestone] = [],
        notes: String? = nil
    ) -> PerformanceGoal {
        let now = Date()
        return PerformanceGoal(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: title,
            description: description,
            goalType: goalType,
            metric: metric,
            targetValue: targetValue,
            currentValue: 0.0,
            startDate: startDate,
            endDate: endDate,
            createdAt: now,
            updatedAt: now,
            createdBy: createdBy,
            assignedTo: assignedTo,
            storeCode: storeCode,
            department: department,
            category: category,
            priority: priority,
            status: .draft,
            isActive: false,
            isRecurring: isRecurring,
            recurringPeriod: recurringPeriod,
            parentGoalId: parentGoalId,
            tags: tags,
            milestones: milestones,
            notes: notes,
            completedAt: nil
        )
    }
    
    // MARK: - Helper Methods
    
    public func updateProgress(_ newValue: Double) -> PerformanceGoal {
        let newStatus: GoalStatus = {
            if newValue >= targetValue {
                return .completed
            } else if status == .draft {
                return .active
            } else {
                return status
            }
        }()
        
        let completedAt = newStatus == .completed ? Date() : nil
        
        return PerformanceGoal(
            id: id,
            title: title,
            description: description,
            goalType: goalType,
            metric: metric,
            targetValue: targetValue,
            currentValue: newValue,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: Date(),
            createdBy: createdBy,
            assignedTo: assignedTo,
            storeCode: storeCode,
            department: department,
            category: category,
            priority: priority,
            status: newStatus,
            isActive: newStatus == .active,
            isRecurring: isRecurring,
            recurringPeriod: recurringPeriod,
            parentGoalId: parentGoalId,
            tags: tags,
            milestones: milestones,
            notes: notes,
            completedAt: completedAt
        )
    }
    
    public func activate() -> PerformanceGoal {
        return PerformanceGoal(
            id: id,
            title: title,
            description: description,
            goalType: goalType,
            metric: metric,
            targetValue: targetValue,
            currentValue: currentValue,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: Date(),
            createdBy: createdBy,
            assignedTo: assignedTo,
            storeCode: storeCode,
            department: department,
            category: category,
            priority: priority,
            status: .active,
            isActive: true,
            isRecurring: isRecurring,
            recurringPeriod: recurringPeriod,
            parentGoalId: parentGoalId,
            tags: tags,
            milestones: milestones,
            notes: notes,
            completedAt: nil
        )
    }
    
    public func complete() -> PerformanceGoal {
        return PerformanceGoal(
            id: id,
            title: title,
            description: description,
            goalType: goalType,
            metric: metric,
            targetValue: targetValue,
            currentValue: currentValue >= targetValue ? currentValue : targetValue,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: Date(),
            createdBy: createdBy,
            assignedTo: assignedTo,
            storeCode: storeCode,
            department: department,
            category: category,
            priority: priority,
            status: .completed,
            isActive: false,
            isRecurring: isRecurring,
            recurringPeriod: recurringPeriod,
            parentGoalId: parentGoalId,
            tags: tags,
            milestones: milestones,
            notes: notes,
            completedAt: Date()
        )
    }
    
    public func updateMilestone(_ milestoneId: UUID, completed: Bool) -> PerformanceGoal {
        let updatedMilestones = milestones.map { milestone in
            if milestone.id == milestoneId {
                return GoalMilestone(
                    id: milestone.id,
                    title: milestone.title,
                    description: milestone.description,
                    targetValue: milestone.targetValue,
                    targetDate: milestone.targetDate,
                    isCompleted: completed,
                    completedAt: completed ? Date() : nil,
                    notes: milestone.notes
                )
            }
            return milestone
        }
        
        return PerformanceGoal(
            id: id,
            title: title,
            description: description,
            goalType: goalType,
            metric: metric,
            targetValue: targetValue,
            currentValue: currentValue,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: Date(),
            createdBy: createdBy,
            assignedTo: assignedTo,
            storeCode: storeCode,
            department: department,
            category: category,
            priority: priority,
            status: status,
            isActive: isActive,
            isRecurring: isRecurring,
            recurringPeriod: recurringPeriod,
            parentGoalId: parentGoalId,
            tags: tags,
            milestones: updatedMilestones,
            notes: notes,
            completedAt: completedAt
        )
    }
}
