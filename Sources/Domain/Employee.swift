import Foundation
import CloudKit

// MARK: - Extended Employee Model (Enterprise Directory)
public struct Employee: Identifiable, Codable, Hashable {
    public let id: String
    public var employeeNumber: String
    public var firstName: String
    public var lastName: String
    public var email: String
    public var phone: String?
    public var department: String
    public var title: String
    public var managerId: String?
    public var directReports: [String]
    public var hireDate: Date
    public var birthDate: Date?
    public var address: Address
    public var emergencyContact: EmergencyContact
    public var skills: [String]
    public var certifications: [Certification]
    public var performanceHistory: [PerformanceReview]
    public var salaryGrade: String?
    public var workSchedule: WorkSchedule
    public var userRole: UserRole
    public var storeCodes: [String]
    public var isActive: Bool
    public var profilePhoto: String?
    public var lastLoginAt: Date?
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        employeeNumber: String,
        firstName: String,
        lastName: String,
        email: String,
        phone: String? = nil,
        department: String,
        title: String,
        managerId: String? = nil,
        directReports: [String] = [],
        hireDate: Date,
        birthDate: Date? = nil,
        address: Address,
        emergencyContact: EmergencyContact,
        skills: [String] = [],
        certifications: [Certification] = [],
        performanceHistory: [PerformanceReview] = [],
        salaryGrade: String? = nil,
        workSchedule: WorkSchedule = WorkSchedule(),
        userRole: UserRole,
        storeCodes: [String] = [],
        isActive: Bool = true,
        profilePhoto: String? = nil,
        lastLoginAt: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.employeeNumber = employeeNumber
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.department = department
        self.title = title
        self.managerId = managerId
        self.directReports = directReports
        self.hireDate = hireDate
        self.birthDate = birthDate
        self.address = address
        self.emergencyContact = emergencyContact
        self.skills = skills
        self.certifications = certifications
        self.performanceHistory = performanceHistory
        self.salaryGrade = salaryGrade
        self.workSchedule = workSchedule
        self.userRole = userRole
        self.storeCodes = storeCodes
        self.isActive = isActive
        self.profilePhoto = profilePhoto
        self.lastLoginAt = lastLoginAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    public var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    public var displayName: String {
        return fullName
    }
}

// MARK: - Vendor Model
public struct Vendor: Identifiable, Codable, Hashable {
    public let id: String
    public var companyName: String
    public var contactPerson: String
    public var email: String
    public var phone: String
    public var address: Address
    public var vendorType: VendorType
    public var contractStart: Date
    public var contractEnd: Date
    public var paymentTerms: String
    public var performanceRating: Double
    public var certifications: [String]
    public var serviceCategories: [String]
    public var isPreferred: Bool
    public var riskLevel: RiskLevel
    public var auditHistory: [VendorAudit]
    public var contacts: [VendorContact]
    public var documents: [String] // Document IDs
    public var notes: String?
    public var isActive: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        companyName: String,
        contactPerson: String,
        email: String,
        phone: String,
        address: Address,
        vendorType: VendorType,
        contractStart: Date,
        contractEnd: Date,
        paymentTerms: String,
        performanceRating: Double = 0.0,
        certifications: [String] = [],
        serviceCategories: [String] = [],
        isPreferred: Bool = false,
        riskLevel: RiskLevel = .medium,
        auditHistory: [VendorAudit] = [],
        contacts: [VendorContact] = [],
        documents: [String] = [],
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.companyName = companyName
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.vendorType = vendorType
        self.contractStart = contractStart
        self.contractEnd = contractEnd
        self.paymentTerms = paymentTerms
        self.performanceRating = performanceRating
        self.certifications = certifications
        self.serviceCategories = serviceCategories
        self.isPreferred = isPreferred
        self.riskLevel = riskLevel
        self.auditHistory = auditHistory
        self.contacts = contacts
        self.documents = documents
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Supporting Models

public struct Address: Codable, Hashable {
    public var street: String
    public var city: String
    public var state: String
    public var zipCode: String
    public var country: String
    
