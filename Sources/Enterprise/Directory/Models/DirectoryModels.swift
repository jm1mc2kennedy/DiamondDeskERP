//
//  DirectoryModels.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import SwiftUI

// MARK: - Employee Directory Models

/// Comprehensive employee profile model for enterprise directory
/// Supports organizational hierarchy, skills tracking, and contact management
struct Employee: Identifiable, Codable, Hashable {
    let id: UUID
    let employeeId: String
    let personalInfo: PersonalInfo
    let contactInfo: ContactInfo
    let organizationalInfo: OrganizationalInfo
    let professionalInfo: ProfessionalInfo
    let systemInfo: SystemInfo
    let permissions: EmployeePermissions
    let preferences: EmployeePreferences
    let analytics: EmployeeAnalytics
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        employeeId: String,
        personalInfo: PersonalInfo,
        contactInfo: ContactInfo,
        organizationalInfo: OrganizationalInfo,
        professionalInfo: ProfessionalInfo,
        systemInfo: SystemInfo,
        permissions: EmployeePermissions,
        preferences: EmployeePreferences = EmployeePreferences(),
        analytics: EmployeeAnalytics = EmployeeAnalytics()
    ) {
        self.id = id
        self.employeeId = employeeId
        self.personalInfo = personalInfo
        self.contactInfo = contactInfo
        self.organizationalInfo = organizationalInfo
        self.professionalInfo = professionalInfo
        self.systemInfo = systemInfo
        self.permissions = permissions
        self.preferences = preferences
        self.analytics = analytics
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Personal information for employee profile
struct PersonalInfo: Codable, Hashable {
    let firstName: String
    let lastName: String
    let middleName: String?
    let preferredName: String?
    let profileImageURL: String?
    let dateOfBirth: Date?
    let personalStatement: String?
    let pronouns: String?
    let languages: [Language]
    
    var fullName: String {
        let components = [firstName, middleName, lastName].compactMap { $0 }
        return components.joined(separator: " ")
    }
    
    var displayName: String {
        return preferredName ?? firstName
    }
}

/// Contact information for employee
struct ContactInfo: Codable, Hashable {
    let workEmail: String
    let personalEmail: String?
    let workPhone: String?
    let mobilePhone: String?
    let emergencyContact: EmergencyContact?
    let workAddress: Address?
    let homeAddress: Address?
    let socialProfiles: [SocialProfile]
}

/// Emergency contact information
struct EmergencyContact: Codable, Hashable {
    let name: String
    let relationship: String
    let phoneNumber: String
    let alternatePhone: String?
    let email: String?
}

/// Address information
struct Address: Codable, Hashable {
    let street1: String
    let street2: String?
    let city: String
    let state: String
    let zipCode: String
    let country: String
    
    var formattedAddress: String {
        let components = [
            [street1, street2].compactMap { $0 }.joined(separator: " "),
            city,
            state,
            zipCode,
            country
        ].filter { !$0.isEmpty }
        
        return components.joined(separator: ", ")
    }
}

/// Social media profile information
struct SocialProfile: Codable, Hashable, Identifiable {
    let id: UUID
    let platform: SocialPlatform
    let username: String
    let profileURL: String
    let isPublic: Bool
    
    init(platform: SocialPlatform, username: String, profileURL: String, isPublic: Bool = false) {
        self.id = UUID()
        self.platform = platform
        self.username = username
        self.profileURL = profileURL
        self.isPublic = isPublic
    }
}

/// Supported social media platforms
enum SocialPlatform: String, CaseIterable, Codable {
    case linkedin = "LinkedIn"
    case twitter = "Twitter"
    case github = "GitHub"
    case slack = "Slack"
    case teams = "Microsoft Teams"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .linkedin: return "briefcase.fill"
        case .twitter: return "bubble.left.and.bubble.right.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .slack: return "message.fill"
        case .teams: return "video.fill"
        case .other: return "link"
        }
    }
    
    var color: Color {
        switch self {
        case .linkedin: return .blue
        case .twitter: return .cyan
        case .github: return .primary
        case .slack: return .purple
        case .teams: return .blue
        case .other: return .gray
        }
    }
}

