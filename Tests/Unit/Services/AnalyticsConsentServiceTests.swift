import XCTest
@testable import DiamondDeskERP

// MARK: - Analytics Consent Service Tests
final class AnalyticsConsentServiceTests: XCTestCase {
    
    var consentService: AnalyticsConsentService!
    var userDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // Use a test user defaults suite to avoid affecting real data
        userDefaults = UserDefaults(suiteName: "AnalyticsConsentServiceTests")!
        userDefaults.removePersistentDomain(forName: "AnalyticsConsentServiceTests")
        
        consentService = AnalyticsConsentService.shared
        consentService.resetConsent() // Start with clean state
    }
    
    override func tearDown() {
        consentService.resetConsent()
        userDefaults.removePersistentDomain(forName: "AnalyticsConsentServiceTests")
        consentService = nil
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testServiceInitialization() {
        XCTAssertNotNil(consentService)
        XCTAssertEqual(consentService.consentStatus, .unknown)
        XCTAssertEqual(consentService.consentPreferences, .default)
        XCTAssertFalse(consentService.showingConsentBanner)
    }
    
    func testInitializationWithStoredConsent() {
        // Set up stored consent
        let preferences = ConsentPreferences.allGranted
        consentService.updateConsent(preferences)
        
        // Verify stored consent is loaded
        XCTAssertEqual(consentService.consentStatus, .granted)
        XCTAssertEqual(consentService.consentPreferences, preferences)
    }
    
    // MARK: - Consent Status Tests
    
    func testUpdateConsentGranted() {
        let preferences = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: true,
            targetingAnalytics: false,
            crashAnalytics: true
        )
        
        consentService.updateConsent(preferences)
        
        XCTAssertEqual(consentService.consentStatus, .granted)
        XCTAssertEqual(consentService.consentPreferences, preferences)
        XCTAssertFalse(consentService.showingConsentBanner)
    }
    
    func testDenyConsent() {
        consentService.denyConsent()
        
        XCTAssertEqual(consentService.consentStatus, .denied)
        XCTAssertEqual(consentService.consentPreferences, .denied)
        XCTAssertFalse(consentService.showingConsentBanner)
    }
    
    func testRevokeConsent() {
        // First grant consent
        consentService.updateConsent(.allGranted)
        XCTAssertEqual(consentService.consentStatus, .granted)
        
        // Then revoke it
        consentService.revokeConsent()
        
        XCTAssertEqual(consentService.consentStatus, .revoked)
        XCTAssertEqual(consentService.consentPreferences, .denied)
    }
    
    func testResetConsent() {
        // Set up some consent state
        consentService.updateConsent(.allGranted)
        XCTAssertEqual(consentService.consentStatus, .granted)
        
        // Reset consent
        consentService.resetConsent()
        
        XCTAssertEqual(consentService.consentStatus, .unknown)
        XCTAssertEqual(consentService.consentPreferences, .default)
        XCTAssertFalse(consentService.showingConsentBanner)
    }
    
    // MARK: - Permission Tests
    
    func testIsPermittedEssential() {
        // Essential analytics should always be permitted
        XCTAssertTrue(consentService.isPermitted(.essential))
        
        consentService.denyConsent()
        XCTAssertTrue(consentService.isPermitted(.essential))
    }
    
    func testIsPermittedWithGrantedConsent() {
        let preferences = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: false,
            targetingAnalytics: true,
            crashAnalytics: false
        )
        
        consentService.updateConsent(preferences)
        
        XCTAssertTrue(consentService.isPermitted(.essential))
        XCTAssertTrue(consentService.isPermitted(.performance))
        XCTAssertFalse(consentService.isPermitted(.functional))
        XCTAssertTrue(consentService.isPermitted(.targeting))
        XCTAssertFalse(consentService.isPermitted(.crashes))
    }
    
    func testIsPermittedWithDeniedConsent() {
        consentService.denyConsent()
        
        XCTAssertTrue(consentService.isPermitted(.essential))
        XCTAssertFalse(consentService.isPermitted(.performance))
        XCTAssertFalse(consentService.isPermitted(.functional))
        XCTAssertFalse(consentService.isPermitted(.targeting))
        XCTAssertFalse(consentService.isPermitted(.crashes))
    }
    
    func testIsPermittedWithUnknownConsent() {
        // Unknown consent should deny all optional categories
        XCTAssertEqual(consentService.consentStatus, .unknown)
        
        XCTAssertTrue(consentService.isPermitted(.essential))
        XCTAssertFalse(consentService.isPermitted(.performance))
        XCTAssertFalse(consentService.isPermitted(.functional))
        XCTAssertFalse(consentService.isPermitted(.targeting))
        XCTAssertFalse(consentService.isPermitted(.crashes))
    }
    
    // MARK: - Service-Specific Consent Tests
    
    func testGetConsentStatusForServiceAppAnalytics() {
        let preferences = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: true,
            targetingAnalytics: false,
            crashAnalytics: false
        )
        
        consentService.updateConsent(preferences)
        
        // App analytics requires both performance and functional
        XCTAssertTrue(consentService.getConsentStatusForService(.appAnalytics))
    }
    
    func testGetConsentStatusForServiceCrashReporting() {
        let preferences = ConsentPreferences(
            performanceAnalytics: false,
            functionalAnalytics: false,
            targetingAnalytics: false,
            crashAnalytics: true
        )
        
        consentService.updateConsent(preferences)
        
        XCTAssertTrue(consentService.getConsentStatusForService(.crashReporting))
        XCTAssertFalse(consentService.getConsentStatusForService(.appAnalytics))
    }
    
    func testGetConsentStatusForServiceUserBehavior() {
        let preferences = ConsentPreferences(
            performanceAnalytics: false,
            functionalAnalytics: true,
            targetingAnalytics: false,
            crashAnalytics: false
        )
        
        consentService.updateConsent(preferences)
        
        XCTAssertTrue(consentService.getConsentStatusForService(.userBehavior))
    }
    
    func testGetConsentStatusForServicePerformanceMonitoring() {
        let preferences = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: false,
            targetingAnalytics: false,
            crashAnalytics: false
        )
        
        consentService.updateConsent(preferences)
        
        XCTAssertTrue(consentService.getConsentStatusForService(.performanceMonitoring))
    }
    
    // MARK: - Consent Banner Tests
    
    func testShowConsentSettings() {
        XCTAssertFalse(consentService.showingConsentBanner)
        
        consentService.showConsentSettings()
        
        XCTAssertTrue(consentService.showingConsentBanner)
    }
    
    func testGetConsentBannerConfig() {
        let config = consentService.getConsentBannerConfig()
        
        XCTAssertFalse(config.title.isEmpty)
        XCTAssertFalse(config.message.isEmpty)
        XCTAssertFalse(config.acceptAllTitle.isEmpty)
        XCTAssertFalse(config.declineTitle.isEmpty)
        XCTAssertFalse(config.customizeTitle.isEmpty)
        XCTAssertFalse(config.categories.isEmpty)
        
        // Should not include essential category (not optional)
        XCTAssertFalse(config.categories.contains(.essential))
    }
    
    // MARK: - Persistence Tests
    
    func testConsentPersistence() {
        let preferences = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: false,
            targetingAnalytics: true,
            crashAnalytics: false
        )
        
        consentService.updateConsent(preferences)
        
        // Create new service instance to test persistence
        let newService = AnalyticsConsentService.shared
        
        XCTAssertEqual(newService.consentStatus, .granted)
        XCTAssertEqual(newService.consentPreferences.performanceAnalytics, true)
        XCTAssertEqual(newService.consentPreferences.functionalAnalytics, false)
        XCTAssertEqual(newService.consentPreferences.targetingAnalytics, true)
        XCTAssertEqual(newService.consentPreferences.crashAnalytics, false)
    }
    
    // MARK: - Notification Tests
    
    func testNotificationPostedOnConsentChange() {
        let expectation = XCTestExpectation(description: "Consent change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .analyticsConsentChanged,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["consentStatus"])
            XCTAssertNotNil(notification.userInfo?["preferences"])
            expectation.fulfill()
        }
        
        consentService.updateConsent(.allGranted)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Edge Cases Tests
    
    func testConsentStatusTransitions() {
        // Unknown -> Granted
        XCTAssertEqual(consentService.consentStatus, .unknown)
        consentService.updateConsent(.allGranted)
        XCTAssertEqual(consentService.consentStatus, .granted)
        
        // Granted -> Revoked
        consentService.revokeConsent()
        XCTAssertEqual(consentService.consentStatus, .revoked)
        
        // Revoked -> Granted (re-granting)
        consentService.updateConsent(.default)
        XCTAssertEqual(consentService.consentStatus, .granted)
        
        // Granted -> Denied
        consentService.denyConsent()
        XCTAssertEqual(consentService.consentStatus, .denied)
        
        // Any -> Unknown (reset)
        consentService.resetConsent()
        XCTAssertEqual(consentService.consentStatus, .unknown)
    }
    
    func testMultipleConsentUpdates() {
        // Test rapid consent changes
        for i in 0..<10 {
            let preferences = ConsentPreferences(
                performanceAnalytics: i % 2 == 0,
                functionalAnalytics: i % 3 == 0,
                targetingAnalytics: i % 4 == 0,
                crashAnalytics: i % 5 == 0
            )
            
            consentService.updateConsent(preferences)
            XCTAssertEqual(consentService.consentStatus, .granted)
            XCTAssertEqual(consentService.consentPreferences, preferences)
        }
    }
    
    // MARK: - Performance Tests
    
    func testConsentCheckPerformance() {
        consentService.updateConsent(.allGranted)
        
        measure {
            for _ in 0..<1000 {
                _ = consentService.isPermitted(.performance)
                _ = consentService.isPermitted(.functional)
                _ = consentService.isPermitted(.targeting)
                _ = consentService.isPermitted(.crashes)
            }
        }
    }
    
    func testServiceConsentCheckPerformance() {
        consentService.updateConsent(.allGranted)
        
        measure {
            for _ in 0..<1000 {
                _ = consentService.getConsentStatusForService(.appAnalytics)
                _ = consentService.getConsentStatusForService(.crashReporting)
                _ = consentService.getConsentStatusForService(.userBehavior)
                _ = consentService.getConsentStatusForService(.performanceMonitoring)
            }
        }
    }
}

