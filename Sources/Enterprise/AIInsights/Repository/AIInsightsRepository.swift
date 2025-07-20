//
//  AIInsightsRepository.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit
import Combine
import os.log

/// Repository for managing AI insights data persistence and CloudKit operations
final class AIInsightsRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let container: CKContainer
    private let database: CKDatabase
    private let logger = Logger(subsystem: "com.diamonddesk.erp", category: "AIInsightsRepository")
    
    // MARK: - Initialization
    
    init() {
        self.container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
        self.database = container.privateCloudDatabase
    }
    
    // MARK: - Insights CRUD Operations
    
    /// Fetch insights with filtering and pagination
    func fetchInsights(
        userId: String,
        types: [InsightType]? = nil,
        priorities: [InsightPriority]? = nil,
        categories: [InsightCategory]? = nil,
        limit: Int = 50,
        cursor: CKQueryOperation.Cursor? = nil
    ) async throws -> (insights: [AIInsight], cursor: CKQueryOperation.Cursor?) {
        
        var predicates: [NSPredicate] = []
        
        // Base predicate for active insights
        predicates.append(NSPredicate(format: "expiresAt == NULL OR expiresAt > %@", Date() as NSDate))
        
        // Filter by types
        if let types = types, !types.isEmpty {
            let typeStrings = types.map { $0.rawValue }
            predicates.append(NSPredicate(format: "type IN %@", typeStrings))
        }
        
        // Filter by priorities
        if let priorities = priorities, !priorities.isEmpty {
            let priorityStrings = priorities.map { $0.rawValue }
            predicates.append(NSPredicate(format: "priority IN %@", priorityStrings))
        }
        
        // Filter by categories
        if let categories = categories, !categories.isEmpty {
            let categoryStrings = categories.map { $0.rawValue }
            predicates.append(NSPredicate(format: "category IN %@", categoryStrings))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: "AIInsight", predicate: compoundPredicate)
        
        // Sort by priority and creation date
        query.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = limit
        operation.cursor = cursor
        
        return try await withCheckedThrowingContinuation { continuation in
            var insights: [AIInsight] = []
            var resultCursor: CKQueryOperation.Cursor?
            
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let insight = AIInsight.fromCKRecord(record) {
                        insights.append(insight)
                    }
                case .failure(let error):
                    self.logger.error("Failed to process insight record \(recordID.recordName): \(error.localizedDescription)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    resultCursor = cursor
                    continuation.resume(returning: (insights: insights, cursor: resultCursor))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    /// Save a single insight
    func saveInsight(_ insight: AIInsight) async throws -> AIInsight {
        let record = insight.toCKRecord()
        let savedRecord = try await database.save(record)
        
        guard let savedInsight = AIInsight.fromCKRecord(savedRecord) else {
            throw AIInsightsRepositoryError.invalidRecord
        }
        
        logger.info("Saved insight: \(savedInsight.id)")
        return savedInsight
    }
    
    /// Save multiple insights in batch
    func saveInsights(_ insights: [AIInsight]) async throws -> [AIInsight] {
        let records = insights.map { $0.toCKRecord() }
        let (savedRecordsResult, _) = try await database.modifyRecords(saving: records, deleting: [])
        
        var savedInsights: [AIInsight] = []
        
        for (recordID, result) in savedRecordsResult {
            switch result {
            case .success(let record):
                if let insight = AIInsight.fromCKRecord(record) {
                    savedInsights.append(insight)
                    logger.debug("Saved insight: \(recordID.recordName)")
                }
            case .failure(let error):
                logger.error("Failed to save insight \(recordID.recordName): \(error.localizedDescription)")
            }
        }
        
        logger.info("Saved \(savedInsights.count)/\(insights.count) insights")
        return savedInsights
    }
    
    /// Update an existing insight
    func updateInsight(_ insight: AIInsight) async throws -> AIInsight {
        let record = insight.toCKRecord()
        let updatedRecord = try await database.save(record)
        
        guard let updatedInsight = AIInsight.fromCKRecord(updatedRecord) else {
            throw AIInsightsRepositoryError.invalidRecord
        }
        
        logger.info("Updated insight: \(updatedInsight.id)")
        return updatedInsight
    }
    
    /// Delete an insight
    func deleteInsight(_ insightId: String) async throws {
        let recordID = CKRecord.ID(recordName: insightId)
        try await database.deleteRecord(withID: recordID)
        logger.info("Deleted insight: \(insightId)")
    }
    
    /// Fetch a specific insight by ID
    func fetchInsight(id: String) async throws -> AIInsight? {
        let recordID = CKRecord.ID(recordName: id)
        let record = try await database.record(for: recordID)
        return AIInsight.fromCKRecord(record)
    }
    
    // MARK: - Predictions CRUD Operations
    
    /// Save performance predictions
    func savePredictions(_ predictions: [PerformancePrediction]) async throws -> [PerformancePrediction] {
        let records = predictions.map { $0.toCKRecord() }
        let (savedRecordsResult, _) = try await database.modifyRecords(saving: records, deleting: [])
        
        var savedPredictions: [PerformancePrediction] = []
        
        for (recordID, result) in savedRecordsResult {
            switch result {
            case .success(let record):
                if let prediction = PerformancePrediction.fromCKRecord(record) {
                    savedPredictions.append(prediction)
                    logger.debug("Saved prediction: \(recordID.recordName)")
                }
            case .failure(let error):
                logger.error("Failed to save prediction \(recordID.recordName): \(error.localizedDescription)")
            }
        }
        
        return savedPredictions
    }
    
    /// Fetch predictions for an entity
    func fetchPredictions(
        entityId: String,
        entityType: String,
        predictionTypes: [PredictionType]? = nil
    ) async throws -> [PerformancePrediction] {
        
        var predicates = [
            NSPredicate(format: "entityId == %@", entityId),
            NSPredicate(format: "entityType == %@", entityType)
        ]
        
        if let types = predictionTypes, !types.isEmpty {
            let typeStrings = types.map { $0.rawValue }
            predicates.append(NSPredicate(format: "predictionType IN %@", typeStrings))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: "PerformancePrediction", predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (records, _) = try await database.records(matching: query)
        
        return records.compactMapValues { record in
            PerformancePrediction.fromCKRecord(record)
        }.values.map { $0 }
    }
    
    // MARK: - Interactions Tracking
    
    /// Record user interaction with insight
    func recordInteraction(_ interaction: InsightInteraction) async throws {
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
        logger.debug("Recorded interaction for insight: \(interaction.insightId)")
    }
    
    /// Fetch interactions for analytics
    func fetchInteractions(
        insightId: String? = nil,
        userId: String? = nil,
        dateRange: DateInterval? = nil
    ) async throws -> [InsightInteraction] {
        
        var predicates: [NSPredicate] = []
        
        if let insightId = insightId {
            predicates.append(NSPredicate(format: "insightId == %@", insightId))
        }
        
        if let userId = userId {
            predicates.append(NSPredicate(format: "userId == %@", userId))
        }
        
        if let dateRange = dateRange {
            predicates.append(NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", 
                                        dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        let predicate = predicates.isEmpty ? NSPredicate(value: true) : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: "InsightInteraction", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let (records, _) = try await database.records(matching: query)
        
        return records.compactMapValues { record -> InsightInteraction? in
            guard let insightId = record["insightId"] as? String,
                  let userId = record["userId"] as? String,
                  let interactionTypeString = record["interactionType"] as? String,
                  let interactionType = InteractionType(rawValue: interactionTypeString),
                  let timestamp = record["timestamp"] as? Date else {
                return nil
            }
            
            let durationSeconds = record["durationSeconds"] as? Double
            
            var metadata: [String: String] = [:]
            if let metadataString = record["metadata"] as? String,
               let metadataData = metadataString.data(using: .utf8) {
                metadata = (try? JSONDecoder().decode([String: String].self, from: metadataData)) ?? [:]
            }
            
            return InsightInteraction(
                insightId: insightId,
                userId: userId,
                interactionType: interactionType,
                timestamp: timestamp,
                durationSeconds: durationSeconds,
                metadata: metadata
            )
        }.values.map { $0 }
    }
    
    // MARK: - Analytics
    
    /// Calculate insight analytics for a period
    func calculateAnalytics(for period: DateInterval) async throws -> InsightAnalytics {
        // Fetch all insights in the period
        let insights = try await fetchInsightsInPeriod(period)
        
        // Fetch all interactions in the period
        let interactions = try await fetchInteractions(dateRange: period)
        
        // Calculate metrics
        let totalInsights = insights.count
        let insightsByType = Dictionary(grouping: insights, by: { $0.type })
            .mapValues { $0.count }
        let insightsByPriority = Dictionary(grouping: insights, by: { $0.priority })
            .mapValues { $0.count }
        
        let averageConfidence = insights.isEmpty ? 0.0 : insights.map { $0.confidence }.reduce(0, +) / Double(insights.count)
        
        let actionTakenCount = insights.filter { $0.isActionTaken }.count
        let actionTakenRate = totalInsights > 0 ? Double(actionTakenCount) / Double(totalInsights) : 0.0
        
        let feedbackInsights = insights.compactMap { $0.feedback }
        let userFeedbackAverage = feedbackInsights.isEmpty ? 0.0 : 
            feedbackInsights.map { Double($0.rating) }.reduce(0, +) / Double(feedbackInsights.count)
        
        let categoryCounts = Dictionary(grouping: insights, by: { $0.category })
            .mapValues { $0.count }
        let topCategories = categoryCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        return InsightAnalytics(
            totalInsights: totalInsights,
            insightsByType: insightsByType,
            insightsByPriority: insightsByPriority,
            averageConfidence: averageConfidence,
            actionTakenRate: actionTakenRate,
            userFeedbackAverage: userFeedbackAverage,
            topCategories: Array(topCategories),
            periodStart: period.start,
            periodEnd: period.end
        )
    }
    
    // MARK: - Training Data
    
    /// Save training data for ML models
    func saveTrainingData(_ trainingData: [MLTrainingData]) async throws {
        let records = trainingData.map { data in
            let record = CKRecord(recordType: "MLTrainingData")
            record["entityType"] = data.entityType
            record["entityId"] = data.entityId
            record["timestamp"] = data.timestamp
            record["target"] = data.target
            
            if let featuresData = try? JSONEncoder().encode(data.features),
               let featuresString = String(data: featuresData, encoding: .utf8) {
                record["features"] = featuresString
            }
            
            if let labelsData = try? JSONEncoder().encode(data.labels),
               let labelsString = String(data: labelsData, encoding: .utf8) {
                record["labels"] = labelsString
            }
            
            return record
        }
        
        let (results, _) = try await database.modifyRecords(saving: records, deleting: [])
        
        let successCount = results.values.compactMap { result in
            if case .success = result { return 1 } else { return nil }
        }.count
        
        logger.info("Saved \(successCount)/\(trainingData.count) training data records")
    }
    
    /// Fetch training data for model training
    func fetchTrainingData(
        entityType: String,
        dateRange: DateInterval? = nil,
        limit: Int = 1000
    ) async throws -> [MLTrainingData] {
        
        var predicates = [NSPredicate(format: "entityType == %@", entityType)]
        
        if let dateRange = dateRange {
            predicates.append(NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                        dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: "MLTrainingData", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = limit
        
        return try await withCheckedThrowingContinuation { continuation in
            var trainingData: [MLTrainingData] = []
            
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let data = self.parseTrainingDataRecord(record) {
                        trainingData.append(data)
                    }
                case .failure(let error):
                    self.logger.error("Failed to process training data record \(recordID.recordName): \(error.localizedDescription)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: trainingData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    // MARK: - Model Metrics
    
    /// Save model performance metrics
    func saveModelMetrics(_ metrics: MLModelMetrics) async throws {
        let record = CKRecord(recordType: "MLModelMetrics")
        record["modelName"] = metrics.modelName
        record["version"] = metrics.version
        record["accuracy"] = metrics.accuracy
        record["precision"] = metrics.precision
        record["recall"] = metrics.recall
        record["f1Score"] = metrics.f1Score
        record["meanAbsoluteError"] = metrics.meanAbsoluteError
        record["rootMeanSquareError"] = metrics.rootMeanSquareError
        record["trainingDataSize"] = metrics.trainingDataSize
        record["lastTrainedAt"] = metrics.lastTrainedAt
        record["evaluatedAt"] = metrics.evaluatedAt
        
        try await database.save(record)
        logger.info("Saved metrics for model: \(metrics.modelName) v\(metrics.version)")
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchInsightsInPeriod(_ period: DateInterval) async throws -> [AIInsight] {
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@",
                                   period.start as NSDate, period.end as NSDate)
        let query = CKQuery(recordType: "AIInsight", predicate: predicate)
        
        let (records, _) = try await database.records(matching: query)
        
        return records.compactMapValues { record in
            AIInsight.fromCKRecord(record)
        }.values.map { $0 }
    }
    
    private func parseTrainingDataRecord(_ record: CKRecord) -> MLTrainingData? {
        guard let entityType = record["entityType"] as? String,
              let entityId = record["entityId"] as? String,
              let timestamp = record["timestamp"] as? Date,
              let target = record["target"] as? Double else {
            return nil
        }
        
        var features: [String: Double] = [:]
        if let featuresString = record["features"] as? String,
           let featuresData = featuresString.data(using: .utf8) {
            features = (try? JSONDecoder().decode([String: Double].self, from: featuresData)) ?? [:]
        }
        
        var labels: [String] = []
        if let labelsString = record["labels"] as? String,
           let labelsData = labelsString.data(using: .utf8) {
            labels = (try? JSONDecoder().decode([String].self, from: labelsData)) ?? []
        }
        
        return MLTrainingData(
            id: record.recordID.recordName,
            features: features,
            target: target,
            entityType: entityType,
            entityId: entityId,
            timestamp: timestamp,
            labels: labels
        )
    }
}

// MARK: - Error Types

enum AIInsightsRepositoryError: LocalizedError {
    case invalidRecord
    case saveFailed
    case fetchFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidRecord:
            return "Invalid record format"
        case .saveFailed:
            return "Failed to save record"
        case .fetchFailed:
            return "Failed to fetch records"
        case .deleteFailed:
            return "Failed to delete record"
        }
    }
}