/// Organizational hierarchy and role information
struct OrganizationalInfo: Codable, Hashable {
    let department: Department
    let jobTitle: String
    let level: EmployeeLevel
    let managerEmployeeId: String?
    let directReports: [String] // Employee IDs
    let costCenter: String?
    let location: WorkLocation
    let employmentType: EmploymentType
    let startDate: Date
    let endDate: Date?
    let probationEndDate: Date?
    let workSchedule: WorkSchedule
}

/// Department information
struct Department: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let code: String
    let description: String?
    let parentDepartmentId: UUID?
    let headEmployeeId: String?
    let budgetCode: String?
    let isActive: Bool
    
    init(name: String, code: String, description: String? = nil, parentDepartmentId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.description = description
        self.parentDepartmentId = parentDepartmentId
        self.headEmployeeId = nil
        self.budgetCode = nil
        self.isActive = true
    }
}

/// Employee hierarchy levels
enum EmployeeLevel: String, CaseIterable, Codable {
    case intern = "Intern"
    case associate = "Associate"
    case senior = "Senior"
    case lead = "Lead"
    case principal = "Principal"
    case manager = "Manager"
    case director = "Director"
    case vp = "Vice President"
    case svp = "Senior Vice President"
    case cLevel = "C-Level"
    case founder = "Founder"
    
    var hierarchy: Int {
        switch self {
        case .intern: return 1
        case .associate: return 2
        case .senior: return 3
        case .lead: return 4
        case .principal: return 5
        case .manager: return 6
        case .director: return 7
        case .vp: return 8
        case .svp: return 9
        case .cLevel: return 10
        case .founder: return 11
        }
    }
    
    var color: Color {
        switch hierarchy {
        case 1...2: return .green
        case 3...4: return .blue
        case 5...6: return .orange
        case 7...8: return .purple
        case 9...11: return .red
        default: return .gray
        }
    }
}

/// Work location information
struct WorkLocation: Codable, Hashable {
    let type: LocationType
    let officeName: String?
    let address: Address?
    let timeZone: String
    let coordinates: LocationCoordinates?
}

/// Location coordinates for mapping
struct LocationCoordinates: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

/// Location types
enum LocationType: String, CaseIterable, Codable {
    case office = "Office"
    case remote = "Remote"
    case hybrid = "Hybrid"
    case fieldWork = "Field Work"
    case client = "Client Site"
    
    var iconName: String {
        switch self {
        case .office: return "building.2.fill"
        case .remote: return "house.fill"
        case .hybrid: return "building.2.crop.circle.fill"
        case .fieldWork: return "location.fill"
        case .client: return "briefcase.fill"
        }
    }
}

/// Employment types
enum EmploymentType: String, CaseIterable, Codable {
    case fullTime = "Full Time"
    case partTime = "Part Time"
    case contract = "Contract"
    case temporary = "Temporary"
    case intern = "Intern"
    case consultant = "Consultant"
    
    var shortCode: String {
        switch self {
        case .fullTime: return "FT"
        case .partTime: return "PT"
        case .contract: return "CT"
        case .temporary: return "TM"
        case .intern: return "IN"
        case .consultant: return "CN"
        }
    }
}

/// Work schedule information
struct WorkSchedule: Codable, Hashable {
    let type: ScheduleType
    let hoursPerWeek: Int
    let workDays: [DayOfWeek]
    let startTime: String? // HH:mm format
    let endTime: String? // HH:mm format
    let flexibleHours: Bool
    let coreHours: TimeRange?
}

/// Schedule types
enum ScheduleType: String, CaseIterable, Codable {
    case standard = "Standard"
    case flexible = "Flexible"
    case compressed = "Compressed"
    case shift = "Shift Work"
    case onCall = "On Call"
    
    var description: String {
        switch self {
        case .standard: return "Monday-Friday, standard business hours"
        case .flexible: return "Flexible start and end times"
        case .compressed: return "Longer days, shorter work week"
        case .shift: return "Rotating or fixed shifts"
        case .onCall: return "On-call availability required"
        }
    }
}

/// Days of the week
enum DayOfWeek: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var shortName: String {
        return String(rawValue.prefix(3))
    }
}

/// Time range for core hours
struct TimeRange: Codable, Hashable {
    let startTime: String // HH:mm format
    let endTime: String // HH:mm format
    
