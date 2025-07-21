#if canImport(XCTest)
//
//  TicketViewModelTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import CloudKit

@MainActor
struct TicketViewModelTests {
    
    // MARK: - Mock Dependencies
    
    class MockTicketRepository: TicketRepositoryProtocol {
        var shouldFailFetch = false
        var shouldFailSave = false
        var mockTickets: [TicketModel] = []
        var saveCallCount = 0
        var fetchCallCount = 0
        
        func fetchAll() async throws -> [TicketModel] {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            return mockTickets
        }
        
        func save(_ ticket: TicketModel) async throws {
            saveCallCount += 1
            if shouldFailSave {
                throw CKError(.quotaExceeded)
            }
            mockTickets.append(ticket)
        }
        
        func delete(_ ticketId: String) async throws {
            mockTickets.removeAll { $0.id.recordName == ticketId }
        }
        
        func fetchById(_ id: String) async throws -> TicketModel? {
            return mockTickets.first { $0.id.recordName == id }
        }
        
        func fetchByStore(_ storeCode: String) async throws -> [TicketModel] {
            return mockTickets.filter { $0.storeCode == storeCode }
        }
    }
    
    // MARK: - Test Setup
    
    func createMockTicket(
        title: String = "Test Ticket",
        status: TicketStatus = .open,
        priority: TicketPriority = .medium
    ) -> TicketModel {
        return TicketModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            title: title,
            description: "Test ticket description",
            status: status,
            priority: priority,
            category: .technical,
            storeCode: "08",
            department: "QA",
            submittedByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            assignedToUserRef: nil,
            submittedAt: Date(),
            updatedAt: Date(),
            dueDate: Date().addingTimeInterval(86400),
            tags: ["test"],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .low,
            requiresFollowUp: false
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("TicketViewModel initializes with empty state")
    func testInitialization() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        #expect(viewModel.tickets.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.filteredTickets.isEmpty)
    }
    
    // MARK: - Loading Tests
    
    @Test("loadTickets successfully fetches tickets")
    func testLoadTicketsSuccess() async throws {
        let mockRepository = MockTicketRepository()
        let mockTicket = createMockTicket()
        mockRepository.mockTickets = [mockTicket]
        
        let viewModel = TicketViewModel(repository: mockRepository)
        
        await viewModel.loadTickets()
        
        #expect(mockRepository.fetchCallCount == 1)
        #expect(viewModel.tickets.count == 1)
        #expect(viewModel.tickets.first?.title == "Test Ticket")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test("loadTickets handles fetch failure")
    func testLoadTicketsFailure() async throws {
        let mockRepository = MockTicketRepository()
        mockRepository.shouldFailFetch = true
        
        let viewModel = TicketViewModel(repository: mockRepository)
        
        await viewModel.loadTickets()
        
        #expect(mockRepository.fetchCallCount == 1)
        #expect(viewModel.tickets.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("loadTickets sets loading state correctly")
    func testLoadTicketsLoadingState() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let loadingTask = Task {
            await viewModel.loadTickets()
        }
        
        #expect(viewModel.isLoading == true)
        
        await loadingTask.value
        
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Create Ticket Tests
    
    @Test("createTicket successfully saves new ticket")
    func testCreateTicketSuccess() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let newTicket = createMockTicket(title: "New Ticket")
        
        await viewModel.createTicket(newTicket)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.mockTickets.count == 1)
        #expect(mockRepository.mockTickets.first?.title == "New Ticket")
        #expect(viewModel.error == nil)
    }
    
