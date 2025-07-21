import SwiftUI

struct SecurityConfigurationView: View {
    @StateObject private var configManager = SecurityConfigurationManager()
    @State private var showingPasswordPolicy = false
    @State private var showingEncryptionSettings = false
    @State private var showingNetworkSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                // Authentication Configuration
                Section("Authentication Settings") {
                    NavigationLink("Password Policy", destination: PasswordPolicyView(config: configManager))
                    
                    Toggle("Require Biometric Authentication", isOn: $configManager.requireBiometric)
                    
                    Toggle("Enable Two-Factor Authentication", isOn: $configManager.enableTwoFactor)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Session Timeout")
                            Spacer()
                            Text("\(configManager.sessionTimeoutMinutes) min")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(configManager.sessionTimeoutMinutes) },
                                set: { configManager.sessionTimeoutMinutes = Int($0) }
                            ),
                            in: 5...120,
                            step: 5
                        )
                    }
                }
                
                // Data Protection Configuration
                Section("Data Protection") {
                    NavigationLink("Encryption Settings", destination: EncryptionSettingsView(config: configManager))
                    
                    Toggle("Encrypt Data at Rest", isOn: $configManager.encryptDataAtRest)
                    
                    Toggle("Encrypt Network Communications", isOn: $configManager.encryptNetworkComms)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Data Retention Period")
                            Spacer()
                            Text("\(configManager.dataRetentionDays) days")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(configManager.dataRetentionDays) },
                                set: { configManager.dataRetentionDays = Int($0) }
                            ),
                            in: 30...730,
                            step: 30
                        )
                    }
                }
                
                // Network Security Configuration
                Section("Network Security") {
                    NavigationLink("Network Settings", destination: NetworkSecuritySettingsView(config: configManager))
                    
                    Toggle("Enforce HTTPS", isOn: $configManager.enforceHTTPS)
                    
                    Toggle("Certificate Pinning", isOn: $configManager.enableCertificatePinning)
                    
                    Toggle("Network Monitoring", isOn: $configManager.enableNetworkMonitoring)
                }
                
                // Privacy Configuration
                Section("Privacy Settings") {
                    Toggle("GDPR Compliance Mode", isOn: $configManager.gdprComplianceMode)
                    
                    Toggle("Data Minimization", isOn: $configManager.dataMinimization)
                    
                    Toggle("Anonymous Analytics", isOn: $configManager.anonymousAnalytics)
                    
                    Picker("Privacy Level", selection: $configManager.privacyLevel) {
                        ForEach(PrivacyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
                
                // Security Monitoring Configuration
                Section("Security Monitoring") {
                    Toggle("Real-time Threat Detection", isOn: $configManager.enableThreatDetection)
                    
                    Toggle("Vulnerability Scanning", isOn: $configManager.enableVulnerabilityScanning)
                    
                    Toggle("Audit Logging", isOn: $configManager.enableAuditLogging)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Log Retention Period")
                            Spacer()
                            Text("\(configManager.logRetentionDays) days")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(configManager.logRetentionDays) },
                                set: { configManager.logRetentionDays = Int($0) }
                            ),
                            in: 7...365,
                            step: 7
                        )
                    }
                }
                
                // Actions
                Section("Actions") {
                    Button("Export Security Configuration") {
                        configManager.exportConfiguration()
                    }
                    
                    Button("Import Security Configuration") {
                        configManager.importConfiguration()
                    }
                    
                    Button("Reset to Defaults") {
                        configManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Security Configuration")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        configManager.saveConfiguration()
                    }
                }
            }
        }
    }
}

// MARK: - Password Policy View

struct PasswordPolicyView: View {
    @ObservedObject var config: SecurityConfigurationManager
    
