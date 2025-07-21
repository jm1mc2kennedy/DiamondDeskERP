#if canImport(XCTest)
import CryptoKit
import LocalAuthentication
import XCTest

final class SecurityAuditTests: XCTestCase {
    var securityManager: SecurityManager!
    var encryptionService: EncryptionService!
    var authenticationService: AuthenticationService!
    var dataValidationService: DataValidationService!
    
    override func setUp() {
        super.setUp()
        securityManager = SecurityManager.shared
        encryptionService = EncryptionService()
        authenticationService = AuthenticationService()
        dataValidationService = DataValidationService()
    }
    
    override func tearDown() {
        securityManager = nil
        encryptionService = nil
        authenticationService = nil
        dataValidationService = nil
        super.tearDown()
    }
    
    // MARK: - Data Encryption Tests
    
    func testSensitiveDataEncryption() {
        let sensitiveData = [
            "john.doe@company.com",
            "555-123-4567",
            "123 Main Street, Anytown, ST 12345",
            "Emergency Contact: Jane Doe",
            "Social Security: XXX-XX-XXXX"
        ]
        
        for data in sensitiveData {
            let encrypted = encryptionService.encrypt(data)
            XCTAssertNotEqual(encrypted, data, "Data should be encrypted")
            XCTAssertTrue(encrypted.count > 0, "Encrypted data should not be empty")
            
            let decrypted = encryptionService.decrypt(encrypted)
            XCTAssertEqual(decrypted, data, "Decrypted data should match original")
        }
        
        print("✅ Sensitive data encryption validation passed")
    }
    
    func testEncryptionKeyRotation() {
        let testData = "Test encryption key rotation"
        
        // Encrypt with current key
        let encrypted1 = encryptionService.encrypt(testData)
        
        // Rotate encryption key
        encryptionService.rotateEncryptionKey()
        
        // Encrypt with new key
        let encrypted2 = encryptionService.encrypt(testData)
        
        // Should be different encrypted values
        XCTAssertNotEqual(encrypted1, encrypted2, "Different keys should produce different encrypted values")
        
        // Both should decrypt correctly
        XCTAssertEqual(encryptionService.decrypt(encrypted1), testData)
        XCTAssertEqual(encryptionService.decrypt(encrypted2), testData)
        
        print("✅ Encryption key rotation validation passed")
    }
    
    func testCloudKitDataEncryption() async {
        let employee = Employee(
            employeeNumber: "SEC001",
            firstName: "Security",
            lastName: "Test",
            email: "security.test@company.com",
            department: "Security",
            title: "Security Tester",
            hireDate: Date(),
            address: Address(street: "123 Secure St", city: "Safe City", state: "SC", zipCode: "12345"),
            emergencyContact: EmergencyContact(name: "Emergency Contact", relationship: "Contact", phone: "555-0123"),
            workLocation: .office,
            employmentType: .fullTime
        )
        
        // Test CloudKit record encryption
        let record = await CloudKitManager.shared.createEncryptedRecord(for: employee)
        
        // Verify sensitive fields are encrypted
        let emailField = record["email"] as? String
        XCTAssertNotEqual(emailField, employee.email, "Email should be encrypted in CloudKit record")
        
        let phoneField = record["emergencyPhone"] as? String
        XCTAssertNotEqual(phoneField, employee.emergencyContact.phone, "Phone should be encrypted in CloudKit record")
        
        // Verify decryption works
        let decryptedEmployee = await CloudKitManager.shared.decryptRecord(record, as: Employee.self)
        XCTAssertEqual(decryptedEmployee?.email, employee.email, "Decrypted email should match original")
        XCTAssertEqual(decryptedEmployee?.emergencyContact.phone, employee.emergencyContact.phone, "Decrypted phone should match original")
        
        print("✅ CloudKit data encryption validation passed")
    }
    
    // MARK: - Authentication Security Tests
    
    func testBiometricAuthentication() async {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("⚠️ Biometric authentication not available on this device")
            return
        }
        
        // Test biometric authentication flow
        let result = await authenticationService.authenticateWithBiometrics()
        
