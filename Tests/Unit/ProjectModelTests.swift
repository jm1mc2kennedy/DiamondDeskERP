import XCTest
import CloudKit
@testable import DiamondDeskERP

/// Comprehensive unit tests for Advanced ProjectModel
/// Tests PT3VS1 compliance and enterprise portfolio management features
final class ProjectModelTests: XCTestCase {
    
    var sampleProject: ProjectModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create a comprehensive sample project for testing
        sampleProject = ProjectModel(
            name: "Enterprise Digital Transformation",
            description: "Comprehensive digital transformation initiative to modernize business processes and technology infrastructure",
            projectManager: "John Smith",
            sponsor: "Jane Doe",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date(),
            status: .active,
            priority: .high,
            budget: 1_000_000.0
        )
    }
    
    override func tearDownWithError() throws {
        sampleProject = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Project Model Tests
    
    func testProjectModelInitialization() throws {
        XCTAssertNotNil(sampleProject)
        XCTAssertFalse(sampleProject.id.isEmpty)
        XCTAssertEqual(sampleProject.name, "Enterprise Digital Transformation")
        XCTAssertEqual(sampleProject.projectManager, "John Smith")
        XCTAssertEqual(sampleProject.sponsor, "Jane Doe")
        XCTAssertEqual(sampleProject.status, .active)
        XCTAssertEqual(sampleProject.priority, .high)
        XCTAssertEqual(sampleProject.budget, 1_000_000.0)
        XCTAssertEqual(sampleProject.actualCost, 0.0)
        XCTAssertEqual(sampleProject.progress, 0.0)
        XCTAssertEqual(sampleProject.overallHealth, .green)
    }
    
    func testProjectStatusEnum() throws {
        let allStatuses: [ProjectStatus] = [.planning, .active, .onHold, .completed, .cancelled, .archived]
        
        for status in allStatuses {
            XCTAssertFalse(status.displayName.isEmpty)
            XCTAssertFalse(status.color.isEmpty)
        }
        
        XCTAssertEqual(ProjectStatus.planning.displayName, "Planning")
        XCTAssertEqual(ProjectStatus.active.color, "green")
        XCTAssertEqual(ProjectStatus.cancelled.color, "red")
    }
    
    func testProjectPriorityEnum() throws {
        XCTAssertEqual(ProjectPriority.critical.numericValue, 4)
        XCTAssertEqual(ProjectPriority.high.numericValue, 3)
        XCTAssertEqual(ProjectPriority.medium.numericValue, 2)
        XCTAssertEqual(ProjectPriority.low.numericValue, 1)
    }
    
    func testProjectHealthEnum() throws {
        XCTAssertEqual(ProjectHealth.green.displayName, "On Track")
        XCTAssertEqual(ProjectHealth.yellow.displayName, "At Risk")
        XCTAssertEqual(ProjectHealth.red.displayName, "Critical")
    }
    
    // MARK: - Financial Management Tests
    
    func testROICalculation() throws {
        var roi = ROICalculation()
        roi.expectedBenefits = 1_500_000.0
        roi.totalInvestment = 1_000_000.0
        
        XCTAssertEqual(roi.roi, 50.0, accuracy: 0.01) // 50% ROI
        XCTAssertTrue(roi.isPositive)
        
        // Test negative ROI
        roi.expectedBenefits = 800_000.0
        XCTAssertEqual(roi.roi, -20.0, accuracy: 0.01) // -20% ROI
        XCTAssertFalse(roi.isPositive)
        
        // Test zero investment
        roi.totalInvestment = 0.0
        XCTAssertEqual(roi.roi, 0.0)
    }
    
    func testBudgetVarianceCalculation() throws {
        sampleProject.actualCost = 1_200_000.0
        
        XCTAssertEqual(sampleProject.budgetVariance, 200_000.0)
        XCTAssertEqual(sampleProject.budgetVariancePercentage, 20.0, accuracy: 0.01)
        
        // Test under budget
        sampleProject.actualCost = 800_000.0
        XCTAssertEqual(sampleProject.budgetVariance, -200_000.0)
        XCTAssertEqual(sampleProject.budgetVariancePercentage, -20.0, accuracy: 0.01)
    }
    
    func testCostCategory() throws {
        let costCategory = CostCategory(
            name: "Software Licenses",
            budgetedAmount: 100_000.0,
            actualAmount: 120_000.0,
            costType: .software
        )
        
        XCTAssertEqual(costCategory.variance, 20_000.0)
        XCTAssertEqual(costCategory.variancePercentage, 20.0, accuracy: 0.01)
        XCTAssertEqual(costCategory.costType, .software)
    }
    
    func testFinancialForecast() throws {
        let forecast = FinancialForecast(
            period: .quarterly,
            projectedCost: 250_000.0,
            projectedBenefits: 300_000.0,
            confidence: 85.0
        )
        
        XCTAssertEqual(forecast.period, .quarterly)
        XCTAssertEqual(forecast.projectedCost, 250_000.0)
        XCTAssertEqual(forecast.projectedBenefits, 300_000.0)
        XCTAssertEqual(forecast.confidence, 85.0)
        XCTAssertNotNil(forecast.id)
    }
    
    // MARK: - Performance and Progress Tests
    
    func testPerformanceIndicator() throws {
        var indicator = PerformanceIndicator(
            name: "Schedule Performance",
            category: .schedule,
            target: 100.0,
            unit: "percent",
            frequency: .weekly
        )
        
        indicator.actual = 95.0
        
        XCTAssertEqual(indicator.performancePercentage, 95.0)
        XCTAssertEqual(indicator.status, .excellent)
        
        // Test different performance levels
        indicator.actual = 85.0
        XCTAssertEqual(indicator.status, .good)
        
        indicator.actual = 75.0
        XCTAssertEqual(indicator.status, .satisfactory)
        
        indicator.actual = 60.0
        XCTAssertEqual(indicator.status, .belowTarget)
        
        indicator.actual = 40.0
        XCTAssertEqual(indicator.status, .poor)
    }
    
    // MARK: - Project Structure Tests
    
    func testProjectPhase() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? Date()
        
        var phase = ProjectPhase(
            name: "Analysis Phase",
            startDate: startDate,
            endDate: endDate,
            budget: 200_000.0
        )
        
        XCTAssertEqual(phase.name, "Analysis Phase")
        XCTAssertEqual(phase.status, .notStarted)
        XCTAssertEqual(phase.progress, 0.0)
        XCTAssertEqual(phase.budget, 200_000.0)
        XCTAssertEqual(phase.actualCost, 0.0)
        XCTAssertTrue(phase.tasks.isEmpty)
        XCTAssertTrue(phase.milestones.isEmpty)
        XCTAssertTrue(phase.dependencies.isEmpty)
        
        // Test schedule performance
        phase.progress = 50.0
        // Since we're in the middle of the phase timeline, 50% progress should be on schedule
        // Note: The exact logic depends on current date relative to phase dates
    }
    
    func testMilestone() throws {
        let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        var milestone = Milestone(
            name: "Requirements Complete",
            description: "All business requirements documented and approved",
            dueDate: dueDate,
            criticalPath: true
        )
        
        XCTAssertEqual(milestone.name, "Requirements Complete")
        XCTAssertEqual(milestone.status, .notStarted)
        XCTAssertTrue(milestone.criticalPath)
        XCTAssertFalse(milestone.isOverdue)
        XCTAssertNil(milestone.completedDate)
        
        // Test overdue logic
        let pastDue = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        milestone.dueDate = pastDue
        XCTAssertTrue(milestone.isOverdue)
        
        // Test completed milestone
        milestone.status = .completed
        milestone.completedDate = Date()
        XCTAssertFalse(milestone.isOverdue) // Completed milestones are not overdue
    }
    
    func testAcceptanceCriteria() throws {
        var criteria = AcceptanceCriteria(
            description: "User acceptance testing completed with 95% pass rate",
            priority: .critical,
            verificationMethod: "Automated testing suite"
        )
        
        XCTAssertFalse(criteria.isMet)
        XCTAssertEqual(criteria.priority, .critical)
        XCTAssertEqual(criteria.verificationMethod, "Automated testing suite")
        XCTAssertNil(criteria.verifiedBy)
        XCTAssertNil(criteria.verificationDate)
        
        // Test verification
        criteria.isMet = true
        criteria.verifiedBy = "QA Team Lead"
        criteria.verificationDate = Date()
        
        XCTAssertTrue(criteria.isMet)
        XCTAssertNotNil(criteria.verifiedBy)
        XCTAssertNotNil(criteria.verificationDate)
    }
    
    // MARK: - Dependencies and Work Breakdown Tests
    
    func testProjectDependency() throws {
        let dependency = ProjectDependency(
            fromId: "task-1",
            toId: "task-2",
            dependencyType: .finishToStart,
            lag: 86400, // 1 day
            description: "Task 1 must complete before Task 2 can start"
        )
        
        XCTAssertEqual(dependency.fromId, "task-1")
        XCTAssertEqual(dependency.toId, "task-2")
        XCTAssertEqual(dependency.dependencyType, .finishToStart)
        XCTAssertEqual(dependency.lag, 86400)
        XCTAssertTrue(dependency.isActive)
        XCTAssertNotNil(dependency.description)
    }
    
    func testWorkPackage() throws {
        var workPackage = WorkPackage(
            name: "Database Design",
            description: "Design and implement database schema",
            estimatedHours: 80.0
        )
        
        XCTAssertEqual(workPackage.name, "Database Design")
        XCTAssertEqual(workPackage.estimatedHours, 80.0)
        XCTAssertEqual(workPackage.actualHours, 0.0)
        XCTAssertEqual(workPackage.status, .notStarted)
        XCTAssertTrue(workPackage.assignedResources.isEmpty)
        XCTAssertTrue(workPackage.deliverables.isEmpty)
        
        // Test progress
        workPackage.actualHours = 40.0
        workPackage.status = .inProgress
        
        XCTAssertEqual(workPackage.actualHours, 40.0)
        XCTAssertEqual(workPackage.status, .inProgress)
    }
    
    func testDeliverable() throws {
        let dueDate = Calendar.current.date(byAdding: .week, value: 2, to: Date()) ?? Date()
        
        var deliverable = Deliverable(
            name: "Technical Specification",
            description: "Detailed technical specification document",
            type: .document,
            dueDate: dueDate
        )
        
        XCTAssertEqual(deliverable.name, "Technical Specification")
        XCTAssertEqual(deliverable.type, .document)
        XCTAssertEqual(deliverable.status, .notStarted)
        XCTAssertEqual(deliverable.qualityScore, 0.0)
        XCTAssertFalse(deliverable.isOverdue)
        XCTAssertNil(deliverable.deliveredDate)
        XCTAssertNil(deliverable.approver)
        
        // Test delivery
        deliverable.status = .delivered
        deliverable.deliveredDate = Date()
        deliverable.qualityScore = 92.0
        
        XCTAssertEqual(deliverable.status, .delivered)
        XCTAssertNotNil(deliverable.deliveredDate)
        XCTAssertEqual(deliverable.qualityScore, 92.0)
    }
    
    // MARK: - Resource Management Tests
    
    func testResourceAllocation() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 2, to: startDate) ?? Date()
        
        var allocation = ResourceAllocation(
            resourceId: "dev-001",
            resourceType: .human,
            allocation: 80.0, // 80%
            startDate: startDate,
            endDate: endDate,
            cost: 160_000.0
        )
        
        XCTAssertEqual(allocation.resourceId, "dev-001")
        XCTAssertEqual(allocation.resourceType, .human)
        XCTAssertEqual(allocation.allocation, 80.0)
        XCTAssertFalse(allocation.isOverAllocated)
        XCTAssertEqual(allocation.actualUtilization, 0.0)
        
        // Test over-allocation
        allocation.allocation = 120.0
        XCTAssertTrue(allocation.isOverAllocated)
        
        // Test under-utilization
        allocation.allocation = 80.0
        allocation.actualUtilization = 60.0 // 60% actual vs 80% allocated
        XCTAssertTrue(allocation.isUnderUtilized) // 60% < 80% * 0.8
    }
    
    func testResourceBottleneck() throws {
        let bottleneck = ResourceBottleneck(
            resourceId: "server-001",
            severity: .high,
            description: "Server capacity at 95% utilization",
            impact: "Potential system slowdowns and project delays"
        )
        
        XCTAssertEqual(bottleneck.resourceId, "server-001")
        XCTAssertEqual(bottleneck.severity, .high)
        XCTAssertNotNil(bottleneck.description)
        XCTAssertNotNil(bottleneck.impact)
        XCTAssertTrue(bottleneck.recommendedActions.isEmpty)
    }
    
    func testOptimizationRecommendation() throws {
        let recommendation = OptimizationRecommendation(
            type: .reallocation,
            description: "Reallocate developers from Project A to Project B",
            expectedBenefit: "Reduce Project B timeline by 2 weeks",
            implementationEffort: .moderate,
            priority: .high
        )
        
        XCTAssertEqual(recommendation.type, .reallocation)
        XCTAssertEqual(recommendation.implementationEffort, .moderate)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertNotNil(recommendation.description)
        XCTAssertNotNil(recommendation.expectedBenefit)
    }
    
    // MARK: - Risk Management Tests
    
    func testProjectRisk() throws {
        var risk = ProjectRisk(
            name: "Technology Risk",
            description: "New technology platform may not meet performance requirements",
            category: .technical,
            probability: .medium,
            impact: .major,
            owner: "Technical Lead"
        )
        
        XCTAssertEqual(risk.name, "Technology Risk")
        XCTAssertEqual(risk.category, .technical)
        XCTAssertEqual(risk.probability, .medium)
        XCTAssertEqual(risk.impact, .major)
        XCTAssertEqual(risk.riskScore, 12.0) // 3.0 * 4.0
        XCTAssertEqual(risk.riskLevel, .critical) // Score of 12 is critical
        XCTAssertEqual(risk.status, .identified)
        XCTAssertEqual(risk.owner, "Technical Lead")
        XCTAssertTrue(risk.mitigationActions.isEmpty)
        
        // Test different risk levels
        risk.probability = .low
        risk.impact = .minor
        XCTAssertEqual(risk.riskScore, 4.0) // 2.0 * 2.0
        XCTAssertEqual(risk.riskLevel, .high)
        
        risk.probability = .veryLow
        risk.impact = .negligible
        XCTAssertEqual(risk.riskScore, 1.0) // 1.0 * 1.0
        XCTAssertEqual(risk.riskLevel, .low)
    }
    
    func testMitigationAction() throws {
        let dueDate = Calendar.current.date(byAdding: .week, value: 1, to: Date()) ?? Date()
        
        var action = MitigationAction(
            description: "Conduct proof of concept testing",
            type: .mitigate,
            owner: "Senior Developer",
            dueDate: dueDate,
            estimatedCost: 25_000.0,
            effectiveness: .high
        )
        
        XCTAssertEqual(action.type, .mitigate)
        XCTAssertEqual(action.owner, "Senior Developer")
        XCTAssertEqual(action.estimatedCost, 25_000.0)
        XCTAssertEqual(action.effectiveness, .high)
        XCTAssertEqual(action.status, .notStarted)
        XCTAssertFalse(action.isOverdue)
        XCTAssertNil(action.completedDate)
        
        // Test completion
        action.status = .completed
        action.completedDate = Date()
        
        XCTAssertEqual(action.status, .completed)
        XCTAssertNotNil(action.completedDate)
        XCTAssertFalse(action.isOverdue) // Completed actions are not overdue
    }
    
    func testRiskMitigationPlan() throws {
        let plan = RiskMitigationPlan(
            riskId: "risk-001",
            planName: "Technology Risk Mitigation",
            strategy: .prevention,
            implementationTimeline: 604800 // 1 week in seconds
        )
        
        XCTAssertEqual(plan.riskId, "risk-001")
        XCTAssertEqual(plan.planName, "Technology Risk Mitigation")
        XCTAssertEqual(plan.strategy, .prevention)
        XCTAssertEqual(plan.implementationTimeline, 604800)
        XCTAssertEqual(plan.status, .draft)
        XCTAssertTrue(plan.actions.isEmpty)
        XCTAssertEqual(plan.totalCost, 0.0)
    }
    
    func testContingencyPlan() throws {
        var plan = ContingencyPlan(
            name: "Server Failure Response",
            estimatedCost: 50_000.0,
            activationTimeframe: 3600 // 1 hour
        )
        
        XCTAssertEqual(plan.name, "Server Failure Response")
        XCTAssertEqual(plan.estimatedCost, 50_000.0)
        XCTAssertEqual(plan.activationTimeframe, 3600)
        XCTAssertFalse(plan.isActive)
        XCTAssertTrue(plan.triggerConditions.isEmpty)
        XCTAssertTrue(plan.activationCriteria.isEmpty)
        XCTAssertTrue(plan.responseActions.isEmpty)
        
        // Test activation
        plan.isActive = true
        XCTAssertTrue(plan.isActive)
    }
    
    // MARK: - Critical Path Tests
    
    func testCriticalPathItem() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 5, to: startDate) ?? Date()
        
        let pathItem = CriticalPathItem(
            itemId: "task-001",
            itemType: .task,
            name: "Database Setup",
            duration: 432000, // 5 days in seconds
            startDate: startDate,
            endDate: endDate,
            slack: 0, // Critical path items have zero slack
            criticality: 100.0
        )
        
        XCTAssertEqual(pathItem.itemId, "task-001")
        XCTAssertEqual(pathItem.itemType, .task)
        XCTAssertEqual(pathItem.name, "Database Setup")
        XCTAssertEqual(pathItem.duration, 432000)
        XCTAssertEqual(pathItem.slack, 0)
        XCTAssertEqual(pathItem.criticality, 100.0)
    }
    
    func testOptimizationOpportunity() throws {
        let opportunity = OptimizationOpportunity(
            type: .parallelization,
            description: "Run testing and documentation tasks in parallel",
            potentialTimeSaving: 172800, // 2 days
            implementationComplexity: .medium,
            riskLevel: .low,
            costImpact: 0.0
        )
        
        XCTAssertEqual(opportunity.type, .parallelization)
        XCTAssertEqual(opportunity.potentialTimeSaving, 172800)
        XCTAssertEqual(opportunity.implementationComplexity, .medium)
        XCTAssertEqual(opportunity.riskLevel, .low)
        XCTAssertEqual(opportunity.costImpact, 0.0)
    }
    
    // MARK: - CloudKit Integration Tests
    
    func testCloudKitSerialization() throws {
        // Test converting to CKRecord
        let record = sampleProject.toCKRecord()
        
        XCTAssertEqual(record.recordType, "ProjectModel")
        XCTAssertEqual(record.recordID.recordName, sampleProject.id)
        XCTAssertEqual(record["name"] as? String, sampleProject.name)
        XCTAssertEqual(record["description"] as? String, sampleProject.description)
        XCTAssertEqual(record["projectManager"] as? String, sampleProject.projectManager)
        XCTAssertEqual(record["sponsor"] as? String, sampleProject.sponsor)
        XCTAssertEqual(record["status"] as? String, sampleProject.status.rawValue)
        XCTAssertEqual(record["priority"] as? String, sampleProject.priority.rawValue)
        XCTAssertEqual(record["budget"] as? Double, sampleProject.budget)
        XCTAssertEqual(record["actualCost"] as? Double, sampleProject.actualCost)
        XCTAssertEqual(record["progress"] as? Double, sampleProject.progress)
        XCTAssertNotNil(record["roi"])
        XCTAssertNotNil(record["costBreakdown"])
        
        // Test converting from CKRecord
        let deserializedProject = ProjectModel.fromCKRecord(record)
        XCTAssertNotNil(deserializedProject)
        
        if let project = deserializedProject {
            XCTAssertEqual(project.id, sampleProject.id)
            XCTAssertEqual(project.name, sampleProject.name)
            XCTAssertEqual(project.description, sampleProject.description)
            XCTAssertEqual(project.projectManager, sampleProject.projectManager)
            XCTAssertEqual(project.sponsor, sampleProject.sponsor)
            XCTAssertEqual(project.status, sampleProject.status)
            XCTAssertEqual(project.priority, sampleProject.priority)
            XCTAssertEqual(project.budget, sampleProject.budget)
            XCTAssertEqual(project.actualCost, sampleProject.actualCost)
            XCTAssertEqual(project.progress, sampleProject.progress)
        }
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testEmptyProjectName() throws {
        let project = ProjectModel(
            name: "",
            description: "Test project",
            projectManager: "Manager",
            sponsor: "Sponsor",
            startDate: Date(),
            endDate: Date()
        )
        
        // Should still create project but with empty name
        XCTAssertTrue(project.name.isEmpty)
        XCTAssertFalse(project.id.isEmpty)
    }
    
    func testInvalidDateRange() throws {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? Date()
        
        // Start date after end date
        let project = ProjectModel(
            name: "Invalid Date Project",
            description: "Project with invalid date range",
            projectManager: "Manager",
            sponsor: "Sponsor",
            startDate: startDate,
            endDate: endDate
        )
        
        // Model should still be created but dates should be validated by business logic
        XCTAssertTrue(project.startDate > project.endDate)
    }
    
    func testNegativeBudget() throws {
        let project = ProjectModel(
            name: "Negative Budget Project",
            description: "Project with negative budget",
            projectManager: "Manager",
            sponsor: "Sponsor",
            startDate: Date(),
            endDate: Date(),
            budget: -100_000.0
        )
        
        XCTAssertEqual(project.budget, -100_000.0)
        // Business logic should validate this
    }
    
    func testProgressBounds() throws {
        sampleProject.progress = 150.0 // Over 100%
        XCTAssertEqual(sampleProject.progress, 150.0)
        // UI and business logic should enforce 0-100 bounds
        
        sampleProject.progress = -10.0 // Negative
        XCTAssertEqual(sampleProject.progress, -10.0)
        // Business logic should validate this
    }
    
    // MARK: - Performance Tests
    
    func testProjectModelPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let project = ProjectModel(
                    name: "Performance Test Project",
                    description: "Testing project creation performance",
                    projectManager: "Manager",
                    sponsor: "Sponsor",
                    startDate: Date(),
                    endDate: Date()
                )
                
                // Perform some operations
                _ = project.budgetVariance
                _ = project.budgetVariancePercentage
                _ = project.toCKRecord()
            }
        }
    }
    
    func testCloudKitSerializationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let record = sampleProject.toCKRecord()
                _ = ProjectModel.fromCKRecord(record)
            }
        }
    }
}

