import SwiftUI
import Charts

struct SecurityDashboardView: View {
    @StateObject private var securityManager = SecurityManager.shared
    @StateObject private var vulnerabilityScanner = VulnerabilityScanner()
    @State private var selectedTab = 0
    @State private var isScanning = false
    @State private var lastScanDate: Date?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Security Score
                SecurityScoreHeaderView(
                    score: securityManager.currentSecurityScore,
                    status: securityManager.securityStatus
                )
                
                // Tab Selection
                Picker("Security Views", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Vulnerabilities").tag(1)
                    Text("Audit Log").tag(2)
                    Text("Settings").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    SecurityOverviewView(securityManager: securityManager)
                        .tag(0)
                    
                    VulnerabilityView(
                        scanner: vulnerabilityScanner,
                        isScanning: $isScanning,
                        lastScanDate: $lastScanDate
                    )
                    .tag(1)
                    
                    SecurityAuditLogView(securityManager: securityManager)
                        .tag(2)
                    
                    SecuritySettingsView(securityManager: securityManager)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Security Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Scan") {
                        performSecurityScan()
                    }
                    .disabled(isScanning)
                }
            }
        }
        .onAppear {
            securityManager.startMonitoring()
        }
    }
    
    private func performSecurityScan() {
        isScanning = true
        
        Task {
            let _ = vulnerabilityScanner.scanForVulnerabilities()
            await MainActor.run {
                isScanning = false
                lastScanDate = Date()
            }
        }
    }
}

// MARK: - Security Score Header

struct SecurityScoreHeaderView: View {
    let score: Double
    let status: SecurityStatus
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Score")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(String(format: "%.0f%%", score * 100))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: score)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text(status.emoji)
                        .font(.system(size: 24))
                }
            }
            
            StatusBadgeView(status: status)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct StatusBadgeView: View {
    let status: SecurityStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Security Overview

struct SecurityOverviewView: View {
    @ObservedObject var securityManager: SecurityManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Security Components Status
                SecurityComponentsGridView(securityManager: securityManager)
                
                // Recent Security Events
                RecentEventsView(events: securityManager.recentEvents)
                
                // Security Trends Chart
                SecurityTrendsChartView(trends: securityManager.securityTrends)
            }
            .padding()
        }
    }
}

struct SecurityComponentsGridView: View {
    @ObservedObject var securityManager: SecurityManager
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Components")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(securityManager.componentStatuses, id: \.component) { status in
                    SecurityComponentCard(status: status)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SecurityComponentCard: View {
    let status: ComponentStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: status.iconName)
                    .foregroundColor(status.isHealthy ? .green : .red)
                
                Spacer()
                
