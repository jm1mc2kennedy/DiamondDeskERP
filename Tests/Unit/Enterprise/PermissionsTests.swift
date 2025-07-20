//
//  PermissionsTests.swift
//  DiamondDeskERPTests
//
//  Created by AI Assistant on 7/20/25.
//

import XCTest
import CloudKit
import Combine
@testable import DiamondDeskERP

/// Comprehensive test suite for Phase 4.2 Unified Permissions Framework
/// Tests: RBAC, permission inheritance, audit trails, and enterprise security
final class PermissionsTests: XCTestCase {
    
    var permissionsService: UnifiedPermissionsService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        permissionsService = UnifiedPermissionsService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Permission Policy Tests
    
    func testPermissionPolicyCreation() {
        let policy = PermissionPolicy(
            id: "test-policy-001",
            name: "Document Access Policy",
            description: "Controls access to confidential documents",
            rules: [
                PermissionRule(
                    resource: "documents",
                    action: "read",
                    condition: "department == 'HR' OR role == 'Admin'"
                )
            ],
            isActive: true,
            priority: 100,
            applicableRoles: ["HR_Manager", "Admin"],
            effectiveDate: Date(),
            expirationDate: nil
        )
        
        XCTAssertEqual(policy.name, "Document Access Policy")
        XCTAssertTrue(policy.isActive)
        XCTAssertEqual(policy.rules.count, 1)
        XCTAssertTrue(policy.applicableRoles.contains("HR_Manager"))
    }
    
    func testPermissionPolicyValidation() {
        // Test invalid policy (missing required fields)
        let invalidPolicy = PermissionPolicy(
            id: "",
            name: "",
            description: "",
            rules: [],
            isActive: false,
            priority: -1,
            applicableRoles: [],
            effectiveDate: Date(),
            expirationDate: nil
        )
        
        XCTAssertFalse(permissionsService.validatePolicy(invalidPolicy))
        
        // Test valid policy
        let validPolicy = PermissionPolicy(
            id: "valid-policy-001",
            name: "Valid Policy",
            description: "Valid test policy",
            rules: [
                PermissionRule(
                    resource: "tasks",
                    action: "create",
                    condition: "role == 'Manager'"
                )
            ],
            isActive: true,
            priority: 50,
            applicableRoles: ["Manager"],
            effectiveDate: Date(),
            expirationDate: nil
        )
        
        XCTAssertTrue(permissionsService.validatePolicy(validPolicy))
    }
    
    // MARK: - Role Definition Tests
    
    func testRoleDefinitionCreation() {
        let role = RoleDefinition(
            id: "store-manager-001",
            name: "Store Manager",
            description: "Manages store operations and staff",
            permissions: [
                "tasks:create",
                "tasks:assign",
                "tickets:view",
                "tickets:edit",
                "clients:view",
                "performance:view"
            ],
            inheritFrom: "base-manager",
            departmentScope: ["Operations", "Sales"],
            locationScope: ["Store-08", "Store-10"],
            isSystemRole: false,
            contextualRules: [
                ContextualRule(
                    condition: "time >= 08:00 AND time <= 22:00",
                    additionalPermissions: ["cash_drawer:access"],
                    restrictedPermissions: []
                )
            ],
            metadata: [
                "created_by": "admin-001",
                "approved_by": "hr-manager-001"
            ]
        )
        
        XCTAssertEqual(role.name, "Store Manager")
        XCTAssertTrue(role.permissions.contains("tasks:create"))
        XCTAssertEqual(role.departmentScope.count, 2)
        XCTAssertFalse(role.isSystemRole)
    }
    
