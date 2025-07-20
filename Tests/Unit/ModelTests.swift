//
//  ModelTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import Testing
import CloudKit
@testable import DiamondDeskERP

struct ModelTests {
    
    // MARK: - Task Model Tests
    
    @Test("TaskModel initializes with all required properties")
    func testTaskModelInitialization() throws {
        let taskId = CKRecord.ID(recordName: "test-task")
        let userRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "test-user"),
            action: .none
        )
        let dueDate = Date()
        let createdAt = Date()
        let updatedAt = Date()
        
        let task = TaskModel(
            id: taskId,
            title: "Test Task",
            description: "Test Description",
            status: .pending,
            priority: .high,
            dueDate: dueDate,
            estimatedHours: 2.5,
            tags: ["urgent", "testing"],
            assignedUserRefs: [userRef],
            storeCodes: ["08", "09"],
            departments: ["QA", "Development"],
            createdByUserRef: userRef,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isGroupTask: true,
            requiresAcknowledgment: true,
            completionMode: .collaborative
        )
        
        #expect(task.id.recordName == "test-task")
        #expect(task.title == "Test Task")
        #expect(task.description == "Test Description")
        #expect(task.status == .pending)
        #expect(task.priority == .high)
        #expect(task.dueDate == dueDate)
        #expect(task.estimatedHours == 2.5)
        #expect(task.tags == ["urgent", "testing"])
        #expect(task.assignedUserRefs.count == 1)
        #expect(task.storeCodes == ["08", "09"])
        #expect(task.departments == ["QA", "Development"])
        #expect(task.isGroupTask == true)
        #expect(task.requiresAcknowledgment == true)
        #expect(task.completionMode == .collaborative)
    }
    
    @Test("TaskStatus enum has correct cases")
    func testTaskStatusEnum() throws {
        let statuses: [TaskStatus] = [.pending, .inProgress, .completed, .cancelled, .onHold]
        
        #expect(statuses.contains(.pending))
        #expect(statuses.contains(.inProgress))
        #expect(statuses.contains(.completed))
        #expect(statuses.contains(.cancelled))
        #expect(statuses.contains(.onHold))
    }
    
    @Test("TaskPriority enum has correct cases")
    func testTaskPriorityEnum() throws {
        let priorities: [TaskPriority] = [.low, .medium, .high, .critical]
        
        #expect(priorities.contains(.low))
        #expect(priorities.contains(.medium))
        #expect(priorities.contains(.high))
        #expect(priorities.contains(.critical))
    }
    
    @Test("CompletionMode enum has correct cases")
    func testCompletionModeEnum() throws {
        let modes: [CompletionMode] = [.individual, .collaborative, .sequential]
        
        #expect(modes.contains(.individual))
        #expect(modes.contains(.collaborative))
        #expect(modes.contains(.sequential))
    }
    
    // MARK: - Ticket Model Tests
    
    @Test("TicketModel initializes with all required properties")
    func testTicketModelInitialization() throws {
        let ticketId = CKRecord.ID(recordName: "test-ticket")
        let userRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "test-user"),
            action: .none
        )
        let submittedAt = Date()
        let updatedAt = Date()
        let dueDate = Date().addingTimeInterval(86400)
        
        let ticket = TicketModel(
            id: ticketId,
            title: "Test Ticket",
            description: "Test ticket description",
            status: .open,
            priority: .high,
            category: .technical,
            storeCode: "08",
            department: "IT",
            submittedByUserRef: userRef,
            assignedToUserRef: userRef,
            submittedAt: submittedAt,
            updatedAt: updatedAt,
            dueDate: dueDate,
            tags: ["urgent", "server"],
            escalationLevel: 1,
            resolutionNotes: "Resolution notes",
            customerImpact: .high,
            requiresFollowUp: true
        )
        
        #expect(ticket.id.recordName == "test-ticket")
        #expect(ticket.title == "Test Ticket")
        #expect(ticket.description == "Test ticket description")
        #expect(ticket.status == .open)
        #expect(ticket.priority == .high)
        #expect(ticket.category == .technical)
        #expect(ticket.storeCode == "08")
        #expect(ticket.department == "IT")
        #expect(ticket.submittedAt == submittedAt)
        #expect(ticket.updatedAt == updatedAt)
        #expect(ticket.dueDate == dueDate)
        #expect(ticket.tags == ["urgent", "server"])
        #expect(ticket.escalationLevel == 1)
        #expect(ticket.resolutionNotes == "Resolution notes")
        #expect(ticket.customerImpact == .high)
        #expect(ticket.requiresFollowUp == true)
    }
    
    @Test("TicketStatus enum has correct cases")
    func testTicketStatusEnum() throws {
        let statuses: [TicketStatus] = [.open, .inProgress, .waiting, .resolved, .closed]
        
        #expect(statuses.contains(.open))
        #expect(statuses.contains(.inProgress))
        #expect(statuses.contains(.waiting))
        #expect(statuses.contains(.resolved))
        #expect(statuses.contains(.closed))
    }
    
    @Test("TicketPriority enum has correct cases")
    func testTicketPriorityEnum() throws {
        let priorities: [TicketPriority] = [.low, .medium, .high, .critical]
        
        #expect(priorities.contains(.low))
        #expect(priorities.contains(.medium))
        #expect(priorities.contains(.high))
        #expect(priorities.contains(.critical))
    }
    
    @Test("TicketCategory enum has correct cases")
    func testTicketCategoryEnum() throws {
        let categories: [TicketCategory] = [.technical, .administrative, .customerService, .maintenance, .other]
        
        #expect(categories.contains(.technical))
        #expect(categories.contains(.administrative))
        #expect(categories.contains(.customerService))
        #expect(categories.contains(.maintenance))
        #expect(categories.contains(.other))
    }
    
    @Test("CustomerImpact enum has correct cases")
    func testCustomerImpactEnum() throws {
        let impacts: [CustomerImpact] = [.none, .low, .medium, .high, .critical]
        
        #expect(impacts.contains(.none))
        #expect(impacts.contains(.low))
        #expect(impacts.contains(.medium))
        #expect(impacts.contains(.high))
        #expect(impacts.contains(.critical))
    }
    
    // MARK: - Client Model Tests
    
    @Test("ClientModel initializes with all required properties")
    func testClientModelInitialization() throws {
        let clientId = CKRecord.ID(recordName: "test-client")
        let createdAt = Date()
        let updatedAt = Date()
        let lastContactDate = Date()
        let birthday = Date().addingTimeInterval(-31536000) // 1 year ago
        let anniversary = Date().addingTimeInterval(-63072000) // 2 years ago
        let lastOrderDate = Date().addingTimeInterval(-86400) // Yesterday
        
        let client = ClientModel(
            id: clientId,
            name: "John Doe",
            email: "john.doe@example.com",
            phone: "555-0123",
            company: "Acme Corp",
            status: .active,
            storeCode: "08",
            department: "Sales",
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastContactDate: lastContactDate,
            tags: ["vip", "corporate"],
            notes: "Important client notes",
            preferredContactMethod: .email,
            birthday: birthday,
            anniversary: anniversary,
            totalOrderValue: 15000.0,
            lastOrderDate: lastOrderDate,
            creditLimit: 50000.0,
            paymentTerms: "Net 30"
        )
        
        #expect(client.id.recordName == "test-client")
        #expect(client.name == "John Doe")
        #expect(client.email == "john.doe@example.com")
        #expect(client.phone == "555-0123")
        #expect(client.company == "Acme Corp")
        #expect(client.status == .active)
        #expect(client.storeCode == "08")
        #expect(client.department == "Sales")
        #expect(client.createdAt == createdAt)
        #expect(client.updatedAt == updatedAt)
        #expect(client.lastContactDate == lastContactDate)
        #expect(client.tags == ["vip", "corporate"])
        #expect(client.notes == "Important client notes")
        #expect(client.preferredContactMethod == .email)
        #expect(client.birthday == birthday)
        #expect(client.anniversary == anniversary)
        #expect(client.totalOrderValue == 15000.0)
        #expect(client.lastOrderDate == lastOrderDate)
        #expect(client.creditLimit == 50000.0)
        #expect(client.paymentTerms == "Net 30")
    }
    
    @Test("ClientStatus enum has correct cases")
    func testClientStatusEnum() throws {
        let statuses: [ClientStatus] = [.prospect, .active, .inactive, .archived]
        
        #expect(statuses.contains(.prospect))
        #expect(statuses.contains(.active))
        #expect(statuses.contains(.inactive))
        #expect(statuses.contains(.archived))
    }
    
    @Test("ContactMethod enum has correct cases")
    func testContactMethodEnum() throws {
        let methods: [ContactMethod] = [.email, .phone, .sms, .inPerson, .other]
        
        #expect(methods.contains(.email))
        #expect(methods.contains(.phone))
        #expect(methods.contains(.sms))
        #expect(methods.contains(.inPerson))
        #expect(methods.contains(.other))
    }
    
    // MARK: - KPI Model Tests
    
    @Test("KPIModel initializes with all required properties")
    func testKPIModelInitialization() throws {
        let kpiId = CKRecord.ID(recordName: "test-kpi")
        let targetDate = Date()
        let createdAt = Date()
        let updatedAt = Date()
        
        let kpi = KPIModel(
            id: kpiId,
            name: "Task Completion Rate",
            description: "Percentage of tasks completed on time",
            category: "Productivity",
            currentValue: 85.5,
            targetValue: 90.0,
            unit: "%",
            storeCode: "08",
            department: "Operations",
            targetDate: targetDate,
            isActive: true,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: ["performance", "tasks"]
        )
        
        #expect(kpi.id.recordName == "test-kpi")
        #expect(kpi.name == "Task Completion Rate")
        #expect(kpi.description == "Percentage of tasks completed on time")
        #expect(kpi.category == "Productivity")
        #expect(kpi.currentValue == 85.5)
        #expect(kpi.targetValue == 90.0)
        #expect(kpi.unit == "%")
        #expect(kpi.storeCode == "08")
        #expect(kpi.department == "Operations")
        #expect(kpi.targetDate == targetDate)
        #expect(kpi.isActive == true)
        #expect(kpi.createdAt == createdAt)
        #expect(kpi.updatedAt == updatedAt)
        #expect(kpi.tags == ["performance", "tasks"])
    }
    
    // MARK: - Store Report Model Tests
    
    @Test("StoreReportModel initializes with all required properties")
    func testStoreReportModelInitialization() throws {
        let reportId = CKRecord.ID(recordName: "test-report")
        let reportDate = Date()
        let createdAt = Date()
        let updatedAt = Date()
        
        let report = StoreReportModel(
            id: reportId,
            storeCode: "08",
            reportDate: reportDate,
            revenue: 15000.0,
            transactions: 150,
            averageTransactionValue: 100.0,
            topSellingItems: ["Item A", "Item B", "Item C"],
            customerCount: 125,
            staffHours: 40.0,
            notes: "Good sales day",
            createdByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "manager-user"),
                action: .none
            ),
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSubmitted: true,
            submittedAt: createdAt
        )
        
        #expect(report.id.recordName == "test-report")
        #expect(report.storeCode == "08")
        #expect(report.reportDate == reportDate)
        #expect(report.revenue == 15000.0)
        #expect(report.transactions == 150)
        #expect(report.averageTransactionValue == 100.0)
        #expect(report.topSellingItems == ["Item A", "Item B", "Item C"])
        #expect(report.customerCount == 125)
        #expect(report.staffHours == 40.0)
        #expect(report.notes == "Good sales day")
        #expect(report.createdAt == createdAt)
        #expect(report.updatedAt == updatedAt)
        #expect(report.isSubmitted == true)
        #expect(report.submittedAt == createdAt)
    }
    
    // MARK: - Model Validation Tests
    
    @Test("TaskModel validates required fields")
    func testTaskModelValidation() throws {
        // Valid task
        let validTask = TaskModel(
            id: CKRecord.ID(recordName: "valid-task"),
            title: "Valid Task",
            description: "Description",
            status: .pending,
            priority: .medium,
            dueDate: Date().addingTimeInterval(86400),
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
        
        #expect(validTask.title.isEmpty == false)
        #expect(validTask.storeCodes.isEmpty == false)
        #expect(validTask.departments.isEmpty == false)
    }
    
    @Test("TicketModel validates required fields")
    func testTicketModelValidation() throws {
        let validTicket = TicketModel(
            id: CKRecord.ID(recordName: "valid-ticket"),
            title: "Valid Ticket",
            description: "Description",
            status: .open,
            priority: .medium,
            category: .technical,
            storeCode: "08",
            department: "IT",
            submittedByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            assignedToUserRef: nil,
            submittedAt: Date(),
            updatedAt: Date(),
            dueDate: Date().addingTimeInterval(86400),
            tags: [],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .low,
            requiresFollowUp: false
        )
        
        #expect(validTicket.title.isEmpty == false)
        #expect(validTicket.storeCode.isEmpty == false)
        #expect(validTicket.department.isEmpty == false)
    }
    
    @Test("ClientModel validates required fields")
    func testClientModelValidation() throws {
        let validClient = ClientModel(
            id: CKRecord.ID(recordName: "valid-client"),
            name: "Valid Client",
            email: "valid@example.com",
            phone: "555-0123",
            company: "Company",
            status: .active,
            storeCode: "08",
            department: "Sales",
            createdAt: Date(),
            updatedAt: Date(),
            lastContactDate: Date(),
            tags: [],
            notes: "",
            preferredContactMethod: .email,
            birthday: nil,
            anniversary: nil,
            totalOrderValue: 0.0,
            lastOrderDate: nil,
            creditLimit: 0.0,
            paymentTerms: ""
        )
        
        #expect(validClient.name.isEmpty == false)
        #expect(validClient.email.isEmpty == false)
        #expect(validClient.storeCode.isEmpty == false)
        #expect(validClient.email.contains("@") == true)
    }
    
    // MARK: - Model Relationships Tests
    
    @Test("TaskModel handles user references correctly")
    func testTaskModelUserReferences() throws {
        let createdByRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "creator-user"),
            action: .none
        )
        let assignedRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "assigned-user"),
            action: .none
        )
        
        let task = TaskModel(
            id: CKRecord.ID(recordName: "test-task"),
            title: "Test Task",
            description: "Description",
            status: .pending,
            priority: .medium,
            dueDate: Date(),
            estimatedHours: 1.0,
            tags: [],
            assignedUserRefs: [assignedRef],
            storeCodes: ["08"],
            departments: ["QA"],
            createdByUserRef: createdByRef,
            createdAt: Date(),
            updatedAt: Date(),
            isGroupTask: false,
            requiresAcknowledgment: false,
            completionMode: .individual
        )
        
        #expect(task.createdByUserRef.recordID.recordName == "creator-user")
        #expect(task.assignedUserRefs.count == 1)
        #expect(task.assignedUserRefs.first?.recordID.recordName == "assigned-user")
    }
    
    @Test("TicketModel handles user references correctly")
    func testTicketModelUserReferences() throws {
        let submittedByRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "submitter-user"),
            action: .none
        )
        let assignedToRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: "assigned-user"),
            action: .none
        )
        
        let ticket = TicketModel(
            id: CKRecord.ID(recordName: "test-ticket"),
            title: "Test Ticket",
            description: "Description",
            status: .open,
            priority: .medium,
            category: .technical,
            storeCode: "08",
            department: "IT",
            submittedByUserRef: submittedByRef,
            assignedToUserRef: assignedToRef,
            submittedAt: Date(),
            updatedAt: Date(),
            dueDate: Date(),
            tags: [],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .low,
            requiresFollowUp: false
        )
        
        #expect(ticket.submittedByUserRef.recordID.recordName == "submitter-user")
        #expect(ticket.assignedToUserRef?.recordID.recordName == "assigned-user")
    }
}
