import SwiftUI

// MARK: - Localization Validation Dashboard
/// Admin interface for monitoring and managing localization validation
struct LocalizationValidationDashboard: View {
    @StateObject private var validationService = LocalizationValidationService.shared
    @State private var showingDetailReport = false
    @State private var showingExportSheet = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Overall Score Card
                    overallScoreCard
                    
                    // Validation Categories
                    validationCategoriesSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    // Recent Results
                    if validationService.lastValidationDate != nil {
                        recentResultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Localization Validation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await validationService.validateLocalization()
                        }
                    }
                    .disabled(validationService.isValidating)
                }
            }
            .sheet(isPresented: $showingDetailReport) {
                LocalizationDetailReportView()
            }
            .sheet(isPresented: $showingExportSheet) {
                LocalizationExportView()
            }
        }
        .task {
            if validationService.lastValidationDate == nil {
                await validationService.validateLocalization()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Localization Health")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if validationService.isValidating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text("Monitor string completeness, format compliance, and accessibility standards")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Overall Score Card
    private var overallScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Score")
                    .font(.headline)
                
                Spacer()
                
                if validationService.lastValidationDate != nil {
                    Text(formatDate(validationService.lastValidationDate!))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(validationService.validationResults.overallScore / 100))
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(validationService.validationResults.overallScore))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    scoreStatusView
                    
                    Text("Target: 85%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var scoreColor: Color {
        let score = validationService.validationResults.overallScore
        if score >= 85 { return .green }
        if score >= 70 { return .orange }
        return .red
    }
    
    private var scoreStatusView: some View {
        HStack(spacing: 4) {
            Image(systemName: validationService.validationResults.isPassingThreshold ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(scoreColor)
            
            Text(validationService.validationResults.isPassingThreshold ? "Passing" : "Needs Attention")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(scoreColor)
        }
    }
    
    // MARK: - Validation Categories
    private var validationCategoriesSection: some View {
        VStack(spacing: 12) {
            Text("Validation Categories")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                categoryRow(
                    title: "Base Language",
                    score: validationService.validationResults.baseLanguageResults.completionPercentage,
                    icon: "textformat",
                    subtitle: "\(validationService.validationResults.baseLanguageResults.missingKeys.count) missing keys"
                )
                
                categoryRow(
                    title: "Key Coverage",
                    score: validationService.validationResults.coverageResults.coveragePercentage,
                    icon: "list.bullet.clipboard",
                    subtitle: "\(validationService.validationResults.coverageResults.missingKeys.count) / \(validationService.validationResults.coverageResults.requiredKeys.count) required"
                )
                
                categoryRow(
                    title: "Accessibility",
                    score: validationService.validationResults.accessibilityResults.complianceScore,
                    icon: "accessibility",
                    subtitle: "\(validationService.validationResults.accessibilityResults.issues.count) issues found"
                )
            }
        }
    }
    
    private func categoryRow(title: String, score: Double, icon: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(score))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(score >= 85 ? .green : score >= 70 ? .orange : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await validationService.validateLocalization()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Run Validation")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(validationService.isValidating)
            
            HStack(spacing: 12) {
                Button(action: {
                    showingDetailReport = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("View Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .disabled(validationService.lastValidationDate == nil)
                
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
                .disabled(validationService.lastValidationDate == nil)
            }
        }
    }
    
    // MARK: - Recent Results
    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Results")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 8) {
                if !validationService.validationResults.baseLanguageResults.missingKeys.isEmpty {
                    issueCard(
                        title: "Missing Keys",
                        count: validationService.validationResults.baseLanguageResults.missingKeys.count,
                        color: .red,
                        icon: "exclamationmark.triangle"
                    )
                }
                
                if !validationService.validationResults.accessibilityResults.issues.isEmpty {
                    issueCard(
                        title: "Accessibility Issues",
                        count: validationService.validationResults.accessibilityResults.issues.count,
                        color: .orange,
                        icon: "accessibility"
                    )
                }
                
                if validationService.validationResults.isPassingThreshold {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("All validation criteria met")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func issueCard(title: String, count: Int, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Report View
struct LocalizationDetailReportView: View {
    @StateObject private var validationService = LocalizationValidationService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(validationService.generateValidationReport())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Validation Report")
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

// MARK: - Export View
struct LocalizationExportView: View {
    @StateObject private var validationService = LocalizationValidationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Export Validation Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Export validation results in JSON format for external analysis or reporting")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    exportData = validationService.exportValidationData()
                    showingShareSheet = true
                }) {
                    Text("Export JSON Data")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
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
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportData {
                    ActivityViewController(activityItems: [data])
                }
            }
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    LocalizationValidationDashboard()
}
