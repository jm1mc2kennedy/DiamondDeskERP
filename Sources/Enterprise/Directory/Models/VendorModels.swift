import Foundation
import CloudKit

// MARK: - Vendor Management Models

public struct Vendor: Identifiable, Codable, Hashable {
    public let id: String
    public var vendorNumber: String
    public var companyName: String
    public var contactPerson: String
    public var email: String
    public var phone: String
    public var website: String?
    public var address: Address
    public var vendorType: VendorType
    public var serviceCategories: [ServiceCategory]
    public var contractInfo: ContractInfo
    public var paymentTerms: PaymentTerms
    public var performanceMetrics: PerformanceMetrics
    public var certifications: [VendorCertification]
    public var complianceStatus: ComplianceStatus
    public var riskAssessment: RiskAssessment
    public var auditHistory: [VendorAudit]
    public var isPreferred: Bool
    public var isActive: Bool
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    
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
        serviceCategories: [ServiceCategory] = [],
        contractInfo: ContractInfo,
        paymentTerms: PaymentTerms,
        performanceMetrics: PerformanceMetrics = PerformanceMetrics(),
        certifications: [VendorCertification] = [],
        complianceStatus: ComplianceStatus = ComplianceStatus(),
        riskAssessment: RiskAssessment = RiskAssessment(),
        auditHistory: [VendorAudit] = [],
        isPreferred: Bool = false,
        isActive: Bool = true,
        notes: String? = nil
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
        self.contractInfo = contractInfo
        self.paymentTerms = paymentTerms
        self.performanceMetrics = performanceMetrics
        self.certifications = certifications
        self.complianceStatus = complianceStatus
        self.riskAssessment = riskAssessment
        self.auditHistory = auditHistory
        self.isPreferred = isPreferred
        self.isActive = isActive
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public var overallRating: Double {
        performanceMetrics.overallRating
    }
    
    public var isContractExpiring: Bool {
        guard let endDate = contractInfo.endDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return endDate <= thirtyDaysFromNow && endDate > Date()
    }
    
    public var contractStatus: ContractStatus {
        guard let endDate = contractInfo.endDate else { return .indefinite }
        if endDate < Date() {
            return .expired
        } else if isContractExpiring {
            return .expiring
        } else {
            return .active
        }
    }
}

public struct ContractInfo: Codable, Hashable {
    public let contractNumber: String
    public let startDate: Date
    public let endDate: Date?
    public let renewalTerms: String?
    public let contractValue: Double?
    public let currency: String
    public let terminationClause: String?
    public let slaRequirements: [SLARequirement]
    
    public init(
        contractNumber: String,
        startDate: Date,
        endDate: Date? = nil,
        renewalTerms: String? = nil,
        contractValue: Double? = nil,
        currency: String = "USD",
        terminationClause: String? = nil,
        slaRequirements: [SLARequirement] = []
    ) {
        self.contractNumber = contractNumber
        self.startDate = startDate
        self.endDate = endDate
        self.renewalTerms = renewalTerms
        self.contractValue = contractValue
        self.currency = currency
        self.terminationClause = terminationClause
        self.slaRequirements = slaRequirements
    }
}

public struct PaymentTerms: Codable, Hashable {
    public let terms: PaymentTermType
    public let discountTerms: String?
    public let lateFeePolicy: String?
    public let preferredPaymentMethod: PaymentMethod
    public let taxExempt: Bool
    public let taxId: String?
    
    public init(
        terms: PaymentTermType,
        discountTerms: String? = nil,
        lateFeePolicy: String? = nil,
        preferredPaymentMethod: PaymentMethod,
        taxExempt: Bool = false,
        taxId: String? = nil
    ) {
        self.terms = terms
        self.discountTerms = discountTerms
        self.lateFeePolicy = lateFeePolicy
        self.preferredPaymentMethod = preferredPaymentMethod
        self.taxExempt = taxExempt
        self.taxId = taxId
    }
}

