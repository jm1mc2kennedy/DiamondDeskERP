import Foundation
import SwiftUI

// MARK: - Analytics Consent Service
/// Enterprise-grade analytics consent management for GDPR/CCPA compliance
/// Manages user consent preferences, persistent storage, and integration with analytics services
final class AnalyticsConsentService: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = AnalyticsConsentService()
    
    // MARK: - Published Properties
    @Published var consentStatus: ConsentStatus = .unknown
    @Published var consentPreferences: ConsentPreferences = .default
    @Published var showingConsentBanner: Bool = false
    @Published var isInitialized: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let localizationService = LocalizationService.shared
    
    // MARK: - Storage Keys
    private struct StorageKeys {
        static let consentStatus = "analytics_consent_status"
        static let consentPreferences = "analytics_consent_preferences"
        static let consentTimestamp = "analytics_consent_timestamp"
        static let consentVersion = "analytics_consent_version"
        static let hasShownBanner = "analytics_consent_banner_shown"
    }
    
    // MARK: - Configuration
    private struct ConsentConfig {
        static let currentConsentVersion = "1.0"
        static let consentExpiryDays = 365
        static let requiredForProduction = true
        static let defaultAnalyticsEnabled = false
        static let bannerDisplayDelay: TimeInterval = 2.0
    }
    
    // MARK: - Initialization
    private init() {
        loadStoredConsent()
        initializeConsentFlow()
    }
    
    // MARK: - Public Methods
    
    /// Initialize consent flow on app launch
    func initializeConsentFlow() {
        guard !isInitialized else { return }
        
        // Check if consent is required
        if requiresConsentPrompt() {
            scheduleConsentBanner()
        }
        
        isInitialized = true
    }
    
    /// Update consent preferences with user selection
    func updateConsent(_ preferences: ConsentPreferences) {
        consentPreferences = preferences
        consentStatus = .granted
        showingConsentBanner = false
        
        persistConsent()
        notifyAnalyticsServices()
        
        // Log consent update
        logConsentChange("User granted consent with preferences: \(preferences)")
    }
    
    /// Explicitly deny analytics consent
    func denyConsent() {
        consentPreferences = .denied
        consentStatus = .denied
        showingConsentBanner = false
        
        persistConsent()
        notifyAnalyticsServices()
        
        logConsentChange("User denied analytics consent")
    }
    
    /// Revoke previously granted consent
    func revokeConsent() {
        consentPreferences = .denied
        consentStatus = .revoked
        
        persistConsent()
        notifyAnalyticsServices()
        
        logConsentChange("User revoked analytics consent")
    }
    
    /// Check if specific analytics category is permitted
    func isPermitted(_ category: AnalyticsCategory) -> Bool {
        guard consentStatus == .granted else { return false }
        
        switch category {
        case .essential:
            return true // Always allowed for app functionality
        case .performance:
            return consentPreferences.performanceAnalytics
        case .functional:
            return consentPreferences.functionalAnalytics
        case .targeting:
            return consentPreferences.targetingAnalytics
        case .crashes:
            return consentPreferences.crashAnalytics
        }
    }
    
    /// Get consent status for external services
    func getConsentStatusForService(_ service: AnalyticsService) -> Bool {
        switch service {
        case .appAnalytics:
            return isPermitted(.performance) && isPermitted(.functional)
        case .crashReporting:
            return isPermitted(.crashes)
        case .userBehavior:
            return isPermitted(.functional)
        case .performanceMonitoring:
            return isPermitted(.performance)
        }
    }
    
    /// Reset consent state (for testing or GDPR deletion)
    func resetConsent() {
        consentStatus = .unknown
        consentPreferences = .default
        showingConsentBanner = false
        
        clearStoredConsent()
        notifyAnalyticsServices()
        
        logConsentChange("Consent state reset")
    }
    
    /// Force show consent banner (for settings review)
    func showConsentSettings() {
        showingConsentBanner = true
    }
    
    // MARK: - Private Methods
    
    private func requiresConsentPrompt() -> Bool {
        // Check if consent is required based on current status
        switch consentStatus {
        case .unknown:
            return true
        case .expired:
            return true
        case .granted, .denied, .revoked:
            return false
        }
    }
    
    private func scheduleConsentBanner() {
        DispatchQueue.main.asyncAfter(deadline: .now() + ConsentConfig.bannerDisplayDelay) {
            self.showingConsentBanner = true
        }
    }
    
    private func loadStoredConsent() {
        // Load consent status
        if let statusString = userDefaults.string(forKey: StorageKeys.consentStatus),
           let status = ConsentStatus(rawValue: statusString) {
            consentStatus = status
        }
        
        // Load consent preferences
        if let preferencesData = userDefaults.data(forKey: StorageKeys.consentPreferences) {
            do {
                consentPreferences = try JSONDecoder().decode(ConsentPreferences.self, from: preferencesData)
            } catch {
                print("⚠️ Failed to decode consent preferences: \(error)")
                consentPreferences = .default
            }
        }
        
        // Check consent expiry
        if let timestamp = userDefaults.object(forKey: StorageKeys.consentTimestamp) as? Date {
            let expiryDate = Calendar.current.date(byAdding: .day, value: ConsentConfig.consentExpiryDays, to: timestamp)
            if let expiry = expiryDate, Date() > expiry {
                consentStatus = .expired
            }
        }
        
        // Check consent version compatibility
        let storedVersion = userDefaults.string(forKey: StorageKeys.consentVersion)
        if storedVersion != ConsentConfig.currentConsentVersion {
            consentStatus = .expired
        }
    }
    
    private func persistConsent() {
        userDefaults.set(consentStatus.rawValue, forKey: StorageKeys.consentStatus)
        userDefaults.set(Date(), forKey: StorageKeys.consentTimestamp)
        userDefaults.set(ConsentConfig.currentConsentVersion, forKey: StorageKeys.consentVersion)
        userDefaults.set(true, forKey: StorageKeys.hasShownBanner)
        
        // Encode and store preferences
        do {
            let preferencesData = try JSONEncoder().encode(consentPreferences)
            userDefaults.set(preferencesData, forKey: StorageKeys.consentPreferences)
        } catch {
            print("⚠️ Failed to encode consent preferences: \(error)")
        }
    }
    
    private func clearStoredConsent() {
        userDefaults.removeObject(forKey: StorageKeys.consentStatus)
        userDefaults.removeObject(forKey: StorageKeys.consentPreferences)
        userDefaults.removeObject(forKey: StorageKeys.consentTimestamp)
        userDefaults.removeObject(forKey: StorageKeys.consentVersion)
        userDefaults.removeObject(forKey: StorageKeys.hasShownBanner)
    }
    
    private func notifyAnalyticsServices() {
        // Notify all registered analytics services of consent changes
        NotificationCenter.default.post(
            name: .analyticsConsentChanged,
            object: self,
            userInfo: [
                "consentStatus": consentStatus,
                "preferences": consentPreferences
            ]
        )
    }
    
    private func logConsentChange(_ message: String) {
        print("📊 Analytics Consent: \(message)")
        
        // Only log to analytics if basic functionality is permitted
        if isPermitted(.essential) {
            // Log to internal analytics (essential category)
            // Implementation would integrate with AnalyticsService
        }
    }
}

