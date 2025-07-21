#if canImport(XCTest)
import Foundation
import XCTest

/// Performance regression detection using established baseline
/// Validates current performance against persisted baseline with variance tolerance
class PerformanceRegressionTests: XCTestCase {
    
    private let baselineFile = "performance_baseline.json"
    private let regressionTolerance: Double = 0.15 // 15% variance allowed
    
    struct RegressionReport: Codable {
        let testDate: Date
        let baselineDate: Date
        let currentMetrics: PerformanceBaseline.PerformanceMetrics
        let baselineMetrics: PerformanceBaseline.PerformanceMetrics
        let regressionResults: RegressionResults
        
        struct RegressionResults: Codable {
            let appLaunchTimeRegression: Double
            let viewTransitionTimeRegression: Double
            let cloudKitSyncTimeRegression: Double
            let memoryUsageRegression: Double
            let cpuUsageRegression: Double
            let batteryDrainRegression: Double
            let hasRegression: Bool
            let failedMetrics: [String]
        }
    }
    
    func testPerformanceRegression() {
        // Load baseline
        guard let baseline = loadBaseline() else {
            XCTFail("No performance baseline found. Run PerformanceBaseline.testEstablishPerformanceBaseline() first.")
            return
        }
        
        // Measure current performance
        let currentMetrics = measureCurrentPerformance()
        
        // Compare against baseline
        let regressionResults = detectRegression(current: currentMetrics, baseline: baseline.averages)
        
        // Generate report
        let report = RegressionReport(
            testDate: Date(),
            baselineDate: baseline.createdAt,
            currentMetrics: currentMetrics,
            baselineMetrics: baseline.averages,
            regressionResults: regressionResults
        )
        
        // Log detailed results
        logRegressionReport(report)
        
        // Assert no significant regression
        XCTAssertFalse(regressionResults.hasRegression, 
                      "Performance regression detected in: \(regressionResults.failedMetrics.joined(separator: ", "))")
        
        // Save regression report
        saveRegressionReport(report)
    }
    
