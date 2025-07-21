import Foundation
import CloudKit
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let repository: TaskRepository
    
    init(repository: TaskRepository = TaskRepository()) {
        self.repository = repository
    }
    
    func loadTasks() async {
        isLoading = true
        
        do {
            let fetchedTasks = try await repository.fetchAll()
            self.tasks = fetchedTasks
            self.error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func fetchTasks(for user: User) async {
        isLoading = true
        
        do {
            let fetchedTasks = try await repository.fetchTasks(for: user)
            self.tasks = fetchedTasks
            self.error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func createTask(
        title: String,
        description: String,
        priority: TaskPriority,
        status: TaskStatus,
        completionMode: TaskCompletionMode,
        category: String,
        dueDate: Date,
        estimatedDuration: TimeInterval,
        assignee: User?,
        collaborators: [User],
        tags: [String],
        creator: User
    ) async throws -> TaskModel {
        
        let task = TaskModel(
            id: UUID().uuidString,
            title: title,
            description: description,
            priority: priority,
            status: status,
            completionMode: completionMode,
            category: category,
            dueDate: dueDate,
            estimatedDuration: estimatedDuration,
            assignee: assignee,
            creator: creator,
            collaborators: collaborators,
            tags: tags,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save the task
        try await repository.save(task)
        
        // Reload tasks to refresh the list
        await loadTasks()
        
        return task
    }
    
    @MainActor
    func updateTask(_ task: TaskModel) async throws {
        try await repository.save(task)
        await loadTasks()
    }
    
    @MainActor
    func deleteTask(_ task: TaskModel) async throws {
        try await repository.delete(task)
        await loadTasks()
    }
}
