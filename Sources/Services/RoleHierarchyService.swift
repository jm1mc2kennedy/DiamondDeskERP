import Foundation
import CloudKit
import Combine

/// Enhanced Role Management Service with hierarchy support
/// Implements PT3VS1 specifications for role inheritance and validation
@MainActor
class RoleHierarchyService: ObservableObject {
    
    @Published var roles: [RoleDefinitionModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let container: CKContainer
    private let database: CKDatabase
    private let roleCache: NSCache<NSString, RoleDefinitionModel>
    private var cancellables = Set<AnyCancellable>()
    
    init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.database = container.privateCloudDatabase
        self.roleCache = NSCache<NSString, RoleDefinitionModel>()
        self.roleCache.countLimit = 100
        
        setupNotifications()
    }
    
    // MARK: - Core CRUD Operations
    
    /// Create a new role with hierarchy validation
    func createRole(_ role: RoleDefinitionModel) async throws -> RoleDefinitionModel {
        isLoading = true
        defer { isLoading = false }
        
        var newRole = role
        newRole.modifiedAt = Date()
        
        // Validate hierarchy before creation
        let validationErrors = newRole.validateHierarchy(in: roles)
        if !validationErrors.isEmpty {
            throw RoleHierarchyError.validationFailed(errors: validationErrors)
        }
        
        // Check max assignments if specified
        if let maxAssignments = newRole.maxAssignments {
            let currentAssignments = await getCurrentAssignmentCount(roleId: newRole.id)
            if currentAssignments >= maxAssignments {
                throw RoleHierarchyError.maxAssignmentsExceeded(
                    roleId: newRole.id, 
                    current: currentAssignments, 
                    max: maxAssignments
                )
            }
        }
        
        // Calculate effective permissions
        newRole.calculateEffectivePermissions(allRoles: roles)
        
        let record = newRole.toCKRecord()
        let savedRecord = try await database.save(record)
        
        guard let savedRole = RoleDefinitionModel.fromCKRecord(savedRecord) else {
            throw RoleHierarchyError.serializationFailed
        }
        
        // Update parent's child list if this role has a parent
        if let parentId = savedRole.inheritFrom {
            try await addChildToParent(childId: savedRole.id, parentId: parentId)
        }
        
        // Update local cache and state
        roles.append(savedRole)
        roleCache.setObject(savedRole, forKey: savedRole.id as NSString)
        
        // Recalculate effective permissions for all descendants
        await recalculateDescendantPermissions(for: savedRole.id)
        
        return savedRole
    }
    
    /// Update existing role with hierarchy validation
    func updateRole(_ role: RoleDefinitionModel) async throws -> RoleDefinitionModel {
        isLoading = true
        defer { isLoading = false }
        
        var updatedRole = role
        updatedRole.modifiedAt = Date()
        updatedRole.version += 1
        
        // Get old role for comparison
        guard let oldRole = roles.first(where: { $0.id == role.id }) else {
            throw RoleHierarchyError.roleNotFound(id: role.id)
        }
        
        // Validate hierarchy changes
        let validationErrors = updatedRole.validateHierarchy(in: roles)
        if !validationErrors.isEmpty {
            throw RoleHierarchyError.validationFailed(errors: validationErrors)
        }
        
        // Check if parent changed and handle hierarchy updates
        if oldRole.inheritFrom != updatedRole.inheritFrom {
            try await handleParentChange(
                roleId: updatedRole.id,
                oldParentId: oldRole.inheritFrom,
                newParentId: updatedRole.inheritFrom
            )
        }
        
        // Calculate effective permissions
        updatedRole.calculateEffectivePermissions(allRoles: roles)
        
        let record = updatedRole.toCKRecord()
        let savedRecord = try await database.save(record)
        
        guard let savedRole = RoleDefinitionModel.fromCKRecord(savedRecord) else {
            throw RoleHierarchyError.serializationFailed
        }
        
        // Update local cache and state
        if let index = roles.firstIndex(where: { $0.id == savedRole.id }) {
            roles[index] = savedRole
        }
        roleCache.setObject(savedRole, forKey: savedRole.id as NSString)
        
        // Recalculate effective permissions for all descendants
        await recalculateDescendantPermissions(for: savedRole.id)
        
        return savedRole
    }
    