    var formattedRange: String {
        return "\(startTime) - \(endTime)"
    }
}

/// Professional information and skills
struct ProfessionalInfo: Codable, Hashable {
    let skills: [Skill]
    let certifications: [Certification]
    let education: [Education]
    let workExperience: [WorkExperience]
    let projects: [String] // Project IDs
    let performanceReviews: [String] // Review IDs
    let goals: [ProfessionalGoal]
    let mentoring: MentoringInfo
}

/// Skill information with proficiency levels
struct Skill: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let category: SkillCategory
    let proficiency: ProficiencyLevel
    let yearsOfExperience: Int?
    let lastUsed: Date?
    let certifications: [String] // Certification IDs
    let endorsements: Int
    let isCore: Bool // Core skill for current role
    
    init(name: String, category: SkillCategory, proficiency: ProficiencyLevel, yearsOfExperience: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.proficiency = proficiency
        self.yearsOfExperience = yearsOfExperience
        self.lastUsed = nil
        self.certifications = []
        self.endorsements = 0
        self.isCore = false
    }
}

/// Skill categories
enum SkillCategory: String, CaseIterable, Codable {
    case technical = "Technical"
    case software = "Software"
    case leadership = "Leadership"
    case communication = "Communication"
    case analytical = "Analytical"
    case creative = "Creative"
    case projectManagement = "Project Management"
    case sales = "Sales"
    case marketing = "Marketing"
    case finance = "Finance"
    case operations = "Operations"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .technical: return "gearshape.fill"
        case .software: return "laptopcomputer"
        case .leadership: return "person.3.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .analytical: return "chart.bar.fill"
        case .creative: return "paintbrush.fill"
        case .projectManagement: return "list.bullet.clipboard.fill"
        case .sales: return "chart.line.uptrend.xyaxis"
        case .marketing: return "megaphone.fill"
        case .finance: return "dollarsign.circle.fill"
        case .operations: return "gear.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .technical: return .blue
        case .software: return .purple
        case .leadership: return .red
        case .communication: return .orange
        case .analytical: return .green
        case .creative: return .pink
        case .projectManagement: return .teal
        case .sales: return .yellow
        case .marketing: return .cyan
        case .finance: return .mint
        case .operations: return .brown
        case .other: return .gray
        }
    }
}

/// Proficiency levels for skills
enum ProficiencyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    case master = "Master"
    
    var score: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        case .master: return 5
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .red
        case .intermediate: return .orange
        case .advanced: return .yellow
        case .expert: return .green
        case .master: return .blue
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Basic understanding, requires guidance"
        case .intermediate: return "Good working knowledge, some independence"
        case .advanced: return "Strong expertise, works independently"
        case .expert: return "Deep knowledge, mentors others"
        case .master: return "Industry recognized expertise, thought leader"
        }
    }
}

/// Professional certification
struct Certification: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let issuer: String
    let issueDate: Date
    let expirationDate: Date?
    let credentialId: String?
    let verificationURL: String?
    let skills: [String] // Related skill names
    let isActive: Bool
    
    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }
    
    var expiresWithin90Days: Bool {
        guard let expiration = expirationDate else { return false }
        let ninetyDaysFromNow = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        return expiration <= ninetyDaysFromNow && expiration >= Date()
    }
    
    init(name: String, issuer: String, issueDate: Date, expirationDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.issuer = issuer
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.credentialId = nil
        self.verificationURL = nil
        self.skills = []
        self.isActive = true
    }
}

/// Education information
struct Education: Codable, Hashable, Identifiable {
    let id: UUID
    let institution: String
    let degree: String
    let fieldOfStudy: String
    let startDate: Date
    let endDate: Date?
    let gpa: Double?
    let honors: String?
    let activities: [String]
    let relevantCoursework: [String]
    
    var isCompleted: Bool {
        guard let end = endDate else { return false }
        return end <= Date()
    }
    
    init(institution: String, degree: String, fieldOfStudy: String, startDate: Date, endDate: Date? = nil) {
        self.id = UUID()
        self.institution = institution
        self.degree = degree
        self.fieldOfStudy = fieldOfStudy
        self.startDate = startDate
        self.endDate = endDate
        self.gpa = nil
        self.honors = nil
        self.activities = []
        self.relevantCoursework = []
    }
}

