import Foundation
import SwiftUI

// MARK: - Localization Validation Service
/// Production-grade localization validation system for Diamond Desk ERP
/// Validates string completeness, format compliance, and accessibility requirements
final class LocalizationValidationService: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = LocalizationValidationService()
    
    // MARK: - Published Properties
    @Published var validationResults: LocalizationValidationResults = .empty
    @Published var isValidating: Bool = false
    @Published var lastValidationDate: Date?
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let mainBundle = Bundle.main
    
    // MARK: - Validation Configuration
    private struct ValidationConfig {
        static let supportedLanguages = ["en", "es"] // English base + future Spanish
        static let requiredStringKeys = [
            // Core Navigation
            "nav.dashboard", "nav.tasks", "nav.tickets", "nav.clients", "nav.kpis",
            // Common Actions
            "action.save", "action.cancel", "action.delete", "action.edit", "action.create",
            "action.assign", "action.complete", "action.filter", "action.search",
            // Status Labels
            "status.pending", "status.in_progress", "status.completed", "status.cancelled",
            "status.open", "status.closed", "status.resolved",
            // Form Labels
            "form.title", "form.description", "form.due_date", "form.assigned_to",
            "form.priority", "form.category", "form.department", "form.store",
            // Error Messages
            "error.network", "error.validation", "error.permission", "error.unknown",
            "error.required_field", "error.invalid_format", "error.save_failed",
            // Accessibility
            "accessibility.task_card", "accessibility.ticket_card", "accessibility.client_card",
            "accessibility.kpi_card", "accessibility.create_button", "accessibility.filter_button"
        ]
        static let maxStringLength = 200
        static let requiredPlaceholderPattern = #"\{[a-zA-Z_]+\}"#
    }
    
    // MARK: - Initialization
    private init() {
        setupValidationFramework()
    }
    
    // MARK: - Public Methods
    
    /// Perform comprehensive localization validation
    func validateLocalization() async {
        await MainActor.run {
            isValidating = true
            validationResults = .empty
        }
        
        let results = await performValidation()
        
        await MainActor.run {
            self.validationResults = results
            self.lastValidationDate = Date()
            self.isValidating = false
        }
    }
    
    /// Get localized string with validation tracking
    func localizedString(for key: String, defaultValue: String? = nil) -> String {
        let value = NSLocalizedString(key, comment: "")
        
        // Track missing keys
        if value == key && defaultValue == nil {
            trackMissingKey(key)
        }
        
        return value != key ? value : (defaultValue ?? key)
    }
    
    /// Validate specific string key format
    func validateStringFormat(_ key: String, value: String) -> StringValidationResult {
        var issues: [LocalizationIssue] = []
        
        // Length validation
        if value.count > ValidationConfig.maxStringLength {
            issues.append(.excessiveLength(key: key, length: value.count))
        }
        
        // Empty string validation
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyString(key: key))
        }
        
        // Placeholder validation
        let placeholderRegex = try? NSRegularExpression(pattern: ValidationConfig.requiredPlaceholderPattern)
        let placeholderMatches = placeholderRegex?.numberOfMatches(in: value, range: NSRange(value.startIndex..., in: value)) ?? 0
        
        // Check for unescaped special characters
        if value.contains("%@") || value.contains("%d") {
            issues.append(.invalidPlaceholder(key: key, format: "Legacy format specifier"))
        }
        
        return StringValidationResult(
            key: key,
            value: value,
            isValid: issues.isEmpty,
            issues: issues,
            placeholderCount: placeholderMatches
        )
    }
    
    // MARK: - Private Methods
    
    private func setupValidationFramework() {
        // Initialize validation framework
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func performValidation() async -> LocalizationValidationResults {
        var results = LocalizationValidationResults.empty
        
        // Validate base language (English)
        results.baseLanguageResults = await validateLanguage("en")
        
        // Validate coverage for required keys
        results.coverageResults = validateKeyCoverage()
        
        // Validate accessibility strings
        results.accessibilityResults = validateAccessibilityStrings()
        
        // Calculate overall score
        results.overallScore = calculateOverallScore(results)
        
        return results
    }
    
    private func validateLanguage(_ languageCode: String) async -> LanguageValidationResult {
        let bundlePath = mainBundle.path(forResource: languageCode, ofType: "lproj")
        let localizationBundle = bundlePath.flatMap { Bundle(path: $0) } ?? mainBundle
        
        var stringResults: [StringValidationResult] = []
        var missingKeys: [String] = []
        
        for key in ValidationConfig.requiredStringKeys {
            let localizedValue = localizationBundle.localizedString(forKey: key, value: nil, table: nil)
            
            if localizedValue == key {
                missingKeys.append(key)
            } else {
                let validationResult = validateStringFormat(key, value: localizedValue)
                stringResults.append(validationResult)
            }
        }
        
        return LanguageValidationResult(
            languageCode: languageCode,
            stringResults: stringResults,
            missingKeys: missingKeys,
            completionPercentage: calculateCompletionPercentage(stringResults.count, total: ValidationConfig.requiredStringKeys.count)
        )
    }
    
    private func validateKeyCoverage() -> KeyCoverageResult {
        let stringsPath = mainBundle.path(forResource: "Localizable", ofType: "strings")
        let existingKeys = extractKeysFromStringsFile(stringsPath)
        
        let requiredKeys = Set(ValidationConfig.requiredStringKeys)
        let availableKeys = Set(existingKeys)
        
        let missingKeys = requiredKeys.subtracting(availableKeys)
        let extraKeys = availableKeys.subtracting(requiredKeys)
        
        return KeyCoverageResult(
            requiredKeys: Array(requiredKeys),
            availableKeys: Array(availableKeys),
            missingKeys: Array(missingKeys),
            extraKeys: Array(extraKeys),
            coveragePercentage: Double(availableKeys.intersection(requiredKeys).count) / Double(requiredKeys.count) * 100
        )
    }
    
    private func validateAccessibilityStrings() -> AccessibilityValidationResult {
        var issues: [AccessibilityIssue] = []
        let accessibilityKeys = ValidationConfig.requiredStringKeys.filter { $0.hasPrefix("accessibility.") }
        
        for key in accessibilityKeys {
            let value = localizedString(for: key)
            
            // Check for accessibility best practices
            if value.count < 10 {
                issues.append(.tooShort(key: key, length: value.count))
            }
            
            if value.lowercased().contains("button") && !value.lowercased().contains("tap") {
                issues.append(.missingAction(key: key, suggestion: "Consider adding action verb like 'tap'"))
            }
        }
        
        return AccessibilityValidationResult(
            validatedKeys: accessibilityKeys,
            issues: issues,
            complianceScore: calculateAccessibilityScore(accessibilityKeys.count, issues: issues.count)
        )
    }
    
    private func extractKeysFromStringsFile(_ path: String?) -> [String] {
        guard let path = path,
              let content = try? String(contentsOfFile: path) else {
            return []
        }
        
        let keyPattern = #"^"([^"]+)"\s*="#
        let regex = try? NSRegularExpression(pattern: keyPattern, options: .anchorsMatchLines)
        let range = NSRange(content.startIndex..., in: content)
        
        var keys: [String] = []
        regex?.enumerateMatches(in: content, range: range) { match, _, _ in
            if let match = match,
               let keyRange = Range(match.range(at: 1), in: content) {
                keys.append(String(content[keyRange]))
            }
        }
        
        return keys
    }
    
    private func calculateCompletionPercentage(_ completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total) * 100.0
    }
    
    private func calculateOverallScore(_ results: LocalizationValidationResults) -> Double {
        let baseLanguageScore = results.baseLanguageResults.completionPercentage
        let coverageScore = results.coverageResults.coveragePercentage
        let accessibilityScore = results.accessibilityResults.complianceScore
        
        return (baseLanguageScore + coverageScore + accessibilityScore) / 3.0
    }
    
    private func calculateAccessibilityScore(_ totalKeys: Int, issues: Int) -> Double {
        guard totalKeys > 0 else { return 100.0 }
        let successfulKeys = max(0, totalKeys - issues)
        return Double(successfulKeys) / Double(totalKeys) * 100.0
    }
    
    private func trackMissingKey(_ key: String) {
        // Track missing keys for future validation runs
        // This could integrate with analytics or logging service
        print("⚠️ Missing localization key: \(key)")
    }
    
    @objc private func applicationDidBecomeActive() {
        Task {
            await validateLocalization()
        }
    }
}

