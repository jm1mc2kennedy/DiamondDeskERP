import Foundation
import CloudKit

/// Sales target management and tracking model
public struct SalesTarget: Identifiable, Codable {
    public let id: CKRecord.ID
    public let targetName: String
    public let targetType: TargetType
    public let targetLevel: TargetLevel
    public let targetScope: TargetScope
    public let storeCode: String?
    public let storeName: String?
    public let employeeRef: CKRecord.Reference?
    public let employeeName: String?
    public let categoryId: String?
    public let categoryName: String?
    public let productId: String?
    public let productName: String?
    public let period: TargetPeriod
    public let startDate: Date
    public let endDate: Date
    public let fiscalYear: Int
    public let fiscalQuarter: Int?
    public let fiscalMonth: Int?
    public let targets: TargetMetrics
    public let achievements: AchievementMetrics
    public let performance: PerformanceMetrics
    public let tracking: TrackingInfo
    public let incentives: IncentiveStructure
    public let adjustments: [TargetAdjustment]
    public let milestones: [TargetMilestone]
    public let alerts: [TargetAlert]
    public let notes: String?
    public let status: TargetStatus
    public let isActive: Bool
    public let createdBy: CKRecord.Reference
    public let createdByName: String
    public let approvedBy: CKRecord.Reference?
    public let approvedByName: String?
    public let approvedAt: Date?
    public let lastReviewed: Date?
    public let reviewedBy: CKRecord.Reference?
    public let reviewedByName: String?
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum TargetType: String, CaseIterable, Codable {
        case revenue = "revenue"
        case units = "units"
        case margin = "margin"
        case growth = "growth"
        case newCustomers = "new_customers"
        case retention = "retention"
        case upsell = "upsell"
        case crossSell = "cross_sell"
        case conversion = "conversion"
        case attachRate = "attach_rate"
        case averageTicket = "average_ticket"
        case transactions = "transactions"
        case composite = "composite"
        
        public var displayName: String {
            switch self {
            case .revenue: return "Revenue"
            case .units: return "Units Sold"
            case .margin: return "Gross Margin"
            case .growth: return "Growth Rate"
            case .newCustomers: return "New Customers"
            case .retention: return "Customer Retention"
            case .upsell: return "Upselling"
            case .crossSell: return "Cross-selling"
            case .conversion: return "Conversion Rate"
            case .attachRate: return "Attach Rate"
            case .averageTicket: return "Average Ticket"
            case .transactions: return "Transaction Count"
            case .composite: return "Composite Score"
            }
        }
        
        public var unit: String {
            switch self {
            case .revenue, .margin: return "$"
            case .units, .newCustomers, .transactions: return "units"
            case .growth, .retention, .upsell, .crossSell, .conversion, .attachRate: return "%"
            case .averageTicket: return "$/transaction"
            case .composite: return "score"
            }
        }
    }
    
    public enum TargetLevel: String, CaseIterable, Codable {
        case company = "company"
        case region = "region"
        case district = "district"
        case store = "store"
        case department = "department"
        case category = "category"
        case product = "product"
        case employee = "employee"
        case team = "team"
        
        public var displayName: String {
            switch self {
            case .company: return "Company"
            case .region: return "Region"
            case .district: return "District"
            case .store: return "Store"
            case .department: return "Department"
            case .category: return "Category"
            case .product: return "Product"
            case .employee: return "Employee"
            case .team: return "Team"
            }
        }
    }
    
    public enum TargetScope: String, CaseIterable, Codable {
        case individual = "individual"
        case team = "team"
        case department = "department"
        case store = "store"
        case district = "district"
        case region = "region"
        case company = "company"
        
        public var displayName: String {
            switch self {
            case .individual: return "Individual"
            case .team: return "Team"
            case .department: return "Department"
            case .store: return "Store"
            case .district: return "District"
            case .region: return "Region"
            case .company: return "Company"
            }
        }
    }
    
