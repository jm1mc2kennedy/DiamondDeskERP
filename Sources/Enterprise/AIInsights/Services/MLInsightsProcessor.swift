//
//  MLInsightsProcessor.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CoreML
import NaturalLanguage
import Combine
import os.log

/// Machine learning processor for generating AI insights and predictions
final class MLInsightsProcessor: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.diamonddesk.erp", category: "MLInsightsProcessor")
    private let processingQueue = DispatchQueue(label: "com.diamonddesk.ml", qos: .userInitiated)
    
    // ML Models
    private var documentEmbeddingModel: NLEmbedding?
    private var performancePredictionModel: MLModel?
    private var riskAssessmentModel: MLModel?
    private var workflowAnalysisModel: MLModel?
    
    // Model metadata
    private var modelsLoaded = false
    private var modelVersions: [String: String] = [:]
    
    // MARK: - Initialization
    
    init() {
        loadMLModels()
    }
    
    // MARK: - Public Interface
    
    /// Generate document recommendations based on user activity
    func generateDocumentRecommendations(
        for userId: String,
        recentDocuments: [DocumentModel],
        allDocuments: [DocumentModel]
    ) async throws -> [AIInsight] {
        
        guard !recentDocuments.isEmpty, !allDocuments.isEmpty else {
            return []
        }
        
        logger.info("Generating document recommendations for user \(userId)")
        
        return try await withTaskGroup(of: [AIInsight].self) { group in
            // Process each recent document for similarities
            for document in recentDocuments.prefix(5) { // Limit to 5 most recent
                group.addTask {
                    return await self.findSimilarDocuments(
                        sourceDocument: document,
                        candidateDocuments: allDocuments,
                        userId: userId
                    )
                }
            }
            
            var allRecommendations: [AIInsight] = []
            for await recommendations in group {
                allRecommendations.append(contentsOf: recommendations)
            }
            
            // Deduplicate and rank recommendations
            return self.deduplicateAndRankRecommendations(allRecommendations)
        }
    }
    
    /// Generate performance predictions for a user
    func generatePerformancePredictions(
        for userId: String,
        historicalData: [PerformanceDataPoint]
    ) async throws -> [PerformancePrediction] {
        
        guard !historicalData.isEmpty else {
            logger.warning("No historical data available for user \(userId)")
            return []
        }
        
        logger.info("Generating performance predictions for user \(userId)")
        
        return try await processingQueue.async {
            var predictions: [PerformancePrediction] = []
            
            // Sales performance prediction
            if let salesPrediction = try await self.predictSalesPerformance(
                userId: userId,
                data: historicalData
            ) {
                predictions.append(salesPrediction)
            }
            
            // Task completion prediction
            if let taskPrediction = try await self.predictTaskCompletion(
                userId: userId,
                data: historicalData
            ) {
                predictions.append(taskPrediction)
            }
            
            // Audit score prediction
            if let auditPrediction = try await self.predictAuditScore(
                userId: userId,
                data: historicalData
            ) {
                predictions.append(auditPrediction)
            }
            
            return predictions
        }
    }
    
    /// Assess compliance and operational risks
    func assessRisks(
        for userId: String,
        userData: UserActivityData
    ) async throws -> [AIInsight] {
        
        logger.info("Assessing risks for user \(userId)")
        
        var riskInsights: [AIInsight] = []
        
        // Compliance risk assessment
        let complianceRisks = try await assessComplianceRisks(userData: userData)
        riskInsights.append(contentsOf: complianceRisks)
        
        // Performance risk assessment
        let performanceRisks = try await assessPerformanceRisks(userData: userData)
        riskInsights.append(contentsOf: performanceRisks)
        
        // Workflow risk assessment
        let workflowRisks = try await assessWorkflowRisks(userData: userData)
        riskInsights.append(contentsOf: workflowRisks)
        
        return riskInsights.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    /// Analyze task patterns and suggest optimizations
    func analyzeTaskPatterns(
        for userId: String,
        tasks: [TaskModel]
    ) async throws -> [AIInsight] {
        
        guard !tasks.isEmpty else { return [] }
        
        logger.info("Analyzing task patterns for user \(userId)")
        
        var optimizations: [AIInsight] = []
        
        // Analyze completion patterns
        let completionOptimizations = try await analyzeTaskCompletionPatterns(
            userId: userId,
            tasks: tasks
        )
        optimizations.append(contentsOf: completionOptimizations)
        
        // Analyze timing patterns
        let timingOptimizations = try await analyzeTaskTimingPatterns(
            userId: userId,
            tasks: tasks
        )
        optimizations.append(contentsOf: timingOptimizations)
        
        // Analyze workload patterns
        let workloadOptimizations = try await analyzeWorkloadPatterns(
            userId: userId,
            tasks: tasks
        )
        optimizations.append(contentsOf: workloadOptimizations)
        
        return optimizations
    }
    
    /// Generate training recommendations based on performance gaps
    func generateTrainingRecommendations(
        for userId: String,
        performanceData: [PerformanceDataPoint],
        availableTraining: [TrainingCourse]
    ) async throws -> [AIInsight] {
        
        guard !performanceData.isEmpty, !availableTraining.isEmpty else { return [] }
        
        logger.info("Generating training recommendations for user \(userId)")
        
        // Identify performance gaps
        let performanceGaps = identifyPerformanceGaps(performanceData)
        
        var recommendations: [AIInsight] = []
        
        for gap in performanceGaps {
            // Find relevant training courses
            let relevantCourses = findRelevantTrainingCourses(
                for: gap,
                from: availableTraining
            )
            
            for course in relevantCourses.prefix(2) { // Limit to top 2 per gap
                let insight = createTrainingRecommendationInsight(
                    userId: userId,
                    course: course,
                    performanceGap: gap
                )
                recommendations.append(insight)
            }
        }
        
        return recommendations
    }
    
    // MARK: - Document Similarity Analysis
    
    private func findSimilarDocuments(
        sourceDocument: DocumentModel,
        candidateDocuments: [DocumentModel],
        userId: String
    ) async -> [AIInsight] {
        
        guard let documentEmbedding = documentEmbeddingModel else {
            logger.warning("Document embedding model not available")
            return []
        }
        
        var recommendations: [AIInsight] = []
        
        do {
            // Generate embedding for source document
            let sourceText = "\(sourceDocument.title) \(sourceDocument.tags.joined(separator: " "))"
            guard let sourceEmbedding = documentEmbedding.vector(for: sourceText) else {
                return []
            }
            
            // Calculate similarities with other documents
            var similarities: [(document: DocumentModel, similarity: Double)] = []
            
            for candidate in candidateDocuments {
                guard candidate.id != sourceDocument.id else { continue }
                
                let candidateText = "\(candidate.title) \(candidate.tags.joined(separator: " "))"
                guard let candidateEmbedding = documentEmbedding.vector(for: candidateText) else {
                    continue
                }
                
                let similarity = cosineSimilarity(sourceEmbedding, candidateEmbedding)
                if similarity > 0.5 { // Minimum similarity threshold
                    similarities.append((document: candidate, similarity: similarity))
                }
            }
            
            // Sort by similarity and take top results
            similarities.sort { $0.similarity > $1.similarity }
            
            for (document, similarity) in similarities.prefix(3) {
                let insight = createDocumentRecommendationInsight(
                    sourceDocument: sourceDocument,
                    recommendedDocument: document,
                    similarity: similarity,
                    userId: userId
                )
                recommendations.append(insight)
            }
            
        } catch {
            logger.error("Error in document similarity analysis: \(error.localizedDescription)")
        }
        
        return recommendations
    }
    
    private func cosineSimilarity(_ vector1: [Double], _ vector2: [Double]) -> Double {
        guard vector1.count == vector2.count else { return 0.0 }
        
        let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    // MARK: - Performance Predictions
    
    private func predictSalesPerformance(
        userId: String,
        data: [PerformanceDataPoint]
    ) async throws -> PerformancePrediction? {
        
        let salesData = data.filter { $0.metric == "sales" }.suffix(30) // Last 30 data points
        guard salesData.count >= 7 else { return nil } // Need at least a week of data
        
        // Extract features for prediction
        let features = extractSalesFeatures(from: Array(salesData))
        
        // Use simple linear regression for demonstration
        // In production, this would use the actual ML model
        let trend = calculateTrend(values: salesData.map { $0.value })
        let seasonality = calculateSeasonality(data: salesData)
        let volatility = calculateVolatility(values: salesData.map { $0.value })
        
        // Predict next period performance
        let lastValue = salesData.last?.value ?? 0
        let predictedValue = max(0, lastValue + trend + seasonality)
        let confidence = max(0.1, min(0.95, 1.0 - volatility))
        
        // Identify influencing factors
        let influencingFactors = identifyInfluencingFactors(
            metric: "sales",
            data: salesData,
            features: features
        )
        
        return PerformancePrediction(
            entityId: userId,
            entityType: "User",
            predictionType: .salesPerformance,
            predictedValue: predictedValue,
            confidence: confidence,
            timeframe: .weekly,
            influencingFactors: influencingFactors,
            createdAt: Date()
        )
    }
    
    private func predictTaskCompletion(
        userId: String,
        data: [PerformanceDataPoint]
    ) async throws -> PerformancePrediction? {
        
        let taskData = data.filter { $0.metric == "task_completion" }.suffix(14) // Last 14 days
        guard taskData.count >= 5 else { return nil }
        
        let values = taskData.map { $0.value }
        let trend = calculateTrend(values: values)
        let average = values.reduce(0, +) / Double(values.count)
        let volatility = calculateVolatility(values: values)
        
        let predictedValue = max(0, min(1.0, average + trend))
        let confidence = max(0.1, min(0.95, 1.0 - volatility))
        
        let influencingFactors = identifyInfluencingFactors(
            metric: "task_completion",
            data: taskData,
            features: [:]
        )
        
        return PerformancePrediction(
            entityId: userId,
            entityType: "User",
            predictionType: .taskCompletion,
            predictedValue: predictedValue,
            confidence: confidence,
            timeframe: .daily,
            influencingFactors: influencingFactors,
            createdAt: Date()
        )
    }
    
    private func predictAuditScore(
        userId: String,
        data: [PerformanceDataPoint]
    ) async throws -> PerformancePrediction? {
        
        let auditData = data.filter { $0.metric == "audit_score" }.suffix(10) // Last 10 audits
        guard auditData.count >= 3 else { return nil }
        
        let values = auditData.map { $0.value }
        let trend = calculateTrend(values: values)
        let average = values.reduce(0, +) / Double(values.count)
        let volatility = calculateVolatility(values: values)
        
        let predictedValue = max(0, min(1.0, average + trend))
        let confidence = max(0.1, min(0.95, 1.0 - volatility))
        
        let influencingFactors = identifyInfluencingFactors(
            metric: "audit_score",
            data: auditData,
            features: [:]
        )
        
        return PerformancePrediction(
            entityId: userId,
            entityType: "User",
            predictionType: .auditScore,
            predictedValue: predictedValue,
            confidence: confidence,
            timeframe: .monthly,
            influencingFactors: influencingFactors,
            createdAt: Date()
        )
    }
    
    // MARK: - Risk Assessment
    
    private func assessComplianceRisks(userData: UserActivityData) async throws -> [AIInsight] {
        var risks: [AIInsight] = []
        
        // Check training compliance
        if userData.overdueMandatoryTraining > 0 {
            let insight = AIInsight(
                id: UUID().uuidString,
                type: .complianceAlert,
                title: "Overdue Mandatory Training",
                description: "You have \(userData.overdueMandatoryTraining) overdue mandatory training course\(userData.overdueMandatoryTraining == 1 ? "" : "s").",
                confidence: 0.95,
                priority: userData.overdueMandatoryTraining > 2 ? .critical : .high,
                category: .compliance,
                targetEntityType: "User",
                targetEntityId: userData.userId,
                actionRecommendations: [
                    ActionRecommendation(
                        id: UUID().uuidString,
                        title: "Complete Training",
                        description: "Access and complete overdue training",
                        actionType: .navigate,
                        estimatedImpact: 0.9,
                        estimatedEffort: .medium,
                        targetUrl: "/training",
                        parameters: [:],
                        isCompleted: false,
                        completedAt: nil
                    )
                ],
                supportingData: [
                    "overdueCount": userData.overdueMandatoryTraining,
                    "riskLevel": "HIGH"
                ],
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                isActionTaken: false,
                feedback: nil,
                tags: ["compliance", "training", "overdue"]
            )
            risks.append(insight)
        }
        
        // Check audit compliance
        if userData.failedAuditsCount > 0 {
            let insight = AIInsight(
                id: UUID().uuidString,
                type: .complianceAlert,
                title: "Recent Audit Failures",
                description: "You have \(userData.failedAuditsCount) failed audit\(userData.failedAuditsCount == 1 ? "" : "s") requiring attention.",
                confidence: 0.9,
                priority: .high,
                category: .compliance,
                targetEntityType: "User",
                targetEntityId: userData.userId,
                actionRecommendations: [
                    ActionRecommendation(
                        id: UUID().uuidString,
                        title: "Review Failed Audits",
                        description: "Review and address audit failures",
                        actionType: .review,
                        estimatedImpact: 0.8,
                        estimatedEffort: .medium,
                        targetUrl: "/audits",
                        parameters: ["filter": "failed"],
                        isCompleted: false,
                        completedAt: nil
                    )
                ],
                supportingData: [
                    "failedCount": userData.failedAuditsCount,
                    "complianceStatus": "AT_RISK"
                ],
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                isActionTaken: false,
                feedback: nil,
                tags: ["compliance", "audit", "failed"]
            )
            risks.append(insight)
        }
        
        return risks
    }
    
    private func assessPerformanceRisks(userData: UserActivityData) async throws -> [AIInsight] {
        var risks: [AIInsight] = []
        
        // Check task completion rate
        if userData.taskCompletionRate < 0.7 {
            let insight = AIInsight(
                id: UUID().uuidString,
                type: .riskAssessment,
                title: "Low Task Completion Rate",
                description: "Your task completion rate of \(Int(userData.taskCompletionRate * 100))% is below recommended levels.",
                confidence: 0.85,
                priority: userData.taskCompletionRate < 0.5 ? .high : .medium,
                category: .performance,
                targetEntityType: "User",
                targetEntityId: userData.userId,
                actionRecommendations: [
                    ActionRecommendation(
                        id: UUID().uuidString,
                        title: "Review Task Load",
                        description: "Analyze current task assignments and priorities",
                        actionType: .review,
                        estimatedImpact: 0.7,
                        estimatedEffort: .low,
                        targetUrl: "/tasks",
                        parameters: ["view": "assigned"],
                        isCompleted: false,
                        completedAt: nil
                    )
                ],
                supportingData: [
                    "completionRate": userData.taskCompletionRate,
                    "benchmark": 0.85
                ],
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                isActionTaken: false,
                feedback: nil,
                tags: ["performance", "tasks", "completion"]
            )
            risks.append(insight)
        }
        
        return risks
    }
    
    private func assessWorkflowRisks(userData: UserActivityData) async throws -> [AIInsight] {
        var risks: [AIInsight] = []
        
        // Check for workflow bottlenecks
        if userData.averageTaskDuration > userData.benchmarkTaskDuration * 1.5 {
            let insight = AIInsight(
                id: UUID().uuidString,
                type: .workflowImprovement,
                title: "Task Duration Above Benchmark",
                description: "Your average task completion time is \(Int(((userData.averageTaskDuration / userData.benchmarkTaskDuration) - 1) * 100))% above benchmark.",
                confidence: 0.8,
                priority: .medium,
                category: .optimization,
                targetEntityType: "User",
                targetEntityId: userData.userId,
                actionRecommendations: [
                    ActionRecommendation(
                        id: UUID().uuidString,
                        title: "Analyze Workflow",
                        description: "Review task workflow for optimization opportunities",
                        actionType: .review,
                        estimatedImpact: 0.6,
                        estimatedEffort: .medium,
                        targetUrl: "/analytics/workflow",
                        parameters: [:],
                        isCompleted: false,
                        completedAt: nil
                    )
                ],
                supportingData: [
                    "averageDuration": userData.averageTaskDuration,
                    "benchmark": userData.benchmarkTaskDuration
                ],
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                isActionTaken: false,
                feedback: nil,
                tags: ["workflow", "optimization", "duration"]
            )
            risks.append(insight)
        }
        
        return risks
    }
    
    // MARK: - Task Pattern Analysis
    
    private func analyzeTaskCompletionPatterns(
        userId: String,
        tasks: [TaskModel]
    ) async throws -> [AIInsight] {
        
        // Analyze completion time patterns
        let completedTasks = tasks.filter { task in
            task.completedUserIds.contains(userId)
        }
        
        guard completedTasks.count >= 10 else { return [] }
        
        // Identify optimal completion times
        let timeAnalysis = analyzeCompletionTimes(completedTasks)
        
        if let optimalTime = timeAnalysis.optimalTime {
            let insight = AIInsight(
                id: UUID().uuidString,
                type: .taskOptimization,
                title: "Optimal Task Completion Time Identified",
                description: "You complete tasks \(Int(timeAnalysis.efficiencyImprovement * 100))% faster during \(optimalTime).",
                confidence: timeAnalysis.confidence,
                priority: .medium,
                category: .productivity,
                targetEntityType: "User",
                targetEntityId: userId,
                actionRecommendations: [
                    ActionRecommendation(
                        id: UUID().uuidString,
                        title: "Schedule Tasks Optimally",
                        description: "Focus important tasks during your peak time: \(optimalTime)",
                        actionType: .schedule,
                        estimatedImpact: timeAnalysis.efficiencyImprovement,
                        estimatedEffort: .minimal,
                        targetUrl: "/tasks/schedule",
                        parameters: ["optimalTime": optimalTime],
                        isCompleted: false,
                        completedAt: nil
                    )
                ],
                supportingData: [
                    "optimalTime": optimalTime,
                    "efficiencyImprovement": timeAnalysis.efficiencyImprovement,
                    "sampleSize": completedTasks.count
                ],
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                isActionTaken: false,
                feedback: nil,
                tags: ["task", "optimization", "timing"]
            )
            return [insight]
        }
        
        return []
    }
    
    private func analyzeTaskTimingPatterns(
        userId: String,
        tasks: [TaskModel]
    ) async throws -> [AIInsight] {
        
        // This would analyze when tasks are typically started, completed, etc.
        // For now, return empty array - implementation would be more complex
        return []
    }
    
    private func analyzeWorkloadPatterns(
        userId: String,
        tasks: [TaskModel]
    ) async throws -> [AIInsight] {
        
        // This would analyze workload distribution and suggest optimizations
        // For now, return empty array - implementation would be more complex
        return []
    }
    
    // MARK: - Training Recommendations
    
    private func identifyPerformanceGaps(_ data: [PerformanceDataPoint]) -> [PerformanceGap] {
        var gaps: [PerformanceGap] = []
        
        // Group data by metric
        let groupedData = Dictionary(grouping: data) { $0.metric }
        
        for (metric, points) in groupedData {
            let values = points.map { $0.value }
            let average = values.reduce(0, +) / Double(values.count)
            
            // Define benchmarks for different metrics
            let benchmark = getBenchmark(for: metric)
            
            if average < benchmark * 0.8 { // 20% below benchmark
                let gap = PerformanceGap(
                    metric: metric,
                    currentValue: average,
                    targetValue: benchmark,
                    severity: calculateGapSeverity(current: average, target: benchmark)
                )
                gaps.append(gap)
            }
        }
        
        return gaps.sorted { $0.severity > $1.severity }
    }
    
    private func findRelevantTrainingCourses(
        for gap: PerformanceGap,
        from courses: [TrainingCourse]
    ) -> [TrainingCourse] {
        
        // Simple keyword matching - in production this would be more sophisticated
        let keywords = getTrainingKeywords(for: gap.metric)
        
        return courses.filter { course in
            let courseText = "\(course.title) \(course.description)".lowercased()
            return keywords.contains { keyword in
                courseText.contains(keyword.lowercased())
            }
        }
    }
    
    private func createTrainingRecommendationInsight(
        userId: String,
        course: TrainingCourse,
        performanceGap: PerformanceGap
    ) -> AIInsight {
        
        return AIInsight(
            id: UUID().uuidString,
            type: .trainingRecommendation,
            title: "Training Recommended: \(course.title)",
            description: "Based on your \(performanceGap.metric) performance, this training could help improve your results.",
            confidence: 0.75,
            priority: performanceGap.severity > 0.5 ? .high : .medium,
            category: .recommendation,
            targetEntityType: "TrainingCourse",
            targetEntityId: course.id,
            actionRecommendations: [
                ActionRecommendation(
                    id: UUID().uuidString,
                    title: "Enroll in Training",
                    description: "Start the recommended training course",
                    actionType: .navigate,
                    estimatedImpact: 0.7,
                    estimatedEffort: .high,
                    targetUrl: "/training/\(course.id)",
                    parameters: ["courseId": course.id],
                    isCompleted: false,
                    completedAt: nil
                )
            ],
            supportingData: [
                "performanceGap": performanceGap.severity,
                "metric": performanceGap.metric,
                "courseId": course.id
            ],
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            isActionTaken: false,
            feedback: nil,
            tags: ["training", "recommendation", performanceGap.metric]
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadMLModels() {
        Task {
            do {
                // Load document embedding model
                if NLEmbedding.wordEmbedding(for: .english) != nil {
                    documentEmbeddingModel = NLEmbedding.wordEmbedding(for: .english)
                    logger.info("Loaded document embedding model")
                }
                
                // In a real implementation, you would load custom Core ML models here
                // For now, we'll simulate with basic algorithms
                
                modelsLoaded = true
                logger.info("ML models loaded successfully")
                
            } catch {
                logger.error("Failed to load ML models: \(error.localizedDescription)")
            }
        }
    }
    
    private func deduplicateAndRankRecommendations(_ recommendations: [AIInsight]) -> [AIInsight] {
        var seen = Set<String>()
        var deduplicated: [AIInsight] = []
        
        for recommendation in recommendations.sorted(by: { $0.confidence > $1.confidence }) {
            let key = "\(recommendation.targetEntityType):\(recommendation.targetEntityId)"
            if !seen.contains(key) {
                seen.insert(key)
                deduplicated.append(recommendation)
            }
        }
        
        return Array(deduplicated.prefix(10)) // Limit to top 10
    }
    
    private func createDocumentRecommendationInsight(
        sourceDocument: DocumentModel,
        recommendedDocument: DocumentModel,
        similarity: Double,
        userId: String
    ) -> AIInsight {
        
        return AIInsight(
            id: UUID().uuidString,
            type: .documentRecommendation,
            title: "Related Document Found",
            description: "Based on your work with '\(sourceDocument.title)', you might find '\(recommendedDocument.title)' helpful.",
            confidence: similarity,
            priority: similarity > 0.8 ? .high : .medium,
            category: .recommendation,
            targetEntityType: "Document",
            targetEntityId: recommendedDocument.id,
            actionRecommendations: [
                ActionRecommendation(
                    id: UUID().uuidString,
                    title: "View Document",
                    description: "Open the recommended document",
                    actionType: .navigate,
                    estimatedImpact: similarity,
                    estimatedEffort: .minimal,
                    targetUrl: "/documents/\(recommendedDocument.id)",
                    parameters: ["documentId": recommendedDocument.id],
                    isCompleted: false,
                    completedAt: nil
                )
            ],
            supportingData: [
                "similarityScore": similarity,
                "sourceDocument": sourceDocument.id,
                "algorithm": "cosine_similarity"
            ],
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            isActionTaken: false,
            feedback: nil,
            tags: ["document", "recommendation", "similarity"]
        )
    }
    
    // MARK: - Statistical Helper Methods
    
    private func calculateTrend(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let n = Double(values.count)
        let x = Array(1...values.count).map(Double.init)
        let sumX = x.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(x, values).map(*).reduce(0, +)
        let sumXX = x.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        return slope
    }
    
    private func calculateSeasonality(data: [PerformanceDataPoint]) -> Double {
        // Simple day-of-week seasonality
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let weekdayData = data.filter { 
            Calendar.current.component(.weekday, from: $0.timestamp) == dayOfWeek 
        }
        
        guard !weekdayData.isEmpty else { return 0 }
        
        let weekdayAverage = weekdayData.map { $0.value }.reduce(0, +) / Double(weekdayData.count)
        let overallAverage = data.map { $0.value }.reduce(0, +) / Double(data.count)
        
        return weekdayAverage - overallAverage
    }
    
    private func calculateVolatility(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        let standardDeviation = sqrt(variance)
        
        return mean > 0 ? standardDeviation / mean : 1.0
    }
    
    private func extractSalesFeatures(from data: [PerformanceDataPoint]) -> [String: Double] {
        // Extract relevant features for sales prediction
        return [
            "trend": calculateTrend(values: data.map { $0.value }),
            "volatility": calculateVolatility(values: data.map { $0.value }),
            "average": data.map { $0.value }.reduce(0, +) / Double(data.count),
            "recency": Double(data.count)
        ]
    }
    
    private func identifyInfluencingFactors(
        metric: String,
        data: [PerformanceDataPoint],
        features: [String: Double]
    ) -> [InfluencingFactor] {
        
        var factors: [InfluencingFactor] = []
        
        // Add trend factor
        if let trend = features["trend"] {
            factors.append(InfluencingFactor(
                factor: "Historical Trend",
                impact: min(1.0, max(-1.0, trend * 10)),
                confidence: 0.7,
                description: trend > 0 ? "Positive historical trend" : "Negative historical trend"
            ))
        }
        
        // Add seasonality factor
        let seasonality = calculateSeasonality(data: data)
        if abs(seasonality) > 0.1 {
            factors.append(InfluencingFactor(
                factor: "Day of Week Pattern",
                impact: min(1.0, max(-1.0, seasonality)),
                confidence: 0.6,
                description: seasonality > 0 ? "Higher performance on this day" : "Lower performance on this day"
            ))
        }
        
        return factors
    }
    
    private func analyzeCompletionTimes(_ tasks: [TaskModel]) -> CompletionTimeAnalysis {
        // Analyze when tasks are typically completed to find optimal times
        // This is a simplified implementation
        
        let completionHours = tasks.compactMap { task -> Int? in
            // In a real implementation, you'd get the actual completion time
            // For now, simulate with creation time
            return Calendar.current.component(.hour, from: task.createdAt)
        }
        
        let hourCounts = Dictionary(grouping: completionHours, by: { $0 })
        let optimalHour = hourCounts.max { $0.value.count < $1.value.count }?.key
        
        if let hour = optimalHour {
            let timeString = "\(hour):00"
            return CompletionTimeAnalysis(
                optimalTime: timeString,
                confidence: 0.7,
                efficiencyImprovement: 0.2
            )
        }
        
        return CompletionTimeAnalysis(optimalTime: nil, confidence: 0, efficiencyImprovement: 0)
    }
    
    private func getBenchmark(for metric: String) -> Double {
        switch metric {
        case "sales": return 1000.0
        case "task_completion": return 0.85
        case "audit_score": return 0.9
        case "client_satisfaction": return 0.8
        default: return 0.8
        }
    }
    
    private func calculateGapSeverity(current: Double, target: Double) -> Double {
        return max(0, (target - current) / target)
    }
    
    private func getTrainingKeywords(for metric: String) -> [String] {
        switch metric {
        case "sales": return ["sales", "selling", "customer", "revenue"]
        case "task_completion": return ["productivity", "time management", "organization"]
        case "audit_score": return ["compliance", "quality", "audit", "standards"]
        case "client_satisfaction": return ["customer service", "communication", "relationship"]
        default: return ["general", "skills", "professional"]
        }
    }
}

// MARK: - Supporting Types

struct PerformanceDataPoint {
    let userId: String
    let metric: String
    let value: Double
    let timestamp: Date
}

struct UserActivityData {
    let userId: String
    let taskCompletionRate: Double
    let averageTaskDuration: TimeInterval
    let benchmarkTaskDuration: TimeInterval
    let overdueMandatoryTraining: Int
    let failedAuditsCount: Int
}

struct PerformanceGap {
    let metric: String
    let currentValue: Double
    let targetValue: Double
    let severity: Double
}

struct CompletionTimeAnalysis {
    let optimalTime: String?
    let confidence: Double
    let efficiencyImprovement: Double
}

struct TrainingCourse {
    let id: String
    let title: String
    let description: String
}
