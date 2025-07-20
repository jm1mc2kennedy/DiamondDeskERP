import Foundation
import CloudKit

/// Category performance analytics and tracking model
public struct CategoryPerformance: Identifiable, Codable {
    public let id: CKRecord.ID
    public let categoryId: String
    public let categoryName: String
    public let parentCategoryId: String?
    public let parentCategoryName: String?
    public let storeCode: String
    public let storeName: String?
    public let reportingPeriod: ReportingPeriod
    public let periodStart: Date
    public let periodEnd: Date
    public let status: PerformanceStatus
    public let metrics: CategoryMetrics
    public let targets: CategoryTargets
    public let performance: PerformanceAnalysis
    public let trends: TrendAnalysis
    public let comparisons: ComparisonAnalysis
    public let insights: [PerformanceInsight]
    public let actions: [ActionItem]
    public let forecasts: ForecastData
    public let rankings: CategoryRankings
    public let alerts: [PerformanceAlert]
    public let lastCalculated: Date
    public let calculatedBy: CKRecord.Reference
    public let calculatedByName: String
    public let reviewedBy: CKRecord.Reference?
    public let reviewedByName: String?
    public let reviewedAt: Date?
    public let approvedBy: CKRecord.Reference?
    public let approvedByName: String?
    public let approvedAt: Date?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum ReportingPeriod: String, CaseIterable, Codable {
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
    }
    
    public enum PerformanceStatus: String, CaseIterable, Codable {
        case calculating = "calculating"
        case completed = "completed"
        case underReview = "under_review"
        case approved = "approved"
        case published = "published"
        case archived = "archived"
        
        public var displayName: String {
            switch self {
            case .calculating: return "Calculating"
            case .completed: return "Completed"
            case .underReview: return "Under Review"
            case .approved: return "Approved"
            case .published: return "Published"
            case .archived: return "Archived"
            }
        }
    }
    
    public struct CategoryMetrics: Codable {
        public let sales: SalesMetrics
        public let inventory: InventoryMetrics
        public let customer: CustomerMetrics
        public let operational: OperationalMetrics
        public let financial: FinancialMetrics
        public let quality: QualityMetrics
        
        public struct SalesMetrics: Codable {
            public let totalRevenue: Decimal
            public let totalUnits: Int
            public let averageUnitPrice: Decimal
            public let grossMargin: Decimal
            public let grossMarginPercentage: Double
            public let salesGrowth: Double // Percentage
            public let unitGrowth: Double // Percentage
            public let marketShare: Double // Percentage
            public let salesVelocity: Double // Units per day
            public let conversionRate: Double // Percentage
            public let attachRate: Double // Percentage
            public let crossSellRate: Double // Percentage
            public let returnRate: Double // Percentage
            public let refundAmount: Decimal
            public let discountAmount: Decimal
            public let discountPercentage: Double
        }
        
        public struct InventoryMetrics: Codable {
            public let currentStock: Int
            public let stockValue: Decimal
            public let stockTurnover: Double
            public let daysOfInventory: Double
            public let stockoutEvents: Int
            public let stockoutDays: Int
            public let overstockEvents: Int
            public let overstockValue: Decimal
            public let writeOffAmount: Decimal
            public let writeOffPercentage: Double
            public let receivedUnits: Int
            public let receivedValue: Decimal
            public let adjustmentUnits: Int
            public let adjustmentValue: Decimal
            public let shrinkageRate: Double
            public let inventoryAccuracy: Double
        }
        
        public struct CustomerMetrics: Codable {
            public let uniqueCustomers: Int
            public let newCustomers: Int
            public let returningCustomers: Int
            public let customerRetentionRate: Double
            public let averageTransactionValue: Decimal
            public let transactionCount: Int
            public let averageItemsPerTransaction: Double
            public let customerSatisfactionScore: Double
            public let customerComplaintCount: Int
            public let customerComplimentCount: Int
            public let loyaltySignups: Int
            public let loyaltyRedemptions: Int
            public let referralCount: Int
            public let reviewCount: Int
            public let averageRating: Double
        }
        
        public struct OperationalMetrics: Codable {
            public let staffHours: Double
            public let productivityScore: Double
            public let trainingHours: Double
            public let trainingCompletionRate: Double
            public let qualityScore: Double
            public let complianceScore: Double
            public let safetyIncidents: Int
            public let maintenanceHours: Double
            public let equipmentDowntime: Double
            public let energyConsumption: Double
            public let wasteGenerated: Double
            public let recyclingRate: Double
            public let auditScore: Double
            public let processEfficiency: Double
        }
        
        public struct FinancialMetrics: Codable {
            public let costOfGoodsSold: Decimal
            public let operatingExpenses: Decimal
            public let marketingSpend: Decimal
            public let promotionalSpend: Decimal
            public let laborCost: Decimal
            public let overheadAllocation: Decimal
            public let netProfit: Decimal
            public let netProfitMargin: Double
            public let returnOnInvestment: Double
            public let priceElasticity: Double
            public let competitiveIndex: Double
            public let valuePercentage: Double
            public let costPerAcquisition: Decimal
            public let lifetimeValue: Decimal
        }
        
        public struct QualityMetrics: Codable {
            public let defectRate: Double
            public let qualityScore: Double
            public let customerSatisfaction: Double
            public let returnedDefectiveUnits: Int
            public let qualityComplaints: Int
            public let qualityCompliments: Int
            public let certificationScore: Double
            public let auditFindings: Int
            public let correctiveActions: Int
            public let preventiveActions: Int
            public let supplierQualityScore: Double
            public let productRecalls: Int
            public let safetyIncidents: Int
            public let complianceViolations: Int
        }
    }
    