/// Work experience information
struct WorkExperience: Codable, Hashable, Identifiable {
    let id: UUID
    let company: String
    let jobTitle: String
    let department: String?
    let startDate: Date
    let endDate: Date?
    let description: String
    let achievements: [String]
    let skills: [String] // Skill names used in this role
    let supervisor: String?
    let isCurrentPosition: Bool
    
    var duration: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let start = formatter.string(from: startDate)
        if let end = endDate {
            let endStr = formatter.string(from: end)
            return "\(start) - \(endStr)"
        } else {
            return "\(start) - Present"
        }
    }
    
    init(company: String, jobTitle: String, startDate: Date, endDate: Date? = nil, description: String) {
        self.id = UUID()
        self.company = company
        self.jobTitle = jobTitle
        self.department = nil
        self.startDate = startDate
        self.endDate = endDate
        self.description = description
        self.achievements = []
        self.skills = []
        self.supervisor = nil
        self.isCurrentPosition = endDate == nil
    }
}

/// Professional goals and career development
struct ProfessionalGoal: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: GoalCategory
    let targetDate: Date
    let priority: GoalPriority
    let progress: Double // 0.0 to 1.0
    let milestones: [GoalMilestone]
    let skills: [String] // Skills to develop
    let status: GoalStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(title: String, description: String, category: GoalCategory, targetDate: Date, priority: GoalPriority) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.targetDate = targetDate
        self.priority = priority
        self.progress = 0.0
        self.milestones = []
        self.skills = []
        self.status = .notStarted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Goal categories
enum GoalCategory: String, CaseIterable, Codable {
    case skillDevelopment = "Skill Development"
    case careerAdvancement = "Career Advancement"
    case leadership = "Leadership"
    case education = "Education"
    case certification = "Certification"
    case networking = "Networking"
    case performance = "Performance"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .skillDevelopment: return "brain.head.profile"
        case .careerAdvancement: return "arrow.up.right.circle.fill"
        case .leadership: return "person.3.fill"
        case .education: return "graduationcap.fill"
        case .certification: return "rosette"
        case .networking: return "person.2.wave.2.fill"
        case .performance: return "chart.line.uptrend.xyaxis"
        case .other: return "target"
        }
    }
}

/// Goal priorities
enum GoalPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

/// Goal status
enum GoalStatus: String, CaseIterable, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .onHold: return .orange
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

/// Goal milestone
struct GoalMilestone: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let targetDate: Date
    let completedDate: Date?
    let isCompleted: Bool
    
    init(title: String, description: String? = nil, targetDate: Date) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.completedDate = nil
        self.isCompleted = false
    }
}

/// Mentoring information
struct MentoringInfo: Codable, Hashable {
    let isActiveMentor: Bool
    let isActiveMentee: Bool
    let mentors: [String] // Employee IDs
    let mentees: [String] // Employee IDs
    let mentoringAreas: [MentoringArea]
    let availability: MentoringAvailability
    let experience: MentoringExperience
}

/// Mentoring areas of expertise
enum MentoringArea: String, CaseIterable, Codable {
    case careerDevelopment = "Career Development"
    case technicalSkills = "Technical Skills"
    case leadership = "Leadership"
    case communication = "Communication"
    case projectManagement = "Project Management"
    case workLifeBalance = "Work-Life Balance"
    case diversity = "Diversity & Inclusion"
    case entrepreneurship = "Entrepreneurship"
    
    var iconName: String {
        switch self {
        case .careerDevelopment: return "arrow.up.right.circle"
        case .technicalSkills: return "gearshape"
        case .leadership: return "person.3"
        case .communication: return "bubble.left.and.bubble.right"
        case .projectManagement: return "list.bullet.clipboard"
        case .workLifeBalance: return "scale.3d"
        case .diversity: return "person.2.badge.gearshape"
        case .entrepreneurship: return "lightbulb"
        }
    }
}

/// Mentoring availability
struct MentoringAvailability: Codable, Hashable {
    let hoursPerMonth: Int
    let preferredMeetingType: MeetingType
    let timeZones: [String]
    let languages: [Language]
}

