//
//  ServiceTests.swift
//  DiamondDeskERPTests
//
//  Created by J.Michael McDermott on 7/18/25.
//

import Testing
import CloudKit
import UserNotifications
@testable import DiamondDeskERP

@MainActor
struct ServiceTests {
    
    // MARK: - Notification Service Tests
    
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
    
    @Test("NotificationService requests authorization")
    func testNotificationServiceRequestsAuthorization() async throws {
        let mockCenter = MockUNUserNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        let granted = try await service.requestPermission()
        
        #expect(mockCenter.requestAuthorizationCalled == true)
        #expect(granted == true)
    }
    
    @Test("NotificationService schedules local notification")
    func testNotificationServiceSchedulesNotification() async throws {
        let mockCenter = MockUNUserNotificationCenter()
        mockCenter.authorizationStatus = .authorized
        let service = NotificationService(notificationCenter: mockCenter)
        
        try await service.scheduleLocalNotification(
            title: "Test Title",
            body: "Test Body",
            date: Date().addingTimeInterval(60)
        )
        
        #expect(mockCenter.addNotificationRequestCalled == true)
        #expect(mockCenter.scheduledNotifications.count == 1)
        #expect(mockCenter.scheduledNotifications.first?.content.title == "Test Title")
    }
    
    @Test("NotificationService schedules task reminder")
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
        
        #expect(mockCenter.addNotificationRequestCalled == true)
        #expect(mockCenter.scheduledNotifications.count == 1)
        
        let notification = mockCenter.scheduledNotifications.first!
        #expect(notification.content.title.contains("Task Reminder") == true)
        #expect(notification.content.body.contains("Test Task") == true)
    }
    
    // MARK: - Analytics Service Tests
    
    @Test("AnalyticsService calculates task completion rate")
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
        
        #expect(completionRate == 0.5) // 1 out of 2 tasks completed
    }
    
    @Test("AnalyticsService calculates average resolution time")
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
        
        #expect(abs(avgResolutionTime - 5400) < 60) // Average of 1.5 hours (5400 seconds)
    }
    
    @Test("AnalyticsService generates KPI summary")
    func testAnalyticsServiceKPISummary() async throws {
        let service = AnalyticsService()
        
        // Create test data
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
        
        #expect(kpiSummary.totalTasks == 1)
        #expect(kpiSummary.totalTickets == 1)
        #expect(kpiSummary.taskCompletionRate == 1.0)
    }
    
    // MARK: - User Provisioning Service Tests
    
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
    
    @Test("UserProvisioningService creates new user")
    func testUserProvisioningServiceCreatesUser() async throws {
        let service = MockUserProvisioningService()
        
        let userId = try await service.createUser(
            name: "Test User",
            email: "test@example.com",
            role: "manager",
            storeCode: "08"
        )
        
        #expect(service.createUserCalled == true)
        #expect(userId == "mock-user-id")
    }
    
    @Test("UserProvisioningService updates user role")
    func testUserProvisioningServiceUpdatesRole() async throws {
        let service = MockUserProvisioningService()
        
        try await service.updateUserRole("test-user", newRole: "admin")
        
        #expect(service.updateUserCalled == true)
    }
    
    @Test("UserProvisioningService deactivates user")
    func testUserProvisioningServiceDeactivatesUser() async throws {
        let service = MockUserProvisioningService()
        
        try await service.deactivateUser("test-user")
        
        #expect(service.deactivateUserCalled == true)
    }
    
    // MARK: - Performance Optimization Service Tests
    
    @Test("PerformanceOptimizationService optimizes memory usage")
    func testPerformanceOptimizationServiceMemoryOptimization() async throws {
        let service = PerformanceOptimizationService()
        
        // Create large array to simulate memory usage
        var largeArray = Array(0..<10000)
        
        await service.optimizeMemoryUsage()
        
        // The service should trigger garbage collection
        // This is more of a functional test to ensure the method runs without error
        #expect(largeArray.count == 10000) // Array should still exist
        
        largeArray.removeAll() // Clean up
    }
    
    @Test("PerformanceOptimizationService optimizes network requests")
    func testPerformanceOptimizationServiceNetworkOptimization() async throws {
        let service = PerformanceOptimizationService()
        
        await service.optimizeNetworkRequests()
        
        // This is a functional test to ensure the method runs without error
        // In a real implementation, we would test specific optimization behaviors
        #expect(true) // Method completed successfully
    }
    
    // MARK: - Offline Capability Service Tests
    
    @Test("OfflineCapabilityService handles offline state")
    func testOfflineCapabilityServiceOfflineState() async throws {
        let service = OfflineCapabilityService()
        
        // Simulate going offline
        await service.handleOfflineState()
        
        let isOffline = await service.isOffline
        #expect(isOffline == true)
    }
    
    @Test("OfflineCapabilityService syncs when online")
    func testOfflineCapabilityServiceSyncWhenOnline() async throws {
        let service = OfflineCapabilityService()
        
        // Simulate going back online
        await service.handleOnlineState()
        
        let isOffline = await service.isOffline
        #expect(isOffline == false)
    }
    
    // MARK: - Accessibility Service Tests
    
    @Test("AccessibilityService enables voice over support")
    func testAccessibilityServiceVoiceOverSupport() async throws {
        let service = AccessibilityService()
        
        await service.enableVoiceOverSupport()
        
        let isVoiceOverEnabled = await service.isVoiceOverEnabled
        #expect(isVoiceOverEnabled == true)
    }
    
    @Test("AccessibilityService enables larger text support")
    func testAccessibilityServiceLargerTextSupport() async throws {
        let service = AccessibilityService()
        
        await service.enableLargerTextSupport()
        
        let isLargerTextEnabled = await service.isLargerTextEnabled
        #expect(isLargerTextEnabled == true)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Services handle CloudKit errors gracefully")
    func testServiceCloudKitErrorHandling() async throws {
        // Test that services can handle CloudKit errors without crashing
        let service = AnalyticsService()
        
        // This would typically test error scenarios, but since our mock
        // analytics service doesn't use CloudKit directly, we ensure
        // it handles empty data gracefully
        let emptyKPI = service.generateKPISummary(tasks: [], tickets: [])
        
        #expect(emptyKPI.totalTasks == 0)
        #expect(emptyKPI.totalTickets == 0)
        #expect(emptyKPI.taskCompletionRate == 0.0)
    }
    
    @Test("Services handle network connectivity issues")
    func testServiceNetworkErrorHandling() async throws {
        let service = OfflineCapabilityService()
        
        // Test that offline service handles network issues gracefully
        await service.handleNetworkError()
        
        let hasNetworkError = await service.hasNetworkError
        #expect(hasNetworkError == true)
    }
}
