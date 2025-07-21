import SwiftUI
import Combine
import CloudKit

/// Employee Management View Model
/// Handles employee data operations, search, filtering, and UI state management
@MainActor
final class EmployeeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var employees: [Employee] = []
    @Published var filteredEmployees: [Employee] = []
    @Published var selectedEmployee: Employee?
    @Published var isLoading = false
    @Published var error: EmployeeServiceError?
    @Published var showingError = false
    
    // MARK: - Search and Filter Properties
    
    @Published var searchText = ""
    @Published var selectedDepartment: String?
    @Published var selectedRole: EmployeeRole?
    @Published var selectedStatus: EmployeeStatus = .active
    @Published var sortOrder: EmployeeSortOrder = .lastNameAsc
    @Published var showingInactive = false
    
    // MARK: - UI State Properties
    
    @Published var showingCreateEmployee = false
    @Published var showingEmployeeDetail = false
    @Published var showingEditEmployee = false
    @Published var showingDeleteConfirmation = false
    @Published var showingFilters = false
    @Published var viewMode: EmployeeViewMode = .list
    
    // MARK: - Analytics Properties
    
    @Published var employeeStats: EmployeeStatistics?
    @Published var departmentBreakdown: [DepartmentStats] = []
    @Published var recentHires: [Employee] = []
    @Published var upcomingReviews: [Employee] = []
    @Published var birthdayReminders: [Employee] = []
    
    // MARK: - Form Properties
    
    @Published var newEmployee = EmployeeFormData()
    @Published var editingEmployee = EmployeeFormData()
    
    // MARK: - Performance Properties
    
    @Published var performanceMetrics: [String: PerformanceMetrics] = [:]
    @Published var showingPerformanceDetail = false
    
    // MARK: - Private Properties
    
    private let employeeService: EmployeeService
    private var cancellables = Set<AnyCancellable>()
    private let searchDebouncer = PassthroughSubject<String, Never>()
    
    // MARK: - Computed Properties
    
    var departments: [String] {
        Array(Set(employees.map { $0.department })).sorted()
    }
    
    var activeEmployeeCount: Int {
        employees.filter { $0.isActive }.count
    }
    
    var totalEmployeeCount: Int {
        employees.count
    }
    
    var averageTenure: Double {
        let tenures = employees.compactMap { employee in
            Calendar.current.dateComponents([.day], from: employee.hireDate, to: Date()).day
        }
        guard !tenures.isEmpty else { return 0 }
        return Double(tenures.reduce(0, +)) / Double(tenures.count) / 365.25
    }
    
    // MARK: - Initialization
    
    init(employeeService: EmployeeService = EmployeeService()) {
        self.employeeService = employeeService
        setupBindings()
        setupSearchDebouncing()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Bind search text changes to filtering
        $searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.searchDebouncer.send(searchText)
            }
            .store(in: &cancellables)
        
        // Bind filter changes to update filtered results
        Publishers.CombineLatest4($employees, $selectedDepartment, $selectedRole, $selectedStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.updateFilteredEmployees()
            }
            .store(in: &cancellables)
        
        // Bind sort order changes
        $sortOrder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFilteredEmployees()
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchDebouncing() {
        searchDebouncer
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.performSearch(query: searchText)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Employee Operations
    
    func loadEmployees() async {
        isLoading = true
        error = nil
        
        do {
            try await employeeService.fetchEmployees()
            employees = employeeService.employees
            await loadAnalytics()
            updateFilteredEmployees()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
            showingError = true
        }
        
        isLoading = false
    }
    
    func createEmployee() async {
        isLoading = true
        error = nil
        
        do {
            let employee = newEmployee.toEmployee()
            try await employeeService.createEmployee(employee)
            employees = employeeService.employees
            newEmployee = EmployeeFormData()
            showingCreateEmployee = false
            updateFilteredEmployees()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
            showingError = true
        }
        
        isLoading = false
    }
    
    func updateEmployee(_ employee: Employee) async {
        isLoading = true
        error = nil
        
        do {
            try await employeeService.updateEmployee(employee)
            employees = employeeService.employees
            updateFilteredEmployees()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
            showingError = true
        }
        
        isLoading = false
    }
    
    func deleteEmployee(_ employee: Employee) async {
        isLoading = true
        error = nil
        
        do {
            try await employeeService.deleteEmployee(id: employee.id)
            employees = employeeService.employees
            updateFilteredEmployees()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
            showingError = true
        }
        
        isLoading = false
    }
    
    func deactivateEmployee(_ employee: Employee) async {
        isLoading = true
        error = nil
        
        do {
            try await employeeService.deactivateEmployee(id: employee.id)
            employees = employeeService.employees
            updateFilteredEmployees()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
            showingError = true
        }
        
        isLoading = false
    }
    
    func reactivateEmployee(_ employee: Employee) async {
        isLoading = true
        error = nil
        
        do {
            try await employeeService.reactivateEmployee(id: employee.id)
            employees = employeeService.employees
            updateFilteredEmployees()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
            showingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Search and Filter Methods
    
    private func performSearch(query: String) {
        updateFilteredEmployees()
    }
    
    private func updateFilteredEmployees() {
        var filtered = employees
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { employee in
                employee.firstName.localizedCaseInsensitiveContains(searchText) ||
                employee.lastName.localizedCaseInsensitiveContains(searchText) ||
                employee.email.localizedCaseInsensitiveContains(searchText) ||
                employee.employeeNumber.localizedCaseInsensitiveContains(searchText) ||
                employee.department.localizedCaseInsensitiveContains(searchText) ||
                employee.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply department filter
        if let selectedDepartment = selectedDepartment {
            filtered = filtered.filter { $0.department == selectedDepartment }
        }
        
        // Apply role filter
        if let selectedRole = selectedRole {
            filtered = filtered.filter { $0.roles.contains(selectedRole) }
        }
        
        // Apply status filter
        switch selectedStatus {
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .inactive:
            filtered = filtered.filter { !$0.isActive }
        case .all:
            break
        }
        
        // Apply sorting
        filtered = applySorting(to: filtered)
        
        filteredEmployees = filtered
    }
    
    private func applySorting(to employees: [Employee]) -> [Employee] {
        switch sortOrder {
        case .firstNameAsc:
            return employees.sorted { $0.firstName < $1.firstName }
        case .firstNameDesc:
            return employees.sorted { $0.firstName > $1.firstName }
        case .lastNameAsc:
            return employees.sorted { $0.lastName < $1.lastName }
        case .lastNameDesc:
            return employees.sorted { $0.lastName > $1.lastName }
        case .hireDateAsc:
            return employees.sorted { $0.hireDate < $1.hireDate }
        case .hireDateDesc:
            return employees.sorted { $0.hireDate > $1.hireDate }
        case .departmentAsc:
            return employees.sorted { $0.department < $1.department }
        case .departmentDesc:
            return employees.sorted { $0.department > $1.department }
        }
    }
    
    // MARK: - Analytics Methods
    
    func loadAnalytics() async {
        do {
            employeeStats = try await employeeService.getEmployeeStatistics()
            departmentBreakdown = try await employeeService.getDepartmentStatistics()
            recentHires = getRecentHires()
            upcomingReviews = getUpcomingReviews()
            birthdayReminders = try await employeeService.getBirthdayReminders()
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
        }
    }
    
    private func getRecentHires() -> [Employee] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return employees
            .filter { $0.hireDate >= thirtyDaysAgo }
            .sorted { $0.hireDate > $1.hireDate }
            .prefix(10)
            .map { $0 }
    }
    
    private func getUpcomingReviews() -> [Employee] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return employees
            .filter { employee in
                if let nextReviewDate = employee.nextReviewDate {
                    return nextReviewDate <= thirtyDaysFromNow && nextReviewDate >= Date()
                }
                return false
            }
            .sorted { $0.nextReviewDate ?? Date.distantFuture < $1.nextReviewDate ?? Date.distantFuture }
    }
    
    func loadPerformanceMetrics(for employee: Employee) async {
        do {
            let metrics = try await employeeService.calculatePerformanceMetrics(employeeId: employee.id)
            performanceMetrics[employee.id] = metrics
        } catch {
            self.error = error as? EmployeeServiceError ?? .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - UI Action Methods
    
    func selectEmployee(_ employee: Employee) {
        selectedEmployee = employee
        editingEmployee = EmployeeFormData(from: employee)
    }
    
    func clearSelection() {
        selectedEmployee = nil
        editingEmployee = EmployeeFormData()
    }
    
    func clearFilters() {
        searchText = ""
        selectedDepartment = nil
        selectedRole = nil
        selectedStatus = .active
        sortOrder = .lastNameAsc
    }
    
    func clearError() {
        error = nil
        showingError = false
    }
    
    func refreshData() async {
        await loadEmployees()
    }
    
    // MARK: - Organization Chart Methods
    
    func getDirectReports(for manager: Employee) -> [Employee] {
        return employees.filter { $0.manager == manager.id }
    }
    
    func getManagerChain(for employee: Employee) -> [Employee] {
        var chain: [Employee] = []
        var currentEmployee = employee
        
        while let managerId = currentEmployee.manager,
              let manager = employees.first(where: { $0.id == managerId }) {
            chain.append(manager)
            currentEmployee = manager
        }
        
        return chain
    }
    
    func getAllSubordinates(for manager: Employee) -> [Employee] {
        var subordinates: [Employee] = []
        let directReports = getDirectReports(for: manager)
        
        subordinates.append(contentsOf: directReports)
        
        for report in directReports {
            subordinates.append(contentsOf: getAllSubordinates(for: report))
        }
        
        return subordinates
    }
}

// MARK: - Supporting Types

enum EmployeeViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
    case table = "Table"
    
    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        case .table: return "tablecells"
        }
    }
}

