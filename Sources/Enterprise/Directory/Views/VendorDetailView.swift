import SwiftUI

// MARK: - Vendor Detail View

public struct VendorDetailView: View {
    @StateObject private var viewModel: DirectoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    let vendor: Vendor
    
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedDetailTab: VendorDetailTab = .overview
    
    public init(vendor: Vendor, viewModel: DirectoryViewModel? = nil) {
        self.vendor = vendor
        self._viewModel = StateObject(wrappedValue: viewModel ?? DirectoryViewModel())
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VendorHeaderView(vendor: vendor)
                    .padding(.top)
                
                // Tab Selector
                VendorDetailTabSelector(selectedTab: $selectedDetailTab)
                    .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedDetailTab) {
                    VendorOverviewView(vendor: vendor)
                        .tag(VendorDetailTab.overview)
                    
                    VendorContactView(vendor: vendor)
                        .tag(VendorDetailTab.contact)
                    
                    VendorContractsView(vendor: vendor)
                        .tag(VendorDetailTab.contracts)
                    
                    VendorPerformanceView(vendor: vendor)
                        .tag(VendorDetailTab.performance)
                    
                    VendorComplianceView(vendor: vendor)
                        .tag(VendorDetailTab.compliance)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(vendor.companyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingEditView = true
                    } label: {
                        Image(systemName: "pencil")
                            .accessibilityLabel("Edit Vendor")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .accessibilityLabel("Delete Vendor")
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                VendorEditView(vendor: vendor) { updatedVendor in
                    Task {
                        await viewModel.updateVendor(updatedVendor)
                    }
                }
            }
            .confirmationDialog(
                "Delete Vendor",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteVendor(vendor)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(vendor.companyName)? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Vendor Header View

private struct VendorHeaderView: View {
    let vendor: Vendor
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        VStack(spacing: 20) {
            // Company Logo/Icon
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.blue.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay {
                    Text(vendor.companyName.prefix(2).uppercased())
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                )
            
            VStack(spacing: 8) {
                Text(vendor.companyName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(vendor.contactPerson)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    StatusBadge(
                        text: vendor.vendorType.displayName,
                        color: .green,
                        systemImage: "building.2"
                    )
                    
                    StatusBadge(
                        text: vendor.contractStatus.displayName,
                        color: contractStatusColor(vendor.contractStatus),
                        systemImage: "doc.text"
                    )
                    
                    if vendor.isPreferred {
                        StatusBadge(
                            text: "Preferred",
                            color: .orange,
                            systemImage: "star"
                        )
                    }
                }
                
                // Rating
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(vendor.overallRating) ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(String(format: "%.1f out of 5", vendor.overallRating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(reduceTransparency ? .regularMaterial : .ultraThinMaterial)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vendor.companyName), \(vendor.vendorType.displayName), \(vendor.contractStatus.displayName), Rating \(String(format: "%.1f", vendor.overallRating)) out of 5")
    }
    
    private func contractStatusColor(_ status: ContractStatus) -> Color {
        switch status {
        case .active: return .green
        case .pending: return .orange
        case .expired: return .red
        case .terminated: return .gray
        }
    }
}

// MARK: - Vendor Detail Tab Selector

private struct VendorDetailTabSelector: View {
    @Binding var selectedTab: VendorDetailTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VendorDetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tab.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedTab == tab ? .accentColor.opacity(0.15) : Color.clear)
                        )
                    }
                    .accessibilityLabel(tab.displayName)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Overview Tab

private struct VendorOverviewView: View {
    let vendor: Vendor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Stats
                VendorQuickStatsView(vendor: vendor)
                
                // Basic Information
                InfoSectionView(title: "Basic Information") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Vendor Number",
                            value: vendor.vendorNumber,
                            systemImage: "number"
                        )
                        
                        InfoRowView(
                            label: "Vendor Type",
                            value: vendor.vendorType.displayName,
                            systemImage: "building.2"
                        )
                        
                        InfoRowView(
                            label: "Registration Date",
                            value: DateFormatter.medium.string(from: vendor.registrationDate),
                            systemImage: "calendar"
                        )
                        
                        InfoRowView(
                            label: "Tax ID",
                            value: vendor.taxID,
                            systemImage: "doc.text"
                        )
                    }
                }
                
