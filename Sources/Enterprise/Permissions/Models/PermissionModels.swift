//
//  PermissionModels.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import CloudKit
import SwiftUI

// MARK: - User Profile Model

/// User profile information for permissions management
struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: String
    var displayName: String
    var email: String
    var avatarURL: String?
    var isActive: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    var metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        userId: String,
        displayName: String,
        email: String,
        avatarURL: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastLoginAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.metadata = metadata
    }
}

// MARK: - Core Permission Models

/// User role definition with hierarchical permissions
struct UserRole: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var displayName: String
    var description: String
    var level: Int // Hierarchy level (0 = highest)
    var permissions: Set<Permission>
    var inheritsFrom: UUID? // Parent role for inheritance
    var isSystemRole: Bool
    var createdAt: Date
    var updatedAt: Date
    var createdBy: String
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        description: String,
        level: Int,
        permissions: Set<Permission> = [],
        inheritsFrom: UUID? = nil,
        isSystemRole: Bool = false,
        createdBy: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.description = description
        self.level = level
        self.permissions = permissions
        self.inheritsFrom = inheritsFrom
        self.isSystemRole = isSystemRole
        self.createdAt = Date()
        self.updatedAt = Date()
        self.createdBy = createdBy
    }
    
    /// All permissions including inherited ones
    func effectivePermissions(roleRepository: UserRoleRepository) async -> Set<Permission> {
        var allPermissions = permissions
        
        // Add inherited permissions
        if let parentId = inheritsFrom,
           let parentRole = await roleRepository.getRole(parentId) {
            let parentPermissions = await parentRole.effectivePermissions(roleRepository: roleRepository)
            allPermissions.formUnion(parentPermissions)
        }
        
        return allPermissions
    }
}

/// Individual permission definition
struct Permission: Identifiable, Codable, Hashable {
    let id: UUID
    var resource: PermissionResource
    var action: PermissionAction
    var scope: PermissionScope
    var conditions: [PermissionCondition]
    var isSystemPermission: Bool
    
    init(
        id: UUID = UUID(),
        resource: PermissionResource,
        action: PermissionAction,
        scope: PermissionScope = .organization,
        conditions: [PermissionCondition] = [],
        isSystemPermission: Bool = false
    ) {
        self.id = id
        self.resource = resource
        self.action = action
        self.scope = scope
        self.conditions = conditions
        self.isSystemPermission = isSystemPermission
    }
    
    var key: String {
        "\(resource.rawValue):\(action.rawValue):\(scope.rawValue)"
    }
    
    var displayName: String {
        "\(action.displayName) \(resource.displayName) (\(scope.displayName))"
    }
}

/// Resources that can have permissions
enum PermissionResource: String, CaseIterable, Codable {
    case documents = "documents"
    case tasks = "tasks"
    case tickets = "tickets"
    case clients = "clients"
    case reports = "reports"
    case analytics = "analytics"
    case users = "users"
    case roles = "roles"
    case settings = "settings"
    case audit = "audit"
    case calendar = "calendar"
    case projects = "projects"
    case assets = "assets"
    case workflows = "workflows"
    case integrations = "integrations"
    
    var displayName: String {
        switch self {
        case .documents: return "Documents"
        case .tasks: return "Tasks"
        case .tickets: return "Tickets"
        case .clients: return "Clients"
        case .reports: return "Reports"
        case .analytics: return "Analytics"
        case .users: return "Users"
        case .roles: return "Roles"
        case .settings: return "Settings"
        case .audit: return "Audit Logs"
        case .calendar: return "Calendar"
        case .projects: return "Projects"
        case .assets: return "Assets"
        case .workflows: return "Workflows"
        case .integrations: return "Integrations"
        }
    }
    
    var icon: String {
        switch self {
        case .documents: return "doc.text"
        case .tasks: return "checklist"
        case .tickets: return "ticket"
        case .clients: return "person.2"
        case .reports: return "chart.bar"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .users: return "person.circle"
        case .roles: return "person.badge.key"
        case .settings: return "gearshape"
        case .audit: return "magnifyingglass.circle"
        case .calendar: return "calendar"
        case .projects: return "folder"
        case .assets: return "cube.box"
        case .workflows: return "arrow.triangle.branch"
        case .integrations: return "link"
        }
    }
}

/// Actions that can be performed on resources
enum PermissionAction: String, CaseIterable, Codable {
    case read = "read"
    case create = "create"
    case update = "update"
    case delete = "delete"
    case approve = "approve"
    case assign = "assign"
    case export = "export"
    case import = "import"
    case configure = "configure"
    case audit = "audit"
    
    var displayName: String {
        switch self {
        case .read: return "View"
        case .create: return "Create"
        case .update: return "Edit"
        case .delete: return "Delete"
        case .approve: return "Approve"
        case .assign: return "Assign"
        case .export: return "Export"
        case .import: return "Import"
        case .configure: return "Configure"
        case .audit: return "Audit"
        }
    }
    
