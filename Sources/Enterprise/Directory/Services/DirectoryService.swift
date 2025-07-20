import Foundation
import CloudKit
import Combine

// MARK: - Directory Service

@MainActor
public class DirectoryService: ObservableObject {
    
    // MARK: - Properties
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.publicCloudDatabase
    }
    
    @Published public var employees: [Employee] = []
    @Published public var vendors: [Vendor] = []
    @Published public var isLoading = false
    @Published public var error: DirectoryError?
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Employee Operations
    
    public func fetchEmployees(filter: EmployeeFilter = EmployeeFilter()) async throws -> [Employee] {
        isLoading = true
        defer { isLoading = false }
        
        let predicate = buildEmployeePredicate(filter: filter)
        let query = CKQuery(recordType: "Employee", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        do {
            let (records, _) = try await database.records(matching: query)
            let fetchedEmployees = records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Employee.fromCKRecord(record)
                case .failure:
                    return nil
                }
            }
            
            employees = fetchedEmployees
            return fetchedEmployees
        } catch {
            self.error = DirectoryError.fetchFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func createEmployee(_ employee: Employee) async throws -> Employee {
        isLoading = true
        defer { isLoading = false }
        
        let record = employee.toCKRecord()
        
        do {
            let savedRecord = try await database.save(record)
            guard let savedEmployee = Employee.fromCKRecord(savedRecord) else {
                throw DirectoryError.invalidData("Failed to convert saved record to Employee")
            }
            
            employees.append(savedEmployee)
            return savedEmployee
        } catch {
            self.error = DirectoryError.saveFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func updateEmployee(_ employee: Employee) async throws -> Employee {
        isLoading = true
        defer { isLoading = false }
        
        var updatedEmployee = employee
        updatedEmployee.updatedAt = Date()
        let record = updatedEmployee.toCKRecord()
        
        do {
            let savedRecord = try await database.save(record)
            guard let savedEmployee = Employee.fromCKRecord(savedRecord) else {
                throw DirectoryError.invalidData("Failed to convert updated record to Employee")
            }
            
            if let index = employees.firstIndex(where: { $0.id == savedEmployee.id }) {
                employees[index] = savedEmployee
            }
            
            return savedEmployee
        } catch {
            self.error = DirectoryError.updateFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func deleteEmployee(_ employee: Employee) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let recordID = CKRecord.ID(recordName: employee.id)
        
        do {
            try await database.deleteRecord(withID: recordID)
            employees.removeAll { $0.id == employee.id }
        } catch {
            self.error = DirectoryError.deleteFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func fetchEmployee(byId id: String) async throws -> Employee? {
        let recordID = CKRecord.ID(recordName: id)
        
        do {
            let record = try await database.record(for: recordID)
            return Employee.fromCKRecord(record)
        } catch {
            self.error = DirectoryError.fetchFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func searchEmployees(query: String) async throws -> [Employee] {
        guard !query.isEmpty else {
            return employees
        }
        
        let predicate = NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@ OR email CONTAINS[cd] %@", 
                                  query, query, query)
        let ckQuery = CKQuery(recordType: "Employee", predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        do {
            let (records, _) = try await database.records(matching: ckQuery)
            return records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Employee.fromCKRecord(record)
                case .failure:
                    return nil
                }
            }
        } catch {
            self.error = DirectoryError.searchFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func getOrganizationChart() async throws -> OrganizationChart {
        let allEmployees = try await fetchEmployees()
        return OrganizationChart(employees: allEmployees)
    }
    
    // MARK: - Vendor Operations
    
    public func fetchVendors(filter: VendorFilter = VendorFilter()) async throws -> [Vendor] {
        isLoading = true
        defer { isLoading = false }
        
        let predicate = buildVendorPredicate(filter: filter)
        let query = CKQuery(recordType: "Vendor", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "companyName", ascending: true)]
        
        do {
            let (records, _) = try await database.records(matching: query)
            let fetchedVendors = records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Vendor.fromCKRecord(record)
                case .failure:
                    return nil
                }
            }
            
            vendors = fetchedVendors
            return fetchedVendors
        } catch {
            self.error = DirectoryError.fetchFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func createVendor(_ vendor: Vendor) async throws -> Vendor {
        isLoading = true
        defer { isLoading = false }
        
        let record = vendor.toCKRecord()
        
        do {
            let savedRecord = try await database.save(record)
            guard let savedVendor = Vendor.fromCKRecord(savedRecord) else {
                throw DirectoryError.invalidData("Failed to convert saved record to Vendor")
            }
            
            vendors.append(savedVendor)
            return savedVendor
        } catch {
            self.error = DirectoryError.saveFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        isLoading = true
        defer { isLoading = false }
        
        var updatedVendor = vendor
        updatedVendor.updatedAt = Date()
        let record = updatedVendor.toCKRecord()
        
        do {
            let savedRecord = try await database.save(record)
            guard let savedVendor = Vendor.fromCKRecord(savedRecord) else {
                throw DirectoryError.invalidData("Failed to convert updated record to Vendor")
            }
            
            if let index = vendors.firstIndex(where: { $0.id == savedVendor.id }) {
                vendors[index] = savedVendor
            }
            
            return savedVendor
        } catch {
            self.error = DirectoryError.updateFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func deleteVendor(_ vendor: Vendor) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let recordID = CKRecord.ID(recordName: vendor.id)
        
        do {
            try await database.deleteRecord(withID: recordID)
            vendors.removeAll { $0.id == vendor.id }
        } catch {
            self.error = DirectoryError.deleteFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func fetchVendor(byId id: String) async throws -> Vendor? {
        let recordID = CKRecord.ID(recordName: id)
        
        do {
            let record = try await database.record(for: recordID)
            return Vendor.fromCKRecord(record)
        } catch {
            self.error = DirectoryError.fetchFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func searchVendors(query: String) async throws -> [Vendor] {
        guard !query.isEmpty else {
            return vendors
        }
        
        let predicate = NSPredicate(format: "companyName CONTAINS[cd] %@ OR contactPerson CONTAINS[cd] %@ OR email CONTAINS[cd] %@", 
                                  query, query, query)
        let ckQuery = CKQuery(recordType: "Vendor", predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "companyName", ascending: true)]
        
        do {
            let (records, _) = try await database.records(matching: ckQuery)
            return records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Vendor.fromCKRecord(record)
                case .failure:
                    return nil
                }
            }
        } catch {
            self.error = DirectoryError.searchFailed(error.localizedDescription)
            throw error
        }
    }
    
    public func getVendorPerformanceReport() async throws -> VendorPerformanceReport {
        let allVendors = try await fetchVendors()
        return VendorPerformanceReport(vendors: allVendors)
    }
    
    // MARK: - Analytics Operations
    
    public func getDirectoryAnalytics() async throws -> DirectoryAnalytics {
        async let employeesFetch = fetchEmployees()
        async let vendorsFetch = fetchVendors()
        
        let (employees, vendors) = try await (employeesFetch, vendorsFetch)
        
        return DirectoryAnalytics(employees: employees, vendors: vendors)
    }
    
    // MARK: - Bulk Operations
    
    public func bulkImportEmployees(_ employees: [Employee]) async throws -> BulkImportResult {
        var successCount = 0
        var failureCount = 0
        var errors: [String] = []
        
        for employee in employees {
            do {
                _ = try await createEmployee(employee)
                successCount += 1
            } catch {
                failureCount += 1
                errors.append("Employee \(employee.fullName): \(error.localizedDescription)")
            }
        }
        
        return BulkImportResult(
            successCount: successCount,
            failureCount: failureCount,
            errors: errors
        )
    }
    
    public func bulkImportVendors(_ vendors: [Vendor]) async throws -> BulkImportResult {
        var successCount = 0
        var failureCount = 0
        var errors: [String] = []
        
        for vendor in vendors {
            do {
                _ = try await createVendor(vendor)
                successCount += 1
            } catch {
                failureCount += 1
                errors.append("Vendor \(vendor.companyName): \(error.localizedDescription)")
            }
        }
        
        return BulkImportResult(
            successCount: successCount,
            failureCount: failureCount,
            errors: errors
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func buildEmployeePredicate(filter: EmployeeFilter) -> NSPredicate {
        var predicates: [NSPredicate] = []
        
        if let isActive = filter.isActive {
            predicates.append(NSPredicate(format: "isActive == %@", NSNumber(value: isActive)))
        }
        
        if let department = filter.department {
            predicates.append(NSPredicate(format: "department == %@", department))
        }
        
        if let workLocation = filter.workLocation {
            predicates.append(NSPredicate(format: "workLocation == %@", workLocation.rawValue))
        }
        
        if let employmentType = filter.employmentType {
            predicates.append(NSPredicate(format: "employmentType == %@", employmentType.rawValue))
        }
        
        if let manager = filter.manager {
            predicates.append(NSPredicate(format: "manager == %@", manager))
        }
        
        return predicates.isEmpty ? NSPredicate(value: true) : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    private func buildVendorPredicate(filter: VendorFilter) -> NSPredicate {
        var predicates: [NSPredicate] = []
        
        if let isActive = filter.isActive {
            predicates.append(NSPredicate(format: "isActive == %@", NSNumber(value: isActive)))
        }
        
        if let vendorType = filter.vendorType {
            predicates.append(NSPredicate(format: "vendorType == %@", vendorType.rawValue))
        }
        
        if let isPreferred = filter.isPreferred {
            predicates.append(NSPredicate(format: "isPreferred == %@", NSNumber(value: isPreferred)))
        }
        
        if let riskLevel = filter.riskLevel {
            predicates.append(NSPredicate(format: "riskAssessment.overallRiskLevel == %@", riskLevel.rawValue))
        }
        
        return predicates.isEmpty ? NSPredicate(value: true) : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

// MARK: - Supporting Types

public struct EmployeeFilter {
    public var isActive: Bool?
    public var department: String?
    public var workLocation: WorkLocation?
    public var employmentType: EmploymentType?
    public var manager: String?
    
    public init(
        isActive: Bool? = nil,
        department: String? = nil,
        workLocation: WorkLocation? = nil,
        employmentType: EmploymentType? = nil,
        manager: String? = nil
    ) {
        self.isActive = isActive
        self.department = department
        self.workLocation = workLocation
        self.employmentType = employmentType
        self.manager = manager
    }
}

public struct VendorFilter {
    public var isActive: Bool?
    public var vendorType: VendorType?
    public var isPreferred: Bool?
    public var riskLevel: RiskLevel?
    
    public init(
        isActive: Bool? = nil,
        vendorType: VendorType? = nil,
        isPreferred: Bool? = nil,
        riskLevel: RiskLevel? = nil
    ) {
        self.isActive = isActive
        self.vendorType = vendorType
        self.isPreferred = isPreferred
        self.riskLevel = riskLevel
    }
}

public struct OrganizationChart {
    public let employees: [Employee]
    public let departments: [String: [Employee]]
    public let managementHierarchy: [String: [Employee]]
    
    public init(employees: [Employee]) {
        self.employees = employees
        
        // Group by department
        self.departments = Dictionary(grouping: employees) { $0.department }
        
        // Group by manager
        self.managementHierarchy = Dictionary(grouping: employees) { employee in
            employee.manager ?? "No Manager"
        }
    }
    
    public var rootEmployees: [Employee] {
        employees.filter { $0.manager == nil }
    }
    
    public func directReports(for managerId: String) -> [Employee] {
        employees.filter { $0.manager == managerId }
    }
}

public struct VendorPerformanceReport {
    public let vendors: [Vendor]
    public let averageRating: Double
    public let topPerformers: [Vendor]
    public let riskySummary: [Vendor]
    public let expiringContracts: [Vendor]
    
    public init(vendors: [Vendor]) {
        self.vendors = vendors
        
        let ratings = vendors.map { $0.overallRating }.filter { $0 > 0 }
        self.averageRating = ratings.isEmpty ? 0.0 : ratings.reduce(0, +) / Double(ratings.count)
        
        self.topPerformers = vendors
            .filter { $0.overallRating >= 4.0 }
            .sorted { $0.overallRating > $1.overallRating }
            .prefix(10)
            .map { $0 }
        
        self.riskySummary = vendors
            .filter { $0.riskAssessment.overallRiskLevel == .high || $0.riskAssessment.overallRiskLevel == .critical }
            .sorted { $0.riskAssessment.overallRiskLevel.rawValue > $1.riskAssessment.overallRiskLevel.rawValue }
        
        self.expiringContracts = vendors.filter { $0.isContractExpiring }
    }
}

public struct DirectoryAnalytics {
    public let totalEmployees: Int
    public let activeEmployees: Int
    public let departmentBreakdown: [String: Int]
    public let employmentTypeBreakdown: [EmploymentType: Int]
    public let workLocationBreakdown: [WorkLocation: Int]
    
    public let totalVendors: Int
    public let activeVendors: Int
    public let preferredVendors: Int
    public let vendorTypeBreakdown: [VendorType: Int]
    public let riskLevelBreakdown: [RiskLevel: Int]
    
    public init(employees: [Employee], vendors: [Vendor]) {
        self.totalEmployees = employees.count
        self.activeEmployees = employees.filter { $0.isActive }.count
        self.departmentBreakdown = Dictionary(employees.map { ($0.department, 1) }, uniquingKeysWith: +)
        self.employmentTypeBreakdown = Dictionary(employees.map { ($0.employmentType, 1) }, uniquingKeysWith: +)
        self.workLocationBreakdown = Dictionary(employees.map { ($0.workLocation, 1) }, uniquingKeysWith: +)
        
        self.totalVendors = vendors.count
        self.activeVendors = vendors.filter { $0.isActive }.count
        self.preferredVendors = vendors.filter { $0.isPreferred }.count
        self.vendorTypeBreakdown = Dictionary(vendors.map { ($0.vendorType, 1) }, uniquingKeysWith: +)
        self.riskLevelBreakdown = Dictionary(vendors.map { ($0.riskAssessment.overallRiskLevel, 1) }, uniquingKeysWith: +)
    }
}

public struct BulkImportResult {
    public let successCount: Int
    public let failureCount: Int
    public let errors: [String]
    
    public init(successCount: Int, failureCount: Int, errors: [String]) {
        self.successCount = successCount
        self.failureCount = failureCount
        self.errors = errors
    }
    
    public var totalProcessed: Int {
        successCount + failureCount
    }
    
    public var successRate: Double {
        guard totalProcessed > 0 else { return 0.0 }
        return Double(successCount) / Double(totalProcessed)
    }
}

// MARK: - Error Types

public enum DirectoryError: LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case searchFailed(String)
    case invalidData(String)
    case networkError
    case permissionDenied
    
    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        case .updateFailed(let message):
            return "Failed to update data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete data: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .networkError:
            return "Network connection error"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
