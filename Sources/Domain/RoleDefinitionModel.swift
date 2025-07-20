import Foundation
import CloudKit

/// Enhanced Role Definition Model with hierarchy support and inheritance
/// Implements PT3VS1 specifications for advanced role management
struct RoleDefinitionModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    
    // Hierarchy Support
    var inheritFrom: String? // Parent role ID for inheritance
    var childRoles: [String] = [] // Child role IDs
    
    // Permission System
    var permissions: [PermissionEntry] = []
    var contextualRules: [ContextualRule] = []
    var effectivePermissions: [PermissionEntry] = [] // Computed from inheritance chain
    
    // Scope and Classification
    var isSystemRole: Bool = false
    var departmentScope: [String] = []
    var locationScope: [String] = []
    var roleLevel: RoleLevel = .standard
    var priority: Int = 0 // For conflict resolution in inheritance
    
    // Metadata
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var isActive: Bool = true
    var version: Int = 1
    
    // Validation Rules
    var validationRules: [RoleValidationRule] = []
    var maxAssignments: Int? // Maximum users that can have this role
    var requiresApproval: Bool = false
    
    // Computed Properties
    var hasChildren: Bool { !childRoles.isEmpty }
    var hasParent: Bool { inheritFrom != nil }
    var isRootRole: Bool { inheritFrom == nil }
    var isLeafRole: Bool { childRoles.isEmpty }
}

/// Permission entry with inheritance tracking
struct PermissionEntry: Codable, Equatable {
    let resource: String
    let actions: [String]
    let conditions: [String]?
    let inherited: Bool
    let inheritedFrom: String? // Role ID that provided this permission
    let priority: Int // For conflict resolution
    let canOverride: Bool // Whether child roles can override this permission
    
    init(resource: String, actions: [String], conditions: [String]? = nil, 
         inherited: Bool = false, inheritedFrom: String? = nil, 
         priority: Int = 0, canOverride: Bool = true) {
        self.resource = resource
        self.actions = actions
        self.conditions = conditions
        self.inherited = inherited
        self.inheritedFrom = inheritedFrom
        self.priority = priority
        self.canOverride = canOverride
    }
}

/// Contextual rules for dynamic permission application
struct ContextualRule: Codable {
    let id: String = UUID().uuidString
    let condition: String
    let timeRestrictions: TimeRestriction?
    let locationRestrictions: [String]?
    let additionalPermissions: [PermissionEntry]
    let deniedPermissions: [PermissionEntry]
    let isActive: Bool = true
    let priority: Int = 0
}

/// Time-based permission restrictions
struct TimeRestriction: Codable {
    let startTime: String? // HH:mm format
    let endTime: String? // HH:mm format
    let daysOfWeek: [Int] // 1-7, Sunday = 1
    let dateRange: DateInterval?
    let timezone: String?
}

/// Role hierarchy level classification
enum RoleLevel: String, Codable, CaseIterable {
    case system = "system"
    case executive = "executive"
    case management = "management"
    case supervisory = "supervisory"
    case standard = "standard"
    case restricted = "restricted"
    
    var hierarchy: Int {
        switch self {
        case .system: return 0
        case .executive: return 1
        case .management: return 2
        case .supervisory: return 3
        case .standard: return 4
        case .restricted: return 5
        }
    }
}

/// Validation rules for role assignment
struct RoleValidationRule: Codable {
    let id: String = UUID().uuidString
    let type: RoleValidationType
    let condition: String
    let errorMessage: String
    let isActive: Bool = true
}

enum RoleValidationType: String, Codable {
    case departmentMatch = "department_match"
    case locationMatch = "location_match"
    case seniorityLevel = "seniority_level"
    case skillRequirement = "skill_requirement"
    case securityClearance = "security_clearance"
    case custom = "custom"
}

// MARK: - Role Hierarchy Management Extensions

extension RoleDefinitionModel {
    
    /// Calculate effective permissions by traversing inheritance chain
    mutating func calculateEffectivePermissions(allRoles: [RoleDefinitionModel]) {
        var computed: [PermissionEntry] = []
        var visited: Set<String> = []
        
        // Traverse inheritance chain to collect permissions
        collectInheritedPermissions(from: self, allRoles: allRoles, 
                                  computed: &computed, visited: &visited)
        
        // Add direct permissions (these have highest priority)
        for permission in self.permissions {
            if !permission.inherited {
                computed.append(permission)
            }
        }
        
        // Resolve conflicts and apply priority rules
        self.effectivePermissions = resolvePermissionConflicts(computed)
    }
    
