#if canImport(XCTest)
import XCTest
import Combine
@testable import DiamondDeskERP

@MainActor
final class DirectoryViewModelTests: XCTestCase {
    private var viewModel: DirectoryViewModel!
    private var mockDirectoryService: MockDirectoryService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        mockDirectoryService = MockDirectoryService()
        viewModel = DirectoryViewModel(directoryService: mockDirectoryService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        mockDirectoryService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.employees.isEmpty)
        XCTAssertTrue(viewModel.vendors.isEmpty)
        XCTAssertEqual(viewModel.selectedTab, .employees)
        XCTAssertEqual(viewModel.viewMode, .list)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertNil(viewModel.analytics)
    }
    
    // MARK: - Data Loading Tests
    
    func testLoadData() async throws {
        // Given
        let employees = createTestEmployees()
        let vendors = createTestVendors()
        mockDirectoryService.employeesToReturn = employees
        mockDirectoryService.vendorsToReturn = vendors
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertEqual(viewModel.employees.count, employees.count)
        XCTAssertEqual(viewModel.vendors.count, vendors.count)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockDirectoryService.fetchEmployeesCalled)
        XCTAssertTrue(mockDirectoryService.fetchVendorsCalled)
    }
    
    func testLoadDataWithError() async throws {
        // Given
        mockDirectoryService.shouldThrowError = true
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertTrue(viewModel.employees.isEmpty)
        XCTAssertTrue(viewModel.vendors.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
    
    func testRefreshData() async throws {
        // Given
        let initialEmployees = createTestEmployees(count: 2)
        let refreshedEmployees = createTestEmployees(count: 3)
        
        mockDirectoryService.employeesToReturn = initialEmployees
        await viewModel.loadData()
        
        XCTAssertEqual(viewModel.employees.count, 2)
        
        // When
        mockDirectoryService.employeesToReturn = refreshedEmployees
        await viewModel.refreshData()
        
        // Then
        XCTAssertEqual(viewModel.employees.count, 3)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchTextFiltering() async throws {
        // Given
        let employees = [
            createTestEmployee(firstName: "John", lastName: "Doe", department: "Engineering"),
            createTestEmployee(firstName: "Jane", lastName: "Smith", department: "Marketing"),
            createTestEmployee(firstName: "Bob", lastName: "Johnson", department: "Engineering")
        ]
        
        mockDirectoryService.employeesToReturn = employees
        await viewModel.loadData()
        
        // When
        viewModel.searchText = "John"
        
        // Then
        XCTAssertEqual(viewModel.filteredEmployees.count, 2) // John Doe and Bob Johnson
        XCTAssertTrue(viewModel.filteredEmployees.allSatisfy { employee in
            employee.firstName.localizedCaseInsensitiveContains("John") ||
            employee.lastName.localizedCaseInsensitiveContains("John") ||
            employee.department.localizedCaseInsensitiveContains("John")
        })
        
        // When
        viewModel.searchText = "Engineering"
        
        // Then
        XCTAssertEqual(viewModel.filteredEmployees.count, 2) // John Doe and Bob Johnson
        XCTAssertTrue(viewModel.filteredEmployees.allSatisfy { $0.department.contains("Engineering") })
    }
    
    func testVendorSearchTextFiltering() async throws {
        // Given
        let vendors = [
            createTestVendor(companyName: "Tech Solutions Inc", vendorType: .supplier),
            createTestVendor(companyName: "Office Supplies Co", vendorType: .supplier),
            createTestVendor(companyName: "Consulting Partners", vendorType: .consultant)
        ]
        
        mockDirectoryService.vendorsToReturn = vendors
        await viewModel.loadData()
        
        // When
        viewModel.searchText = "Tech"
        
        // Then
        XCTAssertEqual(viewModel.filteredVendors.count, 1)
        XCTAssertTrue(viewModel.filteredVendors.first?.companyName.contains("Tech") == true)
        
        // When
        viewModel.searchText = "Co"
        
        // Then
        XCTAssertEqual(viewModel.filteredVendors.count, 2) // Office Supplies Co and Consulting Partners
    }
    
    func testEmployeeFilterApplication() async throws {
        // Given
        let employees = [
            createTestEmployee(department: "Engineering", isActive: true, employmentType: .fullTime),
            createTestEmployee(department: "Marketing", isActive: true, employmentType: .partTime),
            createTestEmployee(department: "Engineering", isActive: false, employmentType: .fullTime),
            createTestEmployee(department: "Sales", isActive: true, employmentType: .contractor)
        ]
        
        mockDirectoryService.employeesToReturn = employees
        await viewModel.loadData()
        
        // When
        viewModel.employeeFilter = EmployeeFilter(
            departments: ["Engineering"],
            isActive: true,
            employmentTypes: [.fullTime],
            workLocations: nil
        )
        
        // Then
        XCTAssertEqual(viewModel.filteredEmployees.count, 1)
        XCTAssertTrue(viewModel.filteredEmployees.allSatisfy { employee in
            employee.department == "Engineering" &&
            employee.isActive &&
            employee.employmentType == .fullTime
        })
    }
    
    func testVendorFilterApplication() async throws {
        // Given
        let vendors = [
            createTestVendor(vendorType: .supplier, isPreferred: true),
            createTestVendor(vendorType: .consultant, isPreferred: false),
            createTestVendor(vendorType: .supplier, isPreferred: false),
            createTestVendor(vendorType: .contractor, isPreferred: true)
        ]
        
        mockDirectoryService.vendorsToReturn = vendors
        await viewModel.loadData()
        
        // When
        viewModel.vendorFilter = VendorFilter(
            vendorTypes: [.supplier],
            isPreferred: true,
            contractStatuses: nil,
            riskLevels: nil
        )
        
        // Then
        XCTAssertEqual(viewModel.filteredVendors.count, 1)
        XCTAssertTrue(viewModel.filteredVendors.allSatisfy { vendor in
            vendor.vendorType == .supplier && vendor.isPreferred
        })
    }
    
    // MARK: - Tab and View Mode Tests
    
    func testTabSelection() {
        // When
        viewModel.selectedTab = .vendors
        
        // Then
        XCTAssertEqual(viewModel.selectedTab, .vendors)
        
        // When
        viewModel.selectedTab = .analytics
        
        // Then
        XCTAssertEqual(viewModel.selectedTab, .analytics)
    }
    
    func testViewModeSelection() {
        // When
        viewModel.viewMode = .grid
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .grid)
        
        // When
        viewModel.viewMode = .orgChart
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .orgChart)
    }
    
    // MARK: - CRUD Operations Tests
    
    func testCreateEmployee() async throws {
        // Given
        let employee = createTestEmployee()
        mockDirectoryService.employeeToReturn = employee
        
        // When
        await viewModel.createEmployee(employee)
        
        // Then
        XCTAssertTrue(mockDirectoryService.createEmployeeCalled)
        XCTAssertTrue(viewModel.employees.contains { $0.employeeNumber == employee.employeeNumber })
        XCTAssertNil(viewModel.error)
    }
    
    func testCreateEmployeeWithError() async throws {
        // Given
        let employee = createTestEmployee()
        mockDirectoryService.shouldThrowError = true
        
        // When
        await viewModel.createEmployee(employee)
        
        // Then
        XCTAssertTrue(mockDirectoryService.createEmployeeCalled)
        XCTAssertFalse(viewModel.employees.contains { $0.employeeNumber == employee.employeeNumber })
        XCTAssertNotNil(viewModel.error)
    }
    
    func testUpdateEmployee() async throws {
        // Given
        let originalEmployee = createTestEmployee()
        mockDirectoryService.employeesToReturn = [originalEmployee]
        await viewModel.loadData()
        
        var updatedEmployee = originalEmployee
        updatedEmployee.title = "Senior Engineer"
        mockDirectoryService.employeeToReturn = updatedEmployee
        
        // When
        await viewModel.updateEmployee(updatedEmployee)
        
        // Then
        XCTAssertTrue(mockDirectoryService.updateEmployeeCalled)
        XCTAssertTrue(viewModel.employees.contains { $0.title == "Senior Engineer" })
        XCTAssertNil(viewModel.error)
    }
    
    func testDeleteEmployee() async throws {
        // Given
        let employee = createTestEmployee()
        mockDirectoryService.employeesToReturn = [employee]
        await viewModel.loadData()
        
        // When
        await viewModel.deleteEmployee(employee)
        
        // Then
        XCTAssertTrue(mockDirectoryService.deleteEmployeeCalled)
        XCTAssertFalse(viewModel.employees.contains { $0.employeeNumber == employee.employeeNumber })
        XCTAssertNil(viewModel.error)
    }
    
    func testCreateVendor() async throws {
        // Given
        let vendor = createTestVendor()
        mockDirectoryService.vendorToReturn = vendor
        
        // When
        await viewModel.createVendor(vendor)
        
        // Then
        XCTAssertTrue(mockDirectoryService.createVendorCalled)
        XCTAssertTrue(viewModel.vendors.contains { $0.vendorNumber == vendor.vendorNumber })
        XCTAssertNil(viewModel.error)
    }
    
    func testUpdateVendor() async throws {
        // Given
        let originalVendor = createTestVendor()
        mockDirectoryService.vendorsToReturn = [originalVendor]
        await viewModel.loadData()
        
        var updatedVendor = originalVendor
        updatedVendor.isPreferred = true
        mockDirectoryService.vendorToReturn = updatedVendor
        
        // When
        await viewModel.updateVendor(updatedVendor)
        
        // Then
        XCTAssertTrue(mockDirectoryService.updateVendorCalled)
        XCTAssertTrue(viewModel.vendors.contains { $0.isPreferred })
        XCTAssertNil(viewModel.error)
    }
    
    func testDeleteVendor() async throws {
        // Given
        let vendor = createTestVendor()
        mockDirectoryService.vendorsToReturn = [vendor]
        await viewModel.loadData()
        
        // When
        await viewModel.deleteVendor(vendor)
        
        // Then
        XCTAssertTrue(mockDirectoryService.deleteVendorCalled)
        XCTAssertFalse(viewModel.vendors.contains { $0.vendorNumber == vendor.vendorNumber })
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Analytics Tests
    
    func testLoadAnalytics() async throws {
        // Given
        let analytics = createTestAnalytics()
        mockDirectoryService.analyticsToReturn = analytics
        
        // When
        await viewModel.loadAnalytics()
        
        // Then
        XCTAssertTrue(mockDirectoryService.generateAnalyticsCalled)
        XCTAssertNotNil(viewModel.analytics)
        XCTAssertEqual(viewModel.analytics?.totalEmployees, analytics.totalEmployees)
        XCTAssertEqual(viewModel.analytics?.totalVendors, analytics.totalVendors)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadAnalyticsWithError() async throws {
        // Given
        mockDirectoryService.shouldThrowError = true
        
        // When
        await viewModel.loadAnalytics()
        
        // Then
        XCTAssertTrue(mockDirectoryService.generateAnalyticsCalled)
        XCTAssertNil(viewModel.analytics)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Selection Tests
    
    func testSelectEmployee() {
        // Given
        let employee = createTestEmployee()
        
        // When
        viewModel.selectEmployee(employee)
        
        // Then
        XCTAssertEqual(viewModel.selectedEmployee, employee)
    }
    
    func testSelectVendor() {
        // Given
        let vendor = createTestVendor()
        
        // When
        viewModel.selectVendor(vendor)
        
        // Then
        XCTAssertEqual(viewModel.selectedVendor, vendor)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        viewModel.error = DirectoryError.networkError
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Reactive Tests
    
    func testSearchTextDebouncing() async throws {
        // Given
        let employees = createTestEmployees(count: 10)
        mockDirectoryService.employeesToReturn = employees
        await viewModel.loadData()
        
        let expectation = XCTestExpectation(description: "Search debouncing")
        var filteredCount: Int?
        
        viewModel.$filteredEmployees
            .dropFirst() // Skip initial empty state
            .sink { employees in
                filteredCount = employees.count
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.searchText = "test"
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(filteredCount)
    }
    
    func testLoadingStateChanges() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 3 { // Initial false, true when loading, false when done
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadData()
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() async throws {
        // Given
        let employees = createTestEmployees(count: 5)
        let vendors = createTestVendors(count: 3)
        
        mockDirectoryService.employeesToReturn = employees
        mockDirectoryService.vendorsToReturn = vendors
        
        // When - Load initial data
        await viewModel.loadData()
        
        // Then
        XCTAssertEqual(viewModel.employees.count, 5)
        XCTAssertEqual(viewModel.vendors.count, 3)
        
        // When - Search employees
        viewModel.searchText = "Employee"
        
        // Then
        XCTAssertGreaterThan(viewModel.filteredEmployees.count, 0)
        
        // When - Switch to vendors tab
        viewModel.selectedTab = .vendors
        
        // Then
        XCTAssertEqual(viewModel.selectedTab, .vendors)
        
        // When - Apply vendor filter
        viewModel.vendorFilter = VendorFilter(
            vendorTypes: [.supplier],
            isPreferred: nil,
            contractStatuses: nil,
            riskLevels: nil
        )
        
        // Then
        XCTAssertTrue(viewModel.filteredVendors.allSatisfy { $0.vendorType == .supplier })
        
        // When - Load analytics
        mockDirectoryService.analyticsToReturn = createTestAnalytics()
        await viewModel.loadAnalytics()
        
        // Then
        XCTAssertNotNil(viewModel.analytics)
    }
    
    // MARK: - Helper Methods
    
    private func createTestEmployees(count: Int = 3) -> [Employee] {
        return (1...count).map { index in
            createTestEmployee(
                employeeNumber: "EMP\(String(format: "%03d", index))",
                firstName: "Employee\(index)",
                lastName: "Test\(index)"
            )
        }
    }
    
    private func createTestVendors(count: Int = 3) -> [Vendor] {
        return (1...count).map { index in
            createTestVendor(
                vendorNumber: "VEN\(String(format: "%03d", index))",
                companyName: "Vendor\(index) Inc"
            )
        }
    }
    
    private func createTestEmployee(
        employeeNumber: String = "EMP001",
        firstName: String = "John",
        lastName: String = "Doe",
        department: String = "Engineering",
        isActive: Bool = true,
        employmentType: EmploymentType = .fullTime
    ) -> Employee {
        return Employee(
            employeeNumber: employeeNumber,
            firstName: firstName,
            lastName: lastName,
            email: "\(firstName.lowercased()).\(lastName.lowercased())@company.com",
            department: department,
            title: "Software Engineer",
            hireDate: Date(),
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102"),
            emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Spouse", phone: "555-0123"),
            workLocation: .office,
            employmentType: employmentType,
            isActive: isActive
        )
    }
    
    private func createTestVendor(
        vendorNumber: String = "VEN001",
        companyName: String = "Test Vendor Inc",
        vendorType: VendorType = .supplier,
        isPreferred: Bool = false
    ) -> Vendor {
        return Vendor(
            vendorNumber: vendorNumber,
            companyName: companyName,
            contactPerson: "Contact Person",
            email: "contact@vendor.com",
            phone: "555-0123",
            address: Address(street: "456 Business Ave", city: "San Francisco", state: "CA", zipCode: "94105"),
            vendorType: vendorType,
            contractInfo: ContractInfo(
                contractNumber: "CNT001",
                startDate: Date(),
                preferredPaymentMethod: .check
            ),
            paymentTerms: PaymentTerms(terms: .net30, preferredPaymentMethod: .check),
            isPreferred: isPreferred
        )
    }
    
    private func createTestAnalytics() -> DirectoryAnalytics {
        return DirectoryAnalytics(
            totalEmployees: 100,
            activeEmployees: 95,
            totalVendors: 50,
            activeVendors: 48,
            preferredVendors: 25,
            departmentBreakdown: [
                "Engineering": 30,
                "Marketing": 15,
                "Sales": 20,
                "Operations": 20,
                "Administration": 10
            ],
            vendorTypeBreakdown: [
                "Supplier": 30,
                "Consultant": 15,
                "Contractor": 5
            ]
        )
    }
}

// MARK: - Mock Directory Service

final class MockDirectoryService: DirectoryServiceProtocol {
    // MARK: - Properties
    var employeesToReturn: [Employee] = []
    var vendorsToReturn: [Vendor] = []
    var employeeToReturn: Employee?
    var vendorToReturn: Vendor?
    var analyticsToReturn: DirectoryAnalytics?
    var shouldThrowError = false
    
    // MARK: - Call Tracking
    var fetchEmployeesCalled = false
    var fetchVendorsCalled = false
    var createEmployeeCalled = false
    var updateEmployeeCalled = false
    var deleteEmployeeCalled = false
    var createVendorCalled = false
    var updateVendorCalled = false
    var deleteVendorCalled = false
    var generateAnalyticsCalled = false
    var searchEmployeesCalled = false
    var searchVendorsCalled = false
    var filterEmployeesCalled = false
    var filterVendorsCalled = false
    
    // MARK: - Employee Methods
    func fetchEmployees() async throws -> [Employee] {
        fetchEmployeesCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return employeesToReturn
    }
    
    func createEmployee(_ employee: Employee) async throws -> Employee {
        createEmployeeCalled = true
        if shouldThrowError {
            throw DirectoryError.invalidData
        }
        employeesToReturn.append(employee)
        return employeeToReturn ?? employee
    }
    
    func updateEmployee(_ employee: Employee) async throws -> Employee {
        updateEmployeeCalled = true
        if shouldThrowError {
            throw DirectoryError.employeeNotFound
        }
        if let index = employeesToReturn.firstIndex(where: { $0.employeeNumber == employee.employeeNumber }) {
            employeesToReturn[index] = employee
        }
        return employeeToReturn ?? employee
    }
    
    func deleteEmployee(_ employee: Employee) async throws {
        deleteEmployeeCalled = true
        if shouldThrowError {
            throw DirectoryError.employeeNotFound
        }
        employeesToReturn.removeAll { $0.employeeNumber == employee.employeeNumber }
    }
    
    func searchEmployees(query: String) async throws -> [Employee] {
        searchEmployeesCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return employeesToReturn.filter { employee in
            employee.firstName.localizedCaseInsensitiveContains(query) ||
            employee.lastName.localizedCaseInsensitiveContains(query) ||
            employee.department.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterEmployees(filter: EmployeeFilter) async throws -> [Employee] {
        filterEmployeesCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return employeesToReturn.filter { employee in
            var matches = true
            
            if let departments = filter.departments, !departments.isEmpty {
                matches = matches && departments.contains(employee.department)
            }
            
            if let isActive = filter.isActive {
                matches = matches && (employee.isActive == isActive)
            }
            
            if let employmentTypes = filter.employmentTypes, !employmentTypes.isEmpty {
                matches = matches && employmentTypes.contains(employee.employmentType)
            }
            
            return matches
        }
    }
    
    func bulkImportEmployees(_ employees: [Employee]) async throws -> [Employee] {
        if shouldThrowError {
            throw DirectoryError.invalidData
        }
        employeesToReturn.append(contentsOf: employees)
        return employees
    }
    
    // MARK: - Vendor Methods
    func fetchVendors() async throws -> [Vendor] {
        fetchVendorsCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return vendorsToReturn
    }
    
    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        createVendorCalled = true
        if shouldThrowError {
            throw DirectoryError.invalidData
        }
        vendorsToReturn.append(vendor)
        return vendorToReturn ?? vendor
    }
    
    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        updateVendorCalled = true
        if shouldThrowError {
            throw DirectoryError.vendorNotFound
        }
        if let index = vendorsToReturn.firstIndex(where: { $0.vendorNumber == vendor.vendorNumber }) {
            vendorsToReturn[index] = vendor
        }
        return vendorToReturn ?? vendor
    }
    
    func deleteVendor(_ vendor: Vendor) async throws {
        deleteVendorCalled = true
        if shouldThrowError {
            throw DirectoryError.vendorNotFound
        }
        vendorsToReturn.removeAll { $0.vendorNumber == vendor.vendorNumber }
    }
    
    func searchVendors(query: String) async throws -> [Vendor] {
        searchVendorsCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return vendorsToReturn.filter { vendor in
            vendor.companyName.localizedCaseInsensitiveContains(query) ||
            vendor.contactPerson.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterVendors(filter: VendorFilter) async throws -> [Vendor] {
        filterVendorsCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return vendorsToReturn.filter { vendor in
            var matches = true
            
            if let vendorTypes = filter.vendorTypes, !vendorTypes.isEmpty {
                matches = matches && vendorTypes.contains(vendor.vendorType)
            }
            
            if let isPreferred = filter.isPreferred {
                matches = matches && (vendor.isPreferred == isPreferred)
            }
            
            return matches
        }
    }
    
    func bulkImportVendors(_ vendors: [Vendor]) async throws -> [Vendor] {
        if shouldThrowError {
            throw DirectoryError.invalidData
        }
        vendorsToReturn.append(contentsOf: vendors)
        return vendors
    }
    
    // MARK: - Analytics Methods
    func generateAnalytics() async throws -> DirectoryAnalytics {
        generateAnalyticsCalled = true
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return analyticsToReturn ?? DirectoryAnalytics(
            totalEmployees: employeesToReturn.count,
            activeEmployees: employeesToReturn.filter { $0.isActive }.count,
            totalVendors: vendorsToReturn.count,
            activeVendors: vendorsToReturn.count,
            preferredVendors: vendorsToReturn.filter { $0.isPreferred }.count,
            departmentBreakdown: [:],
            vendorTypeBreakdown: [:]
        )
    }
    
    // MARK: - Organization Chart Methods
    func buildOrganizationChart() async throws -> OrganizationChart {
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return OrganizationChart(rootEmployee: nil, departments: [])
    }
    
    // MARK: - Export Methods
    func exportEmployeesToCSV() async throws -> URL {
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return URL(fileURLWithPath: "/tmp/employees.csv")
    }
    
    func exportVendorsToCSV() async throws -> URL {
        if shouldThrowError {
            throw DirectoryError.networkError
        }
        return URL(fileURLWithPath: "/tmp/vendors.csv")
    }
}

// MARK: - Directory Service Protocol

protocol DirectoryServiceProtocol {
    func fetchEmployees() async throws -> [Employee]
    func createEmployee(_ employee: Employee) async throws -> Employee
    func updateEmployee(_ employee: Employee) async throws -> Employee
    func deleteEmployee(_ employee: Employee) async throws
    func searchEmployees(query: String) async throws -> [Employee]
    func filterEmployees(filter: EmployeeFilter) async throws -> [Employee]
    func bulkImportEmployees(_ employees: [Employee]) async throws -> [Employee]
    
    func fetchVendors() async throws -> [Vendor]
    func createVendor(_ vendor: Vendor) async throws -> Vendor
    func updateVendor(_ vendor: Vendor) async throws -> Vendor
    func deleteVendor(_ vendor: Vendor) async throws
    func searchVendors(query: String) async throws -> [Vendor]
    func filterVendors(filter: VendorFilter) async throws -> [Vendor]
    func bulkImportVendors(_ vendors: [Vendor]) async throws -> [Vendor]
    
    func generateAnalytics() async throws -> DirectoryAnalytics
    func buildOrganizationChart() async throws -> OrganizationChart
    func exportEmployeesToCSV() async throws -> URL
    func exportVendorsToCSV() async throws -> URL
}
#endif
