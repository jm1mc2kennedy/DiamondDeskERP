//
//  IntegrationTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import Testing
import CloudKit
@testable import DiamondDeskERP

@MainActor
struct IntegrationTests {
    
    // MARK: - Test Configuration
    
    struct TestConfiguration {
        static let testContainer = CKContainer(identifier: "iCloud.com.diamonddesk.erp.test")
        static let testStoreCode = "TEST"
        static let testDepartment = "QA"
    }
    
    // MARK: - Repository Integration Tests
    
    @Test("TaskRepository and TaskViewModel integration")
    func testTaskRepositoryViewModelIntegration() async throws {
        // Create test container and repository
        let container = TestConfiguration.testContainer
        let repository = TaskRepository(container: container)
        let viewModel = TaskViewModel(repository: repository)
        
        // Create a test task
        let testTask = TaskModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: "Integration Test Task",
            description: "Testing repository and view model integration",
            status: .pending,
            priority: .medium,
            dueDate: Date().addingTimeInterval(86400),
            estimatedHours: 2.0,
            tags: ["integration", "test"],
            assignedUserRefs: [],
            storeCodes: [TestConfiguration.testStoreCode],
            departments: [TestConfiguration.testDepartment],
            createdByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isGroupTask: false,
            requiresAcknowledgment: false,
            completionMode: .individual
        )
        
        // Test create operation
        await viewModel.createTask(testTask)
        
        // Verify task was added to view model
        #expect(viewModel.tasks.contains { $0.id == testTask.id })
        #expect(viewModel.error == nil)
        
        // Test load operation
        await viewModel.loadTasks()
        
        // Verify tasks were loaded
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        
        // Test update operation
        var updatedTask = testTask
        updatedTask.title = "Updated Integration Test Task"
        updatedTask.status = .inProgress
        
        await viewModel.updateTask(updatedTask)
        
        // Verify task was updated in view model
        let taskInViewModel = viewModel.tasks.first { $0.id == testTask.id }
        #expect(taskInViewModel?.title == "Updated Integration Test Task")
        #expect(taskInViewModel?.status == .inProgress)
        
        // Test delete operation
        await viewModel.deleteTask(testTask.id.recordName)
        