enum EmployeeSortOrder: String, CaseIterable {
    case firstNameAsc = "First Name ↑"
    case firstNameDesc = "First Name ↓"
    case lastNameAsc = "Last Name ↑"
    case lastNameDesc = "Last Name ↓"
    case hireDateAsc = "Hire Date ↑"
    case hireDateDesc = "Hire Date ↓"
    case departmentAsc = "Department ↑"
    case departmentDesc = "Department ↓"
}

enum EmployeeStatus: String, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case all = "All"
}

enum EmployeeRole: String, CaseIterable, Codable {
    case admin = "Admin"
    case manager = "Manager"
    case employee = "Employee"
    case contractor = "Contractor"
    case intern = "Intern"
    
    var displayName: String {
        return rawValue
    }
}

struct EmployeeFormData {
    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var employeeNumber = ""
    var department = ""
    var title = ""
    var manager: String?
    var hireDate = Date()
    var birthDate: Date?
    var workLocation: WorkLocation = .office
    var employmentType: EmploymentType = .fullTime
    var skills: [String] = []
    var salaryGrade = ""
    var isActive = true
    
    // Address
    var street = ""
    var city = ""
    var state = ""
    var zipCode = ""
    var country = "US"
    
    // Emergency Contact
    var emergencyName = ""
    var emergencyRelationship = ""
    var emergencyPhone = ""
    var emergencyEmail = ""
    
