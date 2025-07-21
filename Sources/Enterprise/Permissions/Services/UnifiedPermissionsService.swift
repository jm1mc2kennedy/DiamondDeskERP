//
//  UnifiedPermissionsService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine

/// Unified Permissions Framework
/// Central authorization system for enterprise-wide access control
@MainActor
final class UnifiedPermissionsService: ObservableObject {
    
    static let shared = UnifiedPermissionsService()
    
    // MARK: - Published Properties
    
    @Published var permissionPolicies: [PermissionPolicy] = []
    @Published var roleDefinitions: [RoleDefinition] = []
    @Published var userPermissions: [String: UserPermissions] = [:]
    @Published var resourcePermissions: [String: ResourcePermissions] = [:]
    @Published var permissionGroups: [PermissionGroup] = []
    @Published var accessControlLists: [AccessControlList] = []
    @Published var isLoading = false
    @Published var error: PermissionsError?
    
    // MARK: - Permission Audit Properties
    
    @Published var permissionAuditLogs: [PermissionAuditLog] = []
    @Published var securityMetrics: SecurityMetrics?
    @Published var complianceStatus: ComplianceStatus?
    
    // MARK: - Private Properties
    
    private let container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
    private var database: CKDatabase { container.privateCloudDatabase }
    private var cancellables = Set<AnyCancellable>()
    private let cacheService = PermissionCacheService()
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultRoles()
        setupDefaultPolicies()
        loadPermissionData()
    }
    
    // MARK: - Permission Checking
    
    /// Checks if user has permission for specific action on resource
    func hasPermission(
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        context: PermissionContext? = nil
    ) async -> Bool {
        // Check cache first
        if let cachedResult = cacheService.getCachedPermission(
            userId: userId,
            action: action,
            resource: resource
        ) {
            return cachedResult
        }
        
        do {
            let result = try await evaluatePermission(
                userId: userId,
                action: action,
                resource: resource,
                context: context
            )
            
            // Cache result
            cacheService.cachePermission(
                userId: userId,
                action: action,
                resource: resource,
                result: result
            )
            
            // Log permission check
            await logPermissionCheck(
                userId: userId,
                action: action,
                resource: resource,
                result: result,
                context: context
            )
            
            return result
            
        } catch {
            await handleError(PermissionsError.permissionCheckFailed(error))
            return false
        }
    }
    
    /// Evaluates complex permission with multiple conditions
    func evaluateComplexPermission(
        userId: String,
        actions: [PermissionAction],
        resources: [PermissionResource],
        conditions: [PermissionCondition] = [],
        context: PermissionContext? = nil
    ) async -> PermissionEvaluationResult {
        var results: [PermissionAction: Bool] = [:]
        var evaluationDetails: [PermissionEvaluationDetail] = []
        
        for action in actions {
            for resource in resources {
                let hasPermission = await hasPermission(
                    userId: userId,
                    action: action,
                    resource: resource,
                    context: context
                )
                
                results[action] = hasPermission
                
                evaluationDetails.append(PermissionEvaluationDetail(
                    action: action,
                    resource: resource,
                    hasPermission: hasPermission,
                    appliedPolicies: getAppliedPolicies(userId: userId, action: action, resource: resource),
                    evaluatedAt: Date()
                ))
            }
        }
        
        // Check additional conditions
        let conditionsResult = await evaluateConditions(conditions, context: context)
        
        return PermissionEvaluationResult(
            userId: userId,
            results: results,
            conditionsResult: conditionsResult,
            evaluationDetails: evaluationDetails,
            evaluatedAt: Date()
        )
    }
    
    // MARK: - Role Management
    
    /// Assigns role to user
    func assignRole(
        userId: String,
        roleId: String,
        scope: PermissionScope = .global,
        expirationDate: Date? = nil,
        assignedBy: String
    ) async throws {
        guard let role = roleDefinitions.first(where: { $0.id == roleId }) else {
            throw PermissionsError.roleNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let roleAssignment = RoleAssignment(
                id: UUID().uuidString,
                userId: userId,
                roleId: roleId,
                scope: scope,
                assignedBy: assignedBy,
                assignedAt: Date(),
                expirationDate: expirationDate,
                isActive: true
            )
            
            // Save to CloudKit
            try await saveRoleAssignment(roleAssignment)
            
            // Update user permissions
            try await updateUserPermissions(userId: userId)
            
            // Clear cache for user
            cacheService.clearUserCache(userId: userId)
            
            // Log role assignment
            await logPermissionChange(
                .roleAssigned,
                userId: userId,
                changedBy: assignedBy,
                details: "Role '\(role.name)' assigned to user"
            )
            
        } catch {
            await handleError(PermissionsError.roleAssignmentFailed(error))
            throw error
        }
    }
    
    /// Revokes role from user
    func revokeRole(
        userId: String,
        roleId: String,
        revokedBy: String,
        reason: String? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Find and deactivate role assignment
            let assignments = try await fetchRoleAssignments(userId: userId)
            guard let assignment = assignments.first(where: { $0.roleId == roleId && $0.isActive }) else {
                throw PermissionsError.roleAssignmentNotFound
            }
            
            assignment.isActive = false
            assignment.revokedAt = Date()
            assignment.revokedBy = revokedBy
            assignment.revocationReason = reason
            
            try await saveRoleAssignment(assignment)
            
            // Update user permissions
            try await updateUserPermissions(userId: userId)
            
            // Clear cache for user
            cacheService.clearUserCache(userId: userId)
            
            // Log role revocation
            await logPermissionChange(
                .roleRevoked,
                userId: userId,
                changedBy: revokedBy,
                details: "Role '\(roleId)' revoked from user. Reason: \(reason ?? "No reason provided")"
            )
            
        } catch {
            await handleError(PermissionsError.roleRevocationFailed(error))
            throw error
        }
    }
    
    // MARK: - Permission Policy Management
    
    /// Creates a new permission policy
    func createPermissionPolicy(
        name: String,
        description: String,
        rules: [PermissionRule],
        scope: PermissionScope,
        priority: PolicyPriority = .normal,
        isActive: Bool = true,
        createdBy: String
    ) async throws -> PermissionPolicy {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let policy = PermissionPolicy(
                id: UUID().uuidString,
                name: name,
                description: description,
                rules: rules,
                scope: scope,
                priority: priority,
                isActive: isActive,
                createdBy: createdBy,
                createdAt: Date()
            )
            
            // Validate policy
            try validatePolicy(policy)
            
            // Save to CloudKit
            try await savePermissionPolicy(policy)
            
            // Update local state
            permissionPolicies.append(policy)
            
            // Clear relevant caches
            cacheService.clearAllCache()
            
            // Log policy creation
            await logPermissionChange(
                .policyCreated,
                userId: createdBy,
                changedBy: createdBy,
                details: "Permission policy '\(name)' created"
            )
            
            return policy
            
        } catch {
            await handleError(PermissionsError.policyCreationFailed(error))
            throw error
        }
    }
    
    /// Updates an existing permission policy
    func updatePermissionPolicy(
        policyId: String,
        name: String? = nil,
        description: String? = nil,
        rules: [PermissionRule]? = nil,
        isActive: Bool? = nil,
        modifiedBy: String
    ) async throws {
        guard let policy = permissionPolicies.first(where: { $0.id == policyId }) else {
            throw PermissionsError.policyNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update policy properties
            if let name = name { policy.name = name }
            if let description = description { policy.description = description }
            if let rules = rules { policy.rules = rules }
            if let isActive = isActive { policy.isActive = isActive }
            
            policy.modifiedBy = modifiedBy
            policy.modifiedAt = Date()
            
            // Validate updated policy
            try validatePolicy(policy)
            
            // Save to CloudKit
            try await savePermissionPolicy(policy)
            
            // Clear relevant caches
            cacheService.clearAllCache()
            
            // Log policy update
            await logPermissionChange(
                .policyUpdated,
                userId: modifiedBy,
                changedBy: modifiedBy,
                details: "Permission policy '\(policy.name)' updated"
            )
            
        } catch {
            await handleError(PermissionsError.policyUpdateFailed(error))
            throw error
        }
    }
    
    // MARK: - Resource Permission Management
    
    /// Sets permissions for a specific resource
    func setResourcePermissions(
        resourceId: String,
        resourceType: ResourceType,
        permissions: [PermissionGrant],
        inheritFromParent: Bool = true,
        setBy: String
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let resourcePermissions = ResourcePermissions(
                resourceId: resourceId,
                resourceType: resourceType,
                permissions: permissions,
                inheritFromParent: inheritFromParent,
                setBy: setBy,
                setAt: Date()
            )
            
            // Save to CloudKit
            try await saveResourcePermissions(resourcePermissions)
            
            // Update local state
            self.resourcePermissions[resourceId] = resourcePermissions
            
            // Clear relevant caches
            cacheService.clearResourceCache(resourceId: resourceId)
            
            // Log resource permission change
            await logPermissionChange(
                .resourcePermissionsSet,
                userId: setBy,
                changedBy: setBy,
                details: "Permissions set for resource \(resourceId) of type \(resourceType.displayName)"
            )
            
        } catch {
            await handleError(PermissionsError.resourcePermissionsFailed(error))
            throw error
        }
    }
    
    /// Inherits permissions from parent resource
    func inheritResourcePermissions(
        childResourceId: String,
        parentResourceId: String,
        inheritedBy: String
    ) async throws {
        guard let parentPermissions = resourcePermissions[parentResourceId] else {
            throw PermissionsError.parentResourceNotFound
        }
        
        try await setResourcePermissions(
            resourceId: childResourceId,
            resourceType: parentPermissions.resourceType,
            permissions: parentPermissions.permissions,
            inheritFromParent: true,
            setBy: inheritedBy
        )
    }
    
    // MARK: - Access Control Lists
    
    /// Creates an Access Control List for a resource
    func createAccessControlList(
        resourceId: String,
        resourceType: ResourceType,
        entries: [ACLEntry],
        inheritanceRules: [InheritanceRule] = [],
        createdBy: String
    ) async throws -> AccessControlList {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let acl = AccessControlList(
                id: UUID().uuidString,
                resourceId: resourceId,
                resourceType: resourceType,
                entries: entries,
                inheritanceRules: inheritanceRules,
                createdBy: createdBy,
                createdAt: Date()
            )
            
            // Save to CloudKit
            try await saveAccessControlList(acl)
            
            // Update local state
            accessControlLists.append(acl)
            
            // Clear relevant caches
            cacheService.clearResourceCache(resourceId: resourceId)
            
            // Log ACL creation
            await logPermissionChange(
                .aclCreated,
                userId: createdBy,
                changedBy: createdBy,
                details: "Access Control List created for resource \(resourceId)"
            )
            
            return acl
            
        } catch {
            await handleError(PermissionsError.aclCreationFailed(error))
            throw error
        }
    }
    
    // MARK: - Permission Auditing
    
    /// Generates security audit report
    func generateSecurityAuditReport(
        timeRange: TimeRange,
        includePermissionChanges: Bool = true,
        includeAccessAttempts: Bool = true,
        includeViolations: Bool = true
    ) async throws -> SecurityAuditReport {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = timeRange.startDate
            let endDate = Date()
            
            let auditLogs = permissionAuditLogs.filter {
                $0.timestamp >= startDate && $0.timestamp <= endDate
            }
            
            let report = SecurityAuditReport(
                id: UUID().uuidString,
                generatedAt: Date(),
                timeRange: timeRange,
                totalPermissionChecks: auditLogs.filter { $0.action == .permissionChecked }.count,
                successfulChecks: auditLogs.filter { $0.action == .permissionChecked && $0.result == .granted }.count,
                deniedChecks: auditLogs.filter { $0.action == .permissionChecked && $0.result == .denied }.count,
                permissionChanges: includePermissionChanges ? auditLogs.filter { $0.action.isChangeAction } : [],
                securityViolations: includeViolations ? identifySecurityViolations(auditLogs) : [],
                userActivitySummary: generateUserActivitySummary(auditLogs),
                resourceAccessSummary: generateResourceAccessSummary(auditLogs),
                riskAssessment: assessSecurityRisk(auditLogs)
            )
            
            return report
            
        } catch {
            await handleError(PermissionsError.auditReportFailed(error))
            throw error
        }
    }
    
    /// Loads security metrics
    func loadSecurityMetrics(timeRange: TimeRange = .lastMonth) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let metrics = try await fetchSecurityMetrics(timeRange: timeRange)
            self.securityMetrics = metrics
            
        } catch {
            await handleError(PermissionsError.metricsFailed(error))
            throw error
        }
    }
    
    // MARK: - Private Implementation
    
    private func evaluatePermission(
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        context: PermissionContext?
    ) async throws -> Bool {
        // Get user's effective permissions
        let userPerms = try await getEffectiveUserPermissions(userId: userId)
        
        // Check direct permissions
        if let directPermission = userPerms.directPermissions[action] {
            if directPermission.applies(to: resource) {
                return directPermission.isGranted
            }
        }
        
        // Check role-based permissions
        for roleId in userPerms.roleIds {
            if let role = roleDefinitions.first(where: { $0.id == roleId }) {
                for permission in role.permissions {
                    if permission.action == action && permission.applies(to: resource) {
                        return permission.isGranted
                    }
                }
            }
        }
        
        // Check policy-based permissions
        let applicablePolicies = getApplicablePolicies(
            userId: userId,
            action: action,
            resource: resource,
            context: context
        )
        
        for policy in applicablePolicies {
            let policyResult = evaluatePolicy(policy, userId: userId, action: action, resource: resource, context: context)
            if policyResult != .notApplicable {
                return policyResult == .granted
            }
        }
        
        // Check resource-specific permissions
        if let resourcePerms = resourcePermissions[resource.id] {
            for grant in resourcePerms.permissions {
                if grant.action == action && grant.principalId == userId {
                    return grant.isGranted
                }
            }
        }
        
        // Check ACL
        let acls = accessControlLists.filter { $0.resourceId == resource.id }
        for acl in acls {
            for entry in acl.entries {
                if entry.principalId == userId && entry.action == action {
                    return entry.isGranted
                }
            }
        }
        
        // Default deny
        return false
    }
    
    private func getEffectiveUserPermissions(userId: String) async throws -> UserPermissions {
        if let cached = userPermissions[userId] {
            return cached
        }
        
        // Fetch and compute user permissions
        let assignments = try await fetchRoleAssignments(userId: userId)
        let activeRoles = assignments.filter { $0.isActive && !$0.isExpired }
        
        let userPerms = UserPermissions(
            userId: userId,
            roleIds: activeRoles.map { $0.roleId },
            directPermissions: [:], // Would be populated from direct grants
            effectivePermissions: [:], // Computed from roles and policies
            lastUpdated: Date()
        )
        
        userPermissions[userId] = userPerms
        return userPerms
    }
    
    private func getApplicablePolicies(
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        context: PermissionContext?
    ) -> [PermissionPolicy] {
        return permissionPolicies.filter { policy in
            policy.isActive && policy.applies(to: userId, action: action, resource: resource, context: context)
        }.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func evaluatePolicy(
        _ policy: PermissionPolicy,
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        context: PermissionContext?
    ) -> PolicyResult {
        for rule in policy.rules {
            let ruleResult = evaluateRule(rule, userId: userId, action: action, resource: resource, context: context)
            if ruleResult != .notApplicable {
                return ruleResult
            }
        }
        return .notApplicable
    }
    
    private func evaluateRule(
        _ rule: PermissionRule,
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        context: PermissionContext?
    ) -> PolicyResult {
        // Check if rule applies
        guard rule.conditions.allSatisfy({ condition in
            evaluateCondition(condition, userId: userId, action: action, resource: resource, context: context)
        }) else {
            return .notApplicable
        }
        
        return rule.effect == .allow ? .granted : .denied
    }
    
    private func evaluateCondition(
        _ condition: PermissionCondition,
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        context: PermissionContext?
    ) -> Bool {
        switch condition.type {
        case .userAttribute:
            return evaluateUserAttributeCondition(condition, userId: userId)
        case .resourceAttribute:
            return evaluateResourceAttributeCondition(condition, resource: resource)
        case .contextual:
            return evaluateContextualCondition(condition, context: context)
        case .temporal:
            return evaluateTemporalCondition(condition)
        case .environmental:
            return evaluateEnvironmentalCondition(condition, context: context)
        }
    }
    
    private func evaluateConditions(_ conditions: [PermissionCondition], context: PermissionContext?) async -> Bool {
        return conditions.allSatisfy { condition in
            // Simplified evaluation - would be more complex in real implementation
            true
        }
    }
    
    private func evaluateUserAttributeCondition(_ condition: PermissionCondition, userId: String) -> Bool {
        // Implementation would check user attributes against condition
        return true
    }
    
    private func evaluateResourceAttributeCondition(_ condition: PermissionCondition, resource: PermissionResource) -> Bool {
        // Implementation would check resource attributes against condition
        return true
    }
    
    private func evaluateContextualCondition(_ condition: PermissionCondition, context: PermissionContext?) -> Bool {
        // Implementation would check context against condition
        return true
    }
    
    private func evaluateTemporalCondition(_ condition: PermissionCondition) -> Bool {
        // Implementation would check time-based conditions
        return true
    }
    
    private func evaluateEnvironmentalCondition(_ condition: PermissionCondition, context: PermissionContext?) -> Bool {
        // Implementation would check environmental conditions (location, device, etc.)
        return true
    }
    
    private func getAppliedPolicies(userId: String, action: PermissionAction, resource: PermissionResource) -> [String] {
        return getApplicablePolicies(userId: userId, action: action, resource: resource, context: nil).map { $0.id }
    }
    
    // MARK: - Setup Methods
    
    private func setupDefaultRoles() {
        roleDefinitions = [
            RoleDefinition(
                id: "admin",
                name: "Administrator",
                description: "Full system administrator",
                permissions: [
                    Permission(action: .create, resource: .any, isGranted: true),
                    Permission(action: .read, resource: .any, isGranted: true),
                    Permission(action: .update, resource: .any, isGranted: true),
                    Permission(action: .delete, resource: .any, isGranted: true),
                    Permission(action: .manage, resource: .any, isGranted: true)
                ],
                isSystemRole: true
            ),
            RoleDefinition(
                id: "manager",
                name: "Manager",
                description: "Department manager",
                permissions: [
                    Permission(action: .create, resource: .document, isGranted: true),
                    Permission(action: .read, resource: .document, isGranted: true),
                    Permission(action: .update, resource: .document, isGranted: true),
                    Permission(action: .approve, resource: .document, isGranted: true),
                    Permission(action: .manage, resource: .team, isGranted: true)
                ],
                isSystemRole: true
            ),
            RoleDefinition(
                id: "user",
                name: "User",
                description: "Standard user",
                permissions: [
                    Permission(action: .create, resource: .document, isGranted: true),
                    Permission(action: .read, resource: .document, isGranted: true),
                    Permission(action: .update, resource: .ownDocument, isGranted: true)
                ],
                isSystemRole: true
            ),
            RoleDefinition(
                id: "viewer",
                name: "Viewer",
                description: "Read-only access",
                permissions: [
                    Permission(action: .read, resource: .document, isGranted: true)
                ],
                isSystemRole: true
            )
        ]
    }
    
    private func setupDefaultPolicies() {
        permissionPolicies = [
            PermissionPolicy(
                id: "security-policy",
                name: "Security Policy",
                description: "Basic security and access control policy",
                rules: [
                    PermissionRule(
                        id: "admin-full-access",
                        conditions: [
                            PermissionCondition(
                                type: .userAttribute,
                                attribute: "role",
                                operator: .equals,
                                value: "admin"
                            )
                        ],
                        effect: .allow
                    ),
                    PermissionRule(
                        id: "owner-access",
                        conditions: [
                            PermissionCondition(
                                type: .resourceAttribute,
                                attribute: "owner",
                                operator: .equals,
                                value: "{{user.id}}"
                            )
                        ],
                        effect: .allow
                    )
                ],
                scope: .global,
                priority: .high,
                isActive: true,
                createdBy: "system",
                createdAt: Date()
            )
        ]
    }
    
    private func loadPermissionData() {
        Task {
            do {
                // Load permission data from CloudKit
                let policies = try await fetchPermissionPolicies()
                let roles = try await fetchRoleDefinitions()
                let groups = try await fetchPermissionGroups()
                let acls = try await fetchAccessControlLists()
                
                await MainActor.run {
                    self.permissionPolicies.append(contentsOf: policies)
                    self.roleDefinitions.append(contentsOf: roles)
                    self.permissionGroups = groups
                    self.accessControlLists = acls
                }
            } catch {
                await handleError(PermissionsError.loadFailed(error))
            }
        }
    }
    
    // MARK: - Validation
    
    private func validatePolicy(_ policy: PermissionPolicy) throws {
        // Validate policy rules and conditions
        for rule in policy.rules {
            for condition in rule.conditions {
                if condition.attribute.isEmpty || condition.value.isEmpty {
                    throw PermissionsError.invalidPolicyRule
                }
            }
        }
    }
    
    // MARK: - CloudKit Operations
    
    private func savePermissionPolicy(_ policy: PermissionPolicy) async throws {
        let record = policy.toCKRecord()
        try await database.save(record)
    }
    
    private func saveRoleAssignment(_ assignment: RoleAssignment) async throws {
        let record = assignment.toCKRecord()
        try await database.save(record)
    }
    
    private func saveResourcePermissions(_ permissions: ResourcePermissions) async throws {
        let record = permissions.toCKRecord()
        try await database.save(record)
    }
    
    private func saveAccessControlList(_ acl: AccessControlList) async throws {
        let record = acl.toCKRecord()
        try await database.save(record)
    }
    
    // MARK: - Fetch Operations
    
    private func fetchPermissionPolicies() async throws -> [PermissionPolicy] {
        return []
    }
    
    private func fetchRoleDefinitions() async throws -> [RoleDefinition] {
        return []
    }
    
    private func fetchPermissionGroups() async throws -> [PermissionGroup] {
        return []
    }
    
    private func fetchAccessControlLists() async throws -> [AccessControlList] {
        return []
    }
    
    private func fetchRoleAssignments(userId: String) async throws -> [RoleAssignment] {
        return []
    }
    
    private func fetchSecurityMetrics(timeRange: TimeRange) async throws -> SecurityMetrics {
        return SecurityMetrics(
            totalPermissionChecks: 0,
            successfulChecks: 0,
            deniedChecks: 0,
            uniqueUsers: 0,
            uniqueResources: 0,
            averageResponseTime: 0,
            securityScore: 85.0,
            riskLevel: .medium
        )
    }
    
    // MARK: - Utility Methods
    
    private func updateUserPermissions(userId: String) async throws {
        // Recompute and update user's effective permissions
        userPermissions.removeValue(forKey: userId)
        _ = try await getEffectiveUserPermissions(userId: userId)
    }
    
    private func logPermissionCheck(
        userId: String,
        action: PermissionAction,
        resource: PermissionResource,
        result: Bool,
        context: PermissionContext?
    ) async {
        let auditLog = PermissionAuditLog(
            id: UUID().uuidString,
            timestamp: Date(),
            userId: userId,
            action: .permissionChecked,
            resource: resource.id,
            result: result ? .granted : .denied,
            context: context?.toDictionary()
        )
        
        permissionAuditLogs.append(auditLog)
        
        // Save to CloudKit (async)
        Task {
            try? await savePermissionAuditLog(auditLog)
        }
    }
    
    private func logPermissionChange(
        _ changeType: PermissionAuditAction,
        userId: String,
        changedBy: String,
        details: String
    ) async {
        let auditLog = PermissionAuditLog(
            id: UUID().uuidString,
            timestamp: Date(),
            userId: userId,
            action: changeType,
            resource: nil,
            result: .granted,
            context: ["changed_by": changedBy, "details": details]
        )
        
        permissionAuditLogs.append(auditLog)
        
        // Save to CloudKit (async)
        Task {
            try? await savePermissionAuditLog(auditLog)
        }
    }
    
    private func savePermissionAuditLog(_ log: PermissionAuditLog) async throws {
        let record = log.toCKRecord()
        try await database.save(record)
    }
    
    private func identifySecurityViolations(_ auditLogs: [PermissionAuditLog]) -> [SecurityViolation] {
        var violations: [SecurityViolation] = []
        
        // Identify suspicious patterns
        let deniedAttempts = auditLogs.filter { $0.result == .denied }
        let userAttempts = Dictionary(grouping: deniedAttempts) { $0.userId }
        
        for (userId, attempts) in userAttempts {
            if attempts.count > 10 { // Configurable threshold
                violations.append(SecurityViolation(
                    id: UUID().uuidString,
                    type: .excessiveDeniedAttempts,
                    severity: .high,
                    userId: userId,
                    description: "User has \(attempts.count) denied permission attempts",
                    detectedAt: Date(),
                    relatedLogs: attempts.map { $0.id }
                ))
            }
        }
        
        return violations
    }
    
    private func generateUserActivitySummary(_ auditLogs: [PermissionAuditLog]) -> [UserActivitySummary] {
        let userGroups = Dictionary(grouping: auditLogs) { $0.userId }
        
        return userGroups.map { (userId, logs) in
            UserActivitySummary(
                userId: userId,
                totalChecks: logs.count,
                successfulChecks: logs.filter { $0.result == .granted }.count,
                deniedChecks: logs.filter { $0.result == .denied }.count,
                uniqueResources: Set(logs.compactMap { $0.resource }).count,
                lastActivity: logs.max { $0.timestamp < $1.timestamp }?.timestamp ?? Date()
            )
        }
    }
    
    private func generateResourceAccessSummary(_ auditLogs: [PermissionAuditLog]) -> [ResourceAccessSummary] {
        let resourceGroups = Dictionary(grouping: auditLogs.compactMap { log in
            guard let resource = log.resource else { return nil }
            return (resource, log)
        }) { $0.0 }
        
        return resourceGroups.map { (resourceId, logs) in
            ResourceAccessSummary(
                resourceId: resourceId,
                totalAccesses: logs.count,
                successfulAccesses: logs.filter { $0.1.result == .granted }.count,
                deniedAccesses: logs.filter { $0.1.result == .denied }.count,
                uniqueUsers: Set(logs.map { $0.1.userId }).count,
                lastAccess: logs.max { $0.1.timestamp < $1.1.timestamp }?.1.timestamp ?? Date()
            )
        }
    }
    
    private func assessSecurityRisk(_ auditLogs: [PermissionAuditLog]) -> SecurityRiskAssessment {
        let totalChecks = auditLogs.count
        let deniedChecks = auditLogs.filter { $0.result == .denied }.count
        let denialRate = totalChecks > 0 ? Double(deniedChecks) / Double(totalChecks) : 0
        
        let riskLevel: SecurityRiskLevel = {
            if denialRate > 0.3 { return .high }
            if denialRate > 0.15 { return .medium }
            return .low
        }()
        
        return SecurityRiskAssessment(
            riskLevel: riskLevel,
            riskScore: denialRate * 100,
            factors: [
                "Denial rate: \(String(format: "%.2f", denialRate * 100))%",
                "Total permission checks: \(totalChecks)",
                "Denied attempts: \(deniedChecks)"
            ],
            recommendations: generateSecurityRecommendations(riskLevel: riskLevel, denialRate: denialRate)
        )
    }
    
    private func generateSecurityRecommendations(riskLevel: SecurityRiskLevel, denialRate: Double) -> [String] {
        var recommendations: [String] = []
        
        if riskLevel == .high {
            recommendations.append("Review and update permission policies")
            recommendations.append("Investigate users with excessive denied attempts")
            recommendations.append("Consider implementing additional security measures")
        }
        
        if denialRate > 0.2 {
            recommendations.append("Review role assignments and permissions")
            recommendations.append("Provide additional user training on system access")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Continue monitoring security metrics")
            recommendations.append("Regular security audits recommended")
        }
        
        return recommendations
    }
    
    private func handleError(_ error: PermissionsError) async {
        await MainActor.run {
            self.error = error
        }
    }
}