                Circle()
                    .fill(status.isHealthy ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            
            Text(status.component)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text(status.statusMessage)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentEventsView: View {
    let events: [SecurityEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Security Events")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    // Handle view all
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(events.prefix(5), id: \.id) { event in
                    SecurityEventRow(event: event)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SecurityEventRow: View {
    let event: SecurityEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(event.severity.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(event.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(event.timestamp.formatted(.relative(presentation: .numeric)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Security Trends Chart

struct SecurityTrendsChartView: View {
    let trends: [SecurityTrend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Score Trends")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(trends) { trend in
                LineMark(
                    x: .value("Time", trend.timestamp),
                    y: .value("Score", trend.score)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Time", trend.timestamp),
                    y: .value("Score", trend.score)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Vulnerability View

struct VulnerabilityView: View {
    @ObservedObject var scanner: VulnerabilityScanner
    @Binding var isScanning: Bool
    @Binding var lastScanDate: Date?
    
    @State private var vulnerabilityReport: SecurityReport?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Scan Controls
                VulnerabilityScanControlsView(
                    isScanning: $isScanning,
                    lastScanDate: $lastScanDate,
                    onScan: performScan
                )
                
                // Vulnerability Summary
                if let report = vulnerabilityReport {
                    VulnerabilitySummaryView(report: report)
                    
                    // Vulnerability List
                    VulnerabilityListView(vulnerabilities: report.vulnerabilities)
                }
            }
            .padding()
        }
        .onAppear {
            if vulnerabilityReport == nil {
                performScan()
            }
        }
    }
    
    private func performScan() {
        isScanning = true
        
        Task {
            let report = scanner.generateSecurityReport()
            await MainActor.run {
                vulnerabilityReport = report
                isScanning = false
                lastScanDate = Date()
            }
        }
    }
}

struct VulnerabilityScanControlsView: View {
    @Binding var isScanning: Bool
    @Binding var lastScanDate: Date?
    let onScan: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Vulnerability Scan")
                        .font(.headline)
                    
                    if let lastScan = lastScanDate {
                        Text("Last scan: \(lastScan.formatted(.relative(presentation: .numeric)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onScan) {
                    HStack {
                        if isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(isScanning ? "Scanning..." : "Start Scan")
                    }
                }
                .disabled(isScanning)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct VulnerabilitySummaryView: View {
    let report: SecurityReport
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Scan Results")
                .font(.headline)
            
            HStack(spacing: 20) {
                VulnerabilityCountView(
                    count: report.criticalVulnerabilities,
                    severity: .critical,
                    label: "Critical"
                )
                
                VulnerabilityCountView(
                    count: report.highVulnerabilities,
                    severity: .high,
                    label: "High"
                )
                
                VulnerabilityCountView(
                    count: report.mediumVulnerabilities,
                    severity: .medium,
                    label: "Medium"
                )
                
                VulnerabilityCountView(
                    count: report.lowVulnerabilities,
                    severity: .low,
                    label: "Low"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct VulnerabilityCountView: View {
    let count: Int
    let severity: VulnerabilitySeverity
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(severity.uiColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct VulnerabilityListView: View {
    let vulnerabilities: [VulnerabilityReport]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vulnerabilities")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(vulnerabilities.indices, id: \.self) { index in
                    VulnerabilityRowView(vulnerability: vulnerabilities[index])
                }
            }
            .padding(.horizontal)
        }
    }
}

struct VulnerabilityRowView: View {
    let vulnerability: VulnerabilityReport
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(vulnerability.severity.color)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vulnerability.type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(vulnerability.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Recommendation:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(vulnerability.recommendation)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Security Audit Log

struct SecurityAuditLogView: View {
    @ObservedObject var securityManager: SecurityManager
    @State private var selectedFilter: AuditLogFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Controls
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AuditLogFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Audit Log List
            List(filteredLogs) { log in
                AuditLogRowView(log: log)
            }
            .listStyle(.plain)
        }
    }
    
    private var filteredLogs: [AuditLog] {
        switch selectedFilter {
        case .all:
            return securityManager.auditLogs
        case .authentication:
            return securityManager.auditLogs.filter { $0.category == .authentication }
        case .dataAccess:
            return securityManager.auditLogs.filter { $0.category == .dataAccess }
        case .systemEvents:
            return securityManager.auditLogs.filter { $0.category == .systemEvent }
        case .errors:
            return securityManager.auditLogs.filter { $0.severity == .high || $0.severity == .critical }
        }
    }
}

struct AuditLogRowView: View {
    let log: AuditLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(log.timestamp.formatted(.dateTime.hour().minute().second()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(log.message)
                .font(.caption)
                .lineLimit(3)
            
            if !log.details.isEmpty {
                Text(log.details)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Security Settings

struct SecuritySettingsView: View {
    @ObservedObject var securityManager: SecurityManager
    
    var body: some View {
        Form {
            Section("Authentication") {
                Toggle("Require Biometric Authentication", isOn: .constant(true))
                Toggle("Two-Factor Authentication", isOn: .constant(false))
                
                HStack {
                    Text("Session Timeout")
                    Spacer()
                    Text("30 minutes")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Data Protection") {
                Toggle("Encrypt Data at Rest", isOn: .constant(true))
                Toggle("Encrypt Network Traffic", isOn: .constant(true))
                
                HStack {
                    Text("Data Retention Period")
                    Spacer()
                    Text("1 year")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Privacy") {
                Toggle("GDPR Compliance Mode", isOn: .constant(true))
                Toggle("Data Minimization", isOn: .constant(true))
                
                Button("Export User Data") {
                    // Handle export
                }
                
                Button("Delete All User Data") {
                    // Handle deletion
                }
                .foregroundColor(.red)
            }
            
            Section("Security Monitoring") {
                Toggle("Real-time Threat Detection", isOn: .constant(true))
                Toggle("Vulnerability Scanning", isOn: .constant(true))
                Toggle("Audit Logging", isOn: .constant(true))
            }
        }
    }
}

// MARK: - Supporting Types and Extensions

enum AuditLogFilter: CaseIterable {
    case all
    case authentication
    case dataAccess
    case systemEvents
    case errors
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .authentication: return "Auth"
        case .dataAccess: return "Data"
        case .systemEvents: return "System"
        case .errors: return "Errors"
        }
    }
}

extension VulnerabilityType {
    var displayName: String {
        switch self {
        case .insecureStorage: return "Insecure Storage"
        case .weakCryptography: return "Weak Cryptography"
        case .insecureNetworking: return "Insecure Networking"
        case .codeInjection: return "Code Injection"
        case .privacyLeak: return "Privacy Leak"
        case .authenticationBypass: return "Authentication Bypass"
        case .accessControl: return "Access Control"
        }
    }
}

extension VulnerabilitySeverity {
    var uiColor: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

extension SecurityStatus {
    var emoji: String {
        switch self {
        case .secure: return "🛡️"
        case .warning: return "⚠️"
        case .critical: return "🚨"
        case .unknown: return "❓"
        }
    }
    
    var color: Color {
        switch self {
        case .secure: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

#Preview {
    SecurityDashboardView()
}
