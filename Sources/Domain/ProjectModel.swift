import Foundation
import CloudKit

/// Advanced Project Model with comprehensive portfolio management
/// Implements PT3VS1 specifications for enterprise project management
public struct ProjectModel: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String
    public var projectManager: String
    public var sponsor: String
    public var startDate: Date
    public var endDate: Date
    public var status: ProjectStatus
    public var priority: ProjectPriority
    
    // Financial Management
    public var budget: Double
    public var actualCost: Double
    public var budgetVariance: Double { actualCost - budget }
    public var budgetVariancePercentage: Double { 
        budget > 0 ? (budgetVariance / budget) * 100 : 0 
    }
    public var roi: ROICalculation
    public var costBreakdown: [CostCategory]
    public var financialForecasts: [FinancialForecast]
    
    // Progress and Performance
    public var progress: Double // 0-100
    public var overallHealth: ProjectHealth
    public var performanceIndicators: [PerformanceIndicator]
    public var milestoneProgress: Double
    public var scheduleVariance: TimeInterval // In seconds
    
    // Structure and Organization
    public var phases: [ProjectPhase]
    public var dependencies: [ProjectDependency]
    public var deliverables: [Deliverable]
    public var workBreakdownStructure: WorkBreakdownStructure
    
    // Resource Management
    public var resources: [ResourceAllocation]
    public var resourceUtilization: ResourceUtilization
    public var resourceOptimization: ResourceOptimization
    public var capacityPlanning: CapacityPlanning
    
    // Risk Management
    public var risks: [ProjectRisk]
    public var riskAssessment: RiskAssessment
    public var riskMitigationPlans: [RiskMitigationPlan]
    public var contingencyPlans: [ContingencyPlan]
    
    // Stakeholder Management
    public var stakeholders: [String]
    public var stakeholderMatrix: StakeholderMatrix
    public var communicationPlan: CommunicationPlan
    
    // Timeline and Scheduling
    public var criticalPath: CriticalPath
    public var timelineAnalysis: TimelineAnalysis
    public var scheduleOptimization: ScheduleOptimization
    
    // Portfolio Management
    public var portfolioAlignment: PortfolioAlignment
    public var strategicValue: StrategicValue
    public var portfolioMetrics: PortfolioMetrics
    
    // Quality and Governance
    public var qualityMetrics: QualityMetrics
    public var governanceFramework: GovernanceFramework
    public var complianceRequirements: [ComplianceRequirement]
    
    // Integration and Automation
    public var integrations: [ProjectIntegration]
    public var automationRules: [AutomationRule]
    public var dashboardConfiguration: DashboardConfiguration
    
    // Metadata and Tracking
    public var tags: [String]
    public var customFields: [String: String]
    public var auditTrail: [AuditEntry]
    public var createdAt: Date
    public var updatedAt: Date
    public var lastReviewDate: Date?
    public var nextReviewDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        projectManager: String,
        sponsor: String,
        startDate: Date,
        endDate: Date,
        status: ProjectStatus = .planning,
        priority: ProjectPriority = .medium,
        budget: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.projectManager = projectManager
        self.sponsor = sponsor
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.priority = priority
        self.budget = budget
        self.actualCost = 0.0
        
        // Initialize with default values
        self.roi = ROICalculation()
        self.costBreakdown = []
        self.financialForecasts = []
        self.progress = 0.0
        self.overallHealth = .green
        self.performanceIndicators = []
        self.milestoneProgress = 0.0
        self.scheduleVariance = 0
        self.phases = []
        self.dependencies = []
        self.deliverables = []
        self.workBreakdownStructure = WorkBreakdownStructure()
        self.resources = []
        self.resourceUtilization = ResourceUtilization()
        self.resourceOptimization = ResourceOptimization()
        self.capacityPlanning = CapacityPlanning()
        self.risks = []
        self.riskAssessment = RiskAssessment()
        self.riskMitigationPlans = []
        self.contingencyPlans = []
        self.stakeholders = []
        self.stakeholderMatrix = StakeholderMatrix()
        self.communicationPlan = CommunicationPlan()
        self.criticalPath = CriticalPath()
        self.timelineAnalysis = TimelineAnalysis()
        self.scheduleOptimization = ScheduleOptimization()
        self.portfolioAlignment = PortfolioAlignment()
        self.strategicValue = StrategicValue()
        self.portfolioMetrics = PortfolioMetrics()
        self.qualityMetrics = QualityMetrics()
        self.governanceFramework = GovernanceFramework()
        self.complianceRequirements = []
        self.integrations = []
        self.automationRules = []
        self.dashboardConfiguration = DashboardConfiguration()
        self.tags = []
        self.customFields = [:]
        self.auditTrail = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastReviewDate = nil
        self.nextReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
    }
}

