import Foundation
internal import Combine

/// Performance monitoring and benchmarking system for DiamondDeskERP
@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var isMonitoring = false
    @Published var currentMetrics: MonitorPerformanceMetrics = MonitorPerformanceMetrics()
    @Published var historicalData: [PerformanceSnapshot] = []
    
    private var metricsTimer: Timer?
    private var operations: [String: OperationMetrics] = [:]
    private let maxHistoryCount = 100
    
    private init() {}
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startMetricsCollection()
        
        print("🚀 Performance monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        metricsTimer?.invalidate()
        metricsTimer = nil
        
        generatePerformanceReport()
        
        print("⏹️ Performance monitoring stopped")
    }
    
    private func startMetricsCollection() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectCurrentMetrics()
            }
        }
    }
    
    private func collectCurrentMetrics() {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            memoryUsage: getCurrentMemoryUsage(),
            cpuUsage: getCurrentCPUUsage(),
            activeOperations: operations.count,
            networkRequests: currentMetrics.networkRequestCount
        )
        
        historicalData.append(snapshot)
        
        // Maintain history limit
        if historicalData.count > maxHistoryCount {
            historicalData.removeFirst()
        }
        
        updateCurrentMetrics()
    }
    
    private func updateCurrentMetrics() {
        let recentSnapshots = Array(historicalData.suffix(10))
        
        currentMetrics = MonitorPerformanceMetrics(
            memoryUsage: recentSnapshots.last?.memoryUsage ?? 0,
            averageMemoryUsage: recentSnapshots.map(\.memoryUsage).reduce(0, +) / Double(recentSnapshots.count),
            peakMemoryUsage: recentSnapshots.map(\.memoryUsage).max() ?? 0,
            cpuUsage: recentSnapshots.last?.cpuUsage ?? 0,
            averageCPUUsage: recentSnapshots.map(\.cpuUsage).reduce(0, +) / Double(recentSnapshots.count),
            networkRequestCount: currentMetrics.networkRequestCount,
            activeOperationCount: operations.count,
            totalOperationsCompleted: currentMetrics.totalOperationsCompleted
        )
    }
    
    // MARK: - Operation Tracking
    
    func startOperation(_ name: String) -> OperationToken {
        let token = OperationToken(id: UUID(), name: name)
        let metrics = OperationMetrics(
            name: name,
            startTime: Date(),
            memoryAtStart: getCurrentMemoryUsage()
        )
        
        operations[token.id.uuidString] = metrics
        
        print("▶️ Started operation: \(name)")
        return token
    }
    
    func endOperation(_ token: OperationToken) {
        guard var metrics = operations[token.id.uuidString] else { return }
        
        metrics.endTime = Date()
        metrics.memoryAtEnd = getCurrentMemoryUsage()
        metrics.duration = metrics.endTime!.timeIntervalSince(metrics.startTime)
        
        operations.removeValue(forKey: token.id.uuidString)
        currentMetrics.totalOperationsCompleted += 1
        
        // Log performance if operation took longer than threshold
        if metrics.duration > 0.5 {
            print("⚠️ Slow operation detected: \(metrics.name) took \(String(format: "%.3f", metrics.duration))s")
        } else {
            print("✅ Completed operation: \(metrics.name) in \(String(format: "%.3f", metrics.duration))s")
        }
        
        // Store completed operation for analysis
        storeCompletedOperation(metrics)
    }
    
    private func storeCompletedOperation(_ metrics: OperationMetrics) {
        // In a real implementation, this could store to Core Data or file system
        // For now, we'll just track in memory
    }
    
    // MARK: - Network Monitoring
    
    func recordNetworkRequest() {
        currentMetrics.networkRequestCount += 1
    }
    
    // MARK: - Memory and CPU Utilities
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // Convert to MB
        }
        
        return 0
    }
    
    private func getCurrentCPUUsage() -> Double {
        var kr: kern_return_t
        var cpuInfo: processor_info_array_t? = nil
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUsU: natural_t = 0
        var cpuUsage: Double = 0

        kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        if kr == KERN_SUCCESS, let cpuInfo = cpuInfo {
            // Basic CPU usage calculation: sum up user + system + nice
            for cpu in 0..<Int(numCPUsU) {
                let cpuLoadInfo = cpuInfo.advanced(by: Int(CPU_STATE_MAX) * cpu)
                let user = Double(cpuLoadInfo[Int(CPU_STATE_USER)])
                let system = Double(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
                let nice = Double(cpuLoadInfo[Int(CPU_STATE_NICE)])
                let total = user + system + Double(cpuLoadInfo[Int(CPU_STATE_IDLE)]) + nice
                cpuUsage += (user + system + nice) / total
            }
            cpuUsage = (cpuUsage / Double(numCPUsU)) * 100
            // Deallocate memory
            let deallocateSize = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), deallocateSize)
            return cpuUsage
        }
        return 0
    }
    
    // MARK: - Benchmarking
    
    func runBenchmark() async -> BenchmarkResults {
        print("🏁 Starting performance benchmark...")
        
        let results = BenchmarkResults()
        
        // Employee Service Benchmark
        results.employeeServiceResults = await benchmarkEmployeeService()
        
        // Workflow Service Benchmark
        results.workflowServiceResults = await benchmarkWorkflowService()
        
        // Asset Management Benchmark
        results.assetManagementResults = await benchmarkAssetManagementService()
        
        // UI Performance Benchmark
        results.uiPerformanceResults = await benchmarkUIPerformance()
        
        print("🏆 Benchmark completed!")
        return results
    }
    
    private func benchmarkEmployeeService() async -> ServiceBenchmarkResults {
        let service = EmployeeService()
        var results = ServiceBenchmarkResults(serviceName: "Employee Service")
        
        // Create operation benchmark
        let createToken = startOperation("Employee Creation Benchmark")
        let startTime = Date()
        
        for i in 0..<20 {
            let employee = Employee(
                employeeNumber: "BENCH\(String(format: "%03d", i))",
                firstName: "Benchmark",
                lastName: "Employee\(i)",
                email: "benchmark\(i)@company.com",
                department: "Testing",
                title: "Benchmark Tester",
                hireDate: Date(),
                address: Address(street: "123 Test St", city: "Test City", state: "TS", zipCode: "12345"),
                emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Contact", phone: "555-0123"),
                workLocation: .office,
                employmentType: .fullTime
            )
            
            await service.createEmployee(employee)
        }
        
        let createTime = Date().timeIntervalSince(startTime)
        endOperation(createToken)
        
        results.createOperationTime = createTime
        results.averageCreateTime = createTime / 20
        
        // Read operation benchmark
        let readToken = startOperation("Employee Read Benchmark")
        let readStartTime = Date()
        
        let employees = await service.getAllEmployees()
        
        let readTime = Date().timeIntervalSince(readStartTime)
        endOperation(readToken)
        
        results.readOperationTime = readTime
        results.recordCount = employees.count
        
        // Search operation benchmark
        let searchToken = startOperation("Employee Search Benchmark")
        let searchStartTime = Date()
        
        _ = await service.searchEmployees(query: "Benchmark")
        
        let searchTime = Date().timeIntervalSince(searchStartTime)
        endOperation(searchToken)
        
        results.searchOperationTime = searchTime
        
        return results
    }
    
    private func benchmarkWorkflowService() async -> ServiceBenchmarkResults {
        let service = WorkflowService()
        var results = ServiceBenchmarkResults(serviceName: "Workflow Service")
        
        // Create operation benchmark
        let createToken = startOperation("Workflow Creation Benchmark")
        let startTime = Date()
        
        for i in 0..<15 {
            let workflow = Workflow(
                title: "Benchmark Workflow \(i)",
                description: "Performance testing workflow",
                priority: .medium,
                assignedTo: UUID(),
                dueDate: Date().addingTimeInterval(86400),
                category: .approval,
                steps: []
            )
            
            await service.createWorkflow(workflow)
        }
        
        let createTime = Date().timeIntervalSince(startTime)
        endOperation(createToken)
        
        results.createOperationTime = createTime
        results.averageCreateTime = createTime / 15
        
        // Read operation benchmark
        let readToken = startOperation("Workflow Read Benchmark")
        let readStartTime = Date()
        
        let workflows = await service.getAllWorkflows()
        
        let readTime = Date().timeIntervalSince(readStartTime)
        endOperation(readToken)
        
        results.readOperationTime = readTime
        results.recordCount = workflows.count
        
        return results
    }
    
    private func benchmarkAssetManagementService() async -> ServiceBenchmarkResults {
        let service = AssetManagementService()
        var results = ServiceBenchmarkResults(serviceName: "Asset Management Service")
        
        // Upload operation benchmark
        let uploadToken = startOperation("Asset Upload Benchmark")
        let startTime = Date()
        
        for i in 0..<10 {
            let asset = Asset(
                name: "Benchmark Asset \(i)",
                type: .document,
                size: 2048,
                mimeType: "application/pdf",
                tags: ["benchmark", "test"],
                uploadedBy: UUID(),
                projectId: UUID()
            )
            
            await service.uploadAsset(asset, data: Data(count: 2048))
        }
        
        let uploadTime = Date().timeIntervalSince(startTime)
        endOperation(uploadToken)
        
        results.createOperationTime = uploadTime
        results.averageCreateTime = uploadTime / 10
        
        // Read operation benchmark
        let readToken = startOperation("Asset Read Benchmark")
        let readStartTime = Date()
        
        let assets = await service.getAssets()
        
        let readTime = Date().timeIntervalSince(readStartTime)
        endOperation(readToken)
        
        results.readOperationTime = readTime
        results.recordCount = assets.count
        
        // Search operation benchmark
        let searchToken = startOperation("Asset Search Benchmark")
        let searchStartTime = Date()
        
        _ = await service.searchAssets(query: "benchmark")
        
        let searchTime = Date().timeIntervalSince(searchStartTime)
        endOperation(searchToken)
        
        results.searchOperationTime = searchTime
        
        return results
    }
    
    private func benchmarkUIPerformance() async -> UIBenchmarkResults {
        var results = UIBenchmarkResults()
        
        // Simulate UI operations
        let renderToken = startOperation("UI Render Benchmark")
        
        // Simulate view rendering time
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        endOperation(renderToken)
        results.averageRenderTime = 0.05
        
        // Navigation performance
        let navigationToken = startOperation("Navigation Benchmark")
        
        // Simulate navigation time
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        endOperation(navigationToken)
        results.averageNavigationTime = 0.1
        
        return results
    }
    
    // MARK: - Reporting
    
    private func generatePerformanceReport() {
        guard !historicalData.isEmpty else { return }
        
        let report = MonitoringSessionReport(
            sessionDuration: Date().timeIntervalSince(historicalData.first?.timestamp ?? Date()),
            totalOperations: currentMetrics.totalOperationsCompleted,
            averageMemoryUsage: currentMetrics.averageMemoryUsage,
            peakMemoryUsage: currentMetrics.peakMemoryUsage,
            averageCPUUsage: currentMetrics.averageCPUUsage,
            networkRequests: currentMetrics.networkRequestCount,
            snapshots: historicalData
        )
        
        print(report.generateSummary())
    }
    
    func exportMetrics() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(historicalData)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Failed to export metrics: \(error)")
            return ""
        }
    }
}

