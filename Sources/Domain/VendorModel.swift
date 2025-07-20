import Foundation
import CloudKit

/// Enhanced Vendor Model with comprehensive lifecycle management
/// Implements PT3VS1 specifications for vendor relationship management (VRM)
public struct VendorModel: Identifiable, Codable, Hashable {
    public let id: String
    public var vendorNumber: String
    public var companyName: String
    public var contactPerson: String
    public var email: String
    public var phone: String
    public var website: String?
    public var address: Address
    
    // Core Classification
    public var vendorType: VendorType
    public var serviceCategories: [String]
    public var businessSegment: BusinessSegment
    public var industryVertical: String
    
    // Contract Management
    public var contractStart: Date
    public var contractEnd: Date
    public var paymentTerms: String
    public var contractValue: Double?
    public var currency: String
    public var renewalOptions: [RenewalOption]
    public var terminationClause: String?
    public var slaRequirements: [SLARequirement]
    
    // Performance & Rating System
    public var performanceRating: Double
    public var performanceHistory: [VendorPerformanceRecord]
    public var kpiMetrics: [VendorKPI]
    public var benchmarkComparisons: [BenchmarkResult]
    public var scorecardData: VendorScorecard
    
    // Lifecycle Management
    public var lifecycleStage: VendorLifecycleStage
    public var onboardingProgress: OnboardingProgress
    public var relationshipManager: String?
    public var escalationContacts: [EscalationContact]
    public var communicationPreferences: CommunicationPreferences
    
    // Risk & Compliance
    public var riskLevel: RiskLevel
    public var riskFactors: [RiskFactor]
    public var complianceStatus: VendorComplianceStatus
    public var certifications: [String]
    public var auditHistory: [VendorAudit]
    public var insuranceInfo: InsuranceInformation
    public var backgroundCheckStatus: BackgroundCheckStatus
    
    // Financial Management
    public var financialHealth: FinancialHealthMetrics
    public var paymentHistory: [PaymentRecord]
    public var invoiceProcessing: InvoiceProcessingRules
    public var budgetAllocation: BudgetAllocation
    public var costBreakdown: [CostCategory]
    
    // Strategic Management
    public var strategicImportance: StrategicImportance
    public var alternativeVendors: [String] // Vendor IDs
    public var contingencyPlans: [ContingencyPlan]
    public var businessContinuityPlan: BusinessContinuityPlan?
    
    // Preferences & Configuration
    public var isPreferred: Bool
    public var isActive: Bool
    public var isStrategicPartner: Bool
    public var exclusivityAgreements: [ExclusivityAgreement]
    public var preferredVendorBenefits: [VendorBenefit]
    
    // Workflow & Automation
    public var automationRules: [VendorAutomationRule]
    public var workflowStages: [WorkflowStage]
    public var approvalWorkflows: [ApprovalWorkflow]
    
    // Integration & Data
    public var integrationEndpoints: [IntegrationEndpoint]
    public var dataExchangeFormats: [DataFormat]
    public var apiCredentials: APICredentials?
    public var ediConfiguration: EDIConfiguration?
    
