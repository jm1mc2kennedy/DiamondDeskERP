//
//  ProjectModels.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

// MARK: - Project Management Models

/// Represents a high-level project entity in the enterprise
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var startDate: Date
    var endDate: Date?
    var status: ProjectStatus
    var managerId: String? // Employee ID
    var stakeholderIds: [String]
    var tasks: [String] // Task IDs
    var milestoneIds: [String]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, description: String? = nil, startDate: Date, endDate: Date? = nil, status: ProjectStatus = .active, managerId: String? = nil, stakeholderIds: [String] = [], tasks: [String] = [], milestoneIds: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.managerId = managerId
        self.stakeholderIds = stakeholderIds
        self.tasks = tasks
        self.milestoneIds = milestoneIds
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum ProjectStatus: String, CaseIterable, Codable {
    case active = "Active"
    case planning = "Planning"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

// MARK: - CloudKit Integration

extension Project {
    /// Convert Project to CloudKit record
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "Project", recordID: CKRecord.ID(recordName: id.uuidString))
        record["name"] = name
        record["description"] = description
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["status"] = status.rawValue
        record["managerId"] = managerId
        record["stakeholderIds"] = stakeholderIds
        record["tasks"] = tasks
        record["milestoneIds"] = milestoneIds
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }

    /// Create Project from CloudKit record
    static func fromCloudKitRecord(_ record: CKRecord) -> Project? {
        guard let name = record["name"] as? String,
              let startDate = record["startDate"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = ProjectStatus(rawValue: statusRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let description = record["description"] as? String
        let endDate = record["endDate"] as? Date
        let managerId = record["managerId"] as? String
        let stakeholderIds = record["stakeholderIds"] as? [String] ?? []
        let tasks = record["tasks"] as? [String] ?? []
        let milestoneIds = record["milestoneIds"] as? [String] ?? []

        var project = Project(id: id, name: name, description: description, startDate: startDate, endDate: endDate, status: status, managerId: managerId, stakeholderIds: stakeholderIds, tasks: tasks, milestoneIds: milestoneIds)
        project.createdAt = createdAt
        project.updatedAt = updatedAt
        return project
    }
}