// MARK: - Project Status and Priority

public enum ProjectStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    case archived = "archived"
    
    public var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .archived: return "Archived"
        }
    }
    
    public var color: String {
        switch self {
        case .planning: return "blue"
        case .active: return "green"
        case .onHold: return "yellow"
        case .completed: return "green"
        case .cancelled: return "red"
        case .archived: return "gray"
        }
    }
}

public enum ProjectPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    public var numericValue: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

public enum ProjectHealth: String, Codable {
    case green = "green"
    case yellow = "yellow"
    case red = "red"
    
    public var displayName: String {
        switch self {
        case .green: return "On Track"
        case .yellow: return "At Risk"
        case .red: return "Critical"
        }
    }
}

// MARK: - Financial Management

public struct ROICalculation: Codable {
    public var expectedBenefits: Double = 0.0
    public var totalInvestment: Double = 0.0
    public var timeToBreakeven: TimeInterval = 0
    public var netPresentValue: Double = 0.0
    public var internalRateOfReturn: Double = 0.0
    public var paybackPeriod: TimeInterval = 0
    public var riskAdjustedROI: Double = 0.0
    public var lastCalculated: Date = Date()
    
    public var roi: Double {
        guard totalInvestment > 0 else { return 0 }
        return ((expectedBenefits - totalInvestment) / totalInvestment) * 100
    }
    
    public var isPositive: Bool { roi > 0 }
}

public struct CostCategory: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let name: String
    public let budgetedAmount: Double
    public var actualAmount: Double
    public let costType: CostType
    public var variance: Double { actualAmount - budgetedAmount }
    public var variancePercentage: Double {
        budgetedAmount > 0 ? (variance / budgetedAmount) * 100 : 0
    }
    
    public init(name: String, budgetedAmount: Double, actualAmount: Double = 0.0, costType: CostType = .operational) {
        self.name = name
        self.budgetedAmount = budgetedAmount
        self.actualAmount = actualAmount
        self.costType = costType
    }
}

public enum CostType: String, Codable {
    case capital = "capital"
    case operational = "operational"
    case labor = "labor"
    case material = "material"
    case overhead = "overhead"
    case contingency = "contingency"
}

public struct FinancialForecast: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let period: ForecastPeriod
    public let forecastDate: Date
    public let projectedCost: Double
    public let projectedBenefits: Double
    public let confidence: Double // 0-100
    public let assumptions: [String]
    public let riskFactors: [String]
    
    public init(period: ForecastPeriod, projectedCost: Double, projectedBenefits: Double, confidence: Double = 80.0) {
        self.period = period
        self.forecastDate = Date()
        self.projectedCost = projectedCost
        self.projectedBenefits = projectedBenefits
        self.confidence = confidence
        self.assumptions = []
        self.riskFactors = []
    }
}

public enum ForecastPeriod: String, Codable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annually = "annually"
}

// MARK: - Performance and Progress

public struct PerformanceIndicator: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let name: String
    public let category: PerformanceCategory
    public let target: Double
    public var actual: Double
    public let unit: String
    public let frequency: MeasurementFrequency
    public var trend: TrendDirection
    public let lastUpdated: Date
    
    public var performancePercentage: Double {
        guard target > 0 else { return 0 }
        return (actual / target) * 100
    }
    
    public var status: PerformanceStatus {
        let percentage = performancePercentage
        switch percentage {
        case 95...: return .excellent
        case 85..<95: return .good
        case 70..<85: return .satisfactory
        case 50..<70: return .belowTarget
        default: return .poor
        }
    }
    
    public init(name: String, category: PerformanceCategory, target: Double, unit: String = "", frequency: MeasurementFrequency = .weekly) {
        self.name = name
        self.category = category
        self.target = target
        self.actual = 0.0
        self.unit = unit
        self.frequency = frequency
        self.trend = .stable
        self.lastUpdated = Date()
    }
}

public enum PerformanceCategory: String, Codable {
    case schedule = "schedule"
    case budget = "budget"
    case quality = "quality"
    case scope = "scope"
    case stakeholder = "stakeholder"
    case risk = "risk"
}

public enum MeasurementFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
}

public enum TrendDirection: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}

public enum PerformanceStatus: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case belowTarget = "below_target"
    case poor = "poor"
}

// MARK: - Project Structure