public struct PerformanceMetrics: Codable, Hashable {
    public var onTimeDeliveryRate: Double
    public var qualityScore: Double
    public var responsivenesScore: Double
    public var costEffectivenessScore: Double
    public var totalTransactions: Int
    public var totalSpend: Double
    public var averageResponseTime: TimeInterval
    public var customerSatisfactionScore: Double
    public var defectRate: Double
    public var lastEvaluationDate: Date?
    
    public init(
        onTimeDeliveryRate: Double = 0.0,
        qualityScore: Double = 0.0,
        responsivenesScore: Double = 0.0,
        costEffectivenessScore: Double = 0.0,
        totalTransactions: Int = 0,
        totalSpend: Double = 0.0,
        averageResponseTime: TimeInterval = 0.0,
        customerSatisfactionScore: Double = 0.0,
        defectRate: Double = 0.0,
        lastEvaluationDate: Date? = nil
    ) {
        self.onTimeDeliveryRate = onTimeDeliveryRate
        self.qualityScore = qualityScore
        self.responsivenesScore = responsivenesScore
        self.costEffectivenessScore = costEffectivenessScore
        self.totalTransactions = totalTransactions
        self.totalSpend = totalSpend
        self.averageResponseTime = averageResponseTime
        self.customerSatisfactionScore = customerSatisfactionScore
        self.defectRate = defectRate
        self.lastEvaluationDate = lastEvaluationDate
    }
    
    public var overallRating: Double {
        let scores = [onTimeDeliveryRate, qualityScore, responsivenesScore, costEffectivenessScore, customerSatisfactionScore]
        let validScores = scores.filter { $0 > 0 }
        guard !validScores.isEmpty else { return 0.0 }
        return validScores.reduce(0, +) / Double(validScores.count)
    }
}

public struct VendorCertification: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let issuingBody: String
    public let issueDate: Date
    public let expirationDate: Date?
    public let certificateNumber: String?
    public let documentPath: String?
    public let isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        issuingBody: String,
        issueDate: Date,
        expirationDate: Date? = nil,
        certificateNumber: String? = nil,
        documentPath: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.issuingBody = issuingBody
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.certificateNumber = certificateNumber
        self.documentPath = documentPath
        self.isActive = isActive
    }
    
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }
    
    public var isExpiringSoon: Bool {
        guard let expirationDate = expirationDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expirationDate <= thirtyDaysFromNow && !isExpired
    }
}

public struct ComplianceStatus: Codable, Hashable {
    public var isCompliant: Bool
    public var lastAuditDate: Date?
    public var nextAuditDate: Date?
    public var complianceScore: Double
    public var violations: [ComplianceViolation]
    public var remedationActions: [RemediationAction]
    
    public init(
        isCompliant: Bool = true,
        lastAuditDate: Date? = nil,
        nextAuditDate: Date? = nil,
        complianceScore: Double = 100.0,
        violations: [ComplianceViolation] = [],
        remedationActions: [RemediationAction] = []
    ) {
        self.isCompliant = isCompliant
        self.lastAuditDate = lastAuditDate
        self.nextAuditDate = nextAuditDate
        self.complianceScore = complianceScore
        self.violations = violations
        self.remedationActions = remedationActions
    }
}

public struct RiskAssessment: Codable, Hashable {
    public var overallRiskLevel: RiskLevel
    public var financialRisk: RiskLevel
    public var operationalRisk: RiskLevel
    public var complianceRisk: RiskLevel
    public var reputationalRisk: RiskLevel
    public var lastAssessmentDate: Date?
    public var nextAssessmentDate: Date?
    public var riskMitigationPlans: [RiskMitigationPlan]
    
