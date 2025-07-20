//
//  EventQAService.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import CloudKit
import Combine
import OSLog

/// Enterprise-grade Event Quality Assurance service for production monitoring
/// Provides real-time event monitoring, debugging, and quality assurance capabilities
@MainActor
final class EventQAService: ObservableObject {
    static let shared = EventQAService()
    
    private let logger = Logger(subsystem: "com.diamonddesk.erp", category: "event-qa")
    private let maxEventHistory = 1000
    private let maxErrorHistory = 500
    
    // MARK: - Published Properties
    
    @Published var isMonitoring: Bool = false
    @Published var eventHistory: [EventEntry] = []
    @Published var errorHistory: [ErrorEntry] = []
    @Published var systemMetrics: SystemMetrics = SystemMetrics()
    @Published var alertSummary: AlertSummary = AlertSummary()
    
    // MARK: - Event Monitoring
    
    private var eventSubscription: AnyCancellable?
    private var metricsTimer: Timer?
    
    private init() {
        setupEventMonitoring()
        startMetricsCollection()
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() {
        isMonitoring = true
        logger.info("Event QA monitoring started")
        
        // Log monitoring start event
        logEvent(
            type: .system,
            category: "monitoring",
            action: "start",
            details: "Event QA Console monitoring activated"
        )
    }
    
    func stopMonitoring() {
        isMonitoring = false
        logger.info("Event QA monitoring stopped")
        
        // Log monitoring stop event
        logEvent(
            type: .system,
            category: "monitoring", 
            action: "stop",
            details: "Event QA Console monitoring deactivated"
        )
    }
    
    func clearHistory() {
        eventHistory.removeAll()
        errorHistory.removeAll()
        logger.info("Event QA history cleared")
    }
    
    func exportEventLog() -> String {
        let events = eventHistory.map { event in
            "\(event.timestamp.ISO8601Format()) | \(event.type.rawValue.uppercased()) | \(event.category) | \(event.action) | \(event.details)"
        }
        
        let errors = errorHistory.map { error in
            "\(error.timestamp.ISO8601Format()) | ERROR | \(error.category) | \(error.severity.rawValue) | \(error.message)"
        }
        
        return """
        DIAMOND DESK ERP - EVENT QA LOG
        Generated: \(Date().ISO8601Format())
        
        === EVENTS ===
        \(events.joined(separator: "\n"))
        
        === ERRORS ===
        \(errors.joined(separator: "\n"))
        """
    }
    
    // MARK: - Event Logging
    
    func logEvent(
        type: EventType,
        category: String,
        action: String,
        details: String,
        metadata: [String: Any] = [:]
    ) {
        guard isMonitoring else { return }
        
        let event = EventEntry(
            id: UUID(),
            timestamp: Date(),
            type: type,
            category: category,
            action: action,
            details: details,
            metadata: metadata
        )
        
        // Add to history (maintain size limit)
        eventHistory.insert(event, at: 0)
        if eventHistory.count > maxEventHistory {
            eventHistory.removeLast()
        }
        
        // Update metrics
        updateMetrics(for: event)
        
        // Check for alerts
        checkAlerts(for: event)
        
        logger.debug("Event logged: \(event.category).\(event.action)")
    }
    
    func logError(
        category: String,
        severity: ErrorSeverity,
        message: String,
        error: Error? = nil,
        context: [String: Any] = [:]
    ) {
        let errorEntry = ErrorEntry(
            id: UUID(),
            timestamp: Date(),
            category: category,
            severity: severity,
            message: message,
            errorDescription: error?.localizedDescription,
            context: context
        )
        
        // Add to error history (maintain size limit)
        errorHistory.insert(errorEntry, at: 0)
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeLast()
        }
        
        // Update alert summary
        alertSummary.incrementError(severity: severity)
        
        logger.error("Error logged: \(message)")
        
        // Log as event too
        logEvent(
            type: .error,
            category: category,
            action: "error_occurred",
            details: message,
            metadata: ["severity": severity.rawValue]
        )
    }
    
    // MARK: - Metrics Collection
    
