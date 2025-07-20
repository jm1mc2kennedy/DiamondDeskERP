import Foundation
import CloudKit
import Combine
import os.log

@MainActor
class LoadTestingService: ObservableObject {
    @Published var isRunningTest = false
    @Published var testResults: [LoadTestResult] = []
    @Published var currentTestProgress: Double = 0.0
    @Published var activeConnections: Int = 0
    
    private let database: CKDatabase
    private let logger = Logger(subsystem: "DiamondDeskERP", category: "LoadTesting")
    private var testOperations: [LoadTestOperation] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    // MARK: - Load Test Configuration
    
    struct LoadTestConfiguration {
        let testType: LoadTestType
        let duration: TimeInterval
        let concurrentUsers: Int
        let operationsPerSecond: Int
        let rampUpTime: TimeInterval
        let dataSetSize: Int
        
        static let light = LoadTestConfiguration(
            testType: .stress,
            duration: 60,
            concurrentUsers: 10,
            operationsPerSecond: 5,
            rampUpTime: 10,
            dataSetSize: 100
        )
        
        static let moderate = LoadTestConfiguration(
            testType: .load,
            duration: 300,
            concurrentUsers: 25,
            operationsPerSecond: 15,
            rampUpTime: 30,
            dataSetSize: 500
        )
        
        static let heavy = LoadTestConfiguration(
            testType: .stress,
            duration: 600,
            concurrentUsers: 50,
            operationsPerSecond: 30,
            rampUpTime: 60,
            dataSetSize: 1000
        )
    }
    
    // MARK: - Test Execution
    
    func runLoadTest(configuration: LoadTestConfiguration) async {
        guard !isRunningTest else { return }
        
        isRunningTest = true
        currentTestProgress = 0.0
        activeConnections = 0
        
        logger.info("Starting load test with configuration: \(configuration)")
        
        let testResult = LoadTestResult(
            id: UUID().uuidString,
            testType: configuration.testType,
            startTime: Date(),
            configuration: configuration
        )
        
        do {
            // Prepare test data
            await prepareTestData(configuration: configuration)
            
            // Execute the load test
            let metrics = try await executeLoadTest(configuration: configuration)
            
            // Finalize results
            var finalResult = testResult
            finalResult.endTime = Date()
            finalResult.metrics = metrics
            finalResult.status = .completed
            
            testResults.append(finalResult)
            
            logger.info("Load test completed successfully")
            
        } catch {
            var finalResult = testResult
            finalResult.endTime = Date()
            finalResult.status = .failed(error.localizedDescription)
            
            testResults.append(finalResult)
            
            logger.error("Load test failed: \(error)")
        }
        
        isRunningTest = false
        currentTestProgress = 1.0
        activeConnections = 0
    }
    
    private func prepareTestData(configuration: LoadTestConfiguration) async {
        logger.debug("Preparing test data...")
        
        // Generate sample tasks
        testOperations = []
        
        for i in 0..<configuration.dataSetSize {
            let operation = LoadTestOperation(
                id: UUID().uuidString,
                type: LoadTestOperationType.allCases.randomElement() ?? .createTask,
                data: generateTestData(for: i),
                expectedDuration: TimeInterval.random(in: 0.1...2.0)
            )
            testOperations.append(operation)
        }
        
        logger.debug("Prepared \(testOperations.count) test operations")
    }
    
    private func generateTestData(for index: Int) -> [String: Any] {
        return [
            "title": "Load Test Task \(index)",
            "description": "This is a load test task created for performance testing",
            "priority": ["low", "medium", "high"].randomElement() ?? "medium",
            "dueDate": Date().addingTimeInterval(TimeInterval.random(in: 86400...604800)),
            "estimatedHours": Double.random(in: 1...8),
            "tags": ["load-test", "performance", "automated"]
        ]
    }
    
    private func executeLoadTest(configuration: LoadTestConfiguration) async throws -> LoadTestMetrics {
        let startTime = Date()
        var metrics = LoadTestMetrics()
        
        // Ramp up period
        await rampUpUsers(configuration: configuration, metrics: &metrics)
        
        // Main test period
        await runMainTest(configuration: configuration, metrics: &metrics)
        
        // Calculate final metrics
        let totalDuration = Date().timeIntervalSince(startTime)
        metrics.totalDuration = totalDuration
        metrics.averageResponseTime = metrics.totalResponseTime / Double(metrics.totalRequests)
        metrics.requestsPerSecond = Double(metrics.totalRequests) / totalDuration
        metrics.errorRate = Double(metrics.failedRequests) / Double(metrics.totalRequests)
        
        return metrics
    }
    