// MARK: - Permission Cache Service

class PermissionCacheService {
    private var cache: [String: Bool] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    func getCachedPermission(userId: String, action: PermissionAction, resource: PermissionResource) -> Bool? {
        let key = "\(userId):\(action.rawValue):\(resource.id)"
        
        if let timestamp = cacheTimestamps[key],
           Date().timeIntervalSince(timestamp) < cacheExpiration {
            return cache[key]
        }
        
        // Remove expired entry
        cache.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
        
        return nil
    }
    
    func cachePermission(userId: String, action: PermissionAction, resource: PermissionResource, result: Bool) {
        let key = "\(userId):\(action.rawValue):\(resource.id)"
        cache[key] = result
        cacheTimestamps[key] = Date()
    }
    
    func clearUserCache(userId: String) {
        let keysToRemove = cache.keys.filter { $0.hasPrefix("\(userId):") }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    func clearResourceCache(resourceId: String) {
        let keysToRemove = cache.keys.filter { $0.hasSuffix(":\(resourceId)") }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    func clearAllCache() {
        cache.removeAll()
        cacheTimestamps.removeAll()
    }
}

// MARK: - Supporting Models and Types

class PermissionPolicy: ObservableObject, Identifiable {
    let id: String
    @Published var name: String
    @Published var description: String
    @Published var rules: [PermissionRule]
    let scope: PermissionScope
    let priority: PolicyPriority
    @Published var isActive: Bool
    let createdBy: String
    let createdAt: Date
    @Published var modifiedBy: String?
    @Published var modifiedAt: Date?
    
    init(
        id: String,
        name: String,
        description: String,
        rules: [PermissionRule],
        scope: PermissionScope,
        priority: PolicyPriority,
        isActive: Bool,
        createdBy: String,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.rules = rules
        self.scope = scope
        self.priority = priority
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
    
    func applies(to userId: String, action: PermissionAction, resource: PermissionResource, context: PermissionContext?) -> Bool {
        // Implementation would check if policy applies to the given parameters
        return true
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "PermissionPolicy", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["rules"] = try? JSONEncoder().encode(rules)
        record["scope"] = scope.rawValue
        record["priority"] = priority.rawValue
        record["isActive"] = isActive
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["modifiedBy"] = modifiedBy
        record["modifiedAt"] = modifiedAt
        return record
    }
}

struct RoleDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let permissions: [Permission]
    let isSystemRole: Bool
    let createdAt: Date = Date()
}

struct Permission: Codable {
    let action: PermissionAction
    let resource: PermissionResourceType
    let isGranted: Bool
    let conditions: [PermissionCondition] = []
    
    func applies(to resource: PermissionResource) -> Bool {
        return self.resource == .any || self.resource.matches(resource)
    }
}

struct UserPermissions {
    let userId: String
    let roleIds: [String]
    let directPermissions: [PermissionAction: Permission]
    let effectivePermissions: [PermissionAction: Permission]
    let lastUpdated: Date
}

struct ResourcePermissions {
    let resourceId: String
    let resourceType: ResourceType
    let permissions: [PermissionGrant]
    let inheritFromParent: Bool
    let setBy: String
    let setAt: Date
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ResourcePermissions", recordID: CKRecord.ID(recordName: resourceId))
        record["resourceType"] = resourceType.rawValue
        record["permissions"] = try? JSONEncoder().encode(permissions)
        record["inheritFromParent"] = inheritFromParent
        record["setBy"] = setBy
        record["setAt"] = setAt
        return record
    }
}

struct PermissionGroup: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let memberIds: [String]
    let permissions: [Permission]
}

