import Foundation
import CloudKit
import Combine

@MainActor
class TicketViewModel: ObservableObject {
    @Published var tickets: [TicketModel] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let repository: TicketRepository
    
    init(repository: TicketRepository = TicketRepository()) {
        self.repository = repository
    }
    
    func loadTickets() async {
        isLoading = true
        
        do {
            let fetchedTickets = try await repository.fetchAll()
            self.tickets = fetchedTickets
            self.error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func fetchTickets(for user: User) async {
        isLoading = true
        
        do {
            let fetchedTickets = try await repository.fetchTickets(for: user)
            self.tickets = fetchedTickets
            self.error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func updateTicket(_ ticket: TicketModel) async throws {
        try await repository.save(ticket)
        await loadTickets()
    }
    
    func deleteTicket(_ ticket: TicketModel) async throws {
        try await repository.delete(ticket)
        await loadTickets()
    }
    
    @MainActor
    func createTicket(
        title: String,
        description: String,
        priority: TicketPriority,
        status: TicketStatus,
        category: String,
        estimatedResolutionTime: TimeInterval,
        assignee: User?,
        watchers: [User],
        reporter: User,
        initialComment: String? = nil
    ) async throws -> TicketModel {
        
        let ticket = TicketModel(
            id: UUID().uuidString,
            title: title,
            description: description,
            priority: priority,
            status: status,
            category: category,
            estimatedResolutionTime: estimatedResolutionTime,
            assignee: assignee,
            reporter: reporter,
            watchers: watchers,
            responseDeltas: [],
            attachments: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save the ticket first
        try await repository.save(ticket)
        
        // Add initial comment if provided
        if let commentText = initialComment, !commentText.isEmpty {
            let comment = TicketComment(
                id: UUID().uuidString,
                ticketId: ticket.id,
                author: reporter,
                content: commentText,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save comment (assuming we have a comment repository)
            // This would be handled by a TicketCommentRepository
            // For now, we'll just include it in the model
        }
        
        // Reload tickets to refresh the list
        await loadTickets()
        
        return ticket
    }
}