public struct ProjectPhase: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var status: PhaseStatus
    public var progress: Double // 0-100
    public var tasks: [String] // Task IDs
    public var milestones: [Milestone]
    public var budget: Double
    public var actualCost: Double
    public var dependencies: [String] // Phase IDs
    public var deliverables: [String] // Deliverable IDs
    public var gatesCriteria: [GateCriteria]
    
    public var isOnSchedule: Bool {
        let today = Date()
        if today < startDate { return true } // Not started yet
        if today > endDate { return progress >= 100 } // Should be complete
        
        // Calculate expected progress based on time elapsed
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsedDuration = today.timeIntervalSince(startDate)
        let expectedProgress = (elapsedDuration / totalDuration) * 100
        
        return progress >= (expectedProgress - 10) // 10% tolerance
    }
    
    public init(name: String, startDate: Date, endDate: Date, budget: Double = 0.0) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.status = .notStarted
        self.progress = 0.0
        self.tasks = []
        self.milestones = []
        self.budget = budget
        self.actualCost = 0.0
        self.dependencies = []
        self.deliverables = []
        self.gatesCriteria = []
    }
}

public enum PhaseStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case onHold = "on_hold"
    case cancelled = "cancelled"
}

public struct Milestone: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public var name: String
    public var description: String
    public var dueDate: Date
    public var completedDate: Date?
    public var status: MilestoneStatus
    public var deliverables: [String] // Deliverable IDs
    public var dependencies: [String] // Milestone IDs
    public var criticalPath: Bool
    public var acceptanceCriteria: [AcceptanceCriteria]
    
    public var isOverdue: Bool {
        guard status != .completed else { return false }
        return Date() > dueDate
    }
    
    public var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    public init(name: String, description: String = "", dueDate: Date, criticalPath: Bool = false) {
        self.name = name
        self.description = description
        self.dueDate = dueDate
        self.completedDate = nil
        self.status = .notStarted
        self.deliverables = []
        self.dependencies = []
        self.criticalPath = criticalPath
        self.acceptanceCriteria = []
    }
}

public enum MilestoneStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case atRisk = "at_risk"
    case overdue = "overdue"
}

public struct AcceptanceCriteria: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let description: String
    public var isMet: Bool
    public let priority: CriteriaPriority
    public var verificationMethod: String
    public var verifiedBy: String?
    public var verificationDate: Date?
    
    public init(description: String, priority: CriteriaPriority = .medium, verificationMethod: String = "") {
        self.description = description
        self.isMet = false
        self.priority = priority
        self.verificationMethod = verificationMethod
        self.verifiedBy = nil
        self.verificationDate = nil
    }
}

public enum CriteriaPriority: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

// MARK: - Dependencies and Work Breakdown

public struct ProjectDependency: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let fromId: String // Task/Phase/Milestone ID
    public let toId: String // Task/Phase/Milestone ID
    public let dependencyType: DependencyType
    public let lag: TimeInterval // Delay between dependent items
    public var isActive: Bool
    public let description: String?
    
    public init(fromId: String, toId: String, dependencyType: DependencyType, lag: TimeInterval = 0, description: String? = nil) {
        self.fromId = fromId
        self.toId = toId
        self.dependencyType = dependencyType
        self.lag = lag
        self.isActive = true
        self.description = description
    }
}

public enum DependencyType: String, Codable {
    case finishToStart = "finish_to_start"
    case startToStart = "start_to_start"
    case finishToFinish = "finish_to_finish"
    case startToFinish = "start_to_finish"
}

public struct WorkBreakdownStructure: Codable {
    public var levels: [WBSLevel] = []
    public var totalWorkPackages: Int = 0
    public var hierarchyDepth: Int = 0
    public var estimationAccuracy: Double = 0.0
    
    public init() {}
}

public struct WBSLevel: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let level: Int
    public let name: String
    public let parentId: String?
    public var workPackages: [WorkPackage]
    public var estimatedEffort: Double // In hours
    public var actualEffort: Double // In hours
    
    public init(level: Int, name: String, parentId: String? = nil) {
        self.level = level
        self.name = name
        self.parentId = parentId
        self.workPackages = []
        self.estimatedEffort = 0.0
        self.actualEffort = 0.0
    }
}

public struct WorkPackage: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let name: String
    public let description: String
    public var estimatedHours: Double
    public var actualHours: Double
    public var assignedResources: [String] // Resource IDs
    public var deliverables: [String] // Deliverable IDs
    public var status: WorkPackageStatus
    
    public init(name: String, description: String, estimatedHours: Double) {
        self.name = name
        self.description = description
        self.estimatedHours = estimatedHours
        self.actualHours = 0.0
        self.assignedResources = []
        self.deliverables = []
        self.status = .notStarted
    }
}

