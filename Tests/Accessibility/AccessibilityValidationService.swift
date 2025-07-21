#if canImport(XCTest)
import Foundation
import SwiftUI
import UIKit

/// Real-time accessibility validation service for production use
/// Provides on-device accessibility checking and user guidance
class AccessibilityValidationService: ObservableObject {
    
    @Published var isAccessibilityModeActive: Bool = false
    @Published var currentAccessibilityIssues: [AccessibilityIssue] = []
    @Published var accessibilityScore: Double = 1.0
    
    private let notificationCenter = NotificationCenter.default
    private var observers: [NSObjectProtocol] = []
    
    struct AccessibilityIssue: Identifiable, Codable {
        let id = UUID()
        let type: IssueType
        let description: String
        let severity: Severity
        let recommendation: String
        let detectedAt: Date
        
        enum IssueType: String, CaseIterable, Codable {
            case dynamicTypeSupport = "DYNAMIC_TYPE_SUPPORT"
            case colorContrast = "COLOR_CONTRAST"
            case touchTargetSize = "TOUCH_TARGET_SIZE"
            case voiceOverSupport = "VOICEOVER_SUPPORT"
            case reduceMotionSupport = "REDUCE_MOTION_SUPPORT"
            case textReadability = "TEXT_READABILITY"
        }
        
        enum Severity: String, CaseIterable, Codable {
            case critical = "CRITICAL"
            case high = "HIGH"
            case medium = "MEDIUM"
            case low = "LOW"
            
            var priority: Int {
                switch self {
                case .critical: return 4
                case .high: return 3
                case .medium: return 2
                case .low: return 1
                }
            }
        }
    }
    
    struct AccessibilitySettings: Codable {
        let preferredContentSizeCategory: String
        let isVoiceOverRunning: Bool
        let isReduceMotionEnabled: Bool
        let isBoldTextEnabled: Bool
        let isButtonShapesEnabled: Bool
        let isReduceTransparencyEnabled: Bool
        let isInvertColorsEnabled: Bool
        let isDarkerSystemColorsEnabled: Bool
        
        static var current: AccessibilitySettings {
            return AccessibilitySettings(
                preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory.rawValue,
                isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
                isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
                isBoldTextEnabled: UIAccessibility.isBoldTextEnabled,
                isButtonShapesEnabled: UIAccessibility.isButtonShapesEnabled,
                isReduceTransparencyEnabled: UIAccessibility.isReduceTransparencyEnabled,
                isInvertColorsEnabled: UIAccessibility.isInvertColorsEnabled,
                isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled
            )
        }
    }
    
    init() {
        setupAccessibilityObservers()
        performInitialAccessibilityCheck()
    }
    
    deinit {
        observers.forEach { notificationCenter.removeObserver($0) }
    }
    
    // MARK: - Public Interface
    
    /// Validates accessibility for a specific view
    func validateView<Content: View>(_ view: Content) -> [AccessibilityIssue] {
        let hostingController = UIHostingController(rootView: view)
        return analyzeViewAccessibility(hostingController.view)
    }
    
    /// Performs comprehensive accessibility audit
    func performAccessibilityAudit() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let issues = self.detectSystemwideAccessibilityIssues()
            
