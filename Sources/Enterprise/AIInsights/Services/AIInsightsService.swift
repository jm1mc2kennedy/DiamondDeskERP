//
//  AIInsightsService.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit
import CoreML
import Combine
import os.log

/// AI-powered insights service for intelligent recommendations and analytics
@MainActor
final class AIInsightsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var insights: [AIInsight] = []
    @Published var predictions: [PerformancePrediction] = []
    @Published var analytics: InsightAnalytics?
    @Published var isProcessing = false
    @Published var error: AIInsightsError?
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let database: CKDatabase
    private let logger = Logger(subsystem: "com.diamonddesk.erp", category: "AIInsights")
    private var cancellables = Set<AnyCancellable>()
    
    // ML Models
    private var documentClassificationModel: MLModel?
    private var performancePredictionModel: MLModel?
    private var riskAssessmentModel: MLModel?
    
    // Processing queues
    private let insightQueue = DispatchQueue(label: "com.diamonddesk.insights", qos: .utility)
    private let mlQueue = DispatchQueue(label: "com.diamonddesk.ml", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        self.container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
        self.database = container.privateCloudDatabase
        
        setupMLModels()
        startBackgroundProcessing()
    }
    
    // MARK: - Public Interface
    
    /// Load all insights for the current user
    func loadInsights() async {
        isProcessing = true
        error = nil
        
        do {
            let userRole = await UserProvisioningService.shared.currentUserRole ?? .associate
            let insights = try await fetchInsights(for: userRole)
            
            await MainActor.run {
                self.insights = insights.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
            }
            
            logger.info("Loaded \(insights.count) AI insights")
            
        } catch {
            await MainActor.run {
                self.error = .failedToLoad(error)
            }
            logger.error("Failed to load insights: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    /// Generate new insights based on current data
    func generateInsights() async {
        isProcessing = true
        
        do {
            // Generate document recommendations
            let documentInsights = try await generateDocumentRecommendations()
            
            // Generate performance predictions
            let performanceInsights = try await generatePerformancePredictions()
            
            // Generate risk assessments
            let riskInsights = try await generateRiskAssessments()
            
            // Generate task optimizations
            let taskInsights = try await generateTaskOptimizations()
            
            // Combine all insights
            let newInsights = documentInsights + performanceInsights + riskInsights + taskInsights
            
            // Save to CloudKit
            try await saveInsights(newInsights)
            
            // Reload to get updated data
            await loadInsights()
            
            logger.info("Generated \(newInsights.count) new insights")
            
        } catch {
            await MainActor.run {
                self.error = .failedToGenerate(error)
            }
            logger.error("Failed to generate insights: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    /// Mark insight as action taken
    func markActionTaken(_ insight: AIInsight, action: ActionRecommendation) async {
        do {
            var updatedInsight = insight
            updatedInsight.isActionTaken = true
            
            // Update action recommendation
            if let index = updatedInsight.actionRecommendations.firstIndex(where: { $0.id == action.id }) {
                updatedInsight.actionRecommendations[index].isCompleted = true
                updatedInsight.actionRecommendations[index].completedAt = Date()
            }
            
            try await updateInsight(updatedInsight)
            
            // Record interaction
            let interaction = InsightInteraction(
                insightId: insight.id,
                userId: UserProvisioningService.shared.currentUserId ?? "unknown",
                interactionType: .actionTaken,
                timestamp: Date(),
                durationSeconds: nil,
                metadata: ["actionId": action.id]
            )
            
            try await recordInteraction(interaction)
            
            await loadInsights()
            
        } catch {
            await MainActor.run {
                self.error = .failedToUpdate(error)
            }
        }
    }
    
    /// Provide feedback on insight
    func provideFeedback(_ insight: AIInsight, feedback: InsightFeedback) async {
        do {
            var updatedInsight = insight
            updatedInsight.feedback = feedback
            
            try await updateInsight(updatedInsight)
            
            // Record interaction
            let interaction = InsightInteraction(
                insightId: insight.id,
                userId: UserProvisioningService.shared.currentUserId ?? "unknown",
                interactionType: .feedbackProvided,
                timestamp: Date(),
                durationSeconds: nil,
                metadata: ["rating": "\(feedback.rating)", "helpful": "\(feedback.isHelpful)"]
            )
            
            try await recordInteraction(interaction)
            
            await loadInsights()
            
        } catch {
            await MainActor.run {
                self.error = .failedToUpdate(error)
            }
        }
    }
    
    /// Generate analytics for insights
    func generateAnalytics(period: DateInterval) async {
        do {
            let analytics = try await calculateInsightAnalytics(for: period)
            
            await MainActor.run {
                self.analytics = analytics
            }
            
        } catch {
            logger.error("Failed to generate analytics: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Document Recommendations
    
    private func generateDocumentRecommendations() async throws -> [AIInsight] {
        var recommendations: [AIInsight] = []
        
        // Get user's recent document activity
        let recentDocuments = try await fetchRecentDocuments()
        
        for document in recentDocuments {
            // Find similar documents using ML
            if let similarities = try await findSimilarDocuments(to: document) {
                for similar in similarities.similarDocuments.prefix(3) {
                    let insight = AIInsight(
                        id: UUID().uuidString,
                        type: .documentRecommendation,
                        title: "Related Document Found",
                        description: "Based on your work with '\(document.title)', you might find '\(similar.documentId)' helpful.",
                        confidence: similar.similarity,
                        priority: similar.similarity > 0.8 ? .high : .medium,
                        category: .recommendation,
                        targetEntityType: "Document",
                        targetEntityId: similar.documentId,
                        actionRecommendations: [
                            ActionRecommendation(
                                id: UUID().uuidString,
                                title: "View Document",
                                description: "Open the recommended document",
                                actionType: .navigate,
                                estimatedImpact: similar.similarity,
                                estimatedEffort: .minimal,
                                targetUrl: "/documents/\(similar.documentId)",
                                parameters: ["documentId": similar.documentId],
                                isCompleted: false,
                                completedAt: nil
                            )
                        ],
                        supportingData: [
                            "similarityScore": similar.similarity,
                            "commonTopics": similar.commonTopics.joined(separator: ", "),
                            "sourceDocument": document.id
                        ],
                        createdAt: Date(),
                        expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                        isActionTaken: false,
                        feedback: nil,
                        tags: ["document", "recommendation", "similarity"]
                    )
                    
                    recommendations.append(insight)
                }
            }
        }
        
        return recommendations
    }
    
    // MARK: - Performance Predictions
    
    private func generatePerformancePredictions() async throws -> [AIInsight] {
        var insights: [AIInsight] = []
        
        // Get current user and their performance data
        guard let currentUser = UserProvisioningService.shared.currentUser else { return insights }
        
        // Generate sales performance prediction
        if let salesPrediction = try await predictSalesPerformance(for: currentUser.id) {
            let insight = createPerformancePredictionInsight(prediction: salesPrediction)
            insights.append(insight)
            
            // Store prediction
            predictions.append(salesPrediction)
        }
        
        // Generate task completion prediction
        if let taskPrediction = try await predictTaskCompletion(for: currentUser.id) {
            let insight = createTaskCompletionInsight(prediction: taskPrediction)
            insights.append(insight)
            
            predictions.append(taskPrediction)
        }
        
        return insights
    }
    
    // MARK: - Risk Assessments
    
    private func generateRiskAssessments() async throws -> [AIInsight] {
        var insights: [AIInsight] = []
        
        // Assess compliance risks
        let complianceRisks = try await assessComplianceRisks()
        insights.append(contentsOf: complianceRisks)
        
        // Assess performance risks
        let performanceRisks = try await assessPerformanceRisks()
        insights.append(contentsOf: performanceRisks)
        
        return insights
    }
    
    // MARK: - Task Optimizations
    
    private func generateTaskOptimizations() async throws -> [AIInsight] {
        var insights: [AIInsight] = []
        
        // Analyze task patterns
        let taskPatterns = try await analyzeTaskPatterns()
        
        for pattern in taskPatterns {
            if pattern.inefficiencyScore > 0.7 {
                let insight = AIInsight(
                    id: UUID().uuidString,
                    type: .taskOptimization,
                    title: "Task Optimization Opportunity",
                    description: "We detected a pattern in your task workflow that could be optimized.",
                    confidence: pattern.confidence,
                    priority: .medium,
                    category: .optimization,
                    targetEntityType: "Task",
                    targetEntityId: pattern.taskId,
                    actionRecommendations: pattern.recommendations,
                    supportingData: [
                        "inefficiencyScore": pattern.inefficiencyScore,
                        "patternType": pattern.type,
                        "frequency": pattern.frequency
                    ],
                    createdAt: Date(),
                    expiresAt: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                    isActionTaken: false,
                    feedback: nil,
                    tags: ["task", "optimization", "workflow"]
                )
                
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    // MARK: - ML Model Operations
    
    private func setupMLModels() {
        Task {
            await loadMLModels()
        }
    }
    
    private func loadMLModels() async {
        do {
            // Load document classification model
            if let modelURL = Bundle.main.url(forResource: "DocumentClassifier", withExtension: "mlmodelc") {
                documentClassificationModel = try MLModel(contentsOf: modelURL)
                logger.info("Loaded document classification model")
            }
            
            // Load performance prediction model
            if let modelURL = Bundle.main.url(forResource: "PerformancePredictor", withExtension: "mlmodelc") {
                performancePredictionModel = try MLModel(contentsOf: modelURL)
                logger.info("Loaded performance prediction model")
            }
            
            // Load risk assessment model
            if let modelURL = Bundle.main.url(forResource: "RiskAssessment", withExtension: "mlmodelc") {
                riskAssessmentModel = try MLModel(contentsOf: modelURL)
                logger.info("Loaded risk assessment model")
            }
            
        } catch {
            logger.error("Failed to load ML models: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Background Processing
    
    private func startBackgroundProcessing() {
        // Process insights every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.generateInsights()
                }
            }
            .store(in: &cancellables)
        
        // Update analytics daily
        Timer.publish(every: 86400, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    let period = DateInterval(start: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(), end: Date())
                    await self?.generateAnalytics(period: period)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func fetchInsights(for role: UserRole) async throws -> [AIInsight] {
        let predicate = NSPredicate(format: "expiresAt == NULL OR expiresAt > %@", Date() as NSDate)
        let query = CKQuery(recordType: "AIInsight", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (records, _) = try await database.records(matching: query)
        
        return records.compactMapValues { record in
            AIInsight.fromCKRecord(record)
        }.values.map { $0 }
    }
    
    private func saveInsights(_ insights: [AIInsight]) async throws {
        let records = insights.map { $0.toCKRecord() }
        let (results, _) = try await database.modifyRecords(saving: records, deleting: [])
        
        for (recordID, result) in results {
            switch result {
            case .success:
                logger.debug("Saved insight: \(recordID.recordName)")
            case .failure(let error):
                logger.error("Failed to save insight \(recordID.recordName): \(error.localizedDescription)")
            }
        }
    }
    
    private func updateInsight(_ insight: AIInsight) async throws {
        let record = insight.toCKRecord()
        try await database.save(record)
    }
    
    private func recordInteraction(_ interaction: InsightInteraction) async throws {
        let record = CKRecord(recordType: "InsightInteraction")
        record["insightId"] = interaction.insightId
        record["userId"] = interaction.userId
        record["interactionType"] = interaction.interactionType.rawValue
        record["timestamp"] = interaction.timestamp
        record["durationSeconds"] = interaction.durationSeconds
        
        if let metadataData = try? JSONEncoder().encode(interaction.metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            record["metadata"] = metadataString
        }
        
        try await database.save(record)
    }
    
    // MARK: - Placeholder ML Methods
    
    private func fetchRecentDocuments() async throws -> [DocumentModel] {
        // Implementation would fetch recent documents from DocumentService
        return []
    }
    
    private func findSimilarDocuments(to document: DocumentModel) async throws -> DocumentSimilarity? {
        // Implementation would use ML model to find similar documents
        return nil
    }
    
    private func predictSalesPerformance(for userId: String) async throws -> PerformancePrediction? {
        // Implementation would use ML model for sales prediction
        return nil
    }
    
    private func predictTaskCompletion(for userId: String) async throws -> PerformancePrediction? {
        // Implementation would use ML model for task completion prediction
        return nil
    }
    
    private func assessComplianceRisks() async throws -> [AIInsight] {
        // Implementation would assess compliance risks
        return []
    }
    
    private func assessPerformanceRisks() async throws -> [AIInsight] {
        // Implementation would assess performance risks
        return []
    }
    
    private func analyzeTaskPatterns() async throws -> [TaskPattern] {
        // Implementation would analyze task patterns
        return []
    }
    
    private func calculateInsightAnalytics(for period: DateInterval) async throws -> InsightAnalytics {
        // Implementation would calculate comprehensive analytics
        return InsightAnalytics(
            totalInsights: insights.count,
            insightsByType: [:],
            insightsByPriority: [:],
            averageConfidence: 0.0,
            actionTakenRate: 0.0,
            userFeedbackAverage: 0.0,
            topCategories: [],
            periodStart: period.start,
            periodEnd: period.end
        )
    }
    
    private func createPerformancePredictionInsight(prediction: PerformancePrediction) -> AIInsight {
        return AIInsight(
            id: UUID().uuidString,
            type: .performancePrediction,
            title: "Performance Prediction Available",
            description: "Based on your recent activity, we predict your \(prediction.predictionType.rawValue.lowercased()) performance.",
            confidence: prediction.confidence,
            priority: prediction.confidence > 0.8 ? .high : .medium,
            category: .prediction,
            targetEntityType: prediction.entityType,
            targetEntityId: prediction.entityId,
            actionRecommendations: [],
            supportingData: [
                "predictedValue": prediction.predictedValue,
                "timeframe": prediction.timeframe.rawValue
            ],
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            isActionTaken: false,
            feedback: nil,
            tags: ["prediction", "performance"]
        )
    }
    
    private func createTaskCompletionInsight(prediction: PerformancePrediction) -> AIInsight {
        return AIInsight(
            id: UUID().uuidString,
            type: .taskOptimization,
            title: "Task Completion Prediction",
            description: "Based on your patterns, we predict you'll complete \(Int(prediction.predictedValue))% of upcoming tasks on time.",
            confidence: prediction.confidence,
            priority: prediction.predictedValue < 0.8 ? .high : .medium,
            category: .prediction,
            targetEntityType: "Task",
            targetEntityId: prediction.entityId,
            actionRecommendations: [],
            supportingData: [
                "completionRate": prediction.predictedValue,
                "timeframe": prediction.timeframe.rawValue
            ],
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            isActionTaken: false,
            feedback: nil,
            tags: ["task", "completion", "prediction"]
        )
    }
}

// MARK: - Supporting Types

struct TaskPattern {
    let taskId: String
    let type: String
    let inefficiencyScore: Double
    let confidence: Double
    let frequency: Int
    let recommendations: [ActionRecommendation]
}

// MARK: - Error Types

enum AIInsightsError: LocalizedError {
    case failedToLoad(Error)
    case failedToGenerate(Error)
    case failedToUpdate(Error)
    case mlModelNotAvailable
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .failedToLoad(let error):
            return "Failed to load insights: \(error.localizedDescription)"
        case .failedToGenerate(let error):
            return "Failed to generate insights: \(error.localizedDescription)"
        case .failedToUpdate(let error):
            return "Failed to update insight: \(error.localizedDescription)"
        case .mlModelNotAvailable:
            return "Machine learning model not available"
        case .insufficientData:
            return "Insufficient data for analysis"
        }
    }
}