public enum WorkPackageStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case onHold = "on_hold"
}

public struct Deliverable: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public var name: String
    public var description: String
    public var type: DeliverableType
    public var dueDate: Date
    public var deliveredDate: Date?
    public var status: DeliverableStatus
    public var qualityScore: Double // 0-100
    public var acceptanceCriteria: [AcceptanceCriteria]
    public var approver: String?
    public var approvalDate: Date?
    
    public var isOverdue: Bool {
        guard status != .delivered && status != .approved else { return false }
        return Date() > dueDate
    }
    
    public init(name: String, description: String, type: DeliverableType, dueDate: Date) {
        self.name = name
        self.description = description
        self.type = type
        self.dueDate = dueDate
        self.deliveredDate = nil
        self.status = .notStarted
        self.qualityScore = 0.0
        self.acceptanceCriteria = []
        self.approver = nil
        self.approvalDate = nil
    }
}

public enum DeliverableType: String, Codable {
    case document = "document"
    case software = "software"
    case report = "report"
    case training = "training"
    case process = "process"
    case system = "system"
    case other = "other"
}

public enum DeliverableStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case delivered = "delivered"
    case approved = "approved"
    case rejected = "rejected"
}

// MARK: - Resource Management

public struct ResourceAllocation: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let resourceId: String
    public let resourceType: ResourceType
    public var allocation: Double // Percentage (0-100)
    public let startDate: Date
    public let endDate: Date
    public var cost: Double
    public var actualUtilization: Double // Percentage (0-100)
    public var efficiency: Double // Percentage (0-100)
    
    public var isOverAllocated: Bool { allocation > 100 }
    public var isUnderUtilized: Bool { actualUtilization < allocation * 0.8 } // 80% threshold
    
    public init(resourceId: String, resourceType: ResourceType, allocation: Double, startDate: Date, endDate: Date, cost: Double = 0.0) {
        self.resourceId = resourceId
        self.resourceType = resourceType
        self.allocation = allocation
        self.startDate = startDate
        self.endDate = endDate
        self.cost = cost
        self.actualUtilization = 0.0
        self.efficiency = 0.0
    }
}

public enum ResourceType: String, Codable, CaseIterable {
    case human = "human"
    case equipment = "equipment"
    case facility = "facility"
    case software = "software"
    case material = "material"
}

public struct ResourceUtilization: Codable {
    public var totalCapacity: Double = 0.0
    public var allocatedCapacity: Double = 0.0
    public var actualUtilization: Double = 0.0
    public var utilizationPercentage: Double {
        totalCapacity > 0 ? (actualUtilization / totalCapacity) * 100 : 0
    }
    public var overAllocationRisk: RiskLevel = .low
    public var bottlenecks: [ResourceBottleneck] = []
    
    public init() {}
}

public struct ResourceBottleneck: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let resourceId: String
    public let severity: BottleneckSeverity
    public let description: String
    public let impact: String
    public let recommendedActions: [String]
    
    public init(resourceId: String, severity: BottleneckSeverity, description: String, impact: String) {
        self.resourceId = resourceId
        self.severity = severity
        self.description = description
        self.impact = impact
        self.recommendedActions = []
    }
}

public enum BottleneckSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public struct ResourceOptimization: Codable {
    public var optimizationScore: Double = 0.0 // 0-100
    public var recommendations: [OptimizationRecommendation] = []
    public var potentialSavings: Double = 0.0
    public var implementationComplexity: OptimizationComplexity = .medium
    public var lastAnalysis: Date = Date()
    
    public init() {}
}

public struct OptimizationRecommendation: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let type: OptimizationType
    public let description: String
    public let expectedBenefit: String
    public let implementationEffort: ImplementationEffort
    public let priority: RecommendationPriority
    
    public init(type: OptimizationType, description: String, expectedBenefit: String, implementationEffort: ImplementationEffort, priority: RecommendationPriority) {
        self.type = type
        self.description = description
        self.expectedBenefit = expectedBenefit
        self.implementationEffort = implementationEffort
        self.priority = priority
    }
}

public enum OptimizationType: String, Codable {
    case reallocation = "reallocation"
    case leveling = "leveling"
    case substitution = "substitution"
    case reduction = "reduction"
    case scheduling = "scheduling"
}

