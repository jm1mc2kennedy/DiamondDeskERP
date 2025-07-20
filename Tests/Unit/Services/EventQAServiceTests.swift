//
//  EventQAServiceTests.swift
//  DiamondDeskERPTests
//
//  Created by AI Assistant on 7/20/25.
//

import XCTest
import Combine
@testable import DiamondDeskERP

final class EventQAServiceTests: XCTestCase {
    var eventQAService: EventQAService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        eventQAService = EventQAService.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing history
        eventQAService.clearHistory()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        eventQAService.stopMonitoring()
        eventQAService.clearHistory()
        super.tearDown()
    }
    
    // MARK: - Monitoring Tests
    
    func testStartMonitoring() {
        // Given
        XCTAssertFalse(eventQAService.isMonitoring)
        
        // When
        eventQAService.startMonitoring()
        
        // Then
        XCTAssertTrue(eventQAService.isMonitoring)
    }
    
    func testStopMonitoring() {
        // Given
        eventQAService.startMonitoring()
        XCTAssertTrue(eventQAService.isMonitoring)
        
        // When
        eventQAService.stopMonitoring()
        
        // Then
        XCTAssertFalse(eventQAService.isMonitoring)
    }
    
    func testMonitoringStartLogsEvent() {
        // Given
        eventQAService.startMonitoring()
        
        // When
        let initialCount = eventQAService.eventHistory.count
        
        // Then
        XCTAssertGreaterThan(eventQAService.eventHistory.count, initialCount)
        
        let startEvent = eventQAService.eventHistory.first { $0.action == "start" }
        XCTAssertNotNil(startEvent)
        XCTAssertEqual(startEvent?.category, "monitoring")
        XCTAssertEqual(startEvent?.type, .system)
    }
    
    // MARK: - Event Logging Tests
    
    func testLogEvent() {
        // Given
        eventQAService.startMonitoring()
        let initialCount = eventQAService.eventHistory.count
        
        // When
        eventQAService.logEvent(
            type: .user,
            category: "task",
            action: "create",
            details: "Test task creation"
        )
        
        // Then
        XCTAssertEqual(eventQAService.eventHistory.count, initialCount + 1)
        
        let loggedEvent = eventQAService.eventHistory.first
        XCTAssertNotNil(loggedEvent)
        XCTAssertEqual(loggedEvent?.type, .user)
        XCTAssertEqual(loggedEvent?.category, "task")
        XCTAssertEqual(loggedEvent?.action, "create")
        XCTAssertEqual(loggedEvent?.details, "Test task creation")
    }
    
    func testLogEventWhenNotMonitoring() {
        // Given
        eventQAService.stopMonitoring()
        let initialCount = eventQAService.eventHistory.count
        
        // When
        eventQAService.logEvent(
            type: .user,
            category: "task",
            action: "create",
            details: "Test task creation"
        )
        
        // Then
        XCTAssertEqual(eventQAService.eventHistory.count, initialCount)
    }
    
    func testEventHistoryLimit() {
        // Given
        eventQAService.startMonitoring()
        let maxEvents = 1000 // From EventQAService.maxEventHistory
        
        // When
        for i in 0..<(maxEvents + 100) {
            eventQAService.logEvent(
                type: .system,
                category: "test",
                action: "event_\(i)",
                details: "Test event \(i)"
            )
        }
        
        // Then
        XCTAssertLessThanOrEqual(eventQAService.eventHistory.count, maxEvents)
    }
    
    // MARK: - Error Logging Tests
    
    func testLogError() {
        // Given
        let initialCount = eventQAService.errorHistory.count
        
        // When
        eventQAService.logError(
            category: "cloudkit",
            severity: .medium,
            message: "Test error message"
        )
        
        // Then
        XCTAssertEqual(eventQAService.errorHistory.count, initialCount + 1)
        
        let loggedError = eventQAService.errorHistory.first
        XCTAssertNotNil(loggedError)
        XCTAssertEqual(loggedError?.category, "cloudkit")
        XCTAssertEqual(loggedError?.severity, .medium)
        XCTAssertEqual(loggedError?.message, "Test error message")
    }
    
    func testLogErrorWithContext() {
        // Given
        let context = ["operation": "fetch", "recordType": "Task"]
        
        // When
        eventQAService.logError(
            category: "cloudkit",
            severity: .high,
            message: "Fetch failed",
            context: context
        )
        
        // Then
        let loggedError = eventQAService.errorHistory.first
        XCTAssertNotNil(loggedError)
        XCTAssertEqual(loggedError?.context.count, context.count)
    }
    
    func testErrorHistoryLimit() {
        // Given
        let maxErrors = 500 // From EventQAService.maxErrorHistory
        
        // When
        for i in 0..<(maxErrors + 50) {
            eventQAService.logError(
                category: "test",
                severity: .low,
                message: "Test error \(i)"
            )
        }
        
        // Then
        XCTAssertLessThanOrEqual(eventQAService.errorHistory.count, maxErrors)
    }
    
    // MARK: - Alert Summary Tests
    
    func testAlertSummaryIncrementsOnError() {
        // Given
        let initialCritical = eventQAService.alertSummary.criticalErrors
        let initialHigh = eventQAService.alertSummary.highErrors
        
        // When
        eventQAService.logError(category: "test", severity: .critical, message: "Critical error")
        eventQAService.logError(category: "test", severity: .high, message: "High error")
        
        // Then
        XCTAssertEqual(eventQAService.alertSummary.criticalErrors, initialCritical + 1)
        XCTAssertEqual(eventQAService.alertSummary.highErrors, initialHigh + 1)
    }
    
    func testAlertSummaryHasCriticalIssues() {
        // Given
        var alertSummary = AlertSummary()
        
        // When - No critical issues
        XCTAssertFalse(alertSummary.hasCriticalIssues)
        
        // When - Critical error
        alertSummary.incrementError(severity: .critical)
        XCTAssertTrue(alertSummary.hasCriticalIssues)
        
        // When - Reset and add high errors
        alertSummary.reset()
        alertSummary.incrementError(severity: .high)
        alertSummary.incrementError(severity: .high)
        alertSummary.incrementError(severity: .high)
        alertSummary.incrementError(severity: .high)
        XCTAssertTrue(alertSummary.hasCriticalIssues)
    }
    
    func testAlertSummaryReset() {
        // Given
        var alertSummary = AlertSummary()
        alertSummary.incrementError(severity: .critical)
        alertSummary.incrementError(severity: .high)
        alertSummary.incrementPerformanceAlert()
        alertSummary.incrementCloudKitAlert()
        
        // When
        alertSummary.reset()
        
        // Then
        XCTAssertEqual(alertSummary.criticalErrors, 0)
        XCTAssertEqual(alertSummary.highErrors, 0)
        XCTAssertEqual(alertSummary.performanceAlerts, 0)
        XCTAssertEqual(alertSummary.cloudKitAlerts, 0)
    }
    
    // MARK: - Clear History Tests
    
    func testClearHistory() {
        // Given
        eventQAService.startMonitoring()
        eventQAService.logEvent(type: .user, category: "test", action: "test", details: "test")
        eventQAService.logError(category: "test", severity: .low, message: "test error")
        
        XCTAssertGreaterThan(eventQAService.eventHistory.count, 0)
        XCTAssertGreaterThan(eventQAService.errorHistory.count, 0)
        
        // When
        eventQAService.clearHistory()
        
        // Then
        XCTAssertEqual(eventQAService.eventHistory.count, 0)
        XCTAssertEqual(eventQAService.errorHistory.count, 0)
    }
    
    // MARK: - Export Tests
    
    func testExportEventLog() {
        // Given
        eventQAService.startMonitoring()
        eventQAService.logEvent(type: .user, category: "task", action: "create", details: "Test task")
        eventQAService.logError(category: "cloudkit", severity: .medium, message: "Test error")
        
        // When
        let exportedLog = eventQAService.exportEventLog()
        
        // Then
        XCTAssertTrue(exportedLog.contains("DIAMOND DESK ERP - EVENT QA LOG"))
        XCTAssertTrue(exportedLog.contains("=== EVENTS ==="))
        XCTAssertTrue(exportedLog.contains("=== ERRORS ==="))
        XCTAssertTrue(exportedLog.contains("task"))
        XCTAssertTrue(exportedLog.contains("create"))
        XCTAssertTrue(exportedLog.contains("Test error"))
    }
    
    // MARK: - Event Type Tests
    
    func testEventTypeCaseIterable() {
        // When
        let allEventTypes = EventType.allCases
        
        // Then
        XCTAssertEqual(allEventTypes.count, 8)
        XCTAssertTrue(allEventTypes.contains(.system))
        XCTAssertTrue(allEventTypes.contains(.user))
        XCTAssertTrue(allEventTypes.contains(.cloudkit))
        XCTAssertTrue(allEventTypes.contains(.performance))
        XCTAssertTrue(allEventTypes.contains(.error))
        XCTAssertTrue(allEventTypes.contains(.security))
        XCTAssertTrue(allEventTypes.contains(.analytics))
        XCTAssertTrue(allEventTypes.contains(.metrics))
    }
    
    // MARK: - Error Severity Tests
    
    func testErrorSeverityCaseIterable() {
        // When
        let allSeverities = ErrorSeverity.allCases
        
        // Then
        XCTAssertEqual(allSeverities.count, 4)
        XCTAssertTrue(allSeverities.contains(.low))
        XCTAssertTrue(allSeverities.contains(.medium))
        XCTAssertTrue(allSeverities.contains(.high))
        XCTAssertTrue(allSeverities.contains(.critical))
    }
    
    // MARK: - System Metrics Tests
    
    func testSystemMetricsInitialization() {
        // When
        let metrics = SystemMetrics()
        
        // Then
        XCTAssertEqual(metrics.memoryUsageMB, 0)
        XCTAssertEqual(metrics.cpuUsagePercent, 0.0)
        XCTAssertEqual(metrics.activeEvents, 0)
        XCTAssertEqual(metrics.errorCount, 0)
        XCTAssertEqual(metrics.lastEventType, .system)
    }
    
    // MARK: - Codable Tests
    
    func testEventEntryCodable() throws {
        // Given
        let event = EventEntry(
            id: UUID(),
            timestamp: Date(),
            type: .user,
            category: "task",
            action: "create",
            details: "Test task creation"
        )
        
        // When
        let data = try JSONEncoder().encode(event)
        let decodedEvent = try JSONDecoder().decode(EventEntry.self, from: data)
        
        // Then
        XCTAssertEqual(decodedEvent.id, event.id)
        XCTAssertEqual(decodedEvent.type, event.type)
        XCTAssertEqual(decodedEvent.category, event.category)
        XCTAssertEqual(decodedEvent.action, event.action)
        XCTAssertEqual(decodedEvent.details, event.details)
    }
    
    func testErrorEntryCodable() throws {
        // Given
        let error = ErrorEntry(
            id: UUID(),
            timestamp: Date(),
            category: "cloudkit",
            severity: .high,
            message: "Test error message"
        )
        
        // When
        let data = try JSONEncoder().encode(error)
        let decodedError = try JSONDecoder().decode(ErrorEntry.self, from: data)
        
        // Then
        XCTAssertEqual(decodedError.id, error.id)
        XCTAssertEqual(decodedError.category, error.category)
        XCTAssertEqual(decodedError.severity, error.severity)
        XCTAssertEqual(decodedError.message, error.message)
    }
    
    func testSystemMetricsCodable() throws {
        // Given
        let metrics = SystemMetrics(
            memoryUsageMB: 128,
            cpuUsagePercent: 15.5,
            activeEvents: 50,
            errorCount: 3,
            lastUpdate: Date(),
            lastEventType: .performance,
            lastEventTime: Date()
        )
        
        // When
        let data = try JSONEncoder().encode(metrics)
        let decodedMetrics = try JSONDecoder().decode(SystemMetrics.self, from: data)
        
        // Then
        XCTAssertEqual(decodedMetrics.memoryUsageMB, metrics.memoryUsageMB)
        XCTAssertEqual(decodedMetrics.cpuUsagePercent, metrics.cpuUsagePercent)
        XCTAssertEqual(decodedMetrics.activeEvents, metrics.activeEvents)
        XCTAssertEqual(decodedMetrics.errorCount, metrics.errorCount)
        XCTAssertEqual(decodedMetrics.lastEventType, metrics.lastEventType)
    }
    
    // MARK: - Integration Tests
    
    func testEventLoggingTriggersAlertUpdates() {
        // Given
        eventQAService.startMonitoring()
        let initialErrorCount = eventQAService.alertSummary.totalErrors
        
        // When
        eventQAService.logEvent(
            type: .error,
            category: "test",
            action: "error_occurred",
            details: "Test error event"
        )
        
        // Then
        XCTAssertGreaterThan(eventQAService.alertSummary.totalErrors, initialErrorCount)
    }
    
    func testPerformanceEventLogging() {
        // Given
        eventQAService.startMonitoring()
        let initialAlerts = eventQAService.alertSummary.performanceAlerts
        
        // When
        eventQAService.logEvent(
            type: .performance,
            category: "performance",
            action: "slow_operation",
            details: "Operation took too long"
        )
        
        // Then
        XCTAssertGreaterThan(eventQAService.alertSummary.performanceAlerts, initialAlerts)
    }
    
    func testCloudKitEventLogging() {
        // Given
        eventQAService.startMonitoring()
        let initialAlerts = eventQAService.alertSummary.cloudKitAlerts
        
        // When
        eventQAService.logEvent(
            type: .cloudkit,
            category: "cloudkit",
            action: "fetch_error",
            details: "CloudKit fetch failed"
        )
        
        // Then
        XCTAssertGreaterThan(eventQAService.alertSummary.cloudKitAlerts, initialAlerts)
    }
}