    var body: some View {
        Form {
            Section("Password Requirements") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Minimum Length")
                        Spacer()
                        Text("\(config.minPasswordLength)")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(config.minPasswordLength) },
                            set: { config.minPasswordLength = Int($0) }
                        ),
                        in: 6...20,
                        step: 1
                    )
                }
                
                Toggle("Require Uppercase Letters", isOn: $config.requireUppercase)
                
                Toggle("Require Lowercase Letters", isOn: $config.requireLowercase)
                
                Toggle("Require Numbers", isOn: $config.requireNumbers)
                
                Toggle("Require Special Characters", isOn: $config.requireSpecialChars)
                
                Toggle("Prevent Common Passwords", isOn: $config.preventCommonPasswords)
            }
            
            Section("Password History") {
                Toggle("Enable Password History", isOn: $config.enablePasswordHistory)
                
                if config.enablePasswordHistory {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Remember Last Passwords")
                            Spacer()
                            Text("\(config.passwordHistoryCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(config.passwordHistoryCount) },
                                set: { config.passwordHistoryCount = Int($0) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                    }
                }
            }
            
            Section("Password Expiry") {
                Toggle("Enable Password Expiry", isOn: $config.enablePasswordExpiry)
                
                if config.enablePasswordExpiry {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Password Expires After")
                            Spacer()
                            Text("\(config.passwordExpiryDays) days")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(config.passwordExpiryDays) },
                                set: { config.passwordExpiryDays = Int($0) }
                            ),
                            in: 30...365,
                            step: 30
                        )
                    }
                }
            }
        }
        .navigationTitle("Password Policy")
    }
}

// MARK: - Encryption Settings View

struct EncryptionSettingsView: View {
    @ObservedObject var config: SecurityConfigurationManager
    
    var body: some View {
        Form {
            Section("Encryption Algorithms") {
                Picker("Primary Algorithm", selection: $config.primaryEncryptionAlgorithm) {
                    ForEach(EncryptionAlgorithmType.allCases, id: \.self) { algorithm in
                        Text(algorithm.displayName).tag(algorithm)
                    }
                }
                
                Picker("Key Size", selection: $config.encryptionKeySize) {
                    ForEach(EncryptionKeySize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
            }
            
            Section("Key Management") {
                Toggle("Automatic Key Rotation", isOn: $config.automaticKeyRotation)
                
                if config.automaticKeyRotation {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Key Rotation Interval")
                            Spacer()
                            Text("\(config.keyRotationDays) days")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(config.keyRotationDays) },
                                set: { config.keyRotationDays = Int($0) }
                            ),
                            in: 30...365,
                            step: 30
                        )
                    }
                }
                
                Toggle("Hardware Security Module", isOn: $config.useHSM)
                
                Toggle("Key Escrow", isOn: $config.enableKeyEscrow)
            }
            
            Section("Data Classification") {
                ForEach(DataClassification.allCases, id: \.self) { classification in
                    HStack {
                        Text(classification.displayName)
                        Spacer()
                        Toggle("", isOn: binding(for: classification))
                            .labelsHidden()
                    }
                }
            }
            
            Section("Actions") {
                Button("Rotate All Keys Now") {
                    config.rotateAllKeys()
                }
                
                Button("Generate New Master Key") {
                    config.generateNewMasterKey()
                }
                .foregroundColor(.orange)
                
                Button("Emergency Key Reset") {
                    config.emergencyKeyReset()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Encryption Settings")
    }
    
    private func binding(for classification: DataClassification) -> Binding<Bool> {
        Binding(
            get: { config.encryptedDataTypes.contains(classification) },
            set: { isEnabled in
                if isEnabled {
                    config.encryptedDataTypes.insert(classification)
                } else {
                    config.encryptedDataTypes.remove(classification)
                }
            }
        )
    }
}

// MARK: - Network Security Settings View

struct NetworkSecuritySettingsView: View {
    @ObservedObject var config: SecurityConfigurationManager
    
