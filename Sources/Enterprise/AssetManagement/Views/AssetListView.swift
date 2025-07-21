import SwiftUI
import UniformTypeIdentifiers

struct AssetListView: View {
    @StateObject private var viewModel = AssetManagementViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header with statistics
                AssetHeaderView(viewModel: viewModel)
                
                // Search and filters
                AssetFilterView(viewModel: viewModel)
                
                // Main content
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading Assets...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        ErrorView(error: error) {
                            Task { await viewModel.refreshData() }
                        }
                    } else if viewModel.filteredAssets.isEmpty {
                        EmptyAssetsView {
                            viewModel.showingUpload = true
                        }
                    } else {
                        AssetContentView(
                            assets: viewModel.filteredAssets,
                            viewMode: viewModel.viewMode,
                            viewModel: viewModel,
                            navigationPath: $navigationPath
                        )
                    }
                }
                
                // Upload progress overlay
                if viewModel.isUploading {
                    UploadProgressView(progress: viewModel.uploadProgress)
                }
            }
            .navigationTitle("Assets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Storage Usage") {
                            // TODO: Show storage analytics
                        }
                        
                        Divider()
                        
                        Picker("View Mode", selection: $viewModel.viewMode) {
                            ForEach(AssetViewMode.allCases, id: \.self) { mode in
                                Label(mode.displayName, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button {
                        viewModel.showingUpload = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingUpload) {
                AssetUploadView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingAssetPreview) {
                if let asset = viewModel.previewAsset {
                    AssetPreviewView(asset: asset, viewModel: viewModel)
                }
            }
            .navigationDestination(for: String.self) { assetId in
                AssetDetailView(assetId: assetId, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Supporting Views

struct AssetHeaderView: View {
    @ObservedObject var viewModel: AssetManagementViewModel
    
    var body: some View {
        if let analytics = viewModel.analytics {
            VStack(spacing: 12) {
                HStack {
                    AssetStatCard(
                        title: "Total",
                        value: "\(analytics.totalAssets)",
                        icon: "doc.fill",
                        color: .blue
                    )
                    
                    AssetStatCard(
                        title: "Storage",
                        value: analytics.formattedTotalSize,
                        icon: "internaldrive.fill",
                        color: .purple
                    )
                    
                    AssetStatCard(
                        title: "Public",
                        value: "\(analytics.publicAssets)",
                        icon: "globe",
                        color: .green
                    )
                    
                    AssetStatCard(
                        title: "Today",
                        value: "\(analytics.recentUploads)",
                        icon: "arrow.up.circle.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Storage usage bar
                if let storage = viewModel.storageUsage {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Storage Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(storage.formattedUsed) of \(storage.formattedAvailable)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: storage.usagePercentage)
                            .tint(storage.usagePercentage > 0.8 ? .red : storage.usagePercentage > 0.6 ? .orange : .blue)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct AssetStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AssetFilterView: View {
    @ObservedObject var viewModel: AssetManagementViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search assets...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button("Clear") {
                        viewModel.searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "Public Only",
                        isSelected: viewModel.showPublicOnly
                    ) {
                        viewModel.showPublicOnly.toggle()
                    }
                    
                    ForEach(AssetType.allCases, id: \.self) { assetType in
                        FilterChip(
                            title: assetType.displayName,
                            isSelected: viewModel.selectedAssetType == assetType
                        ) {
                            if viewModel.selectedAssetType == assetType {
                                viewModel.selectedAssetType = nil
                            } else {
                                viewModel.selectedAssetType = assetType
                            }
                        }
                    }
                    
                    if !viewModel.categories.isEmpty {
                        Menu {
                            Button("All Categories") {
                                viewModel.selectedCategory = nil
                            }
                            
                            ForEach(viewModel.categories, id: \.self) { category in
                                Button(category) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedCategory ?? "Category")
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.selectedCategory != nil ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(viewModel.selectedCategory != nil ? .white : .primary)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AssetContentView: View {
    let assets: [Asset]
    let viewMode: AssetViewMode
    @ObservedObject var viewModel: AssetManagementViewModel
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        switch viewMode {
        case .grid:
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160))
                ], spacing: 16) {
                    ForEach(assets) { asset in
                        AssetGridItem(asset: asset, viewModel: viewModel)
                            .onTapGesture {
                                navigationPath.append(asset.id)
                            }
                    }
                }
                .padding()
            }
        case .list:
            List(assets) { asset in
                AssetListItem(asset: asset, viewModel: viewModel)
                    .onTapGesture {
                        navigationPath.append(asset.id)
                    }
            }
        case .gallery:
            AssetGalleryView(assets: assets, viewModel: viewModel)
        }
    }
}

struct AssetGridItem: View {
    let asset: Asset
    @ObservedObject var viewModel: AssetManagementViewModel
    @State private var thumbnailData: Data?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                
                Group {
                    if let thumbnailData = thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        Image(systemName: asset.type.systemImage)
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Overlay for asset type and status
                VStack {
                    HStack {
                        AssetTypeBadge(type: asset.type)
                        Spacer()
                        if asset.isPublic {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Circle().fill(Color.white))
                        }
                    }
                    Spacer()
                }
                .padding(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(ByteCountFormatter.string(fromByteCount: asset.fileSize, countStyle: .file))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(asset.uploadDate.formatted(.relative(presentation: .numeric)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 160)
        .task {
            if asset.type == .image {
                thumbnailData = await viewModel.generateThumbnail(for: asset)
            }
        }
    }
}

struct AssetListItem: View {
    let asset: Asset
    @ObservedObject var viewModel: AssetManagementViewModel
    @State private var thumbnailData: Data?
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            Group {
                if let thumbnailData = thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Image(systemName: asset.type.systemImage)
                        .font(.title2)
                        .foregroundColor(asset.type.color)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(asset.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    AssetTypeBadge(type: asset.type)
                    
                    if asset.isPublic {
                        Image(systemName: "globe")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Text(ByteCountFormatter.string(fromByteCount: asset.fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let category = asset.category {
                        Text("• \(category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(asset.uploadDate.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !asset.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(asset.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            VStack {
                Button {
                    Task {
                        _ = await viewModel.downloadAsset(asset)
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Menu {
                    Button("Preview") {
                        viewModel.previewAsset = asset
                        viewModel.showingAssetPreview = true
                    }
                    
                    Button("Share") {
                        // TODO: Implement sharing
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.deleteAsset(asset)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .task {
            if asset.type == .image {
                thumbnailData = await viewModel.generateThumbnail(for: asset)
            }
        }
    }
}

struct AssetTypeBadge: View {
    let type: AssetType
    
    var body: some View {
        Text(type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(type.color.opacity(0.2))
            .foregroundColor(type.color)
            .cornerRadius(4)
    }
}

struct AssetGalleryView: View {
    let assets: [Asset]
    @ObservedObject var viewModel: AssetManagementViewModel
    
    var imageAssets: [Asset] {
        assets.filter { $0.type == .image }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(imageAssets.chunked(into: 3), id: \.first?.id) { row in
                    HStack(spacing: 1) {
                        ForEach(row, id: \.id) { asset in
                            AssetGalleryItem(asset: asset, viewModel: viewModel)
                        }
                        
                        // Fill remaining space if row is incomplete
                        if row.count < 3 {
                            ForEach(0..<(3 - row.count), id: \.self) { _ in
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AssetGalleryItem: View {
    let asset: Asset
    @ObservedObject var viewModel: AssetManagementViewModel
    @State private var thumbnailData: Data?
    
    var body: some View {
        Button {
            viewModel.previewAsset = asset
            viewModel.showingAssetPreview = true
        } label: {
            Group {
                if let thumbnailData = thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: asset.type.systemImage)
                        .font(.title)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
        }
        .task {
            thumbnailData = await viewModel.generateThumbnail(for: asset)
        }
    }
}

struct UploadProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Uploading...")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding()
    }
}

struct EmptyAssetsView: View {
    let uploadAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Assets Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Upload your first asset to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Upload Asset") {
                uploadAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extensions

extension AssetType {
    var color: Color {
        switch self {
        case .image: return .green
        case .document: return .blue
        case .video: return .red
        case .audio: return .purple
        case .archive: return .orange
        case .spreadsheet: return .green
        case .presentation: return .orange
        case .code: return .gray
        case .other: return .secondary
        }
    }
    
    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc.text"
        case .video: return "video"
        case .audio: return "waveform"
        case .archive: return "archivebox"
        case .spreadsheet: return "tablecells"
        case .presentation: return "rectangle.on.rectangle"
        case .code: return "curlybraces"
        case .other: return "doc"
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    AssetListView()
}