    @Test("createTicket handles save failure")
    func testCreateTicketFailure() async throws {
        let mockRepository = MockTicketRepository()
        mockRepository.shouldFailSave = true
        
        let viewModel = TicketViewModel(repository: mockRepository)
        let newTicket = createMockTicket()
        
        await viewModel.createTicket(newTicket)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.mockTickets.isEmpty)
        #expect(viewModel.error != nil)
    }
    
    @Test("createTicket adds ticket to local collection on success")
    func testCreateTicketUpdatesLocalCollection() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let newTicket = createMockTicket(title: "Local Ticket")
        
        await viewModel.createTicket(newTicket)
        
        #expect(viewModel.tickets.count == 1)
        #expect(viewModel.tickets.first?.title == "Local Ticket")
    }
    
    // MARK: - Update Ticket Tests
    
    @Test("updateTicket successfully saves changes")
    func testUpdateTicketSuccess() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        var ticket = createMockTicket(title: "Original Title")
        mockRepository.mockTickets = [ticket]
        viewModel.tickets = [ticket]
        
        ticket.title = "Updated Title"
        ticket.status = .inProgress
        
        await viewModel.updateTicket(ticket)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(viewModel.error == nil)
        
        let updatedTicket = viewModel.tickets.first { $0.id == ticket.id }
        #expect(updatedTicket?.title == "Updated Title")
        #expect(updatedTicket?.status == .inProgress)
    }
    
    @Test("updateTicket handles save failure")
    func testUpdateTicketFailure() async throws {
        let mockRepository = MockTicketRepository()
        mockRepository.shouldFailSave = true
        
        let viewModel = TicketViewModel(repository: mockRepository)
        let ticket = createMockTicket()
        
        await viewModel.updateTicket(ticket)
        
        #expect(viewModel.error != nil)
    }
    
    // MARK: - Delete Ticket Tests
    
    @Test("deleteTicket removes ticket from collection")
    func testDeleteTicketSuccess() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket = createMockTicket()
        mockRepository.mockTickets = [ticket]
        viewModel.tickets = [ticket]
        
        await viewModel.deleteTicket(ticket.id.recordName)
        
        #expect(mockRepository.mockTickets.isEmpty)
        #expect(viewModel.tickets.isEmpty)
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Filtering Tests
    
    @Test("filterTickets by status works correctly")
    func testFilterTicketsByStatus() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let openTicket = createMockTicket(title: "Open", status: .open)
        let closedTicket = createMockTicket(title: "Closed", status: .closed)
        
        viewModel.tickets = [openTicket, closedTicket]
        viewModel.filterTickets(by: .open)
        
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.status == .open)
    }
    
    @Test("filterTickets by priority works correctly")
    func testFilterTicketsByPriority() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let highTicket = createMockTicket(title: "High Priority", priority: .high)
        let lowTicket = createMockTicket(title: "Low Priority", priority: .low)
        
        viewModel.tickets = [highTicket, lowTicket]
        viewModel.filterTickets(by: .high)
        
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.priority == .high)
    }
    
    @Test("filterTickets by store works correctly")
    func testFilterTicketsByStore() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        var ticket1 = createMockTicket(title: "Store 08")
        ticket1.storeCode = "08"
        
        var ticket2 = createMockTicket(title: "Store 09")
        ticket2.storeCode = "09"
        
        viewModel.tickets = [ticket1, ticket2]
        viewModel.filterTickets(by: "08")
        
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.storeCode == "08")
    }
    
    @Test("clearFilters shows all tickets")
    func testClearFilters() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket1 = createMockTicket(title: "Ticket 1", status: .open)
        let ticket2 = createMockTicket(title: "Ticket 2", status: .closed)
        
        viewModel.tickets = [ticket1, ticket2]
        viewModel.filterTickets(by: .open)
        viewModel.clearFilters()
        
        #expect(viewModel.filteredTickets.count == 2)
    }
    
    // MARK: - Search Tests
    
    @Test("searchTickets finds matching titles")
    func testSearchTicketsByTitle() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket1 = createMockTicket(title: "Email Server Down")
        let ticket2 = createMockTicket(title: "Printer Issue")
        
        viewModel.tickets = [ticket1, ticket2]
        viewModel.searchTickets(query: "Email")
        
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.title.contains("Email") == true)
    }
    
    @Test("searchTickets is case insensitive")
    func testSearchTicketsCaseInsensitive() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket = createMockTicket(title: "Email Server Down")
        viewModel.tickets = [ticket]
        viewModel.searchTickets(query: "email")
        
        #expect(viewModel.filteredTickets.count == 1)
    }
    
    @Test("empty search query shows all tickets")
    func testEmptySearchQuery() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket1 = createMockTicket(title: "Ticket 1")
        let ticket2 = createMockTicket(title: "Ticket 2")
        
        viewModel.tickets = [ticket1, ticket2]
        viewModel.searchTickets(query: "")
        
        #expect(viewModel.filteredTickets.count == 2)
    }
    
    // MARK: - Escalation Tests
    
    @Test("escalateTicket increases escalation level")
    func testEscalateTicket() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        var ticket = createMockTicket()
        ticket.escalationLevel = 0
        viewModel.tickets = [ticket]
        
        await viewModel.escalateTicket(ticket.id.recordName)
        
        #expect(mockRepository.saveCallCount == 1)
        let escalatedTicket = viewModel.tickets.first { $0.id == ticket.id }
        #expect(escalatedTicket?.escalationLevel == 1)
    }
    
    @Test("escalation caps at maximum level")
    func testEscalationCap() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        var ticket = createMockTicket()
        ticket.escalationLevel = 3 // Max level
        viewModel.tickets = [ticket]
        
        await viewModel.escalateTicket(ticket.id.recordName)
        
        let escalatedTicket = viewModel.tickets.first { $0.id == ticket.id }
        #expect(escalatedTicket?.escalationLevel == 3) // Should remain at max
    }
    
    // MARK: - Assignment Tests
    
    @Test("assignTicket sets assigned user")
    func testAssignTicket() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket = createMockTicket()
        viewModel.tickets = [ticket]
        
        let userRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "assigned-user"),
            action: .none
        )
        
        await viewModel.assignTicket(ticket.id.recordName, to: userRef)
        
        #expect(mockRepository.saveCallCount == 1)
        let assignedTicket = viewModel.tickets.first { $0.id == ticket.id }
        #expect(assignedTicket?.assignedToUserRef?.recordID.recordName == "assigned-user")
    }
    
    // MARK: - Resolution Tests
    
    @Test("resolveTicket closes ticket with notes")
    func testResolveTicket() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket = createMockTicket(status: .inProgress)
        viewModel.tickets = [ticket]
        
        await viewModel.resolveTicket(ticket.id.recordName, notes: "Issue resolved")
        
        #expect(mockRepository.saveCallCount == 1)
        let resolvedTicket = viewModel.tickets.first { $0.id == ticket.id }
        #expect(resolvedTicket?.status == .closed)
        #expect(resolvedTicket?.resolutionNotes == "Issue resolved")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("clearError resets error state")
    func testClearError() async throws {
        let mockRepository = MockTicketRepository()
        mockRepository.shouldFailFetch = true
        
        let viewModel = TicketViewModel(repository: mockRepository)
        
        await viewModel.loadTickets()
        #expect(viewModel.error != nil)
        
        viewModel.clearError()
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Validation Tests
    
    @Test("validateTicket catches empty title")
    func testValidateTicketEmptyTitle() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        var ticket = createMockTicket()
        ticket.title = ""
        
        let isValid = viewModel.validateTicket(ticket)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateTicket catches empty store code")
    func testValidateTicketEmptyStoreCode() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        var ticket = createMockTicket()
        ticket.storeCode = ""
        
        let isValid = viewModel.validateTicket(ticket)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateTicket passes for valid ticket")
    func testValidateTicketValid() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let ticket = createMockTicket()
        
        let isValid = viewModel.validateTicket(ticket)
        
        #expect(isValid == true)
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Analytics Tests
    
    @Test("getTicketsByPriority returns correct distribution")
    func testGetTicketsByPriority() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let highTicket = createMockTicket(priority: .high)
        let mediumTicket1 = createMockTicket(priority: .medium)
        let mediumTicket2 = createMockTicket(priority: .medium)
        let lowTicket = createMockTicket(priority: .low)
        
        viewModel.tickets = [highTicket, mediumTicket1, mediumTicket2, lowTicket]
        
        let distribution = viewModel.getTicketsByPriority()
        
        #expect(distribution[.high] == 1)
        #expect(distribution[.medium] == 2)
        #expect(distribution[.low] == 1)
    }
    
    @Test("getAverageResolutionTime calculates correctly")
    func testGetAverageResolutionTime() async throws {
        let mockRepository = MockTicketRepository()
        let viewModel = TicketViewModel(repository: mockRepository)
        
        let baseDate = Date()
        
        var ticket1 = createMockTicket(status: .closed)
        ticket1.submittedAt = baseDate
        ticket1.updatedAt = baseDate.addingTimeInterval(3600) // 1 hour
        
        var ticket2 = createMockTicket(status: .closed)
        ticket2.submittedAt = baseDate
        ticket2.updatedAt = baseDate.addingTimeInterval(7200) // 2 hours
        
        viewModel.tickets = [ticket1, ticket2]
        
        let avgTime = viewModel.getAverageResolutionTime()
        
        #expect(abs(avgTime - 5400) < 60) // Average of 1.5 hours (5400 seconds), allowing small variance
    }
}
#endif