    // Metadata
    public var tags: [String]
    public var customFields: [String: String]
    public var notes: String?
    public var attachments: [AttachmentReference]
    public var createdAt: Date
    public var updatedAt: Date
    public var lastReviewDate: Date?
    public var nextReviewDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        vendorNumber: String,
        companyName: String,
        contactPerson: String,
        email: String,
        phone: String,
        website: String? = nil,
        address: Address,
        vendorType: VendorType,
        serviceCategories: [String] = [],
        businessSegment: BusinessSegment = .general,
        industryVertical: String = "General",
        contractStart: Date,
        contractEnd: Date,
        paymentTerms: String,
        contractValue: Double? = nil,
        currency: String = "USD"
    ) {
        self.id = id
        self.vendorNumber = vendorNumber
        self.companyName = companyName
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.website = website
        self.address = address
        self.vendorType = vendorType
        self.serviceCategories = serviceCategories
        self.businessSegment = businessSegment
        self.industryVertical = industryVertical
        self.contractStart = contractStart
        self.contractEnd = contractEnd
        self.paymentTerms = paymentTerms
        self.contractValue = contractValue
        self.currency = currency
        
        // Initialize with default values
        self.renewalOptions = []
        self.terminationClause = nil
        self.slaRequirements = []
        self.performanceRating = 0.0
        self.performanceHistory = []
        self.kpiMetrics = []
        self.benchmarkComparisons = []
        self.scorecardData = VendorScorecard()
        self.lifecycleStage = .prospect
        self.onboardingProgress = OnboardingProgress()
        self.relationshipManager = nil
        self.escalationContacts = []
        self.communicationPreferences = CommunicationPreferences()
        self.riskLevel = .medium
        self.riskFactors = []
        self.complianceStatus = VendorComplianceStatus()
        self.certifications = []
        self.auditHistory = []
        self.insuranceInfo = InsuranceInformation()
        self.backgroundCheckStatus = .pending
        self.financialHealth = FinancialHealthMetrics()
        self.paymentHistory = []
        self.invoiceProcessing = InvoiceProcessingRules()
        self.budgetAllocation = BudgetAllocation()
        self.costBreakdown = []
        self.strategicImportance = .standard
        self.alternativeVendors = []
        self.contingencyPlans = []
        self.businessContinuityPlan = nil
        self.isPreferred = false
        self.isActive = true
        self.isStrategicPartner = false
        self.exclusivityAgreements = []
        self.preferredVendorBenefits = []
        self.automationRules = []
        self.workflowStages = []
        self.approvalWorkflows = []
        self.integrationEndpoints = []
        self.dataExchangeFormats = []
        self.apiCredentials = nil
        self.ediConfiguration = nil
        self.tags = []
        self.customFields = [:]
        self.notes = nil
        self.attachments = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastReviewDate = nil
        self.nextReviewDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
    }
}

// MARK: - Vendor Lifecycle Stages

public enum VendorLifecycleStage: String, Codable, CaseIterable {
    case prospect = "prospect"
    case evaluation = "evaluation"
    case onboarding = "onboarding"
    case active = "active"
    case strategic = "strategic"
    case renewal = "renewal"
    case transition = "transition"
    case terminated = "terminated"
    case suspended = "suspended"
    
    public var displayName: String {
        switch self {
        case .prospect: return "Prospect"
        case .evaluation: return "Under Evaluation"
        case .onboarding: return "Onboarding"
        case .active: return "Active"
        case .strategic: return "Strategic Partner"
        case .renewal: return "Renewal Process"
        case .transition: return "Transition Out"
        case .terminated: return "Terminated"
        case .suspended: return "Suspended"
        }
    }
    
    public var allowedNextStages: [VendorLifecycleStage] {
        switch self {
        case .prospect:
            return [.evaluation, .terminated]
        case .evaluation:
            return [.onboarding, .terminated, .prospect]
        case .onboarding:
            return [.active, .terminated]
        case .active:
            return [.strategic, .renewal, .transition, .suspended]
        case .strategic:
            return [.active, .renewal, .transition]
        case .renewal:
            return [.active, .strategic, .terminated]
        case .transition:
            return [.terminated]
        case .terminated:
            return []
        case .suspended:
            return [.active, .terminated]
        }
    }
}

// MARK: - Performance Management

public struct VendorPerformanceRecord: Identifiable, Codable {
    public let id: String
    public let evaluationDate: Date
    public let evaluator: String
    public let period: EvaluationPeriod
    public let overallScore: Double
    public let categoryScores: [PerformanceCategory: Double]
    public let improvementAreas: [String]
    public let strengths: [String]
    public let actionItems: [ActionItem]
    public let comments: String?
    