    private func startMetricsCollection() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectSystemMetrics()
            }
        }
    }
    
    private func collectSystemMetrics() {
        let memoryInfo = ProcessInfo.processInfo.memoryFootprint
        let cpuUsage = ProcessInfo.processInfo.cpuUsage
        
        systemMetrics = SystemMetrics(
            memoryUsageMB: memoryInfo / 1024 / 1024,
            cpuUsagePercent: cpuUsage,
            activeEvents: eventHistory.count,
            errorCount: errorHistory.count,
            lastUpdate: Date()
        )
        
        // Log metrics event
        logEvent(
            type: .metrics,
            category: "system",
            action: "metrics_collected",
            details: "Memory: \(systemMetrics.memoryUsageMB)MB, CPU: \(String(format: "%.1f", systemMetrics.cpuUsagePercent))%"
        )
    }
    
    // MARK: - Alert Management
    
    private func checkAlerts(for event: EventEntry) {
        // Check for error patterns
        if event.type == .error {
            alertSummary.incrementError(severity: .medium)
        }
        
        // Check for performance issues
        if event.category == "performance" && event.action.contains("slow") {
            alertSummary.incrementPerformanceAlert()
        }
        
        // Check for CloudKit issues
        if event.category == "cloudkit" && event.action.contains("error") {
            alertSummary.incrementCloudKitAlert()
        }
    }
    
    private func updateMetrics(for event: EventEntry) {
        // Update event type counters in system metrics
        systemMetrics.lastEventType = event.type
        systemMetrics.lastEventTime = event.timestamp
    }
    
    // MARK: - Monitoring Setup
    
    private func setupEventMonitoring() {
        // Monitor CloudKit operations
        NotificationCenter.default.publisher(for: .cloudKitOperationCompleted)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &subscriptions)
        
        // Monitor performance events
        NotificationCenter.default.publisher(for: .performanceMetricRecorded)
            .sink { [weak self] notification in
                self?.handlePerformanceEvent(notification)
            }
            .store(in: &subscriptions)
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let operation = userInfo["operation"] as? String else { return }
        
        let success = userInfo["success"] as? Bool ?? true
        let duration = userInfo["duration"] as? TimeInterval ?? 0
        
        logEvent(
            type: success ? .cloudkit : .error,
            category: "cloudkit",
            action: operation,
            details: "Duration: \(String(format: "%.3f", duration))s",
            metadata: userInfo
        )
    }
    
    private func handlePerformanceEvent(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let metric = userInfo["metric"] as? String else { return }
        
        let value = userInfo["value"] as? Double ?? 0
        let threshold = userInfo["threshold"] as? Double ?? 0
        
        let type: EventType = value > threshold ? .performance : .system
        
        logEvent(
            type: type,
            category: "performance",
            action: metric,
            details: "Value: \(value), Threshold: \(threshold)",
            metadata: userInfo
        )
    }
}

// MARK: - Data Models

struct EventEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let category: String
    let action: String
    let details: String
    let metadata: [String: Any]
    
    enum CodingKeys: CodingKey {
        case id, timestamp, type, category, action, details, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(EventType.self, forKey: .type)
        category = try container.decode(String.self, forKey: .category)
        action = try container.decode(String.self, forKey: .action)
        details = try container.decode(String.self, forKey: .details)
        metadata = [:]  // Simplified for Codable compliance
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(action, forKey: .action)
        try container.encode(details, forKey: .details)
    }
    
    init(id: UUID, timestamp: Date, type: EventType, category: String, action: String, details: String, metadata: [String: Any] = [:]) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.category = category
        self.action = action
        self.details = details
        self.metadata = metadata
    }
}

enum EventType: String, CaseIterable, Codable {
    case system = "system"
    case user = "user"
    case cloudkit = "cloudkit"
    case performance = "performance"
    case error = "error"
    case security = "security"
    case analytics = "analytics"
    case metrics = "metrics"
}

struct ErrorEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let category: String
    let severity: ErrorSeverity
    let message: String
    let errorDescription: String?
    let context: [String: Any]
    
    init(id: UUID, timestamp: Date, category: String, severity: ErrorSeverity, message: String, errorDescription: String? = nil, context: [String: Any] = [:]) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.severity = severity
        self.message = message
        self.errorDescription = errorDescription
        self.context = context
    }
    
    enum CodingKeys: CodingKey {
        case id, timestamp, category, severity, message, errorDescription
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        category = try container.decode(String.self, forKey: .category)
        severity = try container.decode(ErrorSeverity.self, forKey: .severity)
        message = try container.decode(String.self, forKey: .message)
        errorDescription = try container.decodeIfPresent(String.self, forKey: .errorDescription)
        context = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(severity, forKey: .severity)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(errorDescription, forKey: .errorDescription)
    }
}

enum ErrorSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct SystemMetrics: Codable {
    var memoryUsageMB: Int = 0
    var cpuUsagePercent: Double = 0.0
    var activeEvents: Int = 0
    var errorCount: Int = 0
    var lastUpdate: Date = Date()
    var lastEventType: EventType = .system
    var lastEventTime: Date = Date()
}

struct AlertSummary: Codable {
    var criticalErrors: Int = 0
    var highErrors: Int = 0
    var mediumErrors: Int = 0
    var lowErrors: Int = 0
    var performanceAlerts: Int = 0
    var cloudKitAlerts: Int = 0
    var lastReset: Date = Date()
    
    mutating func incrementError(severity: ErrorSeverity) {
        switch severity {
        case .critical:
            criticalErrors += 1
        case .high:
            highErrors += 1
        case .medium:
            mediumErrors += 1
        case .low:
            lowErrors += 1
        }
    }
    
    mutating func incrementPerformanceAlert() {
        performanceAlerts += 1
    }
    
    mutating func incrementCloudKitAlert() {
        cloudKitAlerts += 1
    }
    
    mutating func reset() {
        criticalErrors = 0
        highErrors = 0
        mediumErrors = 0
        lowErrors = 0
        performanceAlerts = 0
        cloudKitAlerts = 0
        lastReset = Date()
    }
    
    var totalErrors: Int {
        criticalErrors + highErrors + mediumErrors + lowErrors
    }
    
    var hasCriticalIssues: Bool {
        criticalErrors > 0 || highErrors > 3
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let cloudKitOperationCompleted = Notification.Name("cloudKitOperationCompleted")
    static let performanceMetricRecorded = Notification.Name("performanceMetricRecorded")
}

extension ProcessInfo {
    var memoryFootprint: Int {
        let KERN_SUCCESS = 0
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    var cpuUsage: Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == 0 ? Double(info.resident_size) / 1024.0 / 1024.0 : 0.0
    }
}