    public init(
        overallRiskLevel: RiskLevel = .low,
        financialRisk: RiskLevel = .low,
        operationalRisk: RiskLevel = .low,
        complianceRisk: RiskLevel = .low,
        reputationalRisk: RiskLevel = .low,
        lastAssessmentDate: Date? = nil,
        nextAssessmentDate: Date? = nil,
        riskMitigationPlans: [RiskMitigationPlan] = []
    ) {
        self.overallRiskLevel = overallRiskLevel
        self.financialRisk = financialRisk
        self.operationalRisk = operationalRisk
        self.complianceRisk = complianceRisk
        self.reputationalRisk = reputationalRisk
        self.lastAssessmentDate = lastAssessmentDate
        self.nextAssessmentDate = nextAssessmentDate
        self.riskMitigationPlans = riskMitigationPlans
    }
}

public struct VendorAudit: Identifiable, Codable, Hashable {
    public let id: String
    public let auditDate: Date
    public let auditType: AuditType
    public let auditorName: String
    public let findings: [AuditFinding]
    public let overallScore: Double
    public let recommendations: [String]
    public let followUpRequired: Bool
    public let followUpDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        auditDate: Date,
        auditType: AuditType,
        auditorName: String,
        findings: [AuditFinding] = [],
        overallScore: Double,
        recommendations: [String] = [],
        followUpRequired: Bool = false,
        followUpDate: Date? = nil
    ) {
        self.id = id
        self.auditDate = auditDate
        self.auditType = auditType
        self.auditorName = auditorName
        self.findings = findings
        self.overallScore = overallScore
        self.recommendations = recommendations
        self.followUpRequired = followUpRequired
        self.followUpDate = followUpDate
    }
}

public struct SLARequirement: Codable, Hashable {
    public let metric: String
    public let targetValue: Double
    public let unit: String
    public let penalty: String?
    
    public init(metric: String, targetValue: Double, unit: String, penalty: String? = nil) {
        self.metric = metric
        self.targetValue = targetValue
        self.unit = unit
        self.penalty = penalty
    }
}

public struct ComplianceViolation: Identifiable, Codable, Hashable {
    public let id: String
    public let violationType: String
    public let description: String
    public let severity: ViolationSeverity
    public let dateFound: Date
    public let dateResolved: Date?
    public let status: ViolationStatus
    
    public init(
        id: String = UUID().uuidString,
        violationType: String,
        description: String,
        severity: ViolationSeverity,
        dateFound: Date = Date(),
        dateResolved: Date? = nil,
        status: ViolationStatus = .open
    ) {
        self.id = id
        self.violationType = violationType
        self.description = description
        self.severity = severity
        self.dateFound = dateFound
        self.dateResolved = dateResolved
        self.status = status
    }
}

public struct RemediationAction: Identifiable, Codable, Hashable {
    public let id: String
    public let action: String
    public let assignedTo: String
    public let dueDate: Date
    public let status: ActionStatus
    public let completedDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        action: String,
        assignedTo: String,
        dueDate: Date,
        status: ActionStatus = .pending,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.action = action
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.status = status
        self.completedDate = completedDate
    }
}

public struct RiskMitigationPlan: Identifiable, Codable, Hashable {
    public let id: String
    public let riskType: String
    public let mitigationStrategy: String
    public let assignedTo: String
    public let implementationDate: Date
    public let reviewDate: Date
    public let effectiveness: Double?
    
    public init(
        id: String = UUID().uuidString,
        riskType: String,
        mitigationStrategy: String,
        assignedTo: String,
        implementationDate: Date,
        reviewDate: Date,
        effectiveness: Double? = nil
    ) {
        self.id = id
        self.riskType = riskType
        self.mitigationStrategy = mitigationStrategy
        self.assignedTo = assignedTo
        self.implementationDate = implementationDate
        self.reviewDate = reviewDate
        self.effectiveness = effectiveness
    }
}

public struct AuditFinding: Identifiable, Codable, Hashable {
    public let id: String
    public let category: String
    public let description: String
    public let severity: FindingSeverity
    public let recommendation: String
    public let status: FindingStatus
    