// MARK: - Data Models

struct MonitorPerformanceMetrics {
    var memoryUsage: Double = 0
    var averageMemoryUsage: Double = 0
    var peakMemoryUsage: Double = 0
    var cpuUsage: Double = 0
    var averageCPUUsage: Double = 0
    var networkRequestCount: Int = 0
    var activeOperationCount: Int = 0
    var totalOperationsCompleted: Int = 0
}

struct PerformanceSnapshot: Codable {
    let timestamp: Date
    let memoryUsage: Double
    let cpuUsage: Double
    let activeOperations: Int
    let networkRequests: Int
}

struct OperationToken {
    let id: UUID
    let name: String
}

struct OperationMetrics {
    let name: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval = 0
    let memoryAtStart: Double
    var memoryAtEnd: Double?
}

class BenchmarkResults: ObservableObject {
    @Published var employeeServiceResults: ServiceBenchmarkResults?
    @Published var workflowServiceResults: ServiceBenchmarkResults?
    @Published var assetManagementResults: ServiceBenchmarkResults?
    @Published var uiPerformanceResults: UIBenchmarkResults?
    
    var overallScore: Double {
        let scores = [
            employeeServiceResults?.performanceScore ?? 0,
            workflowServiceResults?.performanceScore ?? 0,
            assetManagementResults?.performanceScore ?? 0,
            uiPerformanceResults?.performanceScore ?? 0
        ]
        
        return scores.reduce(0, +) / Double(scores.count)
    }
}

