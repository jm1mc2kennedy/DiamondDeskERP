//
//  AIInsightsModels.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit
import CoreML

// MARK: - AI Insight Models

/// Core AI insight recommendation model
struct AIInsight: Identifiable, Codable {
    let id: String
    var type: InsightType
    var title: String
    var description: String
    var confidence: Double // 0.0 - 1.0
    var priority: InsightPriority
    var category: InsightCategory
    var targetEntityType: String
    var targetEntityId: String
    var actionRecommendations: [ActionRecommendation]
    var supportingData: [String: Any]
    var createdAt: Date
    var expiresAt: Date?
    var isActionTaken: Bool
    var feedback: InsightFeedback?
    var tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, description, confidence, priority, category
        case targetEntityType, targetEntityId, actionRecommendations
        case createdAt, expiresAt, isActionTaken, feedback, tags
        case supportingData = "supporting_data"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(InsightType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        confidence = try container.decode(Double.self, forKey: .confidence)
        priority = try container.decode(InsightPriority.self, forKey: .priority)
        category = try container.decode(InsightCategory.self, forKey: .category)
        targetEntityType = try container.decode(String.self, forKey: .targetEntityType)
        targetEntityId = try container.decode(String.self, forKey: .targetEntityId)
        actionRecommendations = try container.decode([ActionRecommendation].self, forKey: .actionRecommendations)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        isActionTaken = try container.decode(Bool.self, forKey: .isActionTaken)
        feedback = try container.decodeIfPresent(InsightFeedback.self, forKey: .feedback)
        tags = try container.decode([String].self, forKey: .tags)
        
        // Handle supportingData as [String: Any]
        if let data = try? container.decode([String: String].self, forKey: .supportingData) {
            supportingData = data
        } else {
            supportingData = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(priority, forKey: .priority)
        try container.encode(category, forKey: .category)
        try container.encode(targetEntityType, forKey: .targetEntityType)
        try container.encode(targetEntityId, forKey: .targetEntityId)
        try container.encode(actionRecommendations, forKey: .actionRecommendations)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encode(isActionTaken, forKey: .isActionTaken)
        try container.encodeIfPresent(feedback, forKey: .feedback)
        try container.encode(tags, forKey: .tags)
        
        // Encode supportingData as string values only
        let stringData = supportingData.compactMapValues { "\($0)" }
        try container.encode(stringData, forKey: .supportingData)
    }
}

/// Types of AI insights
enum InsightType: String, CaseIterable, Codable {
    case documentRecommendation = "DOCUMENT_RECOMMENDATION"
    case taskOptimization = "TASK_OPTIMIZATION"
    case performancePrediction = "PERFORMANCE_PREDICTION"
    case riskAssessment = "RISK_ASSESSMENT"
    case resourceOptimization = "RESOURCE_OPTIMIZATION"
    case clientEngagement = "CLIENT_ENGAGEMENT"
    case auditScheduling = "AUDIT_SCHEDULING"
    case trainingRecommendation = "TRAINING_RECOMMENDATION"
    case workflowImprovement = "WORKFLOW_IMPROVEMENT"
    case complianceAlert = "COMPLIANCE_ALERT"
}

/// Priority levels for insights
enum InsightPriority: String, CaseIterable, Codable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
    case informational = "INFORMATIONAL"
    
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        case .informational: return 4
        }
    }
}

/// Categories for organizing insights
enum InsightCategory: String, CaseIterable, Codable {
    case productivity = "PRODUCTIVITY"
    case compliance = "COMPLIANCE"
    case performance = "PERFORMANCE"
    case risk = "RISK"
    case engagement = "ENGAGEMENT"
    case optimization = "OPTIMIZATION"
    case prediction = "PREDICTION"
    case recommendation = "RECOMMENDATION"
}

/// Action recommendation within an insight
struct ActionRecommendation: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var actionType: ActionType
    var estimatedImpact: Double // 0.0 - 1.0
    var estimatedEffort: EffortLevel
    var targetUrl: String?
    var parameters: [String: String]
    var isCompleted: Bool
    var completedAt: Date?
    
    enum ActionType: String, CaseIterable, Codable {
        case navigate = "NAVIGATE"
        case create = "CREATE"
        case update = "UPDATE"
        case review = "REVIEW"
        case schedule = "SCHEDULE"
        case assign = "ASSIGN"
        case notify = "NOTIFY"
        case archive = "ARCHIVE"
    }
    
    enum EffortLevel: String, CaseIterable, Codable {
        case minimal = "MINIMAL"     // < 5 minutes
        case low = "LOW"             // 5-15 minutes
        case medium = "MEDIUM"       // 15-60 minutes
        case high = "HIGH"           // 1+ hours
        case planning = "PLANNING"   // Requires planning
    }
}

