import XCTest
import CloudKit
import Combine
@testable import DiamondDeskERP

// MARK: - Reporting Service Tests

final class ReportingServiceTests: XCTestCase {
    private var reportingService: ReportingService!
    private var mockContainer: CKContainer!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockContainer = CKContainer(identifier: "test.container")
        reportingService = ReportingService(container: mockContainer)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        reportingService = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Report CRUD Tests
    
    func testCreateReport() async throws {
        // Given
        let report = createSampleReport()
        
        // When
        let createdReport = try await reportingService.createReport(report)
        
        // Then
        XCTAssertEqual(createdReport.reportName, report.reportName)
        XCTAssertEqual(createdReport.category, report.category)
        XCTAssertEqual(createdReport.reportType, report.reportType)
        XCTAssertNotNil(createdReport.recordID)
    }
    
    func testFetchReports() async throws {
        // Given
        let report1 = createSampleReport(name: "Report 1")
        let report2 = createSampleReport(name: "Report 2")
        
        _ = try await reportingService.createReport(report1)
        _ = try await reportingService.createReport(report2)
        
        // When
        let fetchedReports = try await reportingService.fetchReports()
        
        // Then
        XCTAssertGreaterThanOrEqual(fetchedReports.count, 2)
        XCTAssertTrue(fetchedReports.contains { $0.reportName == "Report 1" })
        XCTAssertTrue(fetchedReports.contains { $0.reportName == "Report 2" })
    }
    
    func testUpdateReport() async throws {
        // Given
        let originalReport = createSampleReport()
        let createdReport = try await reportingService.createReport(originalReport)
        
        var updatedReport = createdReport
        updatedReport.reportName = "Updated Report"
        updatedReport.description = "Updated description"
        
        // When
        let result = try await reportingService.updateReport(updatedReport)
        
        // Then
        XCTAssertEqual(result.reportName, "Updated Report")
        XCTAssertEqual(result.description, "Updated description")
        XCTAssertGreaterThan(result.updatedAt, createdReport.updatedAt)
    }
    
    func testDeleteReport() async throws {
        // Given
        let report = createSampleReport()
        let createdReport = try await reportingService.createReport(report)
        
        // When
        try await reportingService.deleteReport(createdReport.id)
        
        // Then
        let fetchedReports = try await reportingService.fetchReports()
        XCTAssertFalse(fetchedReports.contains { $0.id == createdReport.id })
    }
    
    // MARK: - Dashboard CRUD Tests
    
    func testCreateDashboard() async throws {
        // Given
        let dashboard = createSampleDashboard()
        
        // When
        let createdDashboard = try await reportingService.createDashboard(dashboard)
        
        // Then
        XCTAssertEqual(createdDashboard.name, dashboard.name)
        XCTAssertEqual(createdDashboard.description, dashboard.description)
        XCTAssertNotNil(createdDashboard.recordID)
    }
    
