//
//  DiamondDeskERPTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import Testing
import CloudKit
@testable import DiamondDeskERP

@MainActor
struct TaskViewModelTests {
    
    // MARK: - Mock Dependencies
    
    class MockTaskRepository: TaskRepositoryProtocol {
        var shouldFailFetch = false
        var shouldFailSave = false
        var mockTasks: [TaskModel] = []
        var saveCallCount = 0
        var fetchCallCount = 0
        
        func fetchAll() async throws -> [TaskModel] {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            return mockTasks
        }
        
        func save(_ task: TaskModel) async throws {
            saveCallCount += 1
            if shouldFailSave {
                throw CKError(.quotaExceeded)
            }
            // Simulate successful save by adding to mock collection
            mockTasks.append(task)
        }
        
        func delete(_ taskId: String) async throws {
            mockTasks.removeAll { $0.id.recordName == taskId }
        }
        
        func fetchById(_ id: String) async throws -> TaskModel? {
            return mockTasks.first { $0.id.recordName == id }
        }
    }
    
    // MARK: - Test Setup
    
    func createMockTask(
        title: String = "Test Task",
        status: TaskStatus = .pending,
        priority: TaskPriority = .medium
    ) -> TaskModel {
        return TaskModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: title,
            description: "Test Description",
            status: status,
            priority: priority,
            dueDate: Date().addingTimeInterval(86400), // Tomorrow
            estimatedHours: 2.0,
            tags: ["test"],
            assignedUserRefs: [],
            storeCodes: ["08"],
            departments: ["QA"],
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
    }
    
    // MARK: - Initialization Tests
    
