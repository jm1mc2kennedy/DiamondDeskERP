//
//  DocumentListView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// Enterprise Document Management List View
/// Modern iOS 16+ design with comprehensive document management features
struct DocumentListView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = DocumentViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Layout Configuration
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.documents.isEmpty {
                    loadingView
                } else if viewModel.filteredDocuments.isEmpty {
                    emptyStateView
                } else {
                    documentListContent
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    toolbarContent
                }
                
                ToolbarItemGroup(placement: .topBarLeading) {
                    if viewModel.activeFiltersCount > 0 {
                        filterIndicator
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search documents...")
            .refreshable {
                viewModel.refresh()
            }
        }
        .sheet(isPresented: $viewModel.showingCreateSheet) {
            CreateDocumentView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            DocumentFilterView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAdvancedSearchSheet) {
            AdvancedDocumentSearchView()
        }
        .sheet(isPresented: $viewModel.showingDetailView) {
            if let document = viewModel.selectedDocument {
                DocumentDetailView(document: document, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let shareURL = viewModel.shareURL {
                ActivityViewController(activityItems: [shareURL])
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
        .alert("Delete Document", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let document = viewModel.selectedDocument {
                    viewModel.deleteDocument(document)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this document? This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadDocuments()
        }
    }
    
    // MARK: - Toolbar Content
    
    @ViewBuilder
    private var toolbarContent: some View {
        Button {
            viewModel.showAdvancedSearch()
        } label: {
            Image(systemName: "doc.text.magnifyingglass")
        }
        
        Button {
            viewModel.showFilterSheet()
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.activeFiltersCount > 0 ? .accentColor : .primary)
        }
        
        Button {
            viewModel.showCreateSheet()
        } label: {
            Image(systemName: "plus.circle.fill")
        }
    }
    
    @ViewBuilder
    private var filterIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.caption)
            Text("\(viewModel.activeFiltersCount)")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.accentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    // MARK: - Document List Content
    
    @ViewBuilder
    private var documentListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Statistics Header
                if !viewModel.searchText.isEmpty || viewModel.activeFiltersCount > 0 {
                    searchResultsHeader
                }
                
                // Quick Stats
                documentStatsView
                
                // Documents Grid/List
                if isCompact {
                    documentListLayout
                } else {
                    documentGridLayout
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var searchResultsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.filteredDocuments.count) documents")
                    .font(.title2.weight(.semibold))
                
                if !viewModel.searchText.isEmpty {
                    Text("Results for \"\(viewModel.searchText)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if viewModel.activeFiltersCount > 0 {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom)
    }
    
    @ViewBuilder
    private var documentStatsView: some View {
        if let stats = viewModel.documentStatistics {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total",
                    value: "\(stats.totalDocuments)",
                    icon: "doc.text",
                    color: .blue
                )
                
                StatCard(
                    title: "Storage",
                    value: ByteCountFormatter.string(fromByteCount: stats.totalFileSize, countStyle: .file),
                    icon: "internaldrive",
                    color: .green
                )
                
                StatCard(
                    title: "Recent",
                    value: "\(stats.recentlyModified)",
                    icon: "clock",
                    color: .orange
                )
            }
            .padding(.bottom)
        }
    }
    
    @ViewBuilder
    private var documentListLayout: some View {
        LazyVStack(spacing: 1) {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentRowView(document: document, viewModel: viewModel)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var documentGridLayout: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentCardView(document: document, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading documents...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State View
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Documents")
                    .font(.title2.weight(.semibold))
                
                Text("Upload your first document to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.showCreateSheet()
            } label: {
                Label("Upload Document", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Document Row View

struct DocumentRowView: View {
    let document: DocumentModel
    @ObservedObject var viewModel: DocumentViewModel
    
    var body: some View {
        Button {
            viewModel.selectDocument(document)
        } label: {
            HStack(spacing: 12) {
                // Document Icon
                documentIcon
                
                // Document Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(document.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(document.category.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(document.category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(document.category.color.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(document.modifiedAt.formatted(.relative(presentation: .numeric)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicators
                VStack(spacing: 4) {
                    if document.checkedOutBy != nil {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    accessLevelIndicator
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.tertiary)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            documentContextMenu
        }
    }
    
    @ViewBuilder
    private var documentIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(document.fileType.color.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: document.fileType.systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(document.fileType.color)
        }
    }
    
    @ViewBuilder
    private var accessLevelIndicator: some View {
        Circle()
            .fill(document.accessLevel.color)
            .frame(width: 8, height: 8)
    }
    
    @ViewBuilder
    private var documentContextMenu: some View {
        Button {
            viewModel.selectDocument(document)
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        Button {
            viewModel.shareDocument(document)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button {
            viewModel.exportDocument(document)
        } label: {
            Label("Export", systemImage: "square.and.arrow.down")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.confirmDeleteDocument(document)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Document Card View

struct DocumentCardView: View {
    let document: DocumentModel
    @ObservedObject var viewModel: DocumentViewModel
    
    var body: some View {
        Button {
            viewModel.selectDocument(document)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and access level
                HStack {
                    documentIcon
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        accessLevelIndicator
                        
                        if document.checkedOutBy != nil {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Document info
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(document.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let description = document.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Footer with metadata
                VStack(spacing: 8) {
                    HStack {
                        Text(document.category.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(document.category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(document.category.color.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(document.modifiedAt.formatted(.relative(presentation: .numeric)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !document.tags.isEmpty {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 200)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            documentContextMenu
        }
    }
    
    @ViewBuilder
    private var documentIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(document.fileType.color.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: document.fileType.systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(document.fileType.color)
        }
    }
    
    @ViewBuilder
    private var accessLevelIndicator: some View {
        Circle()
            .fill(document.accessLevel.color)
            .frame(width: 8, height: 8)
    }
    
    @ViewBuilder
    private var documentContextMenu: some View {
        Button {
            viewModel.selectDocument(document)
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        Button {
            viewModel.shareDocument(document)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button {
            viewModel.exportDocument(document)
        } label: {
            Label("Export", systemImage: "square.and.arrow.down")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.confirmDeleteDocument(document)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Stat Card View

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extensions

extension DocumentCategory {
    var color: Color {
        switch self {
        case .financial:
            return .green
        case .legal:
            return .blue
        case .hr:
            return .purple
        case .marketing:
            return .orange
        case .operations:
            return .red
        case .technical:
            return .cyan
        case .general:
            return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .financial:
            return "Financial"
        case .legal:
            return "Legal"
        case .hr:
            return "HR"
        case .marketing:
            return "Marketing"
        case .operations:
            return "Operations"
        case .technical:
            return "Technical"
        case .general:
            return "General"
        }
    }
}

extension DocumentAccessLevel {
    var color: Color {
        switch self {
        case .public:
            return .green
        case .internal:
            return .blue
        case .confidential:
            return .orange
        case .restricted:
            return .red
        case .topSecret:
            return .purple
        }
    }
}

extension DocumentFileType {
    var color: Color {
        switch self {
        case .pdf:
            return .red
        case .word:
            return .blue
        case .excel:
            return .green
        case .powerpoint:
            return .orange
        case .text:
            return .gray
        case .image:
            return .purple
        case .video:
            return .pink
        case .audio:
            return .cyan
        case .archive:
            return .brown
        case .other:
            return .secondary
        }
    }
    
    var systemImage: String {
        switch self {
        case .pdf:
            return "doc.richtext"
        case .word:
            return "doc.text"
        case .excel:
            return "tablecells"
        case .powerpoint:
            return "slider.horizontal.below.rectangle"
        case .text:
            return "doc.plaintext"
        case .image:
            return "photo"
        case .video:
            return "video"
        case .audio:
            return "music.note"
        case .archive:
            return "archivebox"
        case .other:
            return "doc"
        }
    }
}

// MARK: - Activity View Controller Wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview {
    DocumentListView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    DocumentListView()
        .preferredColorScheme(.dark)
}
