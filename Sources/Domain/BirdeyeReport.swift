import Foundation
import CloudKit

/// Birdeye review and reputation management report
public struct BirdeyeReport: Identifiable, Codable {
    public let id: CKRecord.ID
    public let storeCode: String
    public let reportPeriod: ReportPeriod
    public let startDate: Date
    public let endDate: Date
    public let generatedBy: CKRecord.Reference
    public let generatedByName: String
    public let generatedAt: Date
    public let status: ReportStatus
    public let overallRating: Double?
    public let totalReviews: Int
    public let newReviews: Int
    public let responseRate: Double?
    public let averageResponseTime: TimeInterval?
    public let sentimentScore: Double?
    public let competitorAnalysis: CompetitorAnalysis?
    public let reviewBreakdown: ReviewBreakdown?
    public let platformData: [PlatformData]
    public let actionItems: [ActionItem]
    public let trends: TrendAnalysis?
    public let notes: String?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum ReportPeriod: String, CaseIterable, Codable {
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            case .custom: return "Custom"
            }
        }
        
        public var defaultDays: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .quarterly: return 90
            case .yearly: return 365
            case .custom: return 30
            }
        }
    }
    
    public enum ReportStatus: String, CaseIterable, Codable {
        case generating = "generating"
        case completed = "completed"
        case failed = "failed"
        case scheduled = "scheduled"
        
        public var displayName: String {
            switch self {
            case .generating: return "Generating"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .scheduled: return "Scheduled"
            }
        }
    }
    
    public struct CompetitorAnalysis: Codable {
        public let competitors: [CompetitorData]
        public let marketPosition: Int // 1-based ranking
        public let ratingGap: Double // difference from top competitor
        public let recommendations: [String]
        
        public struct CompetitorData: Codable {
            public let name: String
            public let rating: Double
            public let reviewCount: Int
            public let marketShare: Double?
        }
    }
    
    public struct ReviewBreakdown: Codable {
        public let fiveStars: Int
        public let fourStars: Int
        public let threeStars: Int
        public let twoStars: Int
        public let oneStar: Int
        public let averageRating: Double
        public let ratingDistribution: [Double] // percentages
        
        public var totalReviews: Int {
            return fiveStars + fourStars + threeStars + twoStars + oneStar
        }
        
        public var positiveReviews: Int {
            return fiveStars + fourStars
        }
        
        public var negativeReviews: Int {
            return twoStars + oneStar
        }
        
        public var positivePercentage: Double {
            guard totalReviews > 0 else { return 0 }
            return (Double(positiveReviews) / Double(totalReviews)) * 100
        }
    }
    
    public struct PlatformData: Codable, Identifiable {
        public let id: UUID
        public let platformName: String // Google, Yelp, Facebook, etc.
        public let rating: Double
        public let reviewCount: Int
        public let newReviews: Int
        public let responseRate: Double
        public let averageResponseTime: TimeInterval
        public let topKeywords: [String]
        public let sentimentScore: Double
        
        public init(
            id: UUID = UUID(),
            platformName: String,
            rating: Double,
            reviewCount: Int,
            newReviews: Int,
            responseRate: Double,
            averageResponseTime: TimeInterval,
            topKeywords: [String],
            sentimentScore: Double
        ) {
            self.id = id
            self.platformName = platformName
            self.rating = rating
            self.reviewCount = reviewCount
            self.newReviews = newReviews
            self.responseRate = responseRate
            self.averageResponseTime = averageResponseTime
            self.topKeywords = topKeywords
            self.sentimentScore = sentimentScore
        }
    }
    
    public struct ActionItem: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let description: String
        public let priority: ActionPriority
        public let category: ActionCategory
        public let platform: String?
        public let estimatedImpact: ImpactLevel
        public let dueDate: Date?
        public let isCompleted: Bool
        public let completedAt: Date?
        
        public enum ActionPriority: String, CaseIterable, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case urgent = "urgent"
            
            public var displayName: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .urgent: return "Urgent"
                }
            }
        }
        
        public enum ActionCategory: String, CaseIterable, Codable {
            case responseNeeded = "response_needed"
            case serviceImprovement = "service_improvement"
            case staffTraining = "staff_training"
            case processOptimization = "process_optimization"
            case marketingOpportunity = "marketing_opportunity"
            
            public var displayName: String {
                switch self {
                case .responseNeeded: return "Response Needed"
                case .serviceImprovement: return "Service Improvement"
                case .staffTraining: return "Staff Training"
                case .processOptimization: return "Process Optimization"
                case .marketingOpportunity: return "Marketing Opportunity"
                }
            }
        }
        
        public enum ImpactLevel: String, CaseIterable, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            
            public var displayName: String {
                switch self {
                case .low: return "Low Impact"
                case .medium: return "Medium Impact"
                case .high: return "High Impact"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            title: String,
            description: String,
            priority: ActionPriority,
            category: ActionCategory,
            platform: String? = nil,
            estimatedImpact: ImpactLevel,
            dueDate: Date? = nil,
            isCompleted: Bool = false,
            completedAt: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
            self.category = category
            self.platform = platform
            self.estimatedImpact = estimatedImpact
            self.dueDate = dueDate
            self.isCompleted = isCompleted
            self.completedAt = completedAt
        }
    }
    
    public struct TrendAnalysis: Codable {
        public let ratingTrend: TrendDirection
        public let reviewVolumeTrend: TrendDirection
        public let sentimentTrend: TrendDirection
        public let responseTimeTrend: TrendDirection
        public let keyInsights: [String]
        public let recommendations: [String]
        
        public enum TrendDirection: String, CaseIterable, Codable {
            case improving = "improving"
            case declining = "declining"
            case stable = "stable"
            case volatile = "volatile"
            
            public var displayName: String {
                switch self {
                case .improving: return "Improving"
                case .declining: return "Declining"
                case .stable: return "Stable"
                case .volatile: return "Volatile"
                }
            }
            
            public var color: String {
                switch self {
                case .improving: return "green"
                case .declining: return "red"
                case .stable: return "blue"
                case .volatile: return "orange"
                }
            }
        }
    }
    
    // Computed properties
    public var isCompleted: Bool {
        return status == .completed
    }
    
    public var reportPeriodDays: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    public var formattedRating: String {
        guard let rating = overallRating else { return "N/A" }
        return String(format: "%.1f", rating)
    }
    
    public var urgentActionItems: [ActionItem] {
        return actionItems.filter { $0.priority == .urgent && !$0.isCompleted }
    }
    
    public var pendingActionItems: [ActionItem] {
        return actionItems.filter { !$0.isCompleted }
    }
    
    public var completedActionItems: [ActionItem] {
        return actionItems.filter { $0.isCompleted }
    }
    
    public var topPlatform: PlatformData? {
        return platformData.max { $0.rating < $1.rating }
    }
    
    public var averageSentiment: Double {
        guard !platformData.isEmpty else { return 0 }
        return platformData.map { $0.sentimentScore }.reduce(0, +) / Double(platformData.count)
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let storeCode = record["storeCode"] as? String,
              let reportPeriodRaw = record["reportPeriod"] as? String,
              let reportPeriod = ReportPeriod(rawValue: reportPeriodRaw),
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let generatedBy = record["generatedBy"] as? CKRecord.Reference,
              let generatedByName = record["generatedByName"] as? String,
              let generatedAt = record["generatedAt"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = ReportStatus(rawValue: statusRaw),
              let totalReviews = record["totalReviews"] as? Int,
              let newReviews = record["newReviews"] as? Int,
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.storeCode = storeCode
        self.reportPeriod = reportPeriod
        self.startDate = startDate
        self.endDate = endDate
        self.generatedBy = generatedBy
        self.generatedByName = generatedByName
        self.generatedAt = generatedAt
        self.status = status
        self.overallRating = record["overallRating"] as? Double
        self.totalReviews = totalReviews
        self.newReviews = newReviews
        self.responseRate = record["responseRate"] as? Double
        self.averageResponseTime = record["averageResponseTime"] as? TimeInterval
        self.sentimentScore = record["sentimentScore"] as? Double
        self.notes = record["notes"] as? String
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON
        if let competitorData = record["competitorAnalysis"] as? Data {
            self.competitorAnalysis = try? JSONDecoder().decode(CompetitorAnalysis.self, from: competitorData)
        } else {
            self.competitorAnalysis = nil
        }
        
        if let reviewData = record["reviewBreakdown"] as? Data {
            self.reviewBreakdown = try? JSONDecoder().decode(ReviewBreakdown.self, from: reviewData)
        } else {
            self.reviewBreakdown = nil
        }
        
        if let platformDataBytes = record["platformData"] as? Data,
           let decodedPlatforms = try? JSONDecoder().decode([PlatformData].self, from: platformDataBytes) {
            self.platformData = decodedPlatforms
        } else {
            self.platformData = []
        }
        
        if let actionItemsData = record["actionItems"] as? Data,
           let decodedActions = try? JSONDecoder().decode([ActionItem].self, from: actionItemsData) {
            self.actionItems = decodedActions
        } else {
            self.actionItems = []
        }
        
        if let trendsData = record["trends"] as? Data {
            self.trends = try? JSONDecoder().decode(TrendAnalysis.self, from: trendsData)
        } else {
            self.trends = nil
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "BirdeyeReport", recordID: id)
        
        record["storeCode"] = storeCode
        record["reportPeriod"] = reportPeriod.rawValue
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["generatedBy"] = generatedBy
        record["generatedByName"] = generatedByName
        record["generatedAt"] = generatedAt
        record["status"] = status.rawValue
        record["overallRating"] = overallRating
        record["totalReviews"] = totalReviews
        record["newReviews"] = newReviews
        record["responseRate"] = responseRate
        record["averageResponseTime"] = averageResponseTime
        record["sentimentScore"] = sentimentScore
        record["notes"] = notes
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex data as JSON
        if let competitorAnalysis = competitorAnalysis,
           let competitorData = try? JSONEncoder().encode(competitorAnalysis) {
            record["competitorAnalysis"] = competitorData
        }
        
        if let reviewBreakdown = reviewBreakdown,
           let reviewData = try? JSONEncoder().encode(reviewBreakdown) {
            record["reviewBreakdown"] = reviewData
        }
        
        if !platformData.isEmpty,
           let platformDataBytes = try? JSONEncoder().encode(platformData) {
            record["platformData"] = platformDataBytes
        }
        
        if !actionItems.isEmpty,
           let actionItemsData = try? JSONEncoder().encode(actionItems) {
            record["actionItems"] = actionItemsData
        }
        
        if let trends = trends,
           let trendsData = try? JSONEncoder().encode(trends) {
            record["trends"] = trendsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> BirdeyeReport? {
        return BirdeyeReport(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        storeCode: String,
        reportPeriod: ReportPeriod,
        startDate: Date,
        endDate: Date,
        generatedBy: CKRecord.Reference,
        generatedByName: String
    ) -> BirdeyeReport {
        let now = Date()
        
        return BirdeyeReport(
            id: CKRecord.ID(recordName: UUID().uuidString),
            storeCode: storeCode,
            reportPeriod: reportPeriod,
            startDate: startDate,
            endDate: endDate,
            generatedBy: generatedBy,
            generatedByName: generatedByName,
            generatedAt: now,
            status: .generating,
            overallRating: nil,
            totalReviews: 0,
            newReviews: 0,
            responseRate: nil,
            averageResponseTime: nil,
            sentimentScore: nil,
            competitorAnalysis: nil,
            reviewBreakdown: nil,
            platformData: [],
            actionItems: [],
            trends: nil,
            notes: nil,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
    }
}
