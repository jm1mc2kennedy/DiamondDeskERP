//
//  PerformanceTargetModels.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

// MARK: - Performance Targets Models

/// Defines a performance target for a given KPI or metric
struct PerformanceTarget: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let metricType: MetricType
    let targetValue: Double
    let unit: String
    let period: TimePeriod
    let recurrence: Recurrence
    let assignedTo: [String] // Employee IDs
    let departmentId: UUID?
    let projectId: UUID?
    
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        metricType: MetricType,
        targetValue: Double,
        unit: String,
        period: TimePeriod,
        recurrence: Recurrence,
        assignedTo: [String] = [],
        departmentId: UUID? = nil,
        projectId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.metricType = metricType
        self.targetValue = targetValue
        self.unit = unit
        self.period = period
        self.recurrence = recurrence
        self.assignedTo = assignedTo
        self.departmentId = departmentId
        self.projectId = projectId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Types of measurable metrics
enum MetricType: String, CaseIterable, Codable {
    case revenue = "Revenue"
    case tasksCompleted = "Tasks Completed"
    case ticketsResolved = "Tickets Resolved"
    case kpiValue = "KPI Value"
    case userSatisfaction = "User Satisfaction"
    case responseTime = "Response Time"
    case custom = "Custom"
}

/// Time period for performance targets
enum TimePeriod: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    
    var description: String {
        switch self {
        case .daily: return "Every Day"
        case .weekly: return "Every Week"
        case .monthly: return "Every Month"
        case .quarterly: return "Every Quarter"
        case .annually: return "Every Year"
        }
    }
}

/// Recurrence rules for performance targets
enum Recurrence: String, CaseIterable, Codable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
}

/// View model for performance targets
typealias PerformanceTargetViewModel = PerformanceTarget

// MARK: - CloudKit Integration

extension PerformanceTarget {
    /// Convert performance target to CloudKit record
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "PerformanceTarget", recordID: CKRecord.ID(recordName: id.uuidString))
        record["name"] = name
        record["metricType"] = metricType.rawValue
        record["targetValue"] = targetValue
        record["unit"] = unit
        record["period"] = period.rawValue
        record["recurrence"] = recurrence.rawValue
        
        if let desc = description {
            record["description"] = desc
        }
        
        if let dept = departmentId {
            record["departmentId"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: dept.uuidString), action: .none)
        }
        
        if let proj = projectId {
            record["projectId"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: proj.uuidString), action: .none)
        }
        
        record["assignedTo"] = assignedTo
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
    
    /// Create performance target from CloudKit record
    static func fromCloudKitRecord(_ record: CKRecord) -> PerformanceTarget? {
        guard let name = record["name"] as? String,
              let metricRaw = record["metricType"] as? String,
              let metric = MetricType(rawValue: metricRaw),
              let targetValue = record["targetValue"] as? Double,
              let unit = record["unit"] as? String,
              let periodRaw = record["period"] as? String,
              let period = TimePeriod(rawValue: periodRaw),
              let recurrenceRaw = record["recurrence"] as? String,
              let recurrence = Recurrence(rawValue: recurrenceRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        
        var assignedTo: [String] = []
        if let refs = record["assignedTo"] as? [String] {
            assignedTo = refs
        }
        
        let desc = record["description"] as? String
        
        var deptId: UUID?
        if let ref = record["departmentId"] as? CKRecord.Reference {
            deptId = UUID(uuidString: ref.recordID.recordName)
        }
        
        var projId: UUID?
        if let ref = record["projectId"] as? CKRecord.Reference {
            projId = UUID(uuidString: ref.recordID.recordName)
        }
        
        return PerformanceTarget(
            id: id,
            name: name,
            description: desc,
            metricType: metric,
            targetValue: targetValue,
            unit: unit,
            period: period,
            recurrence: recurrence,
            assignedTo: assignedTo,
            departmentId: deptId,
            projectId: projId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