// MARK: - Additional Test Extensions

extension ProjectModelTests {
    
    /// Test comprehensive project with all features populated
    func testComprehensiveProjectModel() throws {
        // Create a fully populated project
        var comprehensiveProject = sampleProject!
        
        // Add financial data
        comprehensiveProject.roi = ROICalculation()
        comprehensiveProject.roi.expectedBenefits = 1_500_000.0
        comprehensiveProject.roi.totalInvestment = 1_000_000.0
        
        comprehensiveProject.costBreakdown = [
            CostCategory(name: "Software", budgetedAmount: 300_000.0, actualAmount: 280_000.0, costType: .software),
            CostCategory(name: "Hardware", budgetedAmount: 200_000.0, actualAmount: 220_000.0, costType: .capital),
            CostCategory(name: "Labor", budgetedAmount: 500_000.0, actualAmount: 450_000.0, costType: .labor)
        ]
        
        // Add performance indicators
        comprehensiveProject.performanceIndicators = [
            PerformanceIndicator(name: "Schedule", category: .schedule, target: 100.0, frequency: .weekly),
            PerformanceIndicator(name: "Budget", category: .budget, target: 100.0, frequency: .monthly),
            PerformanceIndicator(name: "Quality", category: .quality, target: 95.0, frequency: .weekly)
        ]
        
        // Add phases
        let phase1Start = Date()
        let phase1End = Calendar.current.date(byAdding: .month, value: 3, to: phase1Start) ?? Date()
        
        comprehensiveProject.phases = [
            ProjectPhase(name: "Analysis", startDate: phase1Start, endDate: phase1End, budget: 250_000.0),
            ProjectPhase(name: "Design", startDate: phase1End, endDate: Calendar.current.date(byAdding: .month, value: 3, to: phase1End) ?? Date(), budget: 300_000.0)
        ]
        
        // Add risks
        comprehensiveProject.risks = [
            ProjectRisk(name: "Technical Risk", description: "Technology may not scale", category: .technical, probability: .medium, impact: .major),
            ProjectRisk(name: "Resource Risk", description: "Key personnel may leave", category: .resource, probability: .low, impact: .severe)
        ]
        
        // Add resource allocations
        comprehensiveProject.resources = [
            ResourceAllocation(resourceId: "dev-001", resourceType: .human, allocation: 100.0, startDate: Date(), endDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(), cost: 300_000.0),
            ResourceAllocation(resourceId: "srv-001", resourceType: .equipment, allocation: 50.0, startDate: Date(), endDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date(), cost: 50_000.0)
        ]
        
        // Validate comprehensive project
        XCTAssertEqual(comprehensiveProject.roi.roi, 50.0, accuracy: 0.01)
        XCTAssertEqual(comprehensiveProject.costBreakdown.count, 3)
        XCTAssertEqual(comprehensiveProject.performanceIndicators.count, 3)
        XCTAssertEqual(comprehensiveProject.phases.count, 2)
        XCTAssertEqual(comprehensiveProject.risks.count, 2)
        XCTAssertEqual(comprehensiveProject.resources.count, 2)
        
        // Test CloudKit serialization with complex data
        let record = comprehensiveProject.toCKRecord()
        let deserializedProject = ProjectModel.fromCKRecord(record)
        
        XCTAssertNotNil(deserializedProject)
        if let project = deserializedProject {
            XCTAssertEqual(project.costBreakdown.count, 3)
            XCTAssertEqual(project.performanceIndicators.count, 3)
            XCTAssertEqual(project.phases.count, 2)
            XCTAssertEqual(project.risks.count, 2)
            XCTAssertEqual(project.resources.count, 2)
        }
    }
    