    public struct CategoryTargets: Codable {
        public let revenueTarget: Decimal
        public let unitsTarget: Int
        public let marginTarget: Double
        public let growthTarget: Double
        public let marketShareTarget: Double
        public let inventoryTurnTarget: Double
        public let customerSatisfactionTarget: Double
        public let qualityTarget: Double
        public let costTarget: Decimal
        public let customTargets: [String: Double]
        public let targetPeriod: String
        public let setBy: CKRecord.Reference
        public let setByName: String
        public let setAt: Date
        public let reviewFrequency: TargetReviewFrequency
        public let achievementThresholds: AchievementThresholds
        
        public enum TargetReviewFrequency: String, CaseIterable, Codable {
            case monthly = "monthly"
            case quarterly = "quarterly"
            case semiAnnual = "semi_annual"
            case annual = "annual"
            
            public var displayName: String {
                switch self {
                case .monthly: return "Monthly"
                case .quarterly: return "Quarterly"
                case .semiAnnual: return "Semi-Annual"
                case .annual: return "Annual"
                }
            }
        }
        
        public struct AchievementThresholds: Codable {
            public let excellent: Double // e.g., 110% of target
            public let good: Double // e.g., 100% of target
            public let satisfactory: Double // e.g., 90% of target
            public let needsImprovement: Double // e.g., 80% of target
            public let poor: Double // e.g., 70% of target
        }
    }
    
    public struct PerformanceAnalysis: Codable {
        public let overallScore: Double
        public let categoryGrade: PerformanceGrade
        public let keyStrengths: [String]
        public let improvementAreas: [String]
        public let riskFactors: [RiskFactor]
        public let opportunities: [Opportunity]
        public let recommendations: [Recommendation]
        public let targetAchievement: TargetAchievement
        public let competitivePosition: CompetitivePosition
        public let seasonalityImpact: SeasonalityAnalysis
        
        public enum PerformanceGrade: String, CaseIterable, Codable {
            case excellent = "excellent"
            case good = "good"
            case satisfactory = "satisfactory"
            case needsImprovement = "needs_improvement"
            case poor = "poor"
            
            public var displayName: String {
                switch self {
                case .excellent: return "Excellent"
                case .good: return "Good"
                case .satisfactory: return "Satisfactory"
                case .needsImprovement: return "Needs Improvement"
                case .poor: return "Poor"
                }
            }
            
            public var color: String {
                switch self {
                case .excellent: return "green"
                case .good: return "lightgreen"
                case .satisfactory: return "yellow"
                case .needsImprovement: return "orange"
                case .poor: return "red"
                }
            }
        }
        
        public struct RiskFactor: Codable, Identifiable {
            public let id: UUID
            public let type: RiskType
            public let severity: RiskSeverity
            public let description: String
            public let impact: String
            public let probability: Double
            public let mitigationActions: [String]
            public let owner: CKRecord.Reference?
            public let dueDate: Date?
            
            public enum RiskType: String, CaseIterable, Codable {
                case market = "market"
                case operational = "operational"
                case financial = "financial"
                case competitive = "competitive"
                case supply = "supply"
                case customer = "customer"
                case regulatory = "regulatory"
                case technology = "technology"
            }
            
            public enum RiskSeverity: String, CaseIterable, Codable {
                case low = "low"
                case medium = "medium"
                case high = "high"
                case critical = "critical"
            }
        }
        
        public struct Opportunity: Codable, Identifiable {
            public let id: UUID
            public let type: OpportunityType
            public let priority: OpportunityPriority
            public let description: String
            public let potentialImpact: String
            public let effort: OpportunityEffort
            public let timeframe: String
            public let resources: [String]
            public let owner: CKRecord.Reference?
            public let targetDate: Date?
            
            public enum OpportunityType: String, CaseIterable, Codable {
                case growth = "growth"
                case efficiency = "efficiency"
                case quality = "quality"
                case cost = "cost"
                case customer = "customer"
                case innovation = "innovation"
                case market = "market"
                case partnership = "partnership"
            }
            
            public enum OpportunityPriority: String, CaseIterable, Codable {
                case low = "low"
                case medium = "medium"
                case high = "high"
                case critical = "critical"
            }
            
            public enum OpportunityEffort: String, CaseIterable, Codable {
                case low = "low"
                case medium = "medium"
                case high = "high"
            }
        }
        
        public struct Recommendation: Codable, Identifiable {
            public let id: UUID
            public let category: RecommendationCategory
            public let priority: RecommendationPriority
            public let title: String
            public let description: String
            public let rationale: String
            public let expectedOutcome: String
            public let implementation: ImplementationPlan
            public let metrics: [String]
            public let risks: [String]
            public let dependencies: [String]
            
            public enum RecommendationCategory: String, CaseIterable, Codable {
                case pricing = "pricing"
                case promotion = "promotion"
                case inventory = "inventory"
                case display = "display"
                case training = "training"
                case process = "process"
                case supplier = "supplier"
                case technology = "technology"
            }
            
            public enum RecommendationPriority: String, CaseIterable, Codable {
                case immediate = "immediate"
                case short_term = "short_term"
                case medium_term = "medium_term"
                case long_term = "long_term"
            }
            
            public struct ImplementationPlan: Codable {
                public let steps: [String]
                public let timeline: String
                public let resources: [String]
                public let budget: Decimal?
                public let owner: CKRecord.Reference?
                public let success_criteria: [String]
            }
        }
        
        public struct TargetAchievement: Codable {
            public let revenueAchievement: Double // Percentage
            public let unitsAchievement: Double // Percentage
            public let marginAchievement: Double // Percentage
            public let growthAchievement: Double // Percentage
            public let overallAchievement: Double // Weighted average
            public let achievedTargets: Int
            public let totalTargets: Int
            public let achievementRate: Double // Percentage
        }
        
