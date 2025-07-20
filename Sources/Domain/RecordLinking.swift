import Foundation
import CloudKit

// MARK: - Cross-Module Record Linking Models (Phase 4.15+ Placeholder)
public struct RecordLink: Identifiable, Codable, Hashable {
    public let id: String
    public var sourceModule: String
    public var sourceRecordId: String
    public var targetModule: String
    public var targetRecordId: String
    public var linkType: LinkType
    public var relationshipCategory: RelationshipCategory
    public var linkStrength: LinkStrength
    public var bidirectional: Bool
    public var contextMetadata: LinkContext
    public var createdBy: String
    public var createdAt: Date
    public var lastValidated: Date
    public var validationStatus: ValidationStatus
    public var automaticallyCreated: Bool
    public var confidenceScore: Double?
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        sourceModule: String,
        sourceRecordId: String,
        targetModule: String,
        targetRecordId: String,
        linkType: LinkType,
        relationshipCategory: RelationshipCategory,
        linkStrength: LinkStrength = .moderate,
        bidirectional: Bool = false,
        contextMetadata: LinkContext = LinkContext(),
        createdBy: String,
        createdAt: Date = Date(),
        lastValidated: Date = Date(),
        validationStatus: ValidationStatus = .valid,
        automaticallyCreated: Bool = false,
        confidenceScore: Double? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.sourceModule = sourceModule
        self.sourceRecordId = sourceRecordId
        self.targetModule = targetModule
        self.targetRecordId = targetRecordId
        self.linkType = linkType
        self.relationshipCategory = relationshipCategory
        self.linkStrength = linkStrength
        self.bidirectional = bidirectional
        self.contextMetadata = contextMetadata
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastValidated = lastValidated
        self.validationStatus = validationStatus
        self.automaticallyCreated = automaticallyCreated
        self.confidenceScore = confidenceScore
        self.isActive = isActive
    }
}

public enum LinkType: String, CaseIterable, Codable, Identifiable {
    case relatedTo = "RELATED_TO"
    case dependsOn = "DEPENDS_ON"
    case affects = "AFFECTS"
    case contains = "CONTAINS"
    case partOf = "PART_OF"
    case assignedTo = "ASSIGNED_TO"
    case causedBy = "CAUSED_BY"
    case resolvedBy = "RESOLVED_BY"
    case references = "REFERENCES"
    case duplicateOf = "DUPLICATE_OF"
    case derivedFrom = "DERIVED_FROM"
    case triggeredBy = "TRIGGERED_BY"
    case blocks = "BLOCKS"
    case enabledBy = "ENABLED_BY"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .relatedTo: return "Related To"
        case .dependsOn: return "Depends On"
        case .affects: return "Affects"
        case .contains: return "Contains"
        case .partOf: return "Part Of"
        case .assignedTo: return "Assigned To"
        case .causedBy: return "Caused By"
        case .resolvedBy: return "Resolved By"
        case .references: return "References"
        case .duplicateOf: return "Duplicate Of"
        case .derivedFrom: return "Derived From"
        case .triggeredBy: return "Triggered By"
        case .blocks: return "Blocks"
        case .enabledBy: return "Enabled By"
        }
    }
}

public enum RelationshipCategory: String, CaseIterable, Codable, Identifiable {
    case hierarchical = "HIERARCHICAL"
    case peer = "PEER"
    case dependency = "DEPENDENCY"
    case causal = "CAUSAL"
    case temporal = "TEMPORAL"
    case spatial = "SPATIAL"
    case contextual = "CONTEXTUAL"
    case functional = "FUNCTIONAL"
    case structural = "STRUCTURAL"
    
    public var id: String { rawValue }
}

public enum LinkStrength: String, CaseIterable, Codable, Identifiable {
    case weak = "WEAK"
    case moderate = "MODERATE"
    case strong = "STRONG"
    case critical = "CRITICAL"
    
    public var id: String { rawValue }
    
    public var numericValue: Double {
        switch self {
        case .weak: return 0.25
        case .moderate: return 0.5
        case .strong: return 0.75
        case .critical: return 1.0
        }
    }
}

public enum ValidationStatus: String, CaseIterable, Codable, Identifiable {
    case valid = "VALID"
    case invalid = "INVALID"
    case pending = "PENDING"
    case stale = "STALE"
    case broken = "BROKEN"
    
    public var id: String { rawValue }
}

public struct LinkContext: Codable, Hashable {
    public var description: String?
    public var tags: [String]
    public var metadata: [String: String]
    public var businessRules: [String]
    public var expirationDate: Date?
    