    private func rampUpUsers(configuration: LoadTestConfiguration, metrics: inout LoadTestMetrics) async {
        let rampUpInterval = configuration.rampUpTime / Double(configuration.concurrentUsers)
        
        for userIndex in 0..<configuration.concurrentUsers {
            Task {
                await simulateUser(
                    userId: "user_\(userIndex)",
                    configuration: configuration,
                    metrics: metrics
                )
            }
            
            activeConnections += 1
            
            if userIndex < configuration.concurrentUsers - 1 {
                try? await Task.sleep(for: .seconds(rampUpInterval))
            }
        }
        
        logger.debug("Ramp-up completed with \(configuration.concurrentUsers) users")
    }
    
    private func runMainTest(configuration: LoadTestConfiguration, metrics: inout LoadTestMetrics) async {
        let testEndTime = Date().addingTimeInterval(configuration.duration)
        
        while Date() < testEndTime {
            // Update progress
            let elapsed = Date().timeIntervalSince(testEndTime.addingTimeInterval(-configuration.duration))
            currentTestProgress = elapsed / configuration.duration
            
            try? await Task.sleep(for: .seconds(1))
        }
        
        logger.debug("Main test period completed")
    }
    
    private func simulateUser(userId: String, configuration: LoadTestConfiguration, metrics: LoadTestMetrics) async {
        let operationInterval = 1.0 / Double(configuration.operationsPerSecond)
        let endTime = Date().addingTimeInterval(configuration.duration + configuration.rampUpTime)
        
        while Date() < endTime {
            let operation = testOperations.randomElement()!
            await executeOperation(operation: operation, userId: userId, metrics: metrics)
            
            try? await Task.sleep(for: .seconds(operationInterval))
        }
        
        activeConnections -= 1
    }
    
    private func executeOperation(operation: LoadTestOperation, userId: String, metrics: LoadTestMetrics) async {
        let startTime = Date()
        
        do {
            switch operation.type {
            case .createTask:
                try await performCreateTask(operation: operation)
            case .readTask:
                try await performReadTask(operation: operation)
            case .updateTask:
                try await performUpdateTask(operation: operation)
            case .deleteTask:
                try await performDeleteTask(operation: operation)
            case .searchTasks:
                try await performSearchTasks(operation: operation)
            case .createClient:
                try await performCreateClient(operation: operation)
            case .readClient:
                try await performReadClient(operation: operation)
            }
            
            let responseTime = Date().timeIntervalSince(startTime)
            await updateMetrics(metrics: metrics, responseTime: responseTime, success: true)
            
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            await updateMetrics(metrics: metrics, responseTime: responseTime, success: false)
            
            logger.error("Operation failed for user \(userId): \(error)")
        }
    }
    
    // MARK: - Test Operations
    
    private func performCreateTask(operation: LoadTestOperation) async throws {
        let record = CKRecord(recordType: "LoadTestTask")
        record["title"] = operation.data["title"] as? String ?? ""
        record["description"] = operation.data["description"] as? String ?? ""
        record["priority"] = operation.data["priority"] as? String ?? ""
        record["dueDate"] = operation.data["dueDate"] as? Date ?? Date()
        record["estimatedHours"] = operation.data["estimatedHours"] as? Double ?? 0
        
        _ = try await database.save(record)
    }
    
    private func performReadTask(operation: LoadTestOperation) async throws {
        let predicate = NSPredicate(format: "title CONTAINS %@", "Load Test")
        let query = CKQuery(recordType: "LoadTestTask", predicate: predicate)
        query.fetchLimit = 10
        
        _ = try await database.records(matching: query)
    }
    
    private func performUpdateTask(operation: LoadTestOperation) async throws {
        // First find a record to update
        let predicate = NSPredicate(format: "title CONTAINS %@", "Load Test")
        let query = CKQuery(recordType: "LoadTestTask", predicate: predicate)
        query.fetchLimit = 1
        
        let records = try await database.records(matching: query)
        if let (_, result) = records.matchResults.first,
           case .success(let record) = result {
            record["updatedAt"] = Date()
            _ = try await database.save(record)
        }
    }
    
    private func performDeleteTask(operation: LoadTestOperation) async throws {
        let predicate = NSPredicate(format: "title CONTAINS %@", "Load Test")
        let query = CKQuery(recordType: "LoadTestTask", predicate: predicate)
        query.fetchLimit = 1
        
        let records = try await database.records(matching: query)
        if let (recordID, result) = records.matchResults.first,
           case .success(_) = result {
            _ = try await database.deleteRecord(withID: recordID)
        }
    }
    
    private func performSearchTasks(operation: LoadTestOperation) async throws {
        let searchTerms = ["urgent", "important", "review", "follow-up", "client"]
        let term = searchTerms.randomElement() ?? "urgent"
        
        let predicate = NSPredicate(format: "title CONTAINS %@ OR description CONTAINS %@", term, term)
        let query = CKQuery(recordType: "LoadTestTask", predicate: predicate)
        query.fetchLimit = 20
        
        _ = try await database.records(matching: query)
    }
    