    public init(
        id: String = UUID().uuidString,
        category: String,
        description: String,
        severity: FindingSeverity,
        recommendation: String,
        status: FindingStatus = .open
    ) {
        self.id = id
        self.category = category
        self.description = description
        self.severity = severity
        self.recommendation = recommendation
        self.status = status
    }
}

// MARK: - Enums

public enum VendorType: String, CaseIterable, Codable {
    case supplier = "SUPPLIER"
    case contractor = "CONTRACTOR"
    case consultant = "CONSULTANT"
    case service = "SERVICE"
    case technology = "TECHNOLOGY"
    case maintenance = "MAINTENANCE"
    case professional = "PROFESSIONAL"
    
    public var displayName: String {
        switch self {
        case .supplier: return "Supplier"
        case .contractor: return "Contractor"
        case .consultant: return "Consultant"
        case .service: return "Service Provider"
        case .technology: return "Technology"
        case .maintenance: return "Maintenance"
        case .professional: return "Professional Services"
        }
    }
}

public enum ServiceCategory: String, CaseIterable, Codable {
    case manufacturing = "MANUFACTURING"
    case logistics = "LOGISTICS"
    case it = "IT"
    case marketing = "MARKETING"
    case finance = "FINANCE"
    case legal = "LEGAL"
    case hr = "HR"
    case facilities = "FACILITIES"
    case security = "SECURITY"
    case consulting = "CONSULTING"
    
    public var displayName: String {
        switch self {
        case .manufacturing: return "Manufacturing"
        case .logistics: return "Logistics"
        case .it: return "Information Technology"
        case .marketing: return "Marketing"
        case .finance: return "Finance"
        case .legal: return "Legal"
        case .hr: return "Human Resources"
        case .facilities: return "Facilities"
        case .security: return "Security"
        case .consulting: return "Consulting"
        }
    }
}

public enum PaymentTermType: String, CaseIterable, Codable {
    case net15 = "NET_15"
    case net30 = "NET_30"
    case net45 = "NET_45"
    case net60 = "NET_60"
    case net90 = "NET_90"
    case cod = "COD"
    case prepaid = "PREPAID"
    case custom = "CUSTOM"
    
    public var displayName: String {
        switch self {
        case .net15: return "Net 15"
        case .net30: return "Net 30"
        case .net45: return "Net 45"
        case .net60: return "Net 60"
        case .net90: return "Net 90"
        case .cod: return "Cash on Delivery"
        case .prepaid: return "Prepaid"
        case .custom: return "Custom Terms"
        }
    }
}

public enum PaymentMethod: String, CaseIterable, Codable {
    case check = "CHECK"
    case ach = "ACH"
    case wire = "WIRE"
    case card = "CARD"
    case cash = "CASH"
    case other = "OTHER"
    
    public var displayName: String {
        switch self {
        case .check: return "Check"
        case .ach: return "ACH Transfer"
        case .wire: return "Wire Transfer"
        case .card: return "Credit Card"
        case .cash: return "Cash"
        case .other: return "Other"
        }
    }
}

public enum RiskLevel: String, CaseIterable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
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

public enum ContractStatus: String, CaseIterable, Codable {
    case active = "ACTIVE"
    case expiring = "EXPIRING"
    case expired = "EXPIRED"
    case indefinite = "INDEFINITE"
    
    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .expiring: return "Expiring Soon"
        case .expired: return "Expired"
        case .indefinite: return "Indefinite"
        }
    }
}

public enum AuditType: String, CaseIterable, Codable {
    case compliance = "COMPLIANCE"
    case performance = "PERFORMANCE"
    case financial = "FINANCIAL"
    case security = "SECURITY"
    case quality = "QUALITY"
    
    public var displayName: String {
        switch self {
        case .compliance: return "Compliance"
        case .performance: return "Performance"
        case .financial: return "Financial"
        case .security: return "Security"
        case .quality: return "Quality"
        }
    }
}

public enum ViolationSeverity: String, CaseIterable, Codable {
    case minor = "MINOR"
    case major = "MAJOR"
    case critical = "CRITICAL"
    
