#if canImport(XCTest)
import CloudKit
import XCTest

final class WorkflowServiceTests: XCTestCase {
    
    var mockService: MockWorkflowService!
    var sampleWorkflow: Workflow!
    
    override func setUp() {
        super.setUp()
        mockService = MockWorkflowService()
        sampleWorkflow = Workflow(
            name: "Test Workflow",
            description: "A test workflow for unit testing",
            triggerType: .manual,
            createdBy: "test_user"
        )
    }
    
    override func tearDown() {
        mockService = nil
        sampleWorkflow = nil
        super.tearDown()
    }
    
    // MARK: - Create Workflow Tests
    
    func testCreateWorkflow() async throws {
        // Given
        let initialCount = try await mockService.fetchWorkflows().count
        
        // When
        let createdWorkflow = try await mockService.createWorkflow(sampleWorkflow)
        
        // Then
        XCTAssertEqual(createdWorkflow.name, sampleWorkflow.name)
        XCTAssertEqual(createdWorkflow.description, sampleWorkflow.description)
        XCTAssertEqual(createdWorkflow.triggerType, sampleWorkflow.triggerType)
        XCTAssertEqual(createdWorkflow.createdBy, sampleWorkflow.createdBy)
        
        let finalCount = try await mockService.fetchWorkflows().count
        XCTAssertEqual(finalCount, initialCount + 1)
    }
    
    // MARK: - Fetch Workflow Tests
    
    func testFetchWorkflows() async throws {
        // Given
        _ = try await mockService.createWorkflow(sampleWorkflow)
        
        // When
        let workflows = try await mockService.fetchWorkflows()
        
        // Then
        XCTAssertFalse(workflows.isEmpty)
        XCTAssertTrue(workflows.contains { $0.name == sampleWorkflow.name })
    }
    
    func testFetchWorkflowById() async throws {
        // Given
        let createdWorkflow = try await mockService.createWorkflow(sampleWorkflow)
        
        // When
        let fetchedWorkflow = try await mockService.fetchWorkflow(by: createdWorkflow.id)
        
        // Then
        XCTAssertNotNil(fetchedWorkflow)
        XCTAssertEqual(fetchedWorkflow?.id, createdWorkflow.id)
        XCTAssertEqual(fetchedWorkflow?.name, createdWorkflow.name)
    }
    
    func testFetchNonExistentWorkflow() async throws {
        // When
        let fetchedWorkflow = try await mockService.fetchWorkflow(by: "non-existent-id")
        
        // Then
        XCTAssertNil(fetchedWorkflow)
    }
    
    // MARK: - Update Workflow Tests
    
    func testUpdateWorkflow() async throws {
        // Given
        let createdWorkflow = try await mockService.createWorkflow(sampleWorkflow)
        var updatedWorkflow = createdWorkflow
        updatedWorkflow.name = "Updated Test Workflow"
        updatedWorkflow.description = "Updated description"
        
        // When
        let result = try await mockService.updateWorkflow(updatedWorkflow)
        
        // Then
        XCTAssertEqual(result.name, "Updated Test Workflow")
        XCTAssertEqual(result.description, "Updated description")
        
        let fetchedWorkflow = try await mockService.fetchWorkflow(by: createdWorkflow.id)
        XCTAssertEqual(fetchedWorkflow?.name, "Updated Test Workflow")
    }
    
    // MARK: - Delete Workflow Tests
    
    func testDeleteWorkflow() async throws {
        // Given
        let createdWorkflow = try await mockService.createWorkflow(sampleWorkflow)
        let initialCount = try await mockService.fetchWorkflows().count
        
        // When
        try await mockService.deleteWorkflow(id: createdWorkflow.id)
        
        // Then
        let finalCount = try await mockService.fetchWorkflows().count
        XCTAssertEqual(finalCount, initialCount - 1)
        
        let fetchedWorkflow = try await mockService.fetchWorkflow(by: createdWorkflow.id)
        XCTAssertNil(fetchedWorkflow)
    }
    
    // MARK: - Filter Tests
    