public enum OptimizationComplexity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public enum ImplementationEffort: String, Codable {
    case minimal = "minimal"
    case moderate = "moderate"
    case significant = "significant"
}

public enum RecommendationPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public struct CapacityPlanning: Codable {
    public var currentCapacity: Double = 0.0
    public var forecastedDemand: Double = 0.0
    public var capacityGap: Double { forecastedDemand - currentCapacity }
    public var capacityBuffer: Double = 0.2 // 20% buffer
    public var scalingOptions: [ScalingOption] = []
    public var capacityConstraints: [CapacityConstraint] = []
    
    public var hasCapacityGap: Bool { capacityGap > 0 }
    public var hasCapacityRisk: Bool { capacityGap > (currentCapacity * capacityBuffer) }
    
    public init() {}
}

public struct ScalingOption: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let name: String
    public let description: String
    public let additionalCapacity: Double
    public let cost: Double
    public let timeToImplement: TimeInterval
    public let riskLevel: RiskLevel
    
    public init(name: String, description: String, additionalCapacity: Double, cost: Double, timeToImplement: TimeInterval, riskLevel: RiskLevel) {
        self.name = name
        self.description = description
        self.additionalCapacity = additionalCapacity
        self.cost = cost
        self.timeToImplement = timeToImplement
        self.riskLevel = riskLevel
    }
}

public struct CapacityConstraint: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let type: ConstraintType
    public let description: String
    public let impact: ConstraintImpact
    public let mitigationStrategy: String?
    
    public init(type: ConstraintType, description: String, impact: ConstraintImpact, mitigationStrategy: String? = nil) {
        self.type = type
        self.description = description
        self.impact = impact
        self.mitigationStrategy = mitigationStrategy
    }
}

public enum ConstraintType: String, Codable {
    case budget = "budget"
    case time = "time"
    case skills = "skills"
    case equipment = "equipment"
    case regulatory = "regulatory"
}

public enum ConstraintImpact: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Risk Management

public struct ProjectRisk: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public var name: String
    public var description: String
    public var category: RiskCategory
    public var probability: RiskProbability
    public var impact: RiskImpact
    public var riskScore: Double { probability.numericValue * impact.numericValue }
    public var riskLevel: RiskLevel {
        switch riskScore {
        case 1.0..<2.0: return .low
        case 2.0..<3.5: return .medium
        case 3.5..<4.5: return .high
        default: return .critical
        }
    }
    public var status: RiskStatus
    public var owner: String?
    public var identifiedDate: Date
    public var lastReviewDate: Date?
    public var nextReviewDate: Date?
    public var mitigationActions: [MitigationAction]
    
    public init(name: String, description: String, category: RiskCategory, probability: RiskProbability, impact: RiskImpact, owner: String? = nil) {
        self.name = name
        self.description = description
        self.category = category
        self.probability = probability
        self.impact = impact
        self.status = .identified
        self.owner = owner
        self.identifiedDate = Date()
        self.lastReviewDate = nil
        self.nextReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        self.mitigationActions = []
    }
}

public enum RiskCategory: String, Codable {
    case technical = "technical"
    case schedule = "schedule"
    case budget = "budget"
    case resource = "resource"
    case external = "external"
    case scope = "scope"
    case quality = "quality"
    case stakeholder = "stakeholder"
}

public enum RiskProbability: String, Codable {
    case veryLow = "very_low"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    public var numericValue: Double {
        switch self {
        case .veryLow: return 1.0
        case .low: return 2.0
        case .medium: return 3.0
        case .high: return 4.0
        case .veryHigh: return 5.0
        }
    }
}

public enum RiskImpact: String, Codable {
    case negligible = "negligible"
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
    case severe = "severe"
    
    public var numericValue: Double {
        switch self {
        case .negligible: return 1.0
        case .minor: return 2.0
        case .moderate: return 3.0
        case .major: return 4.0
        case .severe: return 5.0
        }
    }
}

public enum RiskLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

public enum RiskStatus: String, Codable {
    case identified = "identified"
    case assessed = "assessed"
    case mitigated = "mitigated"
    case accepted = "accepted"
    case transferred = "transferred"
    case closed = "closed"
}

public struct MitigationAction: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let description: String
    public let type: MitigationType
    public let owner: String
    public let dueDate: Date
    public var completedDate: Date?
    public var status: ActionStatus
    public let estimatedCost: Double
    public let effectiveness: ActionEffectiveness
    
    public var isOverdue: Bool {
        guard status != .completed else { return false }
        return Date() > dueDate
    }
    
    public init(description: String, type: MitigationType, owner: String, dueDate: Date, estimatedCost: Double = 0.0, effectiveness: ActionEffectiveness = .medium) {
        self.description = description
        self.type = type
        self.owner = owner
        self.dueDate = dueDate
        self.completedDate = nil
        self.status = .notStarted
        self.estimatedCost = estimatedCost
        self.effectiveness = effectiveness
    }
}

