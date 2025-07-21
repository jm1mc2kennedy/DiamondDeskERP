import Foundation
import CryptoKit
import Security

/// Comprehensive security management system for DiamondDeskERP
final class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var securityStatus: SecurityStatus = .unknown
    @Published var lastSecurityScan: Date?
    @Published var activeThreats: [SecurityThreat] = []
    
    private let encryptionService: EncryptionService
    private let authenticationService: AuthenticationService
    private let dataValidationService: DataValidationService
    private let auditLogger: SecurityAuditLogger
    
    private init() {
        self.encryptionService = EncryptionService()
        self.authenticationService = AuthenticationService()
        self.dataValidationService = DataValidationService()
        self.auditLogger = SecurityAuditLogger()
        
        performInitialSecurityCheck()
    }
    
    // MARK: - Security Status Management
    
    func performSecurityAudit() async -> SecurityAuditReport {
        auditLogger.log(event: SecurityEvent(type: .auditStarted, timestamp: Date()))
        
        let report = SecurityAuditReport()
        
        // Data encryption audit
        report.encryptionStatus = await auditDataEncryption()
        
        // Authentication security audit
        report.authenticationStatus = await auditAuthentication()
        
        // Input validation audit
        report.inputValidationStatus = await auditInputValidation()
        
        // Network security audit
        report.networkSecurityStatus = await auditNetworkSecurity()
        
        // Access control audit
        report.accessControlStatus = await auditAccessControl()
        
        // Privacy compliance audit
        report.privacyComplianceStatus = await auditPrivacyCompliance()
        
        // Vulnerability assessment
        report.vulnerabilityStatus = await performVulnerabilityAssessment()
        
        // Calculate overall security score
        report.overallSecurityScore = calculateSecurityScore(report)
        
        // Update security status
        updateSecurityStatus(based: report)
        
        lastSecurityScan = Date()
        auditLogger.log(event: SecurityEvent(type: .auditCompleted, timestamp: Date()))
        
        return report
    }
    
    private func performInitialSecurityCheck() {
        Task {
            let report = await performSecurityAudit()
            await MainActor.run {
                self.securityStatus = report.overallSecurityScore >= 0.8 ? .secure : .vulnerable
            }
        }
    }
    
    private func updateSecurityStatus(based report: SecurityAuditReport) {
        let score = report.overallSecurityScore
        
        switch score {
        case 0.9...1.0:
            securityStatus = .excellent
        case 0.8..<0.9:
            securityStatus = .secure
        case 0.6..<0.8:
            securityStatus = .moderate
        case 0.4..<0.6:
            securityStatus = .vulnerable
        default:
            securityStatus = .critical
        }
        
        // Identify active threats
        activeThreats = identifyActiveThreats(from: report)
    }
    
    // MARK: - Security Audit Components
    
    private func auditDataEncryption() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        // Check encryption algorithms
        if !encryptionService.isUsingStrongEncryption() {
            issues.append(SecurityIssue(
                type: .weakEncryption,
                severity: .high,
                description: "Weak encryption algorithms detected",
                recommendation: "Upgrade to AES-256 or equivalent"
            ))
            score -= 0.3
        }
        
        // Check key management
        if !encryptionService.isKeyManagementSecure() {
            issues.append(SecurityIssue(
                type: .insecureKeyManagement,
                severity: .critical,
                description: "Insecure key management practices",
                recommendation: "Implement secure key storage and rotation"
            ))
            score -= 0.5
        }
        
        // Check data at rest encryption
        if !encryptionService.isDataAtRestEncrypted() {
            issues.append(SecurityIssue(
                type: .unencryptedDataAtRest,
                severity: .high,
                description: "Sensitive data not encrypted at rest",
                recommendation: "Enable encryption for all sensitive data storage"
            ))
            score -= 0.4
        }
        
        return SecurityComponentStatus(
            component: .dataEncryption,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    private func auditAuthentication() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        // Check password policies
        if !authenticationService.hasStrongPasswordPolicy() {
            issues.append(SecurityIssue(
                type: .weakPasswordPolicy,
                severity: .medium,
                description: "Password policy does not meet security standards",
                recommendation: "Enforce stronger password requirements"
            ))
            score -= 0.2
        }
        
        // Check multi-factor authentication
        if !authenticationService.isMFAEnabled() {
            issues.append(SecurityIssue(
                type: .missingMFA,
                severity: .high,
                description: "Multi-factor authentication not enabled",
                recommendation: "Implement biometric or SMS-based MFA"
            ))
            score -= 0.3
        }
        
        // Check session management
        if !authenticationService.hasSecureSessionManagement() {
            issues.append(SecurityIssue(
                type: .insecureSessionManagement,
                severity: .medium,
                description: "Session management has security weaknesses",
                recommendation: "Implement secure session tokens and timeouts"
            ))
            score -= 0.2
        }
        
        return SecurityComponentStatus(
            component: .authentication,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    private func auditInputValidation() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        // Check SQL injection protection
        if !dataValidationService.hasSQLInjectionProtection() {
            issues.append(SecurityIssue(
                type: .sqlInjectionVulnerability,
                severity: .critical,
                description: "Application vulnerable to SQL injection attacks",
                recommendation: "Implement parameterized queries and input sanitization"
            ))
            score -= 0.6
        }
        
        // Check XSS protection
        if !dataValidationService.hasXSSProtection() {
            issues.append(SecurityIssue(
                type: .xssVulnerability,
                severity: .high,
                description: "Application vulnerable to XSS attacks",
                recommendation: "Implement input sanitization and output encoding"
            ))
            score -= 0.4
        }
        
        // Check input length validation
        if !dataValidationService.hasInputLengthValidation() {
            issues.append(SecurityIssue(
                type: .inputValidationWeakness,
                severity: .medium,
                description: "Insufficient input length validation",
                recommendation: "Implement proper input length and format validation"
            ))
            score -= 0.2
        }
        
        return SecurityComponentStatus(
            component: .inputValidation,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    private func auditNetworkSecurity() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        // Check HTTPS usage
        if !NetworkSecurityManager.shared.isHTTPSEnforced() {
            issues.append(SecurityIssue(
                type: .insecureTransport,
                severity: .high,
                description: "Not all communications use HTTPS",
                recommendation: "Enforce HTTPS for all network communications"
            ))
            score -= 0.4
        }
        
        // Check certificate pinning
        if !NetworkSecurityManager.shared.isCertificatePinningEnabled() {
            issues.append(SecurityIssue(
                type: .missingCertificatePinning,
                severity: .medium,
                description: "Certificate pinning not implemented",
                recommendation: "Implement certificate pinning for API endpoints"
            ))
            score -= 0.2
        }
        
        // Check API key protection
        if !APIKeyManager.shared.areAPIKeysSecure() {
            issues.append(SecurityIssue(
                type: .exposedAPIKeys,
                severity: .critical,
                description: "API keys may be exposed",
                recommendation: "Store API keys securely and rotate regularly"
            ))
            score -= 0.5
        }
        
        return SecurityComponentStatus(
            component: .networkSecurity,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    private func auditAccessControl() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        // Check role-based access control
        if !RoleBasedAccessControlManager.shared.isProperlyConfigured() {
            issues.append(SecurityIssue(
                type: .inadequateAccessControl,
                severity: .high,
                description: "Role-based access control not properly configured",
                recommendation: "Implement and configure proper RBAC system"
            ))
            score -= 0.4
        }
        
        // Check privilege escalation protection
        if !RoleBasedAccessControlManager.shared.hasPrivilegeEscalationProtection() {
            issues.append(SecurityIssue(
                type: .privilegeEscalationRisk,
                severity: .high,
                description: "Risk of privilege escalation attacks",
                recommendation: "Implement strict privilege separation and validation"
            ))
            score -= 0.3
        }
        
        // Check data access logging
        if !DataAccessAuditLogger.shared.isProperlyConfigured() {
            issues.append(SecurityIssue(
                type: .insufficientAuditLogging,
                severity: .medium,
                description: "Insufficient audit logging for data access",
                recommendation: "Implement comprehensive data access logging"
            ))
            score -= 0.2
        }
        
        return SecurityComponentStatus(
            component: .accessControl,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    private func auditPrivacyCompliance() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        // Check GDPR compliance
        if !GDPRComplianceManager.shared.isCompliant() {
            issues.append(SecurityIssue(
                type: .gdprNonCompliance,
                severity: .high,
                description: "Application not fully GDPR compliant",
                recommendation: "Implement missing GDPR requirements"
            ))
            score -= 0.4
        }
        
        // Check data retention policies
        if !DataPrivacyManager.shared.hasProperRetentionPolicies() {
            issues.append(SecurityIssue(
                type: .inadequateDataRetention,
                severity: .medium,
                description: "Data retention policies not properly implemented",
                recommendation: "Implement and enforce data retention policies"
            ))
            score -= 0.2
        }
        
        // Check consent management
        if !ConsentManager.shared.isProperlyImplemented() {
            issues.append(SecurityIssue(
                type: .inadequateConsentManagement,
                severity: .medium,
                description: "Consent management system inadequate",
                recommendation: "Implement proper consent collection and management"
            ))
            score -= 0.2
        }
        
        return SecurityComponentStatus(
            component: .privacyCompliance,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    private func performVulnerabilityAssessment() async -> SecurityComponentStatus {
        var issues: [SecurityIssue] = []
        var score: Double = 1.0
        
        let scanner = VulnerabilityScanner.shared
        let scanResults = scanner.performComprehensiveScan()
        
        // Check for critical vulnerabilities
        if scanResults.criticalVulnerabilities.count > 0 {
            issues.append(SecurityIssue(
                type: .criticalVulnerability,
                severity: .critical,
                description: "\(scanResults.criticalVulnerabilities.count) critical vulnerabilities found",
                recommendation: "Immediately address all critical vulnerabilities"
            ))
            score -= 0.8
        }
        
        // Check for high-severity vulnerabilities
        if scanResults.highSeverityVulnerabilities.count > 0 {
            issues.append(SecurityIssue(
                type: .highSeverityVulnerability,
                severity: .high,
                description: "\(scanResults.highSeverityVulnerabilities.count) high-severity vulnerabilities found",
                recommendation: "Address high-severity vulnerabilities within 30 days"
            ))
            score -= 0.4
        }
        
        // Check for medium-severity vulnerabilities
        if scanResults.mediumSeverityVulnerabilities.count > 5 {
            issues.append(SecurityIssue(
                type: .mediumSeverityVulnerability,
                severity: .medium,
                description: "\(scanResults.mediumSeverityVulnerabilities.count) medium-severity vulnerabilities found",
                recommendation: "Address medium-severity vulnerabilities within 90 days"
            ))
            score -= 0.2
        }
        
        return SecurityComponentStatus(
            component: .vulnerabilityAssessment,
            score: max(0, score),
            issues: issues,
            lastChecked: Date()
        )
    }
    
    // MARK: - Security Score Calculation
    
    private func calculateSecurityScore(_ report: SecurityAuditReport) -> Double {
        let weights: [SecurityComponent: Double] = [
            .dataEncryption: 0.20,
            .authentication: 0.18,
            .inputValidation: 0.15,
            .networkSecurity: 0.15,
            .accessControl: 0.12,
            .privacyCompliance: 0.10,
            .vulnerabilityAssessment: 0.10
        ]
        
        var totalScore: Double = 0
        var totalWeight: Double = 0
        
        for (component, weight) in weights {
            if let status = report.getStatus(for: component) {
                totalScore += status.score * weight
                totalWeight += weight
            }
        }
        
        return totalWeight > 0 ? totalScore / totalWeight : 0
    }
    
    private func identifyActiveThreats(from report: SecurityAuditReport) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        for status in report.getAllStatuses() {
            for issue in status.issues {
                if issue.severity == .critical || issue.severity == .high {
                    threats.append(SecurityThreat(
                        id: UUID(),
                        type: issue.type,
                        severity: issue.severity,
                        description: issue.description,
                        detectedAt: Date(),
                        status: .active
                    ))
                }
            }
        }
        
        return threats
    }
    
    // MARK: - Threat Response
    
    func respondToThreat(_ threat: SecurityThreat) async {
        auditLogger.log(event: SecurityEvent(type: .threatDetected, threat: threat, timestamp: Date()))
        
        switch threat.severity {
        case .critical:
            await handleCriticalThreat(threat)
        case .high:
            await handleHighSeverityThreat(threat)
        case .medium:
            await handleMediumSeverityThreat(threat)
        case .low:
            await handleLowSeverityThreat(threat)
        }
        
        // Update threat status
        if let index = activeThreats.firstIndex(where: { $0.id == threat.id }) {
            activeThreats[index].status = .mitigated
        }
    }
    
    private func handleCriticalThreat(_ threat: SecurityThreat) async {
        // Immediate response for critical threats
        auditLogger.log(event: SecurityEvent(type: .emergencyProtocolActivated, threat: threat, timestamp: Date()))
        
        // Lock down system if necessary
        // Send immediate alerts
        // Begin incident response
    }
    
    private func handleHighSeverityThreat(_ threat: SecurityThreat) async {
        // Urgent response for high-severity threats
        auditLogger.log(event: SecurityEvent(type: .threatMitigationStarted, threat: threat, timestamp: Date()))
        
        // Apply immediate mitigations
        // Schedule detailed investigation
    }
    
    private func handleMediumSeverityThreat(_ threat: SecurityThreat) async {
        // Standard response for medium-severity threats
        auditLogger.log(event: SecurityEvent(type: .threatMitigationStarted, threat: threat, timestamp: Date()))
        
        // Schedule remediation
        // Monitor for escalation
    }
    
    private func handleLowSeverityThreat(_ threat: SecurityThreat) async {
        // Monitor low-severity threats
        auditLogger.log(event: SecurityEvent(type: .threatLogged, threat: threat, timestamp: Date()))
        
        // Add to monitoring queue
    }
}

// MARK: - Data Models

enum SecurityStatus {
    case unknown
    case excellent
    case secure
    case moderate
    case vulnerable
    case critical
}

enum SecurityComponent {
    case dataEncryption
    case authentication
    case inputValidation
    case networkSecurity
    case accessControl
    case privacyCompliance
    case vulnerabilityAssessment
}

enum SecurityIssueType {
    case weakEncryption
    case insecureKeyManagement
    case unencryptedDataAtRest
    case weakPasswordPolicy
    case missingMFA
    case insecureSessionManagement
    case sqlInjectionVulnerability
    case xssVulnerability
    case inputValidationWeakness
    case insecureTransport
    case missingCertificatePinning
    case exposedAPIKeys
    case inadequateAccessControl
    case privilegeEscalationRisk
    case insufficientAuditLogging
    case gdprNonCompliance
    case inadequateDataRetention
    case inadequateConsentManagement
    case criticalVulnerability
    case highSeverityVulnerability
    case mediumSeverityVulnerability
}

enum SecuritySeverity {
    case low
    case medium
    case high
    case critical
}

struct SecurityIssue {
    let type: SecurityIssueType
    let severity: SecuritySeverity
    let description: String
    let recommendation: String
    let detectedAt: Date = Date()
}

struct SecurityComponentStatus {
    let component: SecurityComponent
    let score: Double
    let issues: [SecurityIssue]
    let lastChecked: Date
}

class SecurityAuditReport {
    var encryptionStatus: SecurityComponentStatus?
    var authenticationStatus: SecurityComponentStatus?
    var inputValidationStatus: SecurityComponentStatus?
    var networkSecurityStatus: SecurityComponentStatus?
    var accessControlStatus: SecurityComponentStatus?
    var privacyComplianceStatus: SecurityComponentStatus?
    var vulnerabilityStatus: SecurityComponentStatus?
    var overallSecurityScore: Double = 0
    
    func getStatus(for component: SecurityComponent) -> SecurityComponentStatus? {
        switch component {
        case .dataEncryption: return encryptionStatus
        case .authentication: return authenticationStatus
        case .inputValidation: return inputValidationStatus
        case .networkSecurity: return networkSecurityStatus
        case .accessControl: return accessControlStatus
        case .privacyCompliance: return privacyComplianceStatus
        case .vulnerabilityAssessment: return vulnerabilityStatus
        }
    }
    
    func getAllStatuses() -> [SecurityComponentStatus] {
        return [
            encryptionStatus,
            authenticationStatus,
            inputValidationStatus,
            networkSecurityStatus,
            accessControlStatus,
            privacyComplianceStatus,
            vulnerabilityStatus
        ].compactMap { $0 }
    }
}

struct SecurityThreat {
    let id: UUID
    let type: SecurityIssueType
    let severity: SecuritySeverity
    let description: String
    let detectedAt: Date
    var status: ThreatStatus
}

enum ThreatStatus {
    case active
    case investigating
    case mitigated
    case resolved
}

struct SecurityEvent {
    let type: SecurityEventType
    let threat: SecurityThreat?
    let timestamp: Date
    let details: [String: Any]?
    
    init(type: SecurityEventType, threat: SecurityThreat? = nil, timestamp: Date, details: [String: Any]? = nil) {
        self.type = type
        self.threat = threat
        self.timestamp = timestamp
        self.details = details
    }
}

enum SecurityEventType {
    case auditStarted
    case auditCompleted
    case threatDetected
    case threatMitigated
    case threatLogged
    case threatMitigationStarted
    case emergencyProtocolActivated
    case securityBreach
    case unauthorizedAccess
    case suspiciousActivity
}

// MARK: - Security Services

final class SecurityAuditLogger {
    private var events: [SecurityEvent] = []
    
    func log(event: SecurityEvent) {
        events.append(event)
        
        // In production, this would write to secure logging system
        print("🔒 Security Event: \(event.type) at \(event.timestamp)")
        
        if let threat = event.threat {
            print("   Threat: \(threat.description) (Severity: \(threat.severity))")
        }
    }
    
    func getEvents(from startDate: Date, to endDate: Date) -> [SecurityEvent] {
        return events.filter { event in
            event.timestamp >= startDate && event.timestamp <= endDate
        }
    }
    
    func getEvents(for threatType: SecurityIssueType) -> [SecurityEvent] {
        return events.filter { event in
            event.threat?.type == threatType
        }
    }
}