        public struct CompetitivePosition: Codable {
            public let marketRank: Int?
            public let marketShare: Double
            public let competitiveAdvantages: [String]
            public let competitiveThreats: [String]
            public let pricingPosition: PricingPosition
            public let qualityPosition: QualityPosition
            public let innovationPosition: InnovationPosition
            
            public enum PricingPosition: String, CaseIterable, Codable {
                case premium = "premium"
                case competitive = "competitive"
                case value = "value"
                case discount = "discount"
            }
            
            public enum QualityPosition: String, CaseIterable, Codable {
                case superior = "superior"
                case comparable = "comparable"
                case below_average = "below_average"
            }
            
            public enum InnovationPosition: String, CaseIterable, Codable {
                case leader = "leader"
                case follower = "follower"
                case laggard = "laggard"
            }
        }
        
        public struct SeasonalityAnalysis: Codable {
            public let isSeasonalCategory: Bool
            public let peakMonths: [Int] // Month numbers
            public let lowMonths: [Int] // Month numbers
            public let seasonalityIndex: Double
            public let yearOverYearComparison: [MonthlyComparison]
            public let seasonalAdjustedPerformance: Double
            
            public struct MonthlyComparison: Codable {
                public let month: Int
                public let currentYear: Double
                public let previousYear: Double
                public let variance: Double
                public let variancePercentage: Double
            }
        }
    }
    
    public struct TrendAnalysis: Codable {
        public let shortTermTrend: TrendDirection // Last 30 days
        public let mediumTermTrend: TrendDirection // Last 90 days
        public let longTermTrend: TrendDirection // Last 365 days
        public let trendStrength: TrendStrength
        public let volatility: VolatilityLevel
        public let cyclicality: CyclicalityPattern
        public let historicalData: [DataPoint]
        public let movingAverages: MovingAverages
        public let trendAnalytics: TrendAnalytics
        
        public enum TrendDirection: String, CaseIterable, Codable {
            case stronglyIncreasing = "strongly_increasing"
            case increasing = "increasing"
            case stable = "stable"
            case decreasing = "decreasing"
            case stronglyDecreasing = "strongly_decreasing"
            
            public var displayName: String {
                switch self {
                case .stronglyIncreasing: return "Strongly Increasing"
                case .increasing: return "Increasing"
                case .stable: return "Stable"
                case .decreasing: return "Decreasing"
                case .stronglyDecreasing: return "Strongly Decreasing"
                }
            }
            
            public var icon: String {
                switch self {
                case .stronglyIncreasing: return "📈"
                case .increasing: return "↗️"
                case .stable: return "→"
                case .decreasing: return "↘️"
                case .stronglyDecreasing: return "📉"
                }
            }
        }
        
        public enum TrendStrength: String, CaseIterable, Codable {
            case weak = "weak"
            case moderate = "moderate"
            case strong = "strong"
            case veryStrong = "very_strong"
        }
        
        public enum VolatilityLevel: String, CaseIterable, Codable {
            case low = "low"
            case moderate = "moderate"
            case high = "high"
            case extreme = "extreme"
        }
        
        public enum CyclicalityPattern: String, CaseIterable, Codable {
            case none = "none"
            case weekly = "weekly"
            case monthly = "monthly"
            case quarterly = "quarterly"
            case seasonal = "seasonal"
            case annual = "annual"
        }
        
        public struct DataPoint: Codable {
            public let date: Date
            public let value: Double
            public let period: String
        }
        
        public struct MovingAverages: Codable {
            public let sma7: Double // 7-day simple moving average
            public let sma30: Double // 30-day simple moving average
            public let sma90: Double // 90-day simple moving average
            public let ema7: Double // 7-day exponential moving average
            public let ema30: Double // 30-day exponential moving average
        }
        
        public struct TrendAnalytics: Codable {
            public let regressionSlope: Double
            public let rSquared: Double
            public let standardDeviation: Double
            public let coefficientOfVariation: Double
            public let correlationFactors: [String: Double]
        }
    }
    
    public struct ComparisonAnalysis: Codable {
        public let storeComparison: StoreComparison
        public let categoryComparison: CategoryComparison
        public let timeComparison: TimeComparison
        public let benchmarkComparison: BenchmarkComparison
        public let targetComparison: TargetComparison
        
        public struct StoreComparison: Codable {
            public let storeRank: Int
            public let totalStores: Int
            public let percentile: Double
            public let aboveAverage: Bool
            public let topPerformers: [StorePerformance]
            public let similarStores: [StorePerformance]
            
            public struct StorePerformance: Codable {
                public let storeCode: String
                public let storeName: String
                public let performance: Double
                public let rank: Int
            }
        }
        
        public struct CategoryComparison: Codable {
            public let categoryRank: Int
            public let totalCategories: Int
            public let percentile: Double
            public let topCategories: [CategoryPerformance]
            public let similarCategories: [CategoryPerformance]
            
            public struct CategoryPerformance: Codable {
                public let categoryId: String
                public let categoryName: String
                public let performance: Double
                public let rank: Int
            }
        }
        
        public struct TimeComparison: Codable {
            public let previousPeriod: PeriodComparison
            public let yearOverYear: PeriodComparison
            public let quarterOverQuarter: PeriodComparison?
            public let monthOverMonth: PeriodComparison?
            
            public struct PeriodComparison: Codable {
                public let current: Double
                public let previous: Double
                public let variance: Double
                public let variancePercentage: Double
                public let improvement: Bool
            }
        }
        