    @Test("TaskViewModel initializes with empty state")
    func testInitialization() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.filteredTasks.isEmpty)
    }
    
    // MARK: - Loading Tests
    
    @Test("loadTasks successfully fetches tasks")
    func testLoadTasksSuccess() async throws {
        let mockRepository = MockTaskRepository()
        let mockTask = createMockTask()
        mockRepository.mockTasks = [mockTask]
        
        let viewModel = TaskViewModel(repository: mockRepository)
        
        await viewModel.loadTasks()
        
        #expect(mockRepository.fetchCallCount == 1)
        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "Test Task")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test("loadTasks handles fetch failure")
    func testLoadTasksFailure() async throws {
        let mockRepository = MockTaskRepository()
        mockRepository.shouldFailFetch = true
        
        let viewModel = TaskViewModel(repository: mockRepository)
        
        await viewModel.loadTasks()
        
        #expect(mockRepository.fetchCallCount == 1)
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("loadTasks sets loading state correctly")
    func testLoadTasksLoadingState() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        // Start loading
        let loadingTask = Task {
            await viewModel.loadTasks()
        }
        
        // Check loading state is set
        #expect(viewModel.isLoading == true)
        
        await loadingTask.value
        
        // Check loading state is cleared
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Create Task Tests
    
    @Test("createTask successfully saves new task")
    func testCreateTaskSuccess() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let newTask = createMockTask(title: "New Task")
        
        await viewModel.createTask(newTask)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.mockTasks.count == 1)
        #expect(mockRepository.mockTasks.first?.title == "New Task")
        #expect(viewModel.error == nil)
    }
    
    @Test("createTask handles save failure")
    func testCreateTaskFailure() async throws {
        let mockRepository = MockTaskRepository()
        mockRepository.shouldFailSave = true
        
        let viewModel = TaskViewModel(repository: mockRepository)
        let newTask = createMockTask()
        
        await viewModel.createTask(newTask)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.mockTasks.isEmpty)
        #expect(viewModel.error != nil)
    }
    
    @Test("createTask adds task to local collection on success")
    func testCreateTaskUpdatesLocalCollection() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let newTask = createMockTask(title: "Local Task")
        
        await viewModel.createTask(newTask)
        
        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "Local Task")
    }
    
    // MARK: - Update Task Tests
    
    @Test("updateTask successfully saves changes")
    func testUpdateTaskSuccess() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        var task = createMockTask(title: "Original Title")
        mockRepository.mockTasks = [task]
        viewModel.tasks = [task]
        
        task.title = "Updated Title"
        
        await viewModel.updateTask(task)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(viewModel.error == nil)
        
        // Check local collection is updated
        let updatedTask = viewModel.tasks.first { $0.id == task.id }
        #expect(updatedTask?.title == "Updated Title")
    }
    
    @Test("updateTask handles save failure")
    func testUpdateTaskFailure() async throws {
        let mockRepository = MockTaskRepository()
        mockRepository.shouldFailSave = true
        
        let viewModel = TaskViewModel(repository: mockRepository)
        let task = createMockTask()
        
        await viewModel.updateTask(task)
        
        #expect(viewModel.error != nil)
    }
    
    // MARK: - Delete Task Tests
    
    @Test("deleteTask removes task from collection")
    func testDeleteTaskSuccess() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let task = createMockTask()
        mockRepository.mockTasks = [task]
        viewModel.tasks = [task]
        
        await viewModel.deleteTask(task.id.recordName)
        
        #expect(mockRepository.mockTasks.isEmpty)
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Filtering Tests
    
    @Test("filterTasks by status works correctly")
    func testFilterTasksByStatus() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let pendingTask = createMockTask(title: "Pending", status: .pending)
        let completedTask = createMockTask(title: "Completed", status: .completed)
        
        viewModel.tasks = [pendingTask, completedTask]
        viewModel.filterTasks(by: .pending)
        
        #expect(viewModel.filteredTasks.count == 1)
        #expect(viewModel.filteredTasks.first?.status == .pending)
    }
    
    @Test("filterTasks by priority works correctly")
    func testFilterTasksByPriority() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let highTask = createMockTask(title: "High Priority", priority: .high)
        let lowTask = createMockTask(title: "Low Priority", priority: .low)
        
        viewModel.tasks = [highTask, lowTask]
        viewModel.filterTasks(by: .high)
        
        #expect(viewModel.filteredTasks.count == 1)
        #expect(viewModel.filteredTasks.first?.priority == .high)
    }
    
    @Test("clearFilters shows all tasks")
    func testClearFilters() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let task1 = createMockTask(title: "Task 1", status: .pending)
        let task2 = createMockTask(title: "Task 2", status: .completed)
        
        viewModel.tasks = [task1, task2]
        viewModel.filterTasks(by: .pending) // Filter first
        viewModel.clearFilters()
        
        #expect(viewModel.filteredTasks.count == 2)
    }
    
    // MARK: - Search Tests
    
    @Test("searchTasks finds matching titles")
    func testSearchTasksByTitle() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let task1 = createMockTask(title: "Important Meeting")
        let task2 = createMockTask(title: "Code Review")
        
        viewModel.tasks = [task1, task2]
        viewModel.searchTasks(query: "Meeting")
        
        #expect(viewModel.filteredTasks.count == 1)
        #expect(viewModel.filteredTasks.first?.title.contains("Meeting") == true)
    }
    
    @Test("searchTasks is case insensitive")
    func testSearchTasksCaseInsensitive() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let task = createMockTask(title: "Important Meeting")
        viewModel.tasks = [task]
        viewModel.searchTasks(query: "important")
        
        #expect(viewModel.filteredTasks.count == 1)
    }
    
    @Test("empty search query shows all tasks")
    func testEmptySearchQuery() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let task1 = createMockTask(title: "Task 1")
        let task2 = createMockTask(title: "Task 2")
        
        viewModel.tasks = [task1, task2]
        viewModel.searchTasks(query: "")
        
        #expect(viewModel.filteredTasks.count == 2)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("clearError resets error state")
    func testClearError() async throws {
        let mockRepository = MockTaskRepository()
        mockRepository.shouldFailFetch = true
        
        let viewModel = TaskViewModel(repository: mockRepository)
        
        await viewModel.loadTasks() // This should set an error
        #expect(viewModel.error != nil)
        
        viewModel.clearError()
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Validation Tests
    
    @Test("validateTask catches empty title")
    func testValidateTaskEmptyTitle() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        var task = createMockTask()
        task.title = ""
        
        let isValid = viewModel.validateTask(task)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateTask catches past due date")
    func testValidateTaskPastDueDate() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        var task = createMockTask()
        task.dueDate = Date().addingTimeInterval(-86400) // Yesterday
        
        let isValid = viewModel.validateTask(task)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateTask passes for valid task")
    func testValidateTaskValid() async throws {
        let mockRepository = MockTaskRepository()
        let viewModel = TaskViewModel(repository: mockRepository)
        
        let task = createMockTask()
        
        let isValid = viewModel.validateTask(task)
        
        #expect(isValid == true)
        #expect(viewModel.error == nil)
    }
}
