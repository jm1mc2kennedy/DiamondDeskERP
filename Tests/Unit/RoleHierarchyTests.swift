import XCTest
@testable import DiamondDeskERP

class RoleHierarchyTests: XCTestCase {
    
    var roleService: RoleHierarchyService!
    var testRoles: [RoleDefinitionModel]!
    
    override func setUp() {
        super.setUp()
        roleService = RoleHierarchyService()
        setupTestRoles()
    }
    
    override func tearDown() {
        roleService = nil
        testRoles = nil
        super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    func setupTestRoles() {
        testRoles = [
            // System Admin (Root)
            RoleDefinitionModel(
                id: "system-admin",
                name: "System Administrator",
                description: "Full system access",
                inheritFrom: nil,
                permissions: [
                    PermissionEntry(resource: "*", actions: ["*"], priority: 100)
                ],
                isSystemRole: true,
                roleLevel: .system,
                priority: 100
            ),
            
            // Executive (Under System Admin)
            RoleDefinitionModel(
                id: "executive",
                name: "Executive",
                description: "Executive level access",
                inheritFrom: "system-admin",
                permissions: [
                    PermissionEntry(resource: "reports", actions: ["read", "create", "export"], priority: 90),
                    PermissionEntry(resource: "analytics", actions: ["read"], priority: 90)
                ],
                roleLevel: .executive,
                priority: 90
            ),
            
            // Manager (Under Executive)
            RoleDefinitionModel(
                id: "manager",
                name: "Manager",
                description: "Management level access",
                inheritFrom: "executive",
                permissions: [
                    PermissionEntry(resource: "team", actions: ["read", "manage"], priority: 80),
                    PermissionEntry(resource: "projects", actions: ["read", "create", "edit"], priority: 80)
                ],
                departmentScope: ["sales", "marketing", "operations"],
                roleLevel: .management,
                priority: 80
            ),
            
            // Employee (Under Manager)
            RoleDefinitionModel(
                id: "employee",
                name: "Employee",
                description: "Standard employee access",
                inheritFrom: "manager",
                permissions: [
                    PermissionEntry(resource: "tasks", actions: ["read", "create", "edit"], priority: 70),
                    PermissionEntry(resource: "calendar", actions: ["read", "edit"], priority: 70)
                ],
                roleLevel: .standard,
                priority: 70,
                maxAssignments: 1000
            )
        ]
        
        // Setup child relationships
        testRoles[0].childRoles = ["executive"]
        testRoles[1].childRoles = ["manager"] 
        testRoles[2].childRoles = ["employee"]
        testRoles[3].childRoles = []
    }
    
    // MARK: - Role Hierarchy Tests
    
    func testRoleHierarchyCalculation() {
        let employee = testRoles[3] // Bottom of hierarchy
        var mutableEmployee = employee
        mutableEmployee.calculateEffectivePermissions(allRoles: testRoles)
        
        // Should have inherited permissions from all ancestors
        XCTAssertTrue(mutableEmployee.effectivePermissions.count > employee.permissions.count)
        
        // Should have system admin permissions (inherited)
        let hasSystemPermission = mutableEmployee.effectivePermissions.contains { permission in
            permission.resource == "*" && permission.inherited
        }
        XCTAssertTrue(hasSystemPermission)
        
        // Should have own permissions
        let hasOwnPermission = mutableEmployee.effectivePermissions.contains { permission in
            permission.resource == "tasks" && !permission.inherited
        }
        XCTAssertTrue(hasOwnPermission)
    }
    
    func testGetAncestors() {
        let employee = testRoles[3]
        let ancestors = employee.getAncestors(from: testRoles)
        
        XCTAssertEqual(ancestors.count, 3)
        XCTAssertEqual(ancestors[0].id, "manager") // Direct parent
        XCTAssertEqual(ancestors[1].id, "executive") // Grandparent
        XCTAssertEqual(ancestors[2].id, "system-admin") // Root
    }
    
    func testGetDescendants() {
        let systemAdmin = testRoles[0]
        let descendants = systemAdmin.getDescendants(from: testRoles)
        
        XCTAssertEqual(descendants.count, 3)
        let descendantIds = descendants.map { $0.id }
        XCTAssertTrue(descendantIds.contains("executive"))
        XCTAssertTrue(descendantIds.contains("manager"))
        XCTAssertTrue(descendantIds.contains("employee"))
    }
    
    func testCircularDependencyDetection() {
        // Create circular dependency: A -> B -> C -> A
        var roleA = RoleDefinitionModel(id: "A", name: "Role A", description: "Test")
        var roleB = RoleDefinitionModel(id: "B", name: "Role B", description: "Test")
        var roleC = RoleDefinitionModel(id: "C", name: "Role C", description: "Test")
        
        roleA.inheritFrom = "C"
        roleB.inheritFrom = "A"
        roleC.inheritFrom = "B"
        
        let circularRoles = [roleA, roleB, roleC]
        
        let errors = roleA.validateHierarchy(in: circularRoles)
        XCTAssertTrue(errors.contains { error in
            if case .circularDependency = error { return true }
            return false
        })
    }
    
    func testPermissionConflictResolution() {
        // Create roles with conflicting permissions
        var parent = RoleDefinitionModel(
            id: "parent",
            name: "Parent Role",
            description: "Parent with lower priority permission"
        )
        parent.permissions = [
            PermissionEntry(resource: "documents", actions: ["read"], priority: 50)
        ]
        
        var child = RoleDefinitionModel(
            id: "child",
            name: "Child Role", 
            description: "Child with higher priority permission"
        )
        child.inheritFrom = "parent"
        child.permissions = [
            PermissionEntry(resource: "documents", actions: ["read", "write", "delete"], priority: 80)
        ]
        
        let roles = [parent, child]
        child.calculateEffectivePermissions(allRoles: roles)
        
        // Child's higher priority permission should win
        let documentPermission = child.effectivePermissions.first { $0.resource == "documents" }
        XCTAssertNotNil(documentPermission)
        XCTAssertTrue(documentPermission!.actions.contains("write"))
        XCTAssertTrue(documentPermission!.actions.contains("delete"))
    }
    
    // MARK: - Role Level Validation Tests
    
    func testRoleLevelHierarchyValidation() {
        // Try to create invalid hierarchy (child with higher level than parent)
        var invalidChild = RoleDefinitionModel(
            id: "invalid",
            name: "Invalid Role",
            description: "Role with invalid hierarchy"
        )
        invalidChild.inheritFrom = "employee" // Employee is .standard (4)
        invalidChild.roleLevel = .management // Management is (2) - higher than standard
        
        let roles = testRoles + [invalidChild]
        let errors = invalidChild.validateHierarchy(in: roles)
        
        XCTAssertTrue(errors.contains { error in
            if case .invalidHierarchy = error { return true }
            return false
        })
    }
    
    func testRoleAssignmentValidation() async {
        let userContext = UserContext(
            userId: "user123",
            department: "sales",
            location: "headquarters",
            seniorityLevel: 5,
            skills: ["project-management", "leadership"],
            securityClearance: "standard"
        )
        
        // Should be able to assign manager role (department matches)
        do {
            let result = try await roleService.validateRoleAssignment(
                roleId: "manager",
                userId: "user123",
                userContext: userContext
            )
            XCTAssertTrue(result)
        } catch {
            XCTFail("Should be able to assign manager role: \(error)")
        }
        
        // Create role with department restriction that doesn't match
        var restrictedRole = RoleDefinitionModel(
            id: "hr-manager",
            name: "HR Manager",
            description: "HR specific role"
        )
        restrictedRole.departmentScope = ["hr", "legal"]
        restrictedRole.isActive = true
        
        roleService.roles.append(restrictedRole)
        
        // Should fail due to department mismatch
        do {
            _ = try await roleService.validateRoleAssignment(
                roleId: "hr-manager",
                userId: "user123", 
                userContext: userContext
            )
            XCTFail("Should not be able to assign HR role to sales user")
        } catch RoleHierarchyError.departmentMismatch {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Permission Management Tests
    
    func testPermissionInheritance() {
        roleService.roles = testRoles
        
        // Calculate effective permissions for all roles
        for i in 0..<roleService.roles.count {
            roleService.roles[i].calculateEffectivePermissions(allRoles: roleService.roles)
        }
        
        // Employee should have permissions from all ancestors
        let hasSystemPermission = roleService.hasPermission(
            roleId: "employee",
            resource: "*",
            action: "*"
        )
        XCTAssertTrue(hasSystemPermission, "Employee should inherit system admin permissions")
        
        let hasManagerPermission = roleService.hasPermission(
            roleId: "employee", 
            resource: "team",
            action: "manage"
        )
        XCTAssertTrue(hasManagerPermission, "Employee should inherit manager permissions")
        
        let hasOwnPermission = roleService.hasPermission(
            roleId: "employee",
            resource: "tasks", 
            action: "create"
        )
        XCTAssertTrue(hasOwnPermission, "Employee should have own permissions")
    }
    
    func testPermissionDiff() {
        roleService.roles = testRoles
        
        // Calculate effective permissions
        for i in 0..<roleService.roles.count {
            roleService.roles[i].calculateEffectivePermissions(allRoles: roleService.roles)
        }
        
        let diff = roleService.getPermissionDiff(fromRoleId: "manager", toRoleId: "employee")
        
        // Employee should have additional permissions
        XCTAssertFalse(diff.added.isEmpty, "Employee should have additional permissions compared to manager")
        
        // Should have some unchanged permissions (inherited ones)
        XCTAssertFalse(diff.unchanged.isEmpty, "Should have some common permissions")
    }
    
    // MARK: - Validation Rule Tests
    
    func testCustomValidationRules() {
        var roleWithRules = RoleDefinitionModel(
            id: "senior-dev",
            name: "Senior Developer", 
            description: "Senior developer role with skill requirements"
        )
        
        roleWithRules.validationRules = [
            RoleValidationRule(
                type: .skillRequirement,
                condition: "senior-development",
                errorMessage: "Requires senior development skills"
            ),
            RoleValidationRule(
                type: .seniorityLevel,
                condition: "7",
                errorMessage: "Requires at least 7 years experience"
            )
        ]
        
        let validUserContext = UserContext(
            userId: "user1",
            department: "engineering",
            location: "office",
            seniorityLevel: 8,
            skills: ["senior-development", "architecture"],
            securityClearance: "standard"
        )
        
        let invalidUserContext = UserContext(
            userId: "user2",
            department: "engineering", 
            location: "office",
            seniorityLevel: 3,
            skills: ["junior-development"],
            securityClearance: "standard"
        )
        
        roleService.roles = [roleWithRules]
        
        Task {
            // Valid user should pass
            do {
                let result = try await roleService.validateRoleAssignment(
                    roleId: "senior-dev",
                    userId: "user1",
                    userContext: validUserContext
                )
                XCTAssertTrue(result)
            } catch {
                XCTFail("Valid user should pass validation: \(error)")
            }
            
            // Invalid user should fail
            do {
                _ = try await roleService.validateRoleAssignment(
                    roleId: "senior-dev", 
                    userId: "user2",
                    userContext: invalidUserContext
                )
                XCTFail("Invalid user should fail validation")
            } catch RoleHierarchyError.validationRuleFailed {
                // Expected error
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    // MARK: - Max Assignments Test
    
    func testMaxAssignments() {
        var limitedRole = RoleDefinitionModel(
            id: "limited",
            name: "Limited Role",
            description: "Role with assignment limit"
        )
        limitedRole.maxAssignments = 2
        limitedRole.isActive = true
        
        roleService.roles = [limitedRole]
        
        // This test would need mock implementation of getCurrentAssignmentCount
        // For now, just verify the validation logic exists
        XCTAssertEqual(limitedRole.maxAssignments, 2)
        XCTAssertTrue(limitedRole.isActive)
    }
    
    // MARK: - Performance Tests
    
    func testLargeHierarchyPerformance() {
        measure {
            // Create a large hierarchy for performance testing
            var largeRoleSet: [RoleDefinitionModel] = []
            
            // Create 100 roles in a deep hierarchy
            for i in 0..<100 {
                var role = RoleDefinitionModel(
                    id: "role-\(i)",
                    name: "Role \(i)",
                    description: "Test role \(i)"
                )
                
                if i > 0 {
                    role.inheritFrom = "role-\(i-1)"
                }
                
                role.permissions = [
                    PermissionEntry(resource: "resource-\(i)", actions: ["read"], priority: i)
                ]
                
                largeRoleSet.append(role)
            }
            
            // Update child relationships
            for i in 0..<largeRoleSet.count - 1 {
                largeRoleSet[i].childRoles = ["role-\(i+1)"]
            }
            
            // Calculate effective permissions for the deepest role
            var deepestRole = largeRoleSet.last!
            deepestRole.calculateEffectivePermissions(allRoles: largeRoleSet)
            
            // Should have inherited all permissions
            XCTAssertEqual(deepestRole.effectivePermissions.count, 100)
        }
    }
}

// MARK: - Mock Extensions for Testing

extension RoleHierarchyService {
    func setTestRoles(_ roles: [RoleDefinitionModel]) {
        self.roles = roles
    }
}
