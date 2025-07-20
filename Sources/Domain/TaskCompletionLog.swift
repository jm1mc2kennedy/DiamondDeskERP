//
//  TaskCompletionLog.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit

/// Tracks task completion progress with step-level granularity for enterprise reporting
/// Supports Store Ops-Center style completion tracking with multi-dimensional breakdowns
struct TaskCompletionLog: Identifiable, Codable {
    
    // MARK: - Properties
    
    let id: CKRecord.ID
    let taskId: String
    let userId: String
    let storeCode: String
    let stepIdsCompleted: [String]
    let timestamp: Date
    let completionPercentage: Double
    let completionMethod: CompletionMethod
    let notes: String?
    
    // MARK: - Enums
    
    enum CompletionMethod: String, CaseIterable, Codable {
        case manual = "manual"
        case stepByStep = "step_by_step"
        case bulkComplete = "bulk_complete"
        case adminOverride = "admin_override"
        
        var displayName: String {
            switch self {
            case .manual: return "Manual"
            case .stepByStep: return "Step-by-Step"
            case .bulkComplete: return "Bulk Complete"
            case .adminOverride: return "Admin Override"
            }
        }
    }
    
    // MARK: - CloudKit Integration
    
    init?(record: CKRecord) {
        guard
            let taskId = record["taskId"] as? String,
            let userId = record["userId"] as? String,
            let storeCode = record["storeCode"] as? String,
            let stepIdsCompleted = record["stepIdsCompleted"] as? [String],
            let timestamp = record["timestamp"] as? Date,
            let completionPercentage = record["completionPercentage"] as? Double,
            let completionMethodRaw = record["completionMethod"] as? String,
            let completionMethod = CompletionMethod(rawValue: completionMethodRaw)
        else {
            return nil
        }
        
        self.id = record.recordID
        self.taskId = taskId
        self.userId = userId
        self.storeCode = storeCode
        self.stepIdsCompleted = stepIdsCompleted
        self.timestamp = timestamp
        self.completionPercentage = completionPercentage
        self.completionMethod = completionMethod
        self.notes = record["notes"] as? String
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "TaskCompletionLog", recordID: id)
        record["taskId"] = taskId
        record["userId"] = userId
        record["storeCode"] = storeCode
        record["stepIdsCompleted"] = stepIdsCompleted
        record["timestamp"] = timestamp
        record["completionPercentage"] = completionPercentage
        record["completionMethod"] = completionMethod.rawValue
        record["notes"] = notes
        return record
    }
    
    // MARK: - Convenience Initializers
    
    init(
        taskId: String,
        userId: String,
        storeCode: String,
        stepIdsCompleted: [String],
        completionMethod: CompletionMethod = .stepByStep,
        notes: String? = nil
    ) {
        self.id = CKRecord.ID(zoneID: CKRecordZone.default().zoneID)
        self.taskId = taskId
        self.userId = userId
        self.storeCode = storeCode
        self.stepIdsCompleted = stepIdsCompleted
        self.timestamp = Date()
        self.completionMethod = completionMethod
        self.notes = notes
        
        // Calculate completion percentage based on step completion
        // This would be enhanced with actual task step count lookup
        self.completionPercentage = stepIdsCompleted.isEmpty ? 0.0 : min(1.0, Double(stepIdsCompleted.count) / 10.0)
    }
}

// MARK: - Task Step Model

struct TaskStep: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let isRequired: Bool
    let order: Int
    let estimatedMinutes: Int?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        isRequired: Bool = true,
        order: Int,
        estimatedMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.order = order
        self.estimatedMinutes = estimatedMinutes
    }
}

// MARK: - Reporting Extensions

extension TaskCompletionLog {
    
    /// Returns a formatted timestamp for reporting
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: timestamp)
    }
    
    /// Returns formatted completion percentage
    var formattedCompletionPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: completionPercentage)) ?? "0%"
    }
    
    /// Returns locale-specific CSV row data
    var csvRow: [String] {
        return [
            taskId,
            userId,
            storeCode,
            formattedTimestamp,
            String(stepIdsCompleted.count),
            formattedCompletionPercentage,
            completionMethod.displayName,
            notes ?? ""
        ]
    }
    
    static var csvHeaders: [String] {
        return [
            "Task ID",
            "User ID",
            "Store Code", 
            "Timestamp",
            "Steps Completed",
            "Completion %",
            "Method",
            "Notes"
        ]
    }
}

// MARK: - Hashable & Equatable

extension TaskCompletionLog: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TaskCompletionLog, rhs: TaskCompletionLog) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Progress Calculation Utilities

extension TaskCompletionLog {
    
    /// Calculates completion percentage for a given task with known step count
    static func calculateCompletionPercentage(
        completedSteps: [String],
        totalSteps: [TaskStep]
    ) -> Double {
        guard !totalSteps.isEmpty else { return 0.0 }
        
        let requiredSteps = totalSteps.filter { $0.isRequired }
        let completedRequiredSteps = completedSteps.filter { stepId in
            requiredSteps.contains { $0.id == stepId }
        }
        
        return Double(completedRequiredSteps.count) / Double(requiredSteps.count)
    }
    
    /// Determines if task is fully complete based on required steps
    static func isTaskComplete(
        completedSteps: [String],
        totalSteps: [TaskStep]
    ) -> Bool {
        let requiredSteps = totalSteps.filter { $0.isRequired }
        let completedRequiredSteps = completedSteps.filter { stepId in
            requiredSteps.contains { $0.id == stepId }
        }
        
        return completedRequiredSteps.count == requiredSteps.count
    }
}
