import CloudKit

final class EmployeeServiceTests: XCTestCase {
    
    var mockService: MockEmployeeService!
    var sampleEmployee: Employee!
    
    override func setUp() {
        super.setUp()
        mockService = MockEmployeeService()
        sampleEmployee = Employee(
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@company.com",
            employeeId: "EMP001",
            department: "Engineering",
            position: "Senior Developer",
            hireDate: Date(),
            isActive: true
        )
    }
    
    override func tearDown() {
        mockService = nil
        sampleEmployee = nil
        super.tearDown()
    }
    
    // MARK: - Create Employee Tests
    
    func testCreateEmployee() async throws {
        // Given
        let initialCount = try await mockService.fetchEmployees().count
        
        // When
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        
        // Then
        XCTAssertEqual(createdEmployee.firstName, sampleEmployee.firstName)
        XCTAssertEqual(createdEmployee.lastName, sampleEmployee.lastName)
        XCTAssertEqual(createdEmployee.email, sampleEmployee.email)
        XCTAssertEqual(createdEmployee.employeeId, sampleEmployee.employeeId)
        XCTAssertEqual(createdEmployee.department, sampleEmployee.department)
        XCTAssertEqual(createdEmployee.position, sampleEmployee.position)
        XCTAssertEqual(createdEmployee.isActive, sampleEmployee.isActive)
        
        let finalCount = try await mockService.fetchEmployees().count
        XCTAssertEqual(finalCount, initialCount + 1)
    }
    
    func testCreateEmployeeWithDuplicateEmail() async throws {
        // Given
        _ = try await mockService.createEmployee(sampleEmployee)
        
        let duplicateEmployee = Employee(
            firstName: "Jane",
            lastName: "Smith",
            email: sampleEmployee.email, // Same email
            employeeId: "EMP002",
            department: "Marketing",
            position: "Manager",
            hireDate: Date(),
            isActive: true
        )
        
        // When/Then
        do {
            _ = try await mockService.createEmployee(duplicateEmployee)
            XCTFail("Should have thrown an error for duplicate email")
        } catch {
            XCTAssertTrue(error is EmployeeServiceError)
            if case EmployeeServiceError.duplicateEmail = error {
                // Expected error
            } else {
                XCTFail("Expected duplicateEmail error")
            }
        }
    }
    
    func testCreateEmployeeWithDuplicateEmployeeId() async throws {
        // Given
        _ = try await mockService.createEmployee(sampleEmployee)
        
        let duplicateEmployee = Employee(
            firstName: "Jane",
            lastName: "Smith",
            email: "jane.smith@company.com",
            employeeId: sampleEmployee.employeeId, // Same employee ID
            department: "Marketing",
            position: "Manager",
            hireDate: Date(),
            isActive: true
        )
        
        // When/Then
        do {
            _ = try await mockService.createEmployee(duplicateEmployee)
            XCTFail("Should have thrown an error for duplicate employee ID")
        } catch {
            XCTAssertTrue(error is EmployeeServiceError)
            if case EmployeeServiceError.duplicateEmployeeId = error {
                // Expected error
            } else {
                XCTFail("Expected duplicateEmployeeId error")
            }
        }
    }
    
    // MARK: - Fetch Employee Tests
    
    func testFetchEmployees() async throws {
        // Given
        _ = try await mockService.createEmployee(sampleEmployee)
        
        // When
        let employees = try await mockService.fetchEmployees()
        
        // Then
        XCTAssertFalse(employees.isEmpty)
        XCTAssertTrue(employees.contains { $0.employeeId == sampleEmployee.employeeId })
    }
    