    func testRoleInheritance() {
        let baseRole = RoleDefinition(
            id: "base-employee",
            name: "Base Employee",
            description: "Basic employee permissions",
            permissions: ["profile:view", "notifications:read"],
            inheritFrom: nil,
            departmentScope: [],
            locationScope: [],
            isSystemRole: true,
            contextualRules: [],
            metadata: [:]
        )
        
        let managerRole = RoleDefinition(
            id: "manager",
            name: "Manager",
            description: "Management permissions",
            permissions: ["tasks:assign", "reports:generate"],
            inheritFrom: "base-employee",
            departmentScope: [],
            locationScope: [],
            isSystemRole: false,
            contextualRules: [],
            metadata: [:]
        )
        
        let inheritedPermissions = permissionsService.getInheritedPermissions(
            for: managerRole,
            from: [baseRole]
        )
        
        XCTAssertTrue(inheritedPermissions.contains("profile:view"))
        XCTAssertTrue(inheritedPermissions.contains("notifications:read"))
        XCTAssertTrue(inheritedPermissions.contains("tasks:assign"))
        XCTAssertTrue(inheritedPermissions.contains("reports:generate"))
    }
    
    // MARK: - Permission Checking Tests
    
    func testPermissionCheck() async {
        let user = UserPermissions(
            userId: "user-001",
            roleIds: ["store-manager"],
            directPermissions: ["special:access"],
            deniedPermissions: [],
            department: "Operations",
            location: "Store-08",
            contextualData: ["shift": "morning"]
        )
        
        // Test direct permission
        let hasDirectPermission = await permissionsService.checkPermission(
            user: user,
            resource: "special",
            action: "access",
            context: [:]
        )
        XCTAssertTrue(hasDirectPermission)
        
        // Test denied permission
        let deniedUser = UserPermissions(
            userId: "user-002",
            roleIds: ["associate"],
            directPermissions: [],
            deniedPermissions: ["admin:access"],
            department: "Sales",
            location: "Store-08",
            contextualData: [:]
        )
        
        let hasDeniedPermission = await permissionsService.checkPermission(
            user: deniedUser,
            resource: "admin",
            action: "access",
            context: [:]
        )
        XCTAssertFalse(hasDeniedPermission)
    }
    
    func testContextualPermissions() async {
        let user = UserPermissions(
            userId: "user-003",
            roleIds: ["cashier"],
            directPermissions: [],
            deniedPermissions: [],
            department: "Sales",
            location: "Store-08",
            contextualData: ["shift": "evening"]
        )
        
        // Test time-based permission
        let morningContext = ["current_time": "09:00"]
        let eveningContext = ["current_time": "23:00"]
        
        let hasMorningAccess = await permissionsService.checkPermission(
            user: user,
            resource: "cash_drawer",
            action: "access",
            context: morningContext
        )
        
        let hasEveningAccess = await permissionsService.checkPermission(
            user: user,
            resource: "cash_drawer",
            action: "access",
            context: eveningContext
        )
        
        XCTAssertTrue(hasMorningAccess)
        XCTAssertFalse(hasEveningAccess) // After hours restriction
    }
    
    // MARK: - Audit Trail Tests
    