// MARK: - Consent Preferences Tests
final class ConsentPreferencesTests: XCTestCase {
    
    func testDefaultPreferences() {
        let preferences = ConsentPreferences.default
        
        XCTAssertFalse(preferences.performanceAnalytics)
        XCTAssertFalse(preferences.functionalAnalytics)
        XCTAssertFalse(preferences.targetingAnalytics)
        XCTAssertTrue(preferences.crashAnalytics) // Default to enabled for stability
    }
    
    func testDeniedPreferences() {
        let preferences = ConsentPreferences.denied
        
        XCTAssertFalse(preferences.performanceAnalytics)
        XCTAssertFalse(preferences.functionalAnalytics)
        XCTAssertFalse(preferences.targetingAnalytics)
        XCTAssertFalse(preferences.crashAnalytics)
    }
    
    func testAllGrantedPreferences() {
        let preferences = ConsentPreferences.allGranted
        
        XCTAssertTrue(preferences.performanceAnalytics)
        XCTAssertTrue(preferences.functionalAnalytics)
        XCTAssertTrue(preferences.targetingAnalytics)
        XCTAssertTrue(preferences.crashAnalytics)
    }
    
    func testPreferencesEquality() {
        let preferences1 = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: false,
            targetingAnalytics: true,
            crashAnalytics: false
        )
        
