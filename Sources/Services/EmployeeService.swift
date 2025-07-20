import Foundation
import CloudKit
import Combine

// MARK: - Employee Service Implementation
@MainActor
public class EmployeeService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var employees: [Employee] = []
    @Published public var vendors: [Vendor] = []
    @Published public var performanceReviews: [PerformanceReview] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(container: CKContainer = .default()) {
        self.container = container
        self.database = container.publicCloudDatabase
        setupSubscriptions()
    }
    
    // MARK: - Employee Management
    
    /// Fetches all employees
    public func fetchEmployees() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "Employee", predicate: predicate)
            query.sortDescriptors = [
                NSSortDescriptor(key: "lastName", ascending: true),
                NSSortDescriptor(key: "firstName", ascending: true)
            ]
            
            let (matchResults, _) = try await database.records(matching: query)
            
            var fetchedEmployees: [Employee] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let employee = Employee.from(record: record) {
                        fetchedEmployees.append(employee)
                    }
                case .failure(let error):
                    print("Error fetching employee record: \(error)")
                }
            }
            
            employees = fetchedEmployees
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch employees: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Creates a new employee
    public func createEmployee(_ employee: Employee) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate employee data
            try validateEmployee(employee)
            
            let record = employee.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let savedEmployee = Employee.from(record: savedRecord) {
                employees.append(savedEmployee)
                employees.sort { $0.lastName < $1.lastName }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to create employee: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Updates an existing employee
    public func updateEmployee(_ employee: Employee) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try validateEmployee(employee)
            
            let record = employee.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let updatedEmployee = Employee.from(record: savedRecord),
               let index = employees.firstIndex(where: { $0.id == employee.id }) {
                employees[index] = updatedEmployee
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to update employee: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Deactivates an employee (soft delete)
    public func deactivateEmployee(id: String) async throws {
        guard var employee = employees.first(where: { $0.id == id }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        employee.isActive = false
        employee.terminationDate = Date()
        
        try await updateEmployee(employee)
    }
    
    /// Searches employees by various criteria
    public func searchEmployees(
        query: String? = nil,
        department: String? = nil,
        role: EmployeeRole? = nil,
        status: EmployeeStatus? = nil
    ) -> [Employee] {
        var results = employees
        
        if let query = query, !query.isEmpty {
            results = results.filter { employee in
                employee.firstName.localizedCaseInsensitiveContains(query) ||
                employee.lastName.localizedCaseInsensitiveContains(query) ||
                employee.email.localizedCaseInsensitiveContains(query) ||
                employee.employeeNumber.localizedCaseInsensitiveContains(query)
            }
        }
        
        if let department = department {
            results = results.filter { $0.department == department }
        }
        
        if let role = role {
            results = results.filter { $0.role == role }
        }
        
        if let status = status {
            results = results.filter { $0.status == status }
        }
        
        return results
    }
    
    /// Gets employees by manager
    public func getDirectReports(managerId: String) -> [Employee] {
        return employees.filter { $0.managerId == managerId }
    }
    
    /// Gets the organizational hierarchy for an employee
    public func getOrganizationalHierarchy(employeeId: String) -> OrganizationalHierarchy? {
        guard let employee = employees.first(where: { $0.id == employeeId }) else {
            return nil
        }
        
        var hierarchy = OrganizationalHierarchy(employee: employee)
        
        // Get manager chain
        var currentEmployee = employee
        while let managerId = currentEmployee.managerId,
              let manager = employees.first(where: { $0.id == managerId }) {
            hierarchy.managers.append(manager)
            currentEmployee = manager
        }
        
        // Get direct reports
        hierarchy.directReports = getDirectReports(managerId: employeeId)
        
        // Get all subordinates (recursive)
        hierarchy.allSubordinates = getAllSubordinates(managerId: employeeId)
        
        return hierarchy
    }
    
    // MARK: - Performance Management
    
    /// Creates a performance review
    public func createPerformanceReview(_ review: PerformanceReview) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let record = review.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let savedReview = PerformanceReview.from(record: savedRecord) {
                performanceReviews.append(savedReview)
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to create performance review: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Gets performance reviews for an employee
    public func getPerformanceReviews(employeeId: String) -> [PerformanceReview] {
        return performanceReviews.filter { $0.employeeId == employeeId }
            .sorted { $0.reviewPeriodEnd > $1.reviewPeriodEnd }
    }
    
    /// Gets the latest performance review for an employee
    public func getLatestPerformanceReview(employeeId: String) -> PerformanceReview? {
        return getPerformanceReviews(employeeId: employeeId).first
    }
    
    /// Calculates performance metrics for an employee
    public func calculatePerformanceMetrics(employeeId: String) -> PerformanceMetrics {
        let reviews = getPerformanceReviews(employeeId: employeeId)
        
        guard !reviews.isEmpty else {
            return PerformanceMetrics(employeeId: employeeId)
        }
        
        let scores = reviews.compactMap { $0.overallScore }
        let averageScore = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        
        let latestReview = reviews.first
        let improvementTrend = calculateImprovementTrend(reviews: reviews)
        let goalAchievementRate = calculateGoalAchievementRate(reviews: reviews)
        
        return PerformanceMetrics(
            employeeId: employeeId,
            averageScore: averageScore,
            latestScore: latestReview?.overallScore,
            improvementTrend: improvementTrend,
            goalAchievementRate: goalAchievementRate,
            totalReviews: reviews.count
        )
    }
    
    // MARK: - Vendor Management
    
    /// Fetches all vendors
    public func fetchVendors() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "Vendor", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "companyName", ascending: true)]
            
            let (matchResults, _) = try await database.records(matching: query)
            
            var fetchedVendors: [Vendor] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let vendor = Vendor.from(record: record) {
                        fetchedVendors.append(vendor)
                    }
                case .failure(let error):
                    print("Error fetching vendor record: \(error)")
                }
            }
            
            vendors = fetchedVendors
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch vendors: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Creates a new vendor
    public func createVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try validateVendor(vendor)
            
            let record = vendor.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let savedVendor = Vendor.from(record: savedRecord) {
                vendors.append(savedVendor)
                vendors.sort { $0.companyName < $1.companyName }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to create vendor: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Updates vendor information
    public func updateVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try validateVendor(vendor)
            
            let record = vendor.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let updatedVendor = Vendor.from(record: savedRecord),
               let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
                vendors[index] = updatedVendor
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to update vendor: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Gets vendors by category
    public func getVendorsByCategory(_ category: VendorCategory) -> [Vendor] {
        return vendors.filter { $0.category == category }
    }
    
    /// Gets vendors by status
    public func getVendorsByStatus(_ status: VendorStatus) -> [Vendor] {
        return vendors.filter { $0.status == status }
    }
    
    /// Calculates vendor performance metrics
    public func calculateVendorMetrics(vendorId: String) -> VendorMetrics? {
        guard let vendor = vendors.first(where: { $0.id == vendorId }) else {
            return nil
        }
        
        // This would typically pull from various data sources
        // For now, we'll use the basic rating from the vendor record
        return VendorMetrics(
            vendorId: vendorId,
            performanceRating: vendor.performanceRating,
            onTimeDeliveryRate: 0.95, // Placeholder
            qualityScore: vendor.performanceRating * 20, // Convert 5-point to 100-point scale
            costEfficiencyRating: vendor.performanceRating,
            totalContracts: 1, // Placeholder
            activeContracts: vendor.status == .active ? 1 : 0,
            totalSpend: 0, // Would be calculated from contracts/invoices
            riskScore: vendor.riskLevel.numericValue
        )
    }
    
    // MARK: - Certification Management
    
    /// Adds a certification to an employee
    public func addCertification(employeeId: String, certification: Certification) async throws {
        guard var employee = employees.first(where: { $0.id == employeeId }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        employee.certifications.append(certification)
        try await updateEmployee(employee)
    }
    
    /// Gets employees with expiring certifications
    public func getEmployeesWithExpiringCertifications(within days: Int = 30) -> [(Employee, [Certification])] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        var result: [(Employee, [Certification])] = []
        
        for employee in employees {
            let expiringCerts = employee.certifications.filter { cert in
                if let expiryDate = cert.expiryDate {
                    return expiryDate <= cutoffDate && expiryDate >= Date()
                }
                return false
            }
            
            if !expiringCerts.isEmpty {
                result.append((employee, expiringCerts))
            }
        }
        
        return result
    }
    
    // MARK: - Schedule Management
    
    /// Updates employee work schedule
    public func updateWorkSchedule(employeeId: String, schedule: WorkSchedule) async throws {
        guard var employee = employees.first(where: { $0.id == employeeId }) else {
            throw EmployeeServiceError.employeeNotFound
        }
        
        employee.workSchedule = schedule
        try await updateEmployee(employee)
    }
    
    /// Gets employees scheduled for a specific date
    public func getScheduledEmployees(for date: Date) -> [Employee] {
        let weekday = Calendar.current.component(.weekday, from: date)
        
        return employees.filter { employee in
            guard let schedule = employee.workSchedule else { return false }
            
            switch weekday {
            case 1: return schedule.sunday != nil // Sunday
            case 2: return schedule.monday != nil // Monday
            case 3: return schedule.tuesday != nil // Tuesday
            case 4: return schedule.wednesday != nil // Wednesday
            case 5: return schedule.thursday != nil // Thursday
            case 6: return schedule.friday != nil // Friday
            case 7: return schedule.saturday != nil // Saturday
            default: return false
            }
        }
    }
    
    // MARK: - Analytics and Reporting
    
    /// Gets department statistics
    public func getDepartmentStatistics() -> [DepartmentStats] {
        let departments = Set(employees.map { $0.department })
        
        return departments.map { department in
            let departmentEmployees = employees.filter { $0.department == department }
            let activeEmployees = departmentEmployees.filter { $0.isActive }
            
            let averageTenure = calculateAverageTenure(employees: departmentEmployees)
            let averagePerformance = calculateAveragePerformance(employees: departmentEmployees)
            
            return DepartmentStats(
                department: department,
                totalEmployees: departmentEmployees.count,
                activeEmployees: activeEmployees.count,
                averageTenure: averageTenure,
                averagePerformanceScore: averagePerformance
            )
        }
    }
    
    /// Gets employee demographics
    public func getEmployeeDemographics() -> EmployeeDemographics {
        let total = employees.count
        let active = employees.filter { $0.isActive }.count
        
        let roleDistribution = Dictionary(grouping: employees, by: { $0.role })
            .mapValues { $0.count }
        
        let departmentDistribution = Dictionary(grouping: employees, by: { $0.department })
            .mapValues { $0.count }
        
        let averageTenure = calculateAverageTenure(employees: employees)
        
        return EmployeeDemographics(
            totalEmployees: total,
            activeEmployees: active,
            roleDistribution: roleDistribution,
            departmentDistribution: departmentDistribution,
            averageTenure: averageTenure
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func setupSubscriptions() {
        // Setup CloudKit subscriptions for real-time updates
    }
    
    private func validateEmployee(_ employee: Employee) throws {
        if employee.firstName.isEmpty {
            throw EmployeeServiceError.validationError("First name is required")
        }
        
        if employee.lastName.isEmpty {
            throw EmployeeServiceError.validationError("Last name is required")
        }
        
        if employee.email.isEmpty || !isValidEmail(employee.email) {
            throw EmployeeServiceError.validationError("Valid email is required")
        }
        
        if employee.employeeNumber.isEmpty {
            throw EmployeeServiceError.validationError("Employee number is required")
        }
        
        // Check for duplicate employee number
        if employees.contains(where: { $0.employeeNumber == employee.employeeNumber && $0.id != employee.id }) {
            throw EmployeeServiceError.validationError("Employee number already exists")
        }
    }
    
    private func validateVendor(_ vendor: Vendor) throws {
        if vendor.companyName.isEmpty {
            throw EmployeeServiceError.validationError("Company name is required")
        }
        
        if vendor.contactPerson.isEmpty {
            throw EmployeeServiceError.validationError("Contact person is required")
        }
        
        if vendor.email.isEmpty || !isValidEmail(vendor.email) {
            throw EmployeeServiceError.validationError("Valid email is required")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func getAllSubordinates(managerId: String) -> [Employee] {
        var subordinates: [Employee] = []
        let directReports = getDirectReports(managerId: managerId)
        
        subordinates.append(contentsOf: directReports)
        
        for report in directReports {
            subordinates.append(contentsOf: getAllSubordinates(managerId: report.id))
        }
        
        return subordinates
    }
    
    private func calculateImprovementTrend(reviews: [PerformanceReview]) -> Double {
        guard reviews.count >= 2 else { return 0 }
        
        let sortedReviews = reviews.sorted { $0.reviewPeriodEnd < $1.reviewPeriodEnd }
        let recent = sortedReviews.suffix(2)
        
        if let previous = recent.first?.overallScore,
           let latest = recent.last?.overallScore {
            return latest - previous
        }
        
        return 0
    }
    
    private func calculateGoalAchievementRate(reviews: [PerformanceReview]) -> Double {
        let allGoals = reviews.flatMap { $0.goals }
        guard !allGoals.isEmpty else { return 0 }
        
        let achievedGoals = allGoals.filter { $0.status == .achieved }.count
        return Double(achievedGoals) / Double(allGoals.count)
    }
    
    private func calculateAverageTenure(employees: [Employee]) -> TimeInterval {
        guard !employees.isEmpty else { return 0 }
        
        let now = Date()
        let tenures = employees.compactMap { employee in
            employee.terminationDate?.timeIntervalSince(employee.hireDate) ??
            now.timeIntervalSince(employee.hireDate)
        }
        
        return tenures.reduce(0, +) / TimeInterval(tenures.count)
    }
    
    private func calculateAveragePerformance(employees: [Employee]) -> Double {
        let employeeIds = employees.map { $0.id }
        let relevantReviews = performanceReviews.filter { employeeIds.contains($0.employeeId) }
        
        guard !relevantReviews.isEmpty else { return 0 }
        
        let scores = relevantReviews.compactMap { $0.overallScore }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
}

// MARK: - Supporting Types

public struct OrganizationalHierarchy {
    public let employee: Employee
    public var managers: [Employee] = []
    public var directReports: [Employee] = []
    public var allSubordinates: [Employee] = []
    
    public init(employee: Employee) {
        self.employee = employee
    }
}

public struct PerformanceMetrics {
    public let employeeId: String
    public let averageScore: Double
    public let latestScore: Double?
    public let improvementTrend: Double
    public let goalAchievementRate: Double
    public let totalReviews: Int
    
    public init(
        employeeId: String,
        averageScore: Double = 0,
        latestScore: Double? = nil,
        improvementTrend: Double = 0,
        goalAchievementRate: Double = 0,
        totalReviews: Int = 0
    ) {
        self.employeeId = employeeId
        self.averageScore = averageScore
        self.latestScore = latestScore
        self.improvementTrend = improvementTrend
        self.goalAchievementRate = goalAchievementRate
        self.totalReviews = totalReviews
    }
}

public struct VendorMetrics {
    public let vendorId: String
    public let performanceRating: Double
    public let onTimeDeliveryRate: Double
    public let qualityScore: Double
    public let costEfficiencyRating: Double
    public let totalContracts: Int
    public let activeContracts: Int
    public let totalSpend: Double
    public let riskScore: Double
}

public struct DepartmentStats {
    public let department: String
    public let totalEmployees: Int
    public let activeEmployees: Int
    public let averageTenure: TimeInterval
    public let averagePerformanceScore: Double
}

public struct EmployeeDemographics {
    public let totalEmployees: Int
    public let activeEmployees: Int
    public let roleDistribution: [EmployeeRole: Int]
    public let departmentDistribution: [String: Int]
    public let averageTenure: TimeInterval
}

public enum EmployeeServiceError: LocalizedError {
    case employeeNotFound
    case vendorNotFound
    case validationError(String)
    case duplicateEmployeeNumber
    case invalidManager
    
    public var errorDescription: String? {
        switch self {
        case .employeeNotFound:
            return "Employee not found"
        case .vendorNotFound:
            return "Vendor not found"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .duplicateEmployeeNumber:
            return "Employee number already exists"
        case .invalidManager:
            return "Invalid manager assignment"
        }
    }
}

// MARK: - Extensions

extension EmployeeService {
    /// Gets birthday reminders for the week
    public func getBirthdayReminders(withinDays days: Int = 7) -> [Employee] {
        let calendar = Calendar.current
        let today = Date()
        
        return employees.filter { employee in
            guard let birthDate = employee.birthDate else { return false }
            
            let thisYearBirthday = calendar.dateBySettingYear(calendar.component(.year, from: today), 
                                                            of: birthDate) ?? birthDate
            
            let daysUntilBirthday = calendar.dateComponents([.day], 
                                                          from: today, 
                                                          to: thisYearBirthday).day ?? 0
            
            return daysUntilBirthday >= 0 && daysUntilBirthday <= days
        }
    }
    
    /// Gets work anniversaries for the week
    public func getWorkAnniversaries(withinDays days: Int = 7) -> [(Employee, Int)] {
        let calendar = Calendar.current
        let today = Date()
        
        var anniversaries: [(Employee, Int)] = []
        
        for employee in employees {
            let yearsOfService = calendar.dateComponents([.year], 
                                                       from: employee.hireDate, 
                                                       to: today).year ?? 0
            
            let thisYearAnniversary = calendar.dateBySettingYear(calendar.component(.year, from: today), 
                                                               of: employee.hireDate) ?? employee.hireDate
            
            let daysUntilAnniversary = calendar.dateComponents([.day], 
                                                             from: today, 
                                                             to: thisYearAnniversary).day ?? 0
            
            if daysUntilAnniversary >= 0 && daysUntilAnniversary <= days {
                anniversaries.append((employee, yearsOfService))
            }
        }
        
        return anniversaries
    }
}

private extension Calendar {
    func dateBySettingYear(_ year: Int, of date: Date) -> Date? {
        var components = dateComponents([.month, .day], from: date)
        components.year = year
        return self.date(from: components)
    }
}

extension RiskLevel {
    var numericValue: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        case .critical: return 4.0
        }
    }
}