/// Meeting types for mentoring
enum MeetingType: String, CaseIterable, Codable {
    case inPerson = "In Person"
    case video = "Video Call"
    case phone = "Phone Call"
    case messaging = "Messaging"
    case email = "Email"
    case flexible = "Flexible"
}

/// Mentoring experience level
enum MentoringExperience: String, CaseIterable, Codable {
    case none = "No Experience"
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case experienced = "Experienced"
    case expert = "Expert"
    
    var description: String {
        switch self {
        case .none: return "New to mentoring"
        case .beginner: return "1-2 mentoring relationships"
        case .intermediate: return "3-5 mentoring relationships"
        case .experienced: return "6-10 mentoring relationships"
        case .expert: return "10+ mentoring relationships"
        }
    }
}

/// Language proficiency
struct Language: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let code: String // ISO 639-1 code
    let proficiency: LanguageProficiency
    let isNative: Bool
    
    init(name: String, code: String, proficiency: LanguageProficiency, isNative: Bool = false) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.proficiency = proficiency
        self.isNative = isNative
    }
}

/// Language proficiency levels
enum LanguageProficiency: String, CaseIterable, Codable {
    case elementary = "Elementary"
    case conversational = "Conversational"
    case professional = "Professional"
    case fluent = "Fluent"
    case native = "Native"
    
    var description: String {
        switch self {
        case .elementary: return "Basic words and phrases"
        case .conversational: return "Can hold basic conversations"
        case .professional: return "Professional working proficiency"
        case .fluent: return "Full professional fluency"
        case .native: return "Native or bilingual proficiency"
        }
    }
}

/// System information for employee
struct SystemInfo: Codable, Hashable {
    let cloudKitRecordId: String?
    let lastLoginDate: Date?
    let accountStatus: AccountStatus
    let accessLevel: AccessLevel
    let deviceInfo: [DeviceInfo]
    let loginHistory: [LoginEvent]
    let securitySettings: SecuritySettings
    let notificationSettings: NotificationSettings
}

/// Account status
enum AccountStatus: String, CaseIterable, Codable {
    case active = "Active"
    case inactive = "Inactive"
    case suspended = "Suspended"
    case terminated = "Terminated"
    case onLeave = "On Leave"
    
    var color: Color {
        switch self {
        case .active: return .green
        case .inactive: return .gray
        case .suspended: return .orange
        case .terminated: return .red
        case .onLeave: return .blue
        }
    }
}

/// Access levels for system permissions
enum AccessLevel: String, CaseIterable, Codable {
    case read = "Read Only"
    case write = "Read/Write"
    case admin = "Administrator"
    case superAdmin = "Super Administrator"
    
    var hierarchy: Int {
        switch self {
        case .read: return 1
        case .write: return 2
        case .admin: return 3
        case .superAdmin: return 4
        }
    }
}

/// Device information for security tracking
struct DeviceInfo: Codable, Hashable, Identifiable {
    let id: UUID
    let deviceName: String
    let deviceType: DeviceType
    let osVersion: String
    let appVersion: String
    let lastUsed: Date
    let isRegistered: Bool
    let isTrusted: Bool
    
    init(deviceName: String, deviceType: DeviceType, osVersion: String, appVersion: String) {
        self.id = UUID()
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.lastUsed = Date()
        self.isRegistered = false
        self.isTrusted = false
    }
}

/// Device types
enum DeviceType: String, CaseIterable, Codable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "Mac"
    case appleWatch = "Apple Watch"
    case web = "Web Browser"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .mac: return "laptopcomputer"
        case .appleWatch: return "applewatch"
        case .web: return "globe"
        case .other: return "questionmark.circle"
        }
    }
}

/// Login event for audit trail
struct LoginEvent: Codable, Hashable, Identifiable {
    let id: UUID
    let timestamp: Date
    let deviceId: UUID
    let ipAddress: String?
    let location: String?
    let success: Bool
    let failureReason: String?
    
    init(deviceId: UUID, ipAddress: String? = nil, location: String? = nil, success: Bool) {
        self.id = UUID()
        self.timestamp = Date()
        self.deviceId = deviceId
        self.ipAddress = ipAddress
        self.location = location
        self.success = success
        self.failureReason = success ? nil : "Authentication failed"
    }
}