    public init(
        description: String? = nil,
        tags: [String] = [],
        metadata: [String: String] = [:],
        businessRules: [String] = [],
        expirationDate: Date? = nil
    ) {
        self.description = description
        self.tags = tags
        self.metadata = metadata
        self.businessRules = businessRules
        self.expirationDate = expirationDate
    }
}

// MARK: - Linkable Record Model
public struct LinkableRecord: Identifiable, Codable, Hashable {
    public let id: String
    public var recordId: String
    public var module: String
    public var recordType: String
    public var title: String
    public var description: String?
    public var metadata: RecordMetadata
    public var linkingRules: [LinkingRule]
    public var searchableFields: [String]
    public var lastIndexed: Date
    public var indexVersion: String
    public var accessRestrictions: [String]
    
    public init(
        id: String = UUID().uuidString,
        recordId: String,
        module: String,
        recordType: String,
        title: String,
        description: String? = nil,
        metadata: RecordMetadata = RecordMetadata(),
        linkingRules: [LinkingRule] = [],
        searchableFields: [String] = [],
        lastIndexed: Date = Date(),
        indexVersion: String = "1.0",
        accessRestrictions: [String] = []
    ) {
        self.id = id
        self.recordId = recordId
        self.module = module
        self.recordType = recordType
        self.title = title
        self.description = description
        self.metadata = metadata
        self.linkingRules = linkingRules
        self.searchableFields = searchableFields
        self.lastIndexed = lastIndexed
        self.indexVersion = indexVersion
        self.accessRestrictions = accessRestrictions
    }
}

public struct RecordMetadata: Codable, Hashable {
    public var primaryKey: String?
    public var foreignKeys: [String: String]
    public var businessIdentifiers: [String: String]
    public var displayFields: [String]
    public var searchKeywords: [String]
    public var categories: [String]
    public var priority: RecordPriority
    public var lastModified: Date
    public var modifiedBy: String?
    
    public init(
        primaryKey: String? = nil,
        foreignKeys: [String: String] = [:],
        businessIdentifiers: [String: String] = [:],
        displayFields: [String] = [],
        searchKeywords: [String] = [],
        categories: [String] = [],
        priority: RecordPriority = .normal,
        lastModified: Date = Date(),
        modifiedBy: String? = nil
    ) {
        self.primaryKey = primaryKey
        self.foreignKeys = foreignKeys
        self.businessIdentifiers = businessIdentifiers
        self.displayFields = displayFields
        self.searchKeywords = searchKeywords
        self.categories = categories
        self.priority = priority
        self.lastModified = lastModified
        self.modifiedBy = modifiedBy
    }
}

public enum RecordPriority: String, CaseIterable, Codable, Identifiable {
    case low = "LOW"
    case normal = "NORMAL"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    public var id: String { rawValue }
}

public struct LinkingRule: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var condition: String
    public var action: LinkingAction
    public var priority: Int
    public var isEnabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        condition: String,
        action: LinkingAction,
        priority: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.condition = condition
        self.action = action
        self.priority = priority
        self.isEnabled = isEnabled
    }
}

public enum LinkingAction: String, CaseIterable, Codable, Identifiable {
    case autoLink = "AUTO_LINK"
    case suggest = "SUGGEST"
    case ignore = "IGNORE"
    case require = "REQUIRE"
    
    public var id: String { rawValue }
}

// MARK: - Record Link Rule Model
public struct RecordLinkRule: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var sourceModule: String
    public var targetModule: String
    public var autoLinkConditions: [AutoLinkCondition]
    public var linkingAlgorithm: LinkingAlgorithm
    public var confidenceThreshold: Double
    public var maxSuggestions: Int
    public var isEnabled: Bool
    public var requiredPermissions: [String]
    public var createdBy: String
    public var createdAt: Date
    public var lastModified: Date
    public var usageStatistics: RuleUsageStatistics
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        sourceModule: String,
        targetModule: String,
        autoLinkConditions: [AutoLinkCondition] = [],
        linkingAlgorithm: LinkingAlgorithm = .similarity,
        confidenceThreshold: Double = 0.8,
        maxSuggestions: Int = 10,
        isEnabled: Bool = true,
        requiredPermissions: [String] = [],
        createdBy: String,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        usageStatistics: RuleUsageStatistics = RuleUsageStatistics()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sourceModule = sourceModule
        self.targetModule = targetModule
        self.autoLinkConditions = autoLinkConditions
        self.linkingAlgorithm = linkingAlgorithm
        self.confidenceThreshold = confidenceThreshold
        self.maxSuggestions = maxSuggestions
        self.isEnabled = isEnabled
        self.requiredPermissions = requiredPermissions
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.usageStatistics = usageStatistics
    }
}