    var color: Color {
        switch self {
        case .read: return .blue
        case .create: return .green
        case .update: return .orange
        case .delete: return .red
        case .approve: return .purple
        case .assign: return .teal
        case .export: return .indigo
        case .import: return .mint
        case .configure: return .brown
        case .audit: return .gray
        }
    }
}

/// Scope of permission (organizational structure)
enum PermissionScope: String, CaseIterable, Codable {
    case organization = "organization"
    case department = "department"
    case team = "team"
    case personal = "personal"
    case location = "location"
    
    var displayName: String {
        switch self {
        case .organization: return "Organization-wide"
        case .department: return "Department"
        case .team: return "Team"
        case .personal: return "Personal"
        case .location: return "Location"
        }
    }
}

/// Conditional permission logic
struct PermissionCondition: Codable, Hashable {
    let type: ConditionType
    let field: String
    let operator: ConditionOperator
    let value: String
    
    enum ConditionType: String, CaseIterable, Codable {
        case userAttribute = "user_attribute"
        case resourceAttribute = "resource_attribute"
        case timeConstraint = "time_constraint"
        case locationConstraint = "location_constraint"
        case dataClassification = "data_classification"
    }
    
    enum ConditionOperator: String, CaseIterable, Codable {
        case equals = "equals"
        case notEquals = "not_equals"
        case contains = "contains"
        case notContains = "not_contains"
        case greaterThan = "greater_than"
        case lessThan = "less_than"
        case inSet = "in_set"
        case notInSet = "not_in_set"
    }
}

/// User assignment to roles with context
struct UserRoleAssignment: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: String
    var roleId: UUID
    var scope: AssignmentScope
    var scopeValues: [String] // Department IDs, Location IDs, etc.
    var isActive: Bool
    var validFrom: Date
    var validUntil: Date?
    var assignedBy: String
    var assignedAt: Date
    var reason: String?
    
    init(
        id: UUID = UUID(),
        userId: String,
        roleId: UUID,
        scope: AssignmentScope = .organization,
        scopeValues: [String] = [],
        isActive: Bool = true,
        validFrom: Date = Date(),
        validUntil: Date? = nil,
        assignedBy: String,
        reason: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.roleId = roleId
        self.scope = scope
        self.scopeValues = scopeValues
        self.isActive = isActive
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.assignedBy = assignedBy
        self.assignedAt = Date()
        self.reason = reason
    }
    
    enum AssignmentScope: String, CaseIterable, Codable {
        case organization = "organization"
        case departments = "departments"
        case locations = "locations"
        case teams = "teams"
        case projects = "projects"
    }
}

/// Permission audit trail
struct PermissionAuditEntry: Identifiable, Codable {
    let id: UUID
    var userId: String
    var action: AuditAction
    var resource: PermissionResource
    var resourceId: String?
    var permission: Permission?
    var roleId: UUID?
    var success: Bool
    var reason: String?
    var timestamp: Date
    var ipAddress: String?
    var userAgent: String?
    var sessionId: String?
    
    enum AuditAction: String, CaseIterable, Codable {
        case permissionGranted = "permission_granted"
        case permissionDenied = "permission_denied"
        case roleAssigned = "role_assigned"
        case roleRevoked = "role_revoked"
        case permissionChecked = "permission_checked"
        case sessionStarted = "session_started"
        case sessionEnded = "session_ended"
        case failedLogin = "failed_login"
        case passwordChanged = "password_changed"
        case mfaEnabled = "mfa_enabled"
        case mfaDisabled = "mfa_disabled"
    }
}

// MARK: - System Roles

extension UserRole {
    /// Predefined system roles
    static let systemRoles: [UserRole] = [
        UserRole(
            name: "super_admin",
            displayName: "Super Administrator",
            description: "Full system access with all permissions",
            level: 0,
            permissions: Set(PermissionResource.allCases.flatMap { resource in
                PermissionAction.allCases.map { action in
                    Permission(resource: resource, action: action, scope: .organization)
                }
            }),
            isSystemRole: true,
            createdBy: "system"
        ),
        UserRole(
            name: "admin",
            displayName: "Administrator",
            description: "Administrative access with most permissions",
            level: 1,
            permissions: Set([
                Permission(resource: .users, action: .read, scope: .organization),
                Permission(resource: .users, action: .create, scope: .organization),
                Permission(resource: .users, action: .update, scope: .organization),
                Permission(resource: .roles, action: .read, scope: .organization),
                Permission(resource: .audit, action: .read, scope: .organization),
                Permission(resource: .settings, action: .configure, scope: .organization)
            ]),
            isSystemRole: true,
            createdBy: "system"
        ),
        UserRole(
            name: "manager",
            displayName: "Manager",
            description: "Departmental management access",
            level: 2,
            permissions: Set([
                Permission(resource: .tasks, action: .read, scope: .department),
                Permission(resource: .tasks, action: .create, scope: .department),
                Permission(resource: .tasks, action: .update, scope: .department),
                Permission(resource: .tasks, action: .assign, scope: .department),
                Permission(resource: .reports, action: .read, scope: .department),
                Permission(resource: .analytics, action: .read, scope: .department)
            ]),
            isSystemRole: true,
            createdBy: "system"
        ),
        UserRole(
            name: "user",
            displayName: "User",
            description: "Standard user access",
            level: 3,
            permissions: Set([
                Permission(resource: .tasks, action: .read, scope: .personal),
                Permission(resource: .tasks, action: .update, scope: .personal),
                Permission(resource: .documents, action: .read, scope: .personal),
                Permission(resource: .documents, action: .create, scope: .personal),
                Permission(resource: .calendar, action: .read, scope: .personal)
            ]),
            isSystemRole: true,
            createdBy: "system"
        ),
        UserRole(
            name: "guest",
            displayName: "Guest",
            description: "Limited read-only access",
            level: 4,
            permissions: Set([
                Permission(resource: .documents, action: .read, scope: .personal),
                Permission(resource: .reports, action: .read, scope: .personal)
            ]),
            isSystemRole: true,
            createdBy: "system"
        )
    ]
}