    public init(
        street: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = "",
        country: String = "US"
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
    
    public var formatted: String {
        return "\(street), \(city), \(state) \(zipCode)"
    }
}

public struct EmergencyContact: Codable, Hashable {
    public var name: String
    public var relationship: String
    public var phone: String
    public var email: String?
    
    public init(
        name: String = "",
        relationship: String = "",
        phone: String = "",
        email: String? = nil
    ) {
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.email = email
    }
}

public struct Certification: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var issuingOrganization: String
    public var issueDate: Date
    public var expirationDate: Date?
    public var credentialId: String?
    public var verificationUrl: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        issuingOrganization: String,
        issueDate: Date,
        expirationDate: Date? = nil,
        credentialId: String? = nil,
        verificationUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.credentialId = credentialId
        self.verificationUrl = verificationUrl
    }
    
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }
}

public struct PerformanceReview: Identifiable, Codable, Hashable {
    public let id: String
    public var reviewPeriodStart: Date
    public var reviewPeriodEnd: Date
    public var overallRating: Double
    public var goals: [PerformanceGoal]
    public var achievements: [String]
    public var areasForImprovement: [String]
    public var reviewerComments: String?
    public var employeeComments: String?
    public var reviewerId: String
    public var reviewDate: Date
    public var status: ReviewStatus
    
    public init(
        id: String = UUID().uuidString,
        reviewPeriodStart: Date,
        reviewPeriodEnd: Date,
        overallRating: Double = 0.0,
        goals: [PerformanceGoal] = [],
        achievements: [String] = [],
        areasForImprovement: [String] = [],
        reviewerComments: String? = nil,
        employeeComments: String? = nil,
        reviewerId: String,
        reviewDate: Date = Date(),
        status: ReviewStatus = .draft
    ) {
        self.id = id
        self.reviewPeriodStart = reviewPeriodStart
        self.reviewPeriodEnd = reviewPeriodEnd
        self.overallRating = overallRating
        self.goals = goals
        self.achievements = achievements
        self.areasForImprovement = areasForImprovement
        self.reviewerComments = reviewerComments
        self.employeeComments = employeeComments
        self.reviewerId = reviewerId
        self.reviewDate = reviewDate
        self.status = status
    }
}

public struct PerformanceGoal: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var description: String
    public var targetValue: Double?
    public var actualValue: Double?
    public var weight: Double
    public var status: GoalStatus
    public var dueDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        targetValue: Double? = nil,
        actualValue: Double? = nil,
        weight: Double = 1.0,
        status: GoalStatus = .notStarted,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.actualValue = actualValue
        self.weight = weight
        self.status = status
        self.dueDate = dueDate
    }
}

public struct WorkSchedule: Codable, Hashable {
    public var workDays: [WorkDay]
    public var timeZone: String
    public var isFlexible: Bool
    public var overtimeEligible: Bool
    
    public init(
        workDays: [WorkDay] = WorkDay.standardWeek,
        timeZone: String = "America/New_York",
        isFlexible: Bool = false,
        overtimeEligible: Bool = true
    ) {
        self.workDays = workDays
        self.timeZone = timeZone
        self.isFlexible = isFlexible
        self.overtimeEligible = overtimeEligible
    }
}

public struct WorkDay: Codable, Hashable {
    public var dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    public var startTime: String // "09:00"
    public var endTime: String // "17:00"
    public var isWorkDay: Bool
    
    public init(
        dayOfWeek: Int,
        startTime: String = "09:00",
        endTime: String = "17:00",
        isWorkDay: Bool = true
    ) {
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.isWorkDay = isWorkDay
    }
    