    var body: some View {
        Form {
            Section("Protocol Settings") {
                Picker("Minimum TLS Version", selection: $config.minimumTLSVersion) {
                    ForEach(TLSVersion.allCases, id: \.self) { version in
                        Text(version.displayName).tag(version)
                    }
                }
                
                Toggle("Perfect Forward Secrecy", isOn: $config.requirePFS)
                
                Toggle("HSTS (HTTP Strict Transport Security)", isOn: $config.enableHSTS)
            }
            
            Section("Certificate Management") {
                Toggle("Certificate Validation", isOn: $config.validateCertificates)
                
                Toggle("Certificate Transparency", isOn: $config.requireCertificateTransparency)
                
                Toggle("OCSP Stapling", isOn: $config.enableOCSPStapling)
                
                Button("Manage Pinned Certificates") {
                    config.managePinnedCertificates()
                }
            }
            
            Section("Network Monitoring") {
                Toggle("DNS Security (DNSSEC)", isOn: $config.enableDNSSEC)
                
                Toggle("Network Anomaly Detection", isOn: $config.enableAnomalyDetection)
                
                Toggle("Traffic Analysis", isOn: $config.enableTrafficAnalysis)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Connection Timeout")
                        Spacer()
                        Text("\(config.connectionTimeoutSeconds)s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(config.connectionTimeoutSeconds) },
                            set: { config.connectionTimeoutSeconds = Int($0) }
                        ),
                        in: 10...120,
                        step: 10
                    )
                }
            }
            
            Section("Firewall Rules") {
                Toggle("Application Firewall", isOn: $config.enableApplicationFirewall)
                
                Button("Configure Allowed Domains") {
                    config.configureAllowedDomains()
                }
                
                Button("Configure Blocked IPs") {
                    config.configureBlockedIPs()
                }
            }
        }
        .navigationTitle("Network Security")
    }
}

// MARK: - Security Configuration Manager

class SecurityConfigurationManager: ObservableObject {
    // Authentication Settings
    @Published var requireBiometric = true
    @Published var enableTwoFactor = false
    @Published var sessionTimeoutMinutes = 30
    
    // Password Policy
    @Published var minPasswordLength = 8
    @Published var requireUppercase = true
    @Published var requireLowercase = true
    @Published var requireNumbers = true
    @Published var requireSpecialChars = true
    @Published var preventCommonPasswords = true
    @Published var enablePasswordHistory = true
    @Published var passwordHistoryCount = 5
    @Published var enablePasswordExpiry = false
    @Published var passwordExpiryDays = 90
    
    // Data Protection
    @Published var encryptDataAtRest = true
    @Published var encryptNetworkComms = true
    @Published var dataRetentionDays = 365
    @Published var primaryEncryptionAlgorithm = EncryptionAlgorithmType.aes256GCM
    @Published var encryptionKeySize = EncryptionKeySize.bits256
    @Published var automaticKeyRotation = true
    @Published var keyRotationDays = 90
    @Published var useHSM = false
    @Published var enableKeyEscrow = false
    @Published var encryptedDataTypes: Set<DataClassification> = [.confidential, .secret]
    
    // Network Security
    @Published var enforceHTTPS = true
    @Published var enableCertificatePinning = true
    @Published var enableNetworkMonitoring = true
    @Published var minimumTLSVersion = TLSVersion.v1_2
    @Published var requirePFS = true
    @Published var enableHSTS = true
    @Published var validateCertificates = true
    @Published var requireCertificateTransparency = true
    @Published var enableOCSPStapling = true
    @Published var enableDNSSEC = true
    @Published var enableAnomalyDetection = true
    @Published var enableTrafficAnalysis = false
    @Published var connectionTimeoutSeconds = 30
    @Published var enableApplicationFirewall = true
    
    // Privacy Settings
    @Published var gdprComplianceMode = true
    @Published var dataMinimization = true
    @Published var anonymousAnalytics = true
    @Published var privacyLevel = PrivacyLevel.high
    
    // Security Monitoring
    @Published var enableThreatDetection = true
    @Published var enableVulnerabilityScanning = true
    @Published var enableAuditLogging = true
    @Published var logRetentionDays = 90
    