// MARK: - Data Models

struct LocalizationValidationResults {
    var baseLanguageResults: LanguageValidationResult
    var coverageResults: KeyCoverageResult
    var accessibilityResults: AccessibilityValidationResult
    var overallScore: Double
    var validationDate: Date
    
    static let empty = LocalizationValidationResults(
        baseLanguageResults: LanguageValidationResult.empty,
        coverageResults: KeyCoverageResult.empty,
        accessibilityResults: AccessibilityValidationResult.empty,
        overallScore: 0.0,
        validationDate: Date()
    )
    
    var isPassingThreshold: Bool {
        overallScore >= 85.0
    }
}

struct LanguageValidationResult {
    let languageCode: String
    let stringResults: [StringValidationResult]
    let missingKeys: [String]
    let completionPercentage: Double
    
    static let empty = LanguageValidationResult(
        languageCode: "en",
        stringResults: [],
        missingKeys: [],
        completionPercentage: 0.0
    )
}

struct StringValidationResult {
    let key: String
    let value: String
    let isValid: Bool
    let issues: [LocalizationIssue]
    let placeholderCount: Int
}

struct KeyCoverageResult {
    let requiredKeys: [String]
    let availableKeys: [String]
    let missingKeys: [String]
    let extraKeys: [String]
    let coveragePercentage: Double
    
