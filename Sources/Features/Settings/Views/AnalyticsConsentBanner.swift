import SwiftUI

// MARK: - Analytics Consent Banner
/// GDPR/CCPA compliant consent banner with granular permissions
struct AnalyticsConsentBanner: View {
    @StateObject private var consentService = AnalyticsConsentService.shared
    @State private var showingDetailedSettings = false
    @State private var customPreferences = ConsentPreferences.default
    
    var body: some View {
        if consentService.showingConsentBanner {
            consentBannerView
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: consentService.showingConsentBanner)
        }
    }
    
    private var consentBannerView: some View {
        VStack(spacing: 0) {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on backdrop tap - user must make explicit choice
                }
            
            // Banner Content
            VStack(spacing: 20) {
                bannerHeader
                bannerMessage
                
                if showingDetailedSettings {
                    detailedSettingsView
                } else {
                    quickActionButtons
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        }
    }
    
    // MARK: - Banner Header
    private var bannerHeader: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            Text(.consentBannerTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if showingDetailedSettings {
                Button(action: {
                    withAnimation {
                        showingDetailedSettings = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
        }
    }
    
    // MARK: - Banner Message
    private var bannerMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.consentBannerMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Text(.consentBannerDetails)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Quick Action Buttons
    private var quickActionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Accept All Button
                Button(action: {
                    consentService.updateConsent(.allGranted)
                }) {
                    Text(.consentAcceptAll)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Decline Button
                Button(action: {
                    consentService.denyConsent()
                }) {
                    Text(.consentDecline)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
            
            // Customize Button
            Button(action: {
                withAnimation {
                    showingDetailedSettings = true
                    customPreferences = .default
                }
            }) {
                Text(.consentCustomize)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Detailed Settings View
    private var detailedSettingsView: some View {
        VStack(spacing: 16) {
            Text(.consentCustomizeTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                consentToggle(
                    title: LocalizationService.shared.string(for: .analyticsCategoryPerformance),
                    description: LocalizationService.shared.string(for: .analyticsCategoryPerformanceDesc),
                    binding: $customPreferences.performanceAnalytics
                )
                
                consentToggle(
                    title: LocalizationService.shared.string(for: .analyticsCategoryFunctional),
                    description: LocalizationService.shared.string(for: .analyticsCategoryFunctionalDesc),
                    binding: $customPreferences.functionalAnalytics
                )
                
                consentToggle(
                    title: LocalizationService.shared.string(for: .analyticsCategoryCrashes),
                    description: LocalizationService.shared.string(for: .analyticsCategoryCrashesDesc),
                    binding: $customPreferences.crashAnalytics
                )
                
                consentToggle(
                    title: LocalizationService.shared.string(for: .analyticsCategoryTargeting),
                    description: LocalizationService.shared.string(for: .analyticsCategoryTargetingDesc),
                    binding: $customPreferences.targetingAnalytics
                )
            }
            
            // Custom Settings Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    consentService.updateConsent(customPreferences)
                }) {
                    Text(.actionSave)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    consentService.denyConsent()
                }) {
                    Text(.consentDeclineAll)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Consent Toggle
    private func consentToggle(title: String, description: String, binding: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: binding)
                    .labelsHidden()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Consent Settings View
/// Dedicated settings view for managing analytics consent preferences
struct AnalyticsConsentSettingsView: View {
    @StateObject private var consentService = AnalyticsConsentService.shared
    @State private var tempPreferences: ConsentPreferences
    @State private var showingResetAlert = false
    
    init() {
        _tempPreferences = State(initialValue: AnalyticsConsentService.shared.consentPreferences)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Current Status Section
                Section {
                    statusRow
                } header: {
                    Text(.consentCurrentStatus)
                }
                
                // Analytics Categories Section
                Section {
                    ForEach(AnalyticsCategory.allCases.filter { $0.isOptional }, id: \.self) { category in
                        categoryToggleRow(category: category)
                    }
                } header: {
                    Text(.consentCategories)
                } footer: {
                    Text(.consentCategoriesFooter)
                        .font(.caption)
                }
                
                // Actions Section
                Section {
                    saveButton
                    resetButton
                } header: {
                    Text(.consentActions)
                }
                
                // Information Section
                Section {
                    informationRows
                } header: {
                    Text(.consentInformation)
                }
            }
            .navigationTitle(Text(.consentSettingsTitle))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                tempPreferences = consentService.consentPreferences
            }
            .alert(Text(.consentResetTitle), isPresented: $showingResetAlert) {
                Button(Text(.actionCancel), role: .cancel) { }
                Button(Text(.consentReset), role: .destructive) {
                    consentService.resetConsent()
                    tempPreferences = .default
                }
            } message: {
                Text(.consentResetMessage)
            }
        }
    }
    
    // MARK: - Status Row
    private var statusRow: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(consentService.consentStatus.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(consentService.consentStatus.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(consentService.consentPreferences.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
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
    
    // MARK: - Category Toggle Row
    private func categoryToggleRow(category: AnalyticsCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: bindingForCategory(category))
                    .labelsHidden()
            }
            
            Text(category.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func bindingForCategory(_ category: AnalyticsCategory) -> Binding<Bool> {
        switch category {
        case .performance:
            return $tempPreferences.performanceAnalytics
        case .functional:
            return $tempPreferences.functionalAnalytics
        case .targeting:
            return $tempPreferences.targetingAnalytics
        case .crashes:
            return $tempPreferences.crashAnalytics
        case .essential:
            return .constant(true) // Essential always enabled
        }
    }
    
    // MARK: - Action Buttons
    private var saveButton: some View {
        Button(action: {
            consentService.updateConsent(tempPreferences)
        }) {
            HStack {
                Image(systemName: "checkmark.circle")
                Text(.consentSavePreferences)
            }
            .foregroundColor(.blue)
        }
        .disabled(tempPreferences == consentService.consentPreferences)
    }
    
    private var resetButton: some View {
        Button(action: {
            showingResetAlert = true
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text(.consentReset)
            }
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Information Rows
    private var informationRows: some View {
        Group {
            NavigationLink(destination: ConsentPrivacyPolicyView()) {
                HStack {
                    Image(systemName: "doc.text")
                    Text(.consentPrivacyPolicy)
                }
            }
            
            NavigationLink(destination: ConsentDataUsageView()) {
                HStack {
                    Image(systemName: "chart.bar")
                    Text(.consentDataUsage)
                }
            }
            
            HStack {
                Image(systemName: "info.circle")
                Text(.consentVersion)
                Spacer()
                Text("v1.0")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct ConsentPrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(.privacyPolicyContent)
                    .font(.body)
                    .padding()
            }
        }
        .navigationTitle(Text(.consentPrivacyPolicy))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConsentDataUsageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(.dataUsageContent)
                    .font(.body)
                    .padding()
            }
        }
        .navigationTitle(Text(.consentDataUsage))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    AnalyticsConsentBanner()
}