struct AccessControlList: Identifiable {
    let id: String
    let resourceId: String
    let resourceType: ResourceType
    let entries: [ACLEntry]
    let inheritanceRules: [InheritanceRule]
    let createdBy: String
    let createdAt: Date
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AccessControlList", recordID: CKRecord.ID(recordName: id))
        record["resourceId"] = resourceId
        record["resourceType"] = resourceType.rawValue
        record["entries"] = try? JSONEncoder().encode(entries)
        record["inheritanceRules"] = try? JSONEncoder().encode(inheritanceRules)
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        return record
    }
}

struct RoleAssignment: Identifiable {
    let id: String
    let userId: String
    let roleId: String
    let scope: PermissionScope
    let assignedBy: String
    let assignedAt: Date
    let expirationDate: Date?
    var isActive: Bool
    var revokedAt: Date?
    var revokedBy: String?
    var revocationReason: String?
    
    var isExpired: Bool {
        if let expirationDate = expirationDate {
            return Date() > expirationDate
        }
        return false
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "RoleAssignment", recordID: CKRecord.ID(recordName: id))
        record["userId"] = userId
        record["roleId"] = roleId
        record["scope"] = scope.rawValue
        record["assignedBy"] = assignedBy
        record["assignedAt"] = assignedAt
        record["expirationDate"] = expirationDate
        record["isActive"] = isActive
        record["revokedAt"] = revokedAt
        record["revokedBy"] = revokedBy
        record["revocationReason"] = revocationReason
        return record
    }
}

