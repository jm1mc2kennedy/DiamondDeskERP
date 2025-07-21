# Phase 4.2 Unified Permissions Framework - Test Plan

## Test Overview

This document outlines comprehensive testing strategies for the DiamondDeskERP Unified Permissions Framework implemented in Phase 4.2.

## Testing Scope

### Core Components
- Role management and CRUD operations
- Permission assignment and inheritance
- User role assignments
- Audit trail logging and analysis
- Permission matrix configuration
- CloudKit synchronization

## Unit Tests

### 1. Permission Model Tests
```swift
import XCTest
@testable import DiamondDeskERP

class PermissionModelTests: XCTestCase {
    
    func testPermissionCreation() {
        let permission = Permission(
            resource: .documents,
            action: .read,
            scope: .organization
        )
        
        XCTAssertEqual(permission.resource, .documents)
        XCTAssertEqual(permission.action, .read)
        XCTAssertEqual(permission.scope, .organization)
    }
    
    func testUserRoleInheritance() {
        let parentRole = UserRole(
            name: "parent",
            displayName: "Parent Role",
            description: "Parent role for testing",
            level: 1,
            permissions: [Permission(resource: .users, action: .read, scope: .organization)],
            createdBy: "test"
        )
        
        let childRole = UserRole(
            name: "child",
            displayName: "Child Role", 
            description: "Child role for testing",
            level: 2,
            permissions: [Permission(resource: .documents, action: .read, scope: .organization)],
            inheritsFrom: parentRole.id,
            createdBy: "test"
        )
        
        XCTAssertEqual(childRole.inheritsFrom, parentRole.id)
        XCTAssertTrue(childRole.level > parentRole.level)
    }
    
    func testUserRoleAssignmentValidation() {
        let assignment = UserRoleAssignment(
            userId: "test-user",
            roleId: UUID(),
            scope: .department,
            scopeValues: ["Engineering"],
            assignedBy: "admin"
        )
        
        XCTAssertTrue(assignment.isActive)
        XCTAssertFalse(assignment.isExpired)
        XCTAssertEqual(assignment.scope, .department)
        XCTAssertEqual(assignment.scopeValues, ["Engineering"])
    }
}
```

### 2. UnifiedPermissionsService Tests
```swift
class UnifiedPermissionsServiceTests: XCTestCase {
    var service: UnifiedPermissionsService!
    
    override func setUp() {
        super.setUp()
        service = UnifiedPermissionsService.shared
    }
    
    func testRoleCreation() async throws {
        let role = UserRole(
            name: "test_role",
            displayName: "Test Role",
            description: "Role for testing",
            level: 3,
            permissions: [Permission(resource: .tasks, action: .read, scope: .organization)],
            createdBy: "test"
        )
        
        try await service.createRole(role)
        
        let retrievedRole = await service.getRole(role.id)
        XCTAssertNotNil(retrievedRole)
        XCTAssertEqual(retrievedRole?.name, "test_role")
    }
    
    func testPermissionChecking() async {
        // Setup test role and assignment
        let role = UserRole(
            name: "reader",
            displayName: "Reader",
            description: "Read-only access",
            level: 5,
            permissions: [Permission(resource: .documents, action: .read, scope: .organization)],
            createdBy: "test"
        )
        
        try await service.createRole(role)
        try await service.assignRole(role.id, to: "test-user", scope: .organization)
        
        // Test permission checking
        let hasPermission = await service.hasPermission(.read, on: .documents, for: "test-user")
        XCTAssertTrue(hasPermission)
        
        let noPermission = await service.hasPermission(.delete, on: .documents, for: "test-user")
        XCTAssertFalse(noPermission)
    }
    
    func testRoleInheritance() async throws {
        // Create parent role
        let parentRole = UserRole(
            name: "parent",
            displayName: "Parent Role",
            description: "Parent with basic permissions",
            level: 1,
            permissions: [
                Permission(resource: .documents, action: .read, scope: .organization),
                Permission(resource: .tasks, action: .read, scope: .organization)
            ],
            createdBy: "test"
        )
        
        try await service.createRole(parentRole)
        
        // Create child role that inherits from parent
        let childRole = UserRole(
            name: "child",
            displayName: "Child Role",
            description: "Child with additional permissions",
            level: 2,
            permissions: [Permission(resource: .documents, action: .create, scope: .organization)],
            inheritsFrom: parentRole.id,
            createdBy: "test"
        )
        
        try await service.createRole(childRole)
        try await service.assignRole(childRole.id, to: "test-user", scope: .organization)
        
        // Test inherited permissions
        let hasInheritedRead = await service.hasPermission(.read, on: .documents, for: "test-user")
        let hasDirectCreate = await service.hasPermission(.create, on: .documents, for: "test-user")
        let hasInheritedTaskRead = await service.hasPermission(.read, on: .tasks, for: "test-user")
        
        XCTAssertTrue(hasInheritedRead)
        XCTAssertTrue(hasDirectCreate)
        XCTAssertTrue(hasInheritedTaskRead)
    }
    
    func testAuditTrailLogging() async {
        let initialCount = await service.getAuditTrail(limit: 1000).count
        
        // Perform an action that should be audited
        let hasPermission = await service.hasPermission(.read, on: .documents)
        
        let newCount = await service.getAuditTrail(limit: 1000).count
        XCTAssertGreaterThan(newCount, initialCount)
        
        let latestEntry = await service.getAuditTrail(limit: 1).first
        XCTAssertNotNil(latestEntry)
        XCTAssertEqual(latestEntry?.action, .permissionChecked)
        XCTAssertEqual(latestEntry?.resource, .documents)
    }
}
```