    static let empty = KeyCoverageResult(
        requiredKeys: [],
        availableKeys: [],
        missingKeys: [],
        extraKeys: [],
        coveragePercentage: 0.0
    )
}

struct AccessibilityValidationResult {
    let validatedKeys: [String]
    let issues: [AccessibilityIssue]
    let complianceScore: Double
    
    static let empty = AccessibilityValidationResult(
        validatedKeys: [],
        issues: [],
        complianceScore: 0.0
    )
}

// MARK: - Issue Types

enum LocalizationIssue {
    case excessiveLength(key: String, length: Int)
    case emptyString(key: String)
    case invalidPlaceholder(key: String, format: String)
    case missingTranslation(key: String, language: String)
    
    var description: String {
        switch self {
        case .excessiveLength(let key, let length):
            return "String '\(key)' exceeds maximum length: \(length) characters"
        case .emptyString(let key):
            return "String '\(key)' is empty or whitespace only"
        case .invalidPlaceholder(let key, let format):
            return "String '\(key)' has invalid placeholder format: \(format)"
        case .missingTranslation(let key, let language):
            return "String '\(key)' missing translation for language: \(language)"
        }
    }
}

enum AccessibilityIssue {
    case tooShort(key: String, length: Int)
    case missingAction(key: String, suggestion: String)
    case noVoiceOverDescription(key: String)
    
    var description: String {
        switch self {
        case .tooShort(let key, let length):
            return "Accessibility string '\(key)' too short: \(length) characters"
        case .missingAction(let key, let suggestion):
            return "Accessibility string '\(key)' missing action verb. \(suggestion)"
        case .noVoiceOverDescription(let key):
            return "Accessibility string '\(key)' lacks VoiceOver description"
        }
    }
}

// MARK: - Localization Service Extension
extension LocalizationValidationService {
    
    /// Generate validation report for debug console
    func generateValidationReport() -> String {
        guard !validationResults.baseLanguageResults.stringResults.isEmpty else {
            return "No validation results available. Run validation first."
        }
        
        var report = """
        # Localization Validation Report
        Generated: \(DateFormatter.iso8601.string(from: validationResults.validationDate))
        Overall Score: \(String(format: "%.1f", validationResults.overallScore))%
        
        ## Base Language (English)
        Completion: \(String(format: "%.1f", validationResults.baseLanguageResults.completionPercentage))%
        Missing Keys: \(validationResults.baseLanguageResults.missingKeys.count)
        
        """
        
        if !validationResults.baseLanguageResults.missingKeys.isEmpty {
            report += "\n### Missing Keys:\n"
            for key in validationResults.baseLanguageResults.missingKeys {
                report += "- \(key)\n"
            }
        }
        
        report += "\n## Key Coverage\n"
        report += "Coverage: \(String(format: "%.1f", validationResults.coverageResults.coveragePercentage))%\n"
        report += "Missing: \(validationResults.coverageResults.missingKeys.count)\n"
        report += "Extra: \(validationResults.coverageResults.extraKeys.count)\n"
        
        report += "\n## Accessibility Compliance\n"
        report += "Score: \(String(format: "%.1f", validationResults.accessibilityResults.complianceScore))%\n"
        report += "Issues: \(validationResults.accessibilityResults.issues.count)\n"
        
        return report
    }
    
    /// Export validation results for external analysis
    func exportValidationData() -> Data? {
        let exportData = [
            "validationDate": ISO8601DateFormatter().string(from: validationResults.validationDate),
            "overallScore": validationResults.overallScore,
            "baseLanguage": [
                "languageCode": validationResults.baseLanguageResults.languageCode,
                "completionPercentage": validationResults.baseLanguageResults.completionPercentage,
                "missingKeys": validationResults.baseLanguageResults.missingKeys
            ],
            "coverage": [
                "coveragePercentage": validationResults.coverageResults.coveragePercentage,
                "missingKeys": validationResults.coverageResults.missingKeys,
                "extraKeys": validationResults.coverageResults.extraKeys
            ],
            "accessibility": [
                "complianceScore": validationResults.accessibilityResults.complianceScore,
                "issueCount": validationResults.accessibilityResults.issues.count
            ]
        ] as [String: Any]
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}