struct PermissionRule: Codable {
    let id: String
    let conditions: [PermissionCondition]
    let effect: RuleEffect
}

struct PermissionCondition: Codable {
    let type: ConditionType
    let attribute: String
    let `operator`: ConditionOperator
    let value: String
}

struct PermissionGrant: Codable {
    let principalId: String
    let principalType: PrincipalType
    let action: PermissionAction
    let isGranted: Bool
    let conditions: [PermissionCondition]
}

struct ACLEntry: Codable {
    let principalId: String
    let principalType: PrincipalType
    let action: PermissionAction
    let isGranted: Bool
}

struct InheritanceRule: Codable {
    let parentResourceId: String
    let inheritedActions: [PermissionAction]
    let conditions: [PermissionCondition]
}

struct PermissionContext {
    let requestTime: Date
    let clientIP: String?
    let userAgent: String?
    let deviceId: String?
    let location: String?
    let sessionId: String?
    let additionalData: [String: Any]
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "requestTime": requestTime,
            "sessionId": sessionId ?? ""
        ]
        
        if let clientIP = clientIP { dict["clientIP"] = clientIP }
        if let userAgent = userAgent { dict["userAgent"] = userAgent }
        if let deviceId = deviceId { dict["deviceId"] = deviceId }
        if let location = location { dict["location"] = location }
        
        dict.merge(additionalData) { (_, new) in new }
        
        return dict
    }
}

