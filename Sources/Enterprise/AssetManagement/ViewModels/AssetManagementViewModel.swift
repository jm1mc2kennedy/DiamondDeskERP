import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Asset Management View Model

@MainActor
public class AssetManagementViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var assets: [Asset] = []
    @Published public var recentAssets: [Asset] = []
    @Published public var publicAssets: [Asset] = []
    @Published public var filteredAssets: [Asset] = []
    
    @Published public var searchText = ""
    @Published public var selectedAssetType: AssetType?
    @Published public var selectedCategory: String?
    @Published public var showPublicOnly = false
    @Published public var viewMode: AssetViewMode = .grid
    
    @Published public var isLoading = false
    @Published public var isUploading = false
    @Published public var uploadProgress: Double = 0.0
    @Published public var error: AssetError?
    @Published public var showingUpload = false
    @Published public var showingCategoryFilter = false
    
    @Published public var selectedAsset: Asset?
    @Published public var previewAsset: Asset?
    @Published public var showingAssetPreview = false
    
    // MARK: - Analytics Data
    
    @Published public var analytics: AssetAnalytics?
    @Published public var storageUsage: StorageUsage?
    @Published public var categories: [String] = []
    
    // MARK: - Services
    
    private let assetService: AssetManagementServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(assetService: AssetManagementServiceProtocol = AssetManagementService()) {
        self.assetService = assetService
        setupBindings()
        setupSearchAndFilters()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        if let service = assetService as? AssetManagementService {
            service.$assets
                .receive(on: DispatchQueue.main)
                .assign(to: \.assets, on: self)
                .store(in: &cancellables)
            
            service.$recentAssets
                .receive(on: DispatchQueue.main)
                .assign(to: \.recentAssets, on: self)
                .store(in: &cancellables)
            
            service.$publicAssets
                .receive(on: DispatchQueue.main)
                .assign(to: \.publicAssets, on: self)
                .store(in: &cancellables)
            
            service.$isLoading
                .receive(on: DispatchQueue.main)
                .assign(to: \.isLoading, on: self)
                .store(in: &cancellables)
            
            service.$uploadProgress
                .receive(on: DispatchQueue.main)
                .assign(to: \.uploadProgress, on: self)
                .store(in: &cancellables)
            
            service.$error
                .receive(on: DispatchQueue.main)
                .map { $0.map(AssetError.serviceError) }
                .assign(to: \.error, on: self)
                .store(in: &cancellables)
        }
    }
    
    private func setupSearchAndFilters() {
        Publishers.CombineLatest4($assets, $searchText, $selectedAssetType, $showPublicOnly)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { assets, searchText, assetType, publicOnly in
                self.filterAssets(assets, searchText: searchText, assetType: assetType, publicOnly: publicOnly)
            }
            .assign(to: \.filteredAssets, on: self)
            .store(in: &cancellables)
        
        // Update categories when assets change
        $assets
            .map { assets in
                Set(assets.compactMap { $0.category }).sorted()
            }
            .assign(to: \.categories, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading Methods
    
    public func loadData() async {
        do {
            await MainActor.run { isLoading = true }
            _ = try await assetService.fetchAssets()
            _ = try await assetService.fetchPublicAssets()
            await loadAnalytics()
        } catch {
            await MainActor.run { 
                self.error = AssetError.loadingFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func refreshData() async {
        await loadData()
    }
    
    private func loadAnalytics() async {
        let totalAssets = assets.count
        let totalSize = assets.reduce(0) { $0 + $1.fileSize }
        let publicCount = assets.filter { $0.isPublic }.count
        let privateCount = totalAssets - publicCount
        
        analytics = AssetAnalytics(
            totalAssets: totalAssets,
            totalSize: totalSize,
            publicAssets: publicCount,
            privateAssets: privateCount,
            assetsByType: Dictionary(grouping: assets, by: { $0.type }).mapValues { $0.count },
            recentUploads: assets.filter { Calendar.current.isDateInToday($0.uploadDate) }.count
        )
        
        storageUsage = StorageUsage(
            totalUsed: totalSize,
            totalAvailable: 1_000_000_000, // 1GB limit as placeholder
            usageByType: Dictionary(grouping: assets, by: { $0.type })
                .mapValues { $0.reduce(0) { $0 + $1.fileSize } }
        )
    }
    
    // MARK: - Asset Operations
    
    public func uploadAsset(data: Data, name: String, type: AssetType, metadata: AssetMetadata? = nil) async {
        do {
            await MainActor.run { 
                isUploading = true
                error = nil
            }
            
            _ = try await assetService.uploadAsset(data: data, name: name, type: type, metadata: metadata)
            
            await MainActor.run { 
                isUploading = false
                showingUpload = false
            }
            
            await refreshData()
        } catch {
            await MainActor.run { 
                self.error = AssetError.uploadFailed(error.localizedDescription)
                isUploading = false
            }
        }
    }
    
    public func downloadAsset(_ asset: Asset) async -> Data? {
        do {
            return try await assetService.downloadAsset(id: asset.id)
        } catch {
            await MainActor.run { 
                self.error = AssetError.downloadFailed(error.localizedDescription)
            }
            return nil
        }
    }
    
    public func deleteAsset(_ asset: Asset) async {
        do {
            await MainActor.run { isLoading = true }
            try await assetService.deleteAsset(id: asset.id)
            await MainActor.run { isLoading = false }
            await refreshData()
        } catch {
            await MainActor.run { 
                self.error = AssetError.deletionFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func generateThumbnail(for asset: Asset) async -> Data? {
        do {
            return try await assetService.generateThumbnail(for: asset.id)
        } catch {
            await MainActor.run { 
                self.error = AssetError.thumbnailFailed
            }
            return nil
        }
    }
    
    public func searchAssets(_ query: String) async {
        if query.isEmpty {
            searchText = ""
            return
        }
        
        do {
            let results = try await assetService.searchAssets(query: query)
            await MainActor.run { 
                filteredAssets = results
                searchText = query
            }
        } catch {
            await MainActor.run { 
                self.error = AssetError.searchFailed(error.localizedDescription)
            }
        }
    }
    
    public func getAssetUsageStats(for asset: Asset) async -> AssetUsageStats? {
        do {
            return try await assetService.getAssetUsageStats(assetId: asset.id)
        } catch {
            await MainActor.run { 
                self.error = AssetError.statsFailed
            }
            return nil
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func filterAssets(_ assets: [Asset], searchText: String, assetType: AssetType?, publicOnly: Bool) -> [Asset] {
        var filtered = assets
        
        // Filter by public/private
        if publicOnly {
            filtered = filtered.filter { $0.isPublic }
        }
        
        // Filter by asset type
        if let assetType = assetType {
            filtered = filtered.filter { $0.type == assetType }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { asset in
                asset.name.localizedCaseInsensitiveContains(searchText) ||
                asset.category?.localizedCaseInsensitiveContains(searchText) == true ||
                asset.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted { $0.uploadDate > $1.uploadDate }
    }
}

// MARK: - Supporting Types

public enum AssetViewMode: CaseIterable {
    case grid
    case list
    case gallery
    
    public var displayName: String {
        switch self {
        case .grid: return "Grid"
        case .list: return "List"
        case .gallery: return "Gallery"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .gallery: return "photo.on.rectangle.angled"
        }
    }
}

public enum AssetError: LocalizedError {
    case loadingFailed(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case deletionFailed(String)
    case searchFailed(String)
    case thumbnailFailed
    case statsFailed
    case serviceError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load assets: \(message)"
        case .uploadFailed(let message):
            return "Failed to upload asset: \(message)"
        case .downloadFailed(let message):
            return "Failed to download asset: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete asset: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .thumbnailFailed:
            return "Failed to generate thumbnail"
        case .statsFailed:
            return "Failed to load usage statistics"
        case .serviceError(let error):
            return error.localizedDescription
        }
    }
}

public struct AssetAnalytics {
    public let totalAssets: Int
    public let totalSize: Int64
    public let publicAssets: Int
    public let privateAssets: Int
    public let assetsByType: [AssetType: Int]
    public let recentUploads: Int
    
    public init(totalAssets: Int, totalSize: Int64, publicAssets: Int, privateAssets: Int, assetsByType: [AssetType: Int], recentUploads: Int) {
        self.totalAssets = totalAssets
        self.totalSize = totalSize
        self.publicAssets = publicAssets
        self.privateAssets = privateAssets
        self.assetsByType = assetsByType
        self.recentUploads = recentUploads
    }
    
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

public struct StorageUsage {
    public let totalUsed: Int64
    public let totalAvailable: Int64
    public let usageByType: [AssetType: Int64]
    
    public init(totalUsed: Int64, totalAvailable: Int64, usageByType: [AssetType: Int64]) {
        self.totalUsed = totalUsed
        self.totalAvailable = totalAvailable
        self.usageByType = usageByType
    }
    
    public var usagePercentage: Double {
        guard totalAvailable > 0 else { return 0 }
        return Double(totalUsed) / Double(totalAvailable)
    }
    
    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: totalUsed, countStyle: .file)
    }
    
    public var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: totalAvailable, countStyle: .file)
    }
}
