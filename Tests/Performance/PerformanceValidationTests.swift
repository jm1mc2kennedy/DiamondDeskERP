import XCTest
import Combine
@testable import DiamondDeskERP

final class PerformanceValidationTests: XCTestCase {
    var workflowService: WorkflowService!
    var assetManagementService: AssetManagementService!
    var employeeService: EmployeeService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        workflowService = WorkflowService()
        assetManagementService = AssetManagementService()
        employeeService = EmployeeService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        workflowService = nil
        assetManagementService = nil
        employeeService = nil
        cancellables?.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Workflow Service Performance Tests
    
    func testWorkflowServiceCRUDPerformance() {
        let expectation = XCTestExpectation(description: "Workflow CRUD operations")
        let startTime = CFAbsoluteTimeGetCurrent()
        let operationCount = 100
        var completedOperations = 0
        
        let testWorkflow = Workflow(
            title: "Performance Test Workflow",
            description: "Test workflow for performance validation",
            priority: .medium,
            assignedTo: UUID(),
            dueDate: Date().addingTimeInterval(86400),
            category: .approval,
            steps: []
        )
        
        // Test Create Operations
        for i in 0..<operationCount {
            var workflow = testWorkflow
            workflow.title = "Performance Test Workflow \(i)"
            
            Task {
                await workflowService.createWorkflow(workflow)
                
                DispatchQueue.main.async {
                    completedOperations += 1
                    if completedOperations == operationCount {
                        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                        let avgTimePerOperation = timeElapsed / Double(operationCount)
                        
                        XCTAssertLessThan(avgTimePerOperation, 0.1, "Average workflow creation time should be under 100ms")
                        XCTAssertLessThan(timeElapsed, 10.0, "Total time for \(operationCount) operations should be under 10 seconds")
                        
                        print("🚀 Workflow Performance Results:")
                        print("   - Total time: \(String(format: "%.3f", timeElapsed))s")
                        print("   - Average per operation: \(String(format: "%.3f", avgTimePerOperation * 1000))ms")
                        print("   - Operations per second: \(String(format: "%.1f", Double(operationCount) / timeElapsed))")
                        
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testWorkflowServiceMemoryUsage() {
        let expectation = XCTestExpectation(description: "Workflow memory usage")
        
        measure(metrics: [XCTMemoryMetric()]) {
            let group = DispatchGroup()
            
            for i in 0..<50 {
                group.enter()
                
                let workflow = Workflow(
                    title: "Memory Test Workflow \(i)",
                    description: "Testing memory usage patterns",
                    priority: .medium,
                    assignedTo: UUID(),
                    dueDate: Date().addingTimeInterval(86400),
                    category: .approval,
                    steps: []
                )
                
                Task {
                    await workflowService.createWorkflow(workflow)
                    let workflows = await workflowService.getAllWorkflows()
                    XCTAssertNotNil(workflows)
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        expectation.fulfill()
    }
    
    func testWorkflowServiceConcurrentOperations() {
        let expectation = XCTestExpectation(description: "Concurrent workflow operations")
        let startTime = CFAbsoluteTimeGetCurrent()
        let concurrentOperations = 20
        var completedOperations = 0
        
        for i in 0..<concurrentOperations {
            Task {
                let workflow = Workflow(
                    title: "Concurrent Test Workflow \(i)",
                    description: "Testing concurrent operations",
                    priority: .medium,
                    assignedTo: UUID(),
                    dueDate: Date().addingTimeInterval(86400),
                    category: .approval,
                    steps: []
                )
                
                await workflowService.createWorkflow(workflow)
                let workflows = await workflowService.getAllWorkflows()
                await workflowService.updateWorkflow(workflow)
                
                DispatchQueue.main.async {
                    completedOperations += 1
                    if completedOperations == concurrentOperations {
                        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                        
                        XCTAssertLessThan(timeElapsed, 5.0, "Concurrent operations should complete within 5 seconds")
                        
                        print("🔄 Workflow Concurrency Results:")
                        print("   - \(concurrentOperations) concurrent operations completed in \(String(format: "%.3f", timeElapsed))s")
                        
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Asset Management Service Performance Tests
    
    func testAssetManagementServicePerformance() {
        let expectation = XCTestExpectation(description: "Asset management performance")
        let startTime = CFAbsoluteTimeGetCurrent()
        let operationCount = 50
        var completedOperations = 0
        
        for i in 0..<operationCount {
            Task {
                let asset = Asset(
                    name: "Performance Test Asset \(i)",
                    type: .document,
                    size: Int64.random(in: 1024...1048576), // 1KB to 1MB
                    mimeType: "application/pdf",
                    tags: ["performance", "test"],
                    uploadedBy: UUID(),
                    projectId: UUID()
                )
                
                await assetManagementService.uploadAsset(asset, data: Data(count: 1024))
                let assets = await assetManagementService.getAssets()
                
                DispatchQueue.main.async {
                    completedOperations += 1
                    if completedOperations == operationCount {
                        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                        let avgTimePerOperation = timeElapsed / Double(operationCount)
                        
                        XCTAssertLessThan(avgTimePerOperation, 0.2, "Average asset operation time should be under 200ms")
                        
                        print("📁 Asset Management Performance Results:")
                        print("   - Total time: \(String(format: "%.3f", timeElapsed))s")
                        print("   - Average per operation: \(String(format: "%.3f", avgTimePerOperation * 1000))ms")
                        
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testAssetUploadPerformance() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Asset upload performance")
            
            let largeData = Data(count: 5 * 1024 * 1024) // 5MB
            let asset = Asset(
                name: "Large Performance Test Asset",
                type: .image,
                size: Int64(largeData.count),
                mimeType: "image/jpeg",
                tags: ["performance", "large"],
                uploadedBy: UUID(),
                projectId: UUID()
            )
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                await assetManagementService.uploadAsset(asset, data: largeData)
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                XCTAssertLessThan(timeElapsed, 3.0, "Large asset upload should complete within 3 seconds")
                
                print("📤 Asset Upload Performance:")
                print("   - 5MB upload time: \(String(format: "%.3f", timeElapsed))s")
                print("   - Upload speed: \(String(format: "%.1f", Double(largeData.count) / timeElapsed / 1024 / 1024))MB/s")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testAssetSearchPerformance() {
        let expectation = XCTestExpectation(description: "Asset search performance")
        
        // First, create test assets
        Task {
            let setupStart = CFAbsoluteTimeGetCurrent()
            
            for i in 0..<100 {
                let asset = Asset(
                    name: "Search Test Asset \(i)",
                    type: i % 2 == 0 ? .document : .image,
                    size: Int64.random(in: 1024...10240),
                    mimeType: i % 2 == 0 ? "application/pdf" : "image/jpeg",
                    tags: ["search", "test", "asset\(i % 10)"],
                    uploadedBy: UUID(),
                    projectId: UUID()
                )
                
                await assetManagementService.uploadAsset(asset, data: Data(count: 1024))
            }
            
            let setupTime = CFAbsoluteTimeGetCurrent() - setupStart
            print("🔧 Asset search setup time: \(String(format: "%.3f", setupTime))s")
            
            // Now test search performance
            let searchStart = CFAbsoluteTimeGetCurrent()
            
            let searchResults = await assetManagementService.searchAssets(query: "test")
            
            let searchTime = CFAbsoluteTimeGetCurrent() - searchStart
            
            XCTAssertLessThan(searchTime, 0.5, "Search should complete within 500ms")
            XCTAssertGreaterThan(searchResults.count, 0, "Search should return results")
            
            print("🔍 Asset Search Performance:")
            print("   - Search time: \(String(format: "%.3f", searchTime * 1000))ms")
            print("   - Results found: \(searchResults.count)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Employee Service Performance Tests
    
    func testEmployeeServicePerformance() {
        let expectation = XCTestExpectation(description: "Employee service performance")
        let startTime = CFAbsoluteTimeGetCurrent()
        let operationCount = 100
        var completedOperations = 0
        
        for i in 0..<operationCount {
            Task {
                let employee = Employee(
                    employeeNumber: "PERF\(String(format: "%03d", i))",
                    firstName: "Performance",
                    lastName: "Test\(i)",
                    email: "perf.test\(i)@company.com",
                    department: "Testing",
                    title: "Performance Tester",
                    hireDate: Date(),
                    address: Address(
                        street: "123 Test St",
                        city: "Test City",
                        state: "TS",
                        zipCode: "12345"
                    ),
                    emergencyContact: EmergencyContact(
                        name: "Emergency Contact",
                        relationship: "Contact",
                        phone: "555-0123"
                    ),
                    workLocation: .office,
                    employmentType: .fullTime
                )
                
                await employeeService.createEmployee(employee)
                let employees = await employeeService.getAllEmployees()
                
                DispatchQueue.main.async {
                    completedOperations += 1
                    if completedOperations == operationCount {
                        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                        let avgTimePerOperation = timeElapsed / Double(operationCount)
                        
                        XCTAssertLessThan(avgTimePerOperation, 0.15, "Average employee operation time should be under 150ms")
                        
                        print("👥 Employee Service Performance Results:")
                        print("   - Total time: \(String(format: "%.3f", timeElapsed))s")
                        print("   - Average per operation: \(String(format: "%.3f", avgTimePerOperation * 1000))ms")
                        print("   - Operations per second: \(String(format: "%.1f", Double(operationCount) / timeElapsed))")
                        
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testEmployeeSearchPerformance() {
        let expectation = XCTestExpectation(description: "Employee search performance")
        
        // Setup test data
        Task {
            for i in 0..<200 {
                let employee = Employee(
                    employeeNumber: "SRCH\(String(format: "%03d", i))",
                    firstName: ["John", "Jane", "Alex", "Sarah", "Mike"][i % 5],
                    lastName: "TestEmployee\(i)",
                    email: "search.test\(i)@company.com",
                    department: ["Engineering", "Sales", "Marketing", "HR", "Finance"][i % 5],
                    title: "Test Employee",
                    hireDate: Date(),
                    address: Address(street: "123 Test St", city: "Test City", state: "TS", zipCode: "12345"),
                    emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Contact", phone: "555-0123"),
                    workLocation: .office,
                    employmentType: .fullTime
                )
                
                await employeeService.createEmployee(employee)
            }
            
            // Test search performance
            let searchTests = [
                ("John", "Search by first name"),
                ("Engineering", "Search by department"),
                ("TestEmployee", "Search by last name"),
                ("search.test", "Search by email"),
                ("SRCH", "Search by employee number")
            ]
            
            for (query, description) in searchTests {
                let searchStart = CFAbsoluteTimeGetCurrent()
                let results = await employeeService.searchEmployees(query: query)
                let searchTime = CFAbsoluteTimeGetCurrent() - searchStart
                
                XCTAssertLessThan(searchTime, 0.3, "\(description) should complete within 300ms")
                XCTAssertGreaterThan(results.count, 0, "\(description) should return results")
                
                print("🔍 Employee Search - \(description):")
                print("   - Query: '\(query)'")
                print("   - Time: \(String(format: "%.3f", searchTime * 1000))ms")
                print("   - Results: \(results.count)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func testEmployeeFilteringPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            let expectation = XCTestExpectation(description: "Employee filtering performance")
            
            Task {
                let employees = await employeeService.getAllEmployees()
                
                let filterStart = CFAbsoluteTimeGetCurrent()
                
                // Test various filtering operations
                let activeEmployees = employees.filter { $0.isActive }
                let engineeringEmployees = employees.filter { $0.department == "Engineering" }
                let recentHires = employees.filter { $0.hireDate > Date().addingTimeInterval(-365 * 24 * 60 * 60) }
                let remoteEmployees = employees.filter { $0.workLocation == .remote }
                
                let filterTime = CFAbsoluteTimeGetCurrent() - filterStart
                
                XCTAssertLessThan(filterTime, 0.1, "Employee filtering should complete within 100ms")
                
                print("🔧 Employee Filtering Performance:")
                print("   - Total employees: \(employees.count)")
                print("   - Filter time: \(String(format: "%.3f", filterTime * 1000))ms")
                print("   - Active: \(activeEmployees.count)")
                print("   - Engineering: \(engineeringEmployees.count)")
                print("   - Recent hires: \(recentHires.count)")
                print("   - Remote: \(remoteEmployees.count)")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Cross-Service Integration Performance Tests
    
    func testCrossServiceIntegrationPerformance() {
        let expectation = XCTestExpectation(description: "Cross-service integration performance")
        
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Create test employee
            let employee = Employee(
                employeeNumber: "INT001",
                firstName: "Integration",
                lastName: "Test",
                email: "integration.test@company.com",
                department: "Testing",
                title: "Integration Tester",
                hireDate: Date(),
                address: Address(street: "123 Int St", city: "Int City", state: "IN", zipCode: "12345"),
                emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Contact", phone: "555-0123"),
                workLocation: .office,
                employmentType: .fullTime
            )
            
            await employeeService.createEmployee(employee)
            
            // Create workflow assigned to employee
            let workflow = Workflow(
                title: "Integration Test Workflow",
                description: "Testing cross-service integration",
                priority: .high,
                assignedTo: employee.id,
                dueDate: Date().addingTimeInterval(86400),
                category: .approval,
                steps: []
            )
            
            await workflowService.createWorkflow(workflow)
            
            // Create asset for the workflow
            let asset = Asset(
                name: "Integration Test Asset",
                type: .document,
                size: 2048,
                mimeType: "application/pdf",
                tags: ["integration", "test"],
                uploadedBy: employee.id,
                projectId: workflow.id
            )
            
            await assetManagementService.uploadAsset(asset, data: Data(count: 2048))
            
            // Fetch all related data
            let allEmployees = await employeeService.getAllEmployees()
            let allWorkflows = await workflowService.getAllWorkflows()
            let allAssets = await assetManagementService.getAssets()
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            
            XCTAssertLessThan(totalTime, 2.0, "Cross-service integration should complete within 2 seconds")
            XCTAssertGreaterThan(allEmployees.count, 0, "Should have employees")
            XCTAssertGreaterThan(allWorkflows.count, 0, "Should have workflows")
            XCTAssertGreaterThan(allAssets.count, 0, "Should have assets")
            
            print("🔗 Cross-Service Integration Performance:")
            print("   - Total time: \(String(format: "%.3f", totalTime))s")
            print("   - Employees: \(allEmployees.count)")
            print("   - Workflows: \(allWorkflows.count)")
            print("   - Assets: \(allAssets.count)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Memory and Resource Tests
    
    func testMemoryUsageUnderLoad() {
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Memory usage under load")
            
            Task {
                // Simulate heavy usage
                await withTaskGroup(of: Void.self) { group in
                    // Create multiple employees concurrently
                    for i in 0..<20 {
                        group.addTask {
                            let employee = Employee(
                                employeeNumber: "MEM\(String(format: "%03d", i))",
                                firstName: "Memory",
                                lastName: "Test\(i)",
                                email: "memory.test\(i)@company.com",
                                department: "Testing",
                                title: "Memory Tester",
                                hireDate: Date(),
                                address: Address(street: "123 Mem St", city: "Mem City", state: "ME", zipCode: "12345"),
                                emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Contact", phone: "555-0123"),
                                workLocation: .office,
                                employmentType: .fullTime
                            )
                            
                            await self.employeeService.createEmployee(employee)
                        }
                    }
                    
                    // Create workflows concurrently
                    for i in 0..<15 {
                        group.addTask {
                            let workflow = Workflow(
                                title: "Memory Test Workflow \(i)",
                                description: "Testing memory usage",
                                priority: .medium,
                                assignedTo: UUID(),
                                dueDate: Date().addingTimeInterval(86400),
                                category: .approval,
                                steps: []
                            )
                            
                            await self.workflowService.createWorkflow(workflow)
                        }
                    }
                    
                    // Create assets concurrently
                    for i in 0..<10 {
                        group.addTask {
                            let asset = Asset(
                                name: "Memory Test Asset \(i)",
                                type: .document,
                                size: 1024,
                                mimeType: "application/pdf",
                                tags: ["memory", "test"],
                                uploadedBy: UUID(),
                                projectId: UUID()
                            )
                            
                            await self.assetManagementService.uploadAsset(asset, data: Data(count: 1024))
                        }
                    }
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - Performance Benchmarking
    
    func testOverallSystemPerformance() {
        let expectation = XCTestExpectation(description: "Overall system performance benchmark")
        
        Task {
            let benchmarkStart = CFAbsoluteTimeGetCurrent()
            
            // Comprehensive performance test
            let results = await performComprehensiveBenchmark()
            
            let totalTime = CFAbsoluteTimeGetCurrent() - benchmarkStart
            
            XCTAssertLessThan(totalTime, 30.0, "Comprehensive benchmark should complete within 30 seconds")
            
            print("🏆 COMPREHENSIVE PERFORMANCE BENCHMARK RESULTS:")
            print("=" * 50)
            print("📊 Total benchmark time: \(String(format: "%.3f", totalTime))s")
            print("")
            
            for (service, metrics) in results {
                print("🔧 \(service):")
                for (operation, time) in metrics {
                    print("   - \(operation): \(String(format: "%.3f", time * 1000))ms")
                }
                print("")
            }
            
            // Performance assertions
            XCTAssertLessThan(results["Employee"]?["Create"] ?? 1.0, 0.2, "Employee creation should be under 200ms")
            XCTAssertLessThan(results["Workflow"]?["Create"] ?? 1.0, 0.15, "Workflow creation should be under 150ms")
            XCTAssertLessThan(results["Asset"]?["Upload"] ?? 1.0, 0.3, "Asset upload should be under 300ms")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 45.0)
    }
    
    private func performComprehensiveBenchmark() async -> [String: [String: Double]] {
        var results: [String: [String: Double]] = [:]
        
        // Employee Service Benchmark
        let employeeStart = CFAbsoluteTimeGetCurrent()
        let employee = Employee(
            employeeNumber: "BENCH001",
            firstName: "Benchmark",
            lastName: "Test",
            email: "benchmark.test@company.com",
            department: "Testing",
            title: "Benchmark Tester",
            hireDate: Date(),
            address: Address(street: "123 Bench St", city: "Bench City", state: "BE", zipCode: "12345"),
            emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Contact", phone: "555-0123"),
            workLocation: .office,
            employmentType: .fullTime
        )
        await employeeService.createEmployee(employee)
        let employeeCreateTime = CFAbsoluteTimeGetCurrent() - employeeStart
        
        let employeeSearchStart = CFAbsoluteTimeGetCurrent()
        _ = await employeeService.searchEmployees(query: "Benchmark")
        let employeeSearchTime = CFAbsoluteTimeGetCurrent() - employeeSearchStart
        
        results["Employee"] = [
            "Create": employeeCreateTime,
            "Search": employeeSearchTime
        ]
        
        // Workflow Service Benchmark
        let workflowStart = CFAbsoluteTimeGetCurrent()
        let workflow = Workflow(
            title: "Benchmark Test Workflow",
            description: "Testing workflow performance",
            priority: .high,
            assignedTo: employee.id,
            dueDate: Date().addingTimeInterval(86400),
            category: .approval,
            steps: []
        )
        await workflowService.createWorkflow(workflow)
        let workflowCreateTime = CFAbsoluteTimeGetCurrent() - workflowStart
        
        let workflowFetchStart = CFAbsoluteTimeGetCurrent()
        _ = await workflowService.getAllWorkflows()
        let workflowFetchTime = CFAbsoluteTimeGetCurrent() - workflowFetchStart
        
        results["Workflow"] = [
            "Create": workflowCreateTime,
            "Fetch All": workflowFetchTime
        ]
        
        // Asset Management Benchmark
        let assetStart = CFAbsoluteTimeGetCurrent()
        let asset = Asset(
            name: "Benchmark Test Asset",
            type: .document,
            size: 4096,
            mimeType: "application/pdf",
            tags: ["benchmark", "test"],
            uploadedBy: employee.id,
            projectId: workflow.id
        )
        await assetManagementService.uploadAsset(asset, data: Data(count: 4096))
        let assetUploadTime = CFAbsoluteTimeGetCurrent() - assetStart
        
        let assetSearchStart = CFAbsoluteTimeGetCurrent()
        _ = await assetManagementService.searchAssets(query: "benchmark")
        let assetSearchTime = CFAbsoluteTimeGetCurrent() - assetSearchStart
        
        results["Asset"] = [
            "Upload": assetUploadTime,
            "Search": assetSearchTime
        ]
        
        return results
    }
}

// MARK: - Performance Monitoring Helper

class PerformanceMonitor {
    static func measureTime<T>(operation: String, block: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("⏱️ \(operation): \(String(format: "%.3f", timeElapsed * 1000))ms")
        
        return (result, timeElapsed)
    }
    
    static func logMemoryUsage(context: String) {
        let task_info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &task_info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryUsage = task_info.resident_size / 1024 / 1024 // Convert to MB
            print("💾 Memory usage (\(context)): \(memoryUsage)MB")
        }
    }
}