struct PermissionResource {
    let id: String
    let type: ResourceType
    let attributes: [String: Any]
}

struct PermissionEvaluationResult {
    let userId: String
    let results: [PermissionAction: Bool]
    let conditionsResult: Bool
    let evaluationDetails: [PermissionEvaluationDetail]
    let evaluatedAt: Date
}

struct PermissionEvaluationDetail {
    let action: PermissionAction
    let resource: PermissionResource
    let hasPermission: Bool
    let appliedPolicies: [String]
    let evaluatedAt: Date
}

struct PermissionAuditLog {
    let id: String
    let timestamp: Date
    let userId: String
    let action: PermissionAuditAction
    let resource: String?
    let result: PermissionResult
    let context: [String: Any]?
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "PermissionAuditLog", recordID: CKRecord.ID(recordName: id))
        record["timestamp"] = timestamp
        record["userId"] = userId
        record["action"] = action.rawValue
        record["resource"] = resource
        record["result"] = result.rawValue
        record["context"] = try? JSONSerialization.data(withJSONObject: context ?? [:])
        return record
    }
}

struct SecurityAuditReport {
    let id: String
    let generatedAt: Date
    let timeRange: TimeRange
    let totalPermissionChecks: Int
    let successfulChecks: Int
    let deniedChecks: Int
    let permissionChanges: [PermissionAuditLog]
    let securityViolations: [SecurityViolation]
    let userActivitySummary: [UserActivitySummary]
    let resourceAccessSummary: [ResourceAccessSummary]
    let riskAssessment: SecurityRiskAssessment
}