    func saveConfiguration() {
        // Save configuration to secure storage
        let config = SecurityConfiguration(
            requireBiometric: requireBiometric,
            enableTwoFactor: enableTwoFactor,
            sessionTimeoutMinutes: sessionTimeoutMinutes,
            minPasswordLength: minPasswordLength,
            encryptDataAtRest: encryptDataAtRest,
            enforceHTTPS: enforceHTTPS,
            gdprComplianceMode: gdprComplianceMode,
            enableThreatDetection: enableThreatDetection
        )
        
        // Store in Keychain or secure UserDefaults
        storeSecureConfiguration(config)
        
        print("🔐 Security configuration saved")
    }
    
    func exportConfiguration() {
        // Export configuration for backup or transfer
        print("📤 Exporting security configuration")
    }
    
    func importConfiguration() {
        // Import configuration from file
        print("📥 Importing security configuration")
    }
    
    func resetToDefaults() {
        // Reset all settings to secure defaults
        requireBiometric = true
        enableTwoFactor = false
        sessionTimeoutMinutes = 30
        minPasswordLength = 8
        encryptDataAtRest = true
        enforceHTTPS = true
        gdprComplianceMode = true
        enableThreatDetection = true
        
        print("🔄 Security configuration reset to defaults")
    }
    
    func rotateAllKeys() {
        // Rotate all encryption keys
        print("🔑 Rotating all encryption keys")
    }
    
    func generateNewMasterKey() {
        // Generate new master encryption key
        print("🗝️ Generating new master key")
    }
    
    func emergencyKeyReset() {
        // Emergency key reset procedure
        print("🚨 Emergency key reset initiated")
    }
    
    func managePinnedCertificates() {
        // Manage pinned certificates
        print("📜 Managing pinned certificates")
    }
    
    func configureAllowedDomains() {
        // Configure allowed domains
        print("🌐 Configuring allowed domains")
    }
    
    func configureBlockedIPs() {
        // Configure blocked IP addresses
        print("🚫 Configuring blocked IPs")
    }
    
    private func storeSecureConfiguration(_ config: SecurityConfiguration) {
        // Store configuration securely
        let keychain = KeychainManager.shared
        
        do {
            let data = try JSONEncoder().encode(config)
            keychain.store(data, for: "security_configuration")
        } catch {
            print("Failed to store security configuration: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum PrivacyLevel: String, CaseIterable, Codable {
    case minimal = "minimal"
    case standard = "standard"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .standard: return "Standard"
        case .high: return "High"
        case .maximum: return "Maximum"
        }
    }
}

enum EncryptionAlgorithmType: String, CaseIterable, Codable {
    case aes256GCM = "aes256gcm"
    case aes256CBC = "aes256cbc"
    case chacha20Poly1305 = "chacha20poly1305"
    
    var displayName: String {
        switch self {
        case .aes256GCM: return "AES-256-GCM"
        case .aes256CBC: return "AES-256-CBC"
        case .chacha20Poly1305: return "ChaCha20-Poly1305"
        }
    }
}

enum EncryptionKeySize: Int, CaseIterable, Codable {
    case bits128 = 128
    case bits192 = 192
    case bits256 = 256
    
    var displayName: String {
        return "\(rawValue) bits"
    }
}

enum DataClassification: String, CaseIterable, Codable {
    case public = "public"
    case internal = "internal"
    case confidential = "confidential"
    case secret = "secret"
    case topSecret = "topSecret"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .internal: return "Internal"
        case .confidential: return "Confidential"
        case .secret: return "Secret"
        case .topSecret: return "Top Secret"
        }
    }
}

enum TLSVersion: String, CaseIterable, Codable {
    case v1_0 = "1.0"
    case v1_1 = "1.1"
    case v1_2 = "1.2"
    case v1_3 = "1.3"
    
    var displayName: String {
        return "TLS \(rawValue)"
    }
}

struct SecurityConfiguration: Codable {
    let requireBiometric: Bool
    let enableTwoFactor: Bool
    let sessionTimeoutMinutes: Int
    let minPasswordLength: Int
    let encryptDataAtRest: Bool
    let enforceHTTPS: Bool
    let gdprComplianceMode: Bool
    let enableThreatDetection: Bool
}

#Preview {
    SecurityConfigurationView()
}