                // Risk Assessment
                InfoSectionView(title: "Risk Assessment") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Overall Risk Level",
                            value: vendor.riskAssessment.overallRiskLevel.displayName,
                            systemImage: "exclamationmark.triangle"
                        )
                        
                        InfoRowView(
                            label: "Financial Risk",
                            value: vendor.riskAssessment.financialRisk.displayName,
                            systemImage: "dollarsign.circle"
                        )
                        
                        InfoRowView(
                            label: "Operational Risk",
                            value: vendor.riskAssessment.operationalRisk.displayName,
                            systemImage: "gear"
                        )
                        
                        InfoRowView(
                            label: "Compliance Risk",
                            value: vendor.riskAssessment.complianceRisk.displayName,
                            systemImage: "checkmark.shield"
                        )
                        
                        InfoRowView(
                            label: "Last Assessment",
                            value: DateFormatter.medium.string(from: vendor.riskAssessment.lastAssessmentDate),
                            systemImage: "calendar"
                        )
                    }
                }
                
                // Performance Metrics
                InfoSectionView(title: "Performance Summary") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Overall Rating",
                            value: String(format: "%.1f / 5.0", vendor.overallRating),
                            systemImage: "star"
                        )
                        
                        InfoRowView(
                            label: "Quality Score",
                            value: String(format: "%.1f", vendor.performanceMetrics.qualityScore),
                            systemImage: "checkmark.circle"
                        )
                        
                        InfoRowView(
                            label: "Delivery Score",
                            value: String(format: "%.1f", vendor.performanceMetrics.deliveryScore),
                            systemImage: "truck.box"
                        )
                        
                        InfoRowView(
                            label: "Communication Score",
                            value: String(format: "%.1f", vendor.performanceMetrics.communicationScore),
                            systemImage: "message"
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Contact Tab

private struct VendorContactView: View {
    let vendor: Vendor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Primary Contact
                InfoSectionView(title: "Primary Contact") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Contact Person",
                            value: vendor.contactPerson,
                            systemImage: "person"
                        )
                        
                        InfoRowView(
                            label: "Email",
                            value: vendor.email,
                            systemImage: "envelope",
                            action: { openEmail(vendor.email) }
                        )
                        
                        InfoRowView(
                            label: "Phone",
                            value: vendor.phone,
                            systemImage: "phone",
                            action: { openPhone(vendor.phone) }
                        )
                        
                        if let website = vendor.website {
                            InfoRowView(
                                label: "Website",
                                value: website,
                                systemImage: "globe",
                                action: { openWebsite(website) }
                            )
                        }
                    }
                }
                
                // Address
                InfoSectionView(title: "Business Address") {
                    AddressView(address: vendor.address)
                }
                
                // Additional Contacts
                if !vendor.alternateContacts.isEmpty {
                    InfoSectionView(title: "Additional Contacts") {
                        VStack(spacing: 12) {
                            ForEach(vendor.alternateContacts) { contact in
                                AlternateContactRowView(contact: contact)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite(_ website: String) {
        if let url = URL(string: website) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Contracts Tab

private struct VendorContractsView: View {
    let vendor: Vendor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Contract
                InfoSectionView(title: "Current Contract") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Contract Number",
                            value: vendor.contractInfo.contractNumber,
                            systemImage: "doc.text"
                        )
                        
                        InfoRowView(
                            label: "Start Date",
                            value: DateFormatter.medium.string(from: vendor.contractInfo.startDate),
                            systemImage: "calendar"
                        )
                        
                        if let endDate = vendor.contractInfo.endDate {
                            InfoRowView(
                                label: "End Date",
                                value: DateFormatter.medium.string(from: endDate),
                                systemImage: "calendar"
                            )
                        }
                        
                        if let value = vendor.contractInfo.contractValue {
                            InfoRowView(
                                label: "Contract Value",
                                value: CurrencyFormatter.shared.string(from: NSNumber(value: value)) ?? "$\(value)",
                                systemImage: "dollarsign.circle"
                            )
                        }
                        
                        InfoRowView(
                            label: "Payment Method",
                            value: vendor.contractInfo.preferredPaymentMethod.displayName,
                            systemImage: "creditcard"
                        )
                    }
                }
                
                // Payment Terms
                InfoSectionView(title: "Payment Terms") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Payment Terms",
                            value: vendor.paymentTerms.terms.displayName,
                            systemImage: "calendar.badge.clock"
                        )
                        
                        InfoRowView(
                            label: "Preferred Payment Method",
                            value: vendor.paymentTerms.preferredPaymentMethod.displayName,
                            systemImage: "creditcard"
                        )
                        
                        if let discountTerms = vendor.paymentTerms.discountTerms {
                            InfoRowView(
                                label: "Early Payment Discount",
                                value: discountTerms,
                                systemImage: "percent"
                            )
                        }
                    }
                }
                
                // SLA Requirements
                if !vendor.slaRequirements.isEmpty {
                    InfoSectionView(title: "SLA Requirements") {
                        VStack(spacing: 12) {
                            ForEach(vendor.slaRequirements) { sla in
                                SLARequirementRowView(sla: sla)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Performance Tab

private struct VendorPerformanceView: View {
    let vendor: Vendor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Performance Metrics
                InfoSectionView(title: "Performance Metrics") {
                    VStack(spacing: 16) {
                        PerformanceMetricRowView(
                            label: "Quality Score",
                            value: vendor.performanceMetrics.qualityScore,
                            systemImage: "checkmark.circle"
                        )
                        
                        PerformanceMetricRowView(
                            label: "Delivery Score",
                            value: vendor.performanceMetrics.deliveryScore,
                            systemImage: "truck.box"
                        )
                        
                        PerformanceMetricRowView(
                            label: "Communication Score",
                            value: vendor.performanceMetrics.communicationScore,
                            systemImage: "message"
                        )
                        
                        PerformanceMetricRowView(
                            label: "Cost Effectiveness",
                            value: vendor.performanceMetrics.costEffectiveness,
                            systemImage: "dollarsign.circle"
                        )
                        
                        InfoRowView(
                            label: "Last Updated",
                            value: DateFormatter.medium.string(from: vendor.performanceMetrics.lastUpdated),
                            systemImage: "calendar"
                        )
                    }
                }
                
                // Audit History
                if !vendor.auditHistory.isEmpty {
                    InfoSectionView(title: "Recent Audits") {
                        VStack(spacing: 12) {
                            ForEach(vendor.auditHistory.prefix(5)) { audit in
                                AuditHistoryRowView(audit: audit)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Compliance Tab

private struct VendorComplianceView: View {
    let vendor: Vendor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Compliance Status
                InfoSectionView(title: "Compliance Status") {
                    VStack(spacing: 16) {
                        InfoRowView(
                            label: "Overall Status",
                            value: vendor.complianceStatus.overall.displayName,
                            systemImage: "checkmark.shield"
                        )
                        
                        InfoRowView(
                            label: "Last Compliance Check",
                            value: DateFormatter.medium.string(from: vendor.complianceStatus.lastComplianceCheck),
                            systemImage: "calendar"
                        )
                        
                        if let nextReview = vendor.complianceStatus.nextReviewDate {
                            InfoRowView(
                                label: "Next Review",
                                value: DateFormatter.medium.string(from: nextReview),
                                systemImage: "calendar.badge.clock"
                            )
                        }
                    }
                }
                
                // Certifications
                if !vendor.certifications.isEmpty {
                    InfoSectionView(title: "Certifications") {
                        VStack(spacing: 12) {
                            ForEach(vendor.certifications) { certification in
                                CertificationRowView(certification: certification)
                            }
                        }
                    }
                }
                
                // Insurance Information
                if !vendor.insuranceInfo.isEmpty {
                    InfoSectionView(title: "Insurance Information") {
                        VStack(spacing: 12) {
                            ForEach(vendor.insuranceInfo) { insurance in
                                InsuranceRowView(insurance: insurance)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Helper Views

private struct VendorQuickStatsView: View {
    let vendor: Vendor
    
    var body: some View {
        HStack(spacing: 16) {
            StatCardView(
                title: "Overall Rating",
                value: String(format: "%.1f", vendor.overallRating),
                systemImage: "star",
                color: .orange
            )
            
            StatCardView(
                title: "Risk Level",
                value: vendor.riskAssessment.overallRiskLevel.shortDisplayName,
                systemImage: "exclamationmark.triangle",
                color: riskLevelColor(vendor.riskAssessment.overallRiskLevel)
            )
            
            StatCardView(
                title: "Contract Status",
                value: vendor.contractStatus.shortDisplayName,
                systemImage: "doc.text",
                color: contractStatusColor(vendor.contractStatus)
            )
        }
    }
    
    private func riskLevelColor(_ riskLevel: RiskLevel) -> Color {
        switch riskLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    private func contractStatusColor(_ status: ContractStatus) -> Color {
        switch status {
        case .active: return .green
        case .pending: return .orange
        case .expired: return .red
        case .terminated: return .gray
        }
    }
}

private struct AlternateContactRowView: View {
    let contact: AlternateContact
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(contact.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let email = contact.email {
                    Button(action: { openEmail(email) }) {
                        Image(systemName: "envelope")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel("Email \(contact.name)")
                }
                
                if let phone = contact.phone {
                    Button(action: { openPhone(phone) }) {
                        Image(systemName: "phone")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel("Call \(contact.name)")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contact.name), \(contact.role)")
    }
    
    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}

private struct SLARequirementRowView: View {
    let sla: SLARequirement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(sla.requirementType)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Target: \(sla.targetValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(sla.unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sla.requirementType), target \(sla.targetValue) \(sla.unit)")
    }
}

private struct PerformanceMetricRowView: View {
    let label: String
    let value: Double
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f", value))
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Performance indicator
            Circle()
                .fill(performanceColor(value))
                .frame(width: 12, height: 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(String(format: "%.1f", value))")
    }
    
    private func performanceColor(_ value: Double) -> Color {
        switch value {
        case 4.0...5.0: return .green
        case 3.0..<4.0: return .yellow
        case 2.0..<3.0: return .orange
        default: return .red
        }
    }
}

private struct AuditHistoryRowView: View {
    let audit: AuditRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(audit.auditType)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(DateFormatter.medium.string(from: audit.auditDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(audit.result)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(auditResultColor(audit.result))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(auditResultColor(audit.result).opacity(0.1))
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(audit.auditType) audit on \(DateFormatter.medium.string(from: audit.auditDate)), result: \(audit.result)")
    }
    
    private func auditResultColor(_ result: String) -> Color {
        switch result.lowercased() {
        case "passed", "compliant": return .green
        case "failed", "non-compliant": return .red
        case "pending", "in progress": return .orange
        default: return .blue
        }
    }
}

private struct InsuranceRowView: View {
    let insurance: Insurance
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insurance.type)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Expires: \(DateFormatter.medium.string(from: insurance.expirationDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(CurrencyFormatter.shared.string(from: NSNumber(value: insurance.coverageAmount)) ?? "$\(insurance.coverageAmount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insurance.type) insurance, \(CurrencyFormatter.shared.string(from: NSNumber(value: insurance.coverageAmount)) ?? "$\(insurance.coverageAmount)") coverage, expires \(DateFormatter.medium.string(from: insurance.expirationDate))")
    }
}

// MARK: - Edit View Placeholder

private struct VendorEditView: View {
    let vendor: Vendor
    let onSave: (Vendor) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Vendor")
                    .font(.headline)
                
                Text("Vendor editing form coming soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit \(vendor.companyName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(vendor)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

public enum VendorDetailTab: String, CaseIterable {
    case overview = "overview"
    case contact = "contact"
    case contracts = "contracts"
    case performance = "performance"
    case compliance = "compliance"
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .contact: return "Contact"
        case .contracts: return "Contracts"
        case .performance: return "Performance"
        case .compliance: return "Compliance"
        }
    }
    
    var systemImage: String {
        switch self {
        case .overview: return "building.2"
        case .contact: return "envelope"
        case .contracts: return "doc.text"
        case .performance: return "chart.bar"
        case .compliance: return "checkmark.shield"
        }
    }
}

// MARK: - Extensions

private extension RiskLevel {
    var shortDisplayName: String {
        switch self {
        case .low: return "LOW"
        case .medium: return "MED"
        case .high: return "HIGH"
        case .critical: return "CRIT"
        }
    }
}

private extension ContractStatus {
    var shortDisplayName: String {
        switch self {
        case .active: return "ACT"
        case .pending: return "PEN"
        case .expired: return "EXP"
        case .terminated: return "TER"
        }
    }
}

private class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    func string(from number: NSNumber) -> String? {
        return formatter.string(from: number)
    }
}

#Preview {
    VendorDetailView(
        vendor: Vendor(
            vendorNumber: "VEN001",
            companyName: "Tech Solutions Inc",
            contactPerson: "John Smith",
            email: "john@techsolutions.com",
            phone: "555-0123",
            address: Address(street: "456 Business Ave", city: "San Francisco", state: "CA", zipCode: "94105"),
            vendorType: .supplier,
            contractInfo: ContractInfo(
                contractNumber: "CNT001",
                startDate: Date(),
                preferredPaymentMethod: .check
            ),
            paymentTerms: PaymentTerms(terms: .net30, preferredPaymentMethod: .check)
        )
    )
}