/// Security settings for employee account
struct SecuritySettings: Codable, Hashable {
    let twoFactorEnabled: Bool
    let biometricEnabled: Bool
    let sessionTimeout: Int // Minutes
    let passwordLastChanged: Date?
    let securityQuestions: [SecurityQuestion]
    let trustedDevices: [UUID] // Device IDs
    let allowedIPRanges: [String]
}

/// Security question for account recovery
struct SecurityQuestion: Codable, Hashable, Identifiable {
    let id: UUID
    let question: String
    let answerHash: String // Hashed answer for security
    let createdAt: Date
    
    init(question: String, answerHash: String) {
        self.id = UUID()
        self.question = question
        self.answerHash = answerHash
        self.createdAt = Date()
    }
}

/// Notification settings for employee
struct NotificationSettings: Codable, Hashable {
    let emailNotifications: Bool
    let pushNotifications: Bool
    let smsNotifications: Bool
    let digestFrequency: DigestFrequency
    let notificationTypes: [NotificationType: Bool]
    let quietHours: QuietHours?
}

/// Notification digest frequency
enum DigestFrequency: String, CaseIterable, Codable {
    case immediate = "Immediate"
    case hourly = "Hourly"
    case daily = "Daily"
    case weekly = "Weekly"
    case never = "Never"
}

/// Types of notifications
enum NotificationType: String, CaseIterable, Codable {
    case taskAssigned = "Task Assigned"
    case taskDue = "Task Due"
    case meetingReminder = "Meeting Reminder"
    case performanceReview = "Performance Review"
    case goalUpdate = "Goal Update"
    case skillEndorsement = "Skill Endorsement"
    case mentorshipRequest = "Mentorship Request"
    case directoryUpdate = "Directory Update"
}

/// Quiet hours for notifications
struct QuietHours: Codable, Hashable {
    let startTime: String // HH:mm format
    let endTime: String // HH:mm format
    let timeZone: String
    let daysOfWeek: [DayOfWeek]
}

/// Employee permissions for various system features
struct EmployeePermissions: Codable, Hashable {
    let canViewDirectory: Bool
    let canEditOwnProfile: Bool
    let canViewOrgChart: Bool
    let canMentor: Bool
    let canRequestMentoring: Bool
    let canEndorseSkills: Bool
    let canViewPerformanceData: Bool
    let canManageTeam: Bool
    let canAccessAnalytics: Bool
    let customPermissions: [String: Bool]
    
    init() {
        self.canViewDirectory = true
        self.canEditOwnProfile = true
        self.canViewOrgChart = true
        self.canMentor = false
        self.canRequestMentoring = true
        self.canEndorseSkills = true
        self.canViewPerformanceData = false
        self.canManageTeam = false
        self.canAccessAnalytics = false
        self.customPermissions = [:]
    }
}

/// Employee preferences for personalization
struct EmployeePreferences: Codable, Hashable {
    let theme: AppTheme
    let language: String
    let timeZone: String
    let dateFormat: DateFormatStyle
    let timeFormat: TimeFormatStyle
    let privacySettings: PrivacySettings
    let displaySettings: DisplaySettings
    
    init() {
        self.theme = .system
        self.language = "en"
        self.timeZone = TimeZone.current.identifier
        self.dateFormat = .medium
        self.timeFormat = .twelve
        self.privacySettings = PrivacySettings()
        self.displaySettings = DisplaySettings()
    }
}

/// App theme preferences
enum AppTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

/// Date format styles
enum DateFormatStyle: String, CaseIterable, Codable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    case full = "Full"
}

/// Time format styles
enum TimeFormatStyle: String, CaseIterable, Codable {
    case twelve = "12 Hour"
    case twentyFour = "24 Hour"
}

/// Privacy settings for employee profile
struct PrivacySettings: Codable, Hashable {
    let showPersonalInfo: VisibilityLevel
    let showContactInfo: VisibilityLevel
    let showSkills: VisibilityLevel
    let showEducation: VisibilityLevel
    let showWorkHistory: VisibilityLevel
    let showLocation: VisibilityLevel
    let allowMentoringRequests: Bool
    let allowSkillEndorsements: Bool
    let showInDirectory: Bool
    
