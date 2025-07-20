//
//  RoleManagementViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for role creation and management
/// Handles role CRUD operations and permission matrix
@MainActor
final class RoleManagementViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedRole: UserRole?
    @Published var roles: [UserRole] = []
    @Published var permissionMatrix: [PermissionResource: [PermissionAction: Bool]] = [:]
    
    // MARK: - Form State
    
    @Published var roleName = ""
    @Published var displayName = ""
    @Published var description = ""
    @Published var level = 3
    @Published var inheritsFromRole: UUID?
    @Published var isCustomRole = true
    
    // MARK: - UI State
    
    @Published var isLoading = false
    @Published var isEditing = false
    @Published var showingDeleteConfirmation = false
    @Published var showingInheritanceSelector = false
    @Published var showingPermissionDetail = false
    @Published var error: PermissionError?
    @Published var showingError = false
    
    // MARK: - Filtering
    
    @Published var searchText = ""
    @Published var selectedLevel: Int?
    @Published var showSystemRoles = true
    @Published var showCustomRoles = true
    
    // MARK: - Private Properties
    
    private let permissionsService = UnifiedPermissionsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredRoles: [UserRole] {
        roles.filter { role in
            // Level filter
            if let selectedLevel = selectedLevel, role.level != selectedLevel {
                return false
            }
            
            // Type filter
            if !showSystemRoles && role.isSystemRole {
                return false
            }
            
            if !showCustomRoles && !role.isSystemRole {
                return false
            }
            
            // Search filter
            if !searchText.isEmpty {
                return role.displayName.localizedCaseInsensitiveContains(searchText) ||
                       role.description.localizedCaseInsensitiveContains(searchText) ||
                       role.name.localizedCaseInsensitiveContains(searchText)
            }
            
            return true
        }.sorted { $0.level < $1.level }
    }
    
    var availableParentRoles: [UserRole] {
        roles.filter { role in
            guard let selectedRole = selectedRole else { return true }
            
            // Can't inherit from self
            if role.id == selectedRole.id { return false }
            
            // Can't inherit from a role with higher or equal level
            if role.level >= level { return false }
            
            // Check for circular inheritance
            return !wouldCreateCircularInheritance(childRole: selectedRole.id, parentRole: role.id)
        }
    }
    
    var effectivePermissions: Set<Permission> {
        guard let selectedRole = selectedRole else { return Set() }
        
        var permissions = selectedRole.permissions
        
        // Add inherited permissions
        if let inheritFromRole = inheritsFromRole,
           let parentRole = roles.first(where: { $0.id == inheritFromRole }) {
            permissions.formUnion(getEffectivePermissions(for: parentRole))
        }
        
        return permissions
    }
    
    var canEditRole: Bool {
        guard let selectedRole = selectedRole else { return false }
        
        // Can't edit system roles
        if selectedRole.isSystemRole { return false }
        
        // Check permissions
        Task {
            return await permissionsService.hasPermission(.update, on: .roles)
        }
        return false // Placeholder
    }
    
    var canDeleteRole: Bool {
        guard let selectedRole = selectedRole else { return false }
        
        // Can't delete system roles
        if selectedRole.isSystemRole { return false }
        
        // Can't delete if role is assigned to users
        if hasActiveAssignments(roleId: selectedRole.id) { return false }
        
        // Check permissions
        Task {
            return await permissionsService.hasPermission(.delete, on: .roles)
        }
        return false // Placeholder
    }
    
    var levelOptions: [Int] {
        Array(1...10)
    }
    
    // MARK: - Initialization
    
    init() {
        setupPermissionMatrix()
        observePermissionsService()
        loadRoles()
    }
    
    // MARK: - Public Methods
    
    func loadRoles() {
        Task {
            isLoading = true
            roles = await permissionsService.getAccessibleRoles()
            isLoading = false
        }
    }
    
    func selectRole(_ role: UserRole) {
        selectedRole = role
        
        // Update form fields
        roleName = role.name
        displayName = role.displayName
        description = role.description
        level = role.level
        inheritsFromRole = role.inheritsFrom
        isCustomRole = !role.isSystemRole
        
        updatePermissionMatrix()
    }
    
    func createNewRole() {
        selectedRole = nil
        resetForm()
        isEditing = true
    }
    
    func saveRole() {
        Task {
            do {
                isLoading = true
                
                let permissions = buildPermissionsFromMatrix()
                
                if let selectedRole = selectedRole {
                    // Update existing role
                    var updatedRole = selectedRole
                    updatedRole.displayName = displayName
                    updatedRole.description = description
                    updatedRole.level = level
                    updatedRole.inheritsFrom = inheritsFromRole
                    updatedRole.permissions = permissions
                    
                    try await permissionsService.updateRole(updatedRole)
                    
                } else {
                    // Create new role
                    let newRole = UserRole(
                        name: roleName.lowercased().replacingOccurrences(of: " ", with: "_"),
                        displayName: displayName,
                        description: description,
                        level: level,
                        permissions: permissions,
                        inheritsFrom: inheritsFromRole,
                        createdBy: await permissionsService.getCurrentUserID() ?? "system"
                    )
                    
                    try await permissionsService.createRole(newRole)
                }
                
                await loadRoles()
                isEditing = false
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func deleteRole() {
        guard let selectedRole = selectedRole else { return }
        
        Task {
            do {
                isLoading = true
                try await permissionsService.deleteRole(selectedRole.id)
                await loadRoles()
                self.selectedRole = nil
                isEditing = false
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func cancelEditing() {
        if let selectedRole = selectedRole {
            selectRole(selectedRole) // Restore original values
        } else {
            resetForm()
        }
        isEditing = false
    }
    
    func togglePermission(resource: PermissionResource, action: PermissionAction, scope: PermissionScope = .organization) {
        permissionMatrix[resource]?[action]?.toggle()
    }
    
    func setPermission(resource: PermissionResource, action: PermissionAction, enabled: Bool) {
        permissionMatrix[resource]?[action] = enabled
    }
    
    func duplicateRole(_ role: UserRole) {
        selectedRole = nil
        roleName = "\(role.name)_copy"
        displayName = "\(role.displayName) (Copy)"
        description = role.description
        level = role.level
        inheritsFromRole = role.inheritsFrom
        isCustomRole = true
        
        // Copy permissions
        for resource in PermissionResource.allCases {
            for action in PermissionAction.allCases {
                let permission = Permission(resource: resource, action: action, scope: .organization)
                permissionMatrix[resource]?[action] = role.permissions.contains(permission)
            }
        }
        
        isEditing = true
    }
    
    func getInheritanceChain(for role: UserRole) -> [UserRole] {
        var chain: [UserRole] = []
        var currentRole: UserRole? = role
        
        while let role = currentRole {
            chain.append(role)
            
            if let inheritFromId = role.inheritsFrom {
                currentRole = roles.first(where: { $0.id == inheritFromId })
            } else {
                currentRole = nil
            }
        }
        
        return chain
    }
    
    func getRoleUsageCount(_ roleId: UUID) -> Int {
        // This would be implemented by querying the service
        return permissionsService.roleAssignments.filter { $0.roleId == roleId && $0.isActive }.count
    }
    
    func exportRoleDefinition(_ role: UserRole) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(role)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }
    
    func importRoleDefinition(_ jsonString: String) throws {
        let decoder = JSONDecoder()
        let data = jsonString.data(using: .utf8) ?? Data()
        
        let importedRole = try decoder.decode(UserRole.self, from: data)
        
        // Create as new role with modified name
        selectedRole = nil
        roleName = "\(importedRole.name)_imported"
        displayName = "\(importedRole.displayName) (Imported)"
        description = importedRole.description
        level = importedRole.level
        inheritsFromRole = nil // Don't copy inheritance
        
        // Copy permissions
        for resource in PermissionResource.allCases {
            for action in PermissionAction.allCases {
                let permission = Permission(resource: resource, action: action, scope: .organization)
                permissionMatrix[resource]?[action] = importedRole.permissions.contains(permission)
            }
        }
        
        isEditing = true
    }
    
    // MARK: - Private Methods
    
    private func setupPermissionMatrix() {
        permissionMatrix = [:]
        
        for resource in PermissionResource.allCases {
            permissionMatrix[resource] = [:]
            for action in PermissionAction.allCases {
                permissionMatrix[resource]?[action] = false
            }
        }
    }
    
    private func updatePermissionMatrix() {
        guard let selectedRole = selectedRole else {
            setupPermissionMatrix()
            return
        }
        
        for resource in PermissionResource.allCases {
            for action in PermissionAction.allCases {
                let permission = Permission(resource: resource, action: action, scope: .organization)
                permissionMatrix[resource]?[action] = selectedRole.permissions.contains(permission)
            }
        }
    }
    
    private func buildPermissionsFromMatrix() -> Set<Permission> {
        var permissions = Set<Permission>()
        
        for (resource, actions) in permissionMatrix {
            for (action, enabled) in actions {
                if enabled {
                    permissions.insert(Permission(resource: resource, action: action, scope: .organization))
                }
            }
        }
        
        return permissions
    }
    
    private func resetForm() {
        roleName = ""
        displayName = ""
        description = ""
        level = 3
        inheritsFromRole = nil
        isCustomRole = true
        setupPermissionMatrix()
    }
    
    private func observePermissionsService() {
        permissionsService.$userRoles
            .sink { [weak self] roles in
                self?.roles = roles
            }
            .store(in: &cancellables)
        
        permissionsService.$error
            .sink { [weak self] error in
                if let error = error {
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        self.error = error as? PermissionError ?? PermissionError.loadFailed(error)
        showingError = true
    }
    
    private func wouldCreateCircularInheritance(childRole: UUID, parentRole: UUID) -> Bool {
        var visited = Set<UUID>()
        var current = parentRole
        
        while !visited.contains(current) {
            visited.insert(current)
            
            if current == childRole {
                return true
            }
            
            guard let role = roles.first(where: { $0.id == current }),
                  let inheritFrom = role.inheritsFrom else {
                break
            }
            
            current = inheritFrom
        }
        
        return false
    }
    
    private func getEffectivePermissions(for role: UserRole) -> Set<Permission> {
        var permissions = role.permissions
        
        if let inheritFromId = role.inheritsFrom,
           let parentRole = roles.first(where: { $0.id == inheritFromId }) {
            permissions.formUnion(getEffectivePermissions(for: parentRole))
        }
        
        return permissions
    }
    
    private func hasActiveAssignments(roleId: UUID) -> Bool {
        return permissionsService.roleAssignments.contains { assignment in
            assignment.roleId == roleId && assignment.isActive
        }
    }
}

// MARK: - Permission Matrix Helpers

extension RoleManagementViewModel {
    
    /// Get all permissions for a specific resource
    func getResourcePermissions(_ resource: PermissionResource) -> [PermissionAction: Bool] {
        return permissionMatrix[resource] ?? [:]
    }
    
    /// Set all permissions for a resource
    func setAllResourcePermissions(_ resource: PermissionResource, enabled: Bool) {
        for action in PermissionAction.allCases {
            permissionMatrix[resource]?[action] = enabled
        }
    }
    
    /// Check if resource has any permissions enabled
    func hasAnyPermission(_ resource: PermissionResource) -> Bool {
        return permissionMatrix[resource]?.values.contains(true) ?? false
    }
    
    /// Get permission count for resource
    func getPermissionCount(_ resource: PermissionResource) -> Int {
        return permissionMatrix[resource]?.values.filter { $0 }.count ?? 0
    }
    
    /// Get total permission count
    var totalPermissionCount: Int {
        return permissionMatrix.values.flatMap { $0.values }.filter { $0 }.count
    }
    
    /// Get permission coverage percentage
    var permissionCoverage: Double {
        let total = PermissionResource.allCases.count * PermissionAction.allCases.count
        guard total > 0 else { return 0 }
        return Double(totalPermissionCount) / Double(total) * 100
    }
}
