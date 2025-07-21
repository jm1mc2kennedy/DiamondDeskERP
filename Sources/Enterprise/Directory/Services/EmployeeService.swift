import Foundation
import CloudKit
import Combine

// MARK: - Employee Service Protocol
public protocol EmployeeServiceProtocol {
    func fetchEmployees() async throws -> [Employee]
    func fetchEmployee(by id: String) async throws -> Employee?
    func fetchEmployeeByNumber(_ employeeNumber: String) async throws -> Employee?
    func fetchEmployeeByEmail(_ email: String) async throws -> Employee?
    func fetchEmployeesByDepartment(_ department: String) async throws -> [Employee]
    func fetchEmployeesByManager(_ managerId: String) async throws -> [Employee]
    func fetchEmployeesByRole(_ role: UserRole) async throws -> [Employee]
    func fetchEmployeesByStore(_ storeCode: String) async throws -> [Employee]
    func fetchActiveEmployees() async throws -> [Employee]
    func createEmployee(_ employee: Employee) async throws -> Employee
    func updateEmployee(_ employee: Employee) async throws -> Employee
    func deleteEmployee(id: String) async throws
    func deactivateEmployee(id: String) async throws -> Employee
    func reactivateEmployee(id: String) async throws -> Employee
    func updateEmployeeRole(id: String, role: UserRole) async throws -> Employee
    func addDirectReport(managerId: String, employeeId: String) async throws -> Employee
    func removeDirectReport(managerId: String, employeeId: String) async throws -> Employee
    func searchEmployees(query: String) async throws -> [Employee]
    func fetchVendors() async throws -> [Vendor]
    func createVendor(_ vendor: Vendor) async throws -> Vendor
    func updateVendor(_ vendor: Vendor) async throws -> Vendor
}

// MARK: - Employee Service Implementation
@MainActor
public final class EmployeeService: ObservableObject, EmployeeServiceProtocol {
    
    // MARK: - Published Properties
    @Published public private(set) var employees: [Employee] = []
    @Published public private(set) var activeEmployees: [Employee] = []
    @Published public private(set) var managers: [Employee] = []
    @Published public private(set) var vendors: [Vendor] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum RecordType {
        static let employee = "Employee"
        static let vendor = "Vendor"
        static let certification = "Certification"
        static let performanceReview = "PerformanceReview"
    }
    
    // MARK: - Initialization
    public init(container: CKContainer = CKContainer.default) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    public func fetchEmployees() async throws -> [Employee] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let query = CKQuery(recordType: RecordType.employee, predicate: NSPredicate(value: true))
            query.sortDescriptors = [
                NSSortDescriptor(key: "lastName", ascending: true),
                NSSortDescriptor(key: "firstName", ascending: true)
            ]
            