    func testFetchDashboards() async throws {
        // Given
        let dashboard1 = createSampleDashboard(name: "Dashboard 1")
        let dashboard2 = createSampleDashboard(name: "Dashboard 2")
        
        _ = try await reportingService.createDashboard(dashboard1)
        _ = try await reportingService.createDashboard(dashboard2)
        
        // When
        let fetchedDashboards = try await reportingService.fetchDashboards()
        
        // Then
        XCTAssertGreaterThanOrEqual(fetchedDashboards.count, 2)
        XCTAssertTrue(fetchedDashboards.contains { $0.name == "Dashboard 1" })
        XCTAssertTrue(fetchedDashboards.contains { $0.name == "Dashboard 2" })
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateReportData() async throws {
        // Given
        let report = createSampleReport()
        let createdReport = try await reportingService.createReport(report)
        
        // When
        let reportData = try await reportingService.generateReportData(for: createdReport)
        
        // Then
        XCTAssertNotNil(reportData)
        XCTAssertFalse(reportData.dataPoints.isEmpty)
        XCTAssertFalse(reportData.summaryStats.isEmpty)
    }
    
    func testGenerateReportWithFilters() async throws {
        // Given
        let report = createSampleReportWithFilters()
        let createdReport = try await reportingService.createReport(report)
        
        // When
        let reportData = try await reportingService.generateReportData(for: createdReport)
        
        // Then
        XCTAssertNotNil(reportData)
        // Verify that filters were applied
        XCTAssertTrue(reportData.dataPoints.count <= 100) // Assuming filter limits results
    }
    
    // MARK: - Export Tests
    
    func testExportReportAsPDF() async throws {
        // Given
        let report = createSampleReport()
        let createdReport = try await reportingService.createReport(report)
        let reportData = try await reportingService.generateReportData(for: createdReport)
        
        // When
        let exportData = try await reportingService.exportReport(
            createdReport,
            data: reportData,
            format: .pdf
        )
        
        // Then
        XCTAssertNotNil(exportData)
        XCTAssertFalse(exportData.isEmpty)
    }
    
    func testExportReportAsExcel() async throws {
        // Given
        let report = createSampleReport()
        let createdReport = try await reportingService.createReport(report)
        let reportData = try await reportingService.generateReportData(for: createdReport)
        
        // When
        let exportData = try await reportingService.exportReport(
            createdReport,
            data: reportData,
            format: .excel
        )
        
        // Then
        XCTAssertNotNil(exportData)
        XCTAssertFalse(exportData.isEmpty)
    }
    
    func testExportReportAsCSV() async throws {
        // Given
        let report = createSampleReport()
        let createdReport = try await reportingService.createReport(report)
        let reportData = try await reportingService.generateReportData(for: createdReport)
        
        // When
        let exportData = try await reportingService.exportReport(
            createdReport,
            data: reportData,
            format: .csv
        )
        
        // Then
        XCTAssertNotNil(exportData)
        XCTAssertFalse(exportData.isEmpty)
        
        // Verify CSV format
        let csvString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString!.contains(",")) // Should contain comma separators
    }
    
    // MARK: - Analytics Tests
    
    func testGenerateReportAnalytics() async throws {
        // Given
        let reports = [
            createSampleReport(name: "Sales Report 1", category: .sales),
            createSampleReport(name: "Finance Report 1", category: .financial),
            createSampleReport(name: "Sales Report 2", category: .sales, type: .dashboard)
        ]
        
        for report in reports {
            _ = try await reportingService.createReport(report)
        }
        
        // When
        let analytics = try await reportingService.generateReportAnalytics()
        
        // Then
        XCTAssertGreaterThanOrEqual(analytics.totalReports, 3)
        XCTAssertGreaterThanOrEqual(analytics.categoryCounts[.sales] ?? 0, 2)
        XCTAssertGreaterThanOrEqual(analytics.categoryCounts[.financial] ?? 0, 1)
        XCTAssertGreaterThanOrEqual(analytics.typeCounts[.standard] ?? 0, 2)
        XCTAssertGreaterThanOrEqual(analytics.typeCounts[.dashboard] ?? 0, 1)
    }
    
    // MARK: - Filtering Tests
    
    func testFilterReportsByCategory() async throws {
        // Given
        let salesReport = createSampleReport(category: .sales)
        let financeReport = createSampleReport(category: .financial)
        
        _ = try await reportingService.createReport(salesReport)
        _ = try await reportingService.createReport(financeReport)
        
        // When
        let salesReports = try await reportingService.fetchReports(category: .sales)
        
        // Then
        XCTAssertTrue(salesReports.allSatisfy { $0.category == .sales })
        XCTAssertFalse(salesReports.contains { $0.category == .financial })
    }
    
    func testFilterReportsByType() async throws {
        // Given
        let standardReport = createSampleReport(type: .standard)
        let dashboardReport = createSampleReport(type: .dashboard)
        
        _ = try await reportingService.createReport(standardReport)
        _ = try await reportingService.createReport(dashboardReport)
        
        // When
        let standardReports = try await reportingService.fetchReports(type: .standard)
        
        // Then
        XCTAssertTrue(standardReports.allSatisfy { $0.reportType == .standard })
        XCTAssertFalse(standardReports.contains { $0.reportType == .dashboard })
    }
    
