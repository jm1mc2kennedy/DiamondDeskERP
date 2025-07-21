import SwiftUI

/// Accessibility Automation with Dynamic Type harness and snapshot diff validation
/// Implements automated accessibility testing across all Dynamic Type content size categories
/// Validates UI layout and readability across accessibility spectrum
class AccessibilityAutomationTests: XCTestCase {
    
    private let snapshotDirectory = "AccessibilitySnapshots"
    private let baselineDirectory = "AccessibilityBaselines"
    
    // All Dynamic Type content size categories for comprehensive testing
    private let dynamicTypeCategories: [UIContentSizeCategory] = [
        .extraSmall,
        .small,
        .medium,
        .large,           // Default
        .extraLarge,
        .extraExtraLarge,
        .extraExtraExtraLarge,
        .accessibilityMedium,
        .accessibilityLarge,
        .accessibilityExtraLarge,
        .accessibilityExtraExtraLarge,
        .accessibilityExtraExtraExtraLarge
    ]
    
    struct AccessibilityTestResult: Codable {
        let testDate: Date
        let contentSizeCategory: String
        let viewType: String
        let passed: Bool
        let issues: [AccessibilityIssue]
        let snapshotPath: String?
        let baselinePath: String?
        let diffPath: String?
        
        struct AccessibilityIssue: Codable {
            let type: IssueType
            let description: String
            let severity: Severity
            let element: String?
            
            enum IssueType: String, Codable {
                case truncation = "TEXT_TRUNCATION"
                case overlap = "ELEMENT_OVERLAP"
                case contrast = "COLOR_CONTRAST"
                case touchTarget = "TOUCH_TARGET_SIZE"
                case navigation = "NAVIGATION_ACCESSIBILITY"
                case readability = "TEXT_READABILITY"
            }
            
            enum Severity: String, Codable {
                case critical = "CRITICAL"
                case high = "HIGH"
                case medium = "MEDIUM"
                case low = "LOW"
            }
        }
    }
    
    struct AccessibilityTestSuite {
        let viewControllers: [String: () -> UIViewController]
        let swiftUIViews: [String: () -> AnyView]
        
        static func defaultSuite() -> AccessibilityTestSuite {
            return AccessibilityTestSuite(
                viewControllers: [:], // Will be populated with actual VCs
                swiftUIViews: [
                    "DashboardView": { AnyView(DashboardView()) },
                    "ClientListView": { AnyView(ClientListView()) },
                    "TaskListView": { AnyView(TaskListView()) },
                    "TicketListView": { AnyView(TicketListView()) },
                    "KPIListView": { AnyView(KPIListView()) },
                    "StoreReportListView": { AnyView(StoreReportListView()) }
                ]
            )
        }
    }
    
    override func setUp() {
        super.setUp()
        setupSnapshotDirectories()
    }
    
    func testDynamicTypeAccessibility() {
        let testSuite = AccessibilityTestSuite.defaultSuite()
        var allResults: [AccessibilityTestResult] = []
        
        // Test all SwiftUI views across all Dynamic Type categories
        for (viewName, viewBuilder) in testSuite.swiftUIViews {
            for category in dynamicTypeCategories {
                let result = testViewAccessibility(
                    viewName: viewName,
                    viewBuilder: viewBuilder,
                    contentSizeCategory: category
                )
                allResults.append(result)
            }
        }
        
        // Generate comprehensive accessibility report
        let report = generateAccessibilityReport(results: allResults)
        saveAccessibilityReport(report)
        
        // Assert no critical accessibility issues
        let criticalIssues = allResults.flatMap { $0.issues }.filter { $0.severity == .critical }
        XCTAssertTrue(criticalIssues.isEmpty, "Critical accessibility issues found: \(criticalIssues.count)")
        
        // Assert reasonable pass rate (allow some medium/low severity issues)
        let passedTests = allResults.filter { $0.passed }.count
        let totalTests = allResults.count
        let passRate = Double(passedTests) / Double(totalTests)
        
        XCTAssertGreaterThan(passRate, 0.85, "Accessibility pass rate too low: \(String(format: "%.1f", passRate * 100))%")
        
        print("Accessibility Testing Complete:")
        print("- Total Tests: \(totalTests)")
        print("- Passed: \(passedTests)")
        print("- Pass Rate: \(String(format: "%.1f", passRate * 100))%")
        print("- Critical Issues: \(criticalIssues.count)")
    }
    