            let (records, _) = try await privateDatabase.records(matching: query)
            let employees = records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Employee.from(record: record)
                case .failure:
                    return nil
                }
            }
            
            self.employees = employees
            self.activeEmployees = employees.filter { $0.isActive }
            self.managers = employees.filter { !$0.directReports.isEmpty }
            
            return employees
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func fetchEmployee(by id: String) async throws -> Employee? {
        do {
            let recordID = CKRecord.ID(recordName: id)
            let record = try await privateDatabase.record(for: recordID)
            
            if let employee = Employee.from(record: record) {
                // Update last access time
                var updatedEmployee = employee
                updatedEmployee.lastLoginAt = Date()
                _ = try? await updateEmployee(updatedEmployee)
                
                return updatedEmployee
            }
            return nil
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil
            }
            throw error
        }
    }
    
    public func fetchEmployeeByNumber(_ employeeNumber: String) async throws -> Employee? {
        let predicate = NSPredicate(format: "employeeNumber == %@", employeeNumber)
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }.first
    }
    
    public func fetchEmployeeByEmail(_ email: String) async throws -> Employee? {
        let predicate = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }.first
    }
    
    public func fetchEmployeesByDepartment(_ department: String) async throws -> [Employee] {
        let predicate = NSPredicate(format: "department == %@", department)
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchEmployeesByManager(_ managerId: String) async throws -> [Employee] {
        let predicate = NSPredicate(format: "managerId == %@", managerId)
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchEmployeesByRole(_ role: UserRole) async throws -> [Employee] {
        let predicate = NSPredicate(format: "userRole == %@", role.rawValue)
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchEmployeesByStore(_ storeCode: String) async throws -> [Employee] {
        let predicate = NSPredicate(format: "ANY storeCodes == %@", storeCode)
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchActiveEmployees() async throws -> [Employee] {
        let predicate = NSPredicate(format: "isActive == YES")
        let query = CKQuery(recordType: RecordType.employee, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        let employees = records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }
        
        self.activeEmployees = employees
        return employees
    }
    
    public func createEmployee(_ employee: Employee) async throws -> Employee {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // Validate unique constraints
            if let existingByNumber = try await fetchEmployeeByNumber(employee.employeeNumber) {
                throw EmployeeServiceError.employeeNumberExists(existingByNumber.employeeNumber)
            }
            
            if let existingByEmail = try await fetchEmployeeByEmail(employee.email) {
                throw EmployeeServiceError.emailExists(existingByEmail.email)
            }
            
            let record = employee.toCKRecord()
            let savedRecord = try await privateDatabase.save(record)
            
            if let savedEmployee = Employee.from(record: savedRecord) {
                employees.append(savedEmployee)
                employees.sort { $0.lastName < $1.lastName }
                
                if savedEmployee.isActive {
                    activeEmployees.append(savedEmployee)
                    activeEmployees.sort { $0.lastName < $1.lastName }
                }
                
                if !savedEmployee.directReports.isEmpty {
                    managers.append(savedEmployee)
                    managers.sort { $0.lastName < $1.lastName }
                }
                
                return savedEmployee
            }
            
            throw EmployeeServiceError.invalidEmployeeData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func updateEmployee(_ employee: Employee) async throws -> Employee {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            var updatedEmployee = employee
            updatedEmployee.modifiedAt = Date()
            
            let record = updatedEmployee.toCKRecord()
            let savedRecord = try await privateDatabase.save(record)
            
            if let savedEmployee = Employee.from(record: savedRecord) {
                if let index = employees.firstIndex(where: { $0.id == employee.id }) {
                    employees[index] = savedEmployee
                }
                
                // Update active employees
                activeEmployees.removeAll { $0.id == employee.id }
                if savedEmployee.isActive {
                    activeEmployees.append(savedEmployee)
                    activeEmployees.sort { $0.lastName < $1.lastName }
                }
                
                // Update managers
                managers.removeAll { $0.id == employee.id }
                if !savedEmployee.directReports.isEmpty {
                    managers.append(savedEmployee)
                    managers.sort { $0.lastName < $1.lastName }
                }
                
                return savedEmployee
            }
            
            throw EmployeeServiceError.invalidEmployeeData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func deleteEmployee(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // Check if employee has direct reports
            if let employee = try await fetchEmployee(by: id), !employee.directReports.isEmpty {
                throw EmployeeServiceError.hasDirectReports
            }
            
            let recordID = CKRecord.ID(recordName: id)
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            
            employees.removeAll { $0.id == id }
            activeEmployees.removeAll { $0.id == id }
            managers.removeAll { $0.id == id }
            
            // Remove from any manager's direct reports
            for employee in employees where employee.directReports.contains(id) {
                var updatedEmployee = employee
                updatedEmployee.directReports.removeAll { $0 == id }
                _ = try? await updateEmployee(updatedEmployee)
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func deactivateEmployee(id: String) async throws -> Employee {
        guard let employee = try await fetchEmployee(by: id) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        var updatedEmployee = employee
        updatedEmployee.isActive = false
        
        return try await updateEmployee(updatedEmployee)
    }
    
    public func reactivateEmployee(id: String) async throws -> Employee {
        guard let employee = try await fetchEmployee(by: id) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        var updatedEmployee = employee
        updatedEmployee.isActive = true
        
        return try await updateEmployee(updatedEmployee)
    }
    
    public func updateEmployeeRole(id: String, role: UserRole) async throws -> Employee {
        guard let employee = try await fetchEmployee(by: id) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        var updatedEmployee = employee
        updatedEmployee.userRole = role
        
        return try await updateEmployee(updatedEmployee)
    }
    
    public func addDirectReport(managerId: String, employeeId: String) async throws -> Employee {
        guard let manager = try await fetchEmployee(by: managerId) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        guard let employee = try await fetchEmployee(by: employeeId) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        var updatedManager = manager
        var updatedEmployee = employee
        
        // Add to manager's direct reports
        if !updatedManager.directReports.contains(employeeId) {
            updatedManager.directReports.append(employeeId)
        }
        
        // Update employee's manager
        updatedEmployee.managerId = managerId
        
        // Save both updates
        _ = try await updateEmployee(updatedEmployee)
        return try await updateEmployee(updatedManager)
    }
    
    public func removeDirectReport(managerId: String, employeeId: String) async throws -> Employee {
        guard let manager = try await fetchEmployee(by: managerId) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        guard let employee = try await fetchEmployee(by: employeeId) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        var updatedManager = manager
        var updatedEmployee = employee
        
        // Remove from manager's direct reports
        updatedManager.directReports.removeAll { $0 == employeeId }
        
        // Clear employee's manager
        updatedEmployee.managerId = nil
        
        // Save both updates
        _ = try await updateEmployee(updatedEmployee)
        return try await updateEmployee(updatedManager)
    }
    
    public func searchEmployees(query: String) async throws -> [Employee] {
        let predicate = NSPredicate(
            format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@ OR email CONTAINS[cd] %@ OR employeeNumber CONTAINS[cd] %@ OR department CONTAINS[cd] %@ OR title CONTAINS[cd] %@",
            query, query, query, query, query, query
        )
        let ckQuery = CKQuery(recordType: RecordType.employee, predicate: predicate)
        ckQuery.sortDescriptors = [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
        
        let (records, _) = try await privateDatabase.records(matching: ckQuery)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Employee.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    // MARK: - Vendor Methods
    
    public func fetchVendors() async throws -> [Vendor] {
        let query = CKQuery(recordType: RecordType.vendor, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        let vendors = records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Vendor.from(record: record)
            case .failure:
                return nil
            }
        }
        
        self.vendors = vendors
        return vendors
    }
    
    public func createVendor(_ vendor: Vendor) async throws -> Vendor {
        let record = vendor.toCKRecord()
        let savedRecord = try await privateDatabase.save(record)
        
        if let savedVendor = Vendor.from(record: savedRecord) {
            vendors.append(savedVendor)
            vendors.sort { $0.name < $1.name }
            return savedVendor
        }
        
        throw EmployeeServiceError.invalidVendorData
    }
    
    public func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        let record = vendor.toCKRecord()
        let savedRecord = try await privateDatabase.save(record)
        
        if let updatedVendor = Vendor.from(record: savedRecord) {
            if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
                vendors[index] = updatedVendor
            }
            return updatedVendor
        }
        
        throw EmployeeServiceError.invalidVendorData
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        do {
            _ = try await fetchEmployees()
            _ = try await fetchVendors()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Employee Service Error
public enum EmployeeServiceError: LocalizedError {
    case invalidEmployeeData
    case invalidVendorData
    case employeeNotFound
    case employeeNumberExists(String)
    case emailExists(String)
    case hasDirectReports
    case invalidRole
    case cloudKitError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmployeeData:
            return "Invalid employee data"
        case .invalidVendorData:
            return "Invalid vendor data"
        case .employeeNotFound:
            return "Employee not found"
        case .employeeNumberExists(let number):
            return "Employee number \(number) already exists"
        case .emailExists(let email):
            return "Email \(email) already exists"
        case .hasDirectReports:
            return "Cannot delete employee with direct reports"
        case .invalidRole:
            return "Invalid user role"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Employee Service
public final class MockEmployeeService: EmployeeServiceProtocol {
    private var employees: [Employee] = []
    private var vendors: [Vendor] = []
    
    public init() {}
    
    public func fetchEmployees() async throws -> [Employee] {
        return employees
    }
    
    public func fetchEmployee(by id: String) async throws -> Employee? {
        return employees.first { $0.id == id }
    }
    
    public func fetchEmployeeByNumber(_ employeeNumber: String) async throws -> Employee? {
        return employees.first { $0.employeeNumber == employeeNumber }
    }
    
    public func fetchEmployeeByEmail(_ email: String) async throws -> Employee? {
        return employees.first { $0.email.lowercased() == email.lowercased() }
    }
    
    public func fetchEmployeesByDepartment(_ department: String) async throws -> [Employee] {
        return employees.filter { $0.department == department }
    }
    
    public func fetchEmployeesByManager(_ managerId: String) async throws -> [Employee] {
        return employees.filter { $0.managerId == managerId }
    }
    
    public func fetchEmployeesByRole(_ role: UserRole) async throws -> [Employee] {
        return employees.filter { $0.userRole == role }
    }
    
    public func fetchEmployeesByStore(_ storeCode: String) async throws -> [Employee] {
        return employees.filter { $0.storeCodes.contains(storeCode) }
    }
    
    public func fetchActiveEmployees() async throws -> [Employee] {
        return employees.filter { $0.isActive }
    }
    
    public func createEmployee(_ employee: Employee) async throws -> Employee {
        employees.append(employee)
        return employee
    }
    
    public func updateEmployee(_ employee: Employee) async throws -> Employee {
        if let index = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[index] = employee
        }
        return employee
    }
    
    public func deleteEmployee(id: String) async throws {
        employees.removeAll { $0.id == id }
    }
    
    public func deactivateEmployee(id: String) async throws -> Employee {
        guard let employee = employees.first(where: { $0.id == id }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        var updated = employee
        updated.isActive = false
        return try await updateEmployee(updated)
    }
    
    public func reactivateEmployee(id: String) async throws -> Employee {
        guard let employee = employees.first(where: { $0.id == id }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        var updated = employee
        updated.isActive = true
        return try await updateEmployee(updated)
    }
    
    public func updateEmployeeRole(id: String, role: UserRole) async throws -> Employee {
        guard let employee = employees.first(where: { $0.id == id }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        var updated = employee
        updated.userRole = role
        return try await updateEmployee(updated)
    }
    
    public func addDirectReport(managerId: String, employeeId: String) async throws -> Employee {
        guard let manager = employees.first(where: { $0.id == managerId }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        var updated = manager
        if !updated.directReports.contains(employeeId) {
            updated.directReports.append(employeeId)
        }
        return try await updateEmployee(updated)
    }
    
    public func removeDirectReport(managerId: String, employeeId: String) async throws -> Employee {
        guard let manager = employees.first(where: { $0.id == managerId }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        var updated = manager
        updated.directReports.removeAll { $0 == employeeId }
        return try await updateEmployee(updated)
    }
    
    public func searchEmployees(query: String) async throws -> [Employee] {
        return employees.filter {
            $0.firstName.localizedCaseInsensitiveContains(query) ||
            $0.lastName.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query) ||
            $0.department.localizedCaseInsensitiveContains(query) ||
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }
    
    public func fetchVendors() async throws -> [Vendor] {
        return vendors
    }
    
    public func createVendor(_ vendor: Vendor) async throws -> Vendor {
        vendors.append(vendor)
        return vendor
    }
    
    public func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            vendors[index] = vendor
        }
        return vendor
    }
}