    func testFetchEmployeeById() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        
        // When
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        
        // Then
        XCTAssertNotNil(fetchedEmployee)
        XCTAssertEqual(fetchedEmployee?.id, createdEmployee.id)
        XCTAssertEqual(fetchedEmployee?.employeeId, createdEmployee.employeeId)
    }
    
    func testFetchEmployeeByEmployeeId() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        
        // When
        let fetchedEmployee = try await mockService.fetchEmployeeByEmployeeId(createdEmployee.employeeId)
        
        // Then
        XCTAssertNotNil(fetchedEmployee)
        XCTAssertEqual(fetchedEmployee?.id, createdEmployee.id)
        XCTAssertEqual(fetchedEmployee?.employeeId, createdEmployee.employeeId)
    }
    
    func testFetchEmployeeByEmail() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        
        // When
        let fetchedEmployee = try await mockService.fetchEmployeeByEmail(createdEmployee.email)
        
        // Then
        XCTAssertNotNil(fetchedEmployee)
        XCTAssertEqual(fetchedEmployee?.id, createdEmployee.id)
        XCTAssertEqual(fetchedEmployee?.email, createdEmployee.email)
    }
    
    func testFetchNonExistentEmployee() async throws {
        // When
        let fetchedEmployee = try await mockService.fetchEmployee(by: "non-existent-id")
        
        // Then
        XCTAssertNil(fetchedEmployee)
    }
    
    // MARK: - Update Employee Tests
    
    func testUpdateEmployee() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        var updatedEmployee = createdEmployee
        updatedEmployee.department = "Product Management"
        updatedEmployee.position = "Product Manager"
        updatedEmployee.salary = 95000
        
        // When
        let result = try await mockService.updateEmployee(updatedEmployee)
        
        // Then
        XCTAssertEqual(result.department, "Product Management")
        XCTAssertEqual(result.position, "Product Manager")
        XCTAssertEqual(result.salary, 95000)
        
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertEqual(fetchedEmployee?.department, "Product Management")
        XCTAssertEqual(fetchedEmployee?.position, "Product Manager")
    }
    
    // MARK: - Delete Employee Tests
    
    func testDeleteEmployee() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        let initialCount = try await mockService.fetchEmployees().count
        
        // When
        try await mockService.deleteEmployee(id: createdEmployee.id)
        
        // Then
        let finalCount = try await mockService.fetchEmployees().count
        XCTAssertEqual(finalCount, initialCount - 1)
        
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertNil(fetchedEmployee)
    }
    
    // MARK: - Department Tests
    
    func testFetchEmployeesByDepartment() async throws {
        // Given
        let engineeringEmployee = Employee(firstName: "Alice", lastName: "Johnson", email: "alice@company.com", employeeId: "EMP100", department: "Engineering", position: "Developer", hireDate: Date(), isActive: true)
        let marketingEmployee = Employee(firstName: "Bob", lastName: "Wilson", email: "bob@company.com", employeeId: "EMP101", department: "Marketing", position: "Specialist", hireDate: Date(), isActive: true)
        
        _ = try await mockService.createEmployee(engineeringEmployee)
        _ = try await mockService.createEmployee(marketingEmployee)
        
        // When
        let engineeringEmployees = try await mockService.fetchEmployeesByDepartment("Engineering")
        let marketingEmployees = try await mockService.fetchEmployeesByDepartment("Marketing")
        
        // Then
        XCTAssertTrue(engineeringEmployees.contains { $0.employeeId == "EMP100" })
        XCTAssertFalse(engineeringEmployees.contains { $0.employeeId == "EMP101" })
        XCTAssertTrue(marketingEmployees.contains { $0.employeeId == "EMP101" })
        XCTAssertFalse(marketingEmployees.contains { $0.employeeId == "EMP100" })
    }
    
    func testFetchEmployeesByPosition() async throws {
        // Given
        let developer = Employee(firstName: "Charlie", lastName: "Brown", email: "charlie@company.com", employeeId: "EMP200", department: "Engineering", position: "Developer", hireDate: Date(), isActive: true)
        let manager = Employee(firstName: "Diana", lastName: "Green", email: "diana@company.com", employeeId: "EMP201", department: "Engineering", position: "Manager", hireDate: Date(), isActive: true)
        
        _ = try await mockService.createEmployee(developer)
        _ = try await mockService.createEmployee(manager)
        
        // When
        let developers = try await mockService.fetchEmployeesByPosition("Developer")
        let managers = try await mockService.fetchEmployeesByPosition("Manager")
        
        // Then
        XCTAssertTrue(developers.contains { $0.employeeId == "EMP200" })
        XCTAssertFalse(developers.contains { $0.employeeId == "EMP201" })
        XCTAssertTrue(managers.contains { $0.employeeId == "EMP201" })
        XCTAssertFalse(managers.contains { $0.employeeId == "EMP200" })
    }
    
    // MARK: - Status Tests
    
    func testFetchActiveEmployees() async throws {
        // Given
        let activeEmployee = Employee(firstName: "Eve", lastName: "Davis", email: "eve@company.com", employeeId: "EMP300", department: "Sales", position: "Representative", hireDate: Date(), isActive: true)
        let inactiveEmployee = Employee(firstName: "Frank", lastName: "Miller", email: "frank@company.com", employeeId: "EMP301", department: "Sales", position: "Representative", hireDate: Date(), isActive: false)
        
        _ = try await mockService.createEmployee(activeEmployee)
        _ = try await mockService.createEmployee(inactiveEmployee)
        
        // When
        let activeEmployees = try await mockService.fetchActiveEmployees()
        
        // Then
        XCTAssertTrue(activeEmployees.contains { $0.employeeId == "EMP300" })
        XCTAssertFalse(activeEmployees.contains { $0.employeeId == "EMP301" })
        XCTAssertTrue(activeEmployees.allSatisfy { $0.isActive })
    }
    
    func testDeactivateEmployee() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        XCTAssertTrue(createdEmployee.isActive)
        
        // When
        try await mockService.deactivateEmployee(id: createdEmployee.id)
        
        // Then
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertNotNil(fetchedEmployee)
        XCTAssertFalse(fetchedEmployee!.isActive)
        
        let activeEmployees = try await mockService.fetchActiveEmployees()
        XCTAssertFalse(activeEmployees.contains { $0.id == createdEmployee.id })
    }
    
    func testReactivateEmployee() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        try await mockService.deactivateEmployee(id: createdEmployee.id)
        
        // When
        try await mockService.reactivateEmployee(id: createdEmployee.id)
        
        // Then
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertNotNil(fetchedEmployee)
        XCTAssertTrue(fetchedEmployee!.isActive)
        
        let activeEmployees = try await mockService.fetchActiveEmployees()
        XCTAssertTrue(activeEmployees.contains { $0.id == createdEmployee.id })
    }
    
    // MARK: - Search Tests
    
    func testSearchEmployees() async throws {
        // Given
        let employee1 = Employee(firstName: "John", lastName: "Smith", email: "john.smith@company.com", employeeId: "EMP400", department: "Engineering", position: "Senior Developer", hireDate: Date(), isActive: true)
        let employee2 = Employee(firstName: "Jane", lastName: "Johnson", email: "jane.johnson@company.com", employeeId: "EMP401", department: "Marketing", position: "Manager", hireDate: Date(), isActive: true)
        
        _ = try await mockService.createEmployee(employee1)
        _ = try await mockService.createEmployee(employee2)
        
        // When
        let johnResults = try await mockService.searchEmployees(query: "john")
        let smithResults = try await mockService.searchEmployees(query: "smith")
        let engineeringResults = try await mockService.searchEmployees(query: "engineering")
        
        // Then
        XCTAssertTrue(johnResults.contains { $0.firstName.lowercased().contains("john") })
        XCTAssertTrue(smithResults.contains { $0.lastName.lowercased().contains("smith") })
        XCTAssertTrue(engineeringResults.contains { $0.department.lowercased().contains("engineering") })
    }
    
    // MARK: - Role Management Tests
    
    func testAssignRole() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        let role = EmployeeRole.admin
        
        // When
        try await mockService.assignRole(employeeId: createdEmployee.id, role: role)
        
        // Then
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertTrue(fetchedEmployee?.roles.contains(role) ?? false)
    }
    
    func testRemoveRole() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        let role = EmployeeRole.admin
        try await mockService.assignRole(employeeId: createdEmployee.id, role: role)
        
        // When
        try await mockService.removeRole(employeeId: createdEmployee.id, role: role)
        
        // Then
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertFalse(fetchedEmployee?.roles.contains(role) ?? true)
    }
    
    func testFetchEmployeesByRole() async throws {
        // Given
        let adminEmployee = Employee(firstName: "Admin", lastName: "User", email: "admin@company.com", employeeId: "EMP500", department: "IT", position: "Admin", hireDate: Date(), isActive: true)
        let regularEmployee = Employee(firstName: "Regular", lastName: "User", email: "regular@company.com", employeeId: "EMP501", department: "Sales", position: "Rep", hireDate: Date(), isActive: true)
        
        let createdAdmin = try await mockService.createEmployee(adminEmployee)
        let createdRegular = try await mockService.createEmployee(regularEmployee)
        
        try await mockService.assignRole(employeeId: createdAdmin.id, role: .admin)
        try await mockService.assignRole(employeeId: createdRegular.id, role: .user)
        
        // When
        let adminEmployees = try await mockService.fetchEmployeesByRole(.admin)
        let userEmployees = try await mockService.fetchEmployeesByRole(.user)
        
        // Then
        XCTAssertTrue(adminEmployees.contains { $0.id == createdAdmin.id })
        XCTAssertFalse(adminEmployees.contains { $0.id == createdRegular.id })
        XCTAssertTrue(userEmployees.contains { $0.id == createdRegular.id })
        XCTAssertFalse(userEmployees.contains { $0.id == createdAdmin.id })
    }
    
    // MARK: - Performance Tracking Tests
    
    func testUpdatePerformanceRating() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        let performanceReview = PerformanceReview(
            employeeId: createdEmployee.id,
            reviewPeriod: "2024 Q1",
            rating: 4.5,
            goals: ["Complete project X", "Improve skills in Y"],
            achievements: ["Delivered project ahead of schedule"],
            areasForImprovement: ["Time management"],
            reviewerId: "manager-id",
            reviewDate: Date()
        )
        
        // When
        try await mockService.updatePerformanceRating(createdEmployee.id, review: performanceReview)
        
        // Then
        let fetchedEmployee = try await mockService.fetchEmployee(by: createdEmployee.id)
        XCTAssertEqual(fetchedEmployee?.currentPerformanceRating, 4.5)
    }
    
    func testFetchPerformanceHistory() async throws {
        // Given
        let createdEmployee = try await mockService.createEmployee(sampleEmployee)
        
        // When
        let performanceHistory = try await mockService.fetchPerformanceHistory(employeeId: createdEmployee.id)
        
        // Then
        XCTAssertNotNil(performanceHistory)
        // Mock service might return empty array initially
    }
    
    // MARK: - Statistics Tests
    
    func testGetEmployeeStatistics() async throws {
        // Given
        let employee1 = Employee(firstName: "Test1", lastName: "User", email: "test1@company.com", employeeId: "EMP600", department: "Engineering", position: "Developer", hireDate: Date(), isActive: true)
        let employee2 = Employee(firstName: "Test2", lastName: "User", email: "test2@company.com", employeeId: "EMP601", department: "Marketing", position: "Manager", hireDate: Date(), isActive: false)
        
        _ = try await mockService.createEmployee(employee1)
        _ = try await mockService.createEmployee(employee2)
        
        // When
        let stats = try await mockService.getEmployeeStatistics()
        
        // Then
        XCTAssertNotNil(stats)
        XCTAssertGreaterThanOrEqual(stats.totalEmployees, 2)
        XCTAssertGreaterThanOrEqual(stats.activeEmployees, 1)
        XCTAssertGreaterThanOrEqual(stats.inactiveEmployees, 1)
        XCTAssertGreaterThanOrEqual(stats.departmentCounts.count, 1)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceCreateMultipleEmployees() {
        measure {
            Task {
                for i in 0..<50 {
                    let employee = Employee(
                        firstName: "Test\(i)",
                        lastName: "User",
                        email: "test\(i)@company.com",
                        employeeId: "TEST\(i)",
                        department: "Testing",
                        position: "Tester",
                        hireDate: Date(),
                        isActive: true
                    )
                    _ = try? await mockService.createEmployee(employee)
                }
            }
        }
    }
    
    func testPerformanceFetchEmployees() async throws {
        // Given - Create multiple employees
        for i in 0..<30 {
            let employee = Employee(
                firstName: "Perf\(i)",
                lastName: "Test",
                email: "perf\(i)@company.com",
                employeeId: "PERF\(i)",
                department: "Performance",
                position: "Tester",
                hireDate: Date(),
                isActive: true
            )
            _ = try await mockService.createEmployee(employee)
        }
        
        // When/Then
        measure {
            Task {
                _ = try? await mockService.fetchEmployees()
            }
        }
    }
}

