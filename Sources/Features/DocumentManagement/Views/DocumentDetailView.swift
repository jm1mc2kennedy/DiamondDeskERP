//
//  DocumentDetailView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import QuickLook

/// Document Detail View
/// Comprehensive document viewing and management interface
struct DocumentDetailView: View {
    
    // MARK: - Properties
    
    let document: DocumentModel
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var showingQuickLook = false
    @State private var quickLookURL: URL?
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var showingEditMode = false
    @State private var showingShareSheet = false
    @State private var showingVersionHistory = false
    @State private var showingCollaboration = false
    
    // MARK: - Computed Properties
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isDownloading {
                    downloadingView
                } else {
                    documentDetailContent
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingCollaboration = true
                    } label: {
                        Image(systemName: "person.2.fill")
                    }
                    
                    Menu {
                        documentMenuItems
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingQuickLook) {
            if let url = quickLookURL {
                QuickLookView(url: url)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = quickLookURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingVersionHistory) {
            DocumentVersionHistoryView(document: document)
        }
        .sheet(isPresented: $showingCollaboration) {
            DocumentCollaborationView(document: document)
        }
    }
    
    // MARK: - Document Detail Content
    
    @ViewBuilder
    private var documentDetailContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Document Preview
                documentPreviewSection
                
                // Quick Actions
                quickActionsSection
                
                // Document Information
                documentInformationSection
                
                // Metadata Section
                metadataSection
                
                // Security & Access
                securitySection
                
                // Activity Timeline
                activityTimelineSection
                