public enum MitigationType: String, Codable {
    case avoid = "avoid"
    case mitigate = "mitigate"
    case transfer = "transfer"
    case accept = "accept"
}

public enum ActionStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

public enum ActionEffectiveness: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public struct RiskAssessment: Codable {
    public var overallRiskScore: Double = 0.0
    public var riskTolerance: RiskTolerance = .medium
    public var highRiskItems: Int = 0
    public var criticalRiskItems: Int = 0
    public var riskTrend: TrendDirection = .stable
    public var lastAssessmentDate: Date = Date()
    public var nextAssessmentDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    public init() {}
}

public enum RiskTolerance: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public struct RiskMitigationPlan: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let riskId: String
    public let planName: String
    public let strategy: MitigationStrategy
    public let actions: [MitigationAction]
    public var totalCost: Double { actions.reduce(0) { $0 + $1.estimatedCost } }
    public let implementationTimeline: TimeInterval
    public var status: PlanStatus
    
    public init(riskId: String, planName: String, strategy: MitigationStrategy, implementationTimeline: TimeInterval) {
        self.riskId = riskId
        self.planName = planName
        self.strategy = strategy
        self.actions = []
        self.implementationTimeline = implementationTimeline
        self.status = .draft
    }
}

public enum MitigationStrategy: String, Codable {
    case prevention = "prevention"
    case reduction = "reduction"
    case contingency = "contingency"
    case acceptance = "acceptance"
}

public enum PlanStatus: String, Codable {
    case draft = "draft"
    case approved = "approved"
    case active = "active"
    case completed = "completed"
}

public struct ContingencyPlan: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let name: String
    public let triggerConditions: [String]
    public let activationCriteria: [String]
    public let responseActions: [ResponseAction]
    public let resourceRequirements: [String]
    public let estimatedCost: Double
    public let activationTimeframe: TimeInterval
    public var isActive: Bool
    
    public init(name: String, estimatedCost: Double = 0.0, activationTimeframe: TimeInterval = 0) {
        self.name = name
        self.triggerConditions = []
        self.activationCriteria = []
        self.responseActions = []
        self.resourceRequirements = []
        self.estimatedCost = estimatedCost
        self.activationTimeframe = activationTimeframe
        self.isActive = false
    }
}

public struct ResponseAction: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let description: String
    public let responsible: String
    public let timeframe: TimeInterval
    public let priority: ActionPriority
    
    public init(description: String, responsible: String, timeframe: TimeInterval, priority: ActionPriority = .medium) {
        self.description = description
        self.responsible = responsible
        self.timeframe = timeframe
        self.priority = priority
    }
}

public enum ActionPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Critical Path and Timeline Analysis

public struct CriticalPath: Codable {
    public var pathItems: [CriticalPathItem] = []
    public var totalDuration: TimeInterval = 0
    public var slackTime: TimeInterval = 0
    public var criticalityIndex: Double = 0.0 // 0-100
    public var lastCalculated: Date = Date()
    
    public var hasCriticalPath: Bool { !pathItems.isEmpty }
    public var riskLevel: RiskLevel {
        switch criticalityIndex {
        case 0..<25: return .low
        case 25..<50: return .medium
        case 50..<75: return .high
        default: return .critical
        }
    }
    
    public init() {}
}

public struct CriticalPathItem: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let itemId: String // Task/Phase/Milestone ID
    public let itemType: PathItemType
    public let name: String
    public let duration: TimeInterval
    public let startDate: Date
    public let endDate: Date
    public let slack: TimeInterval
    public let criticality: Double // 0-100
    
    public init(itemId: String, itemType: PathItemType, name: String, duration: TimeInterval, startDate: Date, endDate: Date, slack: TimeInterval = 0, criticality: Double = 0) {
        self.itemId = itemId
        self.itemType = itemType
        self.name = name
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.slack = slack
        self.criticality = criticality
    }
}

public enum PathItemType: String, Codable {
    case task = "task"
    case phase = "phase"
    case milestone = "milestone"
}