/// User feedback on insights
struct InsightFeedback: Codable {
    var rating: Int // 1-5 stars
    var isHelpful: Bool
    var comment: String?
    var actionTaken: Bool
    var submittedAt: Date
    var submittedBy: String
}

// MARK: - ML Model Outputs

/// Document similarity analysis result
struct DocumentSimilarity: Codable {
    let documentId: String
    let similarDocuments: [SimilarDocument]
    let analysisDate: Date
    let confidence: Double
}

struct SimilarDocument: Codable {
    let documentId: String
    let similarity: Double // 0.0 - 1.0
    let commonTopics: [String]
    let reasonCodes: [String]
}

/// Performance prediction model output
struct PerformancePrediction: Codable {
    let entityId: String
    let entityType: String // "User", "Store", "Department"
    let predictionType: PredictionType
    let predictedValue: Double
    let confidence: Double
    let timeframe: PredictionTimeframe
    let influencingFactors: [InfluencingFactor]
    let createdAt: Date
}

enum PredictionType: String, CaseIterable, Codable {
    case salesPerformance = "SALES_PERFORMANCE"
    case taskCompletion = "TASK_COMPLETION"
    case auditScore = "AUDIT_SCORE"
    case clientSatisfaction = "CLIENT_SATISFACTION"
    case trainingProgress = "TRAINING_PROGRESS"
    case riskScore = "RISK_SCORE"
}

enum PredictionTimeframe: String, CaseIterable, Codable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case quarterly = "QUARTERLY"
    case annual = "ANNUAL"
}

struct InfluencingFactor: Codable {
    let factor: String
    let impact: Double // -1.0 to 1.0
    let confidence: Double
    let description: String
}

// MARK: - Analytics Models

/// Aggregated analytics for insights
struct InsightAnalytics: Codable {
    let totalInsights: Int
    let insightsByType: [InsightType: Int]
    let insightsByPriority: [InsightPriority: Int]
    let averageConfidence: Double
    let actionTakenRate: Double
    let userFeedbackAverage: Double
    let topCategories: [InsightCategory]
    let periodStart: Date
    let periodEnd: Date
}

/// User interaction with AI insights
struct InsightInteraction: Codable {
    let insightId: String
    let userId: String
    let interactionType: InteractionType
    let timestamp: Date
    let durationSeconds: Double?
    let metadata: [String: String]
}

enum InteractionType: String, CaseIterable, Codable {
    case viewed = "VIEWED"
    case dismissed = "DISMISSED"
    case actionTaken = "ACTION_TAKEN"
    case feedbackProvided = "FEEDBACK_PROVIDED"
    case shared = "SHARED"
    case bookmarked = "BOOKMARKED"
}

// MARK: - Training Models

/// Model training data point
struct MLTrainingData: Codable {
    let id: String
    let features: [String: Double]
    let target: Double
    let entityType: String
    let entityId: String
    let timestamp: Date
    let labels: [String]
}

/// Model performance metrics
struct MLModelMetrics: Codable {
    let modelName: String
    let version: String
    let accuracy: Double
    let precision: Double
    let recall: Double
    let f1Score: Double
    let meanAbsoluteError: Double?
    let rootMeanSquareError: Double?
    let trainingDataSize: Int
    let lastTrainedAt: Date
    let evaluatedAt: Date
}

// MARK: - CloudKit Extensions

extension AIInsight {
    /// Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AIInsight", recordID: CKRecord.ID(recordName: id))
        
        record["type"] = type.rawValue
        record["title"] = title
        record["description"] = description
        record["confidence"] = confidence
        record["priority"] = priority.rawValue
        record["category"] = category.rawValue
        record["targetEntityType"] = targetEntityType
        record["targetEntityId"] = targetEntityId
        record["createdAt"] = createdAt
        record["expiresAt"] = expiresAt
        record["isActionTaken"] = isActionTaken ? 1 : 0
        record["tags"] = tags
        
