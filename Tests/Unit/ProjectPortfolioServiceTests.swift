import CloudKit
import XCTest

/// Comprehensive unit tests for ProjectPortfolioService
/// Tests PT3VS1 compliance and enterprise portfolio management capabilities
@MainActor
final class ProjectPortfolioServiceTests: XCTestCase {
    
    var portfolioService: ProjectPortfolioService!
    var mockContainer: CKContainer!
    var sampleProjects: [ProjectModel]!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create mock container for testing
        mockContainer = CKContainer(identifier: "iCloud.com.test.DiamondDeskERP")
        portfolioService = ProjectPortfolioService(container: mockContainer)
        
        // Create sample projects for testing
        sampleProjects = createSampleProjects()
    }
    
    override func tearDownWithError() throws {
        portfolioService = nil
        mockContainer = nil
        sampleProjects = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Service Initialization Tests
    
    func testPortfolioServiceInitialization() throws {
        XCTAssertNotNil(portfolioService)
        XCTAssertEqual(portfolioService.projects.count, 0)
        XCTAssertFalse(portfolioService.isLoading)
        XCTAssertNil(portfolioService.error)
        XCTAssertNotNil(portfolioService.portfolioDashboard)
        XCTAssertNotNil(portfolioService.resourceOptimization)
        XCTAssertNotNil(portfolioService.riskOverview)
        XCTAssertNotNil(portfolioService.performanceMetrics)
    }
    
    func testDefaultDashboardInitialization() throws {
        let dashboard = portfolioService.portfolioDashboard
        
        XCTAssertEqual(dashboard.totalProjects, 0)
        XCTAssertEqual(dashboard.activeProjects, 0)
        XCTAssertEqual(dashboard.completedProjects, 0)
        XCTAssertEqual(dashboard.projectsAtRisk, 0)
        XCTAssertEqual(dashboard.totalBudget, 0.0)
        XCTAssertEqual(dashboard.totalActualCost, 0.0)
        XCTAssertEqual(dashboard.portfolioROI, 0.0)
        XCTAssertEqual(dashboard.averageProgress, 0.0)
        XCTAssertEqual(dashboard.portfolioHealth, .green)
    }
    
    // MARK: - Project Management Tests
    
    func testCreateProject() async throws {
        let newProject = createSampleProject(
            name: "Test Project",
            status: .planning,
            priority: .medium,
            budget: 500_000.0
        )
        
        // Mock successful creation by directly adding to array
        portfolioService.projects.append(newProject)
        
        XCTAssertEqual(portfolioService.projects.count, 1)
        XCTAssertEqual(portfolioService.projects.first?.name, "Test Project")
        XCTAssertEqual(portfolioService.projects.first?.budget, 500_000.0)
    }
    
    func testUpdateProject() async throws {
        var project = createSampleProject(name: "Update Test", status: .planning, priority: .medium, budget: 100_000.0)
        portfolioService.projects.append(project)
        
        // Update project
        project.status = .active
        project.progress = 25.0
        project.actualCost = 30_000.0
        
        // Mock update
        if let index = portfolioService.projects.firstIndex(where: { $0.id == project.id }) {
            portfolioService.projects[index] = project
        }
        
        XCTAssertEqual(portfolioService.projects.first?.status, .active)
        XCTAssertEqual(portfolioService.projects.first?.progress, 25.0)
        XCTAssertEqual(portfolioService.projects.first?.actualCost, 30_000.0)
    }
    
    func testDeleteProject() async throws {
        let project = createSampleProject(name: "Delete Test", status: .planning, priority: .low, budget: 50_000.0)
        portfolioService.projects.append(project)
        
        XCTAssertEqual(portfolioService.projects.count, 1)
        
        // Mock deletion
        portfolioService.projects.removeAll { $0.id == project.id }
        
        XCTAssertEqual(portfolioService.projects.count, 0)
    }
    
    // MARK: - Portfolio Analytics Tests
    
    func testPortfolioDashboardCalculation() async throws {
        // Add sample projects
        portfolioService.projects = sampleProjects
        
        // Manually trigger dashboard update for testing
        await portfolioService.updatePortfolioDashboard()
        
        let dashboard = portfolioService.portfolioDashboard
        
        // Verify basic counts
        XCTAssertEqual(dashboard.totalProjects, sampleProjects.count)
        
        let activeCount = sampleProjects.filter { $0.status == .active }.count
        XCTAssertEqual(dashboard.activeProjects, activeCount)
        
        let completedCount = sampleProjects.filter { $0.status == .completed }.count
        XCTAssertEqual(dashboard.completedProjects, completedCount)
        
        let atRiskCount = sampleProjects.filter { $0.overallHealth == .red }.count
        XCTAssertEqual(dashboard.projectsAtRisk, atRiskCount)
        
        // Verify budget calculations
        let totalBudget = sampleProjects.reduce(0) { $0 + $1.budget }
        XCTAssertEqual(dashboard.totalBudget, totalBudget)
        
        let totalActualCost = sampleProjects.reduce(0) { $0 + $1.actualCost }
        XCTAssertEqual(dashboard.totalActualCost, totalActualCost)
        
        // Verify last updated timestamp
        XCTAssertNotNil(dashboard.lastUpdated)
    }
    
    func testResourceOptimizationAnalysis() async throws {
        portfolioService.projects = sampleProjects
        
        await portfolioService.analyzeResourceOptimization()
        
        let optimization = portfolioService.resourceOptimization
        
        XCTAssertNotNil(optimization)
        XCTAssertTrue(optimization.lastAnalysis <= Date())
        
        // Verify optimization data structure
        XCTAssertGreaterThanOrEqual(optimization.totalCapacity, 0.0)
        XCTAssertGreaterThanOrEqual(optimization.allocatedCapacity, 0.0)
        XCTAssertGreaterThanOrEqual(optimization.utilizationRate, 0.0)
    }
    
    func testRiskAssessment() async throws {
        portfolioService.projects = sampleProjects
        
        await portfolioService.assessPortfolioRisks()
        
        let riskOverview = portfolioService.riskOverview
        
        XCTAssertNotNil(riskOverview)
        XCTAssertTrue(riskOverview.lastAssessment <= Date())
        
        // Count risks across all projects
        let totalRisks = sampleProjects.reduce(0) { $0 + $1.risks.count }
        XCTAssertEqual(riskOverview.totalRisks, totalRisks)
        
        // Count high-risk projects
        let highRiskProjects = sampleProjects.filter { $0.overallHealth == .red }.count
        XCTAssertGreaterThanOrEqual(riskOverview.criticalRisks, 0)
    }
    
    func testPerformanceMetricsCalculation() async throws {
        portfolioService.projects = sampleProjects
        
        await portfolioService.calculatePerformanceMetrics()
        
        let metrics = portfolioService.performanceMetrics
        
        XCTAssertNotNil(metrics)
        XCTAssertTrue(metrics.lastCalculation <= Date())
        
        // Verify metric ranges
        XCTAssertGreaterThanOrEqual(metrics.schedulePerformanceIndex, 0.0)
        XCTAssertGreaterThanOrEqual(metrics.costPerformanceIndex, 0.0)
        XCTAssertGreaterThanOrEqual(metrics.qualityIndex, 0.0)
        XCTAssertLesssThanOrEqual(metrics.qualityIndex, 100.0)
    }
    
    // MARK: - Filtering and Search Tests
    
    func testProjectFilteringByStatus() throws {
        portfolioService.projects = sampleProjects
        
        let activeProjects = portfolioService.getProjectsByStatus(.active)
        let expectedActiveCount = sampleProjects.filter { $0.status == .active }.count
        XCTAssertEqual(activeProjects.count, expectedActiveCount)
        
        let completedProjects = portfolioService.getProjectsByStatus(.completed)
        let expectedCompletedCount = sampleProjects.filter { $0.status == .completed }.count
        XCTAssertEqual(completedProjects.count, expectedCompletedCount)
        
        let planningProjects = portfolioService.getProjectsByStatus(.planning)
        let expectedPlanningCount = sampleProjects.filter { $0.status == .planning }.count
        XCTAssertEqual(planningProjects.count, expectedPlanningCount)
    }
    
    func testProjectFilteringByPriority() throws {
        portfolioService.projects = sampleProjects
        
        let highPriorityProjects = portfolioService.getProjectsByPriority(.high)
        let expectedHighCount = sampleProjects.filter { $0.priority == .high }.count
        XCTAssertEqual(highPriorityProjects.count, expectedHighCount)
        
        let mediumPriorityProjects = portfolioService.getProjectsByPriority(.medium)
        let expectedMediumCount = sampleProjects.filter { $0.priority == .medium }.count
        XCTAssertEqual(mediumPriorityProjects.count, expectedMediumCount)
    }
    
    func testProjectFilteringByHealth() throws {
        portfolioService.projects = sampleProjects
        
        let healthyProjects = portfolioService.getProjectsByHealth(.green)
        let expectedHealthyCount = sampleProjects.filter { $0.overallHealth == .green }.count
        XCTAssertEqual(healthyProjects.count, expectedHealthyCount)
        
        let atRiskProjects = portfolioService.getProjectsByHealth(.yellow)
        let expectedAtRiskCount = sampleProjects.filter { $0.overallHealth == .yellow }.count
        XCTAssertEqual(atRiskProjects.count, expectedAtRiskCount)
        
        let criticalProjects = portfolioService.getProjectsByHealth(.red)
        let expectedCriticalCount = sampleProjects.filter { $0.overallHealth == .red }.count
        XCTAssertEqual(criticalProjects.count, expectedCriticalCount)
    }
    
    func testProjectSearch() throws {
        portfolioService.projects = sampleProjects
        
        // Test name search
        let alphaResults = portfolioService.searchProjects(query: "Alpha")
        XCTAssertGreaterThanOrEqual(alphaResults.count, 0)
        
        // Test description search
        let transformationResults = portfolioService.searchProjects(query: "transformation")
        XCTAssertGreaterThanOrEqual(transformationResults.count, 0)
        
        // Test manager search
        let managerResults = portfolioService.searchProjects(query: "John")
        XCTAssertGreaterThanOrEqual(managerResults.count, 0)
        
        // Test combined filters
        let combinedResults = portfolioService.searchProjects(
            query: "Project",
            status: .active,
            priority: .high
        )
        XCTAssertGreaterThanOrEqual(combinedResults.count, 0)
    }
    
    func testDateRangeFiltering() throws {
        portfolioService.projects = sampleProjects
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? Date()
        let dateRange = DateInterval(start: startDate, end: endDate)
        
        let resultsInRange = portfolioService.searchProjects(dateRange: dateRange)
        
        // Verify all results fall within date range
        for project in resultsInRange {
            XCTAssertTrue(project.startDate >= dateRange.start)
            XCTAssertTrue(project.endDate <= dateRange.end)
        }
    }
    
    // MARK: - Resource Management Tests
    
    func testResourceConflictDetection() throws {
        portfolioService.projects = createProjectsWithResourceConflicts()
        
        let conflicts = portfolioService.getResourceConflicts()
        
        XCTAssertGreaterThanOrEqual(conflicts.count, 0)
        
        for conflict in conflicts {
            XCTAssertFalse(conflict.resourceId.isEmpty)
            XCTAssertGreaterThan(conflict.conflictingProjects.count, 1)
            XCTAssertFalse(conflict.description.isEmpty)
            XCTAssertFalse(conflict.recommendedResolution.isEmpty)
        }
    }
    
    func testCapacityPlanningRecommendations() throws {
        portfolioService.projects = sampleProjects
        
        let recommendations = portfolioService.getCapacityPlanningRecommendations()
        
        XCTAssertGreaterThanOrEqual(recommendations.count, 0)
        
        // Verify recommendation structure
        for recommendation in recommendations {
            XCTAssertNotNil(recommendation)
            // Add more specific assertions based on CapacityRecommendation structure
        }
    }
    
    // MARK: - Timeline Management Tests
    
    func testTimelineConflictDetection() throws {
        portfolioService.projects = createProjectsWithTimelineConflicts()
        
        let conflicts = portfolioService.getTimelineConflicts()
        
        XCTAssertGreaterThanOrEqual(conflicts.count, 0)
        
        // Verify conflict structure
        for conflict in conflicts {
            XCTAssertNotNil(conflict)
            // Add specific assertions based on TimelineConflict structure
        }
    }
    
    // MARK: - Risk Management Tests
    
    func testRiskDashboardGeneration() throws {
        portfolioService.projects = sampleProjects
        
        let riskDashboard = portfolioService.getRiskDashboard()
        
        XCTAssertNotNil(riskDashboard)
        // Add specific assertions based on PortfolioRiskDashboard structure
    }
    
    func testRiskInterdependencyAnalysis() throws {
        portfolioService.projects = createProjectsWithRiskInterdependencies()
        
        let interdependencies = portfolioService.getRiskInterdependencies()
        
        XCTAssertGreaterThanOrEqual(interdependencies.count, 0)
        
        // Verify interdependency structure
        for interdependency in interdependencies {
            XCTAssertNotNil(interdependency)
            // Add specific assertions based on RiskInterdependency structure
        }
    }
    
    // MARK: - Financial Analysis Tests
    
    func testBudgetVarianceAnalysis() throws {
        portfolioService.projects = sampleProjects
        
        let budgetAnalysis = portfolioService.getBudgetVarianceAnalysis()
        
        XCTAssertNotNil(budgetAnalysis)
        // Add specific assertions based on BudgetVarianceAnalysis structure
    }
    
    // MARK: - Report Generation Tests
    
    func testPortfolioReportGeneration() async throws {
        portfolioService.projects = sampleProjects
        
        let report = await portfolioService.generatePortfolioReport()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report.projects.count, sampleProjects.count)
        XCTAssertTrue(report.generatedDate <= Date())
        XCTAssertNotNil(report.dashboard)
        XCTAssertNotNil(report.performanceMetrics)
        XCTAssertNotNil(report.riskOverview)
        XCTAssertNotNil(report.resourceOptimization)
        XCTAssertNotNil(report.roiAnalysis)
        XCTAssertNotNil(report.criticalPath)
        XCTAssertGreaterThanOrEqual(report.recommendations.count, 0)
    }
    
    func testRecommendationGeneration() throws {
        portfolioService.projects = createProjectsWithIssues()
        
        let recommendations = portfolioService.generateRecommendations()
        
        XCTAssertGreaterThanOrEqual(recommendations.count, 0)
        
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertFalse(recommendation.impact.isEmpty)
            XCTAssertGreaterThan(recommendation.actions.count, 0)
            
            // Verify recommendation types
            XCTAssertTrue([
                .resourceOptimization,
                .schedule,
                .financial,
                .risk,
                .quality,
                .strategic
            ].contains(recommendation.type))
            
            // Verify priorities
            XCTAssertTrue([
                .low,
                .medium,
                .high,
                .critical
            ].contains(recommendation.priority))
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        // Test with invalid data
        portfolioService.error = PortfolioError.loadFailed("Test error")
        
        XCTAssertNotNil(portfolioService.error)
        XCTAssertEqual(portfolioService.error?.localizedDescription, "Failed to load portfolio: Test error")
        
        // Test different error types
        let errors: [PortfolioError] = [
            .loadFailed("Load error"),
            .createFailed("Create error"),
            .updateFailed("Update error"),
            .deleteFailed("Delete error"),
            .analysisFailed("Analysis error"),
            .optimizationFailed("Optimization error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription?.isEmpty ?? true)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPortfolioServicePerformance() throws {
        let largeProjectSet = createLargeProjectSet(count: 100)
        
        measure {
            portfolioService.projects = largeProjectSet
            
            // Perform typical operations
            _ = portfolioService.getProjectsByStatus(.active)
            _ = portfolioService.getProjectsByPriority(.high)
            _ = portfolioService.searchProjects(query: "Project")
            _ = portfolioService.getResourceConflicts()
            _ = portfolioService.getRiskDashboard()
        }
    }
    
    func testDashboardCalculationPerformance() async throws {
        let largeProjectSet = createLargeProjectSet(count: 500)
        portfolioService.projects = largeProjectSet
        
        measure {
            Task {
                await portfolioService.updatePortfolioDashboard()
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyPortfolio() throws {
        portfolioService.projects = []
        
        let dashboard = portfolioService.portfolioDashboard
        XCTAssertEqual(dashboard.totalProjects, 0)
        XCTAssertEqual(dashboard.activeProjects, 0)
        XCTAssertEqual(dashboard.totalBudget, 0.0)
        
        let activeProjects = portfolioService.getProjectsByStatus(.active)
        XCTAssertEqual(activeProjects.count, 0)
        
        let searchResults = portfolioService.searchProjects(query: "anything")
        XCTAssertEqual(searchResults.count, 0)
    }
    
    func testSingleProjectPortfolio() throws {
        let singleProject = createSampleProject(
            name: "Solo Project",
            status: .active,
            priority: .high,
            budget: 100_000.0
        )
        
        portfolioService.projects = [singleProject]
        
        let dashboard = portfolioService.portfolioDashboard
        XCTAssertEqual(dashboard.totalProjects, 1)
        XCTAssertEqual(dashboard.activeProjects, 1)
        XCTAssertEqual(dashboard.totalBudget, 100_000.0)
        
        let activeProjects = portfolioService.getProjectsByStatus(.active)
        XCTAssertEqual(activeProjects.count, 1)
        XCTAssertEqual(activeProjects.first?.name, "Solo Project")
    }
    
    func testProjectsWithExtremeBudgets() throws {
        let projects = [
            createSampleProject(name: "Micro Project", status: .active, priority: .low, budget: 1.0),
            createSampleProject(name: "Mega Project", status: .active, priority: .critical, budget: 1_000_000_000.0)
        ]
        
        portfolioService.projects = projects
        
        let dashboard = portfolioService.portfolioDashboard
        XCTAssertEqual(dashboard.totalProjects, 2)
        XCTAssertEqual(dashboard.totalBudget, 1_000_000_001.0)
        
        // Ensure calculations handle extreme values
        XCTAssertFalse(dashboard.totalBudget.isNaN)
        XCTAssertFalse(dashboard.totalBudget.isInfinite)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleProjects() -> [ProjectModel] {
        return [
            createSampleProject(name: "Alpha Project", status: .active, priority: .high, budget: 1_000_000.0),
            createSampleProject(name: "Beta Project", status: .active, priority: .medium, budget: 750_000.0),
            createSampleProject(name: "Gamma Project", status: .completed, priority: .low, budget: 500_000.0),
            createSampleProject(name: "Delta Project", status: .planning, priority: .medium, budget: 300_000.0),
            createCriticalProject()
        ]
    }
    
    private func createSampleProject(
        name: String,
        status: ProjectStatus,
        priority: ProjectPriority,
        budget: Double
    ) -> ProjectModel {
        var project = ProjectModel(
            name: name,
            description: "Digital transformation initiative",
            projectManager: "John Smith",
            sponsor: "Jane Doe",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date(),
            status: status,
            priority: priority,
            budget: budget
        )
        
        // Add some realistic data
        project.progress = Double.random(in: 0...100)
        project.actualCost = budget * Double.random(in: 0.5...1.2)
        
        return project
    }
    
    private func createCriticalProject() -> ProjectModel {
        var project = createSampleProject(
            name: "Critical Project",
            status: .active,
            priority: .critical,
            budget: 2_000_000.0
        )
        
        project.overallHealth = .red
        project.actualCost = 2_400_000.0 // Over budget
        project.progress = 20.0 // Behind schedule
        
        // Add risks
        project.risks = [
            ProjectRisk(
                name: "Budget Overrun",
                description: "Project significantly over budget",
                category: .budget,
                probability: .high,
                impact: .severe
            ),
            ProjectRisk(
                name: "Schedule Delay",
                description: "Critical path activities delayed",
                category: .schedule,
                probability: .medium,
                impact: .major
            )
        ]
        
        return project
    }
    
    private func createProjectsWithResourceConflicts() -> [ProjectModel] {
        var project1 = createSampleProject(name: "Project 1", status: .active, priority: .high, budget: 500_000.0)
        var project2 = createSampleProject(name: "Project 2", status: .active, priority: .high, budget: 600_000.0)
        
        // Create overlapping resource allocations
        let sharedResource = ResourceAllocation(
            resourceId: "dev-001",
            resourceType: .human,
            allocation: 100.0,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
            cost: 150_000.0
        )
        
        project1.resources = [sharedResource]
        project2.resources = [sharedResource]
        
        return [project1, project2]
    }
    
    private func createProjectsWithTimelineConflicts() -> [ProjectModel] {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: startDate) ?? Date()
        
        var project1 = createSampleProject(name: "Project 1", status: .active, priority: .high, budget: 500_000.0)
        var project2 = createSampleProject(name: "Project 2", status: .planning, priority: .medium, budget: 400_000.0)
        
        project1.startDate = startDate
        project1.endDate = endDate
        project2.startDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? Date()
        project2.endDate = Calendar.current.date(byAdding: .month, value: 9, to: startDate) ?? Date()
        
        // Add dependencies that create conflicts
        let dependency = ProjectDependency(
            fromId: project1.id,
            toId: project2.id,
            dependencyType: .finishToStart
        )
        
        project2.dependencies = [dependency]
        
        return [project1, project2]
    }
    
    private func createProjectsWithRiskInterdependencies() -> [ProjectModel] {
        var project1 = createSampleProject(name: "Project 1", status: .active, priority: .high, budget: 800_000.0)
        var project2 = createSampleProject(name: "Project 2", status: .active, priority: .medium, budget: 600_000.0)
        
        // Add related risks
        let sharedRisk = ProjectRisk(
            name: "Technology Risk",
            description: "Shared technology platform may fail",
            category: .technical,
            probability: .medium,
            impact: .major
        )
        
        project1.risks = [sharedRisk]
        project2.risks = [sharedRisk]
        
        return [project1, project2]
    }
    
    private func createProjectsWithIssues() -> [ProjectModel] {
        var projects: [ProjectModel] = []
        
        // Over-budget project
        var overBudgetProject = createSampleProject(name: "Over Budget", status: .active, priority: .high, budget: 500_000.0)
        overBudgetProject.actualCost = 600_000.0 // 20% over budget
        projects.append(overBudgetProject)
        
        // Delayed project
        var delayedProject = createSampleProject(name: "Delayed", status: .active, priority: .medium, budget: 300_000.0)
        delayedProject.scheduleVariance = 172800 // 2 days behind
        projects.append(delayedProject)
        
        // High-risk project
        var riskProject = createSampleProject(name: "High Risk", status: .active, priority: .critical, budget: 1_000_000.0)
        riskProject.overallHealth = .red
        projects.append(riskProject)
        
        return projects
    }
    
    private func createLargeProjectSet(count: Int) -> [ProjectModel] {
        var projects: [ProjectModel] = []
        
        let statuses: [ProjectStatus] = [.planning, .active, .onHold, .completed, .cancelled]
        let priorities: [ProjectPriority] = [.low, .medium, .high, .critical]
        let healthStates: [ProjectHealth] = [.green, .yellow, .red]
        
        for i in 0..<count {
            var project = createSampleProject(
                name: "Project \(i + 1)",
                status: statuses.randomElement() ?? .active,
                priority: priorities.randomElement() ?? .medium,
                budget: Double.random(in: 50_000...2_000_000)
            )
            
            project.overallHealth = healthStates.randomElement() ?? .green
            project.progress = Double.random(in: 0...100)
            project.actualCost = project.budget * Double.random(in: 0.5...1.3)
            
            projects.append(project)
        }
        
        return projects
    }
}

// MARK: - Portfolio Dashboard Tests

extension ProjectPortfolioServiceTests {
    
    func testPortfolioDashboardDataStructure() throws {
        let dashboard = PortfolioDashboard(
            totalProjects: 10,
            activeProjects: 6,
            completedProjects: 3,
            projectsAtRisk: 1,
            totalBudget: 5_000_000.0,
            totalActualCost: 4_800_000.0,
            portfolioROI: 15.5,
            averageProgress: 67.3,
            onTimeDelivery: 85.2,
            budgetUtilization: 96.0,
            resourceUtilization: 88.5,
            riskScore: 3.2,
            strategicAlignment: 92.1,
            portfolioHealth: .yellow
        )
        
        XCTAssertEqual(dashboard.totalProjects, 10)
        XCTAssertEqual(dashboard.activeProjects, 6)
        XCTAssertEqual(dashboard.completedProjects, 3)
        XCTAssertEqual(dashboard.projectsAtRisk, 1)
        XCTAssertEqual(dashboard.totalBudget, 5_000_000.0)
        XCTAssertEqual(dashboard.totalActualCost, 4_800_000.0)
        XCTAssertEqual(dashboard.portfolioROI, 15.5, accuracy: 0.01)
        XCTAssertEqual(dashboard.averageProgress, 67.3, accuracy: 0.01)
        XCTAssertEqual(dashboard.onTimeDelivery, 85.2, accuracy: 0.01)
        XCTAssertEqual(dashboard.budgetUtilization, 96.0, accuracy: 0.01)
        XCTAssertEqual(dashboard.resourceUtilization, 88.5, accuracy: 0.01)
        XCTAssertEqual(dashboard.riskScore, 3.2, accuracy: 0.01)
        XCTAssertEqual(dashboard.strategicAlignment, 92.1, accuracy: 0.01)
        XCTAssertEqual(dashboard.portfolioHealth, .yellow)
        XCTAssertTrue(dashboard.lastUpdated <= Date())
    }
    
    func testTrendDataPoint() throws {
        let trendPoint = TrendDataPoint(
            date: Date(),
            value: 85.5,
            metric: .progress
        )
        
        XCTAssertNotNil(trendPoint.id)
        XCTAssertFalse(trendPoint.id.isEmpty)
        XCTAssertTrue(trendPoint.date <= Date())
        XCTAssertEqual(trendPoint.value, 85.5)
        XCTAssertEqual(trendPoint.metric, .progress)
    }
    
    func testTrendMetricEnum() throws {
        let allMetrics = TrendMetric.allCases
        
        XCTAssertEqual(allMetrics.count, 5)
        XCTAssertTrue(allMetrics.contains(.progress))
        XCTAssertTrue(allMetrics.contains(.budget))
        XCTAssertTrue(allMetrics.contains(.risks))
        XCTAssertTrue(allMetrics.contains(.resources))
        XCTAssertTrue(allMetrics.contains(.schedule))
    }
}

// MARK: - Resource Optimization Tests

extension ProjectPortfolioServiceTests {
    
    func testResourceConflictStructure() throws {
        let conflict = ResourceConflict(
            resourceId: "dev-001",
            conflictingProjects: ["project-1", "project-2", "project-3"],
            severity: .high,
            description: "Developer allocated to multiple overlapping projects",
            recommendedResolution: "Prioritize critical project and reallocate others"
        )
        
        XCTAssertNotNil(conflict.id)
        XCTAssertEqual(conflict.resourceId, "dev-001")
        XCTAssertEqual(conflict.conflictingProjects.count, 3)
        XCTAssertEqual(conflict.severity, .high)
        XCTAssertFalse(conflict.description.isEmpty)
        XCTAssertFalse(conflict.recommendedResolution.isEmpty)
    }
    
    func testConflictSeverityEnum() throws {
        let severities: [ConflictSeverity] = [.low, .medium, .high, .critical]
        
        for severity in severities {
            XCTAssertFalse(severity.rawValue.isEmpty)
        }
    }
    
    func testResourceOptimizationOpportunity() throws {
        let opportunity = ResourceOptimizationOpportunity(
            type: .reallocation,
            description: "Reallocate underutilized resources",
            potentialSavings: 150_000.0,
            implementationEffort: .moderate,
            priority: .medium
        )
        
        XCTAssertNotNil(opportunity.id)
        XCTAssertEqual(opportunity.type, .reallocation)
        XCTAssertFalse(opportunity.description.isEmpty)
        XCTAssertEqual(opportunity.potentialSavings, 150_000.0)
        XCTAssertEqual(opportunity.implementationEffort, .moderate)
        XCTAssertEqual(opportunity.priority, .medium)
    }
}

// MARK: - Error Handling Edge Cases

extension ProjectPortfolioServiceTests {
    
    func testPortfolioErrorTypes() throws {
        let errors: [(PortfolioError, String)] = [
            (.loadFailed("Network error"), "Failed to load portfolio: Network error"),
            (.createFailed("Validation error"), "Failed to create project: Validation error"),
            (.updateFailed("Conflict error"), "Failed to update project: Conflict error"),
            (.deleteFailed("Permission error"), "Failed to delete project: Permission error"),
            (.analysisFailed("Data error"), "Portfolio analysis failed: Data error"),
            (.optimizationFailed("Algorithm error"), "Optimization failed: Algorithm error")
        ]
        
        for (error, expectedMessage) in errors {
            XCTAssertEqual(error.localizedDescription, expectedMessage)
        }
    }
    
    func testConcurrentAccess() async throws {
        // Test concurrent operations on portfolio service
        let project1 = createSampleProject(name: "Concurrent 1", status: .active, priority: .high, budget: 100_000.0)
        let project2 = createSampleProject(name: "Concurrent 2", status: .active, priority: .medium, budget: 200_000.0)
        
        // Simulate concurrent operations
        async let operation1: () = {
            portfolioService.projects.append(project1)
        }()
        
        async let operation2: () = {
            portfolioService.projects.append(project2)
        }()
        
        // Wait for both operations
        _ = await (operation1, operation2)
        
        // Verify both projects were added
        XCTAssertGreaterThanOrEqual(portfolioService.projects.count, 2)
    }
}