public struct AutoLinkCondition: Identifiable, Codable, Hashable {
    public let id: String
    public var fieldName: String
    public var operator: ConditionOperator
    public var value: String
    public var weight: Double
    
    public init(
        id: String = UUID().uuidString,
        fieldName: String,
        operator: ConditionOperator,
        value: String,
        weight: Double = 1.0
    ) {
        self.id = id
        self.fieldName = fieldName
        self.operator = operator
        self.value = value
        self.weight = weight
    }
}

public enum ConditionOperator: String, CaseIterable, Codable, Identifiable {
    case equals = "EQUALS"
    case contains = "CONTAINS"
    case startsWith = "STARTS_WITH"
    case endsWith = "ENDS_WITH"
    case regex = "REGEX"
    case similarTo = "SIMILAR_TO"
    case greaterThan = "GREATER_THAN"
    case lessThan = "LESS_THAN"
    case between = "BETWEEN"
    
    public var id: String { rawValue }
}

public enum LinkingAlgorithm: String, CaseIterable, Codable, Identifiable {
    case exact = "EXACT"
    case similarity = "SIMILARITY"
    case fuzzy = "FUZZY"
    case semantic = "SEMANTIC"
    case neural = "NEURAL"
    case custom = "CUSTOM"
    
    public var id: String { rawValue }
}

public struct RuleUsageStatistics: Codable, Hashable {
    public var executionCount: Int
    public var successfulLinks: Int
    public var rejectedSuggestions: Int
    public var averageConfidence: Double
    public var lastExecuted: Date?
    public var averageExecutionTime: TimeInterval
    
    public init(
        executionCount: Int = 0,
        successfulLinks: Int = 0,
        rejectedSuggestions: Int = 0,
        averageConfidence: Double = 0.0,
        lastExecuted: Date? = nil,
        averageExecutionTime: TimeInterval = 0
    ) {
        self.executionCount = executionCount
        self.successfulLinks = successfulLinks
        self.rejectedSuggestions = rejectedSuggestions
        self.averageConfidence = averageConfidence
        self.lastExecuted = lastExecuted
        self.averageExecutionTime = averageExecutionTime
    }
}

// MARK: - Link Suggestion Model
public struct LinkSuggestion: Identifiable, Codable, Hashable {
    public let id: String
    public var sourceRecordId: String
    public var targetRecordId: String
    public var suggestionReason: SuggestionReason
    public var confidenceScore: Double
    public var suggestedLinkType: LinkType
    public var supportingEvidence: [EvidenceItem]
    public var generatedAt: Date
    public var status: SuggestionStatus
    public var reviewedBy: String?
    public var reviewedAt: Date?
    public var feedback: SuggestionFeedback?
    
    public init(
        id: String = UUID().uuidString,
        sourceRecordId: String,
        targetRecordId: String,
        suggestionReason: SuggestionReason,
        confidenceScore: Double,
        suggestedLinkType: LinkType,
        supportingEvidence: [EvidenceItem] = [],
        generatedAt: Date = Date(),
        status: SuggestionStatus = .pending,
        reviewedBy: String? = nil,
        reviewedAt: Date? = nil,
        feedback: SuggestionFeedback? = nil
    ) {
        self.id = id
        self.sourceRecordId = sourceRecordId
        self.targetRecordId = targetRecordId
        self.suggestionReason = suggestionReason
        self.confidenceScore = confidenceScore
        self.suggestedLinkType = suggestedLinkType
        self.supportingEvidence = supportingEvidence
        self.generatedAt = generatedAt
        self.status = status
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
        self.feedback = feedback
    }
}

public enum SuggestionReason: String, CaseIterable, Codable, Identifiable {
    case fieldMatch = "FIELD_MATCH"
    case semanticSimilarity = "SEMANTIC_SIMILARITY"
    case temporalProximity = "TEMPORAL_PROXIMITY"
    case userBehavior = "USER_BEHAVIOR"
    case businessRule = "BUSINESS_RULE"
    case machinelearning = "MACHINE_LEARNING"
    case externalSource = "EXTERNAL_SOURCE"
    
    public var id: String { rawValue }
}