    /// Delete role with cascade handling
    func deleteRole(id: String, cascadeDelete: Bool = false) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let role = roles.first(where: { $0.id == id }) else {
            throw RoleHierarchyError.roleNotFound(id: id)
        }
        
        // Check if role has children
        if !role.childRoles.isEmpty && !cascadeDelete {
            throw RoleHierarchyError.hasChildRoles(roleId: id, childIds: role.childRoles)
        }
        
        // Check if role is assigned to users
        let assignmentCount = await getCurrentAssignmentCount(roleId: id)
        if assignmentCount > 0 {
            throw RoleHierarchyError.roleInUse(roleId: id, userCount: assignmentCount)
        }
        
        if cascadeDelete {
            // Delete all child roles recursively
            for childId in role.childRoles {
                try await deleteRole(id: childId, cascadeDelete: true)
            }
        } else {
            // Reassign child roles to parent
            if let parentId = role.inheritFrom {
                for childId in role.childRoles {
                    try await updateRoleParent(childId: childId, newParentId: parentId)
                }
            } else {
                // Make child roles root roles
                for childId in role.childRoles {
                    try await updateRoleParent(childId: childId, newParentId: nil)
                }
            }
        }
        
        // Remove from parent's child list
        if let parentId = role.inheritFrom {
            try await removeChildFromParent(childId: id, parentId: parentId)
        }
        
        // Delete from CloudKit
        let recordId = CKRecord.ID(recordName: id)
        try await database.deleteRecord(withID: recordId)
        