    private func collectInheritedPermissions(from role: RoleDefinitionModel, 
                                           allRoles: [RoleDefinitionModel],
                                           computed: inout [PermissionEntry],
                                           visited: inout Set<String>) {
        // Prevent infinite recursion
        guard !visited.contains(role.id) else { return }
        visited.insert(role.id)
        
        // If role has a parent, collect from parent first
        if let parentId = role.inheritFrom,
           let parent = allRoles.first(where: { $0.id == parentId }) {
            collectInheritedPermissions(from: parent, allRoles: allRoles, 
                                      computed: &computed, visited: &visited)
            
            // Add parent's permissions as inherited
            for permission in parent.permissions {
                if permission.canOverride {
                    let inheritedPermission = PermissionEntry(
                        resource: permission.resource,
                        actions: permission.actions,
                        conditions: permission.conditions,
                        inherited: true,
                        inheritedFrom: parent.id,
                        priority: permission.priority,
                        canOverride: permission.canOverride
                    )
                    computed.append(inheritedPermission)
                }
            }
        }
    }
    
    private func resolvePermissionConflicts(_ permissions: [PermissionEntry]) -> [PermissionEntry] {
        var resolved: [String: PermissionEntry] = [:]
        
        // Group by resource and resolve conflicts
        let grouped = Dictionary(grouping: permissions) { $0.resource }
        
        for (resource, resourcePermissions) in grouped {
            // Sort by priority (higher number = higher priority)
            let sorted = resourcePermissions.sorted { $0.priority > $1.priority }
            
            // Take the highest priority permission for each resource
            if let highestPriority = sorted.first {
                resolved[resource] = highestPriority
            }
        }
        
        return Array(resolved.values)
    }
    
    /// Get all ancestor roles in the hierarchy chain
    func getAncestors(from allRoles: [RoleDefinitionModel]) -> [RoleDefinitionModel] {
        var ancestors: [RoleDefinitionModel] = []
        var current = self
        var visited: Set<String> = []
        
        while let parentId = current.inheritFrom,
              !visited.contains(parentId),
              let parent = allRoles.first(where: { $0.id == parentId }) {
            visited.insert(parentId)
            ancestors.append(parent)
            current = parent
        }
        
        return ancestors
    }
    
    /// Get all descendant roles in the hierarchy chain
    func getDescendants(from allRoles: [RoleDefinitionModel]) -> [RoleDefinitionModel] {
        var descendants: [RoleDefinitionModel] = []
        var queue = childRoles
        var visited: Set<String> = []
        
        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            
            guard !visited.contains(currentId),
                  let role = allRoles.first(where: { $0.id == currentId }) else {
                continue
            }
            
            visited.insert(currentId)
            descendants.append(role)
            queue.append(contentsOf: role.childRoles)
        }
        
        return descendants
    }
    
    /// Validate role hierarchy rules
    func validateHierarchy(in allRoles: [RoleDefinitionModel]) -> [RoleValidationError] {
        var errors: [RoleValidationError] = []
        
        // Check for circular dependencies
        if hasCircularDependency(in: allRoles) {
            errors.append(.circularDependency(roleId: id))
        }
        
        // Check role level consistency
        if let parentId = inheritFrom,
           let parent = allRoles.first(where: { $0.id == parentId }),
           roleLevel.hierarchy <= parent.roleLevel.hierarchy {
            errors.append(.invalidHierarchy(childId: id, parentId: parentId))
        }
        
        // Check permission inheritance rules
        errors.append(contentsOf: validatePermissionInheritance(in: allRoles))
        
        return errors
    }
    
    private func hasCircularDependency(in allRoles: [RoleDefinitionModel]) -> Bool {
        var visited: Set<String> = []
        var current = self
        
        while let parentId = current.inheritFrom {
            if visited.contains(parentId) {
                return true
            }
            visited.insert(current.id)
            
            guard let parent = allRoles.first(where: { $0.id == parentId }) else {
                break
            }
            current = parent
        }
        
        return false
    }
    
    private func validatePermissionInheritance(in allRoles: [RoleDefinitionModel]) -> [RoleValidationError] {
        var errors: [RoleValidationError] = []
        
        // Check if role tries to override non-overridable permissions
        let ancestors = getAncestors(from: allRoles)
        for ancestor in ancestors {
            for ancestorPermission in ancestor.permissions {
                if !ancestorPermission.canOverride {
                    // Check if this role has conflicting permission
                    if let conflict = permissions.first(where: { 
                        $0.resource == ancestorPermission.resource && 
                        !$0.inherited 
                    }) {
                        errors.append(.cannotOverridePermission(
                            roleId: id, 
                            resource: conflict.resource, 
                            parentId: ancestor.id
                        ))
                    }
                }
            }
        }
        
        return errors
    }
}