// MARK: - Data Models

/// Consent status enumeration
enum ConsentStatus: String, CaseIterable, Codable {
    case unknown = "unknown"
    case granted = "granted"
    case denied = "denied"
    case revoked = "revoked"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .unknown:
            return LocalizationService.shared.string(for: .consentStatusUnknown)
        case .granted:
            return LocalizationService.shared.string(for: .consentStatusGranted)
        case .denied:
            return LocalizationService.shared.string(for: .consentStatusDenied)
        case .revoked:
            return LocalizationService.shared.string(for: .consentStatusRevoked)
        case .expired:
            return LocalizationService.shared.string(for: .consentStatusExpired)
        }
    }
    
    var color: Color {
        switch self {
        case .unknown:
            return .orange
        case .granted:
            return .green
        case .denied, .revoked:
            return .red
        case .expired:
            return .yellow
        }
    }
}

/// Granular consent preferences for different analytics categories
struct ConsentPreferences: Codable, Equatable {
    var performanceAnalytics: Bool
    var functionalAnalytics: Bool
    var targetingAnalytics: Bool
    var crashAnalytics: Bool
    
    static let `default` = ConsentPreferences(
        performanceAnalytics: false,
        functionalAnalytics: false,
        targetingAnalytics: false,
        crashAnalytics: true // Default to crash reporting for app stability
    )
    