        // Update local cache and state
        roles.removeAll { $0.id == id }
        roleCache.removeObject(forKey: id as NSString)
    }
    
    // MARK: - Hierarchy Management
    
    /// Get role hierarchy tree starting from root roles
    func getRoleHierarchy() -> [RoleHierarchyNode] {
        let rootRoles = roles.filter { $0.isRootRole }
        return rootRoles.map { buildHierarchyNode(for: $0) }
    }
    
    private func buildHierarchyNode(for role: RoleDefinitionModel) -> RoleHierarchyNode {
        let children = role.childRoles.compactMap { childId in
            roles.first(where: { $0.id == childId })
        }.map { buildHierarchyNode(for: $0) }
        
        return RoleHierarchyNode(
            role: role,
            children: children,
            depth: getHierarchyDepth(for: role.id)
        )
    }
    
    private func getHierarchyDepth(for roleId: String, visited: Set<String> = []) -> Int {
        guard let role = roles.first(where: { $0.id == roleId }),
              !visited.contains(roleId) else {
            return 0
        }
        
        var newVisited = visited
        newVisited.insert(roleId)
        
        guard let parentId = role.inheritFrom else {
            return 0
        }
        
        return 1 + getHierarchyDepth(for: parentId, visited: newVisited)
    }
    
    /// Get all roles that a user can be assigned based on their current role
    func getAssignableRoles(for currentRoleId: String) -> [RoleDefinitionModel] {
        guard let currentRole = roles.first(where: { $0.id == currentRoleId }) else {
            return []
        }
        
        let currentLevel = currentRole.roleLevel.hierarchy
        
        return roles.filter { role in
            // Can only be assigned to same level or lower
            role.roleLevel.hierarchy >= currentLevel &&
            role.isActive &&
            !role.isSystemRole
        }
    }
    
    /// Validate role assignment for a user
    func validateRoleAssignment(roleId: String, userId: String, userContext: UserContext) async throws -> Bool {
        guard let role = roles.first(where: { $0.id == roleId }) else {
            throw RoleHierarchyError.roleNotFound(id: roleId)
        }
        
        // Check if role is active
        if !role.isActive {
            throw RoleHierarchyError.roleInactive(roleId: roleId)
        }
        
        // Check max assignments
        if let maxAssignments = role.maxAssignments {
            let currentCount = await getCurrentAssignmentCount(roleId: roleId)
            if currentCount >= maxAssignments {
                throw RoleHierarchyError.maxAssignmentsExceeded(
                    roleId: roleId,
                    current: currentCount,
                    max: maxAssignments
                )
            }
        }
        
        // Validate department scope
        if !role.departmentScope.isEmpty && 
           !role.departmentScope.contains(userContext.department) {
            throw RoleHierarchyError.departmentMismatch(
                roleId: roleId,
                userDepartment: userContext.department,
                allowedDepartments: role.departmentScope
            )
        }
        
        // Validate location scope
        if !role.locationScope.isEmpty && 
           !role.locationScope.contains(userContext.location) {
            throw RoleHierarchyError.locationMismatch(
                roleId: roleId,
                userLocation: userContext.location,
                allowedLocations: role.locationScope
            )
        }
        
        // Run custom validation rules
        for rule in role.validationRules {
            if rule.isActive {
                let isValid = try await validateRule(rule, for: userContext)
                if !isValid {
                    throw RoleHierarchyError.validationRuleFailed(
                        roleId: roleId,
                        rule: rule.condition,
                        message: rule.errorMessage
                    )
                }
            }
        }
        
        return true
    }
    
    // MARK: - Permission Management
    
    /// Get effective permissions for a role including inherited permissions
    func getEffectivePermissions(for roleId: String) -> [PermissionEntry] {
        guard let role = roles.first(where: { $0.id == roleId }) else {
            return []
        }
        
        return role.effectivePermissions
    }
    
    /// Check if a role has a specific permission
    func hasPermission(roleId: String, resource: String, action: String) -> Bool {
        let effectivePermissions = getEffectivePermissions(for: roleId)
        
        return effectivePermissions.contains { permission in
            permission.resource == resource && permission.actions.contains(action)
        }
    }
    
    /// Get permission diff between two roles
    func getPermissionDiff(fromRoleId: String, toRoleId: String) -> PermissionDiff {
        let fromPermissions = Set(getEffectivePermissions(for: fromRoleId).map { "\($0.resource):\($0.actions.joined(separator: ","))" })
        let toPermissions = Set(getEffectivePermissions(for: toRoleId).map { "\($0.resource):\($0.actions.joined(separator: ","))" })
        
        let added = toPermissions.subtracting(fromPermissions)
        let removed = fromPermissions.subtracting(toPermissions)
        
        return PermissionDiff(
            added: Array(added),
            removed: Array(removed),
            unchanged: Array(fromPermissions.intersection(toPermissions))
        )
    }
    
    // MARK: - Fetch and Sync
    
    /// Fetch all roles from CloudKit
    func fetchRoles() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let query = CKQuery(recordType: "RoleDefinition", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        let results = try await database.records(matching: query)
        var fetchedRoles: [RoleDefinitionModel] = []
        
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let role = RoleDefinitionModel.fromCKRecord(record) {
                    fetchedRoles.append(role)
                    roleCache.setObject(role, forKey: role.id as NSString)
                }
            case .failure(let error):
                print("Failed to fetch role record: \(error)")
            }
        }
        
        roles = fetchedRoles
        
        // Calculate effective permissions for all roles
        for i in 0..<roles.count {
            roles[i].calculateEffectivePermissions(allRoles: roles)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func addChildToParent(childId: String, parentId: String) async throws {
        guard let parentIndex = roles.firstIndex(where: { $0.id == parentId }) else {
            return
        }
        
        if !roles[parentIndex].childRoles.contains(childId) {
            roles[parentIndex].childRoles.append(childId)
            let record = roles[parentIndex].toCKRecord()
            _ = try await database.save(record)
        }
    }
    
    private func removeChildFromParent(childId: String, parentId: String) async throws {
        guard let parentIndex = roles.firstIndex(where: { $0.id == parentId }) else {
            return
        }
        
        roles[parentIndex].childRoles.removeAll { $0 == childId }
        let record = roles[parentIndex].toCKRecord()
        _ = try await database.save(record)
    }
    
    private func handleParentChange(roleId: String, oldParentId: String?, newParentId: String?) async throws {
        // Remove from old parent
        if let oldParentId = oldParentId {
            try await removeChildFromParent(childId: roleId, parentId: oldParentId)
        }
        
        // Add to new parent
        if let newParentId = newParentId {
            try await addChildToParent(childId: roleId, parentId: newParentId)
        }
    }
    
    private func updateRoleParent(childId: String, newParentId: String?) async throws {
        guard let childIndex = roles.firstIndex(where: { $0.id == childId }) else {
            return
        }
        
        let oldParentId = roles[childIndex].inheritFrom
        roles[childIndex].inheritFrom = newParentId
        roles[childIndex].calculateEffectivePermissions(allRoles: roles)
        
        let record = roles[childIndex].toCKRecord()
        _ = try await database.save(record)
        
        try await handleParentChange(roleId: childId, oldParentId: oldParentId, newParentId: newParentId)
    }
    
    private func recalculateDescendantPermissions(for roleId: String) async {
        guard let role = roles.first(where: { $0.id == roleId }) else {
            return
        }
        
        let descendants = role.getDescendants(from: roles)
        for descendant in descendants {
            if let index = roles.firstIndex(where: { $0.id == descendant.id }) {
                roles[index].calculateEffectivePermissions(allRoles: roles)
            }
        }
    }
    
    private func getCurrentAssignmentCount(roleId: String) async -> Int {
        // This would typically query a UserRole relationship table
        // For now, return 0 as placeholder
        return 0
    }
    
    private func validateRule(_ rule: RoleValidationRule, for userContext: UserContext) async throws -> Bool {
        // Implement custom validation logic based on rule type
        switch rule.type {
        case .departmentMatch:
            return userContext.department == rule.condition
        case .locationMatch:
            return userContext.location == rule.condition
        case .seniorityLevel:
            return userContext.seniorityLevel >= Int(rule.condition) ?? 0
        case .skillRequirement:
            return userContext.skills.contains(rule.condition)
        case .securityClearance:
            return userContext.securityClearance == rule.condition
        case .custom:
            // Implement custom validation logic
            return true
        }
    }
    
    private func setupNotifications() {
        // Setup CloudKit subscription for role changes
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task {
                    try? await self?.fetchRoles()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

struct RoleHierarchyNode {
    let role: RoleDefinitionModel
    let children: [RoleHierarchyNode]
    let depth: Int
}

struct UserContext {
    let userId: String
    let department: String
    let location: String
    let seniorityLevel: Int
    let skills: [String]
    let securityClearance: String
}

struct PermissionDiff {
    let added: [String]
    let removed: [String]
    let unchanged: [String]
}

enum RoleHierarchyError: Error, LocalizedError {
    case roleNotFound(id: String)
    case roleInactive(roleId: String)
    case validationFailed(errors: [RoleValidationError])
    case maxAssignmentsExceeded(roleId: String, current: Int, max: Int)
    case hasChildRoles(roleId: String, childIds: [String])
    case roleInUse(roleId: String, userCount: Int)
    case departmentMismatch(roleId: String, userDepartment: String, allowedDepartments: [String])
    case locationMismatch(roleId: String, userLocation: String, allowedLocations: [String])
    case validationRuleFailed(roleId: String, rule: String, message: String)
    case serializationFailed
    
    var errorDescription: String? {
        switch self {
        case .roleNotFound(let id):
            return "Role with ID '\(id)' not found"
        case .roleInactive(let roleId):
            return "Role '\(roleId)' is inactive and cannot be assigned"
        case .validationFailed(let errors):
            return "Role validation failed: \(errors.count) errors"
        case .maxAssignmentsExceeded(let roleId, let current, let max):
            return "Role '\(roleId)' has reached maximum assignments (\(current)/\(max))"
        case .hasChildRoles(let roleId, let childIds):
            return "Cannot delete role '\(roleId)' - has \(childIds.count) child roles"
        case .roleInUse(let roleId, let userCount):
            return "Cannot delete role '\(roleId)' - assigned to \(userCount) users"
        case .departmentMismatch(let roleId, let userDepartment, let allowedDepartments):
            return "Role '\(roleId)' not available for department '\(userDepartment)'. Allowed: \(allowedDepartments.joined(separator: ", "))"
        case .locationMismatch(let roleId, let userLocation, let allowedLocations):
            return "Role '\(roleId)' not available for location '\(userLocation)'. Allowed: \(allowedLocations.joined(separator: ", "))"
        case .validationRuleFailed(let roleId, let rule, let message):
            return "Role '\(roleId)' validation failed for rule '\(rule)': \(message)"
        case .serializationFailed:
            return "Failed to serialize/deserialize role data"
        }
    }
}