    init() {}
    
    init(from employee: Employee) {
        self.firstName = employee.firstName
        self.lastName = employee.lastName
        self.email = employee.email
        self.phone = employee.phone ?? ""
        self.employeeNumber = employee.employeeNumber
        self.department = employee.department
        self.title = employee.title
        self.manager = employee.manager
        self.hireDate = employee.hireDate
        self.birthDate = employee.birthDate
        self.workLocation = employee.workLocation
        self.employmentType = employee.employmentType
        self.skills = employee.skills
        self.salaryGrade = employee.salaryGrade ?? ""
        self.isActive = employee.isActive
        
        // Address
        self.street = employee.address.street
        self.city = employee.address.city
        self.state = employee.address.state
        self.zipCode = employee.address.zipCode
        self.country = employee.address.country
        
        // Emergency Contact
        self.emergencyName = employee.emergencyContact.name
        self.emergencyRelationship = employee.emergencyContact.relationship
        self.emergencyPhone = employee.emergencyContact.phone
        self.emergencyEmail = employee.emergencyContact.email ?? ""
    }
    
    func toEmployee() -> Employee {
        let address = Address(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country
        )
        
        let emergencyContact = EmergencyContact(
            name: emergencyName,
            relationship: emergencyRelationship,
            phone: emergencyPhone,
            email: emergencyEmail.isEmpty ? nil : emergencyEmail
        )
        
        return Employee(
            employeeNumber: employeeNumber,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            department: department,
            title: title,
            manager: manager,
            hireDate: hireDate,
            birthDate: birthDate,
            address: address,
            emergencyContact: emergencyContact,
            skills: skills,
            workLocation: workLocation,
            employmentType: employmentType,
            salaryGrade: salaryGrade.isEmpty ? nil : salaryGrade,
            isActive: isActive
        )
    }
}

struct EmployeeStatistics {
    let totalEmployees: Int
    let activeEmployees: Int
    let inactiveEmployees: Int
    let departmentCounts: [String: Int]
    let averageTenure: Double
    let newHiresThisMonth: Int
    let upcomingReviews: Int
    let birthdaysThisWeek: Int
}

struct DepartmentStats {
    let department: String
    let totalEmployees: Int
    let activeEmployees: Int
    let averageTenure: TimeInterval
    let averagePerformanceScore: Double
}

enum EmployeeServiceError: LocalizedError {
    case employeeNotFound
    case validationError(String)
    case duplicateEmployeeNumber
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .employeeNotFound:
            return "Employee not found"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .duplicateEmployeeNumber:
            return "Employee number already exists"
        case .networkError:
            return "Network error occurred"
        case .unknown(let message):
            return message
        }
    }
}
