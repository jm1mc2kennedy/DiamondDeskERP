import SwiftUI

// MARK: - Analytics Consent Dashboard
/// Admin interface for monitoring analytics consent compliance and user preferences
struct AnalyticsConsentDashboard: View {
    @StateObject private var consentService = AnalyticsConsentService.shared
    @State private var showingDetailedReport = false
    @State private var showingExportSheet = false
    @State private var consentMetrics: ConsentMetrics = .empty
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Overall Compliance Card
                    complianceOverviewCard
                    
                    // Consent Breakdown
                    consentBreakdownSection
                    
                    // Current User Status
                    currentUserStatusSection
                    
                    // Analytics Services Status
                    servicesStatusSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("Analytics Consent")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshMetrics()
                    }
                }
            }
            .sheet(isPresented: $showingDetailedReport) {
                ConsentDetailedReportView(metrics: consentMetrics)
            }
            .sheet(isPresented: $showingExportSheet) {
                ConsentExportView()
            }
        }
        .onAppear {
            refreshMetrics()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Consent Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                complianceStatusIndicator
            }
            
            Text("Monitor analytics consent compliance and user preferences across the organization")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var complianceStatusIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: consentMetrics.isCompliant ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .foregroundColor(consentMetrics.isCompliant ? .green : .orange)
            
            Text(consentMetrics.isCompliant ? "Compliant" : "Review Required")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(consentMetrics.isCompliant ? .green : .orange)
        }
    }
    
    // MARK: - Compliance Overview
    private var complianceOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Compliance Overview")
                    .font(.headline)
                
                Spacer()
                
                Text("Last Updated: \(formatDate(consentMetrics.lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Compliance Score
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(consentMetrics.complianceScore / 100))
                            .stroke(complianceColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(consentMetrics.complianceScore))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(complianceColor)
                    }
                    
                    Text("Compliance Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Key Metrics
                VStack(alignment: .trailing, spacing: 4) {
                    metricRow(title: "Users with Consent", value: "\(consentMetrics.usersWithConsent)")
                    metricRow(title: "Pending Consent", value: "\(consentMetrics.usersPendingConsent)")
                    metricRow(title: "Consent Denied", value: "\(consentMetrics.usersConsentDenied)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var complianceColor: Color {
        let score = consentMetrics.complianceScore
        if score >= 85 { return .green }
        if score >= 70 { return .orange }
        return .red
    }
    
    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Consent Breakdown
    private var consentBreakdownSection: some View {
        VStack(spacing: 12) {
            Text("Consent Categories")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                categoryBreakdownRow(
                    category: "Performance Analytics",
                    granted: consentMetrics.performanceGranted,
                    total: consentMetrics.totalUsers,
                    icon: "speedometer"
                )
                
                categoryBreakdownRow(
                    category: "Functional Analytics",
                    granted: consentMetrics.functionalGranted,
                    total: consentMetrics.totalUsers,
                    icon: "gear"
                )
                
                categoryBreakdownRow(
                    category: "Crash Reporting",
                    granted: consentMetrics.crashReportingGranted,
                    total: consentMetrics.totalUsers,
                    icon: "exclamationmark.triangle"
                )
                
                categoryBreakdownRow(
                    category: "Targeting Analytics",
                    granted: consentMetrics.targetingGranted,
                    total: consentMetrics.totalUsers,
                    icon: "target"
                )
            }
        }
    }
    
    private func categoryBreakdownRow(category: String, granted: Int, total: Int, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(granted) of \(total) users")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress Bar
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(Double(granted) / Double(max(total, 1)) * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ProgressView(value: Double(granted), total: Double(max(total, 1)))
                    .frame(width: 60)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Current User Status
    private var currentUserStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current User Status")
                .font(.headline)
            
            HStack(spacing: 16) {
                Image(systemName: currentUserStatusIcon)
                    .foregroundColor(consentService.consentStatus.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(consentService.consentStatus.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(consentService.consentPreferences.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Review") {
                    consentService.showConsentSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var currentUserStatusIcon: String {
        switch consentService.consentStatus {
        case .unknown:
            return "questionmark.circle"
        case .granted:
            return "checkmark.circle.fill"
        case .denied, .revoked:
            return "xmark.circle.fill"
        case .expired:
            return "clock.circle.fill"
        }
    }
    
    // MARK: - Services Status
    private var servicesStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analytics Services Status")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(AnalyticsService.allCases, id: \.self) { service in
                    serviceStatusRow(service: service)
                }
            }
        }
    }
    
    private func serviceStatusRow(service: AnalyticsService) -> some View {
        HStack {
            Image(systemName: serviceIcon(for: service))
                .foregroundColor(serviceStatusColor(for: service))
                .frame(width: 24)
            
            Text(service.displayName)
                .font(.subheadline)
            
            Spacer()
            
            Text(serviceStatusText(for: service))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(serviceStatusColor(for: service))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func serviceIcon(for service: AnalyticsService) -> String {
        consentService.getConsentStatusForService(service) ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private func serviceStatusColor(for service: AnalyticsService) -> Color {
        consentService.getConsentStatusForService(service) ? .green : .red
    }
    
    private func serviceStatusText(for service: AnalyticsService) -> String {
        consentService.getConsentStatusForService(service) ? "Enabled" : "Disabled"
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingDetailedReport = true
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("View Detailed Report")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    refreshMetrics()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func refreshMetrics() {
        // Simulate metrics calculation - in real implementation, this would aggregate user consent data
        consentMetrics = ConsentMetrics(
            complianceScore: 87.5,
            totalUsers: 156,
            usersWithConsent: 142,
            usersPendingConsent: 8,
            usersConsentDenied: 6,
            performanceGranted: 128,
            functionalGranted: 135,
            crashReportingGranted: 149,
            targetingGranted: 67,
            lastUpdated: Date()
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Consent Metrics Model
struct ConsentMetrics {
    let complianceScore: Double
    let totalUsers: Int
    let usersWithConsent: Int
    let usersPendingConsent: Int
    let usersConsentDenied: Int
    let performanceGranted: Int
    let functionalGranted: Int
    let crashReportingGranted: Int
    let targetingGranted: Int
    let lastUpdated: Date
    
    var isCompliant: Bool {
        complianceScore >= 85.0
    }
    
    static let empty = ConsentMetrics(
        complianceScore: 0.0,
        totalUsers: 0,
        usersWithConsent: 0,
        usersPendingConsent: 0,
        usersConsentDenied: 0,
        performanceGranted: 0,
        functionalGranted: 0,
        crashReportingGranted: 0,
        targetingGranted: 0,
        lastUpdated: Date()
    )
}

// MARK: - Supporting Views
struct ConsentDetailedReportView: View {
    let metrics: ConsentMetrics
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(generateDetailedReport())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Consent Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateDetailedReport() -> String {
        """
        # Analytics Consent Detailed Report
        Generated: \(DateFormatter.iso8601.string(from: Date()))
        
        ## Compliance Overview
        Overall Score: \(String(format: "%.1f", metrics.complianceScore))%
        Compliance Status: \(metrics.isCompliant ? "COMPLIANT" : "NEEDS REVIEW")
        
        ## User Consent Summary
        Total Users: \(metrics.totalUsers)
        Users with Consent: \(metrics.usersWithConsent) (\(String(format: "%.1f", Double(metrics.usersWithConsent) / Double(max(metrics.totalUsers, 1)) * 100))%)
        Pending Consent: \(metrics.usersPendingConsent) (\(String(format: "%.1f", Double(metrics.usersPendingConsent) / Double(max(metrics.totalUsers, 1)) * 100))%)
        Consent Denied: \(metrics.usersConsentDenied) (\(String(format: "%.1f", Double(metrics.usersConsentDenied) / Double(max(metrics.totalUsers, 1)) * 100))%)
        
        ## Category Breakdown
        Performance Analytics: \(metrics.performanceGranted)/\(metrics.totalUsers) (\(String(format: "%.1f", Double(metrics.performanceGranted) / Double(max(metrics.totalUsers, 1)) * 100))%)
        Functional Analytics: \(metrics.functionalGranted)/\(metrics.totalUsers) (\(String(format: "%.1f", Double(metrics.functionalGranted) / Double(max(metrics.totalUsers, 1)) * 100))%)
        Crash Reporting: \(metrics.crashReportingGranted)/\(metrics.totalUsers) (\(String(format: "%.1f", Double(metrics.crashReportingGranted) / Double(max(metrics.totalUsers, 1)) * 100))%)
        Targeting Analytics: \(metrics.targetingGranted)/\(metrics.totalUsers) (\(String(format: "%.1f", Double(metrics.targetingGranted) / Double(max(metrics.totalUsers, 1)) * 100))%)
        
        ## Recommendations
        \(generateRecommendations())
        """
    }
    
    private func generateRecommendations() -> String {
        var recommendations: [String] = []
        
        if metrics.usersPendingConsent > 0 {
            recommendations.append("- Follow up with \(metrics.usersPendingConsent) users who have not provided consent")
        }
        
        if metrics.complianceScore < 85 {
            recommendations.append("- Review consent collection process to improve compliance score")
        }
        
        let crashConsentRate = Double(metrics.crashReportingGranted) / Double(max(metrics.totalUsers, 1))
        if crashConsentRate < 0.8 {
            recommendations.append("- Consider emphasizing benefits of crash reporting for app stability")
        }
        
        return recommendations.isEmpty ? "No specific recommendations at this time." : recommendations.joined(separator: "\n")
    }
}

struct ConsentExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Export Consent Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Export consent compliance data for audit or reporting purposes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Export CSV Report") {
                    // Implementation would generate and share CSV
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AnalyticsConsentDashboard()
}