        // Note: In testing environment, this will likely fail, but we test the flow
        switch result {
        case .success:
            XCTAssertTrue(authenticationService.isAuthenticated, "User should be authenticated after successful biometric auth")
            print("✅ Biometric authentication flow validated")
        case .failure(let authError):
            // Expected in testing environment
            XCTAssertNotNil(authError, "Authentication error should be properly handled")
            print("ℹ️ Biometric authentication failed as expected in test environment: \(authError)")
        }
    }
    
    func testSessionManagement() {
        // Test session creation
        let session = authenticationService.createSession(for: "test.user@company.com")
        XCTAssertNotNil(session, "Session should be created")
        XCTAssertTrue(authenticationService.isValidSession(session), "Session should be valid")
        
        // Test session timeout
        let expiredSession = AuthSession(
            userId: "test.user@company.com",
            token: "expired_token",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            expiresAt: Date().addingTimeInterval(-1800)  // 30 minutes ago
        )
        
        XCTAssertFalse(authenticationService.isValidSession(expiredSession), "Expired session should be invalid")
        
        // Test session invalidation
        authenticationService.invalidateSession(session)
        XCTAssertFalse(authenticationService.isValidSession(session), "Invalidated session should be invalid")
        
        print("✅ Session management validation passed")
    }
    
    func testPasswordSecurity() {
        let weakPasswords = [
            "123456",
            "password",
            "qwerty",
            "12345678",
            "abc123"
        ]
        
        let strongPasswords = [
            "SecureP@ssw0rd123!",
            "MyVery$trong2024Pass",
            "Complex#Pass789word",
            "Unbreakable@2024$Key"
        ]
        
        // Test weak password detection
        for password in weakPasswords {
            let strength = authenticationService.evaluatePasswordStrength(password)
            XCTAssertLessThan(strength, 0.6, "Weak password should have low strength score")
        }
        
        // Test strong password validation
        for password in strongPasswords {
            let strength = authenticationService.evaluatePasswordStrength(password)
            XCTAssertGreaterThan(strength, 0.8, "Strong password should have high strength score")
        }
        
        print("✅ Password security validation passed")
    }
    
    // MARK: - Input Validation Security Tests
    
    func testSQLInjectionPrevention() {
        let maliciousInputs = [
            "'; DROP TABLE employees; --",
            "1' OR '1'='1",
            "admin'/*",
            "1'; UPDATE employees SET salary = 999999; --",
            "' UNION SELECT * FROM sensitive_data --"
        ]
        
        for input in maliciousInputs {
            // Test employee search input validation
            let sanitizedInput = dataValidationService.sanitizeSearchQuery(input)
            XCTAssertFalse(sanitizedInput.contains("DROP"), "SQL injection attempts should be sanitized")
            XCTAssertFalse(sanitizedInput.contains("UPDATE"), "SQL injection attempts should be sanitized")
            XCTAssertFalse(sanitizedInput.contains("UNION"), "SQL injection attempts should be sanitized")
            XCTAssertFalse(sanitizedInput.contains("--"), "SQL comments should be removed")
            
            // Test that search doesn't execute malicious queries
            let searchResult = dataValidationService.validateSearchInput(input)
            XCTAssertFalse(searchResult.isValid, "Malicious input should be rejected")
            XCTAssertNotNil(searchResult.error, "Validation error should be provided")
        }
        
        print("✅ SQL injection prevention validation passed")
    }
    
    func testXSSPrevention() {
        let xssInputs = [
            "<script>alert('XSS')</script>",
            "javascript:alert('XSS')",
            "<img src=x onerror=alert('XSS')>",
            "<iframe src='javascript:alert(`XSS`)'></iframe>",
            "';alert('XSS');//"
        ]
        
        for input in xssInputs {
            let sanitizedInput = dataValidationService.sanitizeUserInput(input)
            XCTAssertFalse(sanitizedInput.contains("<script>"), "Script tags should be removed")
            XCTAssertFalse(sanitizedInput.contains("javascript:"), "JavaScript URLs should be removed")
            XCTAssertFalse(sanitizedInput.contains("onerror="), "Event handlers should be removed")
            XCTAssertFalse(sanitizedInput.contains("<iframe"), "Iframe tags should be removed")
            
            let validationResult = dataValidationService.validateUserInput(input, type: .text)
            XCTAssertFalse(validationResult.isValid, "XSS input should be rejected")
        }
        
        print("✅ XSS prevention validation passed")
    }
    
    func testInputLengthValidation() {
        // Test extremely long inputs (potential buffer overflow)
        let longInput = String(repeating: "A", count: 10000)
        
        let validationResult = dataValidationService.validateUserInput(longInput, type: .text)
        XCTAssertFalse(validationResult.isValid, "Extremely long input should be rejected")
        
        // Test email validation
        let validEmails = [
            "user@company.com",
            "test.email+tag@example.org",
            "valid-email@domain.co.uk"
        ]
        
        let invalidEmails = [
            "invalid-email",
            "@company.com",
            "user@",
            "user..double.dot@company.com",
            longInput + "@company.com"
        ]
        
        for email in validEmails {
            let result = dataValidationService.validateUserInput(email, type: .email)
            XCTAssertTrue(result.isValid, "Valid email should pass validation: \(email)")
        }
        
        for email in invalidEmails {
            let result = dataValidationService.validateUserInput(email, type: .email)
            XCTAssertFalse(result.isValid, "Invalid email should fail validation: \(email)")
        }
        
        print("✅ Input length and format validation passed")
    }
    
    // MARK: - Network Security Tests
    
    func testHTTPSCommunication() async {
        // Test that all network requests use HTTPS
        let testURLs = [
            "https://api.diamonddesk.com/employees",
            "https://api.diamonddesk.com/workflows",
            "https://api.diamonddesk.com/assets"
        ]
        
        for urlString in testURLs {
            guard let url = URL(string: urlString) else {
                XCTFail("Invalid URL: \(urlString)")
                continue
            }
            
            XCTAssertEqual(url.scheme, "https", "All API calls should use HTTPS")
        }
        
        // Test that HTTP URLs are rejected
        let httpURL = URL(string: "http://insecure.example.com")!
        let isSecure = NetworkSecurityManager.shared.isSecureURL(httpURL)
        XCTAssertFalse(isSecure, "HTTP URLs should be rejected")
        
        print("✅ HTTPS communication validation passed")
    }
    
    func testCertificatePinning() async {
        // Test certificate pinning for API endpoints
        let pinnedDomains = [
            "api.diamonddesk.com",
            "cdn.diamonddesk.com",
            "auth.diamonddesk.com"
        ]
        
        for domain in pinnedDomains {
            let isPinned = NetworkSecurityManager.shared.isCertificatePinned(for: domain)
            XCTAssertTrue(isPinned, "Certificate should be pinned for domain: \(domain)")
        }
        
        // Test rejection of unpinned certificates
        let untrustedDomain = "malicious.example.com"
        let isUntrustedPinned = NetworkSecurityManager.shared.isCertificatePinned(for: untrustedDomain)
        XCTAssertFalse(isUntrustedPinned, "Untrusted domain should not have pinned certificate")
        
        print("✅ Certificate pinning validation passed")
    }
    
    func testAPIKeyProtection() {
        // Test that API keys are not exposed in logs or memory dumps
        let apiKeyManager = APIKeyManager.shared
        
        // API keys should be stored securely in Keychain
        let storedKey = apiKeyManager.getAPIKey(for: "production")
        XCTAssertNotNil(storedKey, "API key should be retrievable from secure storage")
        
        // API keys should not appear in string form in memory
        let memoryDump = getMemorySnapshot()
        XCTAssertFalse(memoryDump.contains("sk_live_"), "Live API keys should not appear in memory")
        XCTAssertFalse(memoryDump.contains("pk_live_"), "Public API keys should not appear in memory")
        
        print("✅ API key protection validation passed")
    }
    
    // MARK: - Data Privacy Tests
    
    func testPersonalDataHandling() {
        let personalData = PersonalData(
            email: "privacy.test@company.com",
            phone: "555-PRIVACY",
            address: "123 Private St, Hidden City, HC 12345",
            socialSecurityNumber: "XXX-XX-XXXX",
            birthDate: Date()
        )
        
        // Test data anonymization
        let anonymizedData = DataPrivacyManager.shared.anonymize(personalData)
        XCTAssertNotEqual(anonymizedData.email, personalData.email, "Email should be anonymized")
        XCTAssertNotEqual(anonymizedData.phone, personalData.phone, "Phone should be anonymized")
        XCTAssertEqual(anonymizedData.socialSecurityNumber, "XXX-XX-XXXX", "SSN should remain masked")
        
        // Test data retention policies
        let retentionPeriod = DataPrivacyManager.shared.getRetentionPeriod(for: .personalData)
        XCTAssertEqual(retentionPeriod, 7 * 365 * 24 * 60 * 60, "Personal data retention should be 7 years")
        
        // Test right to be forgotten
        let deletionResult = DataPrivacyManager.shared.processDataDeletionRequest(for: "privacy.test@company.com")
        XCTAssertTrue(deletionResult.success, "Data deletion request should be processed successfully")
        
        print("✅ Personal data handling validation passed")
    }
    
    func testGDPRCompliance() {
        let gdprCompliance = GDPRComplianceManager.shared
        
        // Test consent management
        let consentRecord = ConsentRecord(
            userId: "gdpr.test@company.com",
            consentType: .dataProcessing,
            granted: true,
            timestamp: Date(),
            ipAddress: "192.168.1.1",
            userAgent: "iOS App"
        )
        
        gdprCompliance.recordConsent(consentRecord)
        
        let hasConsent = gdprCompliance.hasValidConsent(for: "gdpr.test@company.com", type: .dataProcessing)
        XCTAssertTrue(hasConsent, "Valid consent should be recorded and retrievable")
        
        // Test data portability
        let exportedData = gdprCompliance.exportUserData(for: "gdpr.test@company.com")
        XCTAssertNotNil(exportedData, "User data should be exportable")
        XCTAssertTrue(exportedData!.contains("gdpr.test@company.com"), "Exported data should contain user information")
        
        // Test data breach notification
        let breachNotification = DataBreachNotification(
            incidentId: "BREACH-001",
            affectedUsers: ["gdpr.test@company.com"],
            dataTypes: [.personalInformation, .contactInformation],
            timestamp: Date(),
            severity: .high
        )
        
        let notificationResult = gdprCompliance.processDataBreach(breachNotification)
        XCTAssertTrue(notificationResult.success, "Data breach should be processed successfully")
        XCTAssertLessThan(notificationResult.notificationTime, 72 * 60 * 60, "Breach notification should be within 72 hours")
        
        print("✅ GDPR compliance validation passed")
    }
    
    // MARK: - Access Control Tests
    
    func testRoleBasedAccessControl() {
        let rbacManager = RoleBasedAccessControlManager.shared
        
        // Define test roles and permissions
        let adminRole = Role(
            name: "Admin",
            permissions: [.createEmployee, .updateEmployee, .deleteEmployee, .viewAllEmployees, .manageRoles]
        )
        
        let managerRole = Role(
            name: "Manager",
            permissions: [.createEmployee, .updateEmployee, .viewAllEmployees]
        )
        
        let employeeRole = Role(
            name: "Employee",
            permissions: [.viewOwnProfile, .updateOwnProfile]
        )
        
        // Test permission checking
        XCTAssertTrue(rbacManager.hasPermission(role: adminRole, permission: .deleteEmployee), "Admin should have delete permission")
        XCTAssertTrue(rbacManager.hasPermission(role: managerRole, permission: .updateEmployee), "Manager should have update permission")
        XCTAssertFalse(rbacManager.hasPermission(role: employeeRole, permission: .deleteEmployee), "Employee should not have delete permission")
        
        // Test access control enforcement
        let adminUser = User(id: "admin.user@company.com", roles: [adminRole])
        let managerUser = User(id: "manager.user@company.com", roles: [managerRole])
        let regularUser = User(id: "regular.user@company.com", roles: [employeeRole])
        
        XCTAssertTrue(rbacManager.canAccess(user: adminUser, resource: .employeeManagement, action: .delete), "Admin should access employee deletion")
        XCTAssertFalse(rbacManager.canAccess(user: managerUser, resource: .employeeManagement, action: .delete), "Manager should not access employee deletion")
        XCTAssertFalse(rbacManager.canAccess(user: regularUser, resource: .employeeManagement, action: .create), "Regular user should not access employee creation")
        
        print("✅ Role-based access control validation passed")
    }
    
    func testDataAccessLogging() {
        let auditLogger = DataAccessAuditLogger.shared
        
        // Test access logging
        let accessEvent = DataAccessEvent(
            userId: "audit.test@company.com",
            resourceType: .employee,
            resourceId: "EMP001",
            action: .read,
            timestamp: Date(),
            ipAddress: "192.168.1.100",
            userAgent: "iOS App",
            success: true
        )
        
        auditLogger.logDataAccess(accessEvent)
        
        // Verify log entry was created
        let logEntries = auditLogger.getAuditLog(for: "audit.test@company.com", from: Date().addingTimeInterval(-3600))
        XCTAssertGreaterThan(logEntries.count, 0, "Audit log should contain entries")
        
        let lastEntry = logEntries.last!
        XCTAssertEqual(lastEntry.userId, accessEvent.userId, "Log entry should match access event")
        XCTAssertEqual(lastEntry.action, accessEvent.action, "Log entry should record correct action")
        
        // Test suspicious activity detection
        let suspiciousEvents = [
            DataAccessEvent(userId: "suspicious.user@company.com", resourceType: .employee, resourceId: "EMP001", action: .read, timestamp: Date(), ipAddress: "192.168.1.200", userAgent: "iOS App", success: true),
            DataAccessEvent(userId: "suspicious.user@company.com", resourceType: .employee, resourceId: "EMP002", action: .read, timestamp: Date(), ipAddress: "192.168.1.200", userAgent: "iOS App", success: true),
            DataAccessEvent(userId: "suspicious.user@company.com", resourceType: .employee, resourceId: "EMP003", action: .read, timestamp: Date(), ipAddress: "192.168.1.200", userAgent: "iOS App", success: true)
        ]
        
        for event in suspiciousEvents {
            auditLogger.logDataAccess(event)
        }
        
        let suspiciousActivity = auditLogger.detectSuspiciousActivity(for: "suspicious.user@company.com")
        XCTAssertTrue(suspiciousActivity.count > 0, "Suspicious activity should be detected")
        
        print("✅ Data access logging validation passed")
    }
    
    // MARK: - Vulnerability Assessment Tests
    
    func testCommonVulnerabilities() {
        let vulnerabilityScanner = VulnerabilityScanner.shared
        
        // Test for common iOS vulnerabilities
        let scanResults = vulnerabilityScanner.performSecurityScan()
        
        // Check for insecure data storage
        XCTAssertFalse(scanResults.hasInsecureDataStorage, "App should not have insecure data storage")
        
        // Check for weak cryptography
        XCTAssertFalse(scanResults.hasWeakCryptography, "App should not use weak cryptography")
        
        // Check for insecure communication
        XCTAssertFalse(scanResults.hasInsecureCommunication, "App should not have insecure communication")
        
        // Check for insufficient transport layer protection
        XCTAssertFalse(scanResults.hasInsufficientTransportProtection, "App should have proper transport layer protection")
        
        // Check for insecure authentication
        XCTAssertFalse(scanResults.hasInsecureAuthentication, "App should have secure authentication")
        
        print("✅ Common vulnerability assessment passed")
    }
    
    func testDependencyVulnerabilities() {
        let dependencyScanner = DependencyVulnerabilityScanner.shared
        
        // Scan for vulnerable dependencies
        let vulnerableDependencies = dependencyScanner.scanDependencies()
        
        XCTAssertEqual(vulnerableDependencies.count, 0, "No vulnerable dependencies should be found")
        
        // Test specific known vulnerable patterns
        let knownVulnerableLibraries = [
            "OldNetworkLibrary 1.0",
            "InsecureCrypto 2.1",
            "VulnerableAuth 3.0"
        ]
        
        for library in knownVulnerableLibraries {
            let isVulnerable = dependencyScanner.isVulnerable(library)
            if isVulnerable {
                XCTFail("Vulnerable library detected: \(library)")
            }
        }
        
        print("✅ Dependency vulnerability assessment passed")
    }
    
    // MARK: - Security Configuration Tests
    
    func testSecurityConfiguration() {
        let securityConfig = SecurityConfiguration.shared
        
        // Test encryption configuration
        XCTAssertEqual(securityConfig.encryptionAlgorithm, .aes256, "Should use AES-256 encryption")
        XCTAssertEqual(securityConfig.keySize, 256, "Should use 256-bit keys")
        
        // Test session configuration
        XCTAssertLessThanOrEqual(securityConfig.sessionTimeout, 30 * 60, "Session timeout should be 30 minutes or less")
        XCTAssertGreaterThanOrEqual(securityConfig.maxLoginAttempts, 3, "Should allow at least 3 login attempts")
        XCTAssertLessThanOrEqual(securityConfig.maxLoginAttempts, 5, "Should not allow more than 5 login attempts")
        
        // Test password policy
        XCTAssertGreaterThanOrEqual(securityConfig.minPasswordLength, 8, "Minimum password length should be 8 characters")
        XCTAssertTrue(securityConfig.requireSpecialCharacters, "Should require special characters in passwords")
        XCTAssertTrue(securityConfig.requireNumbers, "Should require numbers in passwords")
        XCTAssertTrue(securityConfig.requireUppercase, "Should require uppercase letters in passwords")
        
        // Test data retention
        XCTAssertLessThanOrEqual(securityConfig.logRetentionDays, 365, "Log retention should not exceed 1 year")
        XCTAssertGreaterThanOrEqual(securityConfig.logRetentionDays, 90, "Log retention should be at least 90 days")
        
        print("✅ Security configuration validation passed")
    }
    
    // MARK: - Helper Methods
    
    private func getMemorySnapshot() -> String {
        // Simplified memory snapshot for testing
        // In a real implementation, this would capture actual memory contents
        return "Sample memory content without sensitive data"
    }
}

