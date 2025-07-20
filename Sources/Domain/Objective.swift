//
//  Objective.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit

/// Objective model for OKR (Objectives & Key Results) tracking
/// Supports hierarchical structure and multi-level alignment
struct Objective: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    let ownerId: String
    var level: OKRLevel
    var storeCode: String?
    var departmentId: String?
    var quarter: String // Format: "2025-Q1"
    var year: Int
    var parentObjectiveId: UUID? // For hierarchical OKRs
    var status: OKRStatus
    let createdAt: Date
    var updatedAt: Date
    
    // Computed properties (populated separately)
    var keyResults: [KeyResult] = []
    var linkedTasks: [ProjectTask] = []
    var childObjectives: [Objective] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        ownerId: String,
        level: OKRLevel,
        storeCode: String? = nil,
        departmentId: String? = nil,
        quarter: String,
        year: Int,
        parentObjectiveId: UUID? = nil,
        status: OKRStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.ownerId = ownerId
        self.level = level
        self.storeCode = storeCode
        self.departmentId = departmentId
        self.quarter = quarter
        self.year = year
        self.parentObjectiveId = parentObjectiveId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - OKR Level

enum OKRLevel: String, Codable, CaseIterable, Identifiable {
    case company = "COMPANY"
    case store = "STORE"
    case individual = "INDIVIDUAL"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .company: return "Company"
        case .store: return "Store"
        case .individual: return "Individual"
        }
    }
    
    var icon: String {
        switch self {
        case .company: return "building.2"
        case .store: return "storefront"
        case .individual: return "person"
        }
    }
    
    var color: String {
        switch self {
        case .company: return "purple"
        case .store: return "blue"
        case .individual: return "green"
        }
    }
    
    var description: String {
        switch self {
        case .company: return "Company-wide strategic objectives"
        case .store: return "Store-specific operational goals"
        case .individual: return "Personal performance objectives"
        }
    }
}

// MARK: - OKR Status

enum OKRStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case atRisk = "AT_RISK"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .atRisk: return "At Risk"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .active: return "play.circle"
        case .atRisk: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .active: return "blue"
        case .atRisk: return "orange"
        case .completed: return "green"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Key Result

struct KeyResult: Identifiable, Codable, Hashable {
    let id: UUID
    let objectiveId: UUID
    var title: String
    var description: String?
    var targetValue: Double
    var currentValue: Double
    var unit: String // %, $, count, etc.
    var valueType: ValueType
    var measurementMethod: String?
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var lastUpdatedBy: String
    let createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var milestones: [KRMilestone] = []
    var linkedTasks: [ProjectTask] = []
    
    init(
        id: UUID = UUID(),
        objectiveId: UUID,
        title: String,
        description: String? = nil,
        targetValue: Double,
        currentValue: Double = 0.0,
        unit: String,
        valueType: ValueType,
        measurementMethod: String? = nil,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        lastUpdatedBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.objectiveId = objectiveId
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.valueType = valueType
        self.measurementMethod = measurementMethod
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.lastUpdatedBy = lastUpdatedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Value Type

enum ValueType: String, Codable, CaseIterable, Identifiable {
    case percentage = "PERCENTAGE"
    case currency = "CURRENCY"
    case count = "COUNT"
    case decimal = "DECIMAL"
    case binary = "BINARY"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .currency: return "Currency"
        case .count: return "Count"
        case .decimal: return "Decimal"
        case .binary: return "Yes/No"
        }
    }
    
    var icon: String {
        switch self {
        case .percentage: return "percent"
        case .currency: return "dollarsign.circle"
        case .count: return "number"
        case .decimal: return "number.circle"
        case .binary: return "checkmark.circle"
        }
    }
    
    var defaultUnit: String {
        switch self {
        case .percentage: return "%"
        case .currency: return "$"
        case .count: return "count"
        case .decimal: return "units"
        case .binary: return "yes/no"
        }
    }
}

// MARK: - KR Milestone

struct KRMilestone: Identifiable, Codable, Hashable {
    let id: UUID
    let keyResultId: UUID
    var title: String
    var targetValue: Double
    var targetDate: Date
    var isAchieved: Bool
    var achievedAt: Date?
    var achievedValue: Double?
    var notes: String?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        keyResultId: UUID,
        title: String,
        targetValue: Double,
        targetDate: Date,
        isAchieved: Bool = false,
        achievedAt: Date? = nil,
        achievedValue: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.keyResultId = keyResultId
        self.title = title
        self.targetValue = targetValue
        self.targetDate = targetDate
        self.isAchieved = isAchieved
        self.achievedAt = achievedAt
        self.achievedValue = achievedValue
        self.notes = notes
        self.createdAt = createdAt
    }
    
    mutating func achieve(value: Double, notes: String? = nil) {
        isAchieved = true
        achievedAt = Date()
        achievedValue = value
        if let notes = notes {
            self.notes = notes
        }
    }
}