public struct TimelineAnalysis: Codable {
    public var projectStartVariance: TimeInterval = 0
    public var projectEndVariance: TimeInterval = 0
    public var phaseSchedulePerformance: [String: Double] = [:] // Phase ID to SPI
    public var schedulePerformanceIndex: Double = 1.0 // SPI
    public var scheduleVarianceIndex: Double = 0.0 // SV in days
    public var forecastCompletion: Date = Date()
    public var probabilityOnTime: Double = 0.0 // 0-100
    public var lastAnalysis: Date = Date()
    
    public var scheduleHealth: ProjectHealth {
        switch schedulePerformanceIndex {
        case 0.95...: return .green
        case 0.85..<0.95: return .yellow
        default: return .red
        }
    }
    
    public init() {}
}

public struct ScheduleOptimization: Codable {
    public var optimizationOpportunities: [OptimizationOpportunity] = []
    public var potentialTimeReduction: TimeInterval = 0
    public var implementationRisk: RiskLevel = .medium
    public var costImplication: Double = 0.0
    public var recommendedActions: [ScheduleAction] = []
    
    public init() {}
}

public struct OptimizationOpportunity: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let type: OptimizationOpportunityType
    public let description: String
    public let potentialTimeSaving: TimeInterval
    public let implementationComplexity: OptimizationComplexity
    public let riskLevel: RiskLevel
    public let costImpact: Double
    
    public init(type: OptimizationOpportunityType, description: String, potentialTimeSaving: TimeInterval, implementationComplexity: OptimizationComplexity, riskLevel: RiskLevel, costImpact: Double = 0.0) {
        self.type = type
        self.description = description
        self.potentialTimeSaving = potentialTimeSaving
        self.implementationComplexity = implementationComplexity
        self.riskLevel = riskLevel
        self.costImpact = costImpact
    }
}

public enum OptimizationOpportunityType: String, Codable {
    case parallelization = "parallelization"
    case resourceReallocation = "resource_reallocation"
    case scopeReduction = "scope_reduction"
    case processImprovement = "process_improvement"
    case technologyUpgrade = "technology_upgrade"
}

public struct ScheduleAction: Identifiable, Codable {
    public let id: String = UUID().uuidString
    public let description: String
    public let type: ScheduleActionType
    public let priority: ActionPriority
    public let estimatedEffort: Double // In hours
    public let expectedBenefit: String
    
    public init(description: String, type: ScheduleActionType, priority: ActionPriority, estimatedEffort: Double, expectedBenefit: String) {
        self.description = description
        self.type = type
        self.priority = priority
        self.estimatedEffort = estimatedEffort
        self.expectedBenefit = expectedBenefit
    }
}

public enum ScheduleActionType: String, Codable {
    case replan = "replan"
    case reallocate = "reallocate"
    case accelerate = "accelerate"
    case rescope = "rescope"
    case optimize = "optimize"
}

// MARK: - Additional supporting structures continue in next part...
// (Portfolio Management, Quality Metrics, Governance, etc.)

// Placeholder structures for remaining types
public struct StakeholderMatrix: Codable {
    public init() {}
}

public struct CommunicationPlan: Codable {
    public init() {}
}

public struct PortfolioAlignment: Codable {
    public init() {}
}

public struct StrategicValue: Codable {
    public init() {}
}

public struct PortfolioMetrics: Codable {
    public init() {}
}

public struct QualityMetrics: Codable {
    public init() {}
}

public struct GovernanceFramework: Codable {
    public init() {}
}

public struct ComplianceRequirement: Codable {
    public init() {}
}

public struct ProjectIntegration: Codable {
    public init() {}
}

public struct AutomationRule: Codable {
    public init() {}
}

public struct DashboardConfiguration: Codable {
    public init() {}
}

public struct AuditEntry: Codable {
    public init() {}
}

public struct GateCriteria: Codable {
    public init() {}
}

// MARK: - CloudKit Extensions

extension ProjectModel {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ProjectModel", recordID: CKRecord.ID(recordName: id))
        
        record["name"] = name
        record["description"] = description
        record["projectManager"] = projectManager
        record["sponsor"] = sponsor
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["status"] = status.rawValue
        record["priority"] = priority.rawValue
        record["budget"] = budget
        record["actualCost"] = actualCost
        record["progress"] = progress
        record["overallHealth"] = overallHealth.rawValue
        record["milestoneProgress"] = milestoneProgress
        record["scheduleVariance"] = scheduleVariance
        record["stakeholders"] = stakeholders
        record["tags"] = tags
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["lastReviewDate"] = lastReviewDate
        record["nextReviewDate"] = nextReviewDate
        
        // Serialize complex objects as Data
        if let roiData = try? JSONEncoder().encode(roi) {
            record["roi"] = roiData
        }
        