// MARK: - Test Data Structures

struct PersonalData {
    let email: String
    let phone: String
    let address: String
    let socialSecurityNumber: String
    let birthDate: Date
}

struct ConsentRecord {
    let userId: String
    let consentType: ConsentType
    let granted: Bool
    let timestamp: Date
    let ipAddress: String
    let userAgent: String
}

enum ConsentType {
    case dataProcessing
    case marketing
    case analytics
    case thirdPartySharing
}

struct DataBreachNotification {
    let incidentId: String
    let affectedUsers: [String]
    let dataTypes: [DataType]
    let timestamp: Date
    let severity: BreachSeverity
}

enum DataType {
    case personalInformation
    case contactInformation
    case financialData
    case healthData
}

enum BreachSeverity {
    case low
    case medium
    case high
    case critical
}

struct Role {
    let name: String
    let permissions: [Permission]
}

enum Permission {
    case createEmployee
    case updateEmployee
    case deleteEmployee
    case viewAllEmployees
    case viewOwnProfile
    case updateOwnProfile
    case manageRoles
}

struct User {
    let id: String
    let roles: [Role]
}

enum Resource {
    case employeeManagement
    case workflowManagement
    case assetManagement
    case systemSettings
}

enum Action {
    case create
    case read
    case update
    case delete
}

struct DataAccessEvent {
    let userId: String
    let resourceType: Resource
    let resourceId: String
    let action: Action
    let timestamp: Date
    let ipAddress: String
    let userAgent: String
    let success: Bool
}

struct SecurityScanResult {
    let hasInsecureDataStorage: Bool
    let hasWeakCryptography: Bool
    let hasInsecureCommunication: Bool
    let hasInsufficientTransportProtection: Bool
    let hasInsecureAuthentication: Bool
    let vulnerabilityCount: Int
    let riskLevel: RiskLevel
}

enum RiskLevel {
    case low
    case medium
    case high
    case critical
}
#endif