        public struct BenchmarkComparison: Codable {
            public let industryBenchmark: Double?
            public let companyBenchmark: Double
            public let regionalBenchmark: Double?
            public let performanceVsIndustry: Double?
            public let performanceVsCompany: Double
            public let performanceVsRegion: Double?
        }
        
        public struct TargetComparison: Codable {
            public let targetAchievement: Double
            public let targetVariance: Double
            public let onTrack: Bool
            public let projectedAchievement: Double
            public let timeRemaining: TimeInterval
            public let requiredRunRate: Double
        }
    }
    
    public struct PerformanceInsight: Codable, Identifiable {
        public let id: UUID
        public let type: InsightType
        public let severity: InsightSeverity
        public let title: String
        public let description: String
        public let impact: String
        public let confidence: Double // 0-100
        public let dataPoints: [String]
        public let relatedMetrics: [String]
        public let suggestedActions: [String]
        public let generatedAt: Date
        public let validUntil: Date?
        
        public enum InsightType: String, CaseIterable, Codable {
            case trend = "trend"
            case anomaly = "anomaly"
            case opportunity = "opportunity"
            case risk = "risk"
            case correlation = "correlation"
            case prediction = "prediction"
            case benchmark = "benchmark"
            case target = "target"
        }
        
        public enum InsightSeverity: String, CaseIterable, Codable {
            case info = "info"
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
        }
    }
    
    public struct ActionItem: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let description: String
        public let priority: ActionPriority
        public let category: ActionCategory
        public let status: ActionStatus
        public let assignedTo: CKRecord.Reference?
        public let assignedToName: String?
        public let dueDate: Date?
        public let estimatedEffort: String?
        public let expectedImpact: String?
        public let successMetrics: [String]
        public let progress: Double // 0-100
        public let comments: [ActionComment]
        public let createdAt: Date
        public let updatedAt: Date
        