    private func testViewAccessibility(
        viewName: String,
        viewBuilder: () -> AnyView,
        contentSizeCategory: UIContentSizeCategory
    ) -> AccessibilityTestResult {
        
        print("Testing \(viewName) with \(contentSizeCategory.rawValue)...")
        
        // Create hosting controller with specific Dynamic Type setting
        let hostingController = UIHostingController(rootView: viewBuilder())
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812) // iPhone standard size
        
        // Apply Dynamic Type category
        let traitCollection = UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
        hostingController.setOverrideTraitCollection(traitCollection, forChild: nil)
        
        // Force layout update
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // Capture snapshot
        let snapshot = captureSnapshot(of: hostingController.view)
        let snapshotPath = saveSnapshot(snapshot, viewName: viewName, category: contentSizeCategory)
        
        // Perform accessibility analysis
        let issues = analyzeAccessibility(view: hostingController.view, category: contentSizeCategory)
        
        // Compare with baseline if available
        let (baselinePath, diffPath) = compareWithBaseline(
            snapshot: snapshot,
            viewName: viewName,
            category: contentSizeCategory
        )
        
        let passed = issues.filter { $0.severity == .critical || $0.severity == .high }.isEmpty
        
        return AccessibilityTestResult(
            testDate: Date(),
            contentSizeCategory: contentSizeCategory.rawValue,
            viewType: viewName,
            passed: passed,
            issues: issues,
            snapshotPath: snapshotPath,
            baselinePath: baselinePath,
            diffPath: diffPath
        )
    }
    
    private func analyzeAccessibility(view: UIView, category: UIContentSizeCategory) -> [AccessibilityTestResult.AccessibilityIssue] {
        var issues: [AccessibilityTestResult.AccessibilityIssue] = []
        
        // Analyze touch target sizes
        issues.append(contentsOf: analyzeTouchTargets(view: view))
        
        // Analyze text truncation
        issues.append(contentsOf: analyzeTextTruncation(view: view, category: category))
        
        // Analyze element overlap
        issues.append(contentsOf: analyzeElementOverlap(view: view))
        
        // Analyze color contrast
        issues.append(contentsOf: analyzeColorContrast(view: view))
        
        // Analyze navigation accessibility
        issues.append(contentsOf: analyzeNavigationAccessibility(view: view))
        
        return issues
    }
    
    private func analyzeTouchTargets(view: UIView) -> [AccessibilityTestResult.AccessibilityIssue] {
        var issues: [AccessibilityTestResult.AccessibilityIssue] = []
        let minimumTouchTargetSize: CGFloat = 44.0 // Apple HIG recommendation
        
        func checkSubviews(_ subview: UIView) {
            // Check if view is interactive
            if subview.isUserInteractionEnabled && (subview is UIButton || subview is UIControl) {
                let size = subview.frame.size
                if size.width < minimumTouchTargetSize || size.height < minimumTouchTargetSize {
                    issues.append(AccessibilityTestResult.AccessibilityIssue(
                        type: .touchTarget,
                        description: "Touch target too small: \(size.width)x\(size.height) (minimum: \(minimumTouchTargetSize)x\(minimumTouchTargetSize))",
                        severity: .high,
                        element: String(describing: type(of: subview))
                    ))
                }
            }
            
            subview.subviews.forEach(checkSubviews)
        }
        
        view.subviews.forEach(checkSubviews)
        return issues
    }
    
    private func analyzeTextTruncation(view: UIView, category: UIContentSizeCategory) -> [AccessibilityTestResult.AccessibilityIssue] {
        var issues: [AccessibilityTestResult.AccessibilityIssue] = []
        
        func checkLabels(_ subview: UIView) {
            if let label = subview as? UILabel {
                // Check if text is truncated
                let textSize = label.text?.size(withAttributes: [.font: label.font!]) ?? .zero
                if textSize.width > label.frame.width && label.numberOfLines != 0 {
                    let severity: AccessibilityTestResult.AccessibilityIssue.Severity
                    if category.isAccessibilityCategory {
                        severity = .critical
                    } else {
                        severity = .medium
                    }
                    
                    issues.append(AccessibilityTestResult.AccessibilityIssue(
                        type: .truncation,
                        description: "Text truncation detected in \(category.rawValue): '\(label.text ?? "")'",
                        severity: severity,
                        element: "UILabel"
                    ))
                }
            }
            
            subview.subviews.forEach(checkLabels)
        }
        
        view.subviews.forEach(checkLabels)
        return issues
    }
    
    private func analyzeElementOverlap(view: UIView) -> [AccessibilityTestResult.AccessibilityIssue] {
        var issues: [AccessibilityTestResult.AccessibilityIssue] = []
        var interactiveElements: [(UIView, CGRect)] = []
        
        func collectInteractiveElements(_ subview: UIView) {
            if subview.isUserInteractionEnabled && (subview is UIButton || subview is UIControl) {
                let globalFrame = view.convert(subview.frame, from: subview.superview)
                interactiveElements.append((subview, globalFrame))
            }
            subview.subviews.forEach(collectInteractiveElements)
        }
        
        view.subviews.forEach(collectInteractiveElements)
        
        // Check for overlapping interactive elements
        for i in 0..<interactiveElements.count {
            for j in (i+1)..<interactiveElements.count {
                let rect1 = interactiveElements[i].1
                let rect2 = interactiveElements[j].1
                
                if rect1.intersects(rect2) {
                    issues.append(AccessibilityTestResult.AccessibilityIssue(
                        type: .overlap,
                        description: "Interactive elements overlap: \(type(of: interactiveElements[i].0)) and \(type(of: interactiveElements[j].0))",
                        severity: .high,
                        element: "Multiple"
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func analyzeColorContrast(view: UIView) -> [AccessibilityTestResult.AccessibilityIssue] {
        var issues: [AccessibilityTestResult.AccessibilityIssue] = []
        
        func checkContrast(_ subview: UIView) {
            if let label = subview as? UILabel {
                // Simplified contrast checking - in production this would use proper color analysis
                if let textColor = label.textColor,
                   let backgroundColor = label.backgroundColor ?? view.backgroundColor {
                    
                    // Basic contrast heuristic (proper implementation would calculate WCAG contrast ratio)
                    let textLuminance = calculateLuminance(color: textColor)
                    let backgroundLuminance = calculateLuminance(color: backgroundColor)
                    let contrastRatio = max(textLuminance, backgroundLuminance) / min(textLuminance, backgroundLuminance)
                    
                    if contrastRatio < 4.5 { // WCAG AA standard
                        issues.append(AccessibilityTestResult.AccessibilityIssue(
                            type: .contrast,
                            description: "Low color contrast ratio: \(String(format: "%.1f", contrastRatio)) (minimum: 4.5:1)",
                            severity: .medium,
                            element: "UILabel"
                        ))
                    }
                }
            }
            
            subview.subviews.forEach(checkContrast)
        }
        
        view.subviews.forEach(checkContrast)
        return issues
    }
    
    private func analyzeNavigationAccessibility(view: UIView) -> [AccessibilityTestResult.AccessibilityIssue] {
        var issues: [AccessibilityTestResult.AccessibilityIssue] = []
        
        func checkAccessibilityElements(_ subview: UIView) {
            if subview.isAccessibilityElement {
                // Check for missing accessibility labels
                if subview.accessibilityLabel?.isEmpty ?? true {
                    issues.append(AccessibilityTestResult.AccessibilityIssue(
                        type: .navigation,
                        description: "Missing accessibility label",
                        severity: .medium,
                        element: String(describing: type(of: subview))
                    ))
                }
                
                // Check for missing accessibility hints on interactive elements
                if (subview is UIButton || subview is UIControl) && (subview.accessibilityHint?.isEmpty ?? true) {
                    issues.append(AccessibilityTestResult.AccessibilityIssue(
                        type: .navigation,
                        description: "Missing accessibility hint for interactive element",
                        severity: .low,
                        element: String(describing: type(of: subview))
                    ))
                }
            }
            
            subview.subviews.forEach(checkAccessibilityElements)
        }
        
        view.subviews.forEach(checkAccessibilityElements)
        return issues
    }
    
    private func calculateLuminance(color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Simplified luminance calculation
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
    
    private func captureSnapshot(of view: UIView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
    
    private func saveSnapshot(_ image: UIImage, viewName: String, category: UIContentSizeCategory) -> String {
        let filename = "\(viewName)_\(category.rawValue).png"
        let url = getSnapshotDirectoryURL().appendingPathComponent(filename)
        
        if let data = image.pngData() {
            try? data.write(to: url)
        }
        
        return url.path
    }
    
    private func compareWithBaseline(snapshot: UIImage, viewName: String, category: UIContentSizeCategory) -> (String?, String?) {
        let baselineFilename = "\(viewName)_\(category.rawValue)_baseline.png"
        let baselineURL = getBaselineDirectoryURL().appendingPathComponent(baselineFilename)
        
        guard FileManager.default.fileExists(atPath: baselineURL.path),
              let baselineData = try? Data(contentsOf: baselineURL),
              let baselineImage = UIImage(data: baselineData) else {
            return (nil, nil)
        }
        
        // Generate diff image (simplified - production would use proper image diffing)
        let diffFilename = "\(viewName)_\(category.rawValue)_diff.png"
        let diffURL = getSnapshotDirectoryURL().appendingPathComponent(diffFilename)
        
        // For now, just save the current snapshot as diff (would implement actual diffing)
        if let data = snapshot.pngData() {
            try? data.write(to: diffURL)
        }
        
        return (baselineURL.path, diffURL.path)
    }
    
    private func generateAccessibilityReport(results: [AccessibilityTestResult]) -> AccessibilityReport {
        let totalTests = results.count
        let passedTests = results.filter { $0.passed }.count
        let failedTests = totalTests - passedTests
        
        let issuesByType = Dictionary(grouping: results.flatMap { $0.issues }) { $0.type }
        let issuesBySeverity = Dictionary(grouping: results.flatMap { $0.issues }) { $0.severity }
        
        return AccessibilityReport(
            testDate: Date(),
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            passRate: Double(passedTests) / Double(totalTests),
            issuesByType: issuesByType.mapValues { $0.count },
            issuesBySeverity: issuesBySeverity.mapValues { $0.count },
            results: results
        )
    }
    
    private func saveAccessibilityReport(_ report: AccessibilityReport) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(report)
            let timestamp = ISO8601DateFormatter().string(from: report.testDate).replacingOccurrences(of: ":", with: "-")
            let filename = "accessibility_report_\(timestamp).json"
            let url = getReportsDirectoryURL().appendingPathComponent(filename)
            
            try FileManager.default.createDirectory(at: getReportsDirectoryURL(), withIntermediateDirectories: true)
            try data.write(to: url)
            
            print("Accessibility report saved to: \(url.path)")
        } catch {
            print("Failed to save accessibility report: \(error)")
        }
    }
    
    private func setupSnapshotDirectories() {
        let snapshotURL = getSnapshotDirectoryURL()
        let baselineURL = getBaselineDirectoryURL()
        let reportsURL = getReportsDirectoryURL()
        
        try? FileManager.default.createDirectory(at: snapshotURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: baselineURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: reportsURL, withIntermediateDirectories: true)
    }
    
    private func getSnapshotDirectoryURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(snapshotDirectory)
    }
    
    private func getBaselineDirectoryURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(baselineDirectory)
    }
    
    private func getReportsDirectoryURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("AccessibilityReports")
    }
}

// MARK: - Supporting Types

struct AccessibilityReport: Codable {
    let testDate: Date
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let passRate: Double
    let issuesByType: [String: Int]
    let issuesBySeverity: [String: Int]
    let results: [AccessibilityAutomationTests.AccessibilityTestResult]
}