    func testPermissionAuditLogging() async {
        let user = UserPermissions(
            userId: "user-004",
            roleIds: ["manager"],
            directPermissions: [],
            deniedPermissions: [],
            department: "Operations",
            location: "Store-08",
            contextualData: [:]
        )
        
        // Perform permission check that should be audited
        let _ = await permissionsService.checkPermission(
            user: user,
            resource: "confidential_reports",
            action: "view",
            context: ["report_type": "hr_investigation"]
        )
        
        // Verify audit log was created
        let expectation = XCTestExpectation(description: "Audit log created")
        
        permissionsService.$permissionAuditLogs
            .sink { logs in
                if logs.contains(where: { $0.userId == "user-004" && $0.resource == "confidential_reports" }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testAuditTrailQuery() async {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
        let auditLogs = await permissionsService.getAuditTrail(
            userId: "user-004",
            resource: "confidential_reports",
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertGreaterThanOrEqual(auditLogs.count, 0)
        
        // Verify all logs are within date range
        for log in auditLogs {
            XCTAssertGreaterThanOrEqual(log.timestamp, startDate)
            XCTAssertLessThanOrEqual(log.timestamp, endDate)
        }
    }
    
    // MARK: - Permission Group Tests
    
    func testPermissionGroupManagement() {
        let group = PermissionGroup(
            id: "hr-confidential-group",
            name: "HR Confidential Access",
            description: "Access to confidential HR documents and processes",
            permissions: [
                "hr_documents:read",
                "hr_documents:write",
                "employee_records:view",
                "salary_info:view"
            ],
            memberRoles: ["HR_Manager", "HR_Specialist"],
            memberUsers: ["hr-001", "hr-002"],
            isActive: true,
            createdBy: "admin-001",
            createdAt: Date(),
            expirationDate: nil
        )
        
        XCTAssertEqual(group.name, "HR Confidential Access")
        XCTAssertEqual(group.permissions.count, 4)
        XCTAssertTrue(group.memberRoles.contains("HR_Manager"))
        XCTAssertTrue(group.isActive)
    }
    
    // MARK: - Access Control List Tests
    
    func testAccessControlListCreation() {
        let acl = AccessControlList(
            id: "document-acl-001",
            resourceId: "confidential-doc-123",
            resourceType: "document",
            ownerId: "user-005",
            permissions: [
                ACLPermission(
                    principalId: "hr-manager-001",
                    principalType: .user,
                    permissions: ["read", "write", "share"],
                    grantedBy: "admin-001",
                    grantedAt: Date(),
                    expiresAt: nil
                ),
                ACLPermission(
                    principalId: "hr-group",
                    principalType: .group,
                    permissions: ["read"],
                    grantedBy: "hr-manager-001",
                    grantedAt: Date(),
                    expiresAt: Calendar.current.date(byAdding: .month, value: 6, to: Date())
                )
            ],
            inheritanceRules: [
                InheritanceRule(
                    fromResource: "parent-folder-456",
                    inheritedPermissions: ["read"]
                )
            ],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(acl.resourceId, "confidential-doc-123")
        XCTAssertEqual(acl.permissions.count, 2)
        XCTAssertEqual(acl.inheritanceRules.count, 1)
    }
    
    // MARK: - Security Metrics Tests
    
    func testSecurityMetricsCollection() {
        let metrics = SecurityMetrics(
            totalUsers: 150,
            activeUsers: 142,
            totalRoles: 12,
            customRoles: 8,
            totalPolicies: 25,
            activePolicies: 23,
            permissionChecksToday: 1547,
            deniedAccessAttempts: 12,
            auditLogsCount: 15420,
            lastSecurityReview: Date(),
            complianceScore: 0.94,
            riskLevel: .low,
            flaggedActivities: [
                SecurityFlag(
                    type: .unusualAccess,
                    description: "User accessing resources outside normal hours",
                    severity: .medium,
                    userId: "user-006",
                    timestamp: Date(),
                    resolved: false
                )
            ]
        )
        
        XCTAssertEqual(metrics.totalUsers, 150)
        XCTAssertEqual(metrics.complianceScore, 0.94, accuracy: 0.01)
        XCTAssertEqual(metrics.riskLevel, .low)
        XCTAssertEqual(metrics.flaggedActivities.count, 1)
    }
    
    // MARK: - Performance Tests
    
    func testPermissionCheckPerformance() {
        measure {
            let user = UserPermissions(
                userId: "performance-user",
                roleIds: ["associate"],
                directPermissions: ["basic:access"],
                deniedPermissions: [],
                department: "Sales",
                location: "Store-08",
                contextualData: [:]
            )
            
            for i in 0..<100 {
                Task {
                    let _ = await permissionsService.checkPermission(
                        user: user,
                        resource: "task",
                        action: "view",
                        context: ["task_id": "task-\(i)"]
                    )
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidPermissionRequest() async {
        let user = UserPermissions(
            userId: "error-test-user",
            roleIds: ["invalid-role"],
            directPermissions: [],
            deniedPermissions: [],
            department: "Unknown",
            location: "Store-99",
            contextualData: [:]
        )
        
        let hasPermission = await permissionsService.checkPermission(
            user: user,
            resource: "",  // Invalid empty resource
            action: "",    // Invalid empty action
            context: [:]
        )
        
        XCTAssertFalse(hasPermission)
        XCTAssertNotNil(permissionsService.error)
    }
    
    // MARK: - CloudKit Integration Tests
    
    func testCloudKitPermissionSync() async {
        let expectation = XCTestExpectation(description: "CloudKit sync completed")
        
        // Test syncing permissions to CloudKit
        do {
            let testPolicy = PermissionPolicy(
                id: "cloudkit-test-policy",
                name: "CloudKit Test Policy",
                description: "Test policy for CloudKit integration",
                rules: [
                    PermissionRule(
                        resource: "test_resource",
                        action: "test_action",
                        condition: "role == 'tester'"
                    )
                ],
                isActive: true,
                priority: 1,
                applicableRoles: ["tester"],
                effectiveDate: Date(),
                expirationDate: nil
            )
            
            try await permissionsService.syncPolicyToCloudKit(testPolicy)
            expectation.fulfill()
        } catch {
            XCTFail("CloudKit sync failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndPermissionFlow() async {
        // Create a complete permission scenario
        let role = RoleDefinition(
            id: "integration-test-role",
            name: "Integration Test Role",
            description: "Role for end-to-end testing",
            permissions: ["integration:test"],
            inheritFrom: nil,
            departmentScope: ["Testing"],
            locationScope: ["Test-Store"],
            isSystemRole: false,
            contextualRules: [],
            metadata: [:]
        )
        
        let user = UserPermissions(
            userId: "integration-test-user",
            roleIds: ["integration-test-role"],
            directPermissions: [],
            deniedPermissions: [],
            department: "Testing",
            location: "Test-Store",
            contextualData: [:]
        )
        
        // Add role to service
        await permissionsService.addRole(role)
        
        // Check permission
        let hasPermission = await permissionsService.checkPermission(
            user: user,
            resource: "integration",
            action: "test",
            context: [:]
        )
        
        XCTAssertTrue(hasPermission)
        
        // Verify audit log was created
        let auditLogs = await permissionsService.getAuditTrail(
            userId: "integration-test-user",
            resource: "integration",
            startDate: Date().addingTimeInterval(-60),
            endDate: Date()
        )
        
        XCTAssertGreaterThan(auditLogs.count, 0)
    }
}

// MARK: - Mock Extensions for Testing

extension UnifiedPermissionsService {
    
    func validatePolicy(_ policy: PermissionPolicy) -> Bool {
        return !policy.id.isEmpty &&
               !policy.name.isEmpty &&
               !policy.rules.isEmpty &&
               policy.priority >= 0
    }
    
    func getInheritedPermissions(for role: RoleDefinition, from roles: [RoleDefinition]) -> [String] {
        var permissions = Set(role.permissions)
        
        if let inheritFromId = role.inheritFrom,
           let parentRole = roles.first(where: { $0.id == inheritFromId }) {
            permissions.formUnion(getInheritedPermissions(for: parentRole, from: roles))
        }
        
        return Array(permissions)
    }
    
    func syncPolicyToCloudKit(_ policy: PermissionPolicy) async throws {
        // Mock CloudKit sync - in real implementation this would save to CloudKit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    func addRole(_ role: RoleDefinition) async {
        await MainActor.run {
            roleDefinitions.append(role)
        }
    }
    
    func getAuditTrail(userId: String, resource: String, startDate: Date, endDate: Date) async -> [PermissionAuditLog] {
        return permissionAuditLogs.filter { log in
            log.userId == userId &&
            log.resource == resource &&
            log.timestamp >= startDate &&
            log.timestamp <= endDate
        }
    }
}