        if let costBreakdownData = try? JSONEncoder().encode(costBreakdown) {
            record["costBreakdown"] = costBreakdownData
        }
        
        if let phasesData = try? JSONEncoder().encode(phases) {
            record["phases"] = phasesData
        }
        
        if let dependenciesData = try? JSONEncoder().encode(dependencies) {
            record["dependencies"] = dependenciesData
        }
        
        if let resourcesData = try? JSONEncoder().encode(resources) {
            record["resources"] = resourcesData
        }
        
        if let risksData = try? JSONEncoder().encode(risks) {
            record["risks"] = risksData
        }
        
        if let deliverablesData = try? JSONEncoder().encode(deliverables) {
            record["deliverables"] = deliverablesData
        }
        
        if let performanceIndicatorsData = try? JSONEncoder().encode(performanceIndicators) {
            record["performanceIndicators"] = performanceIndicatorsData
        }
        
        if let customFieldsData = try? JSONEncoder().encode(customFields) {
            record["customFields"] = customFieldsData
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> ProjectModel? {
        guard let name = record["name"] as? String,
              let description = record["description"] as? String,
              let projectManager = record["projectManager"] as? String,
              let sponsor = record["sponsor"] as? String,
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let statusString = record["status"] as? String,
              let status = ProjectStatus(rawValue: statusString),
              let priorityString = record["priority"] as? String,
              let priority = ProjectPriority(rawValue: priorityString),
              let budget = record["budget"] as? Double else {
            return nil
        }
        
        var project = ProjectModel(
            id: record.recordID.recordName,
            name: name,
            description: description,
            projectManager: projectManager,
            sponsor: sponsor,
            startDate: startDate,
            endDate: endDate,
            status: status,
            priority: priority,
            budget: budget
        )
        
        // Restore other properties
        project.actualCost = record["actualCost"] as? Double ?? 0.0
        project.progress = record["progress"] as? Double ?? 0.0
        project.milestoneProgress = record["milestoneProgress"] as? Double ?? 0.0
        project.scheduleVariance = record["scheduleVariance"] as? TimeInterval ?? 0
        project.stakeholders = record["stakeholders"] as? [String] ?? []
        project.tags = record["tags"] as? [String] ?? []
        project.createdAt = record["createdAt"] as? Date ?? Date()
        project.updatedAt = record["updatedAt"] as? Date ?? Date()
        project.lastReviewDate = record["lastReviewDate"] as? Date
        project.nextReviewDate = record["nextReviewDate"] as? Date
        
        if let healthString = record["overallHealth"] as? String,
           let health = ProjectHealth(rawValue: healthString) {
            project.overallHealth = health
        }
        
        // Deserialize complex objects
        if let roiData = record["roi"] as? Data,
           let roi = try? JSONDecoder().decode(ROICalculation.self, from: roiData) {
            project.roi = roi
        }
        
        if let costBreakdownData = record["costBreakdown"] as? Data,
           let costBreakdown = try? JSONDecoder().decode([CostCategory].self, from: costBreakdownData) {
            project.costBreakdown = costBreakdown
        }
        
        if let phasesData = record["phases"] as? Data,
           let phases = try? JSONDecoder().decode([ProjectPhase].self, from: phasesData) {
            project.phases = phases
        }
        
        if let dependenciesData = record["dependencies"] as? Data,
           let dependencies = try? JSONDecoder().decode([ProjectDependency].self, from: dependenciesData) {
            project.dependencies = dependencies
        }
        
        if let resourcesData = record["resources"] as? Data,
           let resources = try? JSONDecoder().decode([ResourceAllocation].self, from: resourcesData) {
            project.resources = resources
        }
        
        if let risksData = record["risks"] as? Data,
           let risks = try? JSONDecoder().decode([ProjectRisk].self, from: risksData) {
            project.risks = risks
        }
        
        if let deliverablesData = record["deliverables"] as? Data,
           let deliverables = try? JSONDecoder().decode([Deliverable].self, from: deliverablesData) {
            project.deliverables = deliverables
        }
        
        if let performanceIndicatorsData = record["performanceIndicators"] as? Data,
           let performanceIndicators = try? JSONDecoder().decode([PerformanceIndicator].self, from: performanceIndicatorsData) {
            project.performanceIndicators = performanceIndicators
        }
        
        if let customFieldsData = record["customFields"] as? Data,
           let customFields = try? JSONDecoder().decode([String: String].self, from: customFieldsData) {
            project.customFields = customFields
        }
        
        return project
    }
}