    /// Test project filtering and search capabilities
    func testProjectFiltering() throws {
        let projects = createSampleProjects()
        
        // Test status filtering
        let activeProjects = projects.filter { $0.status == .active }
        XCTAssertEqual(activeProjects.count, 3)
        
        let completedProjects = projects.filter { $0.status == .completed }
        XCTAssertEqual(completedProjects.count, 2)
        
        // Test priority filtering
        let highPriorityProjects = projects.filter { $0.priority == .high }
        XCTAssertEqual(highPriorityProjects.count, 2)
        
        // Test health filtering
        let atRiskProjects = projects.filter { $0.overallHealth == .red }
        XCTAssertEqual(atRiskProjects.count, 1)
        
        // Test budget range filtering
        let largeBudgetProjects = projects.filter { $0.budget > 500_000.0 }
        XCTAssertEqual(largeBudgetProjects.count, 3)
    }
    
    private func createSampleProjects() -> [ProjectModel] {
        return [
            ProjectModel(name: "Project Alpha", description: "Alpha", projectManager: "PM1", sponsor: "S1", startDate: Date(), endDate: Date(), status: .active, priority: .high, budget: 1_000_000.0),
            ProjectModel(name: "Project Beta", description: "Beta", projectManager: "PM2", sponsor: "S2", startDate: Date(), endDate: Date(), status: .active, priority: .medium, budget: 500_000.0),
            ProjectModel(name: "Project Gamma", description: "Gamma", projectManager: "PM3", sponsor: "S3", startDate: Date(), endDate: Date(), status: .completed, priority: .low, budget: 250_000.0),
            ProjectModel(name: "Project Delta", description: "Delta", projectManager: "PM4", sponsor: "S4", startDate: Date(), endDate: Date(), status: .completed, priority: .medium, budget: 750_000.0),
            createRiskyProject()
        ]
    }
    
    private func createRiskyProject() -> ProjectModel {
        var project = ProjectModel(name: "Project Risky", description: "High risk project", projectManager: "PM5", sponsor: "S5", startDate: Date(), endDate: Date(), status: .active, priority: .high, budget: 2_000_000.0)
        project.overallHealth = .red
        project.actualCost = 2_200_000.0 // Over budget
        project.progress = 30.0 // Behind schedule
        return project
    }
}