        public enum ActionPriority: String, CaseIterable, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case urgent = "urgent"
        }
        
        public enum ActionCategory: String, CaseIterable, Codable {
            case inventory = "inventory"
            case pricing = "pricing"
            case promotion = "promotion"
            case display = "display"
            case training = "training"
            case process = "process"
            case quality = "quality"
            case customer = "customer"
        }
        
        public enum ActionStatus: String, CaseIterable, Codable {
            case pending = "pending"
            case inProgress = "in_progress"
            case completed = "completed"
            case onHold = "on_hold"
            case cancelled = "cancelled"
        }
        
        public struct ActionComment: Codable, Identifiable {
            public let id: UUID
            public let comment: String
            public let author: CKRecord.Reference
            public let authorName: String
            public let timestamp: Date
        }
    }
    
    public struct ForecastData: Codable {
        public let forecastPeriods: [ForecastPeriod]
        public let forecastModel: ForecastModel
        public let confidence: ForecastConfidence
        public let assumptions: [String]
        public let scenarios: [ForecastScenario]
        public let lastUpdated: Date
        
        public struct ForecastPeriod: Codable {
            public let period: String
            public let startDate: Date
            public let endDate: Date
            public let revenue: Decimal
            public let units: Int
            public let margin: Double
            public let confidence: Double
        }
        
        public struct ForecastModel: Codable {
            public let type: ModelType
            public let accuracy: Double
            public let parameters: [String: Double]
            public let lastTrained: Date
            
            public enum ModelType: String, CaseIterable, Codable {
                case linear = "linear"
                case exponential = "exponential"
                case seasonal = "seasonal"
                case arima = "arima"
                case machinelearning = "machine_learning"
            }
        }
        
        public struct ForecastConfidence: Codable {
            public let overall: Double
            public let shortTerm: Double // Next 30 days
            public let mediumTerm: Double // Next 90 days
            public let longTerm: Double // Next 365 days
        }
        
        public struct ForecastScenario: Codable, Identifiable {
            public let id: UUID
            public let name: String
            public let probability: Double
            public let assumptions: [String]
            public let impact: ScenarioImpact
            
            public struct ScenarioImpact: Codable {
                public let revenueImpact: Double // Percentage
                public let unitsImpact: Double // Percentage
                public let marginImpact: Double // Percentage
            }
        }
    }
    
    public struct CategoryRankings: Codable {
        public let overall: RankingInfo
        public let revenue: RankingInfo
        public let growth: RankingInfo
        public let margin: RankingInfo
        public let quality: RankingInfo
        public let customer: RankingInfo
        public let efficiency: RankingInfo
        
        public struct RankingInfo: Codable {
            public let rank: Int
            public let totalCategories: Int
            public let percentile: Double
            public let score: Double
            public let tier: RankingTier
            
            public enum RankingTier: String, CaseIterable, Codable {
                case top = "top" // Top 10%
                case high = "high" // Top 25%
                case medium = "medium" // Top 50%
                case low = "low" // Bottom 50%
                case bottom = "bottom" // Bottom 10%
            }
        }
    }
    
    public struct PerformanceAlert: Codable, Identifiable {
        public let id: UUID
        public let type: AlertType
        public let severity: AlertSeverity
        public let title: String
        public let message: String
        public let metric: String
        public let threshold: Double
        public let actualValue: Double
        public let variance: Double
        public let isActive: Bool
        public let triggeredAt: Date
        public let resolvedAt: Date?
        public let acknowledgedBy: CKRecord.Reference?
        public let acknowledgedAt: Date?
        public let actions: [String]
        
        public enum AlertType: String, CaseIterable, Codable {
            case threshold = "threshold"
            case trend = "trend"
            case anomaly = "anomaly"
            case target = "target"
            case quality = "quality"
            case inventory = "inventory"
            case customer = "customer"
            
            public var displayName: String {
                switch self {
                case .threshold: return "Threshold"
                case .trend: return "Trend"
                case .anomaly: return "Anomaly"
                case .target: return "Target"
                case .quality: return "Quality"
                case .inventory: return "Inventory"
                case .customer: return "Customer"
                }
            }
        }
        
        public enum AlertSeverity: String, CaseIterable, Codable {
            case info = "info"
            case warning = "warning"
            case error = "error"
            case critical = "critical"
            
            public var displayName: String {
                switch self {
                case .info: return "Info"
                case .warning: return "Warning"
                case .error: return "Error"
                case .critical: return "Critical"
                }
            }
            
            public var color: String {
                switch self {
                case .info: return "blue"
                case .warning: return "yellow"
                case .error: return "orange"
                case .critical: return "red"
                }
            }
        }
    }
    
    // Computed properties
    public var overallPerformanceGrade: PerformanceAnalysis.PerformanceGrade {
        return performance.categoryGrade
    }
    
    public var isTopPerformer: Bool {
        return rankings.overall.tier == .top
    }
    
    public var needsAttention: Bool {
        return performance.categoryGrade == .needsImprovement || 
               performance.categoryGrade == .poor ||
               !alerts.filter { $0.severity == .critical || $0.severity == .error }.isEmpty
    }
    
    public var criticalAlerts: [PerformanceAlert] {
        return alerts.filter { $0.severity == .critical && $0.isActive }
    }
    
    public var trendDirection: TrendAnalysis.TrendDirection {
        return trends.shortTermTrend
    }
    
    public var revenueGrowth: Double {
        return trends.shortTermTrend == .increasing || trends.shortTermTrend == .stronglyIncreasing ? 
               comparisons.timeComparison.previousPeriod.variancePercentage : 0
    }
    
    public var targetAchievementPercentage: Double {
        return performance.targetAchievement.overallAchievement
    }
    
    public var isOnTrackForTargets: Bool {
        return comparisons.targetComparison.onTrack
    }
    
    public var keyMetricsSummary: [String: Double] {
        return [
            "Revenue": Double(truncating: metrics.sales.totalRevenue as NSNumber),
            "Growth": metrics.sales.salesGrowth,
            "Margin": metrics.sales.grossMarginPercentage,
            "Quality": metrics.quality.qualityScore,
            "Customer Satisfaction": metrics.customer.customerSatisfactionScore
        ]
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let categoryId = record["categoryId"] as? String,
              let categoryName = record["categoryName"] as? String,
              let storeCode = record["storeCode"] as? String,
              let periodRaw = record["reportingPeriod"] as? String,
              let reportingPeriod = ReportingPeriod(rawValue: periodRaw),
              let periodStart = record["periodStart"] as? Date,
              let periodEnd = record["periodEnd"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = PerformanceStatus(rawValue: statusRaw),
              let lastCalculated = record["lastCalculated"] as? Date,
              let calculatedBy = record["calculatedBy"] as? CKRecord.Reference,
              let calculatedByName = record["calculatedByName"] as? String,
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.parentCategoryId = record["parentCategoryId"] as? String
        self.parentCategoryName = record["parentCategoryName"] as? String
        self.storeCode = storeCode
        self.storeName = record["storeName"] as? String
        self.reportingPeriod = reportingPeriod
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.status = status
        self.lastCalculated = lastCalculated
        self.calculatedBy = calculatedBy
        self.calculatedByName = calculatedByName
        self.reviewedBy = record["reviewedBy"] as? CKRecord.Reference
        self.reviewedByName = record["reviewedByName"] as? String
        self.reviewedAt = record["reviewedAt"] as? Date
        self.approvedBy = record["approvedBy"] as? CKRecord.Reference
        self.approvedByName = record["approvedByName"] as? String
        self.approvedAt = record["approvedAt"] as? Date
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON - with defaults for missing data
        if let metricsData = record["metrics"] as? Data,
           let decodedMetrics = try? JSONDecoder().decode(CategoryMetrics.self, from: metricsData) {
            self.metrics = decodedMetrics
        } else {
            // Create default metrics structure
            self.metrics = CategoryMetrics(
                sales: CategoryMetrics.SalesMetrics(
                    totalRevenue: 0, totalUnits: 0, averageUnitPrice: 0, grossMargin: 0,
                    grossMarginPercentage: 0, salesGrowth: 0, unitGrowth: 0, marketShare: 0,
                    salesVelocity: 0, conversionRate: 0, attachRate: 0, crossSellRate: 0,
                    returnRate: 0, refundAmount: 0, discountAmount: 0, discountPercentage: 0
                ),
                inventory: CategoryMetrics.InventoryMetrics(
                    currentStock: 0, stockValue: 0, stockTurnover: 0, daysOfInventory: 0,
                    stockoutEvents: 0, stockoutDays: 0, overstockEvents: 0, overstockValue: 0,
                    writeOffAmount: 0, writeOffPercentage: 0, receivedUnits: 0, receivedValue: 0,
                    adjustmentUnits: 0, adjustmentValue: 0, shrinkageRate: 0, inventoryAccuracy: 0
                ),
                customer: CategoryMetrics.CustomerMetrics(
                    uniqueCustomers: 0, newCustomers: 0, returningCustomers: 0, customerRetentionRate: 0,
                    averageTransactionValue: 0, transactionCount: 0, averageItemsPerTransaction: 0,
                    customerSatisfactionScore: 0, customerComplaintCount: 0, customerComplimentCount: 0,
                    loyaltySignups: 0, loyaltyRedemptions: 0, referralCount: 0, reviewCount: 0, averageRating: 0
                ),
                operational: CategoryMetrics.OperationalMetrics(
                    staffHours: 0, productivityScore: 0, trainingHours: 0, trainingCompletionRate: 0,
                    qualityScore: 0, complianceScore: 0, safetyIncidents: 0, maintenanceHours: 0,
                    equipmentDowntime: 0, energyConsumption: 0, wasteGenerated: 0, recyclingRate: 0,
                    auditScore: 0, processEfficiency: 0
                ),
                financial: CategoryMetrics.FinancialMetrics(
                    costOfGoodsSold: 0, operatingExpenses: 0, marketingSpend: 0, promotionalSpend: 0,
                    laborCost: 0, overheadAllocation: 0, netProfit: 0, netProfitMargin: 0,
                    returnOnInvestment: 0, priceElasticity: 0, competitiveIndex: 0, valuePercentage: 0,
                    costPerAcquisition: 0, lifetimeValue: 0
                ),
                quality: CategoryMetrics.QualityMetrics(
                    defectRate: 0, qualityScore: 0, customerSatisfaction: 0, returnedDefectiveUnits: 0,
                    qualityComplaints: 0, qualityCompliments: 0, certificationScore: 0, auditFindings: 0,
                    correctiveActions: 0, preventiveActions: 0, supplierQualityScore: 0, productRecalls: 0,
                    safetyIncidents: 0, complianceViolations: 0
                )
            )
        }
        
        // Decode other complex structures with appropriate defaults
        if let targetsData = record["targets"] as? Data,
           let decodedTargets = try? JSONDecoder().decode(CategoryTargets.self, from: targetsData) {
            self.targets = decodedTargets
        } else {
            self.targets = CategoryTargets(
                revenueTarget: 0, unitsTarget: 0, marginTarget: 0, growthTarget: 0,
                marketShareTarget: 0, inventoryTurnTarget: 0, customerSatisfactionTarget: 0,
                qualityTarget: 0, costTarget: 0, customTargets: [:], targetPeriod: "",
                setBy: calculatedBy, setByName: calculatedByName, setAt: Date(),
                reviewFrequency: .quarterly,
                achievementThresholds: CategoryTargets.AchievementThresholds(
                    excellent: 110, good: 100, satisfactory: 90, needsImprovement: 80, poor: 70
                )
            )
        }
        
        // Continue with other complex decodings...
        if let performanceData = record["performance"] as? Data,
           let decodedPerformance = try? JSONDecoder().decode(PerformanceAnalysis.self, from: performanceData) {
            self.performance = decodedPerformance
        } else {
            self.performance = PerformanceAnalysis(
                overallScore: 0, categoryGrade: .satisfactory, keyStrengths: [], improvementAreas: [],
                riskFactors: [], opportunities: [], recommendations: [],
                targetAchievement: PerformanceAnalysis.TargetAchievement(
                    revenueAchievement: 0, unitsAchievement: 0, marginAchievement: 0,
                    growthAchievement: 0, overallAchievement: 0, achievedTargets: 0,
                    totalTargets: 0, achievementRate: 0
                ),
                competitivePosition: PerformanceAnalysis.CompetitivePosition(
                    marketRank: nil, marketShare: 0, competitiveAdvantages: [], competitiveThreats: [],
                    pricingPosition: .competitive, qualityPosition: .comparable, innovationPosition: .follower
                ),
                seasonalityImpact: PerformanceAnalysis.SeasonalityAnalysis(
                    isSeasonalCategory: false, peakMonths: [], lowMonths: [], seasonalityIndex: 1.0,
                    yearOverYearComparison: [], seasonalAdjustedPerformance: 0
                )
            )
        }
        
        // Set remaining properties with defaults
        self.trends = TrendAnalysis(
            shortTermTrend: .stable, mediumTermTrend: .stable, longTermTrend: .stable,
            trendStrength: .moderate, volatility: .moderate, cyclicality: .none,
            historicalData: [], movingAverages: TrendAnalysis.MovingAverages(
                sma7: 0, sma30: 0, sma90: 0, ema7: 0, ema30: 0
            ),
            trendAnalytics: TrendAnalysis.TrendAnalytics(
                regressionSlope: 0, rSquared: 0, standardDeviation: 0,
                coefficientOfVariation: 0, correlationFactors: [:]
            )
        )
        
        // Simplified defaults for other properties
        self.comparisons = ComparisonAnalysis(
            storeComparison: ComparisonAnalysis.StoreComparison(
                storeRank: 1, totalStores: 1, percentile: 50, aboveAverage: true,
                topPerformers: [], similarStores: []
            ),
            categoryComparison: ComparisonAnalysis.CategoryComparison(
                categoryRank: 1, totalCategories: 1, percentile: 50, topCategories: [], similarCategories: []
            ),
            timeComparison: ComparisonAnalysis.TimeComparison(
                previousPeriod: ComparisonAnalysis.TimeComparison.PeriodComparison(
                    current: 0, previous: 0, variance: 0, variancePercentage: 0, improvement: false
                ),
                yearOverYear: ComparisonAnalysis.TimeComparison.PeriodComparison(
                    current: 0, previous: 0, variance: 0, variancePercentage: 0, improvement: false
                ),
                quarterOverQuarter: nil, monthOverMonth: nil
            ),
            benchmarkComparison: ComparisonAnalysis.BenchmarkComparison(
                industryBenchmark: nil, companyBenchmark: 0, regionalBenchmark: nil,
                performanceVsIndustry: nil, performanceVsCompany: 0, performanceVsRegion: nil
            ),
            targetComparison: ComparisonAnalysis.TargetComparison(
                targetAchievement: 0, targetVariance: 0, onTrack: false,
                projectedAchievement: 0, timeRemaining: 0, requiredRunRate: 0
            )
        )
        
        self.insights = []
        self.actions = []
        
        self.forecasts = ForecastData(
            forecastPeriods: [], forecastModel: ForecastData.ForecastModel(
                type: .linear, accuracy: 0, parameters: [:], lastTrained: Date()
            ),
            confidence: ForecastData.ForecastConfidence(overall: 0, shortTerm: 0, mediumTerm: 0, longTerm: 0),
            assumptions: [], scenarios: [], lastUpdated: Date()
        )
        
        self.rankings = CategoryRankings(
            overall: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
            revenue: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
            growth: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
            margin: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
            quality: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
            customer: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
            efficiency: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium)
        )
        
        self.alerts = []
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CategoryPerformance", recordID: id)
        
        record["categoryId"] = categoryId
        record["categoryName"] = categoryName
        record["parentCategoryId"] = parentCategoryId
        record["parentCategoryName"] = parentCategoryName
        record["storeCode"] = storeCode
        record["storeName"] = storeName
        record["reportingPeriod"] = reportingPeriod.rawValue
        record["periodStart"] = periodStart
        record["periodEnd"] = periodEnd
        record["status"] = status.rawValue
        record["lastCalculated"] = lastCalculated
        record["calculatedBy"] = calculatedBy
        record["calculatedByName"] = calculatedByName
        record["reviewedBy"] = reviewedBy
        record["reviewedByName"] = reviewedByName
        record["reviewedAt"] = reviewedAt
        record["approvedBy"] = approvedBy
        record["approvedByName"] = approvedByName
        record["approvedAt"] = approvedAt
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex data as JSON
        if let metricsData = try? JSONEncoder().encode(metrics) {
            record["metrics"] = metricsData
        }
        
        if let targetsData = try? JSONEncoder().encode(targets) {
            record["targets"] = targetsData
        }
        
        if let performanceData = try? JSONEncoder().encode(performance) {
            record["performance"] = performanceData
        }
        
        if let trendsData = try? JSONEncoder().encode(trends) {
            record["trends"] = trendsData
        }
        
        if let comparisonsData = try? JSONEncoder().encode(comparisons) {
            record["comparisons"] = comparisonsData
        }
        
        if !insights.isEmpty,
           let insightsData = try? JSONEncoder().encode(insights) {
            record["insights"] = insightsData
        }
        
        if !actions.isEmpty,
           let actionsData = try? JSONEncoder().encode(actions) {
            record["actions"] = actionsData
        }
        
        if let forecastsData = try? JSONEncoder().encode(forecasts) {
            record["forecasts"] = forecastsData
        }
        
        if let rankingsData = try? JSONEncoder().encode(rankings) {
            record["rankings"] = rankingsData
        }
        
        if !alerts.isEmpty,
           let alertsData = try? JSONEncoder().encode(alerts) {
            record["alerts"] = alertsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CategoryPerformance? {
        return CategoryPerformance(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        categoryId: String,
        categoryName: String,
        parentCategoryId: String? = nil,
        parentCategoryName: String? = nil,
        storeCode: String,
        storeName: String? = nil,
        reportingPeriod: ReportingPeriod,
        periodStart: Date,
        periodEnd: Date,
        calculatedBy: CKRecord.Reference,
        calculatedByName: String
    ) -> CategoryPerformance {
        let now = Date()
        
        return CategoryPerformance(
            id: CKRecord.ID(recordName: UUID().uuidString),
            categoryId: categoryId,
            categoryName: categoryName,
            parentCategoryId: parentCategoryId,
            parentCategoryName: parentCategoryName,
            storeCode: storeCode,
            storeName: storeName,
            reportingPeriod: reportingPeriod,
            periodStart: periodStart,
            periodEnd: periodEnd,
            status: .calculating,
            metrics: CategoryMetrics(
                sales: CategoryMetrics.SalesMetrics(
                    totalRevenue: 0, totalUnits: 0, averageUnitPrice: 0, grossMargin: 0,
                    grossMarginPercentage: 0, salesGrowth: 0, unitGrowth: 0, marketShare: 0,
                    salesVelocity: 0, conversionRate: 0, attachRate: 0, crossSellRate: 0,
                    returnRate: 0, refundAmount: 0, discountAmount: 0, discountPercentage: 0
                ),
                inventory: CategoryMetrics.InventoryMetrics(
                    currentStock: 0, stockValue: 0, stockTurnover: 0, daysOfInventory: 0,
                    stockoutEvents: 0, stockoutDays: 0, overstockEvents: 0, overstockValue: 0,
                    writeOffAmount: 0, writeOffPercentage: 0, receivedUnits: 0, receivedValue: 0,
                    adjustmentUnits: 0, adjustmentValue: 0, shrinkageRate: 0, inventoryAccuracy: 0
                ),
                customer: CategoryMetrics.CustomerMetrics(
                    uniqueCustomers: 0, newCustomers: 0, returningCustomers: 0, customerRetentionRate: 0,
                    averageTransactionValue: 0, transactionCount: 0, averageItemsPerTransaction: 0,
                    customerSatisfactionScore: 0, customerComplaintCount: 0, customerComplimentCount: 0,
                    loyaltySignups: 0, loyaltyRedemptions: 0, referralCount: 0, reviewCount: 0, averageRating: 0
                ),
                operational: CategoryMetrics.OperationalMetrics(
                    staffHours: 0, productivityScore: 0, trainingHours: 0, trainingCompletionRate: 0,
                    qualityScore: 0, complianceScore: 0, safetyIncidents: 0, maintenanceHours: 0,
                    equipmentDowntime: 0, energyConsumption: 0, wasteGenerated: 0, recyclingRate: 0,
                    auditScore: 0, processEfficiency: 0
                ),
                financial: CategoryMetrics.FinancialMetrics(
                    costOfGoodsSold: 0, operatingExpenses: 0, marketingSpend: 0, promotionalSpend: 0,
                    laborCost: 0, overheadAllocation: 0, netProfit: 0, netProfitMargin: 0,
                    returnOnInvestment: 0, priceElasticity: 0, competitiveIndex: 0, valuePercentage: 0,
                    costPerAcquisition: 0, lifetimeValue: 0
                ),
                quality: CategoryMetrics.QualityMetrics(
                    defectRate: 0, qualityScore: 0, customerSatisfaction: 0, returnedDefectiveUnits: 0,
                    qualityComplaints: 0, qualityCompliments: 0, certificationScore: 0, auditFindings: 0,
                    correctiveActions: 0, preventiveActions: 0, supplierQualityScore: 0, productRecalls: 0,
                    safetyIncidents: 0, complianceViolations: 0
                )
            ),
            targets: CategoryTargets(
                revenueTarget: 0, unitsTarget: 0, marginTarget: 0, growthTarget: 0,
                marketShareTarget: 0, inventoryTurnTarget: 0, customerSatisfactionTarget: 0,
                qualityTarget: 0, costTarget: 0, customTargets: [:], targetPeriod: "",
                setBy: calculatedBy, setByName: calculatedByName, setAt: now,
                reviewFrequency: .quarterly,
                achievementThresholds: CategoryTargets.AchievementThresholds(
                    excellent: 110, good: 100, satisfactory: 90, needsImprovement: 80, poor: 70
                )
            ),
            performance: PerformanceAnalysis(
                overallScore: 0, categoryGrade: .satisfactory, keyStrengths: [], improvementAreas: [],
                riskFactors: [], opportunities: [], recommendations: [],
                targetAchievement: PerformanceAnalysis.TargetAchievement(
                    revenueAchievement: 0, unitsAchievement: 0, marginAchievement: 0,
                    growthAchievement: 0, overallAchievement: 0, achievedTargets: 0,
                    totalTargets: 0, achievementRate: 0
                ),
                competitivePosition: PerformanceAnalysis.CompetitivePosition(
                    marketRank: nil, marketShare: 0, competitiveAdvantages: [], competitiveThreats: [],
                    pricingPosition: .competitive, qualityPosition: .comparable, innovationPosition: .follower
                ),
                seasonalityImpact: PerformanceAnalysis.SeasonalityAnalysis(
                    isSeasonalCategory: false, peakMonths: [], lowMonths: [], seasonalityIndex: 1.0,
                    yearOverYearComparison: [], seasonalAdjustedPerformance: 0
                )
            ),
            trends: TrendAnalysis(
                shortTermTrend: .stable, mediumTermTrend: .stable, longTermTrend: .stable,
                trendStrength: .moderate, volatility: .moderate, cyclicality: .none,
                historicalData: [], movingAverages: TrendAnalysis.MovingAverages(
                    sma7: 0, sma30: 0, sma90: 0, ema7: 0, ema30: 0
                ),
                trendAnalytics: TrendAnalysis.TrendAnalytics(
                    regressionSlope: 0, rSquared: 0, standardDeviation: 0,
                    coefficientOfVariation: 0, correlationFactors: [:]
                )
            ),
            comparisons: ComparisonAnalysis(
                storeComparison: ComparisonAnalysis.StoreComparison(
                    storeRank: 1, totalStores: 1, percentile: 50, aboveAverage: true,
                    topPerformers: [], similarStores: []
                ),
                categoryComparison: ComparisonAnalysis.CategoryComparison(
                    categoryRank: 1, totalCategories: 1, percentile: 50, topCategories: [], similarCategories: []
                ),
                timeComparison: ComparisonAnalysis.TimeComparison(
                    previousPeriod: ComparisonAnalysis.TimeComparison.PeriodComparison(
                        current: 0, previous: 0, variance: 0, variancePercentage: 0, improvement: false
                    ),
                    yearOverYear: ComparisonAnalysis.TimeComparison.PeriodComparison(
                        current: 0, previous: 0, variance: 0, variancePercentage: 0, improvement: false
                    ),
                    quarterOverQuarter: nil, monthOverMonth: nil
                ),
                benchmarkComparison: ComparisonAnalysis.BenchmarkComparison(
                    industryBenchmark: nil, companyBenchmark: 0, regionalBenchmark: nil,
                    performanceVsIndustry: nil, performanceVsCompany: 0, performanceVsRegion: nil
                ),
                targetComparison: ComparisonAnalysis.TargetComparison(
                    targetAchievement: 0, targetVariance: 0, onTrack: false,
                    projectedAchievement: 0, timeRemaining: 0, requiredRunRate: 0
                )
            ),
            insights: [],
            actions: [],
            forecasts: ForecastData(
                forecastPeriods: [], forecastModel: ForecastData.ForecastModel(
                    type: .linear, accuracy: 0, parameters: [:], lastTrained: now
                ),
                confidence: ForecastData.ForecastConfidence(overall: 0, shortTerm: 0, mediumTerm: 0, longTerm: 0),
                assumptions: [], scenarios: [], lastUpdated: now
            ),
            rankings: CategoryRankings(
                overall: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
                revenue: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
                growth: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
                margin: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
                quality: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
                customer: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium),
                efficiency: CategoryRankings.RankingInfo(rank: 1, totalCategories: 1, percentile: 50, score: 0, tier: .medium)
            ),
            alerts: [],
            lastCalculated: now,
            calculatedBy: calculatedBy,
            calculatedByName: calculatedByName,
            reviewedBy: nil,
            reviewedByName: nil,
            reviewedAt: nil,
            approvedBy: nil,
            approvedByName: nil,
            approvedAt: nil,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
    }
}