    public var displayName: String {
        switch self {
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}

public enum ViolationStatus: String, CaseIterable, Codable {
    case open = "OPEN"
    case inProgress = "IN_PROGRESS"
    case resolved = "RESOLVED"
    case waived = "WAIVED"
    
    public var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .waived: return "Waived"
        }
    }
}

public enum ActionStatus: String, CaseIterable, Codable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case overdue = "OVERDUE"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        }
    }
}

public enum FindingSeverity: String, CaseIterable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

public enum FindingStatus: String, CaseIterable, Codable {
    case open = "OPEN"
    case acknowledged = "ACKNOWLEDGED"
    case resolved = "RESOLVED"
    case closed = "CLOSED"
    
    public var displayName: String {
        switch self {
        case .open: return "Open"
        case .acknowledged: return "Acknowledged"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }
}

// MARK: - CloudKit Extensions

extension Vendor {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Vendor", recordID: CKRecord.ID(recordName: id))
        record["vendorNumber"] = vendorNumber
        record["companyName"] = companyName
        record["contactPerson"] = contactPerson
        record["email"] = email
        record["phone"] = phone
        record["website"] = website
        record["vendorType"] = vendorType.rawValue
        record["isPreferred"] = isPreferred
        record["isActive"] = isActive
        record["notes"] = notes
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex types as JSON
        if let addressData = try? JSONEncoder().encode(address) {
            record["address"] = String(data: addressData, encoding: .utf8)
        }
        if let serviceCategoriesData = try? JSONEncoder().encode(serviceCategories) {
            record["serviceCategories"] = String(data: serviceCategoriesData, encoding: .utf8)
        }
        if let contractInfoData = try? JSONEncoder().encode(contractInfo) {
            record["contractInfo"] = String(data: contractInfoData, encoding: .utf8)
        }
        if let paymentTermsData = try? JSONEncoder().encode(paymentTerms) {
            record["paymentTerms"] = String(data: paymentTermsData, encoding: .utf8)
        }
        if let performanceMetricsData = try? JSONEncoder().encode(performanceMetrics) {
            record["performanceMetrics"] = String(data: performanceMetricsData, encoding: .utf8)
        }
        if let certificationsData = try? JSONEncoder().encode(certifications) {
            record["certifications"] = String(data: certificationsData, encoding: .utf8)
        }
        if let complianceStatusData = try? JSONEncoder().encode(complianceStatus) {
            record["complianceStatus"] = String(data: complianceStatusData, encoding: .utf8)
        }
        if let riskAssessmentData = try? JSONEncoder().encode(riskAssessment) {
            record["riskAssessment"] = String(data: riskAssessmentData, encoding: .utf8)
        }
        if let auditHistoryData = try? JSONEncoder().encode(auditHistory) {
            record["auditHistory"] = String(data: auditHistoryData, encoding: .utf8)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Vendor? {
        guard let vendorNumber = record["vendorNumber"] as? String,
              let companyName = record["companyName"] as? String,
              let contactPerson = record["contactPerson"] as? String,
              let email = record["email"] as? String,
              let phone = record["phone"] as? String,
              let vendorTypeRaw = record["vendorType"] as? String,
              let vendorType = VendorType(rawValue: vendorTypeRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let website = record["website"] as? String
        let isPreferred = record["isPreferred"] as? Bool ?? false
        let isActive = record["isActive"] as? Bool ?? true
        let notes = record["notes"] as? String
        
        // Decode complex types from JSON with defaults
        let address: Address
        if let addressString = record["address"] as? String,
           let addressData = addressString.data(using: .utf8),
           let decodedAddress = try? JSONDecoder().decode(Address.self, from: addressData) {
            address = decodedAddress
        } else {
            address = Address(street: "", city: "", state: "", zipCode: "")
        }
        
        let serviceCategories: [ServiceCategory]
        if let serviceCategoriesString = record["serviceCategories"] as? String,
           let serviceCategoriesData = serviceCategoriesString.data(using: .utf8),
           let decodedServiceCategories = try? JSONDecoder().decode([ServiceCategory].self, from: serviceCategoriesData) {
            serviceCategories = decodedServiceCategories
        } else {
            serviceCategories = []
        }
        
        let contractInfo: ContractInfo
        if let contractInfoString = record["contractInfo"] as? String,
           let contractInfoData = contractInfoString.data(using: .utf8),
           let decodedContractInfo = try? JSONDecoder().decode(ContractInfo.self, from: contractInfoData) {
            contractInfo = decodedContractInfo
        } else {
            contractInfo = ContractInfo(contractNumber: "", startDate: Date(), preferredPaymentMethod: .check)
        }
        
        let paymentTerms: PaymentTerms
        if let paymentTermsString = record["paymentTerms"] as? String,
           let paymentTermsData = paymentTermsString.data(using: .utf8),
           let decodedPaymentTerms = try? JSONDecoder().decode(PaymentTerms.self, from: paymentTermsData) {
            paymentTerms = decodedPaymentTerms
        } else {
            paymentTerms = PaymentTerms(terms: .net30, preferredPaymentMethod: .check)
        }
        
        let performanceMetrics: PerformanceMetrics
        if let performanceMetricsString = record["performanceMetrics"] as? String,
           let performanceMetricsData = performanceMetricsString.data(using: .utf8),
           let decodedPerformanceMetrics = try? JSONDecoder().decode(PerformanceMetrics.self, from: performanceMetricsData) {
            performanceMetrics = decodedPerformanceMetrics
        } else {
            performanceMetrics = PerformanceMetrics()
        }
        
        let certifications: [VendorCertification]
        if let certificationsString = record["certifications"] as? String,
           let certificationsData = certificationsString.data(using: .utf8),
           let decodedCertifications = try? JSONDecoder().decode([VendorCertification].self, from: certificationsData) {
            certifications = decodedCertifications
        } else {
            certifications = []
        }
        
        let complianceStatus: ComplianceStatus
        if let complianceStatusString = record["complianceStatus"] as? String,
           let complianceStatusData = complianceStatusString.data(using: .utf8),
           let decodedComplianceStatus = try? JSONDecoder().decode(ComplianceStatus.self, from: complianceStatusData) {
            complianceStatus = decodedComplianceStatus
        } else {
            complianceStatus = ComplianceStatus()
        }
        
        let riskAssessment: RiskAssessment
        if let riskAssessmentString = record["riskAssessment"] as? String,
           let riskAssessmentData = riskAssessmentString.data(using: .utf8),
           let decodedRiskAssessment = try? JSONDecoder().decode(RiskAssessment.self, from: riskAssessmentData) {
            riskAssessment = decodedRiskAssessment
        } else {
            riskAssessment = RiskAssessment()
        }
        
        let auditHistory: [VendorAudit]
        if let auditHistoryString = record["auditHistory"] as? String,
           let auditHistoryData = auditHistoryString.data(using: .utf8),
           let decodedAuditHistory = try? JSONDecoder().decode([VendorAudit].self, from: auditHistoryData) {
            auditHistory = decodedAuditHistory
        } else {
            auditHistory = []
        }
        
        return Vendor(
            id: record.recordID.recordName,
            vendorNumber: vendorNumber,
            companyName: companyName,
            contactPerson: contactPerson,
            email: email,
            phone: phone,
            website: website,
            address: address,
            vendorType: vendorType,
            serviceCategories: serviceCategories,
            contractInfo: contractInfo,
            paymentTerms: paymentTerms,
            performanceMetrics: performanceMetrics,
            certifications: certifications,
            complianceStatus: complianceStatus,
            riskAssessment: riskAssessment,
            auditHistory: auditHistory,
            isPreferred: isPreferred,
            isActive: isActive,
            notes: notes
        )
    }
}