// MARK: - Objective Extensions

extension Objective {
    
    var progress: Double {
        guard !keyResults.isEmpty else { return 0.0 }
        
        let totalProgress = keyResults.reduce(0.0) { total, kr in
            return total + kr.progress
        }
        
        return totalProgress / Double(keyResults.count)
    }
    
    var completedKeyResults: Int {
        return keyResults.filter(\.isCompleted).count
    }
    
    var atRiskKeyResults: Int {
        return keyResults.filter { kr in
            guard let dueDate = kr.dueDate else { return false }
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            return daysUntilDue <= 7 && kr.progress < 80 && !kr.isCompleted
        }.count
    }
    
    var isOverdue: Bool {
        // Check if the quarter has passed and objective is not completed
        let quarterEndDate = endOfQuarter
        return Date() > quarterEndDate && status != .completed
    }
    
    var endOfQuarter: Date {
        let quarterNumber = Int(quarter.suffix(1)) ?? 1
        let month = quarterNumber * 3 // Q1=3, Q2=6, Q3=9, Q4=12
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = Calendar.current.range(of: .day, in: .month, for: Date())?.upperBound
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var quarterDisplayName: String {
        return "\(quarter) \(year)"
    }
    
    var isHierarchical: Bool {
        return parentObjectiveId != nil || !childObjectives.isEmpty
    }
    
    var hasParent: Bool {
        return parentObjectiveId != nil
    }
    
    var hasChildren: Bool {
        return !childObjectives.isEmpty
    }
    
    // Status management
    mutating func activate() {
        status = .active
        updatedAt = Date()
    }
    
    mutating func markAtRisk() {
        status = .atRisk
        updatedAt = Date()
    }
    
    mutating func complete() {
        status = .completed
        updatedAt = Date()
        
        // Mark all key results as completed if they're not already
        for i in keyResults.indices {
            if !keyResults[i].isCompleted {
                keyResults[i].complete()
            }
        }
    }
    
    mutating func cancel() {
        status = .cancelled
        updatedAt = Date()
    }
    
    // Auto-update status based on key results
    mutating func updateStatusBasedOnKeyResults() {
        guard status == .active else { return }
        
        if keyResults.allSatisfy(\.isCompleted) {
            complete()
        } else if atRiskKeyResults > 0 || isOverdue {
            markAtRisk()
        }
    }
}

// MARK: - Key Result Extensions

extension KeyResult {
    
    var progress: Double {
        guard targetValue > 0 else { return 0.0 }
        
        switch valueType {
        case .binary:
            return isCompleted ? 100.0 : 0.0
        case .percentage, .currency, .count, .decimal:
            let progressRatio = currentValue / targetValue
            return min(max(progressRatio * 100, 0.0), 100.0)
        }
    }
    
    var formattedCurrentValue: String {
        return formatValue(currentValue)
    }
    
    var formattedTargetValue: String {
        return formatValue(targetValue)
    }
    
    var progressString: String {
        switch valueType {
        case .binary:
            return isCompleted ? "Completed" : "Not Completed"
        case .percentage:
            return "\(Int(progress))%"
        default:
            return "\(formattedCurrentValue) / \(formattedTargetValue) \(unit)"
        }
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }
    
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        let oneWeekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        return dueDate <= oneWeekFromNow && dueDate >= Date()
    }
    
    var completedMilestones: Int {
        return milestones.filter(\.isAchieved).count
    }
    
    var nextMilestone: KRMilestone? {
        return milestones
            .filter { !$0.isAchieved }
            .sorted { $0.targetDate < $1.targetDate }
            .first
    }
    
    private func formatValue(_ value: Double) -> String {
        switch valueType {
        case .percentage:
            return String(format: "%.1f%%", value)
        case .currency:
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        case .count:
            return String(Int(value))
        case .decimal:
            return String(format: "%.2f", value)
        case .binary:
            return value > 0 ? "Yes" : "No"
        }
    }
    