    func testFilterReportsByActiveStatus() async throws {
        // Given
        let activeReport = createSampleReport(isActive: true)
        let inactiveReport = createSampleReport(isActive: false)
        
        _ = try await reportingService.createReport(activeReport)
        _ = try await reportingService.createReport(inactiveReport)
        
        // When
        let activeReports = try await reportingService.fetchReports(activeOnly: true)
        
        // Then
        XCTAssertTrue(activeReports.allSatisfy { $0.isActive })
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateReportWithInvalidData() async throws {
        // Given
        var invalidReport = createSampleReport()
        invalidReport.reportName = "" // Invalid empty name
        
        // When/Then
        do {
            _ = try await reportingService.createReport(invalidReport)
            XCTFail("Should have thrown validation error")
        } catch ReportingServiceError.validationError(let message) {
            XCTAssertTrue(message.contains("name"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testDeleteNonexistentReport() async throws {
        // Given
        let nonexistentID = UUID()
        
        // When/Then
        do {
            try await reportingService.deleteReport(nonexistentID)
            XCTFail("Should have thrown not found error")
        } catch ReportingServiceError.reportNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testFetchLargeNumberOfReports() async throws {
        // Given
        let reportCount = 100
        var reports: [Report] = []
        
        for i in 1...reportCount {
            reports.append(createSampleReport(name: "Report \(i)"))
        }
        
        // Create reports in batches to avoid timeout
        let batchSize = 10
        for batch in reports.chunked(into: batchSize) {
            await withTaskGroup(of: Void.self) { group in
                for report in batch {
                    group.addTask {
                        do {
                            _ = try await self.reportingService.createReport(report)
                        } catch {
                            XCTFail("Failed to create report: \(error)")
                        }
                    }
                }
            }
        }
        
        // When
        let startTime = Date()
        let fetchedReports = try await reportingService.fetchReports()
        let fetchTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertGreaterThanOrEqual(fetchedReports.count, reportCount)
        XCTAssertLessThan(fetchTime, 5.0) // Should complete within 5 seconds
    }
    
    // MARK: - Helper Methods
    
    private func createSampleReport(
        name: String = "Test Report",
        category: ReportCategory = .sales,
        type: ReportType = .standard,
        isActive: Bool = true
    ) -> Report {
        Report(
            id: UUID(),
            reportName: name,
            description: "Test report description",
            category: category,
            reportType: type,
            dataSource: .sales,
            dateRange: DateRange(
                start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                end: Date()
            ),
            filters: [],
            visualizations: [createSampleVisualization()],
            schedule: nil,
            isActive: isActive,
            isPublic: false,
            createdBy: "test-user",
            createdAt: Date(),
            updatedAt: Date(),
            metadata: ReportMetadata(
                version: 1,
                tags: ["test"],
                lastGenerated: nil,
                generationCount: 0,
                averageGenerationTime: 0,
                fileSize: 0,
                recordCount: 0
            )
        )
    }
    
    private func createSampleReportWithFilters() -> Report {
        var report = createSampleReport()
        report.filters = [
            ReportFilter(
                id: UUID(),
                field: "amount",
                operator: .greaterThan,
                value: "1000",
                dataType: .number
            )
        ]
        return report
    }
    
    private func createSampleVisualization() -> ReportVisualization {
        ReportVisualization(
            id: UUID(),
            title: "Test Chart",
            type: .bar,
            config: VisualizationConfig(
                xField: "date",
                yField: "amount",
                groupField: nil,
                colorScheme: "default",
                showLegend: true,
                showLabels: true
            )
        )
    }
    
    private func createSampleDashboard(name: String = "Test Dashboard") -> Dashboard {
        Dashboard(
            id: UUID(),
            name: name,
            description: "Test dashboard description",
            layout: DashboardLayout(
                columns: 2,
                spacing: 16,
                padding: 16
            ),
            widgets: [],
            isDefault: false,
            isPublic: false,
            createdBy: "test-user",
            createdAt: Date(),
            updatedAt: Date(),
            metadata: DashboardMetadata(
                version: 1,
                tags: ["test"],
                lastViewed: nil,
                viewCount: 0
            )
        )
    }
}

// MARK: - Reporting View Model Tests

final class ReportingViewModelTests: XCTestCase {
    private var viewModel: ReportingViewModel!
    private var mockReportingService: MockReportingService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockReportingService = MockReportingService()
        viewModel = ReportingViewModel(reportingService: mockReportingService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockReportingService = nil
        super.tearDown()
    }
    
    // MARK: - Loading Tests
    
    func testLoadData() async throws {
        // Given
        let sampleReports = [createSampleReport(), createSampleReport()]
        let sampleDashboards = [createSampleDashboard(), createSampleDashboard()]
        
        mockReportingService.mockReports = sampleReports
        mockReportingService.mockDashboards = sampleDashboards
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.reports.count, 2)
        XCTAssertEqual(viewModel.dashboards.count, 2)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadDataWithError() async throws {
        // Given
        mockReportingService.shouldThrowError = true
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchReports() async throws {
        // Given
        let reports = [
            createSampleReport(name: "Sales Report"),
            createSampleReport(name: "Finance Report"),
            createSampleReport(name: "Marketing Analysis")
        ]
        mockReportingService.mockReports = reports
        await viewModel.loadData()
        
        // When
        viewModel.searchText = "Sales"
        
        // Then
        XCTAssertEqual(viewModel.filteredReports.count, 1)
        XCTAssertEqual(viewModel.filteredReports.first?.reportName, "Sales Report")
    }
    
    func testFilterReportsByCategory() async throws {
        // Given
        let reports = [
            createSampleReport(category: .sales),
            createSampleReport(category: .financial),
            createSampleReport(category: .sales)
        ]
        mockReportingService.mockReports = reports
        await viewModel.loadData()
        
        // When
        viewModel.categoryFilter = .sales
        
        // Then
        XCTAssertEqual(viewModel.filteredReports.count, 2)
        XCTAssertTrue(viewModel.filteredReports.allSatisfy { $0.category == .sales })
    }
    
    func testFilterReportsByType() async throws {
        // Given
        let reports = [
            createSampleReport(type: .standard),
            createSampleReport(type: .dashboard),
            createSampleReport(type: .standard)
        ]
        mockReportingService.mockReports = reports
        await viewModel.loadData()
        
        // When
        viewModel.typeFilter = .standard
        
        // Then
        XCTAssertEqual(viewModel.filteredReports.count, 2)
        XCTAssertTrue(viewModel.filteredReports.allSatisfy { $0.reportType == .standard })
    }
    
    // MARK: - Report Builder Tests
    
    func testInitializeReportBuilder() {
        // When
        viewModel.initializeReportBuilder()
        
        // Then
        XCTAssertFalse(viewModel.reportBuilderName.isEmpty)
        XCTAssertNotNil(viewModel.reportBuilderCategory)
        XCTAssertNotNil(viewModel.reportBuilderType)
        XCTAssertNotNil(viewModel.reportBuilderDataSource)
    }
    
    func testReportBuilderValidation() {
        // Given
        viewModel.initializeReportBuilder()
        
        // When - Invalid state (empty name)
        viewModel.reportBuilderName = ""
        
        // Then
        XCTAssertFalse(viewModel.isBuilderValid)
        XCTAssertFalse(viewModel.builderValidationErrors.isEmpty)
    }
    
    func testCreateReportFromBuilder() async throws {
        // Given
        viewModel.initializeReportBuilder()
        viewModel.reportBuilderName = "Test Builder Report"
        viewModel.reportBuilderDescription = "Test description"
        viewModel.reportBuilderSelectedFields = ["field1", "field2"]
        
        // When
        await viewModel.createReportFromBuilder()
        
        // Then
        XCTAssertTrue(mockReportingService.createReportCalled)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Bulk Operations Tests
    
    func testSelectAllReports() async throws {
        // Given
        let reports = [createSampleReport(), createSampleReport(), createSampleReport()]
        mockReportingService.mockReports = reports
        await viewModel.loadData()
        
        // When
        viewModel.selectAllReports()
        
        // Then
        XCTAssertEqual(viewModel.selectedReportIds.count, 3)
    }
    
    func testDeselectAllReports() async throws {
        // Given
        let reports = [createSampleReport(), createSampleReport()]
        mockReportingService.mockReports = reports
        await viewModel.loadData()
        viewModel.selectAllReports()
        
        // When
        viewModel.deselectAllReports()
        
        // Then
        XCTAssertTrue(viewModel.selectedReportIds.isEmpty)
    }
    
    func testBulkDeleteReports() async throws {
        // Given
        let reports = [createSampleReport(), createSampleReport()]
        mockReportingService.mockReports = reports
        await viewModel.loadData()
        viewModel.selectAllReports()
        
        // When
        await viewModel.performBulkAction(.delete)
        
        // Then
        XCTAssertTrue(mockReportingService.deleteReportCalled)
        XCTAssertTrue(viewModel.selectedReportIds.isEmpty)
    }
    
    // MARK: - Export Tests
    
    func testExportReport() async throws {
        // Given
        let report = createSampleReport()
        viewModel.selectedReport = report
        viewModel.reportData = createSampleReportData()
        
        // When
        await viewModel.exportReport(format: .pdf)
        
        // Then
        XCTAssertTrue(mockReportingService.exportReportCalled)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Analytics Tests
    
    func testLoadAnalytics() async throws {
        // Given
        let analytics = ReportAnalytics(
            totalReports: 10,
            publicReports: 5,
            recentReports: 3,
            averageGenerationTime: 2.5,
            categoryCounts: [.sales: 4, .financial: 3, .customers: 3],
            typeCounts: [.standard: 8, .dashboard: 2]
        )
        mockReportingService.mockAnalytics = analytics
        
        // When
        await viewModel.loadAnalytics()
        
        // Then
        XCTAssertNotNil(viewModel.reportAnalytics)
        XCTAssertEqual(viewModel.reportAnalytics?.totalReports, 10)
        XCTAssertEqual(viewModel.reportAnalytics?.publicReports, 5)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleReport(
        name: String = "Test Report",
        category: ReportCategory = .sales,
        type: ReportType = .standard
    ) -> Report {
        Report(
            id: UUID(),
            reportName: name,
            description: "Test description",
            category: category,
            reportType: type,
            dataSource: .sales,
            dateRange: DateRange(start: Date(), end: Date()),
            filters: [],
            visualizations: [],
            schedule: nil,
            isActive: true,
            isPublic: false,
            createdBy: "test-user",
            createdAt: Date(),
            updatedAt: Date(),
            metadata: ReportMetadata(
                version: 1,
                tags: [],
                lastGenerated: nil,
                generationCount: 0,
                averageGenerationTime: 0,
                fileSize: 0,
                recordCount: 0
            )
        )
    }
    
    private func createSampleDashboard() -> Dashboard {
        Dashboard(
            id: UUID(),
            name: "Test Dashboard",
            description: "Test description",
            layout: DashboardLayout(columns: 2, spacing: 16, padding: 16),
            widgets: [],
            isDefault: false,
            isPublic: false,
            createdBy: "test-user",
            createdAt: Date(),
            updatedAt: Date(),
            metadata: DashboardMetadata(
                version: 1,
                tags: [],
                lastViewed: nil,
                viewCount: 0
            )
        )
    }
    
    private func createSampleReportData() -> ReportData {
        ReportData(
            dataPoints: [
                ["field1": "value1", "field2": 100],
                ["field1": "value2", "field2": 200]
            ],
            summaryStats: [
                "Total": 300,
                "Average": 150
            ],
            generatedAt: Date(),
            recordCount: 2
        )
    }
}

// MARK: - Mock Reporting Service

final class MockReportingService: ReportingServiceProtocol {
    var mockReports: [Report] = []
    var mockDashboards: [Dashboard] = []
    var mockAnalytics: ReportAnalytics?
    var mockReportData: ReportData?
    var mockExportData: Data = Data()
    var shouldThrowError = false
    
    // Tracking method calls
    var createReportCalled = false
    var deleteReportCalled = false
    var exportReportCalled = false
    
    func fetchReports(
        category: ReportCategory? = nil,
        type: ReportType? = nil,
        activeOnly: Bool = false,
        publicOnly: Bool = false
    ) async throws -> [Report] {
        if shouldThrowError {
            throw ReportingServiceError.networkError
        }
        
        var filteredReports = mockReports
        
        if let category = category {
            filteredReports = filteredReports.filter { $0.category == category }
        }
        
        if let type = type {
            filteredReports = filteredReports.filter { $0.reportType == type }
        }
        
        if activeOnly {
            filteredReports = filteredReports.filter { $0.isActive }
        }
        
        if publicOnly {
            filteredReports = filteredReports.filter { $0.isPublic }
        }
        
        return filteredReports
    }
    
    func createReport(_ report: Report) async throws -> Report {
        if shouldThrowError {
            throw ReportingServiceError.validationError("Mock error")
        }
        
        createReportCalled = true
        var createdReport = report
        createdReport.recordID = CKRecord.ID()
        mockReports.append(createdReport)
        return createdReport
    }
    
    func updateReport(_ report: Report) async throws -> Report {
        if shouldThrowError {
            throw ReportingServiceError.networkError
        }
        
        var updatedReport = report
        updatedReport.updatedAt = Date()
        
        if let index = mockReports.firstIndex(where: { $0.id == report.id }) {
            mockReports[index] = updatedReport
        }
        
        return updatedReport
    }
    
    func deleteReport(_ reportId: UUID) async throws {
        if shouldThrowError {
            throw ReportingServiceError.reportNotFound
        }
        
        deleteReportCalled = true
        mockReports.removeAll { $0.id == reportId }
    }
    
    func fetchDashboards() async throws -> [Dashboard] {
        if shouldThrowError {
            throw ReportingServiceError.networkError
        }
        
        return mockDashboards
    }
    
    func createDashboard(_ dashboard: Dashboard) async throws -> Dashboard {
        if shouldThrowError {
            throw ReportingServiceError.validationError("Mock error")
        }
        
        var createdDashboard = dashboard
        createdDashboard.recordID = CKRecord.ID()
        mockDashboards.append(createdDashboard)
        return createdDashboard
    }
    
    func generateReportData(for report: Report) async throws -> ReportData {
        if shouldThrowError {
            throw ReportingServiceError.dataGenerationError
        }
        
        return mockReportData ?? ReportData(
            dataPoints: [["test": "data"]],
            summaryStats: ["total": 1],
            generatedAt: Date(),
            recordCount: 1
        )
    }
    
    func exportReport(_ report: Report, data: ReportData, format: ExportFormat) async throws -> Data {
        if shouldThrowError {
            throw ReportingServiceError.exportError
        }
        
        exportReportCalled = true
        return mockExportData
    }
    
    func generateReportAnalytics() async throws -> ReportAnalytics {
        if shouldThrowError {
            throw ReportingServiceError.networkError
        }
        
        return mockAnalytics ?? ReportAnalytics(
            totalReports: mockReports.count,
            publicReports: mockReports.filter { $0.isPublic }.count,
            recentReports: 0,
            averageGenerationTime: 0,
            categoryCounts: [:],
            typeCounts: [:]
        )
    }
}

// MARK: - Array Extension for Testing

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
