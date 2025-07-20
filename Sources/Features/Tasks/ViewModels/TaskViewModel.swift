import Foundation
import CloudKit
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let database: CKDatabase
    private var subscriptions = Set<AnyCancellable>()
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchTasks(for user: User) {
        isLoading = true
        let userRecordID = CKRecord.ID(recordName: user.userId)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        
        let predicate = NSPredicate(format: "assignedUserRefs CONTAINS %@", userReference)
        let query = CKQuery(recordType: "Task", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = error
                    return
                }
                
                self.tasks = records?.compactMap { TaskModel(record: $0) } ?? []
            }
        }
    }
    
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
}