    public init(
        id: String = UUID().uuidString,
        evaluationDate: Date = Date(),
        evaluator: String,
        period: EvaluationPeriod,
        overallScore: Double,
        categoryScores: [PerformanceCategory: Double] = [:],
        improvementAreas: [String] = [],
        strengths: [String] = [],
        actionItems: [ActionItem] = [],
        comments: String? = nil
    ) {
        self.id = id
        self.evaluationDate = evaluationDate
        self.evaluator = evaluator
        self.period = period
        self.overallScore = overallScore
        self.categoryScores = categoryScores
        self.improvementAreas = improvementAreas
        self.strengths = strengths
        self.actionItems = actionItems
        self.comments = comments
    }
}

public enum PerformanceCategory: String, Codable, CaseIterable {
    case quality = "quality"
    case delivery = "delivery"
    case cost = "cost"
    case service = "service"
    case innovation = "innovation"
    case compliance = "compliance"
    case responsiveness = "responsiveness"
    case relationship = "relationship"
}

public enum EvaluationPeriod: String, Codable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiAnnual = "semi_annual"
    case annual = "annual"
    case projectBased = "project_based"
}

public struct VendorKPI: Identifiable, Codable {
    public let id: String
    public let name: String
    public let category: PerformanceCategory
    public let target: Double
    public let actual: Double
    public let unit: String
    public let measurementPeriod: EvaluationPeriod
    public let lastUpdated: Date
    public let trend: TrendDirection
    
    public var performancePercentage: Double {
        guard target > 0 else { return 0 }
        return (actual / target) * 100
    }
    
    public var isOnTarget: Bool {
        performancePercentage >= 95.0
    }
}

public enum TrendDirection: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    case unknown = "unknown"
}

public struct VendorScorecard: Codable {
    public var overallScore: Double = 0.0
    public var qualityScore: Double = 0.0
    public var deliveryScore: Double = 0.0
    public var costScore: Double = 0.0
    public var serviceScore: Double = 0.0
    public var complianceScore: Double = 0.0
    public var lastCalculated: Date = Date()
    public var scoringMethod: ScoringMethod = .weighted
    
    public var rating: VendorRating {
        switch overallScore {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .satisfactory
        case 60..<70: return .needsImprovement
        default: return .poor
        }
    }
}

public enum VendorRating: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsImprovement = "needs_improvement"
    case poor = "poor"
}

public enum ScoringMethod: String, Codable {
    case weighted = "weighted"
    case equal = "equal"
    case custom = "custom"
}

// MARK: - Onboarding Management

public struct OnboardingProgress: Codable {
    public var currentStage: OnboardingStage = .initiation
    public var completedStages: [OnboardingStage] = []
    public var stageProgress: [OnboardingStage: Double] = [:]
    public var totalProgress: Double = 0.0
    public var startDate: Date?
    public var expectedCompletionDate: Date?
    public var actualCompletionDate: Date?
    public var assignedOnboardingManager: String?
    public var onboardingTasks: [OnboardingTask] = []
    
    public var isComplete: Bool {
        totalProgress >= 100.0
    }
    
    public var isOverdue: Bool {
        guard let expectedDate = expectedCompletionDate else { return false }
        return Date() > expectedDate && !isComplete
    }
}

public enum OnboardingStage: String, Codable, CaseIterable {
    case initiation = "initiation"
    case documentation = "documentation"
    case compliance = "compliance"
    case systemSetup = "system_setup"
    case training = "training"
    case testing = "testing"
    case goLive = "go_live"
    case postLaunchReview = "post_launch_review"
    
    public var displayName: String {
        switch self {
        case .initiation: return "Initial Setup"
        case .documentation: return "Documentation Review"
        case .compliance: return "Compliance Verification"
        case .systemSetup: return "System Integration"
        case .training: return "Training & Orientation"
        case .testing: return "Testing & Validation"
        case .goLive: return "Go Live"
        case .postLaunchReview: return "Post-Launch Review"
        }
    }
}

