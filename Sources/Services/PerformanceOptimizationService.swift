import Foundation
import CloudKit
import Combine
import os.log

@MainActor
class PerformanceOptimizationService: ObservableObject {
    @Published var isOptimizing = false
    @Published var cacheHitRate: Double = 0.0
    @Published var averageResponseTime: TimeInterval = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var networkEfficiency: Double = 0.0
    
    private let database: CKDatabase
    private let logger = Logger(subsystem: "DiamondDeskERP", category: "Performance")
    private var performanceMetrics: [PerformanceMetric] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Cache management
    private var dataCache: NSCache<NSString, AnyObject>
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    // Network optimization
    private var pendingRequests: Set<String> = []
    private var requestQueue: OperationQueue
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
        self.dataCache = NSCache<NSString, AnyObject>()
        self.requestQueue = OperationQueue()
        
        configureCache()
        configureRequestQueue()
        startPerformanceMonitoring()
    }
    
    // MARK: - Cache Management
    
    private func configureCache() {
        dataCache.countLimit = 100 // Maximum 100 cached objects
        dataCache.totalCostLimit = 50 * 1024 * 1024 // 50MB cache limit
        
        // Clear cache on memory warning
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearCache()
            }
            .store(in: &cancellables)
    }
    
    private func configureRequestQueue() {
        requestQueue.maxConcurrentOperationCount = 3 // Limit concurrent requests
        requestQueue.qualityOfService = .userInitiated
    }
    
    func cacheData<T: NSCoding>(_ data: T, forKey key: String, cost: Int = 0) {
        let cacheKey = NSString(string: key)
        dataCache.setObject(data, forKey: cacheKey, cost: cost)
        logger.info("Cached data for key: \(key)")
    }
    
    func getCachedData<T>(forKey key: String, type: T.Type) -> T? {
        let cacheKey = NSString(string: key)
        
        if let cachedData = dataCache.object(forKey: cacheKey) as? T {
            cacheHits += 1
            updateCacheHitRate()
            logger.debug("Cache hit for key: \(key)")
            return cachedData
        } else {
            cacheMisses += 1
            updateCacheHitRate()
            logger.debug("Cache miss for key: \(key)")
            return nil
        }
    }
    
    private func updateCacheHitRate() {
        let totalRequests = cacheHits + cacheMisses
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    func clearCache() {
        dataCache.removeAllObjects()
        logger.info("Cache cleared")
    }
    
    // MARK: - Network Optimization
    
    func optimizedCloudKitRequest<T>(
        operation: @escaping () async throws -> T,
        cacheKey: String? = nil,
        cacheDuration: TimeInterval = 300 // 5 minutes default
    ) async throws -> T {
        let requestId = UUID().uuidString
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check cache first
        if let cacheKey = cacheKey,
           let cachedResult = getCachedData(forKey: cacheKey, type: T.self) {
            recordRequestTime(CFAbsoluteTimeGetCurrent() - startTime)
            return cachedResult
        }
        
        // Check for duplicate pending requests
        if let cacheKey = cacheKey, pendingRequests.contains(cacheKey) {
            // Wait a bit and try cache again
            try await Task.sleep(for: .milliseconds(100))
            if let cachedResult = getCachedData(forKey: cacheKey, type: T.self) {
                return cachedResult
            }
        }
        
        // Add to pending requests
        if let cacheKey = cacheKey {
            pendingRequests.insert(cacheKey)
        }
        
        defer {
            if let cacheKey = cacheKey {
                pendingRequests.remove(cacheKey)
            }
        }
        
        do {
            let result = try await operation()
            let requestTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Cache the result if caching is enabled
            if let cacheKey = cacheKey, let codableResult = result as? NSCoding {
                cacheData(codableResult, forKey: cacheKey)
                
                // Schedule cache invalidation
                Task {
                    try await Task.sleep(for: .seconds(cacheDuration))
                    dataCache.removeObject(forKey: NSString(string: cacheKey))
                }
            }
            
            recordRequestTime(requestTime)
            return result
            
        } catch {
            let requestTime = CFAbsoluteTimeGetCurrent() - startTime
            recordRequestTime(requestTime)
            throw error
        }
    }
    
    private func recordRequestTime(_ time: TimeInterval) {
        let metric = PerformanceMetric(
            type: .networkRequest,
            value: time,
            timestamp: Date()
        )
        performanceMetrics.append(metric)
        
        // Keep only last 100 metrics
        if performanceMetrics.count > 100 {
            performanceMetrics.removeFirst(performanceMetrics.count - 100)
        }
        
        updateAverageResponseTime()
    }
    
    private func updateAverageResponseTime() {
        let networkMetrics = performanceMetrics.filter { $0.type == .networkRequest }
        guard !networkMetrics.isEmpty else { return }
        
        let totalTime = networkMetrics.reduce(0) { $0 + $1.value }
        averageResponseTime = totalTime / Double(networkMetrics.count)
    }
    
    // MARK: - Memory Management
    
    private func startPerformanceMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
                self?.updateNetworkEfficiency()
                self?.cleanupExpiredMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func updateMemoryUsage() {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / (1024 * 1024)
            memoryUsage = usedMemoryMB
            
            logger.debug("Memory usage: \(usedMemoryMB) MB")
            
            // Log warning if memory usage is high
            if usedMemoryMB > 100 {
                logger.warning("High memory usage detected: \(usedMemoryMB) MB")
            }
        }
    }
    
    private func updateNetworkEfficiency() {
        let recentMetrics = performanceMetrics.filter {
            Date().timeIntervalSince($0.timestamp) < 300 // Last 5 minutes
        }
        
        guard !recentMetrics.isEmpty else { return }
        
        let fastRequests = recentMetrics.filter { $0.value < 1.0 } // Less than 1 second
        networkEfficiency = Double(fastRequests.count) / Double(recentMetrics.count)
    }
    
    private func cleanupExpiredMetrics() {
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago
        performanceMetrics.removeAll { $0.timestamp < cutoffTime }
    }
    
    // MARK: - Batch Operations
    
    func optimizedBatchOperation<T>(
        operations: [@Sendable () async throws -> T],
        batchSize: Int = 3
    ) async throws -> [T] {
        var results: [T] = []
        
        for chunk in operations.chunked(into: batchSize) {
            let chunkResults = try await withThrowingTaskGroup(of: T.self) { group in
                for operation in chunk {
                    group.addTask {
                        try await operation()
                    }
                }
                
                var chunkResults: [T] = []
                for try await result in group {
                    chunkResults.append(result)
                }
                return chunkResults
            }
            
            results.append(contentsOf: chunkResults)
            
            // Small delay between batches to prevent overwhelming the server
            if chunk.count == batchSize {
                try await Task.sleep(for: .milliseconds(50))
            }
        }
        
        return results
    }
    
    // MARK: - Performance Analysis
    
    func generatePerformanceReport() -> PerformanceReport {
        let report = PerformanceReport(
            cacheHitRate: cacheHitRate,
            averageResponseTime: averageResponseTime,
            memoryUsage: memoryUsage,
            networkEfficiency: networkEfficiency,
            totalMetrics: performanceMetrics.count,
            recommendedOptimizations: generateOptimizationRecommendations()
        )
        
        logger.info("Performance report generated: \(report)")
        return report
    }
    
    private func generateOptimizationRecommendations() -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        if cacheHitRate < 0.7 {
            recommendations.append(.improveCaching)
        }
        
        if averageResponseTime > 2.0 {
            recommendations.append(.optimizeNetworkRequests)
        }
        
        if memoryUsage > 150 {
            recommendations.append(.reduceMemoryUsage)
        }
        
        if networkEfficiency < 0.8 {
            recommendations.append(.optimizeNetworkBatching)
        }
        
        return recommendations
    }
    
    // MARK: - Optimization Actions
    
    func performOptimization() async {
        isOptimizing = true
        
        do {
            // Clear old cache entries
            await clearExpiredCacheEntries()
            
            // Optimize request queue
            await optimizeRequestQueue()
            
            // Cleanup performance metrics
            cleanupExpiredMetrics()
            
            logger.info("Performance optimization completed")
            
        } catch {
            logger.error("Performance optimization failed: \(error)")
        }
        
        isOptimizing = false
    }
    
    private func clearExpiredCacheEntries() async {
        // Implementation would check cache timestamps and remove expired entries
        logger.debug("Clearing expired cache entries")
    }
    
    private func optimizeRequestQueue() async {
        // Adjust queue settings based on current performance
        if networkEfficiency < 0.7 {
            requestQueue.maxConcurrentOperationCount = max(1, requestQueue.maxConcurrentOperationCount - 1)
        } else if networkEfficiency > 0.9 {
            requestQueue.maxConcurrentOperationCount = min(5, requestQueue.maxConcurrentOperationCount + 1)
        }
        
        logger.debug("Request queue optimized: maxConcurrent = \(requestQueue.maxConcurrentOperationCount)")
    }
}

// MARK: - Supporting Types

struct PerformanceMetric {
    let type: MetricType
    let value: Double
    let timestamp: Date
}

enum MetricType {
    case networkRequest
    case cacheOperation
    case memoryUsage
    case renderTime
}

struct PerformanceReport {
    let cacheHitRate: Double
    let averageResponseTime: TimeInterval
    let memoryUsage: Double
    let networkEfficiency: Double
    let totalMetrics: Int
    let recommendedOptimizations: [OptimizationRecommendation]
}

enum OptimizationRecommendation: String, CaseIterable {
    case improveCaching = "Improve data caching strategy"
    case optimizeNetworkRequests = "Optimize network request patterns"
    case reduceMemoryUsage = "Reduce memory footprint"
    case optimizeNetworkBatching = "Implement better request batching"
    
    var description: String {
        return rawValue
    }
}

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