    func testFetchWorkflowsByType() async throws {
        // Given
        let manualWorkflow = Workflow(name: "Manual", triggerType: .manual, createdBy: "test")
        let scheduledWorkflow = Workflow(name: "Scheduled", triggerType: .scheduled, createdBy: "test")
        
        _ = try await mockService.createWorkflow(manualWorkflow)
        _ = try await mockService.createWorkflow(scheduledWorkflow)
        
        // When
        let manualWorkflows = try await mockService.fetchWorkflowsByType(.manual)
        let scheduledWorkflows = try await mockService.fetchWorkflowsByType(.scheduled)
        
        // Then
        XCTAssertTrue(manualWorkflows.contains { $0.name == "Manual" })
        XCTAssertFalse(manualWorkflows.contains { $0.name == "Scheduled" })
        XCTAssertTrue(scheduledWorkflows.contains { $0.name == "Scheduled" })
        XCTAssertFalse(scheduledWorkflows.contains { $0.name == "Manual" })
    }
    
    func testFetchActiveWorkflows() async throws {
        // Given
        let activeWorkflow = Workflow(name: "Active", triggerType: .manual, isActive: true, createdBy: "test")
        let inactiveWorkflow = Workflow(name: "Inactive", triggerType: .manual, isActive: false, createdBy: "test")
        
        _ = try await mockService.createWorkflow(activeWorkflow)
        _ = try await mockService.createWorkflow(inactiveWorkflow)
        
        // When
        let activeWorkflows = try await mockService.fetchActiveWorkflows()
        
        // Then
        XCTAssertTrue(activeWorkflows.contains { $0.name == "Active" })
        XCTAssertFalse(activeWorkflows.contains { $0.name == "Inactive" })
    }
    
    func testFetchWorkflowsByUser() async throws {
        // Given
        let user1Workflow = Workflow(name: "User1", triggerType: .manual, createdBy: "user1")
        let user2Workflow = Workflow(name: "User2", triggerType: .manual, createdBy: "user2")
        
        _ = try await mockService.createWorkflow(user1Workflow)
        _ = try await mockService.createWorkflow(user2Workflow)
        
        // When
        let user1Workflows = try await mockService.fetchWorkflowsByUser("user1")
        let user2Workflows = try await mockService.fetchWorkflowsByUser("user2")
        
        // Then
        XCTAssertTrue(user1Workflows.contains { $0.name == "User1" })
        XCTAssertFalse(user1Workflows.contains { $0.name == "User2" })
        XCTAssertTrue(user2Workflows.contains { $0.name == "User2" })
        XCTAssertFalse(user2Workflows.contains { $0.name == "User1" })
    }
    
    // MARK: - Status Toggle Tests
    
    func testToggleWorkflowStatus() async throws {
        // Given
        let activeWorkflow = try await mockService.createWorkflow(sampleWorkflow)
        XCTAssertTrue(activeWorkflow.isActive)
        
        // When - Deactivate
        let deactivatedWorkflow = try await mockService.toggleWorkflowStatus(id: activeWorkflow.id, isActive: false)
        
        // Then
        XCTAssertFalse(deactivatedWorkflow.isActive)
        
        // When - Reactivate
        let reactivatedWorkflow = try await mockService.toggleWorkflowStatus(id: activeWorkflow.id, isActive: true)
        
        // Then
        XCTAssertTrue(reactivatedWorkflow.isActive)
    }
    
    // MARK: - Execution Tests
    
    func testExecuteWorkflow() async throws {
        // Given
        let createdWorkflow = try await mockService.createWorkflow(sampleWorkflow)
        XCTAssertTrue(createdWorkflow.isActive)
        
        // When
        let execution = try await mockService.executeWorkflow(id: createdWorkflow.id, context: ["test": "data"])
        
        // Then
        XCTAssertEqual(execution.workflowId, createdWorkflow.id)
        XCTAssertEqual(execution.status, .completed)
        XCTAssertNotNil(execution.startedAt)
    }
    