    public static var standardWeek: [WorkDay] {
        return [
            WorkDay(dayOfWeek: 1, isWorkDay: false), // Sunday
            WorkDay(dayOfWeek: 2), // Monday
            WorkDay(dayOfWeek: 3), // Tuesday
            WorkDay(dayOfWeek: 4), // Wednesday
            WorkDay(dayOfWeek: 5), // Thursday
            WorkDay(dayOfWeek: 6), // Friday
            WorkDay(dayOfWeek: 7, isWorkDay: false) // Saturday
        ]
    }
}

public struct VendorContact: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var title: String
    public var email: String
    public var phone: String
    public var isPrimary: Bool
    public var department: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        title: String,
        email: String,
        phone: String,
        isPrimary: Bool = false,
        department: String? = nil
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.email = email
        self.phone = phone
        self.isPrimary = isPrimary
        self.department = department
    }
}

public struct VendorAudit: Identifiable, Codable, Hashable {
    public let id: String
    public var auditDate: Date
    public var auditorId: String
    public var auditType: VendorAuditType
    public var score: Double
    public var findings: [String]
    public var recommendations: [String]
    public var followUpRequired: Bool
    public var followUpDate: Date?
    public var status: AuditStatus
    
    public init(
        id: String = UUID().uuidString,
        auditDate: Date = Date(),
        auditorId: String,
        auditType: VendorAuditType,
        score: Double = 0.0,
        findings: [String] = [],
        recommendations: [String] = [],
        followUpRequired: Bool = false,
        followUpDate: Date? = nil,
        status: AuditStatus = .scheduled
    ) {
        self.id = id
        self.auditDate = auditDate
        self.auditorId = auditorId
        self.auditType = auditType
        self.score = score
        self.findings = findings
        self.recommendations = recommendations
        self.followUpRequired = followUpRequired
        self.followUpDate = followUpDate
        self.status = status
    }
}

// MARK: - Enums

public enum VendorType: String, CaseIterable, Codable, Identifiable {
    case supplier = "SUPPLIER"
    case contractor = "CONTRACTOR"
    case consultant = "CONSULTANT"
    case serviceProvider = "SERVICE_PROVIDER"
    case vendor = "VENDOR"
    case partner = "PARTNER"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .supplier: return "Supplier"
        case .contractor: return "Contractor"
        case .consultant: return "Consultant"
        case .serviceProvider: return "Service Provider"
        case .vendor: return "Vendor"
        case .partner: return "Partner"
        }
    }
}

public enum RiskLevel: String, CaseIterable, Codable, Identifiable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

public enum ReviewStatus: String, CaseIterable, Codable, Identifiable {
    case draft = "DRAFT"
    case inProgress = "IN_PROGRESS"
    case pendingApproval = "PENDING_APPROVAL"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .inProgress: return "In Progress"
        case .pendingApproval: return "Pending Approval"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

public enum GoalStatus: String, CaseIterable, Codable, Identifiable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case overdue = "OVERDUE"
    case cancelled = "CANCELLED"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }
}

public enum VendorAuditType: String, CaseIterable, Codable, Identifiable {
    case financial = "FINANCIAL"
    case compliance = "COMPLIANCE"
    case security = "SECURITY"
    case quality = "QUALITY"
    case performance = "PERFORMANCE"
    case operational = "OPERATIONAL"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .financial: return "Financial"
        case .compliance: return "Compliance"
        case .security: return "Security"
        case .quality: return "Quality"
        case .performance: return "Performance"
        case .operational: return "Operational"
        }
    }
}