        // Encode complex objects as JSON strings
        if let actionsData = try? JSONEncoder().encode(actionRecommendations),
           let actionsString = String(data: actionsData, encoding: .utf8) {
            record["actionRecommendations"] = actionsString
        }
        
        if let feedback = feedback,
           let feedbackData = try? JSONEncoder().encode(feedback),
           let feedbackString = String(data: feedbackData, encoding: .utf8) {
            record["feedback"] = feedbackString
        }
        
        if let supportingDataJSON = try? JSONSerialization.data(withJSONObject: supportingData),
           let supportingDataString = String(data: supportingDataJSON, encoding: .utf8) {
            record["supportingData"] = supportingDataString
        }
        
        return record
    }
    
    /// Create from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> AIInsight? {
        guard let typeString = record["type"] as? String,
              let type = InsightType(rawValue: typeString),
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let confidence = record["confidence"] as? Double,
              let priorityString = record["priority"] as? String,
              let priority = InsightPriority(rawValue: priorityString),
              let categoryString = record["category"] as? String,
              let category = InsightCategory(rawValue: categoryString),
              let targetEntityType = record["targetEntityType"] as? String,
              let targetEntityId = record["targetEntityId"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let isActionTakenInt = record["isActionTaken"] as? Int,
              let tags = record["tags"] as? [String] else {
            return nil
        }
        
        var actionRecommendations: [ActionRecommendation] = []
        if let actionsString = record["actionRecommendations"] as? String,
           let actionsData = actionsString.data(using: .utf8) {
            actionRecommendations = (try? JSONDecoder().decode([ActionRecommendation].self, from: actionsData)) ?? []
        }
        
        var feedback: InsightFeedback?
        if let feedbackString = record["feedback"] as? String,
           let feedbackData = feedbackString.data(using: .utf8) {
            feedback = try? JSONDecoder().decode(InsightFeedback.self, from: feedbackData)
        }
        
        var supportingData: [String: Any] = [:]
        if let supportingDataString = record["supportingData"] as? String,
           let supportingDataData = supportingDataString.data(using: .utf8),
           let data = try? JSONSerialization.jsonObject(with: supportingDataData) as? [String: Any] {
            supportingData = data
        }
        
        return AIInsight(
            id: record.recordID.recordName,
            type: type,
            title: title,
            description: description,
            confidence: confidence,
            priority: priority,
            category: category,
            targetEntityType: targetEntityType,
            targetEntityId: targetEntityId,
            actionRecommendations: actionRecommendations,
            supportingData: supportingData,
            createdAt: createdAt,
            expiresAt: record["expiresAt"] as? Date,
            isActionTaken: isActionTakenInt == 1,
            feedback: feedback,
            tags: tags
        )
    }
}

extension PerformancePrediction {
    /// Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "PerformancePrediction")
        
        record["entityId"] = entityId
        record["entityType"] = entityType
        record["predictionType"] = predictionType.rawValue
        record["predictedValue"] = predictedValue
        record["confidence"] = confidence
        record["timeframe"] = timeframe.rawValue
        record["createdAt"] = createdAt
        
        if let factorsData = try? JSONEncoder().encode(influencingFactors),
           let factorsString = String(data: factorsData, encoding: .utf8) {
            record["influencingFactors"] = factorsString
        }
        
        return record
    }
    
    /// Create from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> PerformancePrediction? {
        guard let entityId = record["entityId"] as? String,
              let entityType = record["entityType"] as? String,
              let predictionTypeString = record["predictionType"] as? String,
              let predictionType = PredictionType(rawValue: predictionTypeString),
              let predictedValue = record["predictedValue"] as? Double,
              let confidence = record["confidence"] as? Double,
              let timeframeString = record["timeframe"] as? String,
              let timeframe = PredictionTimeframe(rawValue: timeframeString),
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        var influencingFactors: [InfluencingFactor] = []
        if let factorsString = record["influencingFactors"] as? String,
           let factorsData = factorsString.data(using: .utf8) {
            influencingFactors = (try? JSONDecoder().decode([InfluencingFactor].self, from: factorsData)) ?? []
        }
        
        return PerformancePrediction(
            entityId: entityId,
            entityType: entityType,
            predictionType: predictionType,
            predictedValue: predictedValue,
            confidence: confidence,
            timeframe: timeframe,
            influencingFactors: influencingFactors,
            createdAt: createdAt
        )
    }
}
