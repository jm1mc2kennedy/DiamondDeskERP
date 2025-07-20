import Foundation
import CloudKit

// MARK: - Employee Management Models

public struct Employee: Identifiable, Codable, Hashable {
    public let id: String
    public var employeeNumber: String
    public var firstName: String
    public var lastName: String
    public var email: String
    public var phone: String?
    public var department: String
    public var title: String
    public var manager: String?
    public var directReports: [String]
    public var hireDate: Date
    public var birthDate: Date?
    public var address: Address
    public var emergencyContact: EmergencyContact
    public var skills: [String]
    public var certifications: [Certification]
    public var performanceHistory: [PerformanceReview]
    public var isActive: Bool
    public var profilePhoto: String?
    public var workLocation: WorkLocation
    public var employmentType: EmploymentType
    public var securityClearance: SecurityClearance?
    public var lastReviewDate: Date?
    public var nextReviewDate: Date?
    public var salaryGrade: String?
    public var costCenter: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        employeeNumber: String,
        firstName: String,
        lastName: String,
        email: String,
        phone: String? = nil,
        department: String,
        title: String,
        manager: String? = nil,
        directReports: [String] = [],
        hireDate: Date,
        birthDate: Date? = nil,
        address: Address,
        emergencyContact: EmergencyContact,
        skills: [String] = [],
        certifications: [Certification] = [],
        performanceHistory: [PerformanceReview] = [],
        isActive: Bool = true,
        profilePhoto: String? = nil,
        workLocation: WorkLocation,
        employmentType: EmploymentType,
        securityClearance: SecurityClearance? = nil,
        lastReviewDate: Date? = nil,
        nextReviewDate: Date? = nil,
        salaryGrade: String? = nil,
        costCenter: String? = nil
    ) {
        self.id = id
        self.employeeNumber = employeeNumber
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.department = department
        self.title = title
        self.manager = manager
        self.directReports = directReports
        self.hireDate = hireDate
        self.birthDate = birthDate
        self.address = address
        self.emergencyContact = emergencyContact
        self.skills = skills
        self.certifications = certifications
        self.performanceHistory = performanceHistory
        self.isActive = isActive
        self.profilePhoto = profilePhoto
        self.workLocation = workLocation
        self.employmentType = employmentType
        self.securityClearance = securityClearance
        self.lastReviewDate = lastReviewDate
        self.nextReviewDate = nextReviewDate
        self.salaryGrade = salaryGrade
        self.costCenter = costCenter
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    public var isManager: Bool {
        !directReports.isEmpty
    }
    
    public var yearsOfService: Int {
        Calendar.current.dateComponents([.year], from: hireDate, to: Date()).year ?? 0
    }
}

public struct Address: Codable, Hashable {
    public let street: String
    public let city: String
    public let state: String
    public let zipCode: String
    public let country: String
    
    public init(street: String, city: String, state: String, zipCode: String, country: String = "US") {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
    
    public var formattedAddress: String {
        "\(street), \(city), \(state) \(zipCode)"
    }
}

public struct EmergencyContact: Codable, Hashable {
    public let name: String
    public let relationship: String
    public let phone: String
    public let email: String?
    
    public init(name: String, relationship: String, phone: String, email: String? = nil) {
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.email = email
    }
}

public struct Certification: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let issuingOrganization: String
    public let issueDate: Date
    public let expirationDate: Date?
    public let certificateNumber: String?
    public let isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        issuingOrganization: String,
        issueDate: Date,
        expirationDate: Date? = nil,
        certificateNumber: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.certificateNumber = certificateNumber
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

public struct PerformanceReview: Identifiable, Codable, Hashable {
    public let id: String
    public let reviewPeriodStart: Date
    public let reviewPeriodEnd: Date
    public let overallRating: PerformanceRating
    public let goals: [PerformanceGoal]
    public let reviewerComments: String
    public let employeeComments: String?
    public let developmentPlan: [DevelopmentItem]
    public let reviewDate: Date
    public let reviewerId: String
    
