import Foundation
import CloudKit

/// Vendor performance tracking and analytics model
public struct VendorPerformance: Identifiable, Codable {
    public let id: CKRecord.ID
    public let vendorId: String
    public let vendorName: String
    public let storeCode: String
    public let storeName: String?
    public let reportingPeriod: ReportingPeriod
    public let periodStart: Date
    public let periodEnd: Date
    public let status: PerformanceStatus
    public let overallScore: Double
    public let maxScore: Double
    public let percentageScore: Double
    public let grade: PerformanceGrade
    public let metrics: VendorMetrics
    public let kpis: [VendorKPI]
    public let benchmarks: VendorBenchmarks
    public let issues: [VendorIssue]
    public let improvements: [VendorImprovement]
    public let contracts: VendorContractInfo
    public let compliance: VendorCompliance
    public let feedback: [VendorFeedback]
    public let recommendations: [String]
    public let nextReviewDate: Date?
    public let createdBy: CKRecord.Reference
    public let createdByName: String
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
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case semiAnnual = "semi_annual"
        case annual = "annual"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
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
            case .weekly: return 7 * 24 * 3600
            case .monthly: return 30 * 24 * 3600
            case .quarterly: return 90 * 24 * 3600
            case .semiAnnual: return 180 * 24 * 3600
            case .annual: return 365 * 24 * 3600
            case .custom: return 0
            }
        }
    }
    
    public enum PerformanceStatus: String, CaseIterable, Codable {
        case draft = "draft"
        case inProgress = "in_progress"
        case completed = "completed"
        case underReview = "under_review"
        case approved = "approved"
        case published = "published"
        case archived = "archived"
        
        public var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .underReview: return "Under Review"
            case .approved: return "Approved"
            case .published: return "Published"
            case .archived: return "Archived"
            }
        }
    }
    
    public enum PerformanceGrade: String, CaseIterable, Codable {
        case excellent = "excellent"
        case good = "good"
        case satisfactory = "satisfactory"
        case needsImprovement = "needs_improvement"
        case poor = "poor"
        case failing = "failing"
        
        public var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .satisfactory: return "Satisfactory"
            case .needsImprovement: return "Needs Improvement"
            case .poor: return "Poor"
            case .failing: return "Failing"
            }
        }
        
        public var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "lightgreen"
            case .satisfactory: return "yellow"
            case .needsImprovement: return "orange"
            case .poor: return "red"
            case .failing: return "darkred"
            }
        }
        
        public var minPercentage: Double {
            switch self {
            case .excellent: return 95.0
            case .good: return 85.0
            case .satisfactory: return 75.0
            case .needsImprovement: return 65.0
            case .poor: return 50.0
            case .failing: return 0.0
            }
        }
        
        public static func from(percentage: Double) -> PerformanceGrade {
            if percentage >= 95.0 { return .excellent }
            if percentage >= 85.0 { return .good }
            if percentage >= 75.0 { return .satisfactory }
            if percentage >= 65.0 { return .needsImprovement }
            if percentage >= 50.0 { return .poor }
            return .failing
        }
    }
    
    public struct VendorMetrics: Codable {
        public let deliveryPerformance: DeliveryMetrics
        public let qualityMetrics: QualityMetrics
        public let serviceMetrics: ServiceMetrics
        public let financialMetrics: FinancialMetrics
        public let complianceMetrics: ComplianceMetrics
        public let communicationMetrics: CommunicationMetrics
        
        public struct DeliveryMetrics: Codable {
            public let onTimeDeliveryRate: Double // Percentage
            public let totalDeliveries: Int
            public let onTimeDeliveries: Int
            public let lateDeliveries: Int
            public let averageDeliveryTime: TimeInterval
            public let deliveryAccuracy: Double // Percentage
            public let damageRate: Double // Percentage
            public let shortageRate: Double // Percentage
        }
        
        public struct QualityMetrics: Codable {
            public let qualityScore: Double
            public let defectRate: Double // Percentage
            public let returnRate: Double // Percentage
            public let customerSatisfaction: Double
            public let qualityIssues: Int
            public let correctiveActions: Int
            public let certificationStatus: String
        }
        
        public struct ServiceMetrics: Codable {
            public let responsiveness: Double
            public let availability: Double
            public let supportQuality: Double
            public let issueResolutionTime: TimeInterval
            public let serviceUptime: Double // Percentage
            public let escalationRate: Double // Percentage
        }
        
        public struct FinancialMetrics: Codable {
            public let costPerformance: Double
            public let pricingCompetitiveness: Double
            public let paymentTermsAdherence: Double
            public let invoiceAccuracy: Double
            public let totalSpend: Decimal
            public let costSavings: Decimal
            public let budgetVariance: Double // Percentage
        }
        
        public struct ComplianceMetrics: Codable {
            public let regulatoryCompliance: Double
            public let safetyCompliance: Double
            public let environmentalCompliance: Double
            public let documentationCompliance: Double
            public let auditScore: Double
            public let violationCount: Int
            public let correctionTime: TimeInterval
        }
        
        public struct CommunicationMetrics: Codable {
            public let responseTime: TimeInterval
            public let communicationClarity: Double
            public let proactiveness: Double
            public let reportingAccuracy: Double
            public let meetingAttendance: Double
            public let escalationHandling: Double
        }
    }
    
    public struct VendorKPI: Codable, Identifiable {
        public let id: UUID
        public let name: String
        public let category: KPICategory
        public let target: Double
        public let actual: Double
        public let variance: Double
        public let variancePercentage: Double
        public let status: KPIStatus
        public let weight: Double // Importance weight
        public let unit: String
        public let trend: TrendDirection
        public let benchmarkValue: Double?
        public let comments: String?
        
        public enum KPICategory: String, CaseIterable, Codable {
            case delivery = "delivery"
            case quality = "quality"
            case service = "service"
            case financial = "financial"
            case compliance = "compliance"
            case innovation = "innovation"
            case sustainability = "sustainability"
            
            public var displayName: String {
                switch self {
                case .delivery: return "Delivery"
                case .quality: return "Quality"
                case .service: return "Service"
                case .financial: return "Financial"
                case .compliance: return "Compliance"
                case .innovation: return "Innovation"
                case .sustainability: return "Sustainability"
                }
            }
        }
        
        public enum KPIStatus: String, CaseIterable, Codable {
            case exceeds = "exceeds"
            case meets = "meets"
            case below = "below"
            case critical = "critical"
            
            public var displayName: String {
                switch self {
                case .exceeds: return "Exceeds Target"
                case .meets: return "Meets Target"
                case .below: return "Below Target"
                case .critical: return "Critical"
                }
            }
            
            public var color: String {
                switch self {
                case .exceeds: return "green"
                case .meets: return "blue"
                case .below: return "yellow"
                case .critical: return "red"
                }
            }
        }
        
        public enum TrendDirection: String, CaseIterable, Codable {
            case improving = "improving"
            case stable = "stable"
            case declining = "declining"
            case volatile = "volatile"
            
            public var displayName: String {
                switch self {
                case .improving: return "Improving"
                case .stable: return "Stable"
                case .declining: return "Declining"
                case .volatile: return "Volatile"
                }
            }
            
            public var icon: String {
                switch self {
                case .improving: return "↗️"
                case .stable: return "→"
                case .declining: return "↘️"
                case .volatile: return "↕️"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            name: String,
            category: KPICategory,
            target: Double,
            actual: Double,
            weight: Double = 1.0,
            unit: String = "%",
            benchmarkValue: Double? = nil,
            comments: String? = nil
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.target = target
            self.actual = actual
            self.variance = actual - target
            self.variancePercentage = target > 0 ? ((actual - target) / target) * 100 : 0
            self.weight = weight
            self.unit = unit
            self.benchmarkValue = benchmarkValue
            self.comments = comments
            
            // Determine status based on variance
            if variancePercentage >= 10 {
                self.status = .exceeds
            } else if variancePercentage >= -5 {
                self.status = .meets
            } else if variancePercentage >= -15 {
                self.status = .below
            } else {
                self.status = .critical
            }
            
            // Determine trend (simplified)
            if variancePercentage > 5 {
                self.trend = .improving
            } else if variancePercentage < -5 {
                self.trend = .declining
            } else {
                self.trend = .stable
            }
        }
    }
    
    public struct VendorBenchmarks: Codable {
        public let industryAverages: [String: Double]
        public let topPerformers: [String: Double]
        public let companyAverages: [String: Double]
        public let previousPeriod: [String: Double]
        public let yearOverYear: [String: Double]
        public let benchmarkSources: [String]
        public let lastUpdated: Date
    }
    
    public struct VendorIssue: Codable, Identifiable {
        public let id: UUID
        public let type: IssueType
        public let severity: IssueSeverity
        public let title: String
        public let description: String
        public let impact: String
        public let rootCause: String?
        public let status: IssueStatus
        public let reportedBy: CKRecord.Reference
        public let reportedByName: String
        public let reportedAt: Date
        public let assignedTo: CKRecord.Reference?
        public let assignedToName: String?
        public let targetResolution: Date?
        public let actualResolution: Date?
        public let resolutionNotes: String?
        public let preventiveMeasures: [String]
        public let relatedTickets: [CKRecord.Reference]
        
        public enum IssueType: String, CaseIterable, Codable {
            case delivery = "delivery"
            case quality = "quality"
            case service = "service"
            case compliance = "compliance"
            case communication = "communication"
            case financial = "financial"
            case safety = "safety"
            case contract = "contract"
            
            public var displayName: String {
                switch self {
                case .delivery: return "Delivery"
                case .quality: return "Quality"
                case .service: return "Service"
                case .compliance: return "Compliance"
                case .communication: return "Communication"
                case .financial: return "Financial"
                case .safety: return "Safety"
                case .contract: return "Contract"
                }
            }
        }
        
        public enum IssueSeverity: String, CaseIterable, Codable {
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
        }
        
        public enum IssueStatus: String, CaseIterable, Codable {
            case open = "open"
            case inProgress = "in_progress"
            case resolved = "resolved"
            case closed = "closed"
            case escalated = "escalated"
            
            public var displayName: String {
                switch self {
                case .open: return "Open"
                case .inProgress: return "In Progress"
                case .resolved: return "Resolved"
                case .closed: return "Closed"
                case .escalated: return "Escalated"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            type: IssueType,
            severity: IssueSeverity,
            title: String,
            description: String,
            impact: String,
            rootCause: String? = nil,
            status: IssueStatus = .open,
            reportedBy: CKRecord.Reference,
            reportedByName: String,
            reportedAt: Date = Date(),
            assignedTo: CKRecord.Reference? = nil,
            assignedToName: String? = nil,
            targetResolution: Date? = nil,
            actualResolution: Date? = nil,
            resolutionNotes: String? = nil,
            preventiveMeasures: [String] = [],
            relatedTickets: [CKRecord.Reference] = []
        ) {
            self.id = id
            self.type = type
            self.severity = severity
            self.title = title
            self.description = description
            self.impact = impact
            self.rootCause = rootCause
            self.status = status
            self.reportedBy = reportedBy
            self.reportedByName = reportedByName
            self.reportedAt = reportedAt
            self.assignedTo = assignedTo
            self.assignedToName = assignedToName
            self.targetResolution = targetResolution
            self.actualResolution = actualResolution
            self.resolutionNotes = resolutionNotes
            self.preventiveMeasures = preventiveMeasures
            self.relatedTickets = relatedTickets
        }
    }
    
    public struct VendorImprovement: Codable, Identifiable {
        public let id: UUID
        public let area: String
        public let currentState: String
        public let targetState: String
        public let actions: [ImprovementAction]
        public let priority: ImprovementPriority
        public let impact: ImprovementImpact
        public let timeline: ImprovementTimeline
        public let resources: [String]
        public let owner: CKRecord.Reference
        public let ownerName: String
        public let status: ImprovementStatus
        public let progress: Double // 0-100
        public let metrics: [String] // KPIs to track
        public let dependencies: [String]
        public let risks: [String]
        
        public struct ImprovementAction: Codable, Identifiable {
            public let id: UUID
            public let description: String
            public let owner: String
            public let dueDate: Date
            public let status: ActionStatus
            public let completion: Double
            
            public enum ActionStatus: String, CaseIterable, Codable {
                case notStarted = "not_started"
                case inProgress = "in_progress"
                case completed = "completed"
                case onHold = "on_hold"
                case cancelled = "cancelled"
            }
        }
        
        public enum ImprovementPriority: String, CaseIterable, Codable {
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
        }
        
        public enum ImprovementImpact: String, CaseIterable, Codable {
            case minimal = "minimal"
            case moderate = "moderate"
            case significant = "significant"
            case transformational = "transformational"
            
            public var displayName: String {
                switch self {
                case .minimal: return "Minimal"
                case .moderate: return "Moderate"
                case .significant: return "Significant"
                case .transformational: return "Transformational"
                }
            }
        }
        
        public enum ImprovementStatus: String, CaseIterable, Codable {
            case proposed = "proposed"
            case approved = "approved"
            case inProgress = "in_progress"
            case completed = "completed"
            case deferred = "deferred"
            case cancelled = "cancelled"
            
            public var displayName: String {
                switch self {
                case .proposed: return "Proposed"
                case .approved: return "Approved"
                case .inProgress: return "In Progress"
                case .completed: return "Completed"
                case .deferred: return "Deferred"
                case .cancelled: return "Cancelled"
                }
            }
        }
        
        public struct ImprovementTimeline: Codable {
            public let startDate: Date
            public let targetDate: Date
            public let actualDate: Date?
            public let milestones: [Milestone]
            
            public struct Milestone: Codable, Identifiable {
                public let id: UUID
                public let name: String
                public let targetDate: Date
                public let actualDate: Date?
                public let status: MilestoneStatus
                
                public enum MilestoneStatus: String, CaseIterable, Codable {
                    case pending = "pending"
                    case inProgress = "in_progress"
                    case completed = "completed"
                    case delayed = "delayed"
                    case cancelled = "cancelled"
                }
            }
        }
    }
    
    public struct VendorContractInfo: Codable {
        public let contractNumber: String
        public let contractType: ContractType
        public let startDate: Date
        public let endDate: Date
        public let renewalDate: Date?
        public let value: Decimal
        public let currency: String
        public let terms: ContractTerms
        public let slaMetrics: [String: Double]
        public let penalties: [ContractPenalty]
        public let incentives: [ContractIncentive]
        
        public enum ContractType: String, CaseIterable, Codable {
            case services = "services"
            case supply = "supply"
            case maintenance = "maintenance"
            case consulting = "consulting"
            case license = "license"
            case lease = "lease"
            
            public var displayName: String {
                switch self {
                case .services: return "Services"
                case .supply: return "Supply"
                case .maintenance: return "Maintenance"
                case .consulting: return "Consulting"
                case .license: return "License"
                case .lease: return "Lease"
                }
            }
        }
        
        public struct ContractTerms: Codable {
            public let paymentTerms: String
            public let deliveryTerms: String
            public let qualityStandards: String
            public let servicelevels: String
            public let terminationClause: String
            public let disputeResolution: String
        }
        
        public struct ContractPenalty: Codable, Identifiable {
            public let id: UUID
            public let type: String
            public let threshold: Double
            public let amount: Decimal
            public let applied: Bool
            public let appliedDate: Date?
        }
        
        public struct ContractIncentive: Codable, Identifiable {
            public let id: UUID
            public let type: String
            public let threshold: Double
            public let reward: Decimal
            public let earned: Bool
            public let earnedDate: Date?
        }
    }
    
    public struct VendorCompliance: Codable {
        public let certifications: [ComplianceCertification]
        public let audits: [ComplianceAudit]
        public let violations: [ComplianceViolation]
        public let trainingStatus: TrainingStatus
        public let documentStatus: DocumentStatus
        public let overallRating: ComplianceRating
        
        public struct ComplianceCertification: Codable, Identifiable {
            public let id: UUID
            public let name: String
            public let issuedBy: String
            public let issuedDate: Date
            public let expiryDate: Date
            public let status: CertificationStatus
            public let documentUrl: String?
            
            public enum CertificationStatus: String, CaseIterable, Codable {
                case valid = "valid"
                case expiring = "expiring"
                case expired = "expired"
                case suspended = "suspended"
                case revoked = "revoked"
            }
        }
        
        public struct ComplianceAudit: Codable, Identifiable {
            public let id: UUID
            public let type: String
            public let auditDate: Date
            public let auditor: String
            public let score: Double
            public let findings: [String]
            public let correctionsPlan: String?
            public let status: AuditStatus
            
            public enum AuditStatus: String, CaseIterable, Codable {
                case scheduled = "scheduled"
                case inProgress = "in_progress"
                case completed = "completed"
                case followUp = "follow_up"
                case closed = "closed"
            }
        }
        
        public struct ComplianceViolation: Codable, Identifiable {
            public let id: UUID
            public let type: String
            public let severity: ViolationSeverity
            public let description: String
            public let discoveredDate: Date
            public let correctedDate: Date?
            public let penalty: Decimal?
            public let status: ViolationStatus
            
            public enum ViolationSeverity: String, CaseIterable, Codable {
                case minor = "minor"
                case moderate = "moderate"
                case major = "major"
                case critical = "critical"
            }
            
            public enum ViolationStatus: String, CaseIterable, Codable {
                case open = "open"
                case corrected = "corrected"
                case disputed = "disputed"
                case closed = "closed"
            }
        }
        
        public struct TrainingStatus: Codable {
            public let requiredTrainings: [String]
            public let completedTrainings: [String]
            public let upcomingTrainings: [String]
            public let complianceRate: Double
        }
        
        public struct DocumentStatus: Codable {
            public let requiredDocuments: [String]
            public let submittedDocuments: [String]
            public let expiredDocuments: [String]
            public let pendingDocuments: [String]
            public let complianceRate: Double
        }
        
        public enum ComplianceRating: String, CaseIterable, Codable {
            case excellent = "excellent"
            case good = "good"
            case satisfactory = "satisfactory"
            case needsAttention = "needs_attention"
            case nonCompliant = "non_compliant"
            
            public var displayName: String {
                switch self {
                case .excellent: return "Excellent"
                case .good: return "Good"
                case .satisfactory: return "Satisfactory"
                case .needsAttention: return "Needs Attention"
                case .nonCompliant: return "Non-Compliant"
                }
            }
        }
    }
    
    public struct VendorFeedback: Codable, Identifiable {
        public let id: UUID
        public let source: FeedbackSource
        public let type: FeedbackType
        public let rating: Double
        public let comments: String
        public let areas: [FeedbackArea]
        public let submittedBy: CKRecord.Reference
        public let submittedByName: String
        public let submittedAt: Date
        public let response: String?
        public let respondedBy: CKRecord.Reference?
        public let respondedAt: Date?
        public let actionTaken: String?
        
        public enum FeedbackSource: String, CaseIterable, Codable {
            case `internal` = "internal"
            case customer = "customer"
            case management = "management"
            case audit = "audit"
            case survey = "survey"
            
            public var displayName: String {
                switch self {
                case .internal: return "Internal"
                case .customer: return "Customer"
                case .management: return "Management"
                case .audit: return "Audit"
                case .survey: return "Survey"
                }
            }
        }
        
        public enum FeedbackType: String, CaseIterable, Codable {
            case positive = "positive"
            case negative = "negative"
            case suggestion = "suggestion"
            case complaint = "complaint"
            case compliment = "compliment"
            
            public var displayName: String {
                switch self {
                case .positive: return "Positive"
                case .negative: return "Negative"
                case .suggestion: return "Suggestion"
                case .complaint: return "Complaint"
                case .compliment: return "Compliment"
                }
            }
        }
        
        public enum FeedbackArea: String, CaseIterable, Codable {
            case delivery = "delivery"
            case quality = "quality"
            case service = "service"
            case communication = "communication"
            case pricing = "pricing"
            case support = "support"
            case innovation = "innovation"
            
            public var displayName: String {
                switch self {
                case .delivery: return "Delivery"
                case .quality: return "Quality"
                case .service: return "Service"
                case .communication: return "Communication"
                case .pricing: return "Pricing"
                case .support: return "Support"
                case .innovation: return "Innovation"
                }
            }
        }
    }
    
    // Computed properties
    public var isExcellent: Bool {
        return grade == .excellent
    }
    
    public var needsImprovement: Bool {
        return grade == .needsImprovement || grade == .poor || grade == .failing
    }
    
    public var criticalIssues: [VendorIssue] {
        return issues.filter { $0.severity == .critical }
    }
    
    public var openIssues: [VendorIssue] {
        return issues.filter { $0.status == .open || $0.status == .inProgress }
    }
    
    public var kpiByCategory: [VendorKPI.KPICategory: [VendorKPI]] {
        return Dictionary(grouping: kpis) { $0.category }
    }
    
    public var averageKPIPerformance: Double {
        guard !kpis.isEmpty else { return 0 }
        let weightedSum = kpis.reduce(0) { $0 + ($1.actual * $1.weight) }
        let totalWeight = kpis.reduce(0) { $0 + $1.weight }
        return totalWeight > 0 ? weightedSum / totalWeight : 0
    }
    
    public var contractRenewalDaysRemaining: Int? {
        guard let renewalDate = contracts.renewalDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: renewalDate).day
    }
    
    public var isContractExpiringSoon: Bool {
        guard let days = contractRenewalDaysRemaining else { return false }
        return days <= 90 && days >= 0
    }
    
    public var averageFeedbackRating: Double {
        guard !feedback.isEmpty else { return 0 }
        return feedback.reduce(0) { $0 + $1.rating } / Double(feedback.count)
    }
    
    public var compliancePercentage: Double {
        // Calculate from compliance metrics
        return 85.0 // Simplified
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let vendorId = record["vendorId"] as? String,
              let vendorName = record["vendorName"] as? String,
              let storeCode = record["storeCode"] as? String,
              let periodRaw = record["reportingPeriod"] as? String,
              let reportingPeriod = ReportingPeriod(rawValue: periodRaw),
              let periodStart = record["periodStart"] as? Date,
              let periodEnd = record["periodEnd"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = PerformanceStatus(rawValue: statusRaw),
              let overallScore = record["overallScore"] as? Double,
              let maxScore = record["maxScore"] as? Double,
              let percentageScore = record["percentageScore"] as? Double,
              let gradeRaw = record["grade"] as? String,
              let grade = PerformanceGrade(rawValue: gradeRaw),
              let createdBy = record["createdBy"] as? CKRecord.Reference,
              let createdByName = record["createdByName"] as? String,
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.vendorId = vendorId
        self.vendorName = vendorName
        self.storeCode = storeCode
        self.storeName = record["storeName"] as? String
        self.reportingPeriod = reportingPeriod
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.status = status
        self.overallScore = overallScore
        self.maxScore = maxScore
        self.percentageScore = percentageScore
        self.grade = grade
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.reviewedBy = record["reviewedBy"] as? CKRecord.Reference
        self.reviewedByName = record["reviewedByName"] as? String
        self.reviewedAt = record["reviewedAt"] as? Date
        self.approvedBy = record["approvedBy"] as? CKRecord.Reference
        self.approvedByName = record["approvedByName"] as? String
        self.approvedAt = record["approvedAt"] as? Date
        self.nextReviewDate = record["nextReviewDate"] as? Date
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON
        if let metricsData = record["metrics"] as? Data,
           let decodedMetrics = try? JSONDecoder().decode(VendorMetrics.self, from: metricsData) {
            self.metrics = decodedMetrics
        } else {
            // Create default metrics
            self.metrics = VendorMetrics(
                deliveryPerformance: VendorMetrics.DeliveryMetrics(
                    onTimeDeliveryRate: 0, totalDeliveries: 0, onTimeDeliveries: 0,
                    lateDeliveries: 0, averageDeliveryTime: 0, deliveryAccuracy: 0,
                    damageRate: 0, shortageRate: 0
                ),
                qualityMetrics: VendorMetrics.QualityMetrics(
                    qualityScore: 0, defectRate: 0, returnRate: 0, customerSatisfaction: 0,
                    qualityIssues: 0, correctiveActions: 0, certificationStatus: ""
                ),
                serviceMetrics: VendorMetrics.ServiceMetrics(
                    responsiveness: 0, availability: 0, supportQuality: 0,
                    issueResolutionTime: 0, serviceUptime: 0, escalationRate: 0
                ),
                financialMetrics: VendorMetrics.FinancialMetrics(
                    costPerformance: 0, pricingCompetitiveness: 0, paymentTermsAdherence: 0,
                    invoiceAccuracy: 0, totalSpend: 0, costSavings: 0, budgetVariance: 0
                ),
                complianceMetrics: VendorMetrics.ComplianceMetrics(
                    regulatoryCompliance: 0, safetyCompliance: 0, environmentalCompliance: 0,
                    documentationCompliance: 0, auditScore: 0, violationCount: 0, correctionTime: 0
                ),
                communicationMetrics: VendorMetrics.CommunicationMetrics(
                    responseTime: 0, communicationClarity: 0, proactiveness: 0,
                    reportingAccuracy: 0, meetingAttendance: 0, escalationHandling: 0
                )
            )
        }
        
        if let kpisData = record["kpis"] as? Data,
           let decodedKPIs = try? JSONDecoder().decode([VendorKPI].self, from: kpisData) {
            self.kpis = decodedKPIs
        } else {
            self.kpis = []
        }
        
        if let benchmarksData = record["benchmarks"] as? Data,
           let decodedBenchmarks = try? JSONDecoder().decode(VendorBenchmarks.self, from: benchmarksData) {
            self.benchmarks = decodedBenchmarks
        } else {
            self.benchmarks = VendorBenchmarks(
                industryAverages: [:], topPerformers: [:], companyAverages: [:],
                previousPeriod: [:], yearOverYear: [:], benchmarkSources: [],
                lastUpdated: Date()
            )
        }
        
        if let issuesData = record["issues"] as? Data,
           let decodedIssues = try? JSONDecoder().decode([VendorIssue].self, from: issuesData) {
            self.issues = decodedIssues
        } else {
            self.issues = []
        }
        
        if let improvementsData = record["improvements"] as? Data,
           let decodedImprovements = try? JSONDecoder().decode([VendorImprovement].self, from: improvementsData) {
            self.improvements = decodedImprovements
        } else {
            self.improvements = []
        }
        
        if let contractsData = record["contracts"] as? Data,
           let decodedContracts = try? JSONDecoder().decode(VendorContractInfo.self, from: contractsData) {
            self.contracts = decodedContracts
        } else {
            // Create default contract info
            self.contracts = VendorContractInfo(
                contractNumber: "", contractType: .services, startDate: Date(),
                endDate: Date(), renewalDate: nil, value: 0, currency: "USD",
                terms: VendorContractInfo.ContractTerms(
                    paymentTerms: "", deliveryTerms: "", qualityStandards: "",
                    servicelevels: "", terminationClause: "", disputeResolution: ""
                ),
                slaMetrics: [:], penalties: [], incentives: []
            )
        }
        
        if let complianceData = record["compliance"] as? Data,
           let decodedCompliance = try? JSONDecoder().decode(VendorCompliance.self, from: complianceData) {
            self.compliance = decodedCompliance
        } else {
            // Create default compliance
            self.compliance = VendorCompliance(
                certifications: [], audits: [], violations: [],
                trainingStatus: VendorCompliance.TrainingStatus(
                    requiredTrainings: [], completedTrainings: [], upcomingTrainings: [], complianceRate: 0
                ),
                documentStatus: VendorCompliance.DocumentStatus(
                    requiredDocuments: [], submittedDocuments: [], expiredDocuments: [],
                    pendingDocuments: [], complianceRate: 0
                ),
                overallRating: .satisfactory
            )
        }
        
        if let feedbackData = record["feedback"] as? Data,
           let decodedFeedback = try? JSONDecoder().decode([VendorFeedback].self, from: feedbackData) {
            self.feedback = decodedFeedback
        } else {
            self.feedback = []
        }
        
        if let recommendationsData = record["recommendations"] as? Data,
           let decodedRecommendations = try? JSONDecoder().decode([String].self, from: recommendationsData) {
            self.recommendations = decodedRecommendations
        } else {
            self.recommendations = []
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "VendorPerformance", recordID: id)
        
        record["vendorId"] = vendorId
        record["vendorName"] = vendorName
        record["storeCode"] = storeCode
        record["storeName"] = storeName
        record["reportingPeriod"] = reportingPeriod.rawValue
        record["periodStart"] = periodStart
        record["periodEnd"] = periodEnd
        record["status"] = status.rawValue
        record["overallScore"] = overallScore
        record["maxScore"] = maxScore
        record["percentageScore"] = percentageScore
        record["grade"] = grade.rawValue
        record["nextReviewDate"] = nextReviewDate
        record["createdBy"] = createdBy
        record["createdByName"] = createdByName
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
        
        if !kpis.isEmpty,
           let kpisData = try? JSONEncoder().encode(kpis) {
            record["kpis"] = kpisData
        }
        
        if let benchmarksData = try? JSONEncoder().encode(benchmarks) {
            record["benchmarks"] = benchmarksData
        }
        
        if !issues.isEmpty,
           let issuesData = try? JSONEncoder().encode(issues) {
            record["issues"] = issuesData
        }
        
        if !improvements.isEmpty,
           let improvementsData = try? JSONEncoder().encode(improvements) {
            record["improvements"] = improvementsData
        }
        
        if let contractsData = try? JSONEncoder().encode(contracts) {
            record["contracts"] = contractsData
        }
        
        if let complianceData = try? JSONEncoder().encode(compliance) {
            record["compliance"] = complianceData
        }
        
        if !feedback.isEmpty,
           let feedbackData = try? JSONEncoder().encode(feedback) {
            record["feedback"] = feedbackData
        }
        
        if !recommendations.isEmpty,
           let recommendationsData = try? JSONEncoder().encode(recommendations) {
            record["recommendations"] = recommendationsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> VendorPerformance? {
        return VendorPerformance(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        vendorId: String,
        vendorName: String,
        storeCode: String,
        storeName: String? = nil,
        reportingPeriod: ReportingPeriod,
        periodStart: Date,
        periodEnd: Date,
        createdBy: CKRecord.Reference,
        createdByName: String
    ) -> VendorPerformance {
        let now = Date()
        
        return VendorPerformance(
            id: CKRecord.ID(recordName: UUID().uuidString),
            vendorId: vendorId,
            vendorName: vendorName,
            storeCode: storeCode,
            storeName: storeName,
            reportingPeriod: reportingPeriod,
            periodStart: periodStart,
            periodEnd: periodEnd,
            status: .draft,
            overallScore: 0,
            maxScore: 100,
            percentageScore: 0,
            grade: .satisfactory,
            metrics: VendorMetrics(
                deliveryPerformance: VendorMetrics.DeliveryMetrics(
                    onTimeDeliveryRate: 0, totalDeliveries: 0, onTimeDeliveries: 0,
                    lateDeliveries: 0, averageDeliveryTime: 0, deliveryAccuracy: 0,
                    damageRate: 0, shortageRate: 0
                ),
                qualityMetrics: VendorMetrics.QualityMetrics(
                    qualityScore: 0, defectRate: 0, returnRate: 0, customerSatisfaction: 0,
                    qualityIssues: 0, correctiveActions: 0, certificationStatus: ""
                ),
                serviceMetrics: VendorMetrics.ServiceMetrics(
                    responsiveness: 0, availability: 0, supportQuality: 0,
                    issueResolutionTime: 0, serviceUptime: 0, escalationRate: 0
                ),
                financialMetrics: VendorMetrics.FinancialMetrics(
                    costPerformance: 0, pricingCompetitiveness: 0, paymentTermsAdherence: 0,
                    invoiceAccuracy: 0, totalSpend: 0, costSavings: 0, budgetVariance: 0
                ),
                complianceMetrics: VendorMetrics.ComplianceMetrics(
                    regulatoryCompliance: 0, safetyCompliance: 0, environmentalCompliance: 0,
                    documentationCompliance: 0, auditScore: 0, violationCount: 0, correctionTime: 0
                ),
                communicationMetrics: VendorMetrics.CommunicationMetrics(
                    responseTime: 0, communicationClarity: 0, proactiveness: 0,
                    reportingAccuracy: 0, meetingAttendance: 0, escalationHandling: 0
                )
            ),
            kpis: [],
            benchmarks: VendorBenchmarks(
                industryAverages: [:], topPerformers: [:], companyAverages: [:],
                previousPeriod: [:], yearOverYear: [:], benchmarkSources: [],
                lastUpdated: now
            ),
            issues: [],
            improvements: [],
            contracts: VendorContractInfo(
                contractNumber: "", contractType: .services, startDate: Date(),
                endDate: Date(), renewalDate: nil, value: 0, currency: "USD",
                terms: VendorContractInfo.ContractTerms(
                    paymentTerms: "", deliveryTerms: "", qualityStandards: "",
                    servicelevels: "", terminationClause: "", disputeResolution: ""
                ),
                slaMetrics: [:], penalties: [], incentives: []
            ),
            compliance: VendorCompliance(
                certifications: [], audits: [], violations: [],
                trainingStatus: VendorCompliance.TrainingStatus(
                    requiredTrainings: [], completedTrainings: [], upcomingTrainings: [], complianceRate: 0
                ),
                documentStatus: VendorCompliance.DocumentStatus(
                    requiredDocuments: [], submittedDocuments: [], expiredDocuments: [],
                    pendingDocuments: [], complianceRate: 0
                ),
                overallRating: .satisfactory
            ),
            feedback: [],
            recommendations: [],
            nextReviewDate: nil,
            createdBy: createdBy,
            createdByName: createdByName,
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