### 3. ViewModel Tests
```swift
@MainActor
class PermissionsViewModelTests: XCTestCase {
    var viewModel: PermissionsViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = PermissionsViewModel()
    }
    
    func testRoleCreation() async {
        viewModel.newRoleName = "test_manager"
        viewModel.newRoleDisplayName = "Test Manager"
        viewModel.newRoleDescription = "Manager role for testing"
        viewModel.newRoleLevel = 3
        viewModel.newRolePermissions = [
            Permission(resource: .tasks, action: .create, scope: .organization),
            Permission(resource: .tasks, action: .assign, scope: .organization)
        ]
        
        await viewModel.createRole()
        
        XCTAssertFalse(viewModel.showingRoleCreation)
        XCTAssertTrue(viewModel.availableRoles.contains { $0.name == "test_manager" })
    }
    
    func testRoleAssignment() async {
        // Setup
        let role = UserRole(
            name: "test_role",
            displayName: "Test Role",
            description: "Test",
            level: 3,
            permissions: [],
            createdBy: "test"
        )
        
        viewModel.availableRoles = [role]
        viewModel.selectedRole = role
        viewModel.assignmentUserId = "test-user"
        viewModel.assignmentScope = .department
        viewModel.assignmentScopeValues = ["Engineering"]
        viewModel.assignmentReason = "Testing assignment"
        
        await viewModel.assignRole()
        
        XCTAssertFalse(viewModel.showingUserAssignment)
        XCTAssertTrue(viewModel.userAssignments.contains { 
            $0.userId == "test-user" && $0.roleId == role.id 
        })
    }
}

@MainActor
class RoleManagementViewModelTests: XCTestCase {
    var viewModel: RoleManagementViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = RoleManagementViewModel()
    }
    
    func testPermissionMatrixToggle() {
        viewModel.permissionMatrix[.documents]?[.read] = false
        
        viewModel.togglePermission(resource: .documents, action: .read)
        
        XCTAssertEqual(viewModel.permissionMatrix[.documents]?[.read], true)
        
        viewModel.togglePermission(resource: .documents, action: .read)
        
        XCTAssertEqual(viewModel.permissionMatrix[.documents]?[.read], false)
    }
    
    func testPermissionSetBuilding() {
        let adminPermissions = viewModel.buildPermissionSet(for: .admin)
        let userPermissions = viewModel.buildPermissionSet(for: .user)
        
        XCTAssertGreaterThan(adminPermissions.count, userPermissions.count)
        XCTAssertTrue(adminPermissions.contains { $0.action == .delete })
        XCTAssertFalse(userPermissions.contains { $0.action == .delete && $0.scope == .organization })
    }
}
```

## Integration Tests