public enum AuditStatus: String, CaseIterable, Codable, Identifiable {
    case scheduled = "SCHEDULED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case postponed = "POSTPONED"
    case cancelled = "CANCELLED"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .postponed: return "Postponed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - CloudKit Extensions
extension Employee {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Employee", recordID: CKRecord.ID(recordName: id))
        record["employeeNumber"] = employeeNumber
        record["firstName"] = firstName
        record["lastName"] = lastName
        record["email"] = email
        record["phone"] = phone
        record["department"] = department
        record["title"] = title
        record["managerId"] = managerId
        record["directReports"] = directReports
        record["hireDate"] = hireDate
        record["birthDate"] = birthDate
        record["skills"] = skills
        record["salaryGrade"] = salaryGrade
        record["userRole"] = userRole.rawValue
        record["storeCodes"] = storeCodes
        record["isActive"] = isActive
        record["profilePhoto"] = profilePhoto
        record["lastLoginAt"] = lastLoginAt
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        
        // Encode complex objects as Data
        if let addressData = try? JSONEncoder().encode(address) {
            record["address"] = addressData
        }
        if let emergencyContactData = try? JSONEncoder().encode(emergencyContact) {
            record["emergencyContact"] = emergencyContactData
        }
        if let certificationsData = try? JSONEncoder().encode(certifications) {
            record["certifications"] = certificationsData
        }
        if let performanceHistoryData = try? JSONEncoder().encode(performanceHistory) {
            record["performanceHistory"] = performanceHistoryData
        }
        if let workScheduleData = try? JSONEncoder().encode(workSchedule) {
            record["workSchedule"] = workScheduleData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> Employee? {
        guard let employeeNumber = record["employeeNumber"] as? String,
              let firstName = record["firstName"] as? String,
              let lastName = record["lastName"] as? String,
              let email = record["email"] as? String,
              let department = record["department"] as? String,
              let title = record["title"] as? String,
              let hireDate = record["hireDate"] as? Date,
              let roleString = record["userRole"] as? String,
              let userRole = UserRole(rawValue: roleString),
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        let phone = record["phone"] as? String
        let managerId = record["managerId"] as? String
        let directReports = record["directReports"] as? [String] ?? []
        let birthDate = record["birthDate"] as? Date
        let skills = record["skills"] as? [String] ?? []
        let salaryGrade = record["salaryGrade"] as? String
        let storeCodes = record["storeCodes"] as? [String] ?? []
        let profilePhoto = record["profilePhoto"] as? String
        let lastLoginAt = record["lastLoginAt"] as? Date
        
        // Decode complex objects
        var address = Address()
        if let addressData = record["address"] as? Data {
            address = (try? JSONDecoder().decode(Address.self, from: addressData)) ?? Address()
        }
        
        var emergencyContact = EmergencyContact()
        if let emergencyContactData = record["emergencyContact"] as? Data {
            emergencyContact = (try? JSONDecoder().decode(EmergencyContact.self, from: emergencyContactData)) ?? EmergencyContact()
        }
        
        var certifications: [Certification] = []
        if let certificationsData = record["certifications"] as? Data {
            certifications = (try? JSONDecoder().decode([Certification].self, from: certificationsData)) ?? []
        }
        
        var performanceHistory: [PerformanceReview] = []
        if let performanceHistoryData = record["performanceHistory"] as? Data {
            performanceHistory = (try? JSONDecoder().decode([PerformanceReview].self, from: performanceHistoryData)) ?? []
        }
        
        var workSchedule = WorkSchedule()
        if let workScheduleData = record["workSchedule"] as? Data {
            workSchedule = (try? JSONDecoder().decode(WorkSchedule.self, from: workScheduleData)) ?? WorkSchedule()
        }
        
        return Employee(
            id: record.recordID.recordName,
            employeeNumber: employeeNumber,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            department: department,
            title: title,
            managerId: managerId,
            directReports: directReports,
            hireDate: hireDate,
            birthDate: birthDate,
            address: address,
            emergencyContact: emergencyContact,
            skills: skills,
            certifications: certifications,
            performanceHistory: performanceHistory,
            salaryGrade: salaryGrade,
            workSchedule: workSchedule,
            userRole: userRole,
            storeCodes: storeCodes,
            isActive: isActive,
            profilePhoto: profilePhoto,
            lastLoginAt: lastLoginAt,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