// MARK: - CloudKit Integration

extension UserRole {
    static let recordType = "UserRole"
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        record["name"] = name
        record["displayName"] = displayName
        record["description"] = description
        record["level"] = level
        record["inheritsFrom"] = inheritsFrom?.uuidString
        record["isSystemRole"] = isSystemRole
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["createdBy"] = createdBy
        
        // Store permissions as JSON
        if let permissionsData = try? JSONEncoder().encode(permissions) {
            record["permissions"] = permissionsData
        }
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let displayName = record["displayName"] as? String,
              let description = record["description"] as? String,
              let level = record["level"] as? Int,
              let isSystemRole = record["isSystemRole"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let createdBy = record["createdBy"] as? String else {
            return nil
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.name = name
        self.displayName = displayName
        self.description = description
        self.level = level
        self.inheritsFrom = (record["inheritsFrom"] as? String).flatMap(UUID.init)
        self.isSystemRole = isSystemRole
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        
        // Decode permissions from JSON
        if let permissionsData = record["permissions"] as? Data,
           let decodedPermissions = try? JSONDecoder().decode(Set<Permission>.self, from: permissionsData) {
            self.permissions = decodedPermissions
        } else {
            self.permissions = []
        }
    }
}

extension UserRoleAssignment {
    static let recordType = "UserRoleAssignment"
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        record["userId"] = userId
        record["roleId"] = roleId.uuidString
        record["scope"] = scope.rawValue
        record["scopeValues"] = scopeValues
        record["isActive"] = isActive
        record["validFrom"] = validFrom
        record["validUntil"] = validUntil
        record["assignedBy"] = assignedBy
        record["assignedAt"] = assignedAt
        record["reason"] = reason
        return record
    }
    
    init?(from record: CKRecord) {
        guard let userId = record["userId"] as? String,
              let roleIdString = record["roleId"] as? String,
              let roleId = UUID(uuidString: roleIdString),
              let scopeRaw = record["scope"] as? String,
              let scope = AssignmentScope(rawValue: scopeRaw),
              let isActive = record["isActive"] as? Bool,
              let validFrom = record["validFrom"] as? Date,
              let assignedBy = record["assignedBy"] as? String,
              let assignedAt = record["assignedAt"] as? Date else {
            return nil
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.userId = userId
        self.roleId = roleId
        self.scope = scope
        self.scopeValues = record["scopeValues"] as? [String] ?? []
        self.isActive = isActive
        self.validFrom = validFrom
        self.validUntil = record["validUntil"] as? Date
        self.assignedBy = assignedBy
        self.assignedAt = assignedAt
        self.reason = record["reason"] as? String
    }
}

extension PermissionAuditEntry {
    static let recordType = "PermissionAuditEntry"
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        record["userId"] = userId
        record["action"] = action.rawValue
        record["resource"] = resource.rawValue
        record["resourceId"] = resourceId
        record["roleId"] = roleId?.uuidString
        record["success"] = success
        record["reason"] = reason
        record["timestamp"] = timestamp
        record["ipAddress"] = ipAddress
        record["userAgent"] = userAgent
        record["sessionId"] = sessionId
        
        // Store permission as JSON
        if let permission = permission,
           let permissionData = try? JSONEncoder().encode(permission) {
            record["permission"] = permissionData
        }
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let userId = record["userId"] as? String,
              let actionRaw = record["action"] as? String,
              let action = AuditAction(rawValue: actionRaw),
              let resourceRaw = record["resource"] as? String,
              let resource = PermissionResource(rawValue: resourceRaw),
              let success = record["success"] as? Bool,
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.userId = userId
        self.action = action
        self.resource = resource
        self.resourceId = record["resourceId"] as? String
        self.roleId = (record["roleId"] as? String).flatMap(UUID.init)
        self.success = success
        self.reason = record["reason"] as? String
        self.timestamp = timestamp
        self.ipAddress = record["ipAddress"] as? String
        self.userAgent = record["userAgent"] as? String
        self.sessionId = record["sessionId"] as? String
        
        // Decode permission from JSON
        if let permissionData = record["permission"] as? Data,
           let decodedPermission = try? JSONDecoder().decode(Permission.self, from: permissionData) {
            self.permission = decodedPermission
        } else {
            self.permission = nil
        }
    }
}