public struct OnboardingTask: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let stage: OnboardingStage
    public let assignee: String?
    public let dueDate: Date?
    public let completedDate: Date?
    public let priority: TaskPriority
    public let dependencies: [String] // Task IDs
    public var isCompleted: Bool
    public var notes: String?
    
    public var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }
}

public enum TaskPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Financial Management

public struct FinancialHealthMetrics: Codable {
    public var creditRating: String?
    public var financialStability: FinancialStability = .stable
    public var daysPayableOutstanding: Double = 0
    public var debtToEquityRatio: Double?
    public var currentRatio: Double?
    public var profitMargin: Double?
    public var revenueGrowth: Double?
    public var lastFinancialReview: Date?
    public var financialRiskScore: Double = 0.0
    
    public var healthRating: FinancialHealthRating {
        switch financialRiskScore {
        case 0..<20: return .excellent
        case 20..<40: return .good
        case 40..<60: return .fair
        case 60..<80: return .poor
        default: return .critical
        }
    }
}

public enum FinancialStability: String, Codable {
    case excellent = "excellent"
    case stable = "stable"
    case concerning = "concerning"
    case unstable = "unstable"
    case critical = "critical"
}

public enum FinancialHealthRating: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
}

public struct PaymentRecord: Identifiable, Codable {
    public let id: String
    public let invoiceNumber: String
    public let amount: Double
    public let currency: String
    public let dueDate: Date
    public let paidDate: Date?
    public let paymentMethod: String
    public let status: PaymentStatus
    public let daysPastDue: Int
    public let discountTaken: Double?
    public let lateFees: Double?
    
    public var isOverdue: Bool {
        guard status != .paid else { return false }
        return Date() > dueDate
    }
}

public enum PaymentStatus: String, Codable {
    case pending = "pending"
    case paid = "paid"
    case overdue = "overdue"
    case disputed = "disputed"
    case cancelled = "cancelled"
}

// MARK: - Strategic Management

public enum StrategicImportance: String, Codable {
    case critical = "critical"
    case strategic = "strategic"
    case important = "important"
    case standard = "standard"
    case tactical = "tactical"
    
    public var displayName: String {
        rawValue.capitalized
    }
    
    public var priority: Int {
        switch self {
        case .critical: return 1
        case .strategic: return 2
        case .important: return 3
        case .standard: return 4
        case .tactical: return 5
        }
    }
}

public struct ContingencyPlan: Identifiable, Codable {
    public let id: String
    public let name: String
    public let scenario: String
    public let triggerConditions: [String]
    public let actionSteps: [ActionStep]
    public let alternativeVendors: [String]
    public let estimatedActivationTime: TimeInterval
    public let lastReviewed: Date
    public let owner: String
}

public struct ActionStep: Identifiable, Codable {
    public let id: String
    public let step: Int
    public let description: String
    public let responsible: String
    public let estimatedDuration: TimeInterval
    public let dependencies: [String]
}

// MARK: - Risk Management

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

public struct RiskFactor: Identifiable, Codable {
    public let id: String
    public let category: RiskCategory
    public let description: String
    public let likelihood: RiskLikelihood
    public let impact: RiskImpact
    public let mitigationPlan: String?
    public let owner: String
    public let reviewDate: Date
    
    public var riskScore: Double {
        likelihood.numericValue * impact.numericValue
    }
}

public enum RiskCategory: String, Codable {
    case financial = "financial"
    case operational = "operational"
    case strategic = "strategic"
    case compliance = "compliance"
    case reputation = "reputation"
    case cybersecurity = "cybersecurity"
    case geopolitical = "geopolitical"
}

public enum RiskLikelihood: String, Codable {
    case rare = "rare"
    case unlikely = "unlikely"
    case possible = "possible"
    case likely = "likely"
    case certain = "certain"
    