/// Role validation errors
enum RoleValidationError: Error {
    case circularDependency(roleId: String)
    case invalidHierarchy(childId: String, parentId: String)
    case cannotOverridePermission(roleId: String, resource: String, parentId: String)
    case maxAssignmentsExceeded(roleId: String, current: Int, max: Int)
    case validationRuleFailed(roleId: String, rule: String, message: String)
}

// MARK: - CloudKit Extensions

extension RoleDefinitionModel {
    
    /// Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "RoleDefinition", recordID: CKRecord.ID(recordName: id))
        
        record["name"] = name
        record["description"] = description
        record["inheritFrom"] = inheritFrom
        record["isSystemRole"] = isSystemRole ? 1 : 0
        record["departmentScope"] = departmentScope
        record["locationScope"] = locationScope
        record["roleLevel"] = roleLevel.rawValue
        record["priority"] = priority
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["isActive"] = isActive ? 1 : 0
        record["version"] = version
        record["maxAssignments"] = maxAssignments
        record["requiresApproval"] = requiresApproval ? 1 : 0
        
        // Serialize complex objects as Data
        if let permissionsData = try? JSONEncoder().encode(permissions) {
            record["permissions"] = permissionsData
        }
        
        if let rulesData = try? JSONEncoder().encode(contextualRules) {
            record["contextualRules"] = rulesData
        }
        
        if let validationData = try? JSONEncoder().encode(validationRules) {
            record["validationRules"] = validationData
        }
        
        record["childRoles"] = childRoles
        
        return record
    }
    
    /// Create from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> RoleDefinitionModel? {
        guard let name = record["name"] as? String,
              let description = record["description"] as? String else {
            return nil
        }
        
        var role = RoleDefinitionModel(
            id: record.recordID.recordName,
            name: name,
            description: description
        )
        
        role.inheritFrom = record["inheritFrom"] as? String
        role.isSystemRole = (record["isSystemRole"] as? Int) == 1
        role.departmentScope = record["departmentScope"] as? [String] ?? []
        role.locationScope = record["locationScope"] as? [String] ?? []
        
        if let levelString = record["roleLevel"] as? String,
           let level = RoleLevel(rawValue: levelString) {
            role.roleLevel = level
        }
        
        role.priority = record["priority"] as? Int ?? 0
        role.createdAt = record["createdAt"] as? Date ?? Date()
        role.modifiedAt = record["modifiedAt"] as? Date ?? Date()
        role.isActive = (record["isActive"] as? Int) == 1
        role.version = record["version"] as? Int ?? 1
        role.maxAssignments = record["maxAssignments"] as? Int
        role.requiresApproval = (record["requiresApproval"] as? Int) == 1
        role.childRoles = record["childRoles"] as? [String] ?? []
        
        // Deserialize complex objects
        if let permissionsData = record["permissions"] as? Data,
           let permissions = try? JSONDecoder().decode([PermissionEntry].self, from: permissionsData) {
            role.permissions = permissions
        }
        
        if let rulesData = record["contextualRules"] as? Data,
           let rules = try? JSONDecoder().decode([ContextualRule].self, from: rulesData) {
            role.contextualRules = rules
        }
        
        if let validationData = record["validationRules"] as? Data,
           let validation = try? JSONDecoder().decode([RoleValidationRule].self, from: validationData) {
            role.validationRules = validation
        }
        
        return role
    }
}
