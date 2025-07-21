//
//  ClientViewModelTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import CloudKit

@MainActor
struct ClientViewModelTests {
    
    // MARK: - Mock Dependencies
    
    class MockClientRepository: ClientRepositoryProtocol {
        var shouldFailFetch = false
        var shouldFailSave = false
        var mockClients: [ClientModel] = []
        var saveCallCount = 0
        var fetchCallCount = 0
        
        func fetchAll() async throws -> [ClientModel] {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            return mockClients
        }
        
        func save(_ client: ClientModel) async throws {
            saveCallCount += 1
            if shouldFailSave {
                throw CKError(.quotaExceeded)
            }
            mockClients.append(client)
        }
        
        func delete(_ clientId: String) async throws {
            mockClients.removeAll { $0.id.recordName == clientId }
        }
        
        func fetchById(_ id: String) async throws -> ClientModel? {
            return mockClients.first { $0.id.recordName == id }
        }
        
        func fetchByStoreCode(_ storeCode: String) async throws -> [ClientModel] {
            return mockClients.filter { $0.storeCode == storeCode }
        }
    }
    
    // MARK: - Test Setup
    
    func createMockClient(
        name: String = "Test Client",
        status: ClientStatus = .active
    ) -> ClientModel {
        return ClientModel(
            id: CKRecord.ID(recordName: UUID().uuidString),
            name: name,
            email: "test@example.com",
            phone: "555-0123",
            company: "Test Company",
            status: status,
            storeCode: "08",
            department: "QA",
            createdAt: Date(),
            updatedAt: Date(),
            lastContactDate: Date(),
            tags: ["test"],
            notes: "Test client notes",
            preferredContactMethod: .email,
            birthday: Date().addingTimeInterval(-31536000), // 1 year ago
            anniversary: nil,
            totalOrderValue: 1000.0,
            lastOrderDate: Date().addingTimeInterval(-86400), // Yesterday
            creditLimit: 5000.0,
            paymentTerms: "Net 30"
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("ClientViewModel initializes with empty state")
    func testInitialization() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        #expect(viewModel.clients.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.filteredClients.isEmpty)
    }
    
    // MARK: - Loading Tests
    
    @Test("loadClients successfully fetches clients")
    func testLoadClientsSuccess() async throws {
        let mockRepository = MockClientRepository()
        let mockClient = createMockClient()
        mockRepository.mockClients = [mockClient]
        
        let viewModel = ClientViewModel(repository: mockRepository)
        
        await viewModel.loadClients()
        
        #expect(mockRepository.fetchCallCount == 1)
        #expect(viewModel.clients.count == 1)
        #expect(viewModel.clients.first?.name == "Test Client")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test("loadClients handles fetch failure")
    func testLoadClientsFailure() async throws {
        let mockRepository = MockClientRepository()
        mockRepository.shouldFailFetch = true
        
        let viewModel = ClientViewModel(repository: mockRepository)
        
        await viewModel.loadClients()
        
        #expect(mockRepository.fetchCallCount == 1)
        #expect(viewModel.clients.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("loadClients sets loading state correctly")
    func testLoadClientsLoadingState() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let loadingTask = Task {
            await viewModel.loadClients()
        }
        
        #expect(viewModel.isLoading == true)
        
        await loadingTask.value
        
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Create Client Tests
    
    @Test("createClient successfully saves new client")
    func testCreateClientSuccess() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let newClient = createMockClient(name: "New Client")
        
        await viewModel.createClient(newClient)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.mockClients.count == 1)
        #expect(mockRepository.mockClients.first?.name == "New Client")
        #expect(viewModel.error == nil)
    }
    
    @Test("createClient handles save failure")
    func testCreateClientFailure() async throws {
        let mockRepository = MockClientRepository()
        mockRepository.shouldFailSave = true
        
        let viewModel = ClientViewModel(repository: mockRepository)
        let newClient = createMockClient()
        
        await viewModel.createClient(newClient)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.mockClients.isEmpty)
        #expect(viewModel.error != nil)
    }
    
    @Test("createClient adds client to local collection on success")
    func testCreateClientUpdatesLocalCollection() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let newClient = createMockClient(name: "Local Client")
        
        await viewModel.createClient(newClient)
        