    private func performCreateClient(operation: LoadTestOperation) async throws {
        let record = CKRecord(recordType: "LoadTestClient")
        record["guestName"] = "Load Test Client \(Int.random(in: 1000...9999))"
        record["email"] = "loadtest\(Int.random(in: 1000...9999))@example.com"
        record["phoneNumber"] = "555-\(Int.random(in: 1000...9999))"
        
        _ = try await database.save(record)
    }
    
    private func performReadClient(operation: LoadTestOperation) async throws {
        let predicate = NSPredicate(format: "guestName CONTAINS %@", "Load Test")
        let query = CKQuery(recordType: "LoadTestClient", predicate: predicate)
        query.fetchLimit = 10
        
        _ = try await database.records(matching: query)
    }
    
    private func updateMetrics(metrics: LoadTestMetrics, responseTime: TimeInterval, success: Bool) async {
        await MainActor.run {
            var updatedMetrics = metrics
            updatedMetrics.totalRequests += 1
            updatedMetrics.totalResponseTime += responseTime
            
            if success {
                updatedMetrics.successfulRequests += 1
            } else {
                updatedMetrics.failedRequests += 1
            }
            
            if responseTime > updatedMetrics.maxResponseTime {
                updatedMetrics.maxResponseTime = responseTime
            }
            
            if responseTime < updatedMetrics.minResponseTime {
                updatedMetrics.minResponseTime = responseTime
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanupTestData() async {
        logger.info("Cleaning up load test data...")
        
        do {
            // Delete test tasks
            let taskPredicate = NSPredicate(format: "title CONTAINS %@", "Load Test")
            let taskQuery = CKQuery(recordType: "LoadTestTask", predicate: taskPredicate)
            let taskRecords = try await database.records(matching: taskQuery)
            
            for (recordID, result) in taskRecords.matchResults {
                if case .success(_) = result {
                    try? await database.deleteRecord(withID: recordID)
                }
            }
            
            // Delete test clients
            let clientPredicate = NSPredicate(format: "guestName CONTAINS %@", "Load Test")
            let clientQuery = CKQuery(recordType: "LoadTestClient", predicate: clientPredicate)
            let clientRecords = try await database.records(matching: clientQuery)
            
            for (recordID, result) in clientRecords.matchResults {
                if case .success(_) = result {
                    try? await database.deleteRecord(withID: recordID)
                }
            }
            
            logger.info("Load test data cleanup completed")
            
        } catch {
            logger.error("Failed to cleanup test data: \(error)")
        }
    }
    
    // MARK: - Results Analysis
    
    func generatePerformanceReport() -> LoadTestReport {
        let report = LoadTestReport(
            testResults: testResults,
            averageResponseTime: testResults.map { $0.metrics?.averageResponseTime ?? 0 }.average,
            averageRequestsPerSecond: testResults.map { $0.metrics?.requestsPerSecond ?? 0 }.average,
            averageErrorRate: testResults.map { $0.metrics?.errorRate ?? 0 }.average,
            recommendations: generatePerformanceRecommendations()
        )
        
        return report
    }
    
    private func generatePerformanceRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let avgResponseTime = testResults.compactMap { $0.metrics?.averageResponseTime }.average
        let avgErrorRate = testResults.compactMap { $0.metrics?.errorRate }.average
        
        if avgResponseTime > 2.0 {
            recommendations.append("Consider implementing request caching to reduce response times")
        }
        
        if avgErrorRate > 0.05 {
            recommendations.append("Error rate is high - investigate CloudKit rate limiting and error handling")
        }
        
        if testResults.count < 3 {
            recommendations.append("Run more load tests to establish reliable performance baselines")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

enum LoadTestType: String, CaseIterable {
    case load = "Load Test"
    case stress = "Stress Test"
    case spike = "Spike Test"
    case volume = "Volume Test"
}

enum LoadTestOperationType: String, CaseIterable {
    case createTask
    case readTask
    case updateTask
    case deleteTask
    case searchTasks
    case createClient
    case readClient
}

struct LoadTestOperation {
    let id: String
    let type: LoadTestOperationType
    let data: [String: Any]
    let expectedDuration: TimeInterval
}

struct LoadTestResult {
    let id: String
    let testType: LoadTestType
    let startTime: Date
    var endTime: Date?
    var metrics: LoadTestMetrics?
    var status: LoadTestStatus = .running
    let configuration: LoadTestingService.LoadTestConfiguration
}

enum LoadTestStatus {
    case running
    case completed
    case failed(String)
}

struct LoadTestMetrics {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var totalResponseTime: TimeInterval = 0
    var averageResponseTime: TimeInterval = 0
    var minResponseTime: TimeInterval = Double.infinity
    var maxResponseTime: TimeInterval = 0
    var requestsPerSecond: Double = 0
    var errorRate: Double = 0
    var totalDuration: TimeInterval = 0
}

struct LoadTestReport {
    let testResults: [LoadTestResult]
    let averageResponseTime: Double
    let averageRequestsPerSecond: Double
    let averageErrorRate: Double
    let recommendations: [String]
}

// MARK: - Extensions

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