    init() {
        self.showPersonalInfo = .team
        self.showContactInfo = .team
        self.showSkills = .organization
        self.showEducation = .organization
        self.showWorkHistory = .organization
        self.showLocation = .team
        self.allowMentoringRequests = true
        self.allowSkillEndorsements = true
        self.showInDirectory = true
    }
}

/// Visibility levels for privacy control
enum VisibilityLevel: String, CaseIterable, Codable {
    case hidden = "Hidden"
    case me = "Only Me"
    case manager = "Manager Only"
    case team = "Team"
    case department = "Department"
    case organization = "Organization"
    case public = "Public"
    
    var description: String {
        switch self {
        case .hidden: return "Not visible to anyone"
        case .me: return "Only visible to you"
        case .manager: return "Only visible to your manager"
        case .team: return "Visible to your immediate team"
        case .department: return "Visible to your department"
        case .organization: return "Visible to entire organization"
        case .public: return "Publicly visible"
        }
    }
}

/// Display settings for UI customization
struct DisplaySettings: Codable, Hashable {
    let showProfileImage: Bool
    let showJobTitle: Bool
    let showDepartment: Bool
    let showSkills: Bool
    let showLocation: Bool
    let showWorkSchedule: Bool
    let compactView: Bool
    
    init() {
        self.showProfileImage = true
        self.showJobTitle = true
        self.showDepartment = true
        self.showSkills = true
        self.showLocation = true
        self.showWorkSchedule = false
        self.compactView = false
    }
}

/// Analytics for employee engagement and performance
struct EmployeeAnalytics: Codable, Hashable {
    let profileViews: Int
    let skillEndorsements: Int
    let mentoringRequests: Int
    let goalCompletionRate: Double
    let lastActiveDate: Date?
    let engagementScore: Double
    let networkSize: Int // Number of connections
    let contributionScore: Double
    
    init() {
        self.profileViews = 0
        self.skillEndorsements = 0
        self.mentoringRequests = 0
        self.goalCompletionRate = 0.0
        self.lastActiveDate = nil
        self.engagementScore = 0.0
        self.networkSize = 0
        self.contributionScore = 0.0
    }
}

// MARK: - CloudKit Integration