        let preferences2 = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: false,
            targetingAnalytics: true,
            crashAnalytics: false
        )
        
        let preferences3 = ConsentPreferences(
            performanceAnalytics: false,
            functionalAnalytics: false,
            targetingAnalytics: true,
            crashAnalytics: false
        )
        
        XCTAssertEqual(preferences1, preferences2)
        XCTAssertNotEqual(preferences1, preferences3)
    }
    
    func testPreferencesDescription() {
        let allGranted = ConsentPreferences.allGranted
        let description = allGranted.description
        
        XCTAssertTrue(description.contains("Performance"))
        XCTAssertTrue(description.contains("Functional"))
        XCTAssertTrue(description.contains("Targeting"))
        XCTAssertTrue(description.contains("Crash Reporting"))
        
        let denied = ConsentPreferences.denied
        XCTAssertEqual(denied.description, "No analytics enabled")
    }
    
    func testPreferencesCodable() {
        let preferences = ConsentPreferences(
            performanceAnalytics: true,
            functionalAnalytics: false,
            targetingAnalytics: true,
            crashAnalytics: false
        )
        
        do {
            let encoded = try JSONEncoder().encode(preferences)
            let decoded = try JSONDecoder().decode(ConsentPreferences.self, from: encoded)
            
            XCTAssertEqual(preferences, decoded)
        } catch {
            XCTFail("Failed to encode/decode preferences: \(error)")
        }
    }
}

