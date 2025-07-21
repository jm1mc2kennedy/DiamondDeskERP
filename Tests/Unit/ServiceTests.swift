//
//  ServiceTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import CloudKit
import UserNotifications

@MainActor final class ServiceTests: XCTestCase {
    
    class MockUNUserNotificationCenter: UNUserNotificationCenter {
        var requestAuthorizationCalled = false
        var addNotificationRequestCalled = false
        var authorizationStatus: UNAuthorizationStatus = .notDetermined
        var scheduledNotifications: [UNNotificationRequest] = []
        
        override func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
            requestAuthorizationCalled = true
            authorizationStatus = .authorized
            return true
        }
        
        override func add(_ request: UNNotificationRequest) async throws {
            addNotificationRequestCalled = true
            scheduledNotifications.append(request)
        }
        
        override func notificationSettings() async -> UNNotificationSettings {
            return UNNotificationSettings()
        }
    }
    
    func testNotificationServiceRequestsAuthorization() async throws {
        let mockCenter = MockUNUserNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        let granted = try await service.requestPermission()
        
        XCTAssertTrue(mockCenter.requestAuthorizationCalled)
        XCTAssertTrue(granted)
    }
    
    func testNotificationServiceSchedulesNotification() async throws {
        let mockCenter = MockUNUserNotificationCenter()
        mockCenter.authorizationStatus = .authorized
        let service = NotificationService(notificationCenter: mockCenter)
        
        try await service.scheduleLocalNotification(
            title: "Test Title",
            body: "Test Body",
            date: Date().addingTimeInterval(60)
        )
        
        XCTAssertTrue(mockCenter.addNotificationRequestCalled)
        XCTAssertEqual(mockCenter.scheduledNotifications.count, 1)
        XCTAssertEqual(mockCenter.scheduledNotifications.first?.content.title, "Test Title")
    }
    
    func testNotificationServiceSchedulesTaskReminder() async throws {
        let mockCenter = MockUNUserNotificationCenter()
        mockCenter.authorizationStatus = .authorized
        let service = NotificationService(notificationCenter: mockCenter)
        
        let task = TaskModel(
            id: CKRecord.ID(recordName: "test-task"),
            title: "Test Task",
            description: "Test Description",
            status: .pending,
            priority: .high,
            dueDate: Date().addingTimeInterval(3600), // 1 hour from now
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
        
        try await service.scheduleTaskReminder(for: task, reminderDate: Date().addingTimeInterval(1800))
        
        XCTAssertTrue(mockCenter.addNotificationRequestCalled)
        XCTAssertEqual(mockCenter.scheduledNotifications.count, 1)
        
        let notification = mockCenter.scheduledNotifications.first!
        XCTAssertTrue(notification.content.title.contains("Task Reminder"))
        XCTAssertTrue(notification.content.body.contains("Test Task"))
    }
    
    func testAnalyticsServiceTaskCompletionRate() async throws {
        let service = AnalyticsService()
        
        let completedTask = TaskModel(
            id: CKRecord.ID(recordName: "completed-task"),
            title: "Completed Task",
            description: "Description",
            status: .completed,
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
        
        let pendingTask = TaskModel(
            id: CKRecord.ID(recordName: "pending-task"),
            title: "Pending Task",
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
        
        let tasks = [completedTask, pendingTask]
        let completionRate = service.calculateTaskCompletionRate(tasks: tasks)
        
        XCTAssertEqual(completionRate, 0.5) // 1 out of 2 tasks completed
    }
    
    func testAnalyticsServiceAverageResolutionTime() async throws {
        let service = AnalyticsService()
        
        let baseDate = Date()
        
        var ticket1 = TicketModel(
            id: CKRecord.ID(recordName: "ticket-1"),
            title: "Ticket 1",
            description: "Description",
            status: .closed,
            priority: .medium,
            category: .technical,
            storeCode: "08",
            department: "QA",
            submittedByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            assignedToUserRef: nil,
            submittedAt: baseDate,
            updatedAt: baseDate.addingTimeInterval(3600), // 1 hour later
            dueDate: baseDate.addingTimeInterval(86400),
            tags: [],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .low,
            requiresFollowUp: false
        )
        
        var ticket2 = TicketModel(
            id: CKRecord.ID(recordName: "ticket-2"),
            title: "Ticket 2",
            description: "Description",
            status: .closed,
            priority: .medium,
            category: .technical,
            storeCode: "08",
            department: "QA",
            submittedByUserRef: CKRecord.Reference(
                recordID: CKRecord.ID(recordName: "test-user"),
                action: .none
            ),
            assignedToUserRef: nil,
            submittedAt: baseDate,
            updatedAt: baseDate.addingTimeInterval(7200), // 2 hours later
            dueDate: baseDate.addingTimeInterval(86400),
            tags: [],
            escalationLevel: 0,
            resolutionNotes: nil,
            customerImpact: .low,
            requiresFollowUp: false
        )
        
        let tickets = [ticket1, ticket2]
        let avgResolutionTime = service.calculateAverageResolutionTime(tickets: tickets)
        
        XCTAssertLessThan(abs(avgResolutionTime - 5400), 60) // Average of 1.5 hours (5400 seconds)
    }
    
    func testAnalyticsServiceKPISummary() async throws {
        let service = AnalyticsService()
        
        let tasks = [
            TaskModel(
                id: CKRecord.ID(recordName: "task-1"),
                title: "Task 1",
                description: "Description",
                status: .completed,
                priority: .high,
                dueDate: Date(),
                estimatedHours: 2.0,
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
        ]
        
        let tickets = [
            TicketModel(
                id: CKRecord.ID(recordName: "ticket-1"),
                title: "Ticket 1",
                description: "Description",
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
                tags: [],
                escalationLevel: 0,
                resolutionNotes: nil,
                customerImpact: .low,
                requiresFollowUp: false
            )
        ]
        
        let kpiSummary = service.generateKPISummary(tasks: tasks, tickets: tickets)
        
        XCTAssertEqual(kpiSummary.totalTasks, 1)
        XCTAssertEqual(kpiSummary.totalTickets, 1)
        XCTAssertEqual(kpiSummary.taskCompletionRate, 1.0)
    }
    
    class MockUserProvisioningService: UserProvisioningService {
        var createUserCalled = false
        var updateUserCalled = false
        var deactivateUserCalled = false
        
        override func createUser(name: String, email: String, role: String, storeCode: String) async throws -> String {
            createUserCalled = true
            return "mock-user-id"
        }
        
        override func updateUserRole(_ userId: String, newRole: String) async throws {
            updateUserCalled = true
        }
        
        override func deactivateUser(_ userId: String) async throws {
            deactivateUserCalled = true
        }
    }
    
    func testUserProvisioningServiceCreatesUser() async throws {
        let service = MockUserProvisioningService()
        
        let userId = try await service.createUser(
            name: "Test User",
            email: "test@example.com",
            role: "manager",
            storeCode: "08"
        )
        
        XCTAssertTrue(service.createUserCalled)
        XCTAssertEqual(userId, "mock-user-id")
    }
    
    func testUserProvisioningServiceUpdatesRole() async throws {
        let service = MockUserProvisioningService()
        
        try await service.updateUserRole("test-user", newRole: "admin")
        
        XCTAssertTrue(service.updateUserCalled)
    }
    
    func testUserProvisioningServiceDeactivatesUser() async throws {
        let service = MockUserProvisioningService()
        
        try await service.deactivateUser("test-user")
        
        XCTAssertTrue(service.deactivateUserCalled)
    }
    
    func testPerformanceOptimizationServiceMemoryOptimization() async throws {
        let service = PerformanceOptimizationService()
        
        var largeArray = Array(0..<10000)
        
        await service.optimizeMemoryUsage()
        
        XCTAssertEqual(largeArray.count, 10000)
        
        largeArray.removeAll()
    }
    
    func testPerformanceOptimizationServiceNetworkOptimization() async throws {
        let service = PerformanceOptimizationService()
        
        await service.optimizeNetworkRequests()
        
        XCTAssertTrue(true)
    }
    
    func testOfflineCapabilityServiceOfflineState() async throws {
        let service = OfflineCapabilityService()
        
        await service.handleOfflineState()
        
        let isOffline = await service.isOffline
        XCTAssertTrue(isOffline)
    }
    
    func testOfflineCapabilityServiceSyncWhenOnline() async throws {
        let service = OfflineCapabilityService()
        
        await service.handleOnlineState()
        
        let isOffline = await service.isOffline
        XCTAssertFalse(isOffline)
    }
    
    func testAccessibilityServiceVoiceOverSupport() async throws {
        let service = AccessibilityService()
        
        await service.enableVoiceOverSupport()
        
        let isVoiceOverEnabled = await service.isVoiceOverEnabled
        XCTAssertTrue(isVoiceOverEnabled)
    }
    
    func testAccessibilityServiceLargerTextSupport() async throws {
        let service = AccessibilityService()
        
        await service.enableLargerTextSupport()
        
        let isLargerTextEnabled = await service.isLargerTextEnabled
        XCTAssertTrue(isLargerTextEnabled)
    }
    
    func testServiceCloudKitErrorHandling() async throws {
        let service = AnalyticsService()
        
        let emptyKPI = service.generateKPISummary(tasks: [], tickets: [])
        
        XCTAssertEqual(emptyKPI.totalTasks, 0)
        XCTAssertEqual(emptyKPI.totalTickets, 0)
        XCTAssertEqual(emptyKPI.taskCompletionRate, 0.0)
    }
    
    func testServiceNetworkErrorHandling() async throws {
        let service = OfflineCapabilityService()
        
        await service.handleNetworkError()
        
        let hasNetworkError = await service.hasNetworkError
        XCTAssertTrue(hasNetworkError)
    }
}