extension Employee {
    /// Convert Employee to CloudKit record
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "Employee", recordID: CKRecord.ID(recordName: id.uuidString))
        
        // Basic identification
        record["employeeId"] = employeeId
        record["firstName"] = personalInfo.firstName
        record["lastName"] = personalInfo.lastName
        record["workEmail"] = contactInfo.workEmail
        record["jobTitle"] = organizationalInfo.jobTitle
        record["department"] = organizationalInfo.department.name
        record["level"] = organizationalInfo.level.rawValue
        record["accountStatus"] = systemInfo.accountStatus.rawValue
        
        // Serialize complex data as JSON
        if let personalInfoData = try? JSONEncoder().encode(personalInfo) {
            record["personalInfoData"] = personalInfoData
        }
        
        if let contactInfoData = try? JSONEncoder().encode(contactInfo) {
            record["contactInfoData"] = contactInfoData
        }
        
        if let organizationalInfoData = try? JSONEncoder().encode(organizationalInfo) {
            record["organizationalInfoData"] = organizationalInfoData
        }
        
        if let professionalInfoData = try? JSONEncoder().encode(professionalInfo) {
            record["professionalInfoData"] = professionalInfoData
        }
        
        if let systemInfoData = try? JSONEncoder().encode(systemInfo) {
            record["systemInfoData"] = systemInfoData
        }
        
        if let permissionsData = try? JSONEncoder().encode(permissions) {
            record["permissionsData"] = permissionsData
        }
        
        if let preferencesData = try? JSONEncoder().encode(preferences) {
            record["preferencesData"] = preferencesData
        }
        
        if let analyticsData = try? JSONEncoder().encode(analytics) {
            record["analyticsData"] = analyticsData
        }
        
        // Timestamps
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
    
    /// Create Employee from CloudKit record
    static func fromCloudKitRecord(_ record: CKRecord) -> Employee? {
        guard let employeeId = record["employeeId"] as? String,
              let personalInfoData = record["personalInfoData"] as? Data,
              let contactInfoData = record["contactInfoData"] as? Data,
              let organizationalInfoData = record["organizationalInfoData"] as? Data,
              let professionalInfoData = record["professionalInfoData"] as? Data,
              let systemInfoData = record["systemInfoData"] as? Data,
              let permissionsData = record["permissionsData"] as? Data,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let decoder = JSONDecoder()
        
        guard let personalInfo = try? decoder.decode(PersonalInfo.self, from: personalInfoData),
              let contactInfo = try? decoder.decode(ContactInfo.self, from: contactInfoData),
              let organizationalInfo = try? decoder.decode(OrganizationalInfo.self, from: organizationalInfoData),
              let professionalInfo = try? decoder.decode(ProfessionalInfo.self, from: professionalInfoData),
              let systemInfo = try? decoder.decode(SystemInfo.self, from: systemInfoData),
              let permissions = try? decoder.decode(EmployeePermissions.self, from: permissionsData) else {
            return nil
        }
        
        // Optional data with defaults
        let preferences: EmployeePreferences
        if let preferencesData = record["preferencesData"] as? Data,
           let decodedPreferences = try? decoder.decode(EmployeePreferences.self, from: preferencesData) {
            preferences = decodedPreferences
        } else {
            preferences = EmployeePreferences()
        }
        
        let analytics: EmployeeAnalytics
        if let analyticsData = record["analyticsData"] as? Data,
           let decodedAnalytics = try? decoder.decode(EmployeeAnalytics.self, from: analyticsData) {
            analytics = decodedAnalytics
        } else {
            analytics = EmployeeAnalytics()
        }
        
        guard let recordId = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        var employee = Employee(
            id: recordId,
            employeeId: employeeId,
            personalInfo: personalInfo,
            contactInfo: contactInfo,
            organizationalInfo: organizationalInfo,
            professionalInfo: professionalInfo,
            systemInfo: systemInfo,
            permissions: permissions,
            preferences: preferences,
            analytics: analytics
        )
        
        employee.createdAt = createdAt
        employee.updatedAt = updatedAt
        
        return employee
    }
}

// MARK: - Directory Search and Filtering

/// Search criteria for employee directory
struct DirectorySearchCriteria: Codable {
    let searchText: String?
    let departments: [String]
    let locations: [LocationType]
    let employeeLevels: [EmployeeLevel]
    let skills: [String]
    let availableForMentoring: Bool?
    let hasSkillEndorsements: Bool?
    let workScheduleTypes: [ScheduleType]
    let languages: [String]
    
    init() {
        self.searchText = nil
        self.departments = []
        self.locations = []
        self.employeeLevels = []
        self.skills = []
        self.availableForMentoring = nil
        self.hasSkillEndorsements = nil
        self.workScheduleTypes = []
        self.languages = []
    }
    /// Convenience initializer for filtering criteria
    init(searchText: String?, departments: [String], locations: [LocationType], employeeLevels: [EmployeeLevel]) {
        self.searchText = searchText
        self.departments = departments
        self.locations = locations
        self.employeeLevels = employeeLevels
        self.skills = []
        self.availableForMentoring = nil
        self.hasSkillEndorsements = nil
        self.workScheduleTypes = []
        self.languages = []
    }
}

/// Sort options for directory listings
enum DirectorySortOption: String, CaseIterable {
    case name = "Name"
    case department = "Department"
    case jobTitle = "Job Title"
    case startDate = "Start Date"
    case level = "Level"
    case location = "Location"
    
    var keyPath: PartialKeyPath<Employee> {
        switch self {
        case .name: return \Employee.personalInfo.lastName
        case .department: return \Employee.organizationalInfo.department.name
        case .jobTitle: return \Employee.organizationalInfo.jobTitle
        case .startDate: return \Employee.organizationalInfo.startDate
        case .level: return \Employee.organizationalInfo.level
        case .location: return \Employee.organizationalInfo.location.type
        }
    }
}

/// Directory view modes
enum DirectoryViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    case orgChart = "Org Chart"
    case map = "Map"
    
    var iconName: String {
        switch self {
        case .grid: return "grid"
        case .list: return "list.bullet"
        case .orgChart: return "hierarchy"
        case .map: return "map"
        }
    }
}