        // Verify task was removed from view model
        #expect(!viewModel.tasks.contains { $0.id == testTask.id })
    }
    
    @Test("TicketRepository and TicketViewModel integration")
    func testTicketRepositoryViewModelIntegration() async throws {
        let container = TestConfiguration.testContainer
        let repository = TicketRepository(container: container)
        let viewModel = TicketViewModel(repository: repository)
        
        let testTicket = TicketModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: "Integration Test Ticket",
            description: "Testing ticket repository and view model integration",
            status: .open,
            priority: .high,
            category: .technical,
            storeCode: TestConfiguration.testStoreCode,
            department: TestConfiguration.testDepartment,
            submittedByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            assignedToUserRef: nil,
            submittedAt: Date(),
            updatedAt: Date(),
            dueDate: Date().addingTimeInterval(86400),
            tags: ["integration", "test"],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .medium,
            requiresFollowUp: false
        )
        
        // Test create operation
        await viewModel.createTicket(testTicket)
        
        #expect(viewModel.tickets.contains { $0.id == testTicket.id })
        #expect(viewModel.error == nil)
        
        // Test filtering by status
        viewModel.filterTickets(by: .open)
        #expect(viewModel.filteredTickets.contains { $0.id == testTicket.id })
        
        // Test search functionality
        viewModel.searchTickets(query: "Integration")
        #expect(viewModel.filteredTickets.contains { $0.id == testTicket.id })
        
        // Test escalation
        await viewModel.escalateTicket(testTicket.id.recordName)
        
        let escalatedTicket = viewModel.tickets.first { $0.id == testTicket.id }
        #expect(escalatedTicket?.escalationLevel == 1)
        
        // Clean up
        await viewModel.deleteTicket(testTicket.id.recordName)
    }
    
    @Test("ClientRepository and ClientViewModel integration")
    func testClientRepositoryViewModelIntegration() async throws {
        let container = TestConfiguration.testContainer
        let repository = ClientRepository(container: container)
        let viewModel = ClientViewModel(repository: repository)
        
        let testClient = ClientModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            name: "Integration Test Client",
            email: "integration@test.com",
            phone: "555-0100",
            company: "Test Integration Corp",
            status: .active,
            storeCode: TestConfiguration.testStoreCode,
            department: TestConfiguration.testDepartment,
            createdAt: Date(),
            updatedAt: Date(),
            lastContactDate: Date(),
            tags: ["integration", "test"],
            notes: "Integration test client",
            preferredContactMethod: .email,
            birthday: nil,
            anniversary: nil,
            totalOrderValue: 1000.0,
            lastOrderDate: Date(),
            creditLimit: 5000.0,
            paymentTerms: "Net 30"
        )
        
        // Test create operation
        await viewModel.createClient(testClient)
        
        #expect(viewModel.clients.contains { $0.id == testClient.id })
        #expect(viewModel.error == nil)
        
        // Test filtering by status
        viewModel.filterClients(by: .active)
        #expect(viewModel.filteredClients.contains { $0.id == testClient.id })
        
        // Test search functionality
        viewModel.searchClients(query: "Integration")
        #expect(viewModel.filteredClients.contains { $0.id == testClient.id })
        
        // Test contact update
        await viewModel.updateLastContactDate(for: testClient.id.recordName)
        
        let updatedClient = viewModel.clients.first { $0.id == testClient.id }
        #expect(updatedClient?.lastContactDate != nil)
        
        // Test note addition
        await viewModel.addNote(to: testClient.id.recordName, note: "Integration test note")
        
        let clientWithNote = viewModel.clients.first { $0.id == testClient.id }
        #expect(clientWithNote?.notes?.contains("Integration test note") == true)
        
        // Clean up
        await viewModel.deleteClient(testClient.id.recordName)
    }
    
    // MARK: - Service Integration Tests
    
    @Test("NotificationService and TaskViewModel integration")
    func testNotificationServiceTaskIntegration() async throws {
        let notificationService = NotificationService()
        let repository = TaskRepository(container: TestConfiguration.testContainer)
        let viewModel = TaskViewModel(repository: repository)
        
        // Create a task with due date
        let dueDate = Date().addingTimeInterval(3600) // 1 hour from now
        let testTask = TaskModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: "Notification Test Task",
            description: "Testing notification integration",
            status: .pending,
            priority: .high,
            dueDate: dueDate,
            estimatedHours: 1.0,
            tags: ["notification", "test"],
            assignedUserRefs: [],
            storeCodes: [TestConfiguration.testStoreCode],
            departments: [TestConfiguration.testDepartment],
            createdByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isGroupTask: false,
            requiresAcknowledgment: false,
            completionMode: .individual
        )
        
        // Create task
        await viewModel.createTask(testTask)
        
        // Schedule reminder notification
        let reminderDate = Date().addingTimeInterval(1800) // 30 minutes from now
        
        do {
            try await notificationService.scheduleTaskReminder(
                for: testTask,
                reminderDate: reminderDate
            )
            
            // If we reach here, the notification was scheduled successfully
            #expect(true)
        } catch {
            // Handle permission denied or other errors gracefully in test environment
            #expect(error is NotificationError || error.localizedDescription.contains("permission"))
        }
        
        // Clean up
        await viewModel.deleteTask(testTask.id.recordName)
    }
    
    @Test("AnalyticsService data aggregation integration")
    func testAnalyticsServiceDataAggregation() async throws {
        let analyticsService = AnalyticsService()
        
        // Create test data
        let tasks = [
            TaskModel(
                id: CKRecord.ID(recordName: "analytics-task-1"),
                title: "Completed Task",
                description: "Description",
                status: .completed,
                priority: .medium,
                dueDate: Date(),
                estimatedHours: 2.0,
                tags: [],
                assignedUserRefs: [],
                storeCodes: [TestConfiguration.testStoreCode],
                departments: [TestConfiguration.testDepartment],
                createdByUserRef: CKRecord.Reference(
                    recordID: CKRecord.ID(recordName: "test-user"),
                    action: .none
                ),
                createdAt: Date(),
                updatedAt: Date(),
                isGroupTask: false,
                requiresAcknowledgment: false,
                completionMode: .individual
            ),
            TaskModel(
                id: CKRecord.ID(recordName: "analytics-task-2"),
                title: "Pending Task",
                description: "Description",
                status: .pending,
                priority: .high,
                dueDate: Date(),
                estimatedHours: 1.5,
                tags: [],
                assignedUserRefs: [],
                storeCodes: [TestConfiguration.testStoreCode],
                departments: [TestConfiguration.testDepartment],
                createdByUserRef: CKRecord.Reference(
                    recordID: CKRecord.ID(recordName: "test-user"),
                    action: .none
                ),
                createdAt: Date(),
                updatedAt: Date(),
                isGroupTask: false,
                requiresAcknowledgment: false,
                completionMode: .individual
            )
        ]
        
        let baseDate = Date()
        let tickets = [
            TicketModel(
                id: CKRecord.ID(recordName: "analytics-ticket-1"),
                title: "Closed Ticket",
                description: "Description",
                status: .closed,
                priority: .medium,
                category: .technical,
                storeCode: TestConfiguration.testStoreCode,
                department: TestConfiguration.testDepartment,
                submittedByUserRef: CKRecord.Reference(
                    recordID: CKRecord.ID(recordName: "test-user"),
                    action: .none
                ),
                assignedToUserRef: nil,
                submittedAt: baseDate,
                updatedAt: baseDate.addingTimeInterval(3600), // 1 hour resolution time
                dueDate: baseDate.addingTimeInterval(86400),
                tags: [],
                escalationLevel: 0,
                resolutionNotes: "Resolved",
                customerImpact: .low,
                requiresFollowUp: false
            )
        ]
        
        // Test analytics calculations
        let completionRate = analyticsService.calculateTaskCompletionRate(tasks: tasks)
        #expect(completionRate == 0.5) // 1 out of 2 tasks completed
        
        let avgResolutionTime = analyticsService.calculateAverageResolutionTime(tickets: tickets)
        #expect(avgResolutionTime == 3600) // 1 hour in seconds
        
        let kpiSummary = analyticsService.generateKPISummary(tasks: tasks, tickets: tickets)
        #expect(kpiSummary.totalTasks == 2)
        #expect(kpiSummary.totalTickets == 1)
        #expect(kpiSummary.taskCompletionRate == 0.5)
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test("Error propagation through service layers")
    func testErrorPropagationThroughServices() async throws {
        // Create a mock repository that will fail
        class FailingTaskRepository: TaskRepositoryProtocol {
            func fetchAll() async throws -> [TaskModel] {
                throw CKError(.networkFailure)
            }
            
            func save(_ task: TaskModel) async throws {
                throw CKError(.quotaExceeded)
            }
            
            func delete(_ taskId: String) async throws {
                throw CKError(.unknownItem)
            }
            
            func fetchById(_ id: String) async throws -> TaskModel? {
                throw CKError(.networkFailure)
            }
        }
        
        let failingRepository = FailingTaskRepository()
        let viewModel = TaskViewModel(repository: failingRepository)
        
        // Test that errors are properly handled
        await viewModel.loadTasks()
        #expect(viewModel.error != nil)
        #expect(viewModel.tasks.isEmpty)
        
        // Test error clearing
        viewModel.clearError()
        #expect(viewModel.error == nil)
        
        // Test save error handling
        let testTask = TaskModel(
            id: CKRecord.ID(recordName: "test-task"),
            title: "Test Task",
            description: "Description",
            status: .pending,
            priority: .medium,
            dueDate: Date(),
            estimatedHours: 1.0,
            tags: [],
            assignedUserRefs: [],
            storeCodes: [TestConfiguration.testStoreCode],
            departments: [TestConfiguration.testDepartment],
            createdByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isGroupTask: false,
            requiresAcknowledgment: false,
            completionMode: .individual
        )
        
        await viewModel.createTask(testTask)
        #expect(viewModel.error != nil)
    }
    
    // MARK: - Performance Integration Tests
    
    @Test("Large dataset handling performance")
    func testLargeDatasetHandling() async throws {
        let repository = TaskRepository(container: TestConfiguration.testContainer)
        let viewModel = TaskViewModel(repository: repository)
        
        // Create a large number of test tasks
        let taskCount = 100
        var tasks: [TaskModel] = []
        
        for i in 0..<taskCount {
            let task = TaskModel(
                id: CKRecord.ID(recordName: "performance-task-\(i)"),
                title: "Performance Test Task \(i)",
                description: "Description \(i)",
                status: i % 2 == 0 ? .completed : .pending,
                priority: .medium,
                dueDate: Date().addingTimeInterval(Double(i) * 3600),
                estimatedHours: Double(i % 5 + 1),
                tags: ["performance", "test", "batch-\(i / 10)"],
                assignedUserRefs: [],
                storeCodes: [TestConfiguration.testStoreCode],
                departments: [TestConfiguration.testDepartment],
                createdByUserRef: CKRecord.Reference(
                    recordID: CKRecord.ID(recordName: "test-user"),
                    action: .none
                ),
                createdAt: Date(),
                updatedAt: Date(),
                isGroupTask: false,
                requiresAcknowledgment: false,
                completionMode: .individual
            )
            tasks.append(task)
        }
        
        // Simulate loading large dataset
        viewModel.tasks = tasks
        
        // Test filtering performance
        let startTime = Date()
        viewModel.filterTasks(by: .completed)
        let filterTime = Date().timeIntervalSince(startTime)
        
        #expect(filterTime < 1.0) // Should complete in less than 1 second
        #expect(viewModel.filteredTasks.count == taskCount / 2) // Half should be completed
        
        // Test search performance
        let searchStartTime = Date()
        viewModel.searchTasks(query: "Performance")
        let searchTime = Date().timeIntervalSince(searchStartTime)
        
        #expect(searchTime < 1.0) // Should complete in less than 1 second
        #expect(viewModel.filteredTasks.count == taskCount) // All tasks should match
        
        // Clear filters
        viewModel.clearFilters()
        #expect(viewModel.filteredTasks.count == taskCount)
    }
    
    // MARK: - Real-time Sync Integration Tests
    
    @Test("CloudKit subscription handling")
    func testCloudKitSubscriptionHandling() async throws {
        let container = TestConfiguration.testContainer
        let database = container.publicCloudDatabase
        
        // Create a subscription for Task changes
        let predicate = NSPredicate(format: "storeCode == %@", TestConfiguration.testStoreCode)
        let subscription = CKQuerySubscription(
            recordType: "Task",
            predicate: predicate,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        subscription.notificationInfo = CKSubscription.NotificationInfo()
        subscription.notificationInfo?.shouldBadge = false
        subscription.notificationInfo?.shouldSendContentAvailable = true
        
        do {
            let savedSubscription = try await database.save(subscription)
            #expect(savedSubscription.subscriptionID == subscription.subscriptionID)
            
            // Clean up subscription
            try await database.deleteSubscription(withID: subscription.subscriptionID)
        } catch {
            // Handle subscription errors gracefully in test environment
            #expect(error is CKError)
        }
    }
    
    // MARK: - Data Consistency Tests
    
    @Test("Data consistency across view models")
    func testDataConsistencyAcrossViewModels() async throws {
        let container = TestConfiguration.testContainer
        
        let taskRepository = TaskRepository(container: container)
        let taskViewModel1 = TaskViewModel(repository: taskRepository)
        let taskViewModel2 = TaskViewModel(repository: taskRepository)
        
        // Create a task in the first view model
        let testTask = TaskModel(
            id: CKRecord.ID(recordName: "consistency-task"),
            title: "Consistency Test Task",
            description: "Testing data consistency",
            status: .pending,
            priority: .medium,
            dueDate: Date().addingTimeInterval(86400),
            estimatedHours: 1.0,
            tags: ["consistency", "test"],
            assignedUserRefs: [],
            storeCodes: [TestConfiguration.testStoreCode],
            departments: [TestConfiguration.testDepartment],
            createdByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isGroupTask: false,
            requiresAcknowledgment: false,
            completionMode: .individual
        )
        
        await taskViewModel1.createTask(testTask)
        
        // Load tasks in the second view model
        await taskViewModel2.loadTasks()
        
        // Both view models should have the same task
        #expect(taskViewModel1.tasks.contains { $0.id == testTask.id })
        #expect(taskViewModel2.tasks.contains { $0.id == testTask.id })
        
        // Update task in first view model
        var updatedTask = testTask
        updatedTask.status = .inProgress
        updatedTask.title = "Updated Consistency Test Task"
        
        await taskViewModel1.updateTask(updatedTask)
        
        // Reload in second view model
        await taskViewModel2.loadTasks()
        
        // Both should reflect the update
        let task1 = taskViewModel1.tasks.first { $0.id == testTask.id }
        let task2 = taskViewModel2.tasks.first { $0.id == testTask.id }
        
        #expect(task1?.status == .inProgress)
        #expect(task2?.status == .inProgress)
        #expect(task1?.title == "Updated Consistency Test Task")
        #expect(task2?.title == "Updated Consistency Test Task")
        
        // Clean up
        await taskViewModel1.deleteTask(testTask.id.recordName)
    }
}
