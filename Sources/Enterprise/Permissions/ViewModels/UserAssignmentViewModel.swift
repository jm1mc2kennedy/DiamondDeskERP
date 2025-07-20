//
//  UserAssignmentViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import SwiftUI
import Combine
import CloudKit

/// ViewModel for user role assignments
/// Handles assignment creation, modification, and bulk operations
@MainActor
final class UserAssignmentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var users: [UserProfile] = []
    @Published var roles: [UserRole] = []
    @Published var assignments: [UserRoleAssignment] = []
    @Published var selectedUser: UserProfile?
    @Published var selectedAssignments: Set<UUID> = []
    
    // MARK: - Form State
    
    @Published var assignmentUserId = ""
    @Published var assignmentRoleId: UUID?
    @Published var assignmentScope: UserRoleAssignment.AssignmentScope = .organization
    @Published var assignmentScopeValues: [String] = []
    @Published var assignmentValidUntil: Date?
    @Published var assignmentReason = ""
    @Published var assignmentPriority = 5
    
    // MARK: - Bulk Operations
    
    @Published var bulkSelectedUsers: Set<String> = []
    @Published var bulkRoleId: UUID?
    @Published var bulkScope: UserRoleAssignment.AssignmentScope = .organization
    @Published var bulkScopeValues: [String] = []
    @Published var bulkValidUntil: Date?
    @Published var bulkReason = ""
    
    // MARK: - UI State
    
    @Published var isLoading = false
    @Published var showingAssignmentForm = false
    @Published var showingBulkAssignment = false
    @Published var showingUserDetail = false
    @Published var showingRevokeConfirmation = false
    @Published var showingBulkRevoke = false
    @Published var error: PermissionError?
    @Published var showingError = false
    @Published var showingImportSheet = false
    @Published var showingExportSheet = false
    
    // MARK: - Filtering and Search
    
    @Published var searchText = ""
    @Published var selectedRoleFilter: UUID?
    @Published var selectedScopeFilter: UserRoleAssignment.AssignmentScope?
    @Published var showActiveOnly = true
    @Published var showExpiredAssignments = false
    @Published var assignmentDateRange: ClosedRange<Date>?
    
    // MARK: - Private Properties
    
    private let permissionsService = UnifiedPermissionsService.shared
    private let userProvisioningService = UserProvisioningService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredUsers: [UserProfile] {
        var filtered = users
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.userId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.displayName < $1.displayName }
    }
    
    var filteredAssignments: [UserRoleAssignment] {
        var filtered = assignments
        
        // Active filter
        if showActiveOnly {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Expired filter
        if !showExpiredAssignments {
            filtered = filtered.filter { !$0.isExpired }
        }
        
        // User filter
        if let selectedUser = selectedUser {
            filtered = filtered.filter { $0.userId == selectedUser.userId }
        }
        
        // Role filter
        if let selectedRoleFilter = selectedRoleFilter {
            filtered = filtered.filter { $0.roleId == selectedRoleFilter }
        }
        
        // Scope filter
        if let selectedScopeFilter = selectedScopeFilter {
            filtered = filtered.filter { $0.scope == selectedScopeFilter }
        }
        
        // Date range filter
        if let dateRange = assignmentDateRange {
            filtered = filtered.filter { dateRange.contains($0.assignedAt) }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.userId.localizedCaseInsensitiveContains(searchText) ||
                $0.reason?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.assignedBy.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.assignedAt > $1.assignedAt }
    }
    
    var availableScopes: [UserRoleAssignment.AssignmentScope] {
        UserRoleAssignment.AssignmentScope.allCases
    }
    
    var canAssignRoles: Bool {
        Task {
            return await permissionsService.hasPermission(.assign, on: .roles)
        }
        return false // Placeholder
    }
    
    var canRevokeRoles: Bool {
        Task {
            return await permissionsService.hasPermission(.revoke, on: .roles)
        }
        return false // Placeholder
    }
    
    var canBulkAssign: Bool {
        Task {
            return await permissionsService.hasPermission(.bulkAssign, on: .roles)
        }
        return false // Placeholder
    }
    
    var selectedAssignmentsList: [UserRoleAssignment] {
        assignments.filter { selectedAssignments.contains($0.id) }
    }
    
    var assignmentStats: AssignmentStats {
        let active = assignments.filter { $0.isActive }.count
        let expired = assignments.filter { $0.isExpired }.count
        let total = assignments.count
        
        return AssignmentStats(
            total: total,
            active: active,
            expired: expired,
            pending: total - active - expired
        )
    }
    
    // MARK: - Initialization
    
    init() {
        observeServices()
        loadData()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadUsers() }
                group.addTask { await self.loadRoles() }
                group.addTask { await self.loadAssignments() }
            }
        }
    }
    
    func loadUsers() async {
        do {
            let userProfiles = try await userProvisioningService.getAllUsers()
            await MainActor.run {
                self.users = userProfiles
            }
        } catch {
            handleError(error)
        }
    }
    
    func loadRoles() async {
        let roles = await permissionsService.getAccessibleRoles()
        await MainActor.run {
            self.roles = roles
        }
    }
    
    func loadAssignments() async {
        // This would be implemented in the service to fetch all assignments
        await MainActor.run {
            self.assignments = permissionsService.roleAssignments
        }
    }
    
    // MARK: - Assignment Operations
    
    func assignRole() {
        guard let roleId = assignmentRoleId else { return }
        
        Task {
            do {
                isLoading = true
                
                try await permissionsService.assignRole(
                    roleId,
                    to: assignmentUserId,
                    scope: assignmentScope,
                    scopeValues: assignmentScopeValues,
                    validUntil: assignmentValidUntil,
                    reason: assignmentReason.isEmpty ? nil : assignmentReason
                )
                
                resetAssignmentForm()
                showingAssignmentForm = false
                await loadAssignments()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func revokeAssignment(_ assignment: UserRoleAssignment) {
        Task {
            do {
                isLoading = true
                
                try await permissionsService.revokeRole(
                    assignment.roleId,
                    from: assignment.userId,
                    reason: "Revoked via assignment management"
                )
                
                await loadAssignments()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func bulkAssignRoles() {
        guard let roleId = bulkRoleId, !bulkSelectedUsers.isEmpty else { return }
        
        Task {
            do {
                isLoading = true
                
                for userId in bulkSelectedUsers {
                    try await permissionsService.assignRole(
                        roleId,
                        to: userId,
                        scope: bulkScope,
                        scopeValues: bulkScopeValues,
                        validUntil: bulkValidUntil,
                        reason: bulkReason.isEmpty ? "Bulk assignment" : bulkReason
                    )
                }
                
                resetBulkForm()
                showingBulkAssignment = false
                await loadAssignments()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func bulkRevokeAssignments() {
        Task {
            do {
                isLoading = true
                
                for assignment in selectedAssignmentsList {
                    try await permissionsService.revokeRole(
                        assignment.roleId,
                        from: assignment.userId,
                        reason: "Bulk revocation"
                    )
                }
                
                selectedAssignments.removeAll()
                showingBulkRevoke = false
                await loadAssignments()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func extendAssignment(_ assignment: UserRoleAssignment, until date: Date) {
        Task {
            do {
                isLoading = true
                
                // This would be implemented in the service
                // For now, we'll revoke and reassign with new date
                try await permissionsService.revokeRole(
                    assignment.roleId,
                    from: assignment.userId,
                    reason: "Extension - revoking old assignment"
                )
                
                try await permissionsService.assignRole(
                    assignment.roleId,
                    to: assignment.userId,
                    scope: assignment.scope,
                    scopeValues: assignment.scopeValues,
                    validUntil: date,
                    reason: "Assignment extended until \(date.formatted())"
                )
                
                await loadAssignments()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    // MARK: - User Management
    
    func selectUser(_ user: UserProfile) {
        selectedUser = user
        assignmentUserId = user.userId
    }
    
    func getUserAssignments(_ userId: String) -> [UserRoleAssignment] {
        return assignments.filter { $0.userId == userId && $0.isActive }
    }
    
    func getUserEffectiveRoles(_ userId: String) -> [UserRole] {
        let userAssignments = getUserAssignments(userId)
        return roles.filter { role in
            userAssignments.contains { $0.roleId == role.id }
        }
    }
    
    func getUserPermissionSummary(_ userId: String) async -> Set<Permission> {
        // This would need to be implemented with user context switching
        return await permissionsService.getUserEffectivePermissions(userId)
    }
    
    // MARK: - Import/Export
    
    func exportAssignments() -> URL? {
        let csv = generateAssignmentsCSV()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("role_assignments_\(Date().timeIntervalSince1970).csv")
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            handleError(error)
            return nil
        }
    }
    
    func importAssignments(from url: URL) {
        Task {
            do {
                let csvContent = try String(contentsOf: url)
                try await processAssignmentImport(csvContent)
                await loadAssignments()
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Utility
    
    func getRoleName(for roleId: UUID) -> String {
        return roles.first { $0.id == roleId }?.displayName ?? "Unknown Role"
    }
    
    func getUserName(for userId: String) -> String {
        return users.first { $0.userId == userId }?.displayName ?? userId
    }
    
    func getScopeDisplayName(_ scope: UserRoleAssignment.AssignmentScope) -> String {
        switch scope {
        case .organization: return "Organization"
        case .department: return "Department"
        case .project: return "Project"
        case .personal: return "Personal"
        }
    }
    
    func formatScopeValues(_ values: [String], for scope: UserRoleAssignment.AssignmentScope) -> String {
        guard !values.isEmpty else { return "All" }
        return values.joined(separator: ", ")
    }
    
    // MARK: - Private Methods
    
    private func observeServices() {
        permissionsService.$roleAssignments
            .sink { [weak self] assignments in
                self?.assignments = assignments
            }
            .store(in: &cancellables)
        
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
    
    private func resetAssignmentForm() {
        assignmentUserId = ""
        assignmentRoleId = nil
        assignmentScope = .organization
        assignmentScopeValues = []
        assignmentValidUntil = nil
        assignmentReason = ""
        assignmentPriority = 5
    }
    
    private func resetBulkForm() {
        bulkSelectedUsers = []
        bulkRoleId = nil
        bulkScope = .organization
        bulkScopeValues = []
        bulkValidUntil = nil
        bulkReason = ""
    }
    
    private func handleError(_ error: Error) {
        self.error = error as? PermissionError ?? PermissionError.loadFailed(error)
        showingError = true
    }
    
    private func generateAssignmentsCSV() -> String {
        var csv = "User ID,User Name,Role ID,Role Name,Scope,Scope Values,Assigned At,Valid Until,Assigned By,Reason,Active\n"
        
        for assignment in filteredAssignments {
            let userName = getUserName(for: assignment.userId)
            let roleName = getRoleName(for: assignment.roleId)
            let scopeValues = formatScopeValues(assignment.scopeValues, for: assignment.scope)
            let validUntil = assignment.validUntil?.formatted() ?? "Permanent"
            let reason = assignment.reason?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(assignment.userId),\(userName),\(assignment.roleId),\(roleName),\(assignment.scope.rawValue),\(scopeValues),\(assignment.assignedAt.formatted()),\(validUntil),\(assignment.assignedBy),\(reason),\(assignment.isActive)\n"
        }
        
        return csv
    }
    
    private func processAssignmentImport(_ csvContent: String) async throws {
        let lines = csvContent.components(separatedBy: .newlines).dropFirst() // Skip header
        
        for line in lines {
            guard !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 6 else { continue }
            
            let userId = components[0].trimmingCharacters(in: .whitespaces)
            guard let roleId = UUID(uuidString: components[2].trimmingCharacters(in: .whitespaces)) else { continue }
            
            let scopeString = components[4].trimmingCharacters(in: .whitespaces)
            guard let scope = UserRoleAssignment.AssignmentScope(rawValue: scopeString) else { continue }
            
            let scopeValues = components[5].trimmingCharacters(in: .whitespaces)
                .components(separatedBy: ";")
                .filter { !$0.isEmpty }
            
            let reason = components.count > 9 ? components[9].trimmingCharacters(in: .whitespaces) : "Imported assignment"
            
            try await permissionsService.assignRole(
                roleId,
                to: userId,
                scope: scope,
                scopeValues: scopeValues,
                validUntil: nil, // Don't import expiration dates
                reason: reason
            )
        }
    }
}

// MARK: - Supporting Types

struct AssignmentStats {
    let total: Int
    let active: Int
    let expired: Int
    let pending: Int
    
    var activePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(active) / Double(total) * 100
    }
    
    var expiredPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(expired) / Double(total) * 100
    }
}