        #expect(viewModel.clients.count == 1)
        #expect(viewModel.clients.first?.name == "Local Client")
    }
    
    // MARK: - Update Client Tests
    
    @Test("updateClient successfully saves changes")
    func testUpdateClientSuccess() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client = createMockClient(name: "Original Name")
        mockRepository.mockClients = [client]
        viewModel.clients = [client]
        
        client.name = "Updated Name"
        client.email = "updated@example.com"
        
        await viewModel.updateClient(client)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(viewModel.error == nil)
        
        let updatedClient = viewModel.clients.first { $0.id == client.id }
        #expect(updatedClient?.name == "Updated Name")
        #expect(updatedClient?.email == "updated@example.com")
    }
    
    @Test("updateClient handles save failure")
    func testUpdateClientFailure() async throws {
        let mockRepository = MockClientRepository()
        mockRepository.shouldFailSave = true
        
        let viewModel = ClientViewModel(repository: mockRepository)
        let client = createMockClient()
        
        await viewModel.updateClient(client)
        
        #expect(viewModel.error != nil)
    }
    
    // MARK: - Delete Client Tests
    
    @Test("deleteClient removes client from collection")
    func testDeleteClientSuccess() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client = createMockClient()
        mockRepository.mockClients = [client]
        viewModel.clients = [client]
        
        await viewModel.deleteClient(client.id.recordName)
        
        #expect(mockRepository.mockClients.isEmpty)
        #expect(viewModel.clients.isEmpty)
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Filtering Tests
    
    @Test("filterClients by status works correctly")
    func testFilterClientsByStatus() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let activeClient = createMockClient(name: "Active", status: .active)
        let inactiveClient = createMockClient(name: "Inactive", status: .inactive)
        
        viewModel.clients = [activeClient, inactiveClient]
        viewModel.filterClients(by: .active)
        
        #expect(viewModel.filteredClients.count == 1)
        #expect(viewModel.filteredClients.first?.status == .active)
    }
    
    @Test("filterClients by store works correctly")
    func testFilterClientsByStore() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client1 = createMockClient(name: "Store 08")
        client1.storeCode = "08"
        
        var client2 = createMockClient(name: "Store 09")
        client2.storeCode = "09"
        
        viewModel.clients = [client1, client2]
        viewModel.filterClients(by: "08")
        
        #expect(viewModel.filteredClients.count == 1)
        #expect(viewModel.filteredClients.first?.storeCode == "08")
    }
    
    @Test("clearFilters shows all clients")
    func testClearFilters() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client1 = createMockClient(name: "Client 1", status: .active)
        let client2 = createMockClient(name: "Client 2", status: .inactive)
        
        viewModel.clients = [client1, client2]
        viewModel.filterClients(by: .active)
        viewModel.clearFilters()
        
        #expect(viewModel.filteredClients.count == 2)
    }
    
    // MARK: - Search Tests
    
    @Test("searchClients finds matching names")
    func testSearchClientsByName() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client1 = createMockClient(name: "John Smith")
        let client2 = createMockClient(name: "Jane Doe")
        
        viewModel.clients = [client1, client2]
        viewModel.searchClients(query: "John")
        
        #expect(viewModel.filteredClients.count == 1)
        #expect(viewModel.filteredClients.first?.name.contains("John") == true)
    }
    
    @Test("searchClients finds matching emails")
    func testSearchClientsByEmail() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client1 = createMockClient(name: "Client 1")
        client1.email = "john@company.com"
        
        var client2 = createMockClient(name: "Client 2")
        client2.email = "jane@company.com"
        
        viewModel.clients = [client1, client2]
        viewModel.searchClients(query: "john@")
        
        #expect(viewModel.filteredClients.count == 1)
        #expect(viewModel.filteredClients.first?.email.contains("john@") == true)
    }
    
    @Test("searchClients is case insensitive")
    func testSearchClientsCaseInsensitive() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client = createMockClient(name: "John Smith")
        viewModel.clients = [client]
        viewModel.searchClients(query: "JOHN")
        
        #expect(viewModel.filteredClients.count == 1)
    }
    
    @Test("empty search query shows all clients")
    func testEmptySearchQuery() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client1 = createMockClient(name: "Client 1")
        let client2 = createMockClient(name: "Client 2")
        
        viewModel.clients = [client1, client2]
        viewModel.searchClients(query: "")
        
        #expect(viewModel.filteredClients.count == 2)
    }
    
    // MARK: - Contact Management Tests
    
    @Test("updateLastContactDate sets current date")
    func testUpdateLastContactDate() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client = createMockClient()
        viewModel.clients = [client]
        
        let beforeUpdate = Date()
        await viewModel.updateLastContactDate(for: client.id.recordName)
        let afterUpdate = Date()
        
        #expect(mockRepository.saveCallCount == 1)
        let updatedClient = viewModel.clients.first { $0.id == client.id }
        #expect(updatedClient?.lastContactDate ?? Date.distantPast >= beforeUpdate)
        #expect(updatedClient?.lastContactDate ?? Date.distantFuture <= afterUpdate)
    }
    
    @Test("addNote appends to existing notes")
    func testAddNote() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client = createMockClient()
        client.notes = "Original notes"
        viewModel.clients = [client]
        
        await viewModel.addNote(to: client.id.recordName, note: "Additional note")
        
        #expect(mockRepository.saveCallCount == 1)
        let updatedClient = viewModel.clients.first { $0.id == client.id }
        #expect(updatedClient?.notes?.contains("Original notes") == true)
        #expect(updatedClient?.notes?.contains("Additional note") == true)
    }
    
    // MARK: - Follow-up Management Tests
    
    @Test("scheduleFollowUp creates follow-up reminder")
    func testScheduleFollowUp() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client = createMockClient()
        viewModel.clients = [client]
        
        let followUpDate = Date().addingTimeInterval(86400) // Tomorrow
        
        await viewModel.scheduleFollowUp(
            for: client.id.recordName,
            date: followUpDate,
            reason: "Check project status"
        )
        
        #expect(mockRepository.saveCallCount == 1)
        // Additional assertions would depend on the CRM follow-up implementation
    }
    
    // MARK: - Analytics Tests
    
    @Test("getClientsByStatus returns correct distribution")
    func testGetClientsByStatus() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let activeClient1 = createMockClient(status: .active)
        let activeClient2 = createMockClient(status: .active)
        let inactiveClient = createMockClient(status: .inactive)
        let prospectClient = createMockClient(status: .prospect)
        
        viewModel.clients = [activeClient1, activeClient2, inactiveClient, prospectClient]
        
        let distribution = viewModel.getClientsByStatus()
        
        #expect(distribution[.active] == 2)
        #expect(distribution[.inactive] == 1)
        #expect(distribution[.prospect] == 1)
    }
    
    @Test("getTotalOrderValue calculates correctly")
    func testGetTotalOrderValue() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client1 = createMockClient()
        client1.totalOrderValue = 1000.0
        
        var client2 = createMockClient()
        client2.totalOrderValue = 2500.0
        
        var client3 = createMockClient()
        client3.totalOrderValue = 750.0
        
        viewModel.clients = [client1, client2, client3]
        
        let total = viewModel.getTotalOrderValue()
        
        #expect(total == 4250.0)
    }
    
    @Test("getClientsWithUpcomingBirthdays returns correct clients")
    func testGetClientsWithUpcomingBirthdays() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let calendar = Calendar.current
        let today = Date()
        
        var client1 = createMockClient(name: "Birthday Soon")
        client1.birthday = calendar.date(byAdding: .day, value: 5, to: today) // 5 days from now
        
        var client2 = createMockClient(name: "Birthday Later")
        client2.birthday = calendar.date(byAdding: .day, value: 35, to: today) // 35 days from now
        
        var client3 = createMockClient(name: "No Birthday")
        client3.birthday = nil
        
        viewModel.clients = [client1, client2, client3]
        
        let upcomingBirthdays = viewModel.getClientsWithUpcomingBirthdays(within: 30)
        
        #expect(upcomingBirthdays.count == 1)
        #expect(upcomingBirthdays.first?.name == "Birthday Soon")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("clearError resets error state")
    func testClearError() async throws {
        let mockRepository = MockClientRepository()
        mockRepository.shouldFailFetch = true
        
        let viewModel = ClientViewModel(repository: mockRepository)
        
        await viewModel.loadClients()
        #expect(viewModel.error != nil)
        
        viewModel.clearError()
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Validation Tests
    
    @Test("validateClient catches empty name")
    func testValidateClientEmptyName() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client = createMockClient()
        client.name = ""
        
        let isValid = viewModel.validateClient(client)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateClient catches invalid email")
    func testValidateClientInvalidEmail() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client = createMockClient()
        client.email = "invalid-email"
        
        let isValid = viewModel.validateClient(client)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateClient catches empty store code")
    func testValidateClientEmptyStoreCode() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        var client = createMockClient()
        client.storeCode = ""
        
        let isValid = viewModel.validateClient(client)
        
        #expect(isValid == false)
        #expect(viewModel.error != nil)
    }
    
    @Test("validateClient passes for valid client")
    func testValidateClientValid() async throws {
        let mockRepository = MockClientRepository()
        let viewModel = ClientViewModel(repository: mockRepository)
        
        let client = createMockClient()
        
        let isValid = viewModel.validateClient(client)
        
        #expect(isValid == true)
        #expect(viewModel.error == nil)
    }
}