struct SecurityViolation {
    let id: String
    let type: SecurityViolationType
    let severity: SecurityViolationSeverity
    let userId: String
    let description: String
    let detectedAt: Date
    let relatedLogs: [String]
}

struct UserActivitySummary {
    let userId: String
    let totalChecks: Int
    let successfulChecks: Int
    let deniedChecks: Int
    let uniqueResources: Int
    let lastActivity: Date
}

struct ResourceAccessSummary {
    let resourceId: String
    let totalAccesses: Int
    let successfulAccesses: Int
    let deniedAccesses: Int
    let uniqueUsers: Int
    let lastAccess: Date
}

struct SecurityRiskAssessment {
    let riskLevel: SecurityRiskLevel
    let riskScore: Double
    let factors: [String]
    let recommendations: [String]
}

struct SecurityMetrics {
    let totalPermissionChecks: Int
    let successfulChecks: Int
    let deniedChecks: Int
    let uniqueUsers: Int
    let uniqueResources: Int
    let averageResponseTime: TimeInterval
    let securityScore: Double
    let riskLevel: SecurityRiskLevel
}

struct ComplianceStatus {
    let overallScore: Double
    let lastAssessment: Date
    let violations: [ComplianceViolation]
    let recommendations: [String]
}

// MARK: - Enums