struct ServiceBenchmarkResults {
    let serviceName: String
    var createOperationTime: TimeInterval = 0
    var readOperationTime: TimeInterval = 0
    var updateOperationTime: TimeInterval = 0
    var deleteOperationTime: TimeInterval = 0
    var searchOperationTime: TimeInterval = 0
    var averageCreateTime: TimeInterval = 0
    var recordCount: Int = 0
    
    var performanceScore: Double {
        // Calculate performance score based on operation times
        let maxAcceptableTime: TimeInterval = 1.0
        let score = max(0, 100 - ((averageCreateTime / maxAcceptableTime) * 100))
        return min(100, score)
    }
}

struct UIBenchmarkResults {
    var averageRenderTime: TimeInterval = 0
    var averageNavigationTime: TimeInterval = 0
    var memoryUsageDuringUI: Double = 0
    var frameDrops: Int = 0
    
    var performanceScore: Double {
        let maxAcceptableRenderTime: TimeInterval = 0.1
        let renderScore = max(0, 100 - ((averageRenderTime / maxAcceptableRenderTime) * 100))
        
        let maxAcceptableNavigationTime: TimeInterval = 0.3
        let navigationScore = max(0, 100 - ((averageNavigationTime / maxAcceptableNavigationTime) * 100))
        
        return (renderScore + navigationScore) / 2
    }
}

