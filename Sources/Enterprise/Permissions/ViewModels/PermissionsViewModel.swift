//
//  PermissionsViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for permissions management interface
/// Handles role assignments, permission checks, and audit trail
@MainActor
final class PermissionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var availableRoles: [UserRole] = []
    @Published var userAssignments: [UserRoleAssignment] = []
    @Published var selectedUser: String?
    @Published var selectedRole: UserRole?
    @Published var auditEntries: [PermissionAuditEntry] = []
    
    // MARK: - UI State
    
    @Published var isLoading = false
    @Published var showingRoleCreation = false
    @Published var showingUserAssignment = false
    @Published var showingAuditDetail = false
    @Published var showingPermissionDetail = false
    @Published var error: PermissionError?
    @Published var showingError = false
    
    // MARK: - Form Properties
    
    @Published var newRoleName = ""
    @Published var newRoleDisplayName = ""
    @Published var newRoleDescription = ""
    @Published var newRoleLevel = 3
    @Published var newRolePermissions: Set<Permission> = []
    @Published var inheritFromRole: UUID?
    
    @Published var assignmentUserId = ""
    @Published var assignmentScope: UserRoleAssignment.AssignmentScope = .organization
    @Published var assignmentScopeValues: [String] = []
    @Published var assignmentValidUntil: Date?
    @Published var assignmentReason = ""
    
    // MARK: - Filtering and Search
    
    @Published var searchText = ""
    @Published var selectedResource: PermissionResource?
    @Published var selectedAction: PermissionAction?
    @Published var selectedAuditAction: PermissionAuditEntry.AuditAction?
    @Published var auditDateRange: ClosedRange<Date>?
    
    // MARK: - Private Properties
    
    private let permissionsService = UnifiedPermissionsService.shared
    private let userProvisioningService = UserProvisioningService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredRoles: [UserRole] {
        var roles = availableRoles
        
        if !searchText.isEmpty {
            roles = roles.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return roles.sorted { $0.level < $1.level }
    }
    
    var filteredUserAssignments: [UserRoleAssignment] {
        var assignments = userAssignments
        
        if let selectedUser = selectedUser {
            assignments = assignments.filter { $0.userId == selectedUser }
        }
        
        if let selectedRole = selectedRole {
            assignments = assignments.filter { $0.roleId == selectedRole.id }
        }
        
        return assignments.filter { $0.isActive }
    }
    
    var filteredAuditEntries: [PermissionAuditEntry] {
        var entries = auditEntries
        
        if let selectedUser = selectedUser {
            entries = entries.filter { $0.userId == selectedUser }
        }
        
        if let selectedResource = selectedResource {
            entries = entries.filter { $0.resource == selectedResource }
        }
        
        if let selectedAction = selectedAuditAction {
            entries = entries.filter { $0.action == selectedAction }
        }
        
        if let dateRange = auditDateRange {
            entries = entries.filter { dateRange.contains($0.timestamp) }
        }
        
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.reason?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.userId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    var canCreateRoles: Bool {
        Task {
            return await permissionsService.hasPermission(.create, on: .roles)
        }
        return false // Placeholder for computed property
    }
    
    var canAssignRoles: Bool {
        Task {
            return await permissionsService.hasPermission(.assign, on: .roles)
        }
        return false // Placeholder for computed property
    }
    
    var canViewAudit: Bool {
        Task {
            return await permissionsService.hasPermission(.audit, on: .audit)
        }
        return false // Placeholder for computed property
    }
    
    // MARK: - Initialization
    
    init() {
        observePermissionsService()
        loadData()
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadRoles() }
                group.addTask { await self.loadUserAssignments() }
                group.addTask { await self.loadAuditTrail() }
            }
        }
    }
    
    func createRole() {
        Task {
            do {
                isLoading = true
                
                let role = UserRole(
                    name: newRoleName.lowercased().replacingOccurrences(of: " ", with: "_"),
                    displayName: newRoleDisplayName,
                    description: newRoleDescription,
                    level: newRoleLevel,
                    permissions: newRolePermissions,
                    inheritsFrom: inheritFromRole,
                    createdBy: await userProvisioningService.getCurrentUserID() ?? "system"
                )
                
                try await permissionsService.createRole(role)
                
                // Reset form
                resetRoleForm()
                showingRoleCreation = false
                
                await loadRoles()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func updateRole(_ role: UserRole) {
        Task {
            do {
                isLoading = true
                try await permissionsService.updateRole(role)
                await loadRoles()
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func deleteRole(_ role: UserRole) {
        Task {
            do {
                isLoading = true
                try await permissionsService.deleteRole(role.id)
                await loadRoles()
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func assignRole() {
        guard let selectedRole = selectedRole else { return }
        
        Task {
            do {
                isLoading = true
                
                try await permissionsService.assignRole(
                    selectedRole.id,
                    to: assignmentUserId,
                    scope: assignmentScope,
                    scopeValues: assignmentScopeValues,
                    validUntil: assignmentValidUntil,
                    reason: assignmentReason.isEmpty ? nil : assignmentReason
                )
                
                // Reset form
                resetAssignmentForm()
                showingUserAssignment = false
                
                await loadUserAssignments()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func revokeRole(_ assignment: UserRoleAssignment) {
        Task {
            do {
                isLoading = true
                try await permissionsService.revokeRole(
                    assignment.roleId,
                    from: assignment.userId,
                    reason: "Revoked via admin interface"
                )
                await loadUserAssignments()
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func getUserEffectivePermissions(_ userId: String) async -> Set<Permission> {
        return await permissionsService.getUserEffectivePermissions(userId)
    }
    
    func checkUserPermission(_ userId: String, _ action: PermissionAction, on resource: PermissionResource) async -> Bool {
        // This would need to be implemented with user context switching
        return await permissionsService.hasPermission(action, on: resource)
    }
    
    func refreshAuditTrail() {
        Task {
            await loadAuditTrail()
        }
    }
    
    func exportAuditTrail() -> URL? {
        // Generate CSV export of audit trail
        let csv = generateAuditCSV()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("audit_trail_\(Date().timeIntervalSince1970).csv")
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Permission Management
    
    func addPermissionToRole(_ permission: Permission, role: UserRole) {
        var updatedRole = role
        updatedRole.permissions.insert(permission)
        updateRole(updatedRole)
    }
    
    func removePermissionFromRole(_ permission: Permission, role: UserRole) {
        var updatedRole = role
        updatedRole.permissions.remove(permission)
        updateRole(updatedRole)
    }
    
    func togglePermission(_ permission: Permission, for role: UserRole) {
        if role.permissions.contains(permission) {
            removePermissionFromRole(permission, role: role)
        } else {
            addPermissionToRole(permission, role: role)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadRoles() async {
        let roles = await permissionsService.getAccessibleRoles()
        await MainActor.run {
            self.availableRoles = roles
        }
    }
    
    private func loadUserAssignments() async {
        // This would need to be implemented in the service
        // For now, use the published property from the service
        await MainActor.run {
            self.userAssignments = permissionsService.roleAssignments
        }
    }
    
    private func loadAuditTrail() async {
        let entries = await permissionsService.getAuditTrail(limit: 500)
        await MainActor.run {
            self.auditEntries = entries
        }
    }
    
    private func observePermissionsService() {
        permissionsService.$userRoles
            .sink { [weak self] roles in
                self?.availableRoles = roles
            }
            .store(in: &cancellables)
        
        permissionsService.$roleAssignments
            .sink { [weak self] assignments in
                self?.userAssignments = assignments
            }
            .store(in: &cancellables)
        
        permissionsService.$auditEntries
            .sink { [weak self] entries in
                self?.auditEntries = entries
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
    
    private func resetRoleForm() {
        newRoleName = ""
        newRoleDisplayName = ""
        newRoleDescription = ""
        newRoleLevel = 3
        newRolePermissions = []
        inheritFromRole = nil
    }
    
    private func resetAssignmentForm() {
        assignmentUserId = ""
        assignmentScope = .organization
        assignmentScopeValues = []
        assignmentValidUntil = nil
        assignmentReason = ""
    }
    
    private func handleError(_ error: Error) {
        self.error = error as? PermissionError ?? PermissionError.loadFailed(error)
        showingError = true
    }
    
    private func generateAuditCSV() -> String {
        var csv = "Timestamp,User ID,Action,Resource,Success,Reason\n"
        
        for entry in filteredAuditEntries {
            let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
            let reason = entry.reason?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(timestamp),\(entry.userId),\(entry.action.rawValue),\(entry.resource.rawValue),\(entry.success),\(reason)\n"
        }
        
        return csv
    }
}

// MARK: - Permission Builder Helper

extension PermissionsViewModel {
    /// Helper to build common permission sets
    func buildPermissionSet(for roleType: SystemRoleType) -> Set<Permission> {
        switch roleType {
        case .admin:
            return Set(PermissionResource.allCases.flatMap { resource in
                PermissionAction.allCases.compactMap { action in
                    // Admins get most permissions but not all
                    if resource == .audit && action == .delete { return nil }
                    return Permission(resource: resource, action: action, scope: .organization)
                }
            })
            
        case .manager:
            return Set([
                Permission(resource: .tasks, action: .read, scope: .department),
                Permission(resource: .tasks, action: .create, scope: .department),
                Permission(resource: .tasks, action: .update, scope: .department),
                Permission(resource: .tasks, action: .assign, scope: .department),
                Permission(resource: .projects, action: .read, scope: .department),
                Permission(resource: .projects, action: .create, scope: .department),
                Permission(resource: .reports, action: .read, scope: .department),
                Permission(resource: .analytics, action: .read, scope: .department),
                Permission(resource: .users, action: .read, scope: .department)
            ])
            
        case .user:
            return Set([
                Permission(resource: .tasks, action: .read, scope: .personal),
                Permission(resource: .tasks, action: .update, scope: .personal),
                Permission(resource: .documents, action: .read, scope: .personal),
                Permission(resource: .documents, action: .create, scope: .personal),
                Permission(resource: .calendar, action: .read, scope: .personal),
                Permission(resource: .calendar, action: .update, scope: .personal)
            ])
            
        case .guest:
            return Set([
                Permission(resource: .documents, action: .read, scope: .personal),
                Permission(resource: .reports, action: .read, scope: .personal)
            ])
        }
    }
}

enum SystemRoleType: CaseIterable {
    case admin, manager, user, guest
    
    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .manager: return "Manager"
        case .user: return "User"
        case .guest: return "Guest"
        }
    }
}