    func testExecuteInactiveWorkflow() async throws {
        // Given
        var inactiveWorkflow = sampleWorkflow!
        inactiveWorkflow.isActive = false
        let createdWorkflow = try await mockService.createWorkflow(inactiveWorkflow)
        
        // When/Then
        do {
            _ = try await mockService.executeWorkflow(id: createdWorkflow.id, context: nil)
            XCTFail("Should have thrown an error for inactive workflow")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is WorkflowServiceError)
        }
    }
    
    // MARK: - Search Tests
    
    func testSearchWorkflows() async throws {
        // Given
        let workflow1 = Workflow(name: "Data Processing", description: "Processes customer data", triggerType: .manual, createdBy: "test")
        let workflow2 = Workflow(name: "Email Notification", description: "Sends email alerts", triggerType: .manual, createdBy: "test")
        
        _ = try await mockService.createWorkflow(workflow1)
        _ = try await mockService.createWorkflow(workflow2)
        
        // When
        let dataResults = try await mockService.searchWorkflows(query: "data")
        let emailResults = try await mockService.searchWorkflows(query: "email")
        let processingResults = try await mockService.searchWorkflows(query: "processing")
        
        // Then
        XCTAssertTrue(dataResults.contains { $0.name == "Data Processing" })
        XCTAssertFalse(dataResults.contains { $0.name == "Email Notification" })
        
        XCTAssertTrue(emailResults.contains { $0.name == "Email Notification" })
        XCTAssertFalse(emailResults.contains { $0.name == "Data Processing" })
        
        XCTAssertTrue(processingResults.contains { $0.name == "Data Processing" })
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceCreateMultipleWorkflows() {
        measure {
            Task {
                for i in 0..<100 {
                    let workflow = Workflow(
                        name: "Performance Test \(i)",
                        triggerType: .manual,
                        createdBy: "test"
                    )
                    _ = try? await mockService.createWorkflow(workflow)
                }
            }
        }
    }
    
    func testPerformanceFetchWorkflows() async throws {
        // Given - Create multiple workflows
        for i in 0..<50 {
            let workflow = Workflow(
                name: "Workflow \(i)",
                triggerType: .manual,
                createdBy: "test"
            )
            _ = try await mockService.createWorkflow(workflow)
        }
        
        // When/Then
        measure {
            Task {
                _ = try? await mockService.fetchWorkflows()
            }
        }
    }
}

// MARK: - CloudKit Extensions Tests

final class WorkflowCloudKitTests: XCTestCase {
    
    func testWorkflowCloudKitSerialization() {
        // Given
        let workflow = Workflow(
            id: "test-id",
            name: "Test Workflow",
            description: "Test description",
            triggerType: .scheduled,
            isActive: true,
            createdBy: "test_user",
            createdAt: Date(),
            tags: ["test", "automation"]
        )
        
        // When
        let record = workflow.toCKRecord()
        let deserializedWorkflow = Workflow.from(record: record)
        
        // Then
        XCTAssertNotNil(deserializedWorkflow)
        XCTAssertEqual(deserializedWorkflow?.id, workflow.id)
        XCTAssertEqual(deserializedWorkflow?.name, workflow.name)
        XCTAssertEqual(deserializedWorkflow?.description, workflow.description)
        XCTAssertEqual(deserializedWorkflow?.triggerType, workflow.triggerType)
        XCTAssertEqual(deserializedWorkflow?.isActive, workflow.isActive)
        XCTAssertEqual(deserializedWorkflow?.createdBy, workflow.createdBy)
        XCTAssertEqual(deserializedWorkflow?.tags, workflow.tags)
    }
    
    func testWorkflowExecutionCloudKitSerialization() {
        // Given
        let execution = WorkflowExecution(
            id: "execution-id",
            workflowId: "workflow-id",
            status: .completed,
            startedAt: Date(),
            completedAt: Date(),
            triggeredBy: "test_user",
            triggerMethod: "manual"
        )
        
        // When
        let record = execution.toCKRecord()
        let deserializedExecution = WorkflowExecution.from(record: record)
        
        // Then
        XCTAssertNotNil(deserializedExecution)
        XCTAssertEqual(deserializedExecution?.id, execution.id)
        XCTAssertEqual(deserializedExecution?.workflowId, execution.workflowId)
        XCTAssertEqual(deserializedExecution?.status, execution.status)
        XCTAssertEqual(deserializedExecution?.triggeredBy, execution.triggeredBy)
        XCTAssertEqual(deserializedExecution?.triggerMethod, execution.triggerMethod)
    }
}
#endif
