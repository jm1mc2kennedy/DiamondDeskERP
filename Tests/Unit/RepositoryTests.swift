#if canImport(XCTest)
//
//  RepositoryTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import CloudKit

@MainActor
struct RepositoryTests {
    
    // MARK: - Mock CloudKit Setup
    
    class MockCKContainer: CKContainer {
        var mockDatabase: MockCKDatabase
        
        init() {
            self.mockDatabase = MockCKDatabase()
            super.init()
        }
        
        override var publicCloudDatabase: CKDatabase {
            return mockDatabase
        }
        
        override var privateCloudDatabase: CKDatabase {
            return mockDatabase
        }
    }
    
    class MockCKDatabase: CKDatabase {
        var shouldFailFetch = false
        var shouldFailSave = false
        var mockRecords: [CKRecord] = []
        var fetchCallCount = 0
        var saveCallCount = 0
        
        override func fetch(withRecordID recordID: CKRecord.ID) async throws -> CKRecord {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            
            guard let record = mockRecords.first(where: { $0.recordID == recordID }) else {
                throw CKError(.unknownItem)
            }
            return record
        }
        
        override func records(matching query: CKQuery) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            
            let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)] = mockRecords.map { record in
                (record.recordID, .success(record))
            }
            
            return (matchResults, nil)
        }
        
        override func save(_ record: CKRecord) async throws -> CKRecord {
            saveCallCount += 1
            if shouldFailSave {
                throw CKError(.quotaExceeded)
            }
            
            // Remove existing record with same ID
            mockRecords.removeAll { $0.recordID == record.recordID }
            mockRecords.append(record)
            return record
        }
        
        override func deleteRecord(withID recordID: CKRecord.ID) async throws -> CKRecord.ID {
            guard let index = mockRecords.firstIndex(where: { $0.recordID == recordID }) else {
                throw CKError(.unknownItem)
            }
            mockRecords.remove(at: index)
            return recordID
        }
    }
    
    // MARK: - Task Repository Tests
    
    @Test("TaskRepository fetchAll returns all tasks")
    func testTaskRepositoryFetchAll() async throws {
        let mockContainer = MockCKContainer()
        let repository = TaskRepository(container: mockContainer)
        
        // Add mock task record
        let taskRecord = CKRecord(recordType: "Task", recordID: CKRecord.ID(recordName: "test-task"))
        taskRecord["title"] = "Test Task"
        taskRecord["description"] = "Test Description"
        taskRecord["status"] = "pending"
        taskRecord["priority"] = "medium"
        taskRecord["dueDate"] = Date()
        taskRecord["estimatedHours"] = 2.0
        taskRecord["tags"] = ["test"]
        taskRecord["storeCodes"] = ["08"]
        taskRecord["departments"] = ["QA"]
        taskRecord["createdAt"] = Date()
        taskRecord["updatedAt"] = Date()
        taskRecord["isGroupTask"] = false
        taskRecord["requiresAcknowledgment"] = false
        taskRecord["completionMode"] = "individual"
        
        // Set up required reference
        let userRecord = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: "test-user"))
        mockContainer.mockDatabase.mockRecords = [taskRecord, userRecord]
        taskRecord["createdByUserRef"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        let tasks = try await repository.fetchAll()
        
        #expect(mockContainer.mockDatabase.fetchCallCount == 1)
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "Test Task")
    }
    
    @Test("TaskRepository save creates new task")
    func testTaskRepositorySave() async throws {
        let mockContainer = MockCKContainer()
        let repository = TaskRepository(container: mockContainer)
        
        let task = TaskModel(
            id: CKRecord.ID(recordName: "new-task"),
            title: "New Task",
            description: "New Description",
            status: .pending,
            priority: .medium,
            dueDate: Date(),
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
        
        try await repository.save(task)
        
        #expect(mockContainer.mockDatabase.saveCallCount == 1)
        #expect(mockContainer.mockDatabase.mockRecords.count == 1)
        #expect(mockContainer.mockDatabase.mockRecords.first?["title"] as? String == "New Task")
    }
    
    @Test("TaskRepository delete removes task")
    func testTaskRepositoryDelete() async throws {
        let mockContainer = MockCKContainer()
        let repository = TaskRepository(container: mockContainer)
        
        let taskRecord = CKRecord(recordType: "Task", recordID: CKRecord.ID(recordName: "test-task"))
        mockContainer.mockDatabase.mockRecords = [taskRecord]
        
        try await repository.delete("test-task")
        
        #expect(mockContainer.mockDatabase.mockRecords.isEmpty)
    }
    
    @Test("TaskRepository handles fetch failure")
    func testTaskRepositoryFetchFailure() async throws {
        let mockContainer = MockCKContainer()
        mockContainer.mockDatabase.shouldFailFetch = true
        let repository = TaskRepository(container: mockContainer)
        
        do {
            _ = try await repository.fetchAll()
            #expect(Bool(false)) // Should not reach here
        } catch {
            #expect(error is CKError)
        }
    }
    
    @Test("TaskRepository handles save failure")
    func testTaskRepositorySaveFailure() async throws {
        let mockContainer = MockCKContainer()
        mockContainer.mockDatabase.shouldFailSave = true
        let repository = TaskRepository(container: mockContainer)
        
        let task = TaskModel(
            id: CKRecord.ID(recordName: "test-task"),
            title: "Test Task",
            description: "Description",
            status: .pending,
            priority: .medium,
            dueDate: Date(),
            estimatedHours: 1.0,
            tags: [],
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
        
        do {
            try await repository.save(task)
            #expect(Bool(false)) // Should not reach here
        } catch {
            #expect(error is CKError)
        }
    }
    
    // MARK: - Ticket Repository Tests
    
    @Test("TicketRepository fetchAll returns all tickets")
    func testTicketRepositoryFetchAll() async throws {
        let mockContainer = MockCKContainer()
        let repository = TicketRepository(container: mockContainer)
        
        let ticketRecord = CKRecord(recordType: "Ticket", recordID: CKRecord.ID(recordName: "test-ticket"))
        ticketRecord["title"] = "Test Ticket"
        ticketRecord["description"] = "Test Description"
        ticketRecord["status"] = "open"
        ticketRecord["priority"] = "medium"
        ticketRecord["category"] = "technical"
        ticketRecord["storeCode"] = "08"
        ticketRecord["department"] = "QA"
        ticketRecord["submittedAt"] = Date()
        ticketRecord["updatedAt"] = Date()
        ticketRecord["dueDate"] = Date()
        ticketRecord["tags"] = ["test"]
        ticketRecord["escalationLevel"] = 0
        ticketRecord["customerImpact"] = "low"
        ticketRecord["requiresFollowUp"] = false
        
        // Set up required reference
        let userRecord = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: "test-user"))
        mockContainer.mockDatabase.mockRecords = [ticketRecord, userRecord]
        ticketRecord["submittedByUserRef"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        let tickets = try await repository.fetchAll()
        
        #expect(mockContainer.mockDatabase.fetchCallCount == 1)
        #expect(tickets.count == 1)
        #expect(tickets.first?.title == "Test Ticket")
    }
    
    @Test("TicketRepository save creates new ticket")
    func testTicketRepositorySave() async throws {
        let mockContainer = MockCKContainer()
        let repository = TicketRepository(container: mockContainer)
        
        let ticket = TicketModel(
            id: CKRecord.ID(recordName: "new-ticket"),
            title: "New Ticket",
            description: "New Description",
            status: .open,
            priority: .medium,
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
            dueDate: Date(),
            tags: ["test"],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .low,
            requiresFollowUp: false
        )
        
        try await repository.save(ticket)
        
        #expect(mockContainer.mockDatabase.saveCallCount == 1)
        #expect(mockContainer.mockDatabase.mockRecords.count == 1)
        #expect(mockContainer.mockDatabase.mockRecords.first?["title"] as? String == "New Ticket")
    }
    
    @Test("TicketRepository fetchByStore filters correctly")
    func testTicketRepositoryFetchByStore() async throws {
        let mockContainer = MockCKContainer()
        let repository = TicketRepository(container: mockContainer)
        
        // Create tickets for different stores
        let ticket1 = CKRecord(recordType: "Ticket", recordID: CKRecord.ID(recordName: "ticket-1"))
        ticket1["storeCode"] = "08"
        ticket1["title"] = "Store 08 Ticket"
        
        let ticket2 = CKRecord(recordType: "Ticket", recordID: CKRecord.ID(recordName: "ticket-2"))
        ticket2["storeCode"] = "09"
        ticket2["title"] = "Store 09 Ticket"
        
        // Set up all required fields
        let userRecord = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: "test-user"))
        let userRef = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        for ticket in [ticket1, ticket2] {
            ticket["description"] = "Description"
            ticket["status"] = "open"
            ticket["priority"] = "medium"
            ticket["category"] = "technical"
            ticket["department"] = "QA"
            ticket["submittedByUserRef"] = userRef
            ticket["submittedAt"] = Date()
            ticket["updatedAt"] = Date()
            ticket["dueDate"] = Date()
            ticket["tags"] = ["test"]
            ticket["escalationLevel"] = 0
            ticket["customerImpact"] = "low"
            ticket["requiresFollowUp"] = false
        }
        
        mockContainer.mockDatabase.mockRecords = [ticket1, ticket2, userRecord]
        
        let storeTickets = try await repository.fetchByStore("08")
        
        #expect(storeTickets.count == 1)
        #expect(storeTickets.first?.storeCode == "08")
    }
    
    // MARK: - Client Repository Tests
    
    @Test("ClientRepository fetchAll returns all clients")
    func testClientRepositoryFetchAll() async throws {
        let mockContainer = MockCKContainer()
        let repository = ClientRepository(container: mockContainer)
        
        let clientRecord = CKRecord(recordType: "Client", recordID: CKRecord.ID(recordName: "test-client"))
        clientRecord["name"] = "Test Client"
        clientRecord["email"] = "test@example.com"
        clientRecord["phone"] = "555-0123"
        clientRecord["company"] = "Test Company"
        clientRecord["status"] = "active"
        clientRecord["storeCode"] = "08"
        clientRecord["department"] = "QA"
        clientRecord["createdAt"] = Date()
        clientRecord["updatedAt"] = Date()
        clientRecord["lastContactDate"] = Date()
        clientRecord["tags"] = ["test"]
        clientRecord["notes"] = "Test notes"
        clientRecord["preferredContactMethod"] = "email"
        clientRecord["totalOrderValue"] = 1000.0
        clientRecord["creditLimit"] = 5000.0
        clientRecord["paymentTerms"] = "Net 30"
        
        mockContainer.mockDatabase.mockRecords = [clientRecord]
        
        let clients = try await repository.fetchAll()
        
        #expect(mockContainer.mockDatabase.fetchCallCount == 1)
        #expect(clients.count == 1)
        #expect(clients.first?.name == "Test Client")
    }
    
    @Test("ClientRepository save creates new client")
    func testClientRepositorySave() async throws {
        let mockContainer = MockCKContainer()
        let repository = ClientRepository(container: mockContainer)
        
        let client = ClientModel(
            id: CKRecord.ID(recordName: "new-client"),
            name: "New Client",
            email: "new@example.com",
            phone: "555-0123",
            company: "New Company",
            status: .active,
            storeCode: "08",
            department: "QA",
            createdAt: Date(),
            updatedAt: Date(),
            lastContactDate: Date(),
            tags: ["test"],
            notes: "New client notes",
            preferredContactMethod: .email,
            birthday: nil,
            anniversary: nil,
            totalOrderValue: 500.0,
            lastOrderDate: nil,
            creditLimit: 2500.0,
            paymentTerms: "Net 15"
        )
        
        try await repository.save(client)
        
        #expect(mockContainer.mockDatabase.saveCallCount == 1)
        #expect(mockContainer.mockDatabase.mockRecords.count == 1)
        #expect(mockContainer.mockDatabase.mockRecords.first?["name"] as? String == "New Client")
    }
    
    @Test("ClientRepository fetchByStoreCode filters correctly")
    func testClientRepositoryFetchByStoreCode() async throws {
        let mockContainer = MockCKContainer()
        let repository = ClientRepository(container: mockContainer)
        
        // Create clients for different stores
        let client1 = CKRecord(recordType: "Client", recordID: CKRecord.ID(recordName: "client-1"))
        client1["storeCode"] = "08"
        client1["name"] = "Store 08 Client"
        
        let client2 = CKRecord(recordType: "Client", recordID: CKRecord.ID(recordName: "client-2"))
        client2["storeCode"] = "09"
        client2["name"] = "Store 09 Client"
        
        // Set up all required fields
        for client in [client1, client2] {
            client["email"] = "test@example.com"
            client["phone"] = "555-0123"
            client["company"] = "Company"
            client["status"] = "active"
            client["department"] = "QA"
            client["createdAt"] = Date()
            client["updatedAt"] = Date()
            client["lastContactDate"] = Date()
            client["tags"] = ["test"]
            client["notes"] = "Notes"
            client["preferredContactMethod"] = "email"
            client["totalOrderValue"] = 1000.0
            client["creditLimit"] = 5000.0
            client["paymentTerms"] = "Net 30"
        }
        
        mockContainer.mockDatabase.mockRecords = [client1, client2]
        
        let storeClients = try await repository.fetchByStoreCode("08")
        
        #expect(storeClients.count == 1)
        #expect(storeClients.first?.storeCode == "08")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Repository handles CloudKit network errors")
    func testRepositoryNetworkError() async throws {
        let mockContainer = MockCKContainer()
        mockContainer.mockDatabase.shouldFailFetch = true
        let repository = TaskRepository(container: mockContainer)
        
        do {
            _ = try await repository.fetchAll()
            #expect(Bool(false)) // Should not reach here
        } catch let error as CKError {
            #expect(error.code == .networkFailure)
        }
    }
    
    @Test("Repository handles CloudKit quota errors")
    func testRepositoryQuotaError() async throws {
        let mockContainer = MockCKContainer()
        mockContainer.mockDatabase.shouldFailSave = true
        let repository = TaskRepository(container: mockContainer)
        
        let task = TaskModel(
            id: CKRecord.ID(recordName: "test"),
            title: "Test",
            description: "Test",
            status: .pending,
            priority: .medium,
            dueDate: Date(),
            estimatedHours: 1.0,
            tags: [],
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
        
        do {
            try await repository.save(task)
            #expect(Bool(false)) // Should not reach here
        } catch let error as CKError {
            #expect(error.code == .quotaExceeded)
        }
    }
}
#endif