                // Version History
                versionHistorySection
            }
            .padding()
        }
    }
    
    // MARK: - Document Preview Section
    
    @ViewBuilder
    private var documentPreviewSection: some View {
        VStack(spacing: 16) {
            // File icon and basic info
            HStack(spacing: 16) {
                // Large file icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(document.fileType.color.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: document.fileType.systemImage)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(document.fileType.color)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.fileName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(document.fileType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(document.accessLevel.color)
                            .frame(width: 8, height: 8)
                        
                        Text(document.accessLevel.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(document.accessLevel.color)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Description if available
            if let description = document.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    @ViewBuilder
    private var quickActionsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            QuickActionCard(
                title: "View",
                icon: "eye.fill",
                color: .blue
            ) {
                downloadAndView()
            }
            
            QuickActionCard(
                title: "Share",
                icon: "square.and.arrow.up",
                color: .green
            ) {
                shareDocument()
            }
            
            QuickActionCard(
                title: "Download",
                icon: "arrow.down.circle",
                color: .orange
            ) {
                downloadDocument()
            }
        }
    }
    
    // MARK: - Document Information Section
    
    @ViewBuilder
    private var documentInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(label: "Category", value: document.category.displayName, color: document.category.color)
                InfoRow(label: "Status", value: document.status.displayName, color: document.status.color)
                InfoRow(label: "Owner", value: document.ownerUserId) // TODO: Resolve to user name
                
                if !document.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                            ForEach(document.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Metadata Section
    
    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Metadata")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(label: "Created", value: document.createdAt.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Modified", value: document.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                
                if let lastAccessed = document.lastAccessedAt {
                    InfoRow(label: "Last Accessed", value: lastAccessed.formatted(date: .abbreviated, time: .shortened))
                }
                
                InfoRow(label: "Version", value: "v\(document.version)")
                
                if let hash = document.documentHash {
                    InfoRow(label: "Checksum", value: String(hash.prefix(16) + "..."))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Security Section
    
    @ViewBuilder
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security & Access")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(document.accessLevel.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Access Level")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Text(document.accessLevel.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(document.accessLevel.color)
                        .frame(width: 12, height: 12)
                }
                
                if document.checkedOutBy != nil {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Checked Out")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            
                            Text("By \(document.checkedOutBy ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let expiration = document.lockExpiration {
                            Text("Expires \(expiration.formatted(.relative(presentation: .numeric)))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if !document.collaboratorUserIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collaborators")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        ForEach(document.collaboratorUserIds.prefix(3), id: \.self) { userId in
                            HStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(String(userId.prefix(2)).uppercased())
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(userId) // TODO: Resolve to user name
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        
                        if document.collaboratorUserIds.count > 3 {
                            Text("And \(document.collaboratorUserIds.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Activity Timeline Section
    
    @ViewBuilder
    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ActivityTimelineItem(
                    icon: "pencil",
                    title: "Document Modified",
                    subtitle: "By \(document.modifiedBy ?? "Unknown")",
                    timestamp: document.modifiedAt,
                    color: .blue
                )
                
                if let lastAccessed = document.lastAccessedAt {
                    ActivityTimelineItem(
                        icon: "eye",
                        title: "Document Viewed",
                        subtitle: "By \(document.lastAccessedBy ?? "Unknown")",
                        timestamp: lastAccessed,
                        color: .green
                    )
                }
                
                ActivityTimelineItem(
                    icon: "plus",
                    title: "Document Created",
                    subtitle: "By \(document.createdBy ?? "Unknown")",
                    timestamp: document.createdAt,
                    color: .purple
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Version History Section
    
    @ViewBuilder
    private var versionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Version History")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    showingVersionHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 12) {
                VersionHistoryItem(
                    version: "v\(document.version)",
                    description: "Current version",
                    timestamp: document.modifiedAt,
                    author: document.modifiedBy ?? "Unknown",
                    isCurrent: true
                )
                
                // TODO: Add historical versions when available
                if document.version > 1 {
                    VersionHistoryItem(
                        version: "v\(document.version - 1)",
                        description: "Previous version",
                        timestamp: document.createdAt,
                        author: document.createdBy ?? "Unknown",
                        isCurrent: false
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Document Menu Items
    
    @ViewBuilder
    private var documentMenuItems: some View {
        Button {
            downloadAndView()
        } label: {
            Label("View Document", systemImage: "eye")
        }
        
        Button {
            shareDocument()
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button {
            downloadDocument()
        } label: {
            Label("Download", systemImage: "arrow.down.circle")
        }
        
        Divider()
        
        if document.checkedOutBy == nil {
            Button {
                viewModel.checkoutDocument(document)
            } label: {
                Label("Check Out", systemImage: "lock")
            }
        } else {
            Button {
                viewModel.checkinDocument(document)
            } label: {
                Label("Check In", systemImage: "lock.open")
            }
        }
        
        Button {
            showingVersionHistory = true
        } label: {
            Label("Version History", systemImage: "clock.arrow.circlepath")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.confirmDeleteDocument(document)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Downloading View
    
    @ViewBuilder
    private var downloadingView: some View {
        VStack(spacing: 24) {
            ProgressView(value: downloadProgress)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Downloading...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Preparing document for viewing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func downloadAndView() {
        Task {
            do {
                isDownloading = true
                downloadProgress = 0.0
                
                let data = try await viewModel.downloadDocument(document)
                
                // Create temporary file
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(document.fileName)
                
                try data.write(to: tempURL)
                
                await MainActor.run {
                    quickLookURL = tempURL
                    showingQuickLook = true
                    isDownloading = false
                }
                
            } catch {
                isDownloading = false
                viewModel.error = .invalidRecord(error.localizedDescription)
                viewModel.showingError = true
            }
        }
    }
    
    private func shareDocument() {
        Task {
            do {
                let data = try await viewModel.downloadDocument(document)
                
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(document.fileName)
                
                try data.write(to: tempURL)
                
                await MainActor.run {
                    quickLookURL = tempURL
                    showingShareSheet = true
                }
                
            } catch {
                viewModel.error = .invalidRecord(error.localizedDescription)
                viewModel.showingError = true
            }
        }
    }
    
    private func downloadDocument() {
        viewModel.exportDocument(document)
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var color: Color = .secondary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

struct ActivityTimelineItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let timestamp: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.caption.weight(.medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timestamp.formatted(.relative(presentation: .numeric)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct VersionHistoryItem: View {
    let version: String
    let description: String
    let timestamp: Date
    let author: String
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isCurrent ? Color.accentColor : Color.secondary)
                    .frame(width: 8, height: 8)
                
                if !isCurrent {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(version)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isCurrent ? .accentColor : .primary)
                    
                    if isCurrent {
                        Text("CURRENT")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("By \(author) • \(timestamp.formatted(.relative(presentation: .numeric)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Quick Look and Share Views

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Document Version History View

struct DocumentVersionHistoryView: View {
    let document: DocumentModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Version history will be implemented with full document versioning system")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension DocumentFileType {
    var displayName: String {
        switch self {
        case .pdf:
            return "PDF Document"
        case .word:
            return "Word Document"
        case .excel:
            return "Excel Spreadsheet"
        case .powerpoint:
            return "PowerPoint Presentation"
        case .text:
            return "Text Document"
        case .image:
            return "Image File"
        case .video:
            return "Video File"
        case .audio:
            return "Audio File"
        case .archive:
            return "Archive File"
        case .other:
            return "Document"
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentDetailView(
        document: DocumentModel(
            title: "Sample Document",
            fileName: "sample.pdf",
            fileType: .pdf,
            fileSize: 1024 * 1024,
            mimeType: "application/pdf",
            category: .financial,
            accessLevel: .internal,
            ownerUserId: "user123",
            createdBy: "user123"
        ),
        viewModel: DocumentViewModel()
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    DocumentDetailView(
        document: DocumentModel(
            title: "Sample Document",
            fileName: "sample.pdf",
            fileType: .pdf,
            fileSize: 1024 * 1024,
            mimeType: "application/pdf",
            category: .financial,
            accessLevel: .internal,
            ownerUserId: "user123",
            createdBy: "user123"
        ),
        viewModel: DocumentViewModel()
    )
    .preferredColorScheme(.dark)
}