### 1. End-to-End Role Management
```swift
class RoleManagementIntegrationTests: XCTestCase {
    
    func testCompleteRoleLifecycle() async throws {
        let service = UnifiedPermissionsService.shared
        
        // 1. Create role
        let role = UserRole(
            name: "integration_test",
            displayName: "Integration Test Role",
            description: "Role for integration testing",
            level: 4,
            permissions: [
                Permission(resource: .tasks, action: .read, scope: .organization),
                Permission(resource: .tasks, action: .create, scope: .department)
            ],
            createdBy: "integration-test"
        )
        
        try await service.createRole(role)
        
        // 2. Assign role to user
        try await service.assignRole(
            role.id,
            to: "integration-test-user",
            scope: .department,
            scopeValues: ["Engineering"],
            reason: "Integration testing"
        )
        
        // 3. Verify permissions
        let hasOrgRead = await service.hasPermission(.read, on: .tasks, for: "integration-test-user")
        let hasDeptCreate = await service.hasPermission(.create, on: .tasks, for: "integration-test-user")
        let hasDelete = await service.hasPermission(.delete, on: .tasks, for: "integration-test-user")
        
        XCTAssertTrue(hasOrgRead)
        XCTAssertTrue(hasDeptCreate)
        XCTAssertFalse(hasDelete)
        
        // 4. Check audit trail
        let auditEntries = await service.getAuditTrail(limit: 10)
        let assignmentEntry = auditEntries.first { $0.action == .roleAssigned }
        XCTAssertNotNil(assignmentEntry)
        
        // 5. Revoke role
        try await service.revokeRole(role.id, from: "integration-test-user", reason: "Test cleanup")
        
        // 6. Verify revocation
        let hasPermissionAfterRevoke = await service.hasPermission(.read, on: .tasks, for: "integration-test-user")
        XCTAssertFalse(hasPermissionAfterRevoke)
        
        // 7. Cleanup
        try await service.deleteRole(role.id)
    }
}
```

## UI Tests

### 1. Permission Matrix Interaction
```swift
class PermissionMatrixUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testPermissionMatrixNavigation() {
        // Navigate to permissions management
        app.tabBars.buttons["Permissions"].tap()
        
        // Navigate to role management
        app.buttons["Role Management"].tap()
        
        // Select a role
        app.buttons["Test Role"].tap()
        
        // Verify permission matrix is displayed
        XCTAssertTrue(app.staticTexts["Permission Matrix"].exists)
        
        // Test permission toggle
        let documentReadToggle = app.buttons["documents_read_toggle"]
        let initialState = documentReadToggle.isSelected
        
        documentReadToggle.tap()
        
        XCTAssertNotEqual(documentReadToggle.isSelected, initialState)
    }
    
    func testRoleCreationFlow() {
        app.tabBars.buttons["Permissions"].tap()
        app.buttons["Create Role"].tap()
        
        // Fill out role form
        app.textFields["Role Name"].tap()
        app.textFields["Role Name"].typeText("Test UI Role")
        
        app.textFields["Display Name"].tap()
        app.textFields["Display Name"].typeText("Test UI Role Display")
        
        app.textViews["Description"].tap()
        app.textViews["Description"].typeText("Role created via UI test")
        
        // Save role
        app.navigationBars.buttons["Save"].tap()
        
        // Verify role appears in list
        XCTAssertTrue(app.staticTexts["Test UI Role Display"].exists)
    }
}
```

### 2. Audit Trail UI Tests
```swift
class AuditTrailUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testAuditTrailFiltering() {
        app.tabBars.buttons["Permissions"].tap()
        app.buttons["Audit Trail"].tap()
        
        // Test time range filter
        app.buttons["Last Week"].tap()
        XCTAssertTrue(app.buttons["Last Week"].isSelected)
        
        // Test search functionality
        app.searchFields["Search audit entries..."].tap()
        app.searchFields["Search audit entries..."].typeText("permission")
        
        // Verify filtered results
        let searchResults = app.tables.cells.count
        XCTAssertGreaterThan(searchResults, 0)
        
        // Test entry detail view
        app.tables.cells.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Audit Entry"].exists)
        
        app.navigationBars.buttons["Done"].tap()
    }
    
    func testAuditTrailExport() {
        app.tabBars.buttons["Permissions"].tap()
        app.buttons["Audit Trail"].tap()
        
        // Navigate to reports tab
        app.buttons["Reports"].tap()
        
        // Test export functionality
        app.buttons["Export Audit Trail"].tap()
        
        // Verify export options
        XCTAssertTrue(app.staticTexts["CSV"].exists)
        XCTAssertTrue(app.staticTexts["JSON"].exists)
        XCTAssertTrue(app.staticTexts["PDF Report"].exists)
    }
}
```