// MARK: - CloudKit Extensions Tests

final class EmployeeCloudKitTests: XCTestCase {
    
    func testEmployeeCloudKitSerialization() {
        // Given
        let employee = Employee(
            id: "test-id",
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@company.com",
            employeeId: "EMP001",
            department: "Engineering",
            position: "Senior Developer",
            hireDate: Date(),
            isActive: true,
            roles: [.admin, .user],
            salary: 90000,
            manager: "manager-id",
            skills: ["Swift", "iOS", "UIKit"],
            currentPerformanceRating: 4.2,
            emergencyContactName: "Jane Doe",
            emergencyContactPhone: "555-0123"
        )
        
        // When
        let record = employee.toCKRecord()
        let deserializedEmployee = Employee.from(record: record)
        
        // Then
        XCTAssertNotNil(deserializedEmployee)
        XCTAssertEqual(deserializedEmployee?.id, employee.id)
        XCTAssertEqual(deserializedEmployee?.firstName, employee.firstName)
        XCTAssertEqual(deserializedEmployee?.lastName, employee.lastName)
        XCTAssertEqual(deserializedEmployee?.email, employee.email)
        XCTAssertEqual(deserializedEmployee?.employeeId, employee.employeeId)
        XCTAssertEqual(deserializedEmployee?.department, employee.department)
        XCTAssertEqual(deserializedEmployee?.position, employee.position)
        XCTAssertEqual(deserializedEmployee?.isActive, employee.isActive)
        XCTAssertEqual(deserializedEmployee?.roles, employee.roles)
        XCTAssertEqual(deserializedEmployee?.salary, employee.salary)
        XCTAssertEqual(deserializedEmployee?.manager, employee.manager)
        XCTAssertEqual(deserializedEmployee?.skills, employee.skills)
        XCTAssertEqual(deserializedEmployee?.currentPerformanceRating, employee.currentPerformanceRating)
        XCTAssertEqual(deserializedEmployee?.emergencyContactName, employee.emergencyContactName)
        XCTAssertEqual(deserializedEmployee?.emergencyContactPhone, employee.emergencyContactPhone)
    }
    