enum PermissionAction: String, CaseIterable, Codable {
    case create = "create"
    case read = "read"
    case update = "update"
    case delete = "delete"
    case approve = "approve"
    case reject = "reject"
    case share = "share"
    case download = "download"
    case upload = "upload"
    case manage = "manage"
    case admin = "admin"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum PermissionResourceType: String, CaseIterable, Codable {
    case any = "any"
    case document = "document"
    case ownDocument = "own_document"
    case folder = "folder"
    case user = "user"
    case team = "team"
    case project = "project"
    case system = "system"
    
    func matches(_ resource: PermissionResource) -> Bool {
        return self == .any || self.rawValue == resource.type.rawValue
    }
}

enum ResourceType: String, CaseIterable, Codable {
    case document = "document"
    case folder = "folder"
    case user = "user"
    case team = "team"
    case project = "project"
    case system = "system"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum PermissionScope: String, CaseIterable, Codable {
    case global = "global"
    case organization = "organization"
    case department = "department"
    case team = "team"
    case project = "project"
    case resource = "resource"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum PolicyPriority: Int, CaseIterable, Codable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

enum RuleEffect: String, CaseIterable, Codable {
    case allow = "allow"
    case deny = "deny"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum ConditionType: String, CaseIterable, Codable {
    case userAttribute = "user_attribute"
    case resourceAttribute = "resource_attribute"
    case contextual = "contextual"
    case temporal = "temporal"
    case environmental = "environmental"
    
    var displayName: String {
        switch self {
        case .userAttribute: return "User Attribute"
        case .resourceAttribute: return "Resource Attribute"
        case .contextual: return "Contextual"
        case .temporal: return "Temporal"
        case .environmental: return "Environmental"
        }
    }
}

enum ConditionOperator: String, CaseIterable, Codable {
    case equals = "equals"
    case notEquals = "not_equals"
    case contains = "contains"
    case notContains = "not_contains"
    case inList = "in"
    case notInList = "not_in"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case matches = "matches"
    
    var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .notEquals: return "Not Equals"
        case .contains: return "Contains"
        case .notContains: return "Not Contains"
        case .inList: return "In"
        case .notInList: return "Not In"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .matches: return "Matches"
        }
    }
}

enum PrincipalType: String, CaseIterable, Codable {
    case user = "user"
    case group = "group"
    case role = "role"
    case system = "system"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum PolicyResult: String, CaseIterable {
    case granted = "granted"
    case denied = "denied"
    case notApplicable = "not_applicable"
}

enum PermissionAuditAction: String, CaseIterable, Codable {
    case permissionChecked = "permission_checked"
    case roleAssigned = "role_assigned"
    case roleRevoked = "role_revoked"
    case policyCreated = "policy_created"
    case policyUpdated = "policy_updated"
    case policyDeleted = "policy_deleted"
    case resourcePermissionsSet = "resource_permissions_set"
    case aclCreated = "acl_created"
    case aclUpdated = "acl_updated"
    