    public var numericValue: Double {
        switch self {
        case .rare: return 1.0
        case .unlikely: return 2.0
        case .possible: return 3.0
        case .likely: return 4.0
        case .certain: return 5.0
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

// MARK: - Supporting Types

public enum BusinessSegment: String, Codable {
    case general = "general"
    case technology = "technology"
    case professional = "professional"
    case manufacturing = "manufacturing"
    case logistics = "logistics"
    case consulting = "consulting"
    case facilities = "facilities"
    case marketing = "marketing"
}

public enum VendorType: String, Codable {
    case supplier = "supplier"
    case serviceProvider = "service_provider"
    case contractor = "contractor"
    case consultant = "consultant"
    case distributor = "distributor"
    case partner = "partner"
}

public struct RenewalOption: Codable {
    public let duration: TimeInterval
    public let terms: String
    public let priceAdjustment: Double?
    public let notificationRequired: TimeInterval
}

public struct SLARequirement: Identifiable, Codable {
    public let id: String
    public let metric: String
    public let target: Double
    public let unit: String
    public let penalty: String?
}

public struct EscalationContact: Identifiable, Codable {
    public let id: String
    public let name: String
    public let role: String
    public let email: String
    public let phone: String
    public let escalationLevel: Int
}

public struct CommunicationPreferences: Codable {
    public var preferredChannel: CommunicationChannel = .email
    public var frequency: CommunicationFrequency = .asNeeded
    public var languages: [String] = ["en"]
    public var timezone: String = "UTC"
    public var businessHours: BusinessHours = BusinessHours()
}

public enum CommunicationChannel: String, Codable {
    case email = "email"
    case phone = "phone"
    case chat = "chat"
    case portal = "portal"
    case inPerson = "in_person"
}

public enum CommunicationFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case asNeeded = "as_needed"
}

public struct BusinessHours: Codable {
    public var startTime: String = "09:00"
    public var endTime: String = "17:00"
    public var workingDays: [Int] = [1, 2, 3, 4, 5] // Monday to Friday
    public var holidays: [Date] = []
}

// Additional supporting structures would continue here...
// (InsuranceInformation, BackgroundCheckStatus, VendorComplianceStatus, etc.)

// MARK: - CloudKit Extensions

extension VendorModel {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "VendorModel", recordID: CKRecord.ID(recordName: id))
        
        record["vendorNumber"] = vendorNumber
        record["companyName"] = companyName
        record["contactPerson"] = contactPerson
        record["email"] = email
        record["phone"] = phone
        record["website"] = website
        record["vendorType"] = vendorType.rawValue
        record["serviceCategories"] = serviceCategories
        record["businessSegment"] = businessSegment.rawValue
        record["industryVertical"] = industryVertical
        record["contractStart"] = contractStart
        record["contractEnd"] = contractEnd
        record["paymentTerms"] = paymentTerms
        record["contractValue"] = contractValue
        record["currency"] = currency
        record["performanceRating"] = performanceRating
        record["lifecycleStage"] = lifecycleStage.rawValue
        record["riskLevel"] = riskLevel.rawValue
        record["certifications"] = certifications
        record["isPreferred"] = isPreferred ? 1 : 0
        record["isActive"] = isActive ? 1 : 0
        record["isStrategicPartner"] = isStrategicPartner ? 1 : 0
        record["strategicImportance"] = strategicImportance.rawValue
        record["tags"] = tags
        record["notes"] = notes
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["lastReviewDate"] = lastReviewDate
        record["nextReviewDate"] = nextReviewDate
        
        // Serialize complex objects as Data
        if let addressData = try? JSONEncoder().encode(address) {
            record["address"] = addressData
        }
        
        if let performanceData = try? JSONEncoder().encode(performanceHistory) {
            record["performanceHistory"] = performanceData
        }
        
        if let scorecardData = try? JSONEncoder().encode(scorecardData) {
            record["scorecardData"] = scorecardData
        }
        
        if let onboardingData = try? JSONEncoder().encode(onboardingProgress) {
            record["onboardingProgress"] = onboardingData
        }
        
        if let financialData = try? JSONEncoder().encode(financialHealth) {
            record["financialHealth"] = financialData
        }
        
        if let customFieldsData = try? JSONEncoder().encode(customFields) {
            record["customFields"] = customFieldsData
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> VendorModel? {
        guard let vendorNumber = record["vendorNumber"] as? String,
              let companyName = record["companyName"] as? String,
              let contactPerson = record["contactPerson"] as? String,
              let email = record["email"] as? String,
              let phone = record["phone"] as? String,
              let contractStart = record["contractStart"] as? Date,
              let contractEnd = record["contractEnd"] as? Date,
              let paymentTerms = record["paymentTerms"] as? String else {
            return nil
        }
        
        // Decode address
        var address = Address(street: "", city: "", state: "", zipCode: "", country: "")
        if let addressData = record["address"] as? Data,
           let decodedAddress = try? JSONDecoder().decode(Address.self, from: addressData) {
            address = decodedAddress
        }
        
        var vendor = VendorModel(
            id: record.recordID.recordName,
            vendorNumber: vendorNumber,
            companyName: companyName,
            contactPerson: contactPerson,
            email: email,
            phone: phone,
            website: record["website"] as? String,
            address: address,
            vendorType: VendorType(rawValue: record["vendorType"] as? String ?? "supplier") ?? .supplier,
            serviceCategories: record["serviceCategories"] as? [String] ?? [],
            businessSegment: BusinessSegment(rawValue: record["businessSegment"] as? String ?? "general") ?? .general,
            industryVertical: record["industryVertical"] as? String ?? "General",
            contractStart: contractStart,
            contractEnd: contractEnd,
            paymentTerms: paymentTerms,
            contractValue: record["contractValue"] as? Double,
            currency: record["currency"] as? String ?? "USD"
        )
        
        // Restore other properties
        vendor.performanceRating = record["performanceRating"] as? Double ?? 0.0
        vendor.lifecycleStage = VendorLifecycleStage(rawValue: record["lifecycleStage"] as? String ?? "prospect") ?? .prospect
        vendor.riskLevel = RiskLevel(rawValue: record["riskLevel"] as? String ?? "medium") ?? .medium
        vendor.certifications = record["certifications"] as? [String] ?? []
        vendor.isPreferred = (record["isPreferred"] as? Int) == 1
        vendor.isActive = (record["isActive"] as? Int) == 1
        vendor.isStrategicPartner = (record["isStrategicPartner"] as? Int) == 1
        vendor.strategicImportance = StrategicImportance(rawValue: record["strategicImportance"] as? String ?? "standard") ?? .standard
        vendor.tags = record["tags"] as? [String] ?? []
        vendor.notes = record["notes"] as? String
        vendor.createdAt = record["createdAt"] as? Date ?? Date()
        vendor.updatedAt = record["updatedAt"] as? Date ?? Date()
        vendor.lastReviewDate = record["lastReviewDate"] as? Date
        vendor.nextReviewDate = record["nextReviewDate"] as? Date
        
        // Deserialize complex objects
        if let performanceData = record["performanceHistory"] as? Data,
           let performance = try? JSONDecoder().decode([VendorPerformanceRecord].self, from: performanceData) {
            vendor.performanceHistory = performance
        }
        
        if let scorecardData = record["scorecardData"] as? Data,
           let scorecard = try? JSONDecoder().decode(VendorScorecard.self, from: scorecardData) {
            vendor.scorecardData = scorecard
        }
        
        if let onboardingData = record["onboardingProgress"] as? Data,
           let onboarding = try? JSONDecoder().decode(OnboardingProgress.self, from: onboardingData) {
            vendor.onboardingProgress = onboarding
        }
        
        if let financialData = record["financialHealth"] as? Data,
           let financial = try? JSONDecoder().decode(FinancialHealthMetrics.self, from: financialData) {
            vendor.financialHealth = financial
        }
        
        if let customFieldsData = record["customFields"] as? Data,
           let customFields = try? JSONDecoder().decode([String: String].self, from: customFieldsData) {
            vendor.customFields = customFields
        }
        
        return vendor
    }
}
