//
//  AcknowledgmentTrackingService.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit
import Combine

/// Enterprise service for tracking message reads and task completions
/// Provides Store Ops-Center style reporting with multi-dimensional breakdowns
@MainActor
final class AcknowledgmentTrackingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messageReadLogs: [MessageReadLog] = []
    @Published var taskCompletionLogs: [TaskCompletionLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let container = CKContainer.default()
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.database = container.publicCloudDatabase
    }
    
    // MARK: - Message Read Tracking
    
    /// Logs a message read acknowledgment
    func logMessageRead(
        messageId: String,
        userId: String,
        storeCode: String,
        readSource: MessageReadLog.ReadSource = .explicitOK
    ) async throws {
        let deviceType: MessageReadLog.DeviceType = UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        
        let readLog = MessageReadLog(
            messageId: messageId,
            userId: userId,
            storeCode: storeCode,
            readSource: readSource,
            deviceType: deviceType
        )
        
        do {
            let record = readLog.toRecord()
            _ = try await database.save(record)
            
            await MainActor.run {
                messageReadLogs.append(readLog)
                // Trigger progress update notifications
                NotificationCenter.default.post(
                    name: .messageReadProgressUpdated,
                    object: nil,
                    userInfo: ["messageId": messageId]
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to log message read: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Retrieves read logs for a specific message
    func getMessageReadLogs(for messageId: String) async throws -> [MessageReadLog] {
        let predicate = NSPredicate(format: "messageId == %@", messageId)
        let query = CKQuery(recordType: "MessageReadLog", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let logs = matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return MessageReadLog(record: record)
                case .failure:
                    return nil
                }
            }
            
            await MainActor.run {
                // Update local cache for this message
                messageReadLogs.removeAll { $0.messageId == messageId }
                messageReadLogs.append(contentsOf: logs)
            }
            
            return logs
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch message read logs: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Task Completion Tracking
    
    /// Logs task step completion
    func logTaskStepComplete(
        taskId: String,
        stepId: String,
        userId: String,
        storeCode: String,
        allSteps: [TaskStep] = [],
        notes: String? = nil
    ) async throws {
        // Get existing completion log for this user/task or create new one
        let existingLogs = try await getTaskCompletionLogs(for: taskId)
        let userLog = existingLogs.first { $0.userId == userId }
        
        var updatedStepIds = userLog?.stepIdsCompleted ?? []
        
        // Add step if not already completed
        if !updatedStepIds.contains(stepId) {
            updatedStepIds.append(stepId)
        }
        
        let completionPercentage = TaskCompletionLog.calculateCompletionPercentage(
            completedSteps: updatedStepIds,
            totalSteps: allSteps
        )
        
        let completionLog = TaskCompletionLog(
            taskId: taskId,
            userId: userId,
            storeCode: storeCode,
            stepIdsCompleted: updatedStepIds,
            completionMethod: .stepByStep,
            notes: notes
        )
        
        do {
            // If updating existing log, delete old record first
            if let existingLog = userLog {
                try await database.deleteRecord(withID: existingLog.id)
            }
            
            let record = completionLog.toRecord()
            _ = try await database.save(record)
            
            await MainActor.run {
                // Update local cache
                taskCompletionLogs.removeAll { $0.userId == userId && $0.taskId == taskId }
                taskCompletionLogs.append(completionLog)
                
                // Trigger progress update notifications
                NotificationCenter.default.post(
                    name: .taskCompletionProgressUpdated,
                    object: nil,
                    userInfo: [
                        "taskId": taskId,
                        "userId": userId,
                        "completionPercentage": completionPercentage
                    ]
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to log task completion: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Retrieves completion logs for a specific task
    func getTaskCompletionLogs(for taskId: String) async throws -> [TaskCompletionLog] {
        let predicate = NSPredicate(format: "taskId == %@", taskId)
        let query = CKQuery(recordType: "TaskCompletionLog", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let logs = matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return TaskCompletionLog(record: record)
                case .failure:
                    return nil
                }
            }
            
            await MainActor.run {
                // Update local cache for this task
                taskCompletionLogs.removeAll { $0.taskId == taskId }
                taskCompletionLogs.append(contentsOf: logs)
            }
            
            return logs
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch task completion logs: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Progress Calculation
    
    /// Calculates message read percentage for reporting
    func calculateMessageReadPercentage(
        messageId: String,
        totalAssignedUsers: Int
    ) async -> Double {
        do {
            let readLogs = try await getMessageReadLogs(for: messageId)
            let uniqueReaders = Set(readLogs.map { $0.userId })
            
            guard totalAssignedUsers > 0 else { return 0.0 }
            return Double(uniqueReaders.count) / Double(totalAssignedUsers)
        } catch {
            return 0.0
        }
    }
    
    /// Calculates task completion percentage for reporting
    func calculateTaskCompletionPercentage(
        taskId: String,
        totalAssignedUsers: Int,
        taskSteps: [TaskStep] = []
    ) async -> Double {
        do {
            let completionLogs = try await getTaskCompletionLogs(for: taskId)
            
            guard totalAssignedUsers > 0 else { return 0.0 }
            
            if taskSteps.isEmpty {
                // Simple completion count
                let completedUsers = completionLogs.filter { $0.completionPercentage >= 1.0 }
                return Double(completedUsers.count) / Double(totalAssignedUsers)
            } else {
                // Weighted by step completion
                let totalCompletion = completionLogs.reduce(0.0) { sum, log in
                    sum + log.completionPercentage
                }
                return totalCompletion / Double(totalAssignedUsers)
            }
        } catch {
            return 0.0
        }
    }
    
    // MARK: - Reporting & Export
    
    /// Generates comprehensive reporting data
    func generateAcknowledgmentReport(
        for dateRange: ClosedRange<Date>,
        storeCode: String? = nil
    ) async throws -> AcknowledgmentReport {
        // Implementation would aggregate data by region, store, user
        // This is a simplified version
        
        var messageFilter = "timestamp >= %@ AND timestamp <= %@"
        var taskFilter = "timestamp >= %@ AND timestamp <= %@"
        var arguments: [Any] = [dateRange.lowerBound, dateRange.upperBound]
        
        if let storeCode = storeCode {
            messageFilter += " AND storeCode == %@"
            taskFilter += " AND storeCode == %@"
            arguments.append(storeCode)
        }
        
        // Fetch filtered data
        let messagePredicate = NSPredicate(format: messageFilter, argumentArray: arguments)
        let taskPredicate = NSPredicate(format: taskFilter, argumentArray: arguments)
        
        let messageQuery = CKQuery(recordType: "MessageReadLog", predicate: messagePredicate)
        let taskQuery = CKQuery(recordType: "TaskCompletionLog", predicate: taskPredicate)
        
        let (messageResults, _) = try await database.records(matching: messageQuery)
        let (taskResults, _) = try await database.records(matching: taskQuery)
        
        let messageLogs = messageResults.compactMap { _, result in
            switch result {
            case .success(let record): return MessageReadLog(record: record)
            case .failure: return nil
            }
        }
        
        let taskLogs = taskResults.compactMap { _, result in
            switch result {
            case .success(let record): return TaskCompletionLog(record: record)
            case .failure: return nil
            }
        }
        
        return AcknowledgmentReport(
            dateRange: dateRange,
            storeCode: storeCode,
            messageReadLogs: messageLogs,
            taskCompletionLogs: taskLogs
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let messageReadProgressUpdated = Notification.Name("messageReadProgressUpdated")
    static let taskCompletionProgressUpdated = Notification.Name("taskCompletionProgressUpdated")
}

// MARK: - Reporting Model

struct AcknowledgmentReport {
    let dateRange: ClosedRange<Date>
    let storeCode: String?
    let messageReadLogs: [MessageReadLog]
    let taskCompletionLogs: [TaskCompletionLog]
    
    var totalMessagesTracked: Int {
        Set(messageReadLogs.map { $0.messageId }).count
    }
    
    var totalTasksTracked: Int {
        Set(taskCompletionLogs.map { $0.taskId }).count
    }
    
    var uniqueUsersInvolved: Int {
        let messageUsers = Set(messageReadLogs.map { $0.userId })
        let taskUsers = Set(taskCompletionLogs.map { $0.userId })
        return messageUsers.union(taskUsers).count
    }
}