            DispatchQueue.main.async {
                self.currentAccessibilityIssues = issues
                self.accessibilityScore = self.calculateAccessibilityScore(issues: issues)
            }
        }
    }
    
    /// Provides accessibility recommendations based on current settings
    func getAccessibilityRecommendations() -> [String] {
        let settings = AccessibilitySettings.current
        var recommendations: [String] = []
        
        if !settings.isVoiceOverRunning {
            recommendations.append("Consider testing with VoiceOver enabled for full accessibility validation")
        }
        
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            recommendations.append("Large text is enabled - ensure all content scales appropriately")
        }
        
        if settings.isReduceMotionEnabled {
            recommendations.append("Motion reduction is enabled - animations should be minimized")
        }
        
        if settings.isReduceTransparencyEnabled {
            recommendations.append("Transparency reduction is enabled - ensure sufficient contrast")
        }
        
        return recommendations
    }
    
    // MARK: - Private Implementation
    
    private func setupAccessibilityObservers() {
        // Content Size Category changes
        let contentSizeObserver = notificationCenter.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAccessibilityChange()
        }
        observers.append(contentSizeObserver)
        
        // VoiceOver state changes
        let voiceOverObserver = notificationCenter.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAccessibilityChange()
        }
        observers.append(voiceOverObserver)
        
        // Reduce Motion changes
        let reduceMotionObserver = notificationCenter.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAccessibilityChange()
        }
        observers.append(reduceMotionObserver)
        
        // Bold Text changes
        let boldTextObserver = notificationCenter.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAccessibilityChange()
        }
        observers.append(boldTextObserver)
    }
    
    private func performInitialAccessibilityCheck() {
        performAccessibilityAudit()
    }
    
    private func handleAccessibilityChange() {
        performAccessibilityAudit()
    }
    
    private func detectSystemwideAccessibilityIssues() -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let settings = AccessibilitySettings.current
        
        // Check Dynamic Type support
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            issues.append(AccessibilityIssue(
                type: .dynamicTypeSupport,
                description: "Large accessibility text size is enabled",
                severity: .medium,
                recommendation: "Ensure all text elements support Dynamic Type scaling",
                detectedAt: Date()
            ))
        }
        
        // Check VoiceOver readiness
        if settings.isVoiceOverRunning {
            issues.append(AccessibilityIssue(
                type: .voiceOverSupport,
                description: "VoiceOver is active",
                severity: .high,
                recommendation: "Verify all interactive elements have proper accessibility labels",
                detectedAt: Date()
            ))
        }
        
        // Check Reduce Motion compliance
        if settings.isReduceMotionEnabled {
            issues.append(AccessibilityIssue(
                type: .reduceMotionSupport,
                description: "Reduce Motion is enabled",
                severity: .medium,
                recommendation: "Minimize or disable animations and transitions",
                detectedAt: Date()
            ))
        }
        
        return issues
    }
    
    private func analyzeViewAccessibility(_ view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Analyze touch target sizes
        issues.append(contentsOf: analyzeTouchTargets(in: view))
        
        // Analyze accessibility labels
        issues.append(contentsOf: analyzeAccessibilityLabels(in: view))
        
        // Analyze color contrast (simplified)
        issues.append(contentsOf: analyzeBasicContrast(in: view))
        
        return issues
    }
    
    private func analyzeTouchTargets(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let minimumTouchTarget: CGFloat = 44.0
        
        func checkSubviews(_ subview: UIView) {
            if subview.isUserInteractionEnabled && (subview is UIButton || subview is UIControl) {
                let size = subview.frame.size
                if size.width < minimumTouchTarget || size.height < minimumTouchTarget {
                    issues.append(AccessibilityIssue(
                        type: .touchTargetSize,
                        description: "Touch target below minimum size: \(Int(size.width))x\(Int(size.height))",
                        severity: .high,
                        recommendation: "Increase touch target to at least 44x44 points",
                        detectedAt: Date()
                    ))
                }
            }
            subview.subviews.forEach(checkSubviews)
        }
        
        view.subviews.forEach(checkSubviews)
        return issues
    }
    
    private func analyzeAccessibilityLabels(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func checkSubviews(_ subview: UIView) {
            if subview.isAccessibilityElement {
                if subview.accessibilityLabel?.isEmpty ?? true {
                    issues.append(AccessibilityIssue(
                        type: .voiceOverSupport,
                        description: "Missing accessibility label on \(type(of: subview))",
                        severity: .medium,
                        recommendation: "Add descriptive accessibility label",
                        detectedAt: Date()
                    ))
                }
            }
            subview.subviews.forEach(checkSubviews)
        }
        
        view.subviews.forEach(checkSubviews)
        return issues
    }
    
    private func analyzeBasicContrast(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func checkSubviews(_ subview: UIView) {
            if let label = subview as? UILabel,
               let textColor = label.textColor,
               let backgroundColor = label.backgroundColor ?? view.backgroundColor {
                
                let contrast = calculateBasicContrast(textColor: textColor, backgroundColor: backgroundColor)
                if contrast < 4.5 {
                    issues.append(AccessibilityIssue(
                        type: .colorContrast,
                        description: "Low color contrast: \(String(format: "%.1f", contrast)):1",
                        severity: .medium,
                        recommendation: "Increase color contrast to at least 4.5:1",
                        detectedAt: Date()
                    ))
                }
            }
            subview.subviews.forEach(checkSubviews)
        }
        
        view.subviews.forEach(checkSubviews)
        return issues
    }
    
    private func calculateBasicContrast(textColor: UIColor, backgroundColor: UIColor) -> Double {
        let textLuminance = calculateLuminance(color: textColor)
        let backgroundLuminance = calculateLuminance(color: backgroundColor)
        return Double(max(textLuminance, backgroundLuminance) / min(textLuminance, backgroundLuminance))
    }
    
    private func calculateLuminance(color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
    
    private func calculateAccessibilityScore(issues: [AccessibilityIssue]) -> Double {
        guard !issues.isEmpty else { return 1.0 }
        
        let totalWeight = issues.reduce(0) { sum, issue in
            sum + issue.severity.priority
        }
        
        let maxPossibleWeight = issues.count * AccessibilityIssue.Severity.critical.priority
        
        return max(0.0, 1.0 - (Double(totalWeight) / Double(maxPossibleWeight)))
    }
}

// MARK: - SwiftUI Integration

struct AccessibilityValidationView: View {
    @StateObject private var validationService = AccessibilityValidationService()
    @State private var showingIssues = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Accessibility Score")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(validationService.accessibilityScore * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            if !validationService.currentAccessibilityIssues.isEmpty {
                Button("View Issues (\(validationService.currentAccessibilityIssues.count))") {
                    showingIssues = true
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingIssues) {
            AccessibilityIssuesView(issues: validationService.currentAccessibilityIssues)
        }
    }
    
    private var scoreColor: Color {
        switch validationService.accessibilityScore {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return .orange
        default:
            return .red
        }
    }
}

struct AccessibilityIssuesView: View {
    let issues: [AccessibilityValidationService.AccessibilityIssue]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(issues) { issue in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(issue.type.rawValue)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(issue.severity.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor(issue.severity))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text(issue.description)
                        .font(.body)
                    
                    Text(issue.recommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Accessibility Issues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func severityColor(_ severity: AccessibilityValidationService.AccessibilityIssue.Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}
#endif