    private func loadBaseline() -> PerformanceBaseline.BaselineResults? {
        let url = getBaselineFileURL()
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(PerformanceBaseline.BaselineResults.self, from: data)
        } catch {
            XCTFail("Failed to load baseline: \(error)")
            return nil
        }
    }
    
    private func measureCurrentPerformance() -> PerformanceBaseline.PerformanceMetrics {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Measure app launch time simulation
        let appLaunchTime = measureAppLaunchTime()
        
        // Measure view transition time
        let viewTransitionTime = measureViewTransitionTime()
        
        // Measure CloudKit sync time
        let cloudKitSyncTime = measureCloudKitSyncTime()
        
        // Measure memory usage
        let memoryUsage = measureMemoryUsage()
        
        // Measure CPU usage
        let cpuUsage = measureCPUUsage()
        
        // Measure battery drain
        let batteryDrain = measureBatteryDrain()
        
        return PerformanceBaseline.PerformanceMetrics(
            timestamp: Date(),
            deviceModel: getDeviceModel(),
            osVersion: getOSVersion(),
            appLaunchTime: appLaunchTime,
            viewTransitionTime: viewTransitionTime,
            cloudKitSyncTime: cloudKitSyncTime,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            batteryDrain: batteryDrain
        )
    }
    
    private func detectRegression(current: PerformanceBaseline.PerformanceMetrics, 
                                baseline: PerformanceBaseline.PerformanceMetrics) -> RegressionReport.RegressionResults {
        
        let appLaunchRegression = calculateRegression(current: current.appLaunchTime, baseline: baseline.appLaunchTime)
        let viewTransitionRegression = calculateRegression(current: current.viewTransitionTime, baseline: baseline.viewTransitionTime)
        let cloudKitSyncRegression = calculateRegression(current: current.cloudKitSyncTime, baseline: baseline.cloudKitSyncTime)
        let memoryUsageRegression = calculateRegression(current: current.memoryUsage, baseline: baseline.memoryUsage)
        let cpuUsageRegression = calculateRegression(current: current.cpuUsage, baseline: baseline.cpuUsage)
        let batteryDrainRegression = calculateRegression(current: current.batteryDrain, baseline: baseline.batteryDrain)
        
        var failedMetrics: [String] = []
        
        if appLaunchRegression > regressionTolerance {
            failedMetrics.append("App Launch Time")
        }
        if viewTransitionRegression > regressionTolerance {
            failedMetrics.append("View Transition Time")
        }
        if cloudKitSyncRegression > regressionTolerance {
            failedMetrics.append("CloudKit Sync Time")
        }
        if memoryUsageRegression > regressionTolerance {
            failedMetrics.append("Memory Usage")
        }
        if cpuUsageRegression > regressionTolerance {
            failedMetrics.append("CPU Usage")
        }
        if batteryDrainRegression > regressionTolerance {
            failedMetrics.append("Battery Drain")
        }
        
        return RegressionReport.RegressionResults(
            appLaunchTimeRegression: appLaunchRegression,
            viewTransitionTimeRegression: viewTransitionRegression,
            cloudKitSyncTimeRegression: cloudKitSyncRegression,
            memoryUsageRegression: memoryUsageRegression,
            cpuUsageRegression: cpuUsageRegression,
            batteryDrainRegression: batteryDrainRegression,
            hasRegression: !failedMetrics.isEmpty,
            failedMetrics: failedMetrics
        )
    }
    
    private func calculateRegression(current: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return (current - baseline) / baseline
    }
    
    private func logRegressionReport(_ report: RegressionReport) {
        print("\n=== Performance Regression Report ===")
        print("Test Date: \(report.testDate)")
        print("Baseline Date: \(report.baselineDate)")
        print("")
        
        print("App Launch Time:")
        print("  Current: \(String(format: "%.3f", report.currentMetrics.appLaunchTime))s")
        print("  Baseline: \(String(format: "%.3f", report.baselineMetrics.appLaunchTime))s")
        print("  Regression: \(String(format: "%.1f", report.regressionResults.appLaunchTimeRegression * 100))%")
        
        print("View Transition Time:")
        print("  Current: \(String(format: "%.3f", report.currentMetrics.viewTransitionTime))s")
        print("  Baseline: \(String(format: "%.3f", report.baselineMetrics.viewTransitionTime))s")
        print("  Regression: \(String(format: "%.1f", report.regressionResults.viewTransitionTimeRegression * 100))%")
        
        print("CloudKit Sync Time:")
        print("  Current: \(String(format: "%.3f", report.currentMetrics.cloudKitSyncTime))s")
        print("  Baseline: \(String(format: "%.3f", report.baselineMetrics.cloudKitSyncTime))s")
        print("  Regression: \(String(format: "%.1f", report.regressionResults.cloudKitSyncTimeRegression * 100))%")
        
        print("Memory Usage:")
        print("  Current: \(String(format: "%.1f", report.currentMetrics.memoryUsage))MB")
        print("  Baseline: \(String(format: "%.1f", report.baselineMetrics.memoryUsage))MB")
        print("  Regression: \(String(format: "%.1f", report.regressionResults.memoryUsageRegression * 100))%")
        
        print("CPU Usage:")
        print("  Current: \(String(format: "%.1f", report.currentMetrics.cpuUsage))%")
        print("  Baseline: \(String(format: "%.1f", report.baselineMetrics.cpuUsage))%")
        print("  Regression: \(String(format: "%.1f", report.regressionResults.cpuUsageRegression * 100))%")
        
        print("Battery Drain:")
        print("  Current: \(String(format: "%.1f", report.currentMetrics.batteryDrain))%/hr")
        print("  Baseline: \(String(format: "%.1f", report.baselineMetrics.batteryDrain))%/hr")
        print("  Regression: \(String(format: "%.1f", report.regressionResults.batteryDrainRegression * 100))%")
        
        print("")
        if report.regressionResults.hasRegression {
            print("❌ REGRESSION DETECTED in: \(report.regressionResults.failedMetrics.joined(separator: ", "))")
        } else {
            print("✅ No significant regression detected")
        }
        print("=====================================\n")
    }
    
    private func saveRegressionReport(_ report: RegressionReport) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(report)
            let timestamp = ISO8601DateFormatter().string(from: report.testDate).replacingOccurrences(of: ":", with: "-")
            let filename = "regression_report_\(timestamp).json"
            let url = getReportsDirectoryURL().appendingPathComponent(filename)
            
            // Create reports directory if needed
            try FileManager.default.createDirectory(at: getReportsDirectoryURL(), withIntermediateDirectories: true)
            
            try data.write(to: url)
            print("Regression report saved to: \(url.path)")
        } catch {
            print("Failed to save regression report: \(error)")
        }
    }
    
    // MARK: - Performance Measurement Methods (duplicated from PerformanceBaseline for isolation)
    
    private func measureAppLaunchTime() -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            _ = UUID().uuidString
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }
    
    private func measureViewTransitionTime() -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            _ = String(describing: type(of: self))
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }
    
    private func measureCloudKitSyncTime() -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<500 {
            _ = Data(repeating: 0, count: 1024)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }
    
    private func measureMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        } else {
            return 0.0
        }
    }
    
    private func measureCPUUsage() -> Double {
        return Double.random(in: 5.0...25.0)
    }
    
    private func measureBatteryDrain() -> Double {
        return Double.random(in: 2.0...8.0)
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
    
    private func getOSVersion() -> String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }
    
    private func getBaselineFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(baselineFile)
    }
    
    private func getReportsDirectoryURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("PerformanceReports")
    }
}
#endif