## Performance Tests

### 1. Large Dataset Performance
```swift
class PermissionsPerformanceTests: XCTestCase {
    
    func testLargeRoleSetPerformance() async {
        let service = UnifiedPermissionsService.shared
        
        // Create 100 roles with various permission sets
        measure {
            Task {
                for i in 0..<100 {
                    let role = UserRole(
                        name: "perf_role_\(i)",
                        displayName: "Performance Role \(i)",
                        description: "Role for performance testing",
                        level: i % 10,
                        permissions: generateRandomPermissions(),
                        createdBy: "perf-test"
                    )
                    
                    try await service.createRole(role)
                }
            }
        }
    }
    
    func testPermissionCheckingPerformance() async {
        measure {
            Task {
                for _ in 0..<1000 {
                    let _ = await UnifiedPermissionsService.shared.hasPermission(
                        .read,
                        on: .documents
                    )
                }
            }
        }
    }
    
    func testAuditTrailQueryPerformance() async {
        measure {
            Task {
                let _ = await UnifiedPermissionsService.shared.getAuditTrail(limit: 1000)
            }
        }
    }
    
    private func generateRandomPermissions() -> Set<Permission> {
        let resources = PermissionResource.allCases.shuffled().prefix(3)
        let actions = PermissionAction.allCases.shuffled().prefix(3)
        
        var permissions = Set<Permission>()
        for resource in resources {
            for action in actions {
                permissions.insert(Permission(
                    resource: resource,
                    action: action,
                    scope: .organization
                ))
            }
        }
        return permissions
    }
}
```

## Security Tests

### 1. Permission Escalation Tests
```swift
class SecurityTests: XCTestCase {
    
    func testPermissionEscalationPrevention() async {
        let service = UnifiedPermissionsService.shared
        
        // Create limited role
        let limitedRole = UserRole(
            name: "limited",
            displayName: "Limited User",
            description: "Limited permissions",
            level: 8,
            permissions: [Permission(resource: .documents, action: .read, scope: .personal)],
            createdBy: "security-test"
        )
        
        try await service.createRole(limitedRole)
        try await service.assignRole(limitedRole.id, to: "limited-user", scope: .personal)
        
        // Attempt to access organization-level resources
        let hasOrgAccess = await service.hasPermission(.read, on: .documents, for: "limited-user", scope: .organization)
        XCTAssertFalse(hasOrgAccess)
        
        // Attempt to access different resource types
        let hasUserAccess = await service.hasPermission(.read, on: .users, for: "limited-user")
        XCTAssertFalse(hasUserAccess)
    }
    
    func testCircularInheritancePrevention() async {
        let service = UnifiedPermissionsService.shared
        
        let roleA = UserRole(
            name: "role_a",
            displayName: "Role A",
            description: "First role",
            level: 1,
            permissions: [],
            createdBy: "security-test"
        )
        
        let roleB = UserRole(
            name: "role_b", 
            displayName: "Role B",
            description: "Second role",
            level: 2,
            permissions: [],
            inheritsFrom: roleA.id,
            createdBy: "security-test"
        )
        
        try await service.createRole(roleA)
        try await service.createRole(roleB)
        
        // Attempt to create circular inheritance
        var updatedRoleA = roleA
        updatedRoleA.inheritsFrom = roleB.id
        
        do {
            try await service.updateRole(updatedRoleA)
            XCTFail("Should have prevented circular inheritance")
        } catch PermissionError.circularInheritance {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
```

## CloudKit Integration Tests

### 1. Sync and Conflict Resolution
```swift
class CloudKitIntegrationTests: XCTestCase {
    
    func testRoleSynchronization() async {
        let service = UnifiedPermissionsService.shared
        
        // Create role
        let role = UserRole(
            name: "sync_test",
            displayName: "Sync Test Role",
            description: "Role for sync testing",
            level: 3,
            permissions: [Permission(resource: .tasks, action: .read, scope: .organization)],
            createdBy: "sync-test"
        )
        
        try await service.createRole(role)
        
        // Simulate sync delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Verify role exists in CloudKit
        let retrievedRole = await service.getRole(role.id)
        XCTAssertNotNil(retrievedRole)
        XCTAssertEqual(retrievedRole?.name, "sync_test")
    }
    
    func testOfflineCapability() async {
        // Test that the app functions when offline
        // This would require network simulation
    }
}
```