    static let denied = ConsentPreferences(
        performanceAnalytics: false,
        functionalAnalytics: false,
        targetingAnalytics: false,
        crashAnalytics: false
    )
    
    static let allGranted = ConsentPreferences(
        performanceAnalytics: true,
        functionalAnalytics: true,
        targetingAnalytics: true,
        crashAnalytics: true
    )
    
    var description: String {
        var components: [String] = []
        
        if performanceAnalytics { components.append("Performance") }
        if functionalAnalytics { components.append("Functional") }
        if targetingAnalytics { components.append("Targeting") }
        if crashAnalytics { components.append("Crash Reporting") }
        
        return components.isEmpty ? "No analytics enabled" : components.joined(separator: ", ")
    }
}

/// Analytics categories for granular consent management
enum AnalyticsCategory: String, CaseIterable {
    case essential = "essential"
    case performance = "performance"
    case functional = "functional"
    case targeting = "targeting"
    case crashes = "crashes"
    
    var displayName: String {
        switch self {
        case .essential:
            return LocalizationService.shared.string(for: .analyticsCategoryEssential)
        case .performance:
            return LocalizationService.shared.string(for: .analyticsCategoryPerformance)
        case .functional:
            return LocalizationService.shared.string(for: .analyticsCategoryFunctional)
        case .targeting:
            return LocalizationService.shared.string(for: .analyticsCategoryTargeting)
        case .crashes:
            return LocalizationService.shared.string(for: .analyticsCategoryCrashes)
        }
    }
    
    var description: String {
        switch self {
        case .essential:
            return LocalizationService.shared.string(for: .analyticsCategoryEssentialDesc)
        case .performance:
            return LocalizationService.shared.string(for: .analyticsCategoryPerformanceDesc)
        case .functional:
            return LocalizationService.shared.string(for: .analyticsCategoryFunctionalDesc)
        case .targeting:
            return LocalizationService.shared.string(for: .analyticsCategoryTargetingDesc)
        case .crashes:
            return LocalizationService.shared.string(for: .analyticsCategoryCrashesDesc)
        }
    }
    
    var isOptional: Bool {
        self != .essential
    }
}

/// Analytics service types for consent management
enum AnalyticsService: String, CaseIterable {
    case appAnalytics = "app_analytics"
    case crashReporting = "crash_reporting"
    case userBehavior = "user_behavior"
    case performanceMonitoring = "performance_monitoring"
    
    var displayName: String {
        switch self {
        case .appAnalytics:
            return "App Analytics"
        case .crashReporting:
            return "Crash Reporting"
        case .userBehavior:
            return "User Behavior"
        case .performanceMonitoring:
            return "Performance Monitoring"
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let analyticsConsentChanged = Notification.Name("AnalyticsConsentChanged")
}

// MARK: - Consent Banner Helper
extension AnalyticsConsentService {
    
    /// Generate consent banner configuration
    func getConsentBannerConfig() -> ConsentBannerConfig {
        return ConsentBannerConfig(
            title: localizationService.string(for: .consentBannerTitle),
            message: localizationService.string(for: .consentBannerMessage),
            acceptAllTitle: localizationService.string(for: .consentAcceptAll),
            declineTitle: localizationService.string(for: .consentDecline),
            customizeTitle: localizationService.string(for: .consentCustomize),
            categories: AnalyticsCategory.allCases.filter { $0.isOptional }
        )
    }
}

struct ConsentBannerConfig {
    let title: String
    let message: String
    let acceptAllTitle: String
    let declineTitle: String
    let customizeTitle: String
    let categories: [AnalyticsCategory]
}
