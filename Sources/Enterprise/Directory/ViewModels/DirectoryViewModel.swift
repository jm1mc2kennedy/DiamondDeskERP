import SwiftUI
import Combine

// Disambiguate Vendor type
typealias DirectoryVendor = EnterpriseDirectory.Vendor
typealias DirectoryEmployee = EnterpriseDirectory.Employee

// MARK: - Directory View Model

@MainActor
public class DirectoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var employees: [DirectoryEmployee] = []
    @Published public var vendors: [DirectoryVendor] = []
    @Published public var filteredEmployees: [DirectoryEmployee] = []
    @Published public var filteredVendors: [DirectoryVendor] = []
    
    @Published public var searchText = ""
    @Published public var selectedTab: DirectoryTab = .employees
    @Published public var viewMode: DirectoryViewMode = .list
    @Published public var employeeFilter = EmployeeFilter()
    @Published public var vendorFilter = VendorFilter()
    
    @Published public var isLoading = false
    @Published public var error: DirectoryError?
    @Published public var showingCreateEmployee = false
    @Published public var showingCreateVendor = false
    @Published public var showingEmployeeFilters = false
    @Published public var showingVendorFilters = false
    @Published public var showingOrganizationChart = false
    @Published public var showingPerformanceReport = false
    @Published public var showingAnalytics = false
    
    @Published public var selectedEmployee: DirectoryEmployee?
    @Published public var selectedVendor: DirectoryVendor?
    
    // MARK: - Analytics Data
    
    @Published public var analytics: DirectoryAnalytics?
    @Published public var organizationChart: OrganizationChart?
    @Published public var vendorPerformanceReport: VendorPerformanceReport?
    
    // MARK: - Services
    
    private let directoryService: DirectoryService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    @MainActor public init(directoryService: DirectoryService = DirectoryService()) {
        self.directoryService = directoryService
        setupBindings()
        setupSearchAndFilters()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        directoryService.$employees
            .receive(on: DispatchQueue.main)
            .assign(to: \.employees, on: self)
            .store(in: &cancellables)
        
        directoryService.$vendors
            .receive(on: DispatchQueue.main)
            .assign(to: \.vendors, on: self)
            .store(in: &cancellables)
        
        directoryService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        directoryService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    private func setupSearchAndFilters() {
        // Employee search and filtering
        Publishers.CombineLatest3($employees, $searchText, $employeeFilter)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { employees, searchText, filter in
                self.filterEmployees(employees, searchText: searchText, filter: filter)
            }
            .assign(to: \.filteredEmployees, on: self)
            .store(in: &cancellables)
        
        // Vendor search and filtering
        Publishers.CombineLatest3($vendors, $searchText, $vendorFilter)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { vendors, searchText, filter in
                self.filterVendors(vendors, searchText: searchText, filter: filter)
            }
            .assign(to: \.filteredVendors, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading Methods
    
    public func loadData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadEmployees()
            }
            group.addTask {
                await self.loadVendors()
            }
        }
    }
    
    public func loadEmployees() async {
        do {
            _ = try await directoryService.fetchEmployees(filter: employeeFilter)
        } catch {
            self.error = error as? DirectoryError ?? .fetchFailed(error.localizedDescription)
        }
    }
    
    public func loadVendors() async {
        do {
            _ = try await directoryService.fetchVendors(filter: vendorFilter)
        } catch {
            self.error = error as? DirectoryError ?? .fetchFailed(error.localizedDescription)
        }
    }
    
    public func refreshData() async {
        await loadData()
    }
    
    public func loadAnalytics() async {
        do {
            analytics = try await directoryService.getDirectoryAnalytics()
        } catch {
            self.error = error as? DirectoryError ?? .fetchFailed(error.localizedDescription)
        }
    }
    
    public func loadOrganizationChart() async {
        do {
            organizationChart = try await directoryService.getOrganizationChart()
        } catch {
            self.error = error as? DirectoryError ?? .fetchFailed(error.localizedDescription)
        }
    }
    
    public func loadVendorPerformanceReport() async {
        do {
            vendorPerformanceReport = try await directoryService.getVendorPerformanceReport()
        } catch {
            self.error = error as? DirectoryError ?? .fetchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Employee Operations
    
    public func createEmployee(_ employee: DirectoryEmployee) async {
        do {
            _ = try await directoryService.createEmployee(employee)
            showingCreateEmployee = false
        } catch {
            self.error = error as? DirectoryError ?? .saveFailed(error.localizedDescription)
        }
    }
    
    public func updateEmployee(_ employee: DirectoryEmployee) async {
        do {
            _ = try await directoryService.updateEmployee(employee)
        } catch {
            self.error = error as? DirectoryError ?? .updateFailed(error.localizedDescription)
        }
    }
    
    public func deleteEmployee(_ employee: DirectoryEmployee) async {
        do {
            try await directoryService.deleteEmployee(employee)
        } catch {
            self.error = error as? DirectoryError ?? .deleteFailed(error.localizedDescription)
        }
    }
    
    public func searchEmployees() async {
        guard !searchText.isEmpty else { return }
        
        do {
            let results = try await directoryService.searchEmployees(query: searchText)
            filteredEmployees = results
        } catch {
            self.error = error as? DirectoryError ?? .searchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Vendor Operations
    
    public func createVendor(_ vendor: DirectoryVendor) async {
        do {
            _ = try await directoryService.createVendor(vendor)
            showingCreateVendor = false
        } catch {
            self.error = error as? DirectoryError ?? .saveFailed(error.localizedDescription)
        }
    }
    
    public func updateVendor(_ vendor: DirectoryVendor) async {
        do {
            _ = try await directoryService.updateVendor(vendor)
        } catch {
            self.error = error as? DirectoryError ?? .updateFailed(error.localizedDescription)
        }
    }
    
    public func deleteVendor(_ vendor: DirectoryVendor) async {
        do {
            try await directoryService.deleteVendor(vendor)
        } catch {
            self.error = error as? DirectoryError ?? .deleteFailed(error.localizedDescription)
        }
    }
    
    public func searchVendors() async {
        guard !searchText.isEmpty else { return }
        
        do {
            let results = try await directoryService.searchVendors(query: searchText)
            filteredVendors = results
        } catch {
            self.error = error as? DirectoryError ?? .searchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Bulk Operations
    
    public func bulkImportEmployees(from url: URL) async {
        // Implementation would parse CSV/Excel file and import employees
        // This is a placeholder for the actual implementation
        print("Bulk import employees from: \(url)")
    }
    
    public func bulkImportVendors(from url: URL) async {
        // Implementation would parse CSV/Excel file and import vendors
        // This is a placeholder for the actual implementation
        print("Bulk import vendors from: \(url)")
    }
    
    public func exportEmployees() async -> URL? {
        // Implementation would create CSV/Excel file with employee data
        // This is a placeholder for the actual implementation
        print("Export employees")
        return nil
    }
    
    public func exportVendors() async -> URL? {
        // Implementation would create CSV/Excel file with vendor data
        // This is a placeholder for the actual implementation
        print("Export vendors")
        return nil
    }
    
    // MARK: - Filter Methods
    
    private func filterEmployees(_ employees: [DirectoryEmployee], searchText: String, filter: EmployeeFilter) -> [DirectoryEmployee] {
        var filtered = employees
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { employee in
                employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                employee.email.localizedCaseInsensitiveContains(searchText) ||
                employee.department.localizedCaseInsensitiveContains(searchText) ||
                employee.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filters
        if let isActive = filter.isActive {
            filtered = filtered.filter { $0.isActive == isActive }
        }
        
        if let department = filter.department {
            filtered = filtered.filter { $0.department == department }
        }
        
        if let workLocation = filter.workLocation {
            filtered = filtered.filter { $0.workLocation == workLocation }
        }
        
        if let employmentType = filter.employmentType {
            filtered = filtered.filter { $0.employmentType == employmentType }
        }
        
        if let manager = filter.manager {
            filtered = filtered.filter { $0.manager == manager }
        }
        
        return filtered
    }
    
    private func filterVendors(_ vendors: [DirectoryVendor], searchText: String, filter: VendorFilter) -> [DirectoryVendor] {
        var filtered = vendors
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { vendor in
                vendor.companyName.localizedCaseInsensitiveContains(searchText) ||
                vendor.contactPerson.localizedCaseInsensitiveContains(searchText) ||
                vendor.email.localizedCaseInsensitiveContains(searchText) ||
                vendor.vendorType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filters
        if let isActive = filter.isActive {
            filtered = filtered.filter { $0.isActive == isActive }
        }
        
        if let vendorType = filter.vendorType {
            filtered = filtered.filter { $0.vendorType == vendorType }
        }
        
        if let isPreferred = filter.isPreferred {
            filtered = filtered.filter { $0.isPreferred == isPreferred }
        }
        
        if let riskLevel = filter.riskLevel {
            filtered = filtered.filter { $0.riskAssessment.overallRiskLevel == riskLevel }
        }
        
        return filtered
    }
    
    // MARK: - Utility Methods
    
    public func clearFilters() {
        employeeFilter = EmployeeFilter()
        vendorFilter = VendorFilter()
        searchText = ""
    }
    
    public func clearError() {
        error = nil
    }
    
    public func selectEmployee(_ employee: DirectoryEmployee) {
        selectedEmployee = employee
    }
    
    public func selectVendor(_ vendor: DirectoryVendor) {
        selectedVendor = vendor
    }
    
    public func getDepartments() -> [String] {
        Array(Set(employees.map { $0.department })).sorted()
    }
    
    public func getManagers() -> [DirectoryEmployee] {
        employees.filter { $0.isManager }.sorted { $0.fullName < $1.fullName }
    }
    
    public func getDirectReports(for managerId: String) -> [DirectoryEmployee] {
        employees.filter { $0.manager == managerId }
    }
    
    public func getEmployeesByDepartment() -> [String: [DirectoryEmployee]] {
        Dictionary(grouping: employees) { $0.department }
    }
    
    public func getVendorsByType() -> [VendorType: [DirectoryVendor]] {
        Dictionary(grouping: vendors) { $0.vendorType }
    }
    
    public func getExpiringVendorContracts() -> [DirectoryVendor] {
        vendors.filter { $0.isContractExpiring }
    }
    
    public func getHighRiskVendors() -> [DirectoryVendor] {
        vendors.filter { $0.riskAssessment.overallRiskLevel == .high || $0.riskAssessment.overallRiskLevel == .critical }
    }
}

// MARK: - Supporting Enums

public enum DirectoryTab: String, CaseIterable {
    case employees = "employees"
    case vendors = "vendors"
    case analytics = "analytics"
    
    public var displayName: String {
        switch self {
        case .employees: return "Employees"
        case .vendors: return "Vendors"
        case .analytics: return "Analytics"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .employees: return "person.3.fill"
        case .vendors: return "building.2.fill"
        case .analytics: return "chart.bar.fill"
        }
    }
}

