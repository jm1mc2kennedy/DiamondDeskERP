// RepositoryFetchTests.swift
// Diamond Desk ERP
// Basic async tests for Task, Ticket, Client, KPI repository fetches

@Suite("Repository fetch and validation")
struct RepositoryFetchTests {
    @Test func testTaskFetch() async throws {
        let repo = CloudKitTaskRepository()
        let tasks = try await repo.fetchAssigned(to: "demo-user-id")
        #expect(tasks != nil, "Tasks should not be nil")
    }

    @Test func testTicketFetch() async throws {
        let repo = CloudKitTicketRepository()
        let tickets = try await repo.fetchAssigned(to: "demo-user-id")
        #expect(tickets != nil, "Tickets should not be nil")
    }

    @Test func testClientFetch() async throws {
        let repo = CloudKitClientRepository()
        let clients = try await repo.fetchAssigned(to: "demo-user-id")
        #expect(clients != nil, "Clients should not be nil")
    }

    @Test func testKPIFetch() async throws {
        let repo = CloudKitKPIRepository()
        let kpis = try await repo.fetchForStore("demo-store")
        #expect(kpis != nil, "KPIs should not be nil")
    }
    
    @Test func testTaskValidationFailsWithEmptyTitle() throws {
        var taskForm = TaskForm()
        taskForm.title = ""
        let isValid = taskForm.validate()
        #expect(!isValid, "Task validation should fail when title is empty")
    }
    
    @Test func testTaskValidationSucceedsWithValidData() throws {
        var taskForm = TaskForm()
        taskForm.title = "New Task"
        taskForm.details = "Details about task"
        let isValid = taskForm.validate()
        #expect(isValid, "Task validation should succeed with valid data")
    }
    
    @Test func testTicketValidationFailsWithEmptyTitle() throws {
        var ticketForm = TicketForm()
        ticketForm.title = ""
        let isValid = ticketForm.validate()
        #expect(!isValid, "Ticket validation should fail when title is empty")
    }
    
    @Test func testTicketValidationSucceedsWithValidData() throws {
        var ticketForm = TicketForm()
        ticketForm.title = "New Ticket"
        ticketForm.description = "Details about ticket"
        let isValid = ticketForm.validate()
        #expect(isValid, "Ticket validation should succeed with valid data")
    }
    
    @Test func testTaskSaveError() async {
        let failingRepo = FailingTaskRepository()
        do {
            let task = Task(title: "Test Task")
            try await failingRepo.save(task)
            #expect(false, "Save should have thrown an error")
        } catch {
            #expect(error as? RepositoryError == .saveFailed, "Expected saveFailed error")
        }
    }
    
    @Test func testTicketSaveError() async {
        let failingRepo = FailingTicketRepository()
        do {
            let ticket = Ticket(title: "Test Ticket")
            try await failingRepo.save(ticket)
            #expect(false, "Save should have thrown an error")
        } catch {
            #expect(error as? RepositoryError == .saveFailed, "Expected saveFailed error")
        }
    }
}

// MARK: - Stub/Mock Repositories and Models for Testing Save Errors and Validation

struct TaskForm {
    var title: String = ""
    var details: String = ""
    
    func validate() -> Bool {
        // Simple validation: title must not be empty
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct TicketForm {
    var title: String = ""
    var description: String = ""
    
    func validate() -> Bool {
        // Simple validation: title must not be empty
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct Task {
    let title: String
}

struct Ticket {
    let title: String
}

enum RepositoryError: Error, Equatable {
    case saveFailed
}

protocol TaskRepository {
    func save(_ task: Task) async throws
}

protocol TicketRepository {
    func save(_ ticket: Ticket) async throws
}

final class FailingTaskRepository: TaskRepository {
    func save(_ task: Task) async throws {
        // Simulate a save failure
        throw RepositoryError.saveFailed
    }
}

final class FailingTicketRepository: TicketRepository {
    func save(_ ticket: Ticket) async throws {
        // Simulate a save failure
        throw RepositoryError.saveFailed
    }
}