    public init(
        id: String = UUID().uuidString,
        reviewPeriodStart: Date,
        reviewPeriodEnd: Date,
        overallRating: PerformanceRating,
        goals: [PerformanceGoal] = [],
        reviewerComments: String,
        employeeComments: String? = nil,
        developmentPlan: [DevelopmentItem] = [],
        reviewDate: Date = Date(),
        reviewerId: String
    ) {
        self.id = id
        self.reviewPeriodStart = reviewPeriodStart
        self.reviewPeriodEnd = reviewPeriodEnd
        self.overallRating = overallRating
        self.goals = goals
        self.reviewerComments = reviewerComments
        self.employeeComments = employeeComments
        self.developmentPlan = developmentPlan
        self.reviewDate = reviewDate
        self.reviewerId = reviewerId
    }
}

public struct PerformanceGoal: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let targetValue: Double?
    public let actualValue: Double?
    public let rating: PerformanceRating
    public let weight: Double
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        targetValue: Double? = nil,
        actualValue: Double? = nil,
        rating: PerformanceRating,
        weight: Double = 1.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.actualValue = actualValue
        self.rating = rating
        self.weight = weight
    }
}

public struct DevelopmentItem: Identifiable, Codable, Hashable {
    public let id: String
    public let skill: String
    public let currentLevel: SkillLevel
    public let targetLevel: SkillLevel
    public let timeline: String
    public let resources: [String]
    
    public init(
        id: String = UUID().uuidString,
        skill: String,
        currentLevel: SkillLevel,
        targetLevel: SkillLevel,
        timeline: String,
        resources: [String] = []
    ) {
        self.id = id
        self.skill = skill
        self.currentLevel = currentLevel
        self.targetLevel = targetLevel
        self.timeline = timeline
        self.resources = resources
    }
}

// MARK: - Enums

public enum WorkLocation: String, CaseIterable, Codable {
    case office = "OFFICE"
    case remote = "REMOTE"
    case hybrid = "HYBRID"
    case field = "FIELD"
    case store = "STORE"
    case warehouse = "WAREHOUSE"
    
    public var displayName: String {
        switch self {
        case .office: return "Office"
        case .remote: return "Remote"
        case .hybrid: return "Hybrid"
        case .field: return "Field"
        case .store: return "Store"
        case .warehouse: return "Warehouse"
        }
    }
}

public enum EmploymentType: String, CaseIterable, Codable {
    case fullTime = "FULL_TIME"
    case partTime = "PART_TIME"
    case contract = "CONTRACT"
    case intern = "INTERN"
    case consultant = "CONSULTANT"
    case temporary = "TEMPORARY"
    
    public var displayName: String {
        switch self {
        case .fullTime: return "Full Time"
        case .partTime: return "Part Time"
        case .contract: return "Contract"
        case .intern: return "Intern"
        case .consultant: return "Consultant"
        case .temporary: return "Temporary"
        }
    }
}

public enum SecurityClearance: String, CaseIterable, Codable {
    case none = "NONE"
    case confidential = "CONFIDENTIAL"
    case secret = "SECRET"
    case topSecret = "TOP_SECRET"
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .confidential: return "Confidential"
        case .secret: return "Secret"
        case .topSecret: return "Top Secret"
        }
    }
}

public enum PerformanceRating: String, CaseIterable, Codable {
    case exceptional = "EXCEPTIONAL"
    case exceeds = "EXCEEDS_EXPECTATIONS"
    case meets = "MEETS_EXPECTATIONS"
    case belowExpectations = "BELOW_EXPECTATIONS"
    case unsatisfactory = "UNSATISFACTORY"
    
    public var displayName: String {
        switch self {
        case .exceptional: return "Exceptional"
        case .exceeds: return "Exceeds Expectations"
        case .meets: return "Meets Expectations"
        case .belowExpectations: return "Below Expectations"
        case .unsatisfactory: return "Unsatisfactory"
        }
    }
    
    public var numericValue: Double {
        switch self {
        case .exceptional: return 5.0
        case .exceeds: return 4.0
        case .meets: return 3.0
        case .belowExpectations: return 2.0
        case .unsatisfactory: return 1.0
        }
    }
}

