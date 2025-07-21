#if canImport(XCTest)
import XCTest
import Combine
@testable import DiamondDeskERP

@MainActor
final class DirectoryServiceTests: XCTestCase {
    private var directoryService: DirectoryService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        directoryService = DirectoryService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        directoryService = nil
        try await super.tearDown()
    }
    
    // MARK: - Employee Tests
    
    func testCreateEmployee() async throws {
        // Given
        let employee = createTestEmployee()
        
        // When
        let createdEmployee = try await directoryService.createEmployee(employee)
        
        // Then
        XCTAssertEqual(createdEmployee.employeeNumber, employee.employeeNumber)
        XCTAssertEqual(createdEmployee.firstName, employee.firstName)
        XCTAssertEqual(createdEmployee.lastName, employee.lastName)
        XCTAssertEqual(createdEmployee.email, employee.email)
        XCTAssertEqual(createdEmployee.department, employee.department)
    }
    
    func testFetchEmployees() async throws {
        // Given
        let employee1 = createTestEmployee(employeeNumber: "EMP001", firstName: "John", lastName: "Doe")
        let employee2 = createTestEmployee(employeeNumber: "EMP002", firstName: "Jane", lastName: "Smith")
        
        _ = try await directoryService.createEmployee(employee1)
        _ = try await directoryService.createEmployee(employee2)
        
        // When
        let employees = try await directoryService.fetchEmployees()
        
        // Then
        XCTAssertGreaterThanOrEqual(employees.count, 2)
        XCTAssertTrue(employees.contains { $0.employeeNumber == "EMP001" })
        XCTAssertTrue(employees.contains { $0.employeeNumber == "EMP002" })
    }
    
    func testUpdateEmployee() async throws {
        // Given
        let originalEmployee = createTestEmployee()
        let createdEmployee = try await directoryService.createEmployee(originalEmployee)
        
        var updatedEmployee = createdEmployee
        updatedEmployee.title = "Senior Software Engineer"
        updatedEmployee.department = "Engineering"
        
        // When
        let result = try await directoryService.updateEmployee(updatedEmployee)
        
        // Then
        XCTAssertEqual(result.title, "Senior Software Engineer")
        XCTAssertEqual(result.department, "Engineering")
        XCTAssertEqual(result.employeeNumber, originalEmployee.employeeNumber)
    }
    
    func testDeleteEmployee() async throws {
        // Given
        let employee = createTestEmployee()
        let createdEmployee = try await directoryService.createEmployee(employee)
        
        // When
        try await directoryService.deleteEmployee(createdEmployee)
        
        // Then
        let employees = try await directoryService.fetchEmployees()
        XCTAssertFalse(employees.contains { $0.employeeNumber == employee.employeeNumber })
    }
    
    func testSearchEmployees() async throws {
        // Given
        let employee1 = createTestEmployee(employeeNumber: "EMP001", firstName: "John", lastName: "Doe", department: "Engineering")
        let employee2 = createTestEmployee(employeeNumber: "EMP002", firstName: "Jane", lastName: "Smith", department: "Marketing")
        let employee3 = createTestEmployee(employeeNumber: "EMP003", firstName: "Bob", lastName: "Johnson", department: "Engineering")
        
        _ = try await directoryService.createEmployee(employee1)
        _ = try await directoryService.createEmployee(employee2)
        _ = try await directoryService.createEmployee(employee3)
        
        // When
        let engineeringEmployees = try await directoryService.searchEmployees(query: "Engineering")
        let johnEmployees = try await directoryService.searchEmployees(query: "John")
        
        // Then
        XCTAssertGreaterThanOrEqual(engineeringEmployees.count, 2)
        XCTAssertTrue(engineeringEmployees.allSatisfy { $0.department.contains("Engineering") || $0.firstName.contains("Engineering") || $0.lastName.contains("Engineering") })
        
        XCTAssertGreaterThanOrEqual(johnEmployees.count, 1)
        XCTAssertTrue(johnEmployees.contains { $0.firstName == "John" || $0.lastName == "Johnson" })
    }
    
    func testFilterEmployees() async throws {
        // Given
        let employee1 = createTestEmployee(employeeNumber: "EMP001", department: "Engineering", isActive: true)
        let employee2 = createTestEmployee(employeeNumber: "EMP002", department: "Marketing", isActive: false)
        let employee3 = createTestEmployee(employeeNumber: "EMP003", department: "Engineering", isActive: true)
        
        _ = try await directoryService.createEmployee(employee1)
        _ = try await directoryService.createEmployee(employee2)
        _ = try await directoryService.createEmployee(employee3)
        
        let filter = EmployeeFilter(
            departments: ["Engineering"],
            isActive: true,
            employmentTypes: nil,
            workLocations: nil
        )
        
        // When
        let filteredEmployees = try await directoryService.filterEmployees(filter: filter)
        
        // Then
        XCTAssertGreaterThanOrEqual(filteredEmployees.count, 2)
        XCTAssertTrue(filteredEmployees.allSatisfy { $0.department == "Engineering" && $0.isActive })
    }
    
    // MARK: - Vendor Tests
    
    func testCreateVendor() async throws {
        // Given
        let vendor = createTestVendor()
        
        // When
        let createdVendor = try await directoryService.createVendor(vendor)
        
        // Then
        XCTAssertEqual(createdVendor.vendorNumber, vendor.vendorNumber)
        XCTAssertEqual(createdVendor.companyName, vendor.companyName)
        XCTAssertEqual(createdVendor.contactPerson, vendor.contactPerson)
        XCTAssertEqual(createdVendor.email, vendor.email)
        XCTAssertEqual(createdVendor.vendorType, vendor.vendorType)
    }
    
    func testFetchVendors() async throws {
        // Given
        let vendor1 = createTestVendor(vendorNumber: "VEN001", companyName: "Tech Solutions Inc")
        let vendor2 = createTestVendor(vendorNumber: "VEN002", companyName: "Office Supplies Co")
        
        _ = try await directoryService.createVendor(vendor1)
        _ = try await directoryService.createVendor(vendor2)
        
        // When
        let vendors = try await directoryService.fetchVendors()
        
        // Then
        XCTAssertGreaterThanOrEqual(vendors.count, 2)
        XCTAssertTrue(vendors.contains { $0.vendorNumber == "VEN001" })
        XCTAssertTrue(vendors.contains { $0.vendorNumber == "VEN002" })
    }
    
    func testUpdateVendor() async throws {
        // Given
        let originalVendor = createTestVendor()
        let createdVendor = try await directoryService.createVendor(originalVendor)
        
        var updatedVendor = createdVendor
        updatedVendor.contactPerson = "Jane Doe"
        updatedVendor.isPreferred = true
        
        // When
        let result = try await directoryService.updateVendor(updatedVendor)
        
        // Then
        XCTAssertEqual(result.contactPerson, "Jane Doe")
        XCTAssertEqual(result.isPreferred, true)
        XCTAssertEqual(result.vendorNumber, originalVendor.vendorNumber)
    }
    
    func testDeleteVendor() async throws {
        // Given
        let vendor = createTestVendor()
        let createdVendor = try await directoryService.createVendor(vendor)
        
        // When
        try await directoryService.deleteVendor(createdVendor)
        
        // Then
        let vendors = try await directoryService.fetchVendors()
        XCTAssertFalse(vendors.contains { $0.vendorNumber == vendor.vendorNumber })
    }
    
    func testSearchVendors() async throws {
        // Given
        let vendor1 = createTestVendor(vendorNumber: "VEN001", companyName: "Tech Solutions Inc", vendorType: .supplier)
        let vendor2 = createTestVendor(vendorNumber: "VEN002", companyName: "Office Supplies Co", vendorType: .supplier)
        let vendor3 = createTestVendor(vendorNumber: "VEN003", companyName: "Consulting Partners", vendorType: .consultant)
        
        _ = try await directoryService.createVendor(vendor1)
        _ = try await directoryService.createVendor(vendor2)
        _ = try await directoryService.createVendor(vendor3)
        
        // When
        let techVendors = try await directoryService.searchVendors(query: "Tech")
        let suppliesVendors = try await directoryService.searchVendors(query: "Supplies")
        
        // Then
        XCTAssertGreaterThanOrEqual(techVendors.count, 1)
        XCTAssertTrue(techVendors.contains { $0.companyName.contains("Tech") })
        
        XCTAssertGreaterThanOrEqual(suppliesVendors.count, 1)
        XCTAssertTrue(suppliesVendors.contains { $0.companyName.contains("Supplies") })
    }
    
    func testFilterVendors() async throws {
        // Given
        let vendor1 = createTestVendor(vendorNumber: "VEN001", vendorType: .supplier, isPreferred: true)
        let vendor2 = createTestVendor(vendorNumber: "VEN002", vendorType: .consultant, isPreferred: false)
        let vendor3 = createTestVendor(vendorNumber: "VEN003", vendorType: .supplier, isPreferred: true)
        
        _ = try await directoryService.createVendor(vendor1)
        _ = try await directoryService.createVendor(vendor2)
        _ = try await directoryService.createVendor(vendor3)
        
        let filter = VendorFilter(
            vendorTypes: [.supplier],
            isPreferred: true,
            contractStatuses: nil,
            riskLevels: nil
        )
        
        // When
        let filteredVendors = try await directoryService.filterVendors(filter: filter)
        
        // Then
        XCTAssertGreaterThanOrEqual(filteredVendors.count, 2)
        XCTAssertTrue(filteredVendors.allSatisfy { $0.vendorType == .supplier && $0.isPreferred })
    }
    
    // MARK: - Analytics Tests
    
    func testGenerateAnalytics() async throws {
        // Given
        let employee1 = createTestEmployee(employeeNumber: "EMP001", department: "Engineering", isActive: true)
        let employee2 = createTestEmployee(employeeNumber: "EMP002", department: "Marketing", isActive: true)
        let employee3 = createTestEmployee(employeeNumber: "EMP003", department: "Engineering", isActive: false)
        
        let vendor1 = createTestVendor(vendorNumber: "VEN001", isPreferred: true)
        let vendor2 = createTestVendor(vendorNumber: "VEN002", isPreferred: false)
        
        _ = try await directoryService.createEmployee(employee1)
        _ = try await directoryService.createEmployee(employee2)
        _ = try await directoryService.createEmployee(employee3)
        _ = try await directoryService.createVendor(vendor1)
        _ = try await directoryService.createVendor(vendor2)
        
        // When
        let analytics = try await directoryService.generateAnalytics()
        
        // Then
        XCTAssertGreaterThanOrEqual(analytics.totalEmployees, 3)
        XCTAssertGreaterThanOrEqual(analytics.activeEmployees, 2)
        XCTAssertGreaterThanOrEqual(analytics.totalVendors, 2)
        XCTAssertGreaterThanOrEqual(analytics.preferredVendors, 1)
        XCTAssertTrue(analytics.departmentBreakdown.keys.contains("Engineering"))
        XCTAssertTrue(analytics.departmentBreakdown.keys.contains("Marketing"))
    }
    
    // MARK: - Bulk Operations Tests
    
    func testBulkImportEmployees() async throws {
        // Given
        let employees = [
            createTestEmployee(employeeNumber: "EMP101", firstName: "Alice", lastName: "Johnson"),
            createTestEmployee(employeeNumber: "EMP102", firstName: "Bob", lastName: "Williams"),
            createTestEmployee(employeeNumber: "EMP103", firstName: "Carol", lastName: "Brown")
        ]
        
        // When
        let results = try await directoryService.bulkImportEmployees(employees)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.employeeNumber.hasPrefix("EMP10") })
        
        let fetchedEmployees = try await directoryService.fetchEmployees()
        XCTAssertTrue(fetchedEmployees.contains { $0.employeeNumber == "EMP101" })
        XCTAssertTrue(fetchedEmployees.contains { $0.employeeNumber == "EMP102" })
        XCTAssertTrue(fetchedEmployees.contains { $0.employeeNumber == "EMP103" })
    }
    
    func testBulkImportVendors() async throws {
        // Given
        let vendors = [
            createTestVendor(vendorNumber: "VEN101", companyName: "Alpha Corp"),
            createTestVendor(vendorNumber: "VEN102", companyName: "Beta LLC"),
            createTestVendor(vendorNumber: "VEN103", companyName: "Gamma Inc")
        ]
        
        // When
        let results = try await directoryService.bulkImportVendors(vendors)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.vendorNumber.hasPrefix("VEN10") })
        
        let fetchedVendors = try await directoryService.fetchVendors()
        XCTAssertTrue(fetchedVendors.contains { $0.vendorNumber == "VEN101" })
        XCTAssertTrue(fetchedVendors.contains { $0.vendorNumber == "VEN102" })
        XCTAssertTrue(fetchedVendors.contains { $0.vendorNumber == "VEN103" })
    }
    
    // MARK: - Performance Tests
    
    func testFetchEmployeesPerformance() {
        measure {
            Task {
                do {
                    _ = try await directoryService.fetchEmployees()
                } catch {
                    XCTFail("Failed to fetch employees: \(error)")
                }
            }
        }
    }
    
    func testFetchVendorsPerformance() {
        measure {
            Task {
                do {
                    _ = try await directoryService.fetchVendors()
                } catch {
                    XCTFail("Failed to fetch vendors: \(error)")
                }
            }
        }
    }
    
    func testSearchPerformance() {
        measure {
            Task {
                do {
                    _ = try await directoryService.searchEmployees(query: "Engineering")
                    _ = try await directoryService.searchVendors(query: "Tech")
                } catch {
                    XCTFail("Failed to perform search: \(error)")
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateEmployeeWithDuplicateNumber() async throws {
        // Given
        let employee1 = createTestEmployee(employeeNumber: "EMP999")
        let employee2 = createTestEmployee(employeeNumber: "EMP999")
        
        _ = try await directoryService.createEmployee(employee1)
        
        // When/Then
        do {
            _ = try await directoryService.createEmployee(employee2)
            XCTFail("Expected error for duplicate employee number")
        } catch {
            XCTAssertTrue(error is DirectoryError)
        }
    }
    
    func testCreateVendorWithDuplicateNumber() async throws {
        // Given
        let vendor1 = createTestVendor(vendorNumber: "VEN999")
        let vendor2 = createTestVendor(vendorNumber: "VEN999")
        
        _ = try await directoryService.createVendor(vendor1)
        
        // When/Then
        do {
            _ = try await directoryService.createVendor(vendor2)
            XCTFail("Expected error for duplicate vendor number")
        } catch {
            XCTAssertTrue(error is DirectoryError)
        }
    }
    
    func testUpdateNonExistentEmployee() async throws {
        // Given
        let employee = createTestEmployee(employeeNumber: "EMP_NONEXISTENT")
        
        // When/Then
        do {
            _ = try await directoryService.updateEmployee(employee)
            XCTFail("Expected error for non-existent employee")
        } catch {
            XCTAssertTrue(error is DirectoryError)
        }
    }
    
    func testUpdateNonExistentVendor() async throws {
        // Given
        let vendor = createTestVendor(vendorNumber: "VEN_NONEXISTENT")
        
        // When/Then
        do {
            _ = try await directoryService.updateVendor(vendor)
            XCTFail("Expected error for non-existent vendor")
        } catch {
            XCTAssertTrue(error is DirectoryError)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestEmployee(
        employeeNumber: String = "EMP\(Int.random(in: 1000...9999))",
        firstName: String = "John",
        lastName: String = "Doe",
        email: String? = nil,
        department: String = "Engineering",
        title: String = "Software Engineer",
        isActive: Bool = true
    ) -> Employee {
        let actualEmail = email ?? "\(firstName.lowercased()).\(lastName.lowercased())@company.com"
        
        return Employee(
            employeeNumber: employeeNumber,
            firstName: firstName,
            lastName: lastName,
            email: actualEmail,
            department: department,
            title: title,
            hireDate: Date(),
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102"
            ),
            emergencyContact: EmergencyContact(
                name: "Emergency Contact",
                relationship: "Spouse",
                phone: "555-0123"
            ),
            workLocation: .office,
            employmentType: .fullTime,
            isActive: isActive
        )
    }
    
    private func createTestVendor(
        vendorNumber: String = "VEN\(Int.random(in: 1000...9999))",
        companyName: String = "Test Vendor Inc",
        contactPerson: String = "Contact Person",
        email: String? = nil,
        vendorType: VendorType = .supplier,
        isPreferred: Bool = false
    ) -> Vendor {
        let actualEmail = email ?? "contact@\(companyName.lowercased().replacingOccurrences(of: " ", with: "")).com"
        
        return Vendor(
            vendorNumber: vendorNumber,
            companyName: companyName,
            contactPerson: contactPerson,
            email: actualEmail,
            phone: "555-0123",
            address: Address(
                street: "456 Business Ave",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105"
            ),
            vendorType: vendorType,
            contractInfo: ContractInfo(
                contractNumber: "CNT\(Int.random(in: 1000...9999))",
                startDate: Date(),
                preferredPaymentMethod: .check
            ),
            paymentTerms: PaymentTerms(
                terms: .net30,
                preferredPaymentMethod: .check
            ),
            isPreferred: isPreferred
        )
    }
}

// MARK: - Mock Errors

enum DirectoryError: Error {
    case duplicateEmployeeNumber
    case duplicateVendorNumber
    case employeeNotFound
    case vendorNotFound
    case invalidData
    case networkError
}

extension DirectoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .duplicateEmployeeNumber:
            return "Employee with this number already exists"
        case .duplicateVendorNumber:
            return "Vendor with this number already exists"
        case .employeeNotFound:
            return "Employee not found"
        case .vendorNotFound:
            return "Vendor not found"
        case .invalidData:
            return "Invalid data provided"
        case .networkError:
            return "Network connection error"
        }
    }
}
#endif