    var isChangeAction: Bool {
        return self != .permissionChecked
    }
    
    var displayName: String {
        switch self {
        case .permissionChecked: return "Permission Checked"
        case .roleAssigned: return "Role Assigned"
        case .roleRevoked: return "Role Revoked"
        case .policyCreated: return "Policy Created"
        case .policyUpdated: return "Policy Updated"
        case .policyDeleted: return "Policy Deleted"
        case .resourcePermissionsSet: return "Resource Permissions Set"
        case .aclCreated: return "ACL Created"
        case .aclUpdated: return "ACL Updated"
        }
    }
}

enum PermissionResult: String, CaseIterable, Codable {
    case granted = "granted"
    case denied = "denied"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum SecurityViolationType: String, CaseIterable, Codable {
    case excessiveDeniedAttempts = "excessive_denied_attempts"
    case suspiciousAccess = "suspicious_access"
    case privilegeEscalation = "privilege_escalation"
    case unauthorizedResourceAccess = "unauthorized_resource_access"
    
    var displayName: String {
        switch self {
        case .excessiveDeniedAttempts: return "Excessive Denied Attempts"
        case .suspiciousAccess: return "Suspicious Access"
        case .privilegeEscalation: return "Privilege Escalation"
        case .unauthorizedResourceAccess: return "Unauthorized Resource Access"
        }
    }
}

enum SecurityViolationSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum SecurityRiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - Error Types

enum PermissionsError: LocalizedError {
    case permissionCheckFailed(Error)
    case roleNotFound
    case roleAssignmentFailed(Error)
    case roleAssignmentNotFound
    case roleRevocationFailed(Error)
    case policyNotFound
    case policyCreationFailed(Error)
    case policyUpdateFailed(Error)
    case invalidPolicyRule
    case resourcePermissionsFailed(Error)
    case parentResourceNotFound
    case aclCreationFailed(Error)
    case auditReportFailed(Error)
    case loadFailed(Error)
    case metricsFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionCheckFailed(let error):
            return "Permission check failed: \(error.localizedDescription)"
        case .roleNotFound:
            return "Role not found"
        case .roleAssignmentFailed(let error):
            return "Failed to assign role: \(error.localizedDescription)"
        case .roleAssignmentNotFound:
            return "Role assignment not found"
        case .roleRevocationFailed(let error):
            return "Failed to revoke role: \(error.localizedDescription)"
        case .policyNotFound:
            return "Permission policy not found"
        case .policyCreationFailed(let error):
            return "Failed to create policy: \(error.localizedDescription)"
        case .policyUpdateFailed(let error):
            return "Failed to update policy: \(error.localizedDescription)"
        case .invalidPolicyRule:
            return "Invalid policy rule configuration"
        case .resourcePermissionsFailed(let error):
            return "Failed to set resource permissions: \(error.localizedDescription)"
        case .parentResourceNotFound:
            return "Parent resource not found for inheritance"
        case .aclCreationFailed(let error):
            return "Failed to create Access Control List: \(error.localizedDescription)"
        case .auditReportFailed(let error):
            return "Failed to generate audit report: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load permissions data: \(error.localizedDescription)"
        case .metricsFailed(let error):
            return "Failed to load security metrics: \(error.localizedDescription)"
        }
    }
}