    public enum TargetPeriod: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case semiAnnual = "semi_annual"
        case annual = "annual"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .semiAnnual: return "Semi-Annual"
            case .annual: return "Annual"
            case .custom: return "Custom"
            }
        }
        
        public var duration: TimeInterval {
            switch self {
            case .daily: return 24 * 3600
            case .weekly: return 7 * 24 * 3600
            case .monthly: return 30 * 24 * 3600
            case .quarterly: return 90 * 24 * 3600
            case .semiAnnual: return 180 * 24 * 3600
            case .annual: return 365 * 24 * 3600
            case .custom: return 0
            }
        }
    }
    
    public enum TargetStatus: String, CaseIterable, Codable {
        case draft = "draft"
        case pending = "pending"
        case active = "active"
        case paused = "paused"
        case completed = "completed"
        case cancelled = "cancelled"
        case archived = "archived"
        
        public var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .pending: return "Pending Approval"
            case .active: return "Active"
            case .paused: return "Paused"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            case .archived: return "Archived"
            }
        }
        
        public var isActive: Bool {
            return self == .active
        }
        
        public var canEdit: Bool {
            switch self {
            case .draft, .pending, .paused:
                return true
            case .active, .completed, .cancelled, .archived:
                return false
            }
        }
    }
    
    public struct TargetMetrics: Codable {
        public let primaryTarget: TargetValue
        public let stretchTarget: TargetValue?
        public let thresholdTarget: TargetValue? // Minimum acceptable
        public let benchmarkTarget: TargetValue? // Industry/company benchmark
        public let historicalBaseline: TargetValue? // Previous period performance
        public let weightedTargets: [WeightedTarget] // For composite targets
        public let subTargets: [SubTarget] // Breakdown by time periods
        
        public struct TargetValue: Codable {
            public let value: Double
            public let unit: String
            public let displayValue: String
            public let confidence: Double? // 0-100
            public let methodology: String? // How target was calculated
            public let source: String? // Data source
            public let lastUpdated: Date
        }
        
        public struct WeightedTarget: Codable, Identifiable {
            public let id: UUID
            public let name: String
            public let targetType: TargetType
            public let target: Double
            public let weight: Double // 0-100
            public let current: Double
            public let achievement: Double
            
            public init(
                id: UUID = UUID(),
                name: String,
                targetType: TargetType,
                target: Double,
                weight: Double,
                current: Double = 0
            ) {
                self.id = id
                self.name = name
                self.targetType = targetType
                self.target = target
                self.weight = weight
                self.current = current
                self.achievement = target > 0 ? (current / target) * 100 : 0
            }
        }
        
        public struct SubTarget: Codable, Identifiable {
            public let id: UUID
            public let period: String
            public let startDate: Date
            public let endDate: Date
            public let target: Double
            public let achieved: Double
            public let progress: Double // 0-100
            public let onTrack: Bool
            
            public init(
                id: UUID = UUID(),
                period: String,
                startDate: Date,
                endDate: Date,
                target: Double,
                achieved: Double = 0
            ) {
                self.id = id
                self.period = period
                self.startDate = startDate
                self.endDate = endDate
                self.target = target
                self.achieved = achieved
                self.progress = target > 0 ? (achieved / target) * 100 : 0
                self.onTrack = self.progress >= 75 // Simplified logic
            }
        }
    }
    
    public struct AchievementMetrics: Codable {
        public let currentValue: Double
        public let achievementPercentage: Double
        public let achievementStatus: AchievementStatus
        public let runRate: Double // Projected end value based on current pace
        public let projectedAchievement: Double
        public let varianceFromTarget: Double
        public let variancePercentage: Double
        public let timeElapsed: Double // Percentage of target period completed
        public let timeRemaining: TimeInterval
        public let requiredRunRate: Double // Rate needed to hit target
        public let trend: TrendDirection
        public let lastCalculated: Date
        
        public enum AchievementStatus: String, CaseIterable, Codable {
            case notStarted = "not_started"
            case onTrack = "on_track"
            case aheadOfTarget = "ahead_of_target"
            case behindTarget = "behind_target"
            case atRisk = "at_risk"
            case exceeded = "exceeded"
            case missed = "missed"
            case completed = "completed"
            
            public var displayName: String {
                switch self {
                case .notStarted: return "Not Started"
                case .onTrack: return "On Track"
                case .aheadOfTarget: return "Ahead of Target"
                case .behindTarget: return "Behind Target"
                case .atRisk: return "At Risk"
                case .exceeded: return "Exceeded"
                case .missed: return "Missed"
                case .completed: return "Completed"
                }
            }
            
            public var color: String {
                switch self {
                case .notStarted: return "gray"
                case .onTrack: return "green"
                case .aheadOfTarget: return "blue"
                case .behindTarget: return "yellow"
                case .atRisk: return "orange"
                case .exceeded: return "purple"
                case .missed: return "red"
                case .completed: return "green"
                }
            }
        }
        
        public enum TrendDirection: String, CaseIterable, Codable {
            case stronglyPositive = "strongly_positive"
            case positive = "positive"
            case stable = "stable"
            case negative = "negative"
            case stronglyNegative = "strongly_negative"
            
            public var displayName: String {
                switch self {
                case .stronglyPositive: return "Strongly Positive"
                case .positive: return "Positive"
                case .stable: return "Stable"
                case .negative: return "Negative"
                case .stronglyNegative: return "Strongly Negative"
                }
            }
            
            public var icon: String {
                switch self {
                case .stronglyPositive: return "📈"
                case .positive: return "↗️"
                case .stable: return "→"
                case .negative: return "↘️"
                case .stronglyNegative: return "📉"
                }
            }
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let dailyPerformance: [DailyPerformance]
        public let weeklyAverages: WeeklyAverages
        public let monthlyTrends: MonthlyTrends
        public let seasonalFactors: SeasonalFactors
        public let comparativeAnalysis: ComparativeAnalysis
        public let riskFactors: [RiskFactor]
        public let accelerators: [Accelerator]
        
        public struct DailyPerformance: Codable, Identifiable {
            public let id: UUID
            public let date: Date
            public let actual: Double
            public let target: Double
            public let achievement: Double
            public let cumulativeActual: Double
            public let cumulativeTarget: Double
            public let cumulativeAchievement: Double
            public let notes: String?
            
            public init(
                id: UUID = UUID(),
                date: Date,
                actual: Double,
                target: Double,
                cumulativeActual: Double = 0,
                cumulativeTarget: Double = 0,
                notes: String? = nil
            ) {
                self.id = id
                self.date = date
                self.actual = actual
                self.target = target
                self.achievement = target > 0 ? (actual / target) * 100 : 0
                self.cumulativeActual = cumulativeActual
                self.cumulativeTarget = cumulativeTarget
                self.cumulativeAchievement = cumulativeTarget > 0 ? (cumulativeActual / cumulativeTarget) * 100 : 0
                self.notes = notes
            }
        }
        
        public struct WeeklyAverages: Codable {
            public let averageDaily: Double
            public let bestDay: Double
            public let worstDay: Double
            public let consistency: Double // Coefficient of variation
            public let weekOverWeekGrowth: Double
        }
        
        public struct MonthlyTrends: Codable {
            public let monthlyProgress: [MonthlyProgress]
            public let bestMonth: MonthlyProgress?
            public let worstMonth: MonthlyProgress?
            public let averageMonthly: Double
            public let monthOverMonthGrowth: Double
            
            public struct MonthlyProgress: Codable {
                public let month: Int
                public let year: Int
                public let actual: Double
                public let target: Double
                public let achievement: Double
            }
        }
        
        public struct SeasonalFactors: Codable {
            public let hasSeasonality: Bool
            public let peakPeriods: [String]
            public let lowPeriods: [String]
            public let seasonalAdjustment: Double
            public let yearOverYearComparison: Double
        }
        
        public struct ComparativeAnalysis: Codable {
            public let peerComparison: PeerComparison
            public let historicalComparison: HistoricalComparison
            public let benchmarkComparison: BenchmarkComparison
            
            public struct PeerComparison: Codable {
                public let rank: Int?
                public let totalPeers: Int
                public let percentile: Double?
                public let averagePeerPerformance: Double
                public let topPerformerValue: Double?
            }
            
            public struct HistoricalComparison: Codable {
                public let previousPeriod: Double
                public let sameperiodLastYear: Double
                public let threeyearAverage: Double
                public let bestHistorical: Double
                public let improvement: Double
            }
            
            public struct BenchmarkComparison: Codable {
                public let industryBenchmark: Double?
                public let companyBenchmark: Double
                public let regionalBenchmark: Double?
                public let performanceVsBenchmarks: Double
            }
        }
        
        public struct RiskFactor: Codable, Identifiable {
            public let id: UUID
            public let factor: String
            public let impact: RiskImpact
            public let probability: Double
            public let mitigation: String?
            
            public enum RiskImpact: String, CaseIterable, Codable {
                case low = "low"
                case medium = "medium"
                case high = "high"
                case critical = "critical"
            }
        }
        
        public struct Accelerator: Codable, Identifiable {
            public let id: UUID
            public let factor: String
            public let impact: AcceleratorImpact
            public let feasibility: Double
            public let action: String?
            
            public enum AcceleratorImpact: String, CaseIterable, Codable {
                case low = "low"
                case medium = "medium"
                case high = "high"
                case transformational = "transformational"
            }
        }
    }
    
    public struct TrackingInfo: Codable {
        public let trackingFrequency: TrackingFrequency
        public let dataSource: String
        public let lastUpdate: Date
        public let nextUpdate: Date
        public let updateResponsible: CKRecord.Reference
        public let updateResponsibleName: String
        public let autoTracking: Bool
        public let manualOverrides: [ManualOverride]
        public let dataQuality: DataQuality
        
        public enum TrackingFrequency: String, CaseIterable, Codable {
            case realTime = "real_time"
            case hourly = "hourly"
            case daily = "daily"
            case weekly = "weekly"
            case monthly = "monthly"
            
            public var displayName: String {
                switch self {
                case .realTime: return "Real-time"
                case .hourly: return "Hourly"
                case .daily: return "Daily"
                case .weekly: return "Weekly"
                case .monthly: return "Monthly"
                }
            }
        }
        
        public struct ManualOverride: Codable, Identifiable {
            public let id: UUID
            public let date: Date
            public let originalValue: Double
            public let adjustedValue: Double
            public let reason: String
            public let approvedBy: CKRecord.Reference
            public let approvedByName: String
            public let timestamp: Date
        }
        
        public struct DataQuality: Codable {
            public let accuracy: Double // 0-100
            public let completeness: Double // 0-100
            public let timeliness: Double // 0-100
            public let consistency: Double // 0-100
            public let overallScore: Double
            public let issues: [String]
        }
    }
    
    public struct IncentiveStructure: Codable {
        public let hasIncentives: Bool
        public let incentiveType: IncentiveType
        public let thresholds: [IncentiveThreshold]
        public let bonusStructure: BonusStructure?
        public let teamIncentives: [TeamIncentive]
        public let penaltyStructure: PenaltyStructure?
        public let totalEarned: Decimal
        public let totalPotential: Decimal
        
        public enum IncentiveType: String, CaseIterable, Codable {
            case none = "none"
            case bonus = "bonus"
            case commission = "commission"
            case spiff = "spiff"
            case recognition = "recognition"
            case advancement = "advancement"
            case hybrid = "hybrid"
            
            public var displayName: String {
                switch self {
                case .none: return "None"
                case .bonus: return "Bonus"
                case .commission: return "Commission"
                case .spiff: return "SPIFF"
                case .recognition: return "Recognition"
                case .advancement: return "Career Advancement"
                case .hybrid: return "Hybrid"
                }
            }
        }
        
        public struct IncentiveThreshold: Codable, Identifiable {
            public let id: UUID
            public let level: String
            public let threshold: Double // Percentage of target
            public let reward: Decimal
            public let achieved: Bool
            public let achievedDate: Date?
        }
        
        public struct BonusStructure: Codable {
            public let baseBonus: Decimal
            public let accelerators: [BonusAccelerator]
            public let caps: BonusCaps
            
            public struct BonusAccelerator: Codable, Identifiable {
                public let id: UUID
                public let threshold: Double
                public let multiplier: Double
                public let description: String
            }
            
            public struct BonusCaps: Codable {
                public let maxBonus: Decimal?
                public let maxMultiplier: Double?
                public let maxPercentOfSalary: Double?
            }
        }
        
        public struct TeamIncentive: Codable, Identifiable {
            public let id: UUID
            public let name: String
            public let teamTarget: Double
            public let teamAchievement: Double
            public let individualShare: Double
            public let earned: Decimal
        }
        
        public struct PenaltyStructure: Codable {
            public let hasPenalties: Bool
            public let minimumThreshold: Double
            public let penaltyRate: Double
            public let maxPenalty: Decimal?
            public let penaltiesApplied: [AppliedPenalty]
            
            public struct AppliedPenalty: Codable, Identifiable {
                public let id: UUID
                public let period: String
                public let shortfall: Double
                public let penalty: Decimal
                public let applied: Bool
                public let appliedDate: Date?
            }
        }
    }
    
    public struct TargetAdjustment: Codable, Identifiable {
        public let id: UUID
        public let adjustmentDate: Date
        public let adjustmentType: AdjustmentType
        public let previousTarget: Double
        public let newTarget: Double
        public let adjustment: Double
        public let adjustmentPercentage: Double
        public let reason: String
        public let approvedBy: CKRecord.Reference
        public let approvedByName: String
        public let impactAssessment: String?
        public let effectiveDate: Date
        
        public enum AdjustmentType: String, CaseIterable, Codable {
            case increase = "increase"
            case decrease = "decrease"
            case correction = "correction"
            case seasonal = "seasonal"
            case strategic = "strategic"
            case market = "market"
            case operational = "operational"
            
            public var displayName: String {
                switch self {
                case .increase: return "Increase"
                case .decrease: return "Decrease"
                case .correction: return "Correction"
                case .seasonal: return "Seasonal"
                case .strategic: return "Strategic"
                case .market: return "Market-driven"
                case .operational: return "Operational"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            adjustmentDate: Date = Date(),
            adjustmentType: AdjustmentType,
            previousTarget: Double,
            newTarget: Double,
            reason: String,
            approvedBy: CKRecord.Reference,
            approvedByName: String,
            impactAssessment: String? = nil,
            effectiveDate: Date
        ) {
            self.id = id
            self.adjustmentDate = adjustmentDate
            self.adjustmentType = adjustmentType
            self.previousTarget = previousTarget
            self.newTarget = newTarget
            self.adjustment = newTarget - previousTarget
            self.adjustmentPercentage = previousTarget > 0 ? ((newTarget - previousTarget) / previousTarget) * 100 : 0
            self.reason = reason
            self.approvedBy = approvedBy
            self.approvedByName = approvedByName
            self.impactAssessment = impactAssessment
            self.effectiveDate = effectiveDate
        }
    }
    
    public struct TargetMilestone: Codable, Identifiable {
        public let id: UUID
        public let name: String
        public let description: String
        public let targetDate: Date
        public let targetValue: Double
        public let actualValue: Double?
        public let achievedDate: Date?
        public let status: MilestoneStatus
        public let importance: MilestoneImportance
        public let dependencies: [String]
        public let actions: [String]
        
        public enum MilestoneStatus: String, CaseIterable, Codable {
            case pending = "pending"
            case inProgress = "in_progress"
            case achieved = "achieved"
            case missed = "missed"
            case deferred = "deferred"
            case cancelled = "cancelled"
            
            public var displayName: String {
                switch self {
                case .pending: return "Pending"
                case .inProgress: return "In Progress"
                case .achieved: return "Achieved"
                case .missed: return "Missed"
                case .deferred: return "Deferred"
                case .cancelled: return "Cancelled"
                }
            }
        }
        
        public enum MilestoneImportance: String, CaseIterable, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
        }
        
        public init(
            id: UUID = UUID(),
            name: String,
            description: String,
            targetDate: Date,
            targetValue: Double,
            actualValue: Double? = nil,
            achievedDate: Date? = nil,
            status: MilestoneStatus = .pending,
            importance: MilestoneImportance = .medium,
            dependencies: [String] = [],
            actions: [String] = []
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.targetDate = targetDate
            self.targetValue = targetValue
            self.actualValue = actualValue
            self.achievedDate = achievedDate
            self.status = status
            self.importance = importance
            self.dependencies = dependencies
            self.actions = actions
        }
    }
    
    public struct TargetAlert: Codable, Identifiable {
        public let id: UUID
        public let alertType: AlertType
        public let severity: AlertSeverity
        public let title: String
        public let message: String
        public let threshold: Double?
        public let currentValue: Double
        public let triggeredAt: Date
        public let isActive: Bool
        public let acknowledgedBy: CKRecord.Reference?
        public let acknowledgedAt: Date?
        public let resolvedAt: Date?
        public let actions: [String]
        
        public enum AlertType: String, CaseIterable, Codable {
            case behindTarget = "behind_target"
            case offTrack = "off_track"
            case milestone = "milestone"
            case exceptional = "exceptional"
            case deadline = "deadline"
            case quality = "quality"
            case trending = "trending"
            
            public var displayName: String {
                switch self {
                case .behindTarget: return "Behind Target"
                case .offTrack: return "Off Track"
                case .milestone: return "Milestone"
                case .exceptional: return "Exceptional Performance"
                case .deadline: return "Deadline Approaching"
                case .quality: return "Data Quality"
                case .trending: return "Trending"
                }
            }
        }
        
        public enum AlertSeverity: String, CaseIterable, Codable {
            case info = "info"
            case warning = "warning"
            case error = "error"
            case critical = "critical"
            
            public var color: String {
                switch self {
                case .info: return "blue"
                case .warning: return "yellow"
                case .error: return "orange"
                case .critical: return "red"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            alertType: AlertType,
            severity: AlertSeverity,
            title: String,
            message: String,
            threshold: Double? = nil,
            currentValue: Double,
            triggeredAt: Date = Date(),
            isActive: Bool = true,
            acknowledgedBy: CKRecord.Reference? = nil,
            acknowledgedAt: Date? = nil,
            resolvedAt: Date? = nil,
            actions: [String] = []
        ) {
            self.id = id
            self.alertType = alertType
            self.severity = severity
            self.title = title
            self.message = message
            self.threshold = threshold
            self.currentValue = currentValue
            self.triggeredAt = triggeredAt
            self.isActive = isActive
            self.acknowledgedBy = acknowledgedBy
            self.acknowledgedAt = acknowledgedAt
            self.resolvedAt = resolvedAt
            self.actions = actions
        }
    }
    
    // Computed properties
    public var isOverdue: Bool {
        return Date() > endDate && status == .active
    }
    
    public var daysRemaining: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    public var progressPercentage: Double {
        return achievements.achievementPercentage
    }
    
    public var isOnTrack: Bool {
        return achievements.achievementStatus == .onTrack || achievements.achievementStatus == .aheadOfTarget
    }
    
    public var timeElapsedPercentage: Double {
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max((elapsed / totalDuration) * 100, 0), 100)
    }
    
    public var criticalAlerts: [TargetAlert] {
        return alerts.filter { $0.severity == .critical && $0.isActive }
    }
    
    public var totalIncentiveEarned: Decimal {
        return incentives.totalEarned
    }
    
    public var recentAdjustments: [TargetAdjustment] {
        return adjustments.filter { $0.adjustmentDate >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date() }
    }
    
    public var upcomingMilestones: [TargetMilestone] {
        return milestones.filter { 
            $0.status == .pending && 
            $0.targetDate >= Date() && 
            $0.targetDate <= Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        }
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let targetName = record["targetName"] as? String,
              let typeRaw = record["targetType"] as? String,
              let targetType = TargetType(rawValue: typeRaw),
              let levelRaw = record["targetLevel"] as? String,
              let targetLevel = TargetLevel(rawValue: levelRaw),
              let scopeRaw = record["targetScope"] as? String,
              let targetScope = TargetScope(rawValue: scopeRaw),
              let periodRaw = record["period"] as? String,
              let period = TargetPeriod(rawValue: periodRaw),
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let fiscalYear = record["fiscalYear"] as? Int,
              let statusRaw = record["status"] as? String,
              let status = TargetStatus(rawValue: statusRaw),
              let isActive = record["isActive"] as? Bool,
              let createdBy = record["createdBy"] as? CKRecord.Reference,
              let createdByName = record["createdByName"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.targetName = targetName
        self.targetType = targetType
        self.targetLevel = targetLevel
        self.targetScope = targetScope
        self.storeCode = record["storeCode"] as? String
        self.storeName = record["storeName"] as? String
        self.employeeRef = record["employeeRef"] as? CKRecord.Reference
        self.employeeName = record["employeeName"] as? String
        self.categoryId = record["categoryId"] as? String
        self.categoryName = record["categoryName"] as? String
        self.productId = record["productId"] as? String
        self.productName = record["productName"] as? String
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.fiscalYear = fiscalYear
        self.fiscalQuarter = record["fiscalQuarter"] as? Int
        self.fiscalMonth = record["fiscalMonth"] as? Int
        self.notes = record["notes"] as? String
        self.status = status
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.approvedBy = record["approvedBy"] as? CKRecord.Reference
        self.approvedByName = record["approvedByName"] as? String
        self.approvedAt = record["approvedAt"] as? Date
        self.lastReviewed = record["lastReviewed"] as? Date
        self.reviewedBy = record["reviewedBy"] as? CKRecord.Reference
        self.reviewedByName = record["reviewedByName"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON with defaults
        if let targetsData = record["targets"] as? Data,
           let decodedTargets = try? JSONDecoder().decode(TargetMetrics.self, from: targetsData) {
            self.targets = decodedTargets
        } else {
            self.targets = TargetMetrics(
                primaryTarget: TargetMetrics.TargetValue(
                    value: 0, unit: targetType.unit, displayValue: "0", confidence: nil,
                    methodology: nil, source: nil, lastUpdated: Date()
                ),
                stretchTarget: nil, thresholdTarget: nil, benchmarkTarget: nil,
                historicalBaseline: nil, weightedTargets: [], subTargets: []
            )
        }
        
        if let achievementsData = record["achievements"] as? Data,
           let decodedAchievements = try? JSONDecoder().decode(AchievementMetrics.self, from: achievementsData) {
            self.achievements = decodedAchievements
        } else {
            self.achievements = AchievementMetrics(
                currentValue: 0, achievementPercentage: 0, achievementStatus: .notStarted,
                runRate: 0, projectedAchievement: 0, varianceFromTarget: 0, variancePercentage: 0,
                timeElapsed: 0, timeRemaining: endDate.timeIntervalSince(Date()),
                requiredRunRate: 0, trend: .stable, lastCalculated: Date()
            )
        }
        
        if let performanceData = record["performance"] as? Data,
           let decodedPerformance = try? JSONDecoder().decode(PerformanceMetrics.self, from: performanceData) {
            self.performance = decodedPerformance
        } else {
            self.performance = PerformanceMetrics(
                dailyPerformance: [],
                weeklyAverages: PerformanceMetrics.WeeklyAverages(
                    averageDaily: 0, bestDay: 0, worstDay: 0, consistency: 0, weekOverWeekGrowth: 0
                ),
                monthlyTrends: PerformanceMetrics.MonthlyTrends(
                    monthlyProgress: [], bestMonth: nil, worstMonth: nil,
                    averageMonthly: 0, monthOverMonthGrowth: 0
                ),
                seasonalFactors: PerformanceMetrics.SeasonalFactors(
                    hasSeasonality: false, peakPeriods: [], lowPeriods: [],
                    seasonalAdjustment: 1.0, yearOverYearComparison: 0
                ),
                comparativeAnalysis: PerformanceMetrics.ComparativeAnalysis(
                    peerComparison: PerformanceMetrics.ComparativeAnalysis.PeerComparison(
                        rank: nil, totalPeers: 0, percentile: nil, averagePeerPerformance: 0, topPerformerValue: nil
                    ),
                    historicalComparison: PerformanceMetrics.ComparativeAnalysis.HistoricalComparison(
                        previousPeriod: 0, sameperiodLastYear: 0, threeyearAverage: 0, bestHistorical: 0, improvement: 0
                    ),
                    benchmarkComparison: PerformanceMetrics.ComparativeAnalysis.BenchmarkComparison(
                        industryBenchmark: nil, companyBenchmark: 0, regionalBenchmark: nil, performanceVsBenchmarks: 0
                    )
                ),
                riskFactors: [], accelerators: []
            )
        }
        
        if let trackingData = record["tracking"] as? Data,
           let decodedTracking = try? JSONDecoder().decode(TrackingInfo.self, from: trackingData) {
            self.tracking = decodedTracking
        } else {
            self.tracking = TrackingInfo(
                trackingFrequency: .daily, dataSource: "Manual", lastUpdate: Date(),
                nextUpdate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                updateResponsible: createdBy, updateResponsibleName: createdByName,
                autoTracking: false, manualOverrides: [],
                dataQuality: TrackingInfo.DataQuality(
                    accuracy: 100, completeness: 100, timeliness: 100, consistency: 100,
                    overallScore: 100, issues: []
                )
            )
        }
        
        if let incentivesData = record["incentives"] as? Data,
           let decodedIncentives = try? JSONDecoder().decode(IncentiveStructure.self, from: incentivesData) {
            self.incentives = decodedIncentives
        } else {
            self.incentives = IncentiveStructure(
                hasIncentives: false, incentiveType: .none, thresholds: [], bonusStructure: nil,
                teamIncentives: [], penaltyStructure: nil, totalEarned: 0, totalPotential: 0
            )
        }
        
        if let adjustmentsData = record["adjustments"] as? Data,
           let decodedAdjustments = try? JSONDecoder().decode([TargetAdjustment].self, from: adjustmentsData) {
            self.adjustments = decodedAdjustments
        } else {
            self.adjustments = []
        }
        
        if let milestonesData = record["milestones"] as? Data,
           let decodedMilestones = try? JSONDecoder().decode([TargetMilestone].self, from: milestonesData) {
            self.milestones = decodedMilestones
        } else {
            self.milestones = []
        }
        
        if let alertsData = record["alerts"] as? Data,
           let decodedAlerts = try? JSONDecoder().decode([TargetAlert].self, from: alertsData) {
            self.alerts = decodedAlerts
        } else {
            self.alerts = []
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "SalesTarget", recordID: id)
        
        record["targetName"] = targetName
        record["targetType"] = targetType.rawValue
        record["targetLevel"] = targetLevel.rawValue
        record["targetScope"] = targetScope.rawValue
        record["storeCode"] = storeCode
        record["storeName"] = storeName
        record["employeeRef"] = employeeRef
        record["employeeName"] = employeeName
        record["categoryId"] = categoryId
        record["categoryName"] = categoryName
        record["productId"] = productId
        record["productName"] = productName
        record["period"] = period.rawValue
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["fiscalYear"] = fiscalYear
        record["fiscalQuarter"] = fiscalQuarter
        record["fiscalMonth"] = fiscalMonth
        record["notes"] = notes
        record["status"] = status.rawValue
        record["isActive"] = isActive
        record["createdBy"] = createdBy
        record["createdByName"] = createdByName
        record["approvedBy"] = approvedBy
        record["approvedByName"] = approvedByName
        record["approvedAt"] = approvedAt
        record["lastReviewed"] = lastReviewed
        record["reviewedBy"] = reviewedBy
        record["reviewedByName"] = reviewedByName
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex data as JSON
        if let targetsData = try? JSONEncoder().encode(targets) {
            record["targets"] = targetsData
        }
        
        if let achievementsData = try? JSONEncoder().encode(achievements) {
            record["achievements"] = achievementsData
        }
        
        if let performanceData = try? JSONEncoder().encode(performance) {
            record["performance"] = performanceData
        }
        
        if let trackingData = try? JSONEncoder().encode(tracking) {
            record["tracking"] = trackingData
        }
        
        if let incentivesData = try? JSONEncoder().encode(incentives) {
            record["incentives"] = incentivesData
        }
        
        if !adjustments.isEmpty,
           let adjustmentsData = try? JSONEncoder().encode(adjustments) {
            record["adjustments"] = adjustmentsData
        }
        
        if !milestones.isEmpty,
           let milestonesData = try? JSONEncoder().encode(milestones) {
            record["milestones"] = milestonesData
        }
        
        if !alerts.isEmpty,
           let alertsData = try? JSONEncoder().encode(alerts) {
            record["alerts"] = alertsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> SalesTarget? {
        return SalesTarget(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        targetName: String,
        targetType: TargetType,
        targetLevel: TargetLevel,
        targetScope: TargetScope,
        period: TargetPeriod,
        startDate: Date,
        endDate: Date,
        fiscalYear: Int,
        primaryTarget: Double,
        createdBy: CKRecord.Reference,
        createdByName: String,
        storeCode: String? = nil,
        storeName: String? = nil
    ) -> SalesTarget {
        let now = Date()
        
        return SalesTarget(
            id: CKRecord.ID(recordName: UUID().uuidString),
            targetName: targetName,
            targetType: targetType,
            targetLevel: targetLevel,
            targetScope: targetScope,
            storeCode: storeCode,
            storeName: storeName,
            employeeRef: nil,
            employeeName: nil,
            categoryId: nil,
            categoryName: nil,
            productId: nil,
            productName: nil,
            period: period,
            startDate: startDate,
            endDate: endDate,
            fiscalYear: fiscalYear,
            fiscalQuarter: nil,
            fiscalMonth: nil,
            targets: TargetMetrics(
                primaryTarget: TargetMetrics.TargetValue(
                    value: primaryTarget, unit: targetType.unit, displayValue: String(primaryTarget),
                    confidence: nil, methodology: nil, source: nil, lastUpdated: now
                ),
                stretchTarget: nil, thresholdTarget: nil, benchmarkTarget: nil,
                historicalBaseline: nil, weightedTargets: [], subTargets: []
            ),
            achievements: AchievementMetrics(
                currentValue: 0, achievementPercentage: 0, achievementStatus: .notStarted,
                runRate: 0, projectedAchievement: 0, varianceFromTarget: -primaryTarget, variancePercentage: -100,
                timeElapsed: 0, timeRemaining: endDate.timeIntervalSince(startDate),
                requiredRunRate: 0, trend: .stable, lastCalculated: now
            ),
            performance: PerformanceMetrics(
                dailyPerformance: [],
                weeklyAverages: PerformanceMetrics.WeeklyAverages(
                    averageDaily: 0, bestDay: 0, worstDay: 0, consistency: 0, weekOverWeekGrowth: 0
                ),
                monthlyTrends: PerformanceMetrics.MonthlyTrends(
                    monthlyProgress: [], bestMonth: nil, worstMonth: nil,
                    averageMonthly: 0, monthOverMonthGrowth: 0
                ),
                seasonalFactors: PerformanceMetrics.SeasonalFactors(
                    hasSeasonality: false, peakPeriods: [], lowPeriods: [],
                    seasonalAdjustment: 1.0, yearOverYearComparison: 0
                ),
                comparativeAnalysis: PerformanceMetrics.ComparativeAnalysis(
                    peerComparison: PerformanceMetrics.ComparativeAnalysis.PeerComparison(
                        rank: nil, totalPeers: 0, percentile: nil, averagePeerPerformance: 0, topPerformerValue: nil
                    ),
                    historicalComparison: PerformanceMetrics.ComparativeAnalysis.HistoricalComparison(
                        previousPeriod: 0, sameperiodLastYear: 0, threeyearAverage: 0, bestHistorical: 0, improvement: 0
                    ),
                    benchmarkComparison: PerformanceMetrics.ComparativeAnalysis.BenchmarkComparison(
                        industryBenchmark: nil, companyBenchmark: 0, regionalBenchmark: nil, performanceVsBenchmarks: 0
                    )
                ),
                riskFactors: [], accelerators: []
            ),
            tracking: TrackingInfo(
                trackingFrequency: .daily, dataSource: "Manual", lastUpdate: now,
                nextUpdate: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now,
                updateResponsible: createdBy, updateResponsibleName: createdByName,
                autoTracking: false, manualOverrides: [],
                dataQuality: TrackingInfo.DataQuality(
                    accuracy: 100, completeness: 100, timeliness: 100, consistency: 100,
                    overallScore: 100, issues: []
                )
            ),
            incentives: IncentiveStructure(
                hasIncentives: false, incentiveType: .none, thresholds: [], bonusStructure: nil,
                teamIncentives: [], penaltyStructure: nil, totalEarned: 0, totalPotential: 0
            ),
            adjustments: [],
            milestones: [],
            alerts: [],
            notes: nil,
            status: .draft,
            isActive: true,
            createdBy: createdBy,
            createdByName: createdByName,
            approvedBy: nil,
            approvedByName: nil,
            approvedAt: nil,
            lastReviewed: nil,
            reviewedBy: nil,
            reviewedByName: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
