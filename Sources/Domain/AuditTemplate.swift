import Foundation
#if canImport(CloudKit)
import CloudKit

/// Enhanced audit template with advanced features for comprehensive store audits
public struct AuditTemplate: Identifiable, Codable {
    public let id: CKRecord.ID
    public let title: String
    public let description: String?
    public let department: String?
    public let category: AuditCategory
    public let version: Int
    public let isActive: Bool
    public let sections: [AuditSection]
    public let weighting: SectionWeighting
    public let settings: AuditSettings
    public let createdBy: CKRecord.Reference
    public let createdByName: String
    public let createdAt: Date
    public let updatedAt: Date
    public let lastUsedAt: Date?
    public let usageCount: Int
    public let estimatedDuration: TimeInterval
    public let requiredRole: String?
    public let tags: [String]
    public let isTemplate: Bool
    public let parentTemplateId: CKRecord.Reference?
    
    public enum AuditCategory: String, CaseIterable, Codable {
        case operations = "operations"
        case safety = "safety"
        case customerService = "customer_service"
        case visualMerchandising = "visual_merchandising"
        case inventory = "inventory"
        case compliance = "compliance"
        case cleanliness = "cleanliness"
        case security = "security"
        case training = "training"
        case sales = "sales"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
            case .operations: return "Operations"
            case .safety: return "Safety"
            case .customerService: return "Customer Service"
            case .visualMerchandising: return "Visual Merchandising"
            case .inventory: return "Inventory"
            case .compliance: return "Compliance"
            case .cleanliness: return "Cleanliness"
            case .security: return "Security"
            case .training: return "Training"
            case .sales: return "Sales"
            case .custom: return "Custom"
            }
        }
        
        public var icon: String {
            switch self {
            case .operations: return "gearshape"
            case .safety: return "shield"
            case .customerService: return "person.2"
            case .visualMerchandising: return "photo"
            case .inventory: return "shippingbox"
            case .compliance: return "checkmark.shield"
            case .cleanliness: return "sparkles"
            case .security: return "lock.shield"
            case .training: return "book"
            case .sales: return "chart.line.uptrend.xyaxis"
            case .custom: return "slider.horizontal.3"
            }
        }
    }
    
    public struct AuditSection: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let description: String?
        public let order: Int
        public let isRequired: Bool
        public let weight: Double
        public let questions: [AuditQuestion]
        public let conditionalLogic: ConditionalLogic?
        
        public init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            order: Int,
            isRequired: Bool = true,
            weight: Double = 1.0,
            questions: [AuditQuestion],
            conditionalLogic: ConditionalLogic? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.order = order
            self.isRequired = isRequired
            self.weight = weight
            self.questions = questions
            self.conditionalLogic = conditionalLogic
        }
        
        public var totalPoints: Double {
            return questions.reduce(0) { $0 + $1.points }
        }
        
        public var weightedPoints: Double {
            return totalPoints * weight
        }
    }
    
    public struct AuditQuestion: Codable, Identifiable {
        public let id: UUID
        public let text: String
        public let description: String?
        public let type: QuestionType
        public let isRequired: Bool
        public let points: Double
        public let order: Int
        public let options: [String]? // For multiple choice
        public let validationRules: ValidationRules?
        public let photoRequired: Bool
        public let autoCreateTicket: Bool
        public let ticketPriority: String?
        public let helpText: String?
        public let tags: [String]
        
        public enum QuestionType: String, CaseIterable, Codable {
            case passFailNA = "pass_fail_na"
            case yesNo = "yes_no"
            case multipleChoice = "multiple_choice"
            case numeric = "numeric"
            case text = "text"
            case rating = "rating"
            case photo = "photo"
            case checklist = "checklist"
            
            public var displayName: String {
                switch self {
                case .passFailNA: return "Pass/Fail/N/A"
                case .yesNo: return "Yes/No"
                case .multipleChoice: return "Multiple Choice"
                case .numeric: return "Numeric"
                case .text: return "Text"
                case .rating: return "Rating"
                case .photo: return "Photo"
                case .checklist: return "Checklist"
                }
            }
        }
        
        public struct ValidationRules: Codable {
            public let minValue: Double?
            public let maxValue: Double?
            public let minLength: Int?
            public let maxLength: Int?
            public let pattern: String? // Regex pattern
            public let requiredOptions: [String]? // For checklist
            
            public init(
                minValue: Double? = nil,
                maxValue: Double? = nil,
                minLength: Int? = nil,
                maxLength: Int? = nil,
                pattern: String? = nil,
                requiredOptions: [String]? = nil
            ) {
                self.minValue = minValue
                self.maxValue = maxValue
                self.minLength = minLength
                self.maxLength = maxLength
                self.pattern = pattern
                self.requiredOptions = requiredOptions
            }
        }
        
        public init(
            id: UUID = UUID(),
            text: String,
            description: String? = nil,
            type: QuestionType,
            isRequired: Bool = true,
            points: Double = 1.0,
            order: Int,
            options: [String]? = nil,
            validationRules: ValidationRules? = nil,
            photoRequired: Bool = false,
            autoCreateTicket: Bool = false,
            ticketPriority: String? = nil,
            helpText: String? = nil,
            tags: [String] = []
        ) {
            self.id = id
            self.text = text
            self.description = description
            self.type = type
            self.isRequired = isRequired
            self.points = points
            self.order = order
            self.options = options
            self.validationRules = validationRules
            self.photoRequired = photoRequired
            self.autoCreateTicket = autoCreateTicket
            self.ticketPriority = ticketPriority
            self.helpText = helpText
            self.tags = tags
        }
    }
    
    public struct ConditionalLogic: Codable {
        public let condition: LogicCondition
        public let action: LogicAction
        
        public enum LogicCondition: Codable {
            case questionAnswered(questionId: UUID, answer: String)
            case sectionCompleted(sectionId: UUID)
            case scoreThreshold(minScore: Double)
            case always
            case never
        }
        
        public enum LogicAction: Codable {
            case showSection(sectionId: UUID)
            case hideSection(sectionId: UUID)
            case showQuestion(questionId: UUID)
            case hideQuestion(questionId: UUID)
            case requirePhoto
            case createTicket(priority: String)
            case setFlag(flag: String)
        }
    }
    
    public struct SectionWeighting: Codable {
        public let sections: [UUID: Double] // sectionId -> weight
        public let totalWeight: Double
        public let normalizeScores: Bool
        
        public init(sections: [UUID: Double], normalizeScores: Bool = true) {
            self.sections = sections
            self.totalWeight = sections.values.reduce(0, +)
            self.normalizeScores = normalizeScores
        }
        
        public func weightForSection(_ sectionId: UUID) -> Double {
            return sections[sectionId] ?? 1.0
        }
        
        public var normalizedWeights: [UUID: Double] {
            guard totalWeight > 0 else { return sections }
            return sections.mapValues { $0 / totalWeight }
        }
    }
    
    public struct AuditSettings: Codable {
        public let allowPartialSubmission: Bool
        public let requireAllPhotos: Bool
        public let autoCreateTicketsOnFail: Bool
        public let requireManagerApproval: Bool
        public let timeLimit: TimeInterval?
        public let randomizeQuestions: Bool
        public let allowComments: Bool
        public let requireSignature: Bool
        public let notificationSettings: NotificationSettings
        public let scoringMethod: ScoringMethod
        
        public enum ScoringMethod: String, CaseIterable, Codable {
            case percentage = "percentage"
            case points = "points"
            case weighted = "weighted"
            case pass_fail = "pass_fail"
            
            public var displayName: String {
                switch self {
                case .percentage: return "Percentage"
                case .points: return "Points"
                case .weighted: return "Weighted"
                case .pass_fail: return "Pass/Fail"
                }
            }
        }
        
        public struct NotificationSettings: Codable {
            public let notifyOnStart: Bool
            public let notifyOnCompletion: Bool
            public let notifyOnFailure: Bool
            public let notifyRoles: [String]
            public let escalationTime: TimeInterval?
            
            public init(
                notifyOnStart: Bool = false,
                notifyOnCompletion: Bool = true,
                notifyOnFailure: Bool = true,
                notifyRoles: [String] = [],
                escalationTime: TimeInterval? = nil
            ) {
                self.notifyOnStart = notifyOnStart
                self.notifyOnCompletion = notifyOnCompletion
                self.notifyOnFailure = notifyOnFailure
                self.notifyRoles = notifyRoles
                self.escalationTime = escalationTime
            }
        }
        
        public init(
            allowPartialSubmission: Bool = false,
            requireAllPhotos: Bool = false,
            autoCreateTicketsOnFail: Bool = false,
            requireManagerApproval: Bool = false,
            timeLimit: TimeInterval? = nil,
            randomizeQuestions: Bool = false,
            allowComments: Bool = true,
            requireSignature: Bool = false,
            notificationSettings: NotificationSettings = NotificationSettings(),
            scoringMethod: ScoringMethod = .percentage
        ) {
            self.allowPartialSubmission = allowPartialSubmission
            self.requireAllPhotos = requireAllPhotos
            self.autoCreateTicketsOnFail = autoCreateTicketsOnFail
            self.requireManagerApproval = requireManagerApproval
            self.timeLimit = timeLimit
            self.randomizeQuestions = randomizeQuestions
            self.allowComments = allowComments
            self.requireSignature = requireSignature
            self.notificationSettings = notificationSettings
            self.scoringMethod = scoringMethod
        }
    }
    
    // Computed properties
    public var totalQuestions: Int {
        return sections.reduce(0) { $0 + $1.questions.count }
    }
    
    public var totalPoints: Double {
        return sections.reduce(0) { $0 + $1.totalPoints }
    }
    
    public var weightedTotalPoints: Double {
        return sections.reduce(0) { $0 + $1.weightedPoints }
    }
    
    public var requiredQuestions: Int {
        return sections.reduce(0) { sum, section in
            sum + section.questions.filter { $0.isRequired }.count
        }
    }
    
    public var photoQuestions: Int {
        return sections.reduce(0) { sum, section in
            sum + section.questions.filter { $0.photoRequired }.count
        }
    }
    
    public var autoTicketQuestions: Int {
        return sections.reduce(0) { sum, section in
            sum + section.questions.filter { $0.autoCreateTicket }.count
        }
    }
    
    public var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    public var complexity: AuditComplexity {
        let questionCount = totalQuestions
        let hasConditionalLogic = sections.contains { $0.conditionalLogic != nil }
        let hasValidation = sections.contains { section in
            section.questions.contains { $0.validationRules != nil }
        }
        
        if questionCount > 50 || hasConditionalLogic || hasValidation {
            return .complex
        } else if questionCount > 20 || photoQuestions > 5 {
            return .medium
        } else {
            return .simple
        }
    }
    
    public enum AuditComplexity: String, CaseIterable {
        case simple = "simple"
        case medium = "medium"
        case complex = "complex"
        
        public var displayName: String {
            switch self {
            case .simple: return "Simple"
            case .medium: return "Medium"
            case .complex: return "Complex"
            }
        }
        
        public var color: String {
            switch self {
            case .simple: return "green"
            case .medium: return "yellow"
            case .complex: return "red"
            }
        }
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let title = record["title"] as? String,
              let categoryRaw = record["category"] as? String,
              let category = AuditCategory(rawValue: categoryRaw),
              let version = record["version"] as? Int,
              let isActive = record["isActive"] as? Bool,
              let createdBy = record["createdBy"] as? CKRecord.Reference,
              let createdByName = record["createdByName"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let usageCount = record["usageCount"] as? Int,
              let estimatedDuration = record["estimatedDuration"] as? TimeInterval,
              let isTemplate = record["isTemplate"] as? Bool else {
            return nil
        }
        
        self.id = record.recordID
        self.title = title
        self.description = record["description"] as? String
        self.department = record["department"] as? String
        self.category = category
        self.version = version
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = record["lastUsedAt"] as? Date
        self.usageCount = usageCount
        self.estimatedDuration = estimatedDuration
        self.requiredRole = record["requiredRole"] as? String
        self.isTemplate = isTemplate
        self.parentTemplateId = record["parentTemplateId"] as? CKRecord.Reference
        
        // Decode tags from JSON
        if let tagsData = record["tags"] as? Data,
           let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
            self.tags = decodedTags
        } else {
            self.tags = []
        }
        
        // Decode sections from JSON
        if let sectionsData = record["sections"] as? Data,
           let decodedSections = try? JSONDecoder().decode([AuditSection].self, from: sectionsData) {
            self.sections = decodedSections
        } else {
            self.sections = []
        }
        
        // Decode weighting from JSON
        if let weightingData = record["weighting"] as? Data,
           let decodedWeighting = try? JSONDecoder().decode(SectionWeighting.self, from: weightingData) {
            self.weighting = decodedWeighting
        } else {
            // Default weighting
            let sectionWeights = Dictionary(uniqueKeysWithValues: sections.map { ($0.id, 1.0) })
            self.weighting = SectionWeighting(sections: sectionWeights)
        }
        
        // Decode settings from JSON
        if let settingsData = record["settings"] as? Data,
           let decodedSettings = try? JSONDecoder().decode(AuditSettings.self, from: settingsData) {
            self.settings = decodedSettings
        } else {
            self.settings = AuditSettings()
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "AuditTemplate", recordID: id)
        
        record["title"] = title
        record["description"] = description
        record["department"] = department
        record["category"] = category.rawValue
        record["version"] = version
        record["isActive"] = isActive
        record["createdBy"] = createdBy
        record["createdByName"] = createdByName
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["lastUsedAt"] = lastUsedAt
        record["usageCount"] = usageCount
        record["estimatedDuration"] = estimatedDuration
        record["requiredRole"] = requiredRole
        record["isTemplate"] = isTemplate
        record["parentTemplateId"] = parentTemplateId
        
        // Encode complex data as JSON
        if let tagsData = try? JSONEncoder().encode(tags) {
            record["tags"] = tagsData
        }
        
        if let sectionsData = try? JSONEncoder().encode(sections) {
            record["sections"] = sectionsData
        }
        
        if let weightingData = try? JSONEncoder().encode(weighting) {
            record["weighting"] = weightingData
        }
        
        if let settingsData = try? JSONEncoder().encode(settings) {
            record["settings"] = settingsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> AuditTemplate? {
        return AuditTemplate(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        title: String,
        description: String? = nil,
        department: String? = nil,
        category: AuditCategory,
        createdBy: CKRecord.Reference,
        createdByName: String,
        requiredRole: String? = nil,
        estimatedDuration: TimeInterval = 1800, // 30 minutes default
        tags: [String] = []
    ) -> AuditTemplate {
        let now = Date()
        
        return AuditTemplate(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: title,
            description: description,
            department: department,
            category: category,
            version: 1,
            isActive: true,
            sections: [],
            weighting: SectionWeighting(sections: [:]),
            settings: AuditSettings(),
            createdBy: createdBy,
            createdByName: createdByName,
            createdAt: now,
            updatedAt: now,
            lastUsedAt: nil,
            usageCount: 0,
            estimatedDuration: estimatedDuration,
            requiredRole: requiredRole,
            tags: tags,
            isTemplate: true,
            parentTemplateId: nil
        )
    }
    
    // MARK: - Helper Methods
    
    public func incrementUsage() -> AuditTemplate {
        return AuditTemplate(
            id: id,
            title: title,
            description: description,
            department: department,
            category: category,
            version: version,
            isActive: isActive,
            sections: sections,
            weighting: weighting,
            settings: settings,
            createdBy: createdBy,
            createdByName: createdByName,
            createdAt: createdAt,
            updatedAt: Date(),
            lastUsedAt: Date(),
            usageCount: usageCount + 1,
            estimatedDuration: estimatedDuration,
            requiredRole: requiredRole,
            tags: tags,
            isTemplate: isTemplate,
            parentTemplateId: parentTemplateId
        )
    }
    
    public func createNewVersion(
        sections: [AuditSection]? = nil,
        weighting: SectionWeighting? = nil,
        settings: AuditSettings? = nil,
        updatedBy: CKRecord.Reference
    ) -> AuditTemplate {
        return AuditTemplate(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: title,
            description: description,
            department: department,
            category: category,
            version: version + 1,
            isActive: isActive,
            sections: sections ?? self.sections,
            weighting: weighting ?? self.weighting,
            settings: settings ?? self.settings,
            createdBy: updatedBy,
            createdByName: createdByName,
            createdAt: Date(),
            updatedAt: Date(),
            lastUsedAt: nil,
            usageCount: 0,
            estimatedDuration: estimatedDuration,
            requiredRole: requiredRole,
            tags: tags,
            isTemplate: isTemplate,
            parentTemplateId: CKRecord.Reference(recordID: id, action: .none)
        )
    }
    
    public func deactivate() -> AuditTemplate {
        return AuditTemplate(
            id: id,
            title: title,
            description: description,
            department: department,
            category: category,
            version: version,
            isActive: false,
            sections: sections,
            weighting: weighting,
            settings: settings,
            createdBy: createdBy,
            createdByName: createdByName,
            createdAt: createdAt,
            updatedAt: Date(),
            lastUsedAt: lastUsedAt,
            usageCount: usageCount,
            estimatedDuration: estimatedDuration,
            requiredRole: requiredRole,
            tags: tags,
            isTemplate: isTemplate,
            parentTemplateId: parentTemplateId
        )
    }
}

public typealias AuditItem = AuditQuestion

#endif