public enum SuggestionStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case expired = "EXPIRED"
    case superseded = "SUPERSEDED"
    
    public var id: String { rawValue }
}

public struct EvidenceItem: Identifiable, Codable, Hashable {
    public let id: String
    public var evidenceType: EvidenceType
    public var description: String
    public var strength: Double
    public var metadata: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        evidenceType: EvidenceType,
        description: String,
        strength: Double,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.evidenceType = evidenceType
        self.description = description
        self.strength = strength
        self.metadata = metadata
    }
}

public enum EvidenceType: String, CaseIterable, Codable, Identifiable {
    case textSimilarity = "TEXT_SIMILARITY"
    case dateSimilarity = "DATE_SIMILARITY"
    case categoryMatch = "CATEGORY_MATCH"
    case userAction = "USER_ACTION"
    case systemRule = "SYSTEM_RULE"
    case externalReference = "EXTERNAL_REFERENCE"
    
    public var id: String { rawValue }
}

public struct SuggestionFeedback: Codable, Hashable {
    public var rating: Int // 1-5 scale
    public var comment: String?
    public var improvementSuggestions: [String]
    public var wasHelpful: Bool
    
    public init(
        rating: Int,
        comment: String? = nil,
        improvementSuggestions: [String] = [],
        wasHelpful: Bool = true
    ) {
        self.rating = rating
        self.comment = comment
        self.improvementSuggestions = improvementSuggestions
        self.wasHelpful = wasHelpful
    }
}

// MARK: - CloudKit Extensions (Placeholder)
extension RecordLink {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "RecordLink", recordID: CKRecord.ID(recordName: id))
        record["sourceModule"] = sourceModule
        record["sourceRecordId"] = sourceRecordId
        record["targetModule"] = targetModule
        record["targetRecordId"] = targetRecordId
        record["linkType"] = linkType.rawValue
        record["relationshipCategory"] = relationshipCategory.rawValue
        record["linkStrength"] = linkStrength.rawValue
        record["bidirectional"] = bidirectional ? 1 : 0
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["lastValidated"] = lastValidated
        record["validationStatus"] = validationStatus.rawValue
        record["automaticallyCreated"] = automaticallyCreated ? 1 : 0
        record["confidenceScore"] = confidenceScore
        record["isActive"] = isActive ? 1 : 0
        
        // Store complex objects as JSON
        if let data = try? JSONEncoder().encode(contextMetadata) {
            record["contextMetadata"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> RecordLink? {
        guard let sourceModule = record["sourceModule"] as? String,
              let sourceRecordId = record["sourceRecordId"] as? String,
              let targetModule = record["targetModule"] as? String,
              let targetRecordId = record["targetRecordId"] as? String,
              let linkTypeString = record["linkType"] as? String,
              let linkType = LinkType(rawValue: linkTypeString),
              let relationshipCategoryString = record["relationshipCategory"] as? String,
              let relationshipCategory = RelationshipCategory(rawValue: relationshipCategoryString),
              let createdBy = record["createdBy"] as? String else {
            return nil
        }
        
        let linkStrength = LinkStrength(rawValue: record["linkStrength"] as? String ?? "MODERATE") ?? .moderate
        let validationStatus = ValidationStatus(rawValue: record["validationStatus"] as? String ?? "VALID") ?? .valid
        let bidirectional = (record["bidirectional"] as? Int) == 1
        let automaticallyCreated = (record["automaticallyCreated"] as? Int) == 1
        let isActive = (record["isActive"] as? Int) == 1
        
        var contextMetadata = LinkContext()
        if let contextData = record["contextMetadata"] as? String,
           let data = contextData.data(using: .utf8) {
            contextMetadata = (try? JSONDecoder().decode(LinkContext.self, from: data)) ?? LinkContext()
        }
        
        return RecordLink(
            id: record.recordID.recordName,
            sourceModule: sourceModule,
            sourceRecordId: sourceRecordId,
            targetModule: targetModule,
            targetRecordId: targetRecordId,
            linkType: linkType,
            relationshipCategory: relationshipCategory,
            linkStrength: linkStrength,
            bidirectional: bidirectional,
            contextMetadata: contextMetadata,
            createdBy: createdBy,
            createdAt: record["createdAt"] as? Date ?? Date(),
            lastValidated: record["lastValidated"] as? Date ?? Date(),
            validationStatus: validationStatus,
            automaticallyCreated: automaticallyCreated,
            confidenceScore: record["confidenceScore"] as? Double,
            isActive: isActive
        )
    }
}