    func testPerformanceReviewCloudKitSerialization() {
        // Given
        let review = PerformanceReview(
            id: "review-id",
            employeeId: "employee-id",
            reviewPeriod: "2024 Q1",
            rating: 4.5,
            goals: ["Goal 1", "Goal 2"],
            achievements: ["Achievement 1", "Achievement 2"],
            areasForImprovement: ["Area 1", "Area 2"],
            reviewerId: "reviewer-id",
            reviewDate: Date(),
            notes: "Additional notes"
        )
        
        // When
        let record = review.toCKRecord()
        let deserializedReview = PerformanceReview.from(record: record)
        
        // Then
        XCTAssertNotNil(deserializedReview)
        XCTAssertEqual(deserializedReview?.id, review.id)
        XCTAssertEqual(deserializedReview?.employeeId, review.employeeId)
        XCTAssertEqual(deserializedReview?.reviewPeriod, review.reviewPeriod)
        XCTAssertEqual(deserializedReview?.rating, review.rating)
        XCTAssertEqual(deserializedReview?.goals, review.goals)
        XCTAssertEqual(deserializedReview?.achievements, review.achievements)
        XCTAssertEqual(deserializedReview?.areasForImprovement, review.areasForImprovement)
        XCTAssertEqual(deserializedReview?.reviewerId, review.reviewerId)
        XCTAssertEqual(deserializedReview?.notes, review.notes)
    }
}
