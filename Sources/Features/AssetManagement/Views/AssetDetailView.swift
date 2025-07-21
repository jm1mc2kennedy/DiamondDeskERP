import SwiftUI

struct AssetDetailView: View {
    @StateObject private var viewModel: AssetManagementViewModel
    @State private var showingPreview = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    
    let asset: Asset
    @Environment(\.dismiss) private var dismiss
    
    init(asset: Asset, viewModel: AssetManagementViewModel) {
        self.asset = asset
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                AssetHeaderView(asset: asset, viewModel: viewModel)
                
                // Preview Section
                if asset.type == .image || asset.type == .video || asset.type == .document {
                    AssetPreviewSection(
                        asset: asset,
                        viewModel: viewModel,
                        showingPreview: $showingPreview
                    )
                }
                
                // Details Section
                AssetDetailsSection(asset: asset)
                
                // Usage Statistics
                AssetUsageSection(asset: asset, viewModel: viewModel)
                
                // Action Buttons
                AssetActionButtons(
                    asset: asset,
                    viewModel: viewModel,
                    showingShareSheet: $showingShareSheet,
                    showingDeleteAlert: $showingDeleteAlert,
                    showingEditSheet: $showingEditSheet,
                    downloadProgress: $downloadProgress,
                    isDownloading: $isDownloading
                )
                
                // Version History
                if !asset.versionHistory.isEmpty {
                    AssetVersionHistorySection(asset: asset, viewModel: viewModel)
                }
                
                // Comments Section
                AssetCommentsSection(asset: asset, viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    if asset.type == .image || asset.type == .video || asset.type == .document {
                        Button(action: { showingPreview = true }) {
                            Label("Preview", systemImage: "eye")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            AssetPreviewView(asset: asset, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditSheet) {
            AssetEditView(asset: asset, viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [asset.name])
        }
        .alert("Delete Asset", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAsset(asset.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(asset.name)? This action cannot be undone.")
        }
        .task {
            await viewModel.trackAssetUsage(assetId: asset.id, action: .viewed)
        }
    }
}

// MARK: - Asset Header View

struct AssetHeaderView: View {
    let asset: Asset
    let viewModel: AssetManagementViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Asset Icon/Thumbnail
            AsyncImage(url: viewModel.getThumbnailURL(for: asset.id)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: asset.type.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(asset.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(ByteCountFormatter.string(fromByteCount: asset.fileSize, countStyle: .file),
                          systemImage: "doc")
                    
                    if let category = asset.category {
                        Label(category, systemImage: "folder")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    if asset.isPublic {
                        Label("Public", systemImage: "globe")
                            .foregroundColor(.blue)
                    } else {
                        Label("Private", systemImage: "lock")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption2)
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// MARK: - Asset Preview Section

struct AssetPreviewSection: View {
    let asset: Asset
    let viewModel: AssetManagementViewModel
    @Binding var showingPreview: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            Button(action: { showingPreview = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "eye")
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                        
                        Text("Tap to Preview")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Asset Details Section

struct AssetDetailsSection: View {
    let asset: Asset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailItem(title: "Uploaded By", value: asset.uploadedBy)
                DetailItem(title: "Upload Date", value: formatDate(asset.uploadDate))
                DetailItem(title: "File Size", value: ByteCountFormatter.string(fromByteCount: asset.fileSize, countStyle: .file))
                DetailItem(title: "MIME Type", value: asset.mimeType)
                
                if let lastModified = asset.lastModified {
                    DetailItem(title: "Last Modified", value: formatDate(lastModified))
                }
                
                if let version = asset.version {
                    DetailItem(title: "Version", value: version)
                }
            }
            
            if !asset.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(asset.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top)
            }
            
            if let description = asset.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Item

struct DetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Asset Usage Section

struct AssetUsageSection: View {
    let asset: Asset
    let viewModel: AssetManagementViewModel
    @State private var usageStats: AssetUsageStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Statistics")
                .font(.headline)
            
            if let stats = usageStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    UsageStatItem(title: "Views", value: "\(stats.totalViews)", icon: "eye")
                    UsageStatItem(title: "Downloads", value: "\(stats.totalDownloads)", icon: "arrow.down.circle")
                    UsageStatItem(title: "Shares", value: "\(stats.totalShares)", icon: "square.and.arrow.up")
                }
                
                HStack {
                    UsageStatItem(title: "Unique Users", value: "\(stats.uniqueUsers)", icon: "person.2")
                    Spacer()
                    if let lastAccessed = stats.lastAccessed {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Last Accessed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(lastAccessed))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.top, 8)
            } else {
                ProgressView("Loading usage statistics...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .task {
            usageStats = await viewModel.getAssetUsageStats(assetId: asset.id)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Usage Stat Item

struct UsageStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Asset Action Buttons

struct AssetActionButtons: View {
    let asset: Asset
    let viewModel: AssetManagementViewModel
    @Binding var showingShareSheet: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingEditSheet: Bool
    @Binding var downloadProgress: Double
    @Binding var isDownloading: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: downloadAsset) {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isDownloading ? "Downloading..." : "Download")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isDownloading)
                
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            if isDownloading {
                ProgressView(value: downloadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            HStack(spacing: 12) {
                Button(action: { showingEditSheet = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private func downloadAsset() {
        Task {
            isDownloading = true
            downloadProgress = 0
            
            // Simulate download progress
            for i in 1...10 {
                downloadProgress = Double(i) / 10.0
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            await viewModel.downloadAsset(asset.id)
            await viewModel.trackAssetUsage(assetId: asset.id, action: .downloaded)
            
            isDownloading = false
            downloadProgress = 0
        }
    }
}

// MARK: - Asset Version History Section

struct AssetVersionHistorySection: View {
    let asset: Asset
    let viewModel: AssetManagementViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Version History")
                .font(.headline)
            
            ForEach(asset.versionHistory.prefix(5), id: \.version) { version in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version \(version.version)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(version.changeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDate(version.createdDate))
                            .font(.caption)
                        
                        Text(version.createdBy)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            if asset.versionHistory.count > 5 {
                Button("View All Versions (\(asset.versionHistory.count))") {
                    // Navigate to full version history
                }
                .foregroundColor(.blue)
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Asset Comments Section

struct AssetCommentsSection: View {
    let asset: Asset
    let viewModel: AssetManagementViewModel
    @State private var newComment = ""
    @State private var comments: [AssetComment] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)
            
            // Add Comment
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Post") {
                    addComment()
                }
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Comments List
            if comments.isEmpty {
                Text("No comments yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(comments.prefix(3), id: \.id) { comment in
                    CommentRow(comment: comment)
                }
                
                if comments.count > 3 {
                    Button("View All Comments (\(comments.count))") {
                        // Navigate to full comments view
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .task {
            await loadComments()
        }
    }
    
    private func addComment() {
        Task {
            let comment = AssetComment(
                assetId: asset.id,
                userId: "current_user", // Replace with actual current user
                content: newComment,
                timestamp: Date()
            )
            
            // Add comment through viewModel
            await viewModel.addComment(to: asset.id, comment: comment)
            newComment = ""
            await loadComments()
        }
    }
    
    private func loadComments() async {
        // Load comments from viewModel
        comments = await viewModel.getComments(for: asset.id)
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: AssetComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.userId)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formatDate(comment.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.content)
                .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AssetDetailView(
            asset: Asset(
                name: "Sample Document.pdf",
                type: .document,
                category: "Reports",
                tags: ["important", "quarterly"],
                uploadedBy: "john.doe",
                uploadDate: Date(),
                storagePath: "/documents/sample.pdf",
                fileSize: 2048576,
                mimeType: "application/pdf",
                description: "Sample document for preview purposes",
                isPublic: false
            ),
            viewModel: AssetManagementViewModel(service: MockAssetManagementService())
        )
    }
}