// MARK: - Analytics Category Tests
final class AnalyticsCategoryTests: XCTestCase {
    
    func testCategoryDisplayNames() {
        // Test that all categories have non-empty display names
        for category in AnalyticsCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
        }
    }
    
    func testOptionalCategories() {
        XCTAssertFalse(AnalyticsCategory.essential.isOptional)
        XCTAssertTrue(AnalyticsCategory.performance.isOptional)
        XCTAssertTrue(AnalyticsCategory.functional.isOptional)
        XCTAssertTrue(AnalyticsCategory.targeting.isOptional)
        XCTAssertTrue(AnalyticsCategory.crashes.isOptional)
    }
    
    func testCategoryRawValues() {
        XCTAssertEqual(AnalyticsCategory.essential.rawValue, "essential")
        XCTAssertEqual(AnalyticsCategory.performance.rawValue, "performance")
        XCTAssertEqual(AnalyticsCategory.functional.rawValue, "functional")
        XCTAssertEqual(AnalyticsCategory.targeting.rawValue, "targeting")
        XCTAssertEqual(AnalyticsCategory.crashes.rawValue, "crashes")
    }
}

// MARK: - Consent Status Tests
final class ConsentStatusTests: XCTestCase {
    
    func testStatusRawValues() {
        XCTAssertEqual(ConsentStatus.unknown.rawValue, "unknown")
        XCTAssertEqual(ConsentStatus.granted.rawValue, "granted")
        XCTAssertEqual(ConsentStatus.denied.rawValue, "denied")
        XCTAssertEqual(ConsentStatus.revoked.rawValue, "revoked")
        XCTAssertEqual(ConsentStatus.expired.rawValue, "expired")
    }
    
    func testStatusDisplayNames() {
        // Test that all statuses have non-empty display names
        for status in ConsentStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty)
        }
    }
    
    func testStatusColors() {
        // Test that each status has an associated color
        for status in ConsentStatus.allCases {
            _ = status.color // Should not crash
        }
    }
    
    func testStatusCodable() {
        for status in ConsentStatus.allCases {
            do {
                let encoded = try JSONEncoder().encode(status)
                let decoded = try JSONDecoder().decode(ConsentStatus.self, from: encoded)
                XCTAssertEqual(status, decoded)
            } catch {
                XCTFail("Failed to encode/decode status \(status): \(error)")
            }
        }
    }
}
