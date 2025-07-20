import Foundation
import Combine
import SwiftUI

// MARK: - Reporting View Model

@MainActor
public final class ReportingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let reportingService: ReportingService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published public var selectedTab: ReportingTab = .reports
    @Published public var searchText = ""
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // MARK: - Report Properties
    @Published public var reports: [Report] = []
    @Published public var filteredReports: [Report] = []
    @Published public var selectedReport: Report?
    @Published public var reportFilters = ReportFilterOptions()
    @Published public var showingCreateReport = false
    @Published public var showingReportFilters = false
    @Published public var showingReportEditor = false
    
    // MARK: - Dashboard Properties
    @Published public var dashboards: [Dashboard] = []
    @Published public var filteredDashboards: [Dashboard] = []
    @Published public var selectedDashboard: Dashboard?
    @Published public var showingCreateDashboard = false
    @Published public var showingDashboardEditor = false
    
    // MARK: - Analytics Properties
    @Published public var reportAnalytics: ReportAnalytics?
    @Published public var showingAnalyticsDetails = false
    
    // MARK: - Report Generation Properties
    @Published public var currentReportData: [[String: Any]] = []
    @Published public var isGeneratingReport = false
    @Published public var reportGenerationProgress: Double = 0.0
    @Published public var showingReportViewer = false
    
    // MARK: - Export Properties
    @Published public var showingExportOptions = false
    @Published public var selectedExportFormat: ExportFormat = .pdf
    @Published public var isExporting = false
    @Published public var exportProgress: Double = 0.0
    
    // MARK: - UI State
    @Published public var showingReportScheduler = false
    @Published public var showingPermissionsEditor = false
    @Published public var selectedReportIds: Set<UUID> = []
    @Published public var bulkActionType: ReportBulkActionType?
    @Published public var showingBulkActions = false
    
    // MARK: - Report Builder Properties
    @Published public var reportBuilder = ReportBuilder()
    @Published public var showingReportBuilder = false
    @Published public var builderStep: ReportBuilderStep = .dataSource
    
    // MARK: - Initialization
    
    public init(reportingService: ReportingService = ReportingService.shared) {
        self.reportingService = reportingService
        setupBindings()
        setupSearchAndFiltering()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind service properties to view model
        reportingService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        reportingService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$error)
        
        reportingService.$reports
            .receive(on: DispatchQueue.main)
            .assign(to: &$reports)
        
        reportingService.$dashboards
            .receive(on: DispatchQueue.main)
            .assign(to: &$dashboards)
    }
    
    private func setupSearchAndFiltering() {
        // Setup reactive search and filtering for reports
        Publishers.CombineLatest3($reports, $searchText, $reportFilters)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] reports, searchText, filters in
                Task { @MainActor in
                    await self?.updateFilteredReports(reports: reports, searchText: searchText, filters: filters)
                }
            }
            .store(in: &cancellables)
        
        // Setup reactive search for dashboards
        Publishers.CombineLatest($dashboards, $searchText)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] dashboards, searchText in
                Task { @MainActor in
                    await self?.updateFilteredDashboards(dashboards: dashboards, searchText: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredReports(reports: [Report], searchText: String, filters: ReportFilterOptions) async {
        var filtered = reports
        
        // Apply search filter
        if !searchText.isEmpty {
            do {
                filtered = try await reportingService.searchReports(searchText)
            } catch {
                print("❌ Search error: \(error)")
            }
        }
        
        // Apply category filter
        if let category = filters.selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply type filter
        if let type = filters.selectedType {
            filtered = filtered.filter { $0.reportType == type }
        }
        
        // Apply visibility filter
        if let isPublic = filters.isPublic {
            filtered = filtered.filter { $0.isPublic == isPublic }
        }
        
        // Apply date range filter
        if let dateRange = filters.dateRange {
            filtered = filtered.filter { report in
                report.createdAt >= dateRange.start && report.createdAt <= dateRange.end
            }
        }
        
        filteredReports = filtered
    }
    
    private func updateFilteredDashboards(dashboards: [Dashboard], searchText: String) async {
        var filtered = dashboards
        
        // Apply search filter for dashboards
        if !searchText.isEmpty {
            let searchTerms = searchText.lowercased()
            filtered = dashboards.filter { dashboard in
                dashboard.name.lowercased().contains(searchTerms) ||
                dashboard.description?.lowercased().contains(searchTerms) == true
            }
        }
        
        filteredDashboards = filtered
    }
    
    // MARK: - Data Loading
    
    public func loadData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.loadReports()
            }
            
            group.addTask { [weak self] in
                await self?.loadDashboards()
            }
        }
    }
    
    public func refreshData() async {
        await loadData()
        await loadAnalytics()
    }
    
    private func loadReports() async {
        do {
            _ = try await reportingService.fetchReports()
        } catch {
            self.error = error
        }
    }
    
    private func loadDashboards() async {
        do {
            _ = try await reportingService.fetchDashboards()
        } catch {
            self.error = error
        }
    }
    
    public func loadAnalytics() async {
        do {
            reportAnalytics = try await reportingService.generateReportAnalytics()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Report Operations
    
    public func createReport(_ report: Report) async {
        do {
            _ = try await reportingService.createReport(report)
            showingCreateReport = false
            showingReportBuilder = false
            resetReportBuilder()
        } catch {
            self.error = error
        }
    }
    
    public func updateReport(_ report: Report) async {
        do {
            _ = try await reportingService.updateReport(report)
        } catch {
            self.error = error
        }
    }
    
    public func deleteReport(_ report: Report) async {
        do {
            try await reportingService.deleteReport(report)
            selectedReport = nil
        } catch {
            self.error = error
        }
    }
    
    public func duplicateReport(_ report: Report) async {
        do {
            let duplicatedReport = try await reportingService.duplicateReport(report)
            selectedReport = duplicatedReport
        } catch {
            self.error = error
        }
    }
    
    public func selectReport(_ report: Report) {
        selectedReport = report
    }
    
    // MARK: - Dashboard Operations
    
    public func createDashboard(_ dashboard: Dashboard) async {
        do {
            _ = try await reportingService.createDashboard(dashboard)
            showingCreateDashboard = false
        } catch {
            self.error = error
        }
    }
    
    public func updateDashboard(_ dashboard: Dashboard) async {
        do {
            _ = try await reportingService.updateDashboard(dashboard)
        } catch {
            self.error = error
        }
    }
    
    public func deleteDashboard(_ dashboard: Dashboard) async {
        do {
            try await reportingService.deleteDashboard(dashboard)
            selectedDashboard = nil
        } catch {
            self.error = error
        }
    }
    
    public func selectDashboard(_ dashboard: Dashboard) {
        selectedDashboard = dashboard
    }
    
    // MARK: - Report Generation
    
    public func generateReport(_ report: Report) async {
        isGeneratingReport = true
        reportGenerationProgress = 0.0
        
        // Simulate progress
        withAnimation(.linear(duration: 2.0)) {
            reportGenerationProgress = 0.5
        }
        
        do {
            let data = try await reportingService.generateReport(report)
            currentReportData = data
            
            withAnimation(.linear(duration: 0.5)) {
                reportGenerationProgress = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isGeneratingReport = false
                self.showingReportViewer = true
                self.reportGenerationProgress = 0.0
            }
        } catch {
            isGeneratingReport = false
            reportGenerationProgress = 0.0
            self.error = error
        }
    }
    
    public func refreshReport(_ report: Report) async {
        // Clear cache for this report
        await generateReport(report)
    }
    
    // MARK: - Export Operations
    
    public func exportReport(_ report: Report, format: ExportFormat) async {
        isExporting = true
        exportProgress = 0.0
        
        // Simulate progress
        withAnimation(.linear(duration: 1.5)) {
            exportProgress = 0.8
        }
        
        do {
            let url = try await reportingService.exportReport(report, format: format)
            
            withAnimation(.linear(duration: 0.3)) {
                exportProgress = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isExporting = false
                self.exportProgress = 0.0
                self.showingExportOptions = false
                
                // In a real app, this would present a share sheet
                print("✅ Report exported to: \(url.lastPathComponent)")
            }
        } catch {
            isExporting = false
            exportProgress = 0.0
            self.error = error
        }
    }
    
    // MARK: - Bulk Operations
    
    public func performBulkAction(_ actionType: ReportBulkActionType) async {
        guard !selectedReportIds.isEmpty else { return }
        
        switch actionType {
        case .delete:
            for reportId in selectedReportIds {
                if let report = reports.first(where: { $0.id == reportId }) {
                    await deleteReport(report)
                }
            }
            
        case .makePublic:
            for reportId in selectedReportIds {
                if let report = reports.first(where: { $0.id == reportId }) {
                    var updatedReport = report
                    updatedReport.isPublic = true
                    await updateReport(updatedReport)
                }
            }
            
        case .makePrivate:
            for reportId in selectedReportIds {
                if let report = reports.first(where: { $0.id == reportId }) {
                    var updatedReport = report
                    updatedReport.isPublic = false
                    await updateReport(updatedReport)
                }
            }
            
        case .duplicate:
            for reportId in selectedReportIds {
                if let report = reports.first(where: { $0.id == reportId }) {
                    await duplicateReport(report)
                }
            }
        }
        
        selectedReportIds.removeAll()
        showingBulkActions = false
    }
    
    public func toggleReportSelection(_ reportId: UUID) {
        if selectedReportIds.contains(reportId) {
            selectedReportIds.remove(reportId)
        } else {
            selectedReportIds.insert(reportId)
        }
    }
    
    public func selectAllReports() {
        selectedReportIds = Set(filteredReports.map { $0.id })
    }
    
    public func deselectAllReports() {
        selectedReportIds.removeAll()
    }
    
    // MARK: - Report Builder
    
    public func startReportBuilder() {
        resetReportBuilder()
        showingReportBuilder = true
        builderStep = .dataSource
    }
    
    public func nextBuilderStep() {
        switch builderStep {
        case .dataSource:
            builderStep = .filters
        case .filters:
            builderStep = .visualizations
        case .visualizations:
            builderStep = .settings
        case .settings:
            builderStep = .preview
        case .preview:
            break
        }
    }
    
    public func previousBuilderStep() {
        switch builderStep {
        case .dataSource:
            break
        case .filters:
            builderStep = .dataSource
        case .visualizations:
            builderStep = .filters
        case .settings:
            builderStep = .visualizations
        case .preview:
            builderStep = .settings
        }
    }
    
    public func finishReportBuilder() async {
        let newReport = reportBuilder.buildReport()
        await createReport(newReport)
    }
    
    private func resetReportBuilder() {
        reportBuilder = ReportBuilder()
        builderStep = .dataSource
    }
    
    // MARK: - Filter Management
    
    public func updateReportFilters(_ filters: ReportFilterOptions) {
        reportFilters = filters
    }
    
    public func clearReportFilters() {
        reportFilters = ReportFilterOptions()
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
    
    // MARK: - Computed Properties
    
    public var totalReports: Int {
        reports.count
    }
    
    public var publicReports: Int {
        reports.filter { $0.isPublic }.count
    }
    
    public var privateReports: Int {
        reports.filter { !$0.isPublic }.count
    }
    
    public var recentReports: [Report] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        
        return reports.filter { $0.createdAt >= oneWeekAgo }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { $0 }
    }
    
    public var reportsByCategory: [ReportCategory: [Report]] {
        Dictionary(grouping: reports, by: { $0.category })
    }
    
    public var reportsByType: [ReportType: [Report]] {
        Dictionary(grouping: reports, by: { $0.reportType })
    }
    
    public var canCreateReport: Bool {
        // Add any business logic for report creation permissions
        return true
    }
    
    public var canCreateDashboard: Bool {
        // Add any business logic for dashboard creation permissions
        return true
    }
}

// MARK: - Supporting Types

public enum ReportingTab: String, CaseIterable {
    case reports = "reports"
    case dashboards = "dashboards"
    case analytics = "analytics"
    case builder = "builder"
    
    public var displayName: String {
        switch self {
        case .reports: return "Reports"
        case .dashboards: return "Dashboards"
        case .analytics: return "Analytics"
        case .builder: return "Builder"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .reports: return "doc.text"
        case .dashboards: return "rectangle.3.group"
        case .analytics: return "chart.bar"
        case .builder: return "wrench.and.screwdriver"
        }
    }
}

public struct ReportFilterOptions {
    public var selectedCategory: ReportCategory?
    public var selectedType: ReportType?
    public var isPublic: Bool?
    public var dateRange: DateRange?
    public var createdBy: UUID?
    
    public init(
        selectedCategory: ReportCategory? = nil,
        selectedType: ReportType? = nil,
        isPublic: Bool? = nil,
        dateRange: DateRange? = nil,
        createdBy: UUID? = nil
    ) {
        self.selectedCategory = selectedCategory
        self.selectedType = selectedType
        self.isPublic = isPublic
        self.dateRange = dateRange
        self.createdBy = createdBy
    }
    
    public var isEmpty: Bool {
        return selectedCategory == nil &&
               selectedType == nil &&
               isPublic == nil &&
               dateRange == nil &&
               createdBy == nil
    }
}

public enum ReportBulkActionType: String, CaseIterable {
    case delete = "delete"
    case makePublic = "make_public"
    case makePrivate = "make_private"
    case duplicate = "duplicate"
    
    public var displayName: String {
        switch self {
        case .delete: return "Delete"
        case .makePublic: return "Make Public"
        case .makePrivate: return "Make Private"
        case .duplicate: return "Duplicate"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .delete: return "trash"
        case .makePublic: return "globe"
        case .makePrivate: return "lock"
        case .duplicate: return "doc.on.doc"
        }
    }
    
    public var isDestructive: Bool {
        return self == .delete
    }
}

// MARK: - Report Builder

public class ReportBuilder: ObservableObject {
    @Published public var reportName: String = ""
    @Published public var reportDescription: String = ""
    @Published public var selectedCategory: ReportCategory = .financial
    @Published public var selectedType: ReportType = .tabular
    @Published public var selectedDataSource: DataSource = .invoices
    @Published public var filters: ReportFilters = ReportFilters()
    @Published public var visualizations: [ReportVisualization] = []
    @Published public var permissions: ReportPermissions = ReportPermissions()
    @Published public var schedule: ReportSchedule?
    @Published public var isPublic: Bool = false
    
    public init() {}
    
    public func buildReport() -> Report {
        return Report(
            reportName: reportName.isEmpty ? "Untitled Report" : reportName,
            reportDescription: reportDescription.isEmpty ? nil : reportDescription,
            reportType: selectedType,
            category: selectedCategory,
            dataSource: selectedDataSource,
            filters: filters,
            visualizations: visualizations,
            schedule: schedule,
            permissions: permissions,
            createdBy: UUID(), // Would use current user ID
            isPublic: isPublic
        )
    }
    
    public func reset() {
        reportName = ""
        reportDescription = ""
        selectedCategory = .financial
        selectedType = .tabular
        selectedDataSource = .invoices
        filters = ReportFilters()
        visualizations = []
        permissions = ReportPermissions()
        schedule = nil
        isPublic = false
    }
    
    public var isValid: Bool {
        return !reportName.isEmpty
    }
}

public enum ReportBuilderStep: String, CaseIterable {
    case dataSource = "data_source"
    case filters = "filters"
    case visualizations = "visualizations"
    case settings = "settings"
    case preview = "preview"
    
    public var displayName: String {
        switch self {
        case .dataSource: return "Data Source"
        case .filters: return "Filters"
        case .visualizations: return "Visualizations"
        case .settings: return "Settings"
        case .preview: return "Preview"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .dataSource: return "cylinder"
        case .filters: return "line.3.horizontal.decrease"
        case .visualizations: return "chart.bar"
        case .settings: return "gear"
        case .preview: return "eye"
        }
    }
    
    public var stepNumber: Int {
        switch self {
        case .dataSource: return 1
        case .filters: return 2
        case .visualizations: return 3
        case .settings: return 4
        case .preview: return 5
        }
    }
}

// MARK: - Dashboard Builder

public class DashboardBuilder: ObservableObject {
    @Published public var dashboardName: String = ""
    @Published public var dashboardDescription: String = ""
    @Published public var widgets: [DashboardWidget] = []
    @Published public var layout: DashboardLayout = DashboardLayout()
    @Published public var permissions: ReportPermissions = ReportPermissions()
    @Published public var refreshInterval: TimeInterval?
    @Published public var isDefault: Bool = false
    
    public init() {}
    
    public func buildDashboard() -> Dashboard {
        return Dashboard(
            name: dashboardName.isEmpty ? "Untitled Dashboard" : dashboardName,
            description: dashboardDescription.isEmpty ? nil : dashboardDescription,
            widgets: widgets,
            layout: layout,
            refreshInterval: refreshInterval,
            permissions: permissions,
            isDefault: isDefault,
            createdBy: UUID() // Would use current user ID
        )
    }
    
    public func addWidget(_ widget: DashboardWidget) {
        widgets.append(widget)
    }
    
    public func removeWidget(_ widgetId: UUID) {
        widgets.removeAll { $0.id == widgetId }
    }
    
    public func updateWidget(_ widget: DashboardWidget) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index] = widget
        }
    }
    
    public func reset() {
        dashboardName = ""
        dashboardDescription = ""
        widgets = []
        layout = DashboardLayout()
        permissions = ReportPermissions()
        refreshInterval = nil
        isDefault = false
    }
    
    public var isValid: Bool {
        return !dashboardName.isEmpty
    }
}

// MARK: - Extensions

extension ReportFilterOptions: Equatable {
    public static func == (lhs: ReportFilterOptions, rhs: ReportFilterOptions) -> Bool {
        return lhs.selectedCategory == rhs.selectedCategory &&
               lhs.selectedType == rhs.selectedType &&
               lhs.isPublic == rhs.isPublic &&
               lhs.dateRange?.start == rhs.dateRange?.start &&
               lhs.dateRange?.end == rhs.dateRange?.end &&
               lhs.createdBy == rhs.createdBy
    }
}

extension Report {
    public var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    public var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
    
    public var isRecent: Bool {
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return createdAt >= oneWeekAgo
    }
    
    public var statusDescription: String {
        if !isActive {
            return "Inactive"
        } else if metadata.lastGenerated == nil {
            return "Not Generated"
        } else {
            return "Active"
        }
    }
}

extension Dashboard {
    public var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    public var widgetCount: Int {
        return widgets.count
    }
    
    public var isRecent: Bool {
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return createdAt >= oneWeekAgo
    }
}