    // Progress management
    mutating func updateProgress(to newValue: Double, by userId: String) {
        currentValue = newValue
        lastUpdatedBy = userId
        updatedAt = Date()
        
        // Auto-complete if target is reached
        if progress >= 100 && !isCompleted {
            complete()
        }
    }
    
    mutating func complete() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
        
        // Set current value to target value if not already
        if currentValue < targetValue {
            currentValue = targetValue
        }
    }
    
    mutating func reopen() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
}

// MARK: - CloudKit Integration

extension Objective {
    
    static let recordType = "Objective"
    
    init?(record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let title = record["title"] as? String,
            let ownerId = record["ownerId"] as? String,
            let levelRaw = record["level"] as? String,
            let level = OKRLevel(rawValue: levelRaw),
            let quarter = record["quarter"] as? String,
            let year = record["year"] as? Int,
            let statusRaw = record["status"] as? String,
            let status = OKRStatus(rawValue: statusRaw),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.description = record["description"] as? String
        self.ownerId = ownerId
        self.level = level
        self.storeCode = record["storeCode"] as? String
        self.departmentId = record["departmentId"] as? String
        self.quarter = quarter
        self.year = year
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Handle parent objective ID
        if let parentObjectiveIdString = record["parentObjectiveId"] as? String {
            self.parentObjectiveId = UUID(uuidString: parentObjectiveIdString)
        } else {
            self.parentObjectiveId = nil
        }
    }
    
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["id"] = id.uuidString
        record["title"] = title
        record["description"] = description
        record["ownerId"] = ownerId
        record["level"] = level.rawValue
        record["storeCode"] = storeCode
        record["departmentId"] = departmentId
        record["quarter"] = quarter
        record["year"] = year
        record["parentObjectiveId"] = parentObjectiveId?.uuidString
        record["status"] = status.rawValue
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
}

extension KeyResult {
    
    static let recordType = "KeyResult"
    
    init?(record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let objectiveIdString = record["objectiveId"] as? String,
            let objectiveId = UUID(uuidString: objectiveIdString),
            let title = record["title"] as? String,
            let targetValue = record["targetValue"] as? Double,
            let currentValue = record["currentValue"] as? Double,
            let unit = record["unit"] as? String,
            let valueTypeRaw = record["valueType"] as? String,
            let valueType = ValueType(rawValue: valueTypeRaw),
            let isCompleted = record["isCompleted"] as? Bool,
            let lastUpdatedBy = record["lastUpdatedBy"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.objectiveId = objectiveId
        self.title = title
        self.description = record["description"] as? String
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.valueType = valueType
        self.measurementMethod = record["measurementMethod"] as? String
        self.dueDate = record["dueDate"] as? Date
        self.isCompleted = isCompleted
        self.completedAt = record["completedAt"] as? Date
        self.lastUpdatedBy = lastUpdatedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["id"] = id.uuidString
        record["objectiveId"] = objectiveId.uuidString
        record["title"] = title
        record["description"] = description
        record["targetValue"] = targetValue
        record["currentValue"] = currentValue
        record["unit"] = unit
        record["valueType"] = valueType.rawValue
        record["measurementMethod"] = measurementMethod
        record["dueDate"] = dueDate
        record["isCompleted"] = isCompleted
        record["completedAt"] = completedAt
        record["lastUpdatedBy"] = lastUpdatedBy
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
}

// MARK: - OKR Progress Tracking

struct OKRProgress: Identifiable, Codable {
    let id: UUID
    let objectiveId: UUID
    let overallProgress: Double
    let keyResultsOnTrack: Int
    let keyResultsAtRisk: Int
    let keyResultsCompleted: Int
    let progressTrend: [ProgressPoint]
    let contributingUsers: [String]
    let generatedAt: Date
    
    init(
        id: UUID = UUID(),
        objectiveId: UUID,
        overallProgress: Double,
        keyResultsOnTrack: Int,
        keyResultsAtRisk: Int,
        keyResultsCompleted: Int,
        progressTrend: [ProgressPoint] = [],
        contributingUsers: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.objectiveId = objectiveId
        self.overallProgress = overallProgress
        self.keyResultsOnTrack = keyResultsOnTrack
        self.keyResultsAtRisk = keyResultsAtRisk
        self.keyResultsCompleted = keyResultsCompleted
        self.progressTrend = progressTrend
        self.contributingUsers = contributingUsers
        self.generatedAt = generatedAt
    }
}

struct ProgressPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let progress: Double
    let notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        progress: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.progress = progress
        self.notes = notes
    }
}