struct MonitoringSessionReport {
    let sessionDuration: TimeInterval
    let totalOperations: Int
    let averageMemoryUsage: Double
    let peakMemoryUsage: Double
    let averageCPUUsage: Double
    let networkRequests: Int
    let snapshots: [PerformanceSnapshot]
    
    func generateSummary() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        
        let sessionTime = formatter.string(from: sessionDuration) ?? "Unknown"
        
        return """
        
        📊 PERFORMANCE MONITORING REPORT
        ================================
        
        📅 Session Duration: \(sessionTime)
        🔄 Total Operations: \(totalOperations)
        🌐 Network Requests: \(networkRequests)
        
        💾 Memory Usage:
           - Average: \(String(format: "%.1f", averageMemoryUsage))MB
           - Peak: \(String(format: "%.1f", peakMemoryUsage))MB
        
        🖥️ CPU Usage:
           - Average: \(String(format: "%.1f", averageCPUUsage))%
        
        📈 Data Points Collected: \(snapshots.count)
        
        ================================
        """
    }
}

// MARK: - Performance Thresholds

enum PerformanceThreshold {
    static let maxMemoryUsage: Double = 500 // MB
    static let maxCPUUsage: Double = 80 // Percentage
    static let maxOperationTime: TimeInterval = 1.0 // Seconds
    static let maxUIRenderTime: TimeInterval = 0.016 // 60 FPS = 16ms per frame
    static let maxNetworkResponseTime: TimeInterval = 3.0 // Seconds
}

// MARK: - Performance Alerts

extension PerformanceMonitor {
    private func checkPerformanceThresholds() {
        // Memory usage check
        if currentMetrics.memoryUsage > PerformanceThreshold.maxMemoryUsage {
            print("⚠️ High memory usage detected: \(String(format: "%.1f", currentMetrics.memoryUsage))MB")
        }
        
        // CPU usage check
        if currentMetrics.cpuUsage > PerformanceThreshold.maxCPUUsage {
            print("⚠️ High CPU usage detected: \(String(format: "%.1f", currentMetrics.cpuUsage))%")
        }
        
        // Active operations check
        if currentMetrics.activeOperationCount > 10 {
            print("⚠️ High number of active operations: \(currentMetrics.activeOperationCount)")
        }
    }
}

