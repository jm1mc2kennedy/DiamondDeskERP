import SwiftUI
import CloudKit

/// Admin-only conflict viewer for monitoring and resolving CloudKit conflicts
/// Provides comprehensive conflict management interface with resolution tools
struct ConflictViewer: View {
    @StateObject private var conflictService = ConflictLoggingService.shared
    @State private var selectedConflict: ConflictLog?
    @State private var showingResolutionSheet = false
    @State private var selectedSeverityFilter: ConflictLoggingService.ConflictSeverity?
    @State private var selectedRecordTypeFilter: String?
    @State private var showingStatistics = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigationPath = NavigationPath()
    
    private let recordTypes = ["All", "Task", "Ticket", "Client", "KPI", "StoreReport"]
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            VStack {
                if conflictService.activeConflicts.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    conflictListView
                }
            }
            .navigationTitle("Conflict Monitor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingStatistics = true }) {
                        Image(systemName: "chart.bar.fill")
                    }
                    
                    Button(action: refreshConflicts) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable {
                await loadConflictHistory()
            }
            .task {
                await loadConflictHistory()
            }
            .sheet(isPresented: $showingResolutionSheet) {
                if let conflict = selectedConflict {
                    ConflictResolutionView(conflict: conflict)
                }
            }
            .sheet(isPresented: $showingStatistics) {
                ConflictStatisticsView()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Active Conflicts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("CloudKit synchronization is running smoothly. All conflicts have been resolved.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("View History") {
                Task { await loadConflictHistory() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var conflictListView: some View {
        VStack {
            filterSection
            
            if isLoading {
                ProgressView("Loading conflicts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredConflicts) { conflict in
                        ConflictRowView(conflict: conflict) {
                            selectedConflict = conflict
                            showingResolutionSheet = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filters")
                    .font(.headline)
                Spacer()
                Button("Clear All") {
                    selectedSeverityFilter = nil
                    selectedRecordTypeFilter = nil
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                // Severity Filter
                Menu {
                    Button("All Severities") {
                        selectedSeverityFilter = nil
                    }
                    
                    ForEach(ConflictLoggingService.ConflictSeverity.allCases, id: \.self) { severity in
                        Button(severity.rawValue.capitalized) {
                            selectedSeverityFilter = severity
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSeverityFilter?.rawValue.capitalized ?? "All Severities")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Record Type Filter
                Menu {
                    ForEach(recordTypes, id: \.self) { recordType in
                        Button(recordType) {
                            selectedRecordTypeFilter = recordType == "All" ? nil : recordType
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRecordTypeFilter ?? "All Types")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private var filteredConflicts: [ConflictLog] {
        conflictService.activeConflicts.filter { conflict in
            if let severityFilter = selectedSeverityFilter, conflict.severity != severityFilter {
                return false
            }
            
            if let recordTypeFilter = selectedRecordTypeFilter, conflict.recordType != recordTypeFilter {
                return false
            }
            
            return true
        }
    }
    
    private func refreshConflicts() {
        Task {
            await loadConflictHistory()
        }
    }
    
    private func loadConflictHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let conflicts = try await conflictService.getConflictHistory(limit: 100)
            await MainActor.run {
                conflictService.activeConflicts = conflicts.filter { !$0.isResolved }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load conflicts: \(error.localizedDescription)"
            }
        }
    }
}

struct ConflictRowView: View {
    let conflict: ConflictLog
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Severity indicator
                Circle()
                    .fill(severityColor)
                    .frame(width: 12, height: 12)
                
                Text(conflict.recordType)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(conflict.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityTextColor)
                    .clipShape(Capsule())
            }
            
            Text(conflict.operation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(conflict.conflictedFields.count.description, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text(RelativeDateTimeFormatter().localizedString(for: conflict.detectedAt, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !conflict.conflictedFields.isEmpty {
                Text("Fields: \(conflict.conflictedFields.prefix(3).joined(separator: ", "))\(conflict.conflictedFields.count > 3 ? "..." : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var severityColor: Color {
        switch conflict.severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
    
    private var severityTextColor: Color {
        switch conflict.severity {
        case .critical, .high:
            return .white
        case .medium, .low:
            return .primary
        }
    }
}

struct ConflictResolutionView: View {
    let conflict: ConflictLog
    @StateObject private var conflictService = ConflictLoggingService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStrategy: ConflictLoggingService.ConflictResolutionStrategy = .lastWriterWins
    @State private var resolutionNotes: String = ""
    @State private var isResolving = false
    @State private var showingFieldDetails = false
    @State private var customResolution: [String: Any] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    conflictSummarySection
                    recordComparisonSection
                    resolutionStrategySection
                    if selectedStrategy == .manualResolution {
                        customResolutionSection
                    }
                    notesSection
                }
                .padding()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Resolve") {
                        Task { await resolveConflict() }
                    }
                    .disabled(isResolving)
                }
            }
        }
    }
    
    private var conflictSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conflict Summary")
                .font(.headline)
            
            ConflictSummaryCard(conflict: conflict)
        }
    }
    
    private var recordComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Record Comparison")
                    .font(.headline)
                
                Spacer()
                
                Button("View Details") {
                    showingFieldDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            RecordComparisonView(
                localRecord: conflict.localRecord,
                serverRecord: conflict.serverRecord,
                conflictedFields: conflict.conflictedFields
            )
        }
        .sheet(isPresented: $showingFieldDetails) {
            FieldConflictDetailsView(conflict: conflict)
        }
    }
    
    private var resolutionStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolution Strategy")
                .font(.headline)
            
            ForEach(ConflictLoggingService.ConflictResolutionStrategy.allCases, id: \.self) { strategy in
                ResolutionStrategyRow(
                    strategy: strategy,
                    isSelected: selectedStrategy == strategy,
                    onSelect: { selectedStrategy = strategy }
                )
            }
        }
    }
    
    private var customResolutionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Resolution")
                .font(.headline)
            
            Text("Manual field-by-field resolution - Advanced users only")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // This would be a complex field-by-field editor
            // For now, showing a placeholder
            Text("Custom resolution editor would be implemented here")
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolution Notes")
                .font(.headline)
            
            TextEditor(text: $resolutionNotes)
                .frame(height: 100)
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
    
    private func resolveConflict() async {
        isResolving = true
        defer { isResolving = false }
        
        do {
            let customData = selectedStrategy == .manualResolution ? customResolution : nil
            let _ = try await conflictService.resolveConflict(
                conflictId: conflict.id,
                strategy: selectedStrategy,
                customResolution: customData
            )
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            // Handle error
            print("Failed to resolve conflict: \(error)")
        }
    }
}

struct ConflictSummaryCard: View {
    let conflict: ConflictLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conflict.recordType)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(conflict.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .clipShape(Capsule())
            }
            
            Text("Record ID: \(conflict.recordID)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Operation: \(conflict.operation)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Detected: \(conflict.detectedAt.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Conflicted Fields: \(conflict.conflictedFields.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var severityColor: Color {
        switch conflict.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct RecordComparisonView: View {
    let localRecord: CKRecord
    let serverRecord: CKRecord
    let conflictedFields: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Local Record")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Modified: \(localRecord.modificationDate?.formatted() ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Server Record")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Modified: \(serverRecord.modificationDate?.formatted() ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("First 3 Conflicted Fields:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(conflictedFields.prefix(3), id: \.self) { field in
                    HStack {
                        Text(field)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("View Details")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if conflictedFields.count > 3 {
                    Text("... and \(conflictedFields.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct ResolutionStrategyRow: View {
    let strategy: ConflictLoggingService.ConflictResolutionStrategy
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategyTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(strategyDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
    }
    
    private var strategyTitle: String {
        switch strategy {
        case .clientWins:
            return "Client Wins"
        case .serverWins:
            return "Server Wins"
        case .lastWriterWins:
            return "Last Writer Wins"
        case .manualResolution:
            return "Manual Resolution"
        case .mergeFields:
            return "Merge Fields"
        case .versionBased:
            return "Version Based"
        }
    }
    
    private var strategyDescription: String {
        switch strategy {
        case .clientWins:
            return "Use the local record, discarding server changes"
        case .serverWins:
            return "Use the server record, discarding local changes"
        case .lastWriterWins:
            return "Use the record with the most recent modification date"
        case .manualResolution:
            return "Manually choose values for each conflicted field"
        case .mergeFields:
            return "Automatically merge non-conflicting fields"
        case .versionBased:
            return "Use version numbers to determine precedence"
        }
    }
}

struct FieldConflictDetailsView: View {
    let conflict: ConflictLog
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conflict.getFieldConflictDetails(), id: \.fieldName) { detail in
                    FieldConflictDetailRow(detail: detail)
                }
            }
            .navigationTitle("Field Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FieldConflictDetailRow: View {
    let detail: FieldConflictDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.fieldName)
                .font(.headline)
            
            Text(detail.conflictType.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Local: \(detail.localValue)")
                    .font(.body)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text("Server: \(detail.serverValue)")
                    .font(.body)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConflictStatisticsView: View {
    @StateObject private var conflictService = ConflictLoggingService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    overviewSection
                    severityBreakdownSection
                    resolutionRateSection
                }
                .padding()
            }
            .navigationTitle("Conflict Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Total Conflicts",
                    value: "\(conflictService.conflictStatistics.totalConflicts)",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Resolved",
                    value: "\(conflictService.conflictStatistics.totalResolved)",
                    color: .green
                )
                
                StatisticCard(
                    title: "Pending",
                    value: "\(conflictService.conflictStatistics.pendingConflicts)",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Resolution Rate",
                    value: "\(Int(conflictService.conflictStatistics.resolutionRate * 100))%",
                    color: .purple
                )
            }
        }
    }
    
    private var severityBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Severity Breakdown")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Critical",
                    value: "\(conflictService.conflictStatistics.criticalCount)",
                    color: .red
                )
                
                StatisticCard(
                    title: "High",
                    value: "\(conflictService.conflictStatistics.highCount)",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Medium",
                    value: "\(conflictService.conflictStatistics.mediumCount)",
                    color: .yellow
                )
                
                StatisticCard(
                    title: "Low",
                    value: "\(conflictService.conflictStatistics.lowCount)",
                    color: .blue
                )
            }
        }
    }
    
    private var resolutionRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolution Performance")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Last Updated:")
                    Spacer()
                    Text(conflictService.conflictStatistics.lastUpdated.formatted())
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ConflictViewer()
}