public enum SkillLevel: String, CaseIterable, Codable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    case expert = "EXPERT"
    
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    public var numericValue: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
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
        record["manager"] = manager
        record["directReports"] = directReports
        record["hireDate"] = hireDate
        record["birthDate"] = birthDate
        record["isActive"] = isActive
        record["profilePhoto"] = profilePhoto
        record["workLocation"] = workLocation.rawValue
        record["employmentType"] = employmentType.rawValue
        record["securityClearance"] = securityClearance?.rawValue
        record["lastReviewDate"] = lastReviewDate
        record["nextReviewDate"] = nextReviewDate
        record["salaryGrade"] = salaryGrade
        record["costCenter"] = costCenter
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex types as JSON
        if let addressData = try? JSONEncoder().encode(address) {
            record["address"] = String(data: addressData, encoding: .utf8)
        }
        if let emergencyContactData = try? JSONEncoder().encode(emergencyContact) {
            record["emergencyContact"] = String(data: emergencyContactData, encoding: .utf8)
        }
        if let skillsData = try? JSONEncoder().encode(skills) {
            record["skills"] = String(data: skillsData, encoding: .utf8)
        }
        if let certificationsData = try? JSONEncoder().encode(certifications) {
            record["certifications"] = String(data: certificationsData, encoding: .utf8)
        }
        if let performanceHistoryData = try? JSONEncoder().encode(performanceHistory) {
            record["performanceHistory"] = String(data: performanceHistoryData, encoding: .utf8)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Employee? {
        guard let employeeNumber = record["employeeNumber"] as? String,
              let firstName = record["firstName"] as? String,
              let lastName = record["lastName"] as? String,
              let email = record["email"] as? String,
              let department = record["department"] as? String,
              let title = record["title"] as? String,
              let hireDate = record["hireDate"] as? Date,
              let workLocationRaw = record["workLocation"] as? String,
              let workLocation = WorkLocation(rawValue: workLocationRaw),
              let employmentTypeRaw = record["employmentType"] as? String,
              let employmentType = EmploymentType(rawValue: employmentTypeRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let phone = record["phone"] as? String
        let manager = record["manager"] as? String
        let directReports = record["directReports"] as? [String] ?? []
        let birthDate = record["birthDate"] as? Date
        let isActive = record["isActive"] as? Bool ?? true
        let profilePhoto = record["profilePhoto"] as? String
        let lastReviewDate = record["lastReviewDate"] as? Date
        let nextReviewDate = record["nextReviewDate"] as? Date
        let salaryGrade = record["salaryGrade"] as? String
        let costCenter = record["costCenter"] as? String
        
        let securityClearance = (record["securityClearance"] as? String).flatMap(SecurityClearance.init(rawValue:))
        
        // Decode complex types from JSON
        let address: Address
        if let addressString = record["address"] as? String,
           let addressData = addressString.data(using: .utf8),
           let decodedAddress = try? JSONDecoder().decode(Address.self, from: addressData) {
            address = decodedAddress
        } else {
            address = Address(street: "", city: "", state: "", zipCode: "")
        }
        
        let emergencyContact: EmergencyContact
        if let emergencyContactString = record["emergencyContact"] as? String,
           let emergencyContactData = emergencyContactString.data(using: .utf8),
           let decodedEmergencyContact = try? JSONDecoder().decode(EmergencyContact.self, from: emergencyContactData) {
            emergencyContact = decodedEmergencyContact
        } else {
            emergencyContact = EmergencyContact(name: "", relationship: "", phone: "")
        }
        
        let skills: [String]
        if let skillsString = record["skills"] as? String,
           let skillsData = skillsString.data(using: .utf8),
           let decodedSkills = try? JSONDecoder().decode([String].self, from: skillsData) {
            skills = decodedSkills
        } else {
            skills = []
        }
        
        let certifications: [Certification]
        if let certificationsString = record["certifications"] as? String,
           let certificationsData = certificationsString.data(using: .utf8),
           let decodedCertifications = try? JSONDecoder().decode([Certification].self, from: certificationsData) {
            certifications = decodedCertifications
        } else {
            certifications = []
        }
        
        let performanceHistory: [PerformanceReview]
        if let performanceHistoryString = record["performanceHistory"] as? String,
           let performanceHistoryData = performanceHistoryString.data(using: .utf8),
           let decodedPerformanceHistory = try? JSONDecoder().decode([PerformanceReview].self, from: performanceHistoryData) {
            performanceHistory = decodedPerformanceHistory
        } else {
            performanceHistory = []
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
            manager: manager,
            directReports: directReports,
            hireDate: hireDate,
            birthDate: birthDate,
            address: address,
            emergencyContact: emergencyContact,
            skills: skills,
            certifications: certifications,
            performanceHistory: performanceHistory,
            isActive: isActive,
            profilePhoto: profilePhoto,
            workLocation: workLocation,
            employmentType: employmentType,
            securityClearance: securityClearance,
            lastReviewDate: lastReviewDate,
            nextReviewDate: nextReviewDate,
            salaryGrade: salaryGrade,
            costCenter: costCenter
        )
    }
}