## Test Data Setup

### 1. Test Role Templates
```swift
enum TestRoleTemplate {
    static let admin = UserRole(
        name: "test_admin",
        displayName: "Test Administrator",
        description: "Full administrative access for testing",
        level: 0,
        permissions: Set(PermissionResource.allCases.flatMap { resource in
            PermissionAction.allCases.map { action in
                Permission(resource: resource, action: action, scope: .organization)
            }
        }),
        createdBy: "test-setup"
    )
    
    static let manager = UserRole(
        name: "test_manager",
        displayName: "Test Manager",
        description: "Manager-level access for testing",
        level: 2,
        permissions: [
            Permission(resource: .tasks, action: .read, scope: .department),
            Permission(resource: .tasks, action: .create, scope: .department),
            Permission(resource: .tasks, action: .assign, scope: .department),
            Permission(resource: .projects, action: .read, scope: .department),
            Permission(resource: .users, action: .read, scope: .department)
        ],
        createdBy: "test-setup"
    )
    
    static let user = UserRole(
        name: "test_user",
        displayName: "Test User",
        description: "Basic user access for testing",
        level: 5,
        permissions: [
            Permission(resource: .tasks, action: .read, scope: .personal),
            Permission(resource: .documents, action: .read, scope: .personal),
            Permission(resource: .calendar, action: .read, scope: .personal)
        ],
        createdBy: "test-setup"
    )
}
```

## Continuous Integration

### 1. Automated Test Pipeline
```yaml
# .github/workflows/permissions-tests.yml
name: Permissions Framework Tests

on:
  push:
    paths:
      - 'Sources/Enterprise/Permissions/**'
  pull_request:
    paths:
      - 'Sources/Enterprise/Permissions/**'

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable
    
    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -project DiamondDeskERP.xcodeproj \
          -scheme DiamondDeskERP \
          -destination 'platform=iOS Simulator,name=iPhone 14' \
          -testPlan PermissionsFrameworkTests
    
    - name: Run UI Tests
      run: |
        xcodebuild test \
          -project DiamondDeskERP.xcodeproj \
          -scheme DiamondDeskERP \
          -destination 'platform=iOS Simulator,name=iPhone 14' \
          -testPlan PermissionsUITests
```

## Manual Testing Checklist

### Role Management
- [ ] Create new custom role
- [ ] Edit existing role permissions
- [ ] Delete role (verify constraints)
- [ ] Test role inheritance setup
- [ ] Verify permission matrix display
- [ ] Test role templates application

### User Assignment
- [ ] Assign role to user
- [ ] Bulk assign roles to multiple users
- [ ] Set time-limited assignments
- [ ] Test scope-based assignments
- [ ] Revoke user assignments
- [ ] Import/export assignments

### Audit Trail
- [ ] View audit entries list
- [ ] Filter by user, resource, action
- [ ] Search audit entries
- [ ] View entry details
- [ ] Export audit reports
- [ ] Test real-time updates

### Permission Matrix
- [ ] Toggle individual permissions
- [ ] Use quick action buttons
- [ ] Apply permission templates
- [ ] View inheritance chain
- [ ] Test permission recommendations

### Error Handling
- [ ] Network connectivity issues
- [ ] Invalid permission combinations
- [ ] Circular inheritance attempts
- [ ] Unauthorized access attempts
- [ ] CloudKit sync conflicts

## Test Coverage Goals

- **Unit Tests**: >90% code coverage
- **Integration Tests**: All critical user journeys
- **UI Tests**: All primary user interactions
- **Performance Tests**: Key operations under load
- **Security Tests**: All permission boundaries

## Reporting

Test results should be tracked and reported using:
- Xcode Test Navigator
- GitHub Actions test reports
- Code coverage reports
- Performance benchmarks
- Security audit findings

This comprehensive test plan ensures the Unified Permissions Framework is robust, secure, and performs well under various conditions.
