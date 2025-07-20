import Foundation
import CloudKit
import Combine
import SwiftUI

// MARK: - VendorPerformance ViewModel
@MainActor
class VendorPerformanceViewModel: ObservableObject {
    @Published var performances: [VendorPerformance] = []
    @Published var selectedPerformance: VendorPerformance?
    @Published var topPerformers: [VendorPerformance] = []
    @Published var underperformers: [VendorPerformance] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var selectedVendor: String?
    @Published var selectedStore: String?
    @Published var selectedPeriod: VendorPerformance.ReportingPeriod?
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private let repository: VendorPerformanceRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for reactive filtering
    var filteredPerformances: [VendorPerformance] {
        var filtered = performances
        
        if !searchText.isEmpty {
            filtered = filtered.filter { performance in
                performance.vendorName.localizedCaseInsensitiveContains(searchText) ||
                performance.storeCode.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let vendor = selectedVendor {
            filtered = filtered.filter { $0.vendorId == vendor }
        }
        
        if let store = selectedStore {
            filtered = filtered.filter { $0.storeCode == store }
        }
        
        if let period = selectedPeriod {
            filtered = filtered.filter { $0.reportingPeriod == period }
        }
        
        return filtered
    }
    
    var performancesByVendor: [String: [VendorPerformance]] {
        Dictionary(grouping: filteredPerformances) { $0.vendorId }
    }
    
    var performancesByGrade: [VendorPerformance.PerformanceGrade: [VendorPerformance]] {
        Dictionary(grouping: filteredPerformances) { $0.grade }
    }
    
    var averageScore: Double {
        guard !filteredPerformances.isEmpty else { return 0 }
        return filteredPerformances.reduce(0) { $0 + $1.percentageScore } / Double(filteredPerformances.count)
    }
    
    init(repository: VendorPerformanceRepositoryProtocol = PerformanceRepositoryFactory.makeVendorPerformanceRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadPerformances() {
        isLoading = true
        error = nil
        
        Task {
            do {
                performances = try await repository.fetchAll()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadCurrentPeriodPerformances() {
        isLoading = true
        error = nil
        
        Task {
            do {
                performances = try await repository.fetchCurrentPeriod()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadTopPerformers() {
        Task {
            do {
                topPerformers = try await repository.fetchTopPerformers(limit: 10)
            } catch {
                self.error = error
            }
        }
    }
    
    func loadUnderperformers() {
        Task {
            do {
                underperformers = try await repository.fetchUnderperformers()
            } catch {
                self.error = error
            }
        }
    }
    
    func loadPerformances(for vendorId: String) {
        Task {
            do {
                let vendorPerformances = try await repository.fetchByVendor(vendorId)
                performances = vendorPerformances
            } catch {
                self.error = error
            }
        }
    }
    
    func loadPerformances(for storeCode: String) {
        Task {
            do {
                let storePerformances = try await repository.fetchByStore(storeCode)
                performances = storePerformances
            } catch {
                self.error = error
            }
        }
    }
    
    func loadPerformances(for period: VendorPerformance.ReportingPeriod, year: Int) {
        Task {
            do {
                let periodPerformances = try await repository.fetchByPeriod(period, year: year)
                performances = periodPerformances
            } catch {
                self.error = error
            }
        }
    }
    
    func savePerformance(_ performance: VendorPerformance) {
        Task {
            do {
                let savedPerformance = try await repository.save(performance)
                if let index = performances.firstIndex(where: { $0.id == savedPerformance.id }) {
                    performances[index] = savedPerformance
                } else {
                    performances.append(savedPerformance)
                }
                
                if selectedPerformance?.id == savedPerformance.id {
                    selectedPerformance = savedPerformance
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func deletePerformance(_ performance: VendorPerformance) {
        Task {
            do {
                try await repository.delete(performance)
                performances.removeAll { $0.id == performance.id }
                topPerformers.removeAll { $0.id == performance.id }
                underperformers.removeAll { $0.id == performance.id }
                
                if selectedPerformance?.id == performance.id {
                    selectedPerformance = nil
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func selectPerformance(_ performance: VendorPerformance) {
        selectedPerformance = performance
    }
    
    func clearSelection() {
        selectedPerformance = nil
    }
    
    func clearFilters() {
        searchText = ""
        selectedVendor = nil
        selectedStore = nil
        selectedPeriod = nil
        selectedYear = Calendar.current.component(.year, from: Date())
    }
}

// MARK: - CategoryPerformance ViewModel
@MainActor
class CategoryPerformanceViewModel: ObservableObject {
    @Published var performances: [CategoryPerformance] = []
    @Published var selectedPerformance: CategoryPerformance?
    @Published var topCategories: [CategoryPerformance] = []
    @Published var underperformingCategories: [CategoryPerformance] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var selectedStore: String?
    @Published var selectedPeriod: CategoryPerformance.ReportingPeriod?
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private let repository: CategoryPerformanceRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for reactive filtering
    var filteredPerformances: [CategoryPerformance] {
        var filtered = performances
        
        if !searchText.isEmpty {
            filtered = filtered.filter { performance in
                performance.categoryName.localizedCaseInsensitiveContains(searchText) ||
                performance.storeCode.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryId == category }
        }
        
        if let store = selectedStore {
            filtered = filtered.filter { $0.storeCode == store }
        }
        
        if let period = selectedPeriod {
            filtered = filtered.filter { $0.reportingPeriod == period }
        }
        
        return filtered
    }
    
    var performancesByCategory: [String: [CategoryPerformance]] {
        Dictionary(grouping: filteredPerformances) { $0.categoryId }
    }
    
    var performancesByGrade: [CategoryPerformance.PerformanceAnalysis.PerformanceGrade: [CategoryPerformance]] {
        Dictionary(grouping: filteredPerformances) { $0.performance.categoryGrade }
    }
    
    var averageScore: Double {
        guard !filteredPerformances.isEmpty else { return 0 }
        return filteredPerformances.reduce(0) { $0 + $1.performance.overallScore } / Double(filteredPerformances.count)
    }
    
    var totalRevenue: Decimal {
        return filteredPerformances.reduce(0) { $0 + $1.metrics.sales.totalRevenue }
    }
    
    init(repository: CategoryPerformanceRepositoryProtocol = PerformanceRepositoryFactory.makeCategoryPerformanceRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadPerformances() {
        isLoading = true
        error = nil
        
        Task {
            do {
                performances = try await repository.fetchAll()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadCurrentPeriodPerformances() {
        isLoading = true
        error = nil
        
        Task {
            do {
                performances = try await repository.fetchCurrentPeriod()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadTopPerformingCategories() {
        Task {
            do {
                topCategories = try await repository.fetchTopPerformingCategories(limit: 10)
            } catch {
                self.error = error
            }
        }
    }
    
    func loadUnderperformingCategories() {
        Task {
            do {
                underperformingCategories = try await repository.fetchUnderperformingCategories()
            } catch {
                self.error = error
            }
        }
    }
    
    func loadPerformances(for categoryId: String) {
        Task {
            do {
                let categoryPerformances = try await repository.fetchByCategory(categoryId)
                performances = categoryPerformances
            } catch {
                self.error = error
            }
        }
    }
    
    func loadPerformances(for storeCode: String) {
        Task {
            do {
                let storePerformances = try await repository.fetchByStore(storeCode)
                performances = storePerformances
            } catch {
                self.error = error
            }
        }
    }
    
    func loadPerformances(for period: CategoryPerformance.ReportingPeriod, year: Int) {
        Task {
            do {
                let periodPerformances = try await repository.fetchByPeriod(period, year: year)
                performances = periodPerformances
            } catch {
                self.error = error
            }
        }
    }
    
    func savePerformance(_ performance: CategoryPerformance) {
        Task {
            do {
                let savedPerformance = try await repository.save(performance)
                if let index = performances.firstIndex(where: { $0.id == savedPerformance.id }) {
                    performances[index] = savedPerformance
                } else {
                    performances.append(savedPerformance)
                }
                
                if selectedPerformance?.id == savedPerformance.id {
                    selectedPerformance = savedPerformance
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func deletePerformance(_ performance: CategoryPerformance) {
        Task {
            do {
                try await repository.delete(performance)
                performances.removeAll { $0.id == performance.id }
                topCategories.removeAll { $0.id == performance.id }
                underperformingCategories.removeAll { $0.id == performance.id }
                
                if selectedPerformance?.id == performance.id {
                    selectedPerformance = nil
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func selectPerformance(_ performance: CategoryPerformance) {
        selectedPerformance = performance
    }
    
    func clearSelection() {
        selectedPerformance = nil
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedStore = nil
        selectedPeriod = nil
        selectedYear = Calendar.current.component(.year, from: Date())
    }
}

// MARK: - SalesTarget ViewModel
@MainActor
class SalesTargetViewModel: ObservableObject {
    @Published var targets: [SalesTarget] = []
    @Published var activeTargets: [SalesTarget] = []
    @Published var overdueTargets: [SalesTarget] = []
    @Published var selectedTarget: SalesTarget?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var selectedStatus: SalesTarget.TargetStatus?
    @Published var selectedType: SalesTarget.TargetType?
    @Published var selectedStore: String?
    @Published var selectedPeriod: SalesTarget.TargetPeriod?
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private let repository: SalesTargetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for reactive filtering
    var filteredTargets: [SalesTarget] {
        var filtered = targets
        
        if !searchText.isEmpty {
            filtered = filtered.filter { target in
                target.targetName.localizedCaseInsensitiveContains(searchText) ||
                target.storeCode?.localizedCaseInsensitiveContains(searchText) == true ||
                target.employeeName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        if let type = selectedType {
            filtered = filtered.filter { $0.targetType == type }
        }
        
        if let store = selectedStore {
            filtered = filtered.filter { $0.storeCode == store }
        }
        
        if let period = selectedPeriod {
            filtered = filtered.filter { $0.period == period }
        }
        
        return filtered
    }
    
    var targetsByType: [SalesTarget.TargetType: [SalesTarget]] {
        Dictionary(grouping: filteredTargets) { $0.targetType }
    }
    
    var targetsByStatus: [SalesTarget.TargetStatus: [SalesTarget]] {
        Dictionary(grouping: filteredTargets) { $0.status }
    }
    
    var onTrackTargets: [SalesTarget] {
        return filteredTargets.filter { $0.isOnTrack }
    }
    
    var atRiskTargets: [SalesTarget] {
        return filteredTargets.filter { 
            $0.achievements.achievementStatus == .atRisk || 
            $0.achievements.achievementStatus == .behindTarget 
        }
    }
    
    var achievementRate: Double {
        guard !filteredTargets.isEmpty else { return 0 }
        let achieved = filteredTargets.filter { $0.achievements.achievementPercentage >= 100 }.count
        return (Double(achieved) / Double(filteredTargets.count)) * 100
    }
    
    init(repository: SalesTargetRepositoryProtocol = PerformanceRepositoryFactory.makeSalesTargetRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadTargets() {
        isLoading = true
        error = nil
        
        Task {
            do {
                targets = try await repository.fetchAll()
                activeTargets = try await repository.fetchActive()
                overdueTargets = try await repository.fetchOverdueTargets()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadActiveTargets() {
        Task {
            do {
                activeTargets = try await repository.fetchActive()
            } catch {
                self.error = error
            }
        }
    }
    
    func loadCurrentTargets() {
        isLoading = true
        error = nil
        
        Task {
            do {
                targets = try await repository.fetchCurrentTargets()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadOverdueTargets() {
        Task {
            do {
                overdueTargets = try await repository.fetchOverdueTargets()
            } catch {
                self.error = error
            }
        }
    }
    
    func loadTargets(for storeCode: String) {
        Task {
            do {
                let storeTargets = try await repository.fetchByStore(storeCode)
                targets = storeTargets
            } catch {
                self.error = error
            }
        }
    }
    
    func loadTargets(for employee: CKRecord.Reference) {
        Task {
            do {
                let employeeTargets = try await repository.fetchByEmployee(employee)
                targets = employeeTargets
            } catch {
                self.error = error
            }
        }
    }
    
    func loadTargets(for period: SalesTarget.TargetPeriod, year: Int) {
        Task {
            do {
                let periodTargets = try await repository.fetchByPeriod(period, year: year)
                targets = periodTargets
            } catch {
                self.error = error
            }
        }
    }
    
    func createTarget(_ target: SalesTarget) {
        Task {
            do {
                let savedTarget = try await repository.save(target)
                targets.append(savedTarget)
                
                if savedTarget.status.isActive {
                    activeTargets.append(savedTarget)
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func updateTarget(_ target: SalesTarget) {
        Task {
            do {
                let updatedTarget = try await repository.save(target)
                if let index = targets.firstIndex(where: { $0.id == updatedTarget.id }) {
                    targets[index] = updatedTarget
                }
                
                if let index = activeTargets.firstIndex(where: { $0.id == updatedTarget.id }) {
                    if updatedTarget.status.isActive {
                        activeTargets[index] = updatedTarget
                    } else {
                        activeTargets.remove(at: index)
                    }
                }
                
                if selectedTarget?.id == updatedTarget.id {
                    selectedTarget = updatedTarget
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func updateTargetAchievement(_ target: SalesTarget, currentValue: Double) {
        Task {
            do {
                let updatedTarget = try await repository.updateAchievement(target, currentValue: currentValue)
                if let index = targets.firstIndex(where: { $0.id == updatedTarget.id }) {
                    targets[index] = updatedTarget
                }
                
                if let index = activeTargets.firstIndex(where: { $0.id == updatedTarget.id }) {
                    activeTargets[index] = updatedTarget
                }
                
                if selectedTarget?.id == updatedTarget.id {
                    selectedTarget = updatedTarget
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func deleteTarget(_ target: SalesTarget) {
        Task {
            do {
                try await repository.delete(target)
                targets.removeAll { $0.id == target.id }
                activeTargets.removeAll { $0.id == target.id }
                overdueTargets.removeAll { $0.id == target.id }
                
                if selectedTarget?.id == target.id {
                    selectedTarget = nil
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func selectTarget(_ target: SalesTarget) {
        selectedTarget = target
    }
    
    func clearSelection() {
        selectedTarget = nil
    }
    
    func clearFilters() {
        searchText = ""
        selectedStatus = nil
        selectedType = nil
        selectedStore = nil
        selectedPeriod = nil
        selectedYear = Calendar.current.component(.year, from: Date())
    }
    
    // Helper methods for analytics
    func averageAchievementPercentage(for storeCode: String) -> Double {
        let storeTargets = targets.filter { $0.storeCode == storeCode }
        guard !storeTargets.isEmpty else { return 0 }
        
        let totalAchievement = storeTargets.reduce(0) { $0 + $1.achievements.achievementPercentage }
        return totalAchievement / Double(storeTargets.count)
    }
    
    func targetsNeedingAttention() -> [SalesTarget] {
        return targets.filter { target in
            target.achievements.achievementStatus == .atRisk ||
            target.achievements.achievementStatus == .behindTarget ||
            target.isOverdue
        }
    }
    
    func upcomingDeadlines(within days: Int = 7) -> [SalesTarget] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return activeTargets.filter { target in
            target.endDate >= Date() && target.endDate <= futureDate
        }
    }
}
