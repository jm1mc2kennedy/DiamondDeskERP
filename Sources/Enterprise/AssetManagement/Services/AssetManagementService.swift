import Foundation
import CloudKit
import Combine
import UniformTypeIdentifiers

// MARK: - Asset Management Service Protocol
public protocol AssetManagementServiceProtocol {
    func fetchAssets() async throws -> [Asset]
    func fetchAsset(by id: String) async throws -> Asset?
    func fetchAssetsByType(_ type: AssetType) async throws -> [Asset]
    func fetchAssetsByCategory(_ category: String) async throws -> [Asset]
    func fetchAssetsByUser(_ userId: String) async throws -> [Asset]
    func fetchPublicAssets() async throws -> [Asset]
    func createAsset(_ asset: Asset) async throws -> Asset
    func updateAsset(_ asset: Asset) async throws -> Asset
    func deleteAsset(id: String) async throws
    func uploadAsset(data: Data, name: String, type: AssetType, metadata: AssetMetadata?) async throws -> Asset
    func downloadAsset(id: String) async throws -> Data?
    func generateThumbnail(for assetId: String) async throws -> Data?
    func trackAssetUsage(_ log: AssetUsageLog) async throws
    func searchAssets(query: String) async throws -> [Asset]
    func getAssetUsageStats(assetId: String) async throws -> AssetUsageStats
}

// MARK: - Asset Management Service Implementation
@MainActor
public final class AssetManagementService: ObservableObject, AssetManagementServiceProtocol {
    
    // MARK: - Published Properties
    @Published public private(set) var assets: [Asset] = []
    @Published public private(set) var recentAssets: [Asset] = []
    @Published public private(set) var publicAssets: [Asset] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var uploadProgress: Double = 0.0
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum RecordType {
        static let asset = "Asset"
        static let assetUsageLog = "AssetUsageLog"
        static let assetVersion = "AssetVersion"
    }
    
    private enum AssetKey {
        static let fileData = "fileData"
        static let thumbnailData = "thumbnailData"
    }
    
    // MARK: - Initialization
    public init(container: CKContainer = CKContainer.default) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    public func fetchAssets() async throws -> [Asset] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let query = CKQuery(recordType: RecordType.asset, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
            
            let (records, _) = try await privateDatabase.records(matching: query)
            let assets = records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Asset.from(record: record)
                case .failure:
                    return nil
                }
            }
            
            self.assets = assets
            self.recentAssets = Array(assets.prefix(10))
            
            return assets
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func fetchAsset(by id: String) async throws -> Asset? {
        do {
            let recordID = CKRecord.ID(recordName: id)
            let record = try await privateDatabase.record(for: recordID)
            
            if let asset = Asset.from(record: record) {
                // Track asset access
                let usageLog = AssetUsageLog(
                    assetId: id,
                    userId: "current_user", // In real implementation, get from auth context
                    action: .viewed,
                    timestamp: Date()
                )
                try? await trackAssetUsage(usageLog)
                
                return asset
            }
            return nil
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil
            }
            throw error
        }
    }
    
    public func fetchAssetsByType(_ type: AssetType) async throws -> [Asset] {
        let predicate = NSPredicate(format: "type == %@", type.rawValue)
        let query = CKQuery(recordType: RecordType.asset, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Asset.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchAssetsByCategory(_ category: String) async throws -> [Asset] {
        let predicate = NSPredicate(format: "category == %@", category)
        let query = CKQuery(recordType: RecordType.asset, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Asset.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchAssetsByUser(_ userId: String) async throws -> [Asset] {
        let predicate = NSPredicate(format: "uploadedBy == %@", userId)
        let query = CKQuery(recordType: RecordType.asset, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Asset.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchPublicAssets() async throws -> [Asset] {
        let predicate = NSPredicate(format: "isPublic == YES")
        let query = CKQuery(recordType: RecordType.asset, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
        
        let database = publicDatabase // Public assets go to public database
        let (records, _) = try await database.records(matching: query)
        let assets = records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Asset.from(record: record)
            case .failure:
                return nil
            }
        }
        
        self.publicAssets = assets
        return assets
    }
    
    public func createAsset(_ asset: Asset) async throws -> Asset {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let record = asset.toCKRecord()
            let database = asset.isPublic ? publicDatabase : privateDatabase
            let savedRecord = try await database.save(record)
            
            if let savedAsset = Asset.from(record: savedRecord) {
                assets.insert(savedAsset, at: 0)
                recentAssets.insert(savedAsset, at: 0)
                if recentAssets.count > 10 {
                    recentAssets = Array(recentAssets.prefix(10))
                }
                
                if savedAsset.isPublic {
                    publicAssets.insert(savedAsset, at: 0)
                }
                
                return savedAsset
            }
            
            throw AssetManagementServiceError.invalidAssetData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func updateAsset(_ asset: Asset) async throws -> Asset {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let record = asset.toCKRecord()
            let database = asset.isPublic ? publicDatabase : privateDatabase
            let savedRecord = try await database.save(record)
            
            if let updatedAsset = Asset.from(record: savedRecord) {
                if let index = assets.firstIndex(where: { $0.id == asset.id }) {
                    assets[index] = updatedAsset
                }
                
                // Update recent assets
                if let recentIndex = recentAssets.firstIndex(where: { $0.id == asset.id }) {
                    recentAssets[recentIndex] = updatedAsset
                }
                
                // Update public assets
                publicAssets.removeAll { $0.id == asset.id }
                if updatedAsset.isPublic {
                    publicAssets.append(updatedAsset)
                }
                
                return updatedAsset
            }
            
            throw AssetManagementServiceError.invalidAssetData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func deleteAsset(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let recordID = CKRecord.ID(recordName: id)
            
            // Try both databases since we don't know which one contains the asset
            do {
                _ = try await privateDatabase.deleteRecord(withID: recordID)
            } catch {
                _ = try await publicDatabase.deleteRecord(withID: recordID)
            }
            
            assets.removeAll { $0.id == id }
            recentAssets.removeAll { $0.id == id }
            publicAssets.removeAll { $0.id == id }
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func uploadAsset(data: Data, name: String, type: AssetType, metadata: AssetMetadata?) async throws -> Asset {
        uploadProgress = 0.0
        isLoading = true
        error = nil
        
        defer { 
            isLoading = false
            uploadProgress = 0.0
        }
        
        do {
            // Generate checksum
            let checksum = data.sha256Hash()
            
            // Determine MIME type
            let mimeType = UTType(filenameExtension: URL(fileURLWithPath: name).pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            
            // Validate file type
            guard type.allowedMimeTypes.contains(mimeType) || type.allowedMimeTypes.isEmpty else {
                throw AssetManagementServiceError.invalidFileType
            }
            
            uploadProgress = 0.3
            
            // Create temporary file for CloudKit asset
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try data.write(to: tempURL)
            
            uploadProgress = 0.5
            
            // Create asset record
            let asset = Asset(
                name: name,
                type: type,
                uploadedBy: "current_user", // In real implementation, get from auth context
                storagePath: tempURL.path,
                fileSize: Int64(data.count),
                mimeType: mimeType,
                metadata: metadata ?? AssetMetadata(),
                checksumHash: checksum
            )
            
            uploadProgress = 0.7
            
            let record = asset.toCKRecord()
            
            // Add file data as CloudKit asset
            let ckAsset = CKAsset(fileURL: tempURL)
            record[AssetKey.fileData] = ckAsset
            
            // Generate and add thumbnail if it's an image
            if type == .image, let thumbnailData = generateImageThumbnail(from: data) {
                let thumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_thumb")
                try thumbnailData.write(to: thumbnailURL)
                record[AssetKey.thumbnailData] = CKAsset(fileURL: thumbnailURL)
            }
            
            uploadProgress = 0.9
            
            let database = asset.isPublic ? publicDatabase : privateDatabase
            let savedRecord = try await database.save(record)
            
            uploadProgress = 1.0
            
            // Clean up temporary files
            try? FileManager.default.removeItem(at: tempURL)
            
            if let savedAsset = Asset.from(record: savedRecord) {
                assets.insert(savedAsset, at: 0)
                recentAssets.insert(savedAsset, at: 0)
                if recentAssets.count > 10 {
                    recentAssets = Array(recentAssets.prefix(10))
                }
                
                // Track upload
                let usageLog = AssetUsageLog(
                    assetId: savedAsset.id,
                    userId: savedAsset.uploadedBy,
                    action: .uploaded,
                    timestamp: Date()
                )
                try? await trackAssetUsage(usageLog)
                
                return savedAsset
            }
            
            throw AssetManagementServiceError.invalidAssetData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func downloadAsset(id: String) async throws -> Data? {
        guard let asset = try await fetchAsset(by: id) else {
            throw AssetManagementServiceError.assetNotFound
        }
        
        let recordID = CKRecord.ID(recordName: id)
        let database = asset.isPublic ? publicDatabase : privateDatabase
        let record = try await database.record(for: recordID)
        
        guard let ckAsset = record[AssetKey.fileData] as? CKAsset,
              let fileURL = ckAsset.fileURL else {
            throw AssetManagementServiceError.assetDataNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        
        // Track download
        let usageLog = AssetUsageLog(
            assetId: id,
            userId: "current_user", // In real implementation, get from auth context
            action: .downloaded,
            timestamp: Date()
        )
        try? await trackAssetUsage(usageLog)
        
        return data
    }
    
    public func generateThumbnail(for assetId: String) async throws -> Data? {
        guard let asset = try await fetchAsset(by: assetId) else {
            throw AssetManagementServiceError.assetNotFound
        }
        
        guard asset.type == .image else {
            return nil // Only generate thumbnails for images
        }
        
        let recordID = CKRecord.ID(recordName: assetId)
        let database = asset.isPublic ? publicDatabase : privateDatabase
        let record = try await database.record(for: recordID)
        
        if let thumbnailAsset = record[AssetKey.thumbnailData] as? CKAsset,
           let thumbnailURL = thumbnailAsset.fileURL {
            return try Data(contentsOf: thumbnailURL)
        }
        
        // Generate thumbnail if it doesn't exist
        if let originalData = try await downloadAsset(id: assetId),
           let thumbnailData = generateImageThumbnail(from: originalData) {
            
            // Save thumbnail back to record
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_thumb")
            try thumbnailData.write(to: tempURL)
            record[AssetKey.thumbnailData] = CKAsset(fileURL: tempURL)
            _ = try await database.save(record)
            
            try? FileManager.default.removeItem(at: tempURL)
            
            return thumbnailData
        }
        
        return nil
    }
    
    public func trackAssetUsage(_ log: AssetUsageLog) async throws {
        let record = log.toCKRecord()
        _ = try await privateDatabase.save(record)
    }
    
    public func searchAssets(query: String) async throws -> [Asset] {
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR category CONTAINS[cd] %@", query, query)
        let ckQuery = CKQuery(recordType: RecordType.asset, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let (records, _) = try await privateDatabase.records(matching: ckQuery)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Asset.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func getAssetUsageStats(assetId: String) async throws -> AssetUsageStats {
        let predicate = NSPredicate(format: "assetId == %@", assetId)
        let query = CKQuery(recordType: RecordType.assetUsageLog, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        let usageLogs = records.compactMap { _, result in
            switch result {
            case .success(let record):
                return AssetUsageLog.from(record: record)
            case .failure:
                return nil
            }
        }
        
        return AssetUsageStats(
            totalViews: usageLogs.filter { $0.action == .viewed }.count,
            totalDownloads: usageLogs.filter { $0.action == .downloaded }.count,
            totalShares: usageLogs.filter { $0.action == .shared }.count,
            uniqueUsers: Set(usageLogs.map { $0.userId }).count,
            lastAccessed: usageLogs.first?.timestamp
        )
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        do {
            _ = try await fetchAssets()
            _ = try await fetchPublicAssets()
        } catch {
            self.error = error
        }
    }
    
    private func generateImageThumbnail(from data: Data, maxSize: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        #if canImport(UIKit)
        import UIKit
        
        guard let image = UIImage(data: data) else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: maxSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: maxSize))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.8)
        #else
        // For macOS, you would use NSImage here
        return nil
        #endif
    }
}

// MARK: - Asset Usage Stats
public struct AssetUsageStats {
    public let totalViews: Int
    public let totalDownloads: Int
    public let totalShares: Int
    public let uniqueUsers: Int
    public let lastAccessed: Date?
    
    public init(totalViews: Int, totalDownloads: Int, totalShares: Int, uniqueUsers: Int, lastAccessed: Date?) {
        self.totalViews = totalViews
        self.totalDownloads = totalDownloads
        self.totalShares = totalShares
        self.uniqueUsers = uniqueUsers
        self.lastAccessed = lastAccessed
    }
}

// MARK: - Asset Management Service Error
public enum AssetManagementServiceError: LocalizedError {
    case invalidAssetData
    case assetNotFound
    case assetDataNotFound
    case invalidFileType
    case uploadFailed(String)
    case downloadFailed(String)
    case thumbnailGenerationFailed
    case cloudKitError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAssetData:
            return "Invalid asset data"
        case .assetNotFound:
            return "Asset not found"
        case .assetDataNotFound:
            return "Asset data not found"
        case .invalidFileType:
            return "Invalid file type for this asset category"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Data Extension for SHA256
extension Data {
    func sha256Hash() -> String {
        import CryptoKit
        let hashed = SHA256.hash(data: self)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Mock Asset Management Service
public final class MockAssetManagementService: AssetManagementServiceProtocol {
    private var assets: [Asset] = []
    
    public init() {}
    
    public func fetchAssets() async throws -> [Asset] {
        return assets
    }
    
    public func fetchAsset(by id: String) async throws -> Asset? {
        return assets.first { $0.id == id }
    }
    
    public func fetchAssetsByType(_ type: AssetType) async throws -> [Asset] {
        return assets.filter { $0.type == type }
    }
    
    public func fetchAssetsByCategory(_ category: String) async throws -> [Asset] {
        return assets.filter { $0.category == category }
    }
    
    public func fetchAssetsByUser(_ userId: String) async throws -> [Asset] {
        return assets.filter { $0.uploadedBy == userId }
    }
    
    public func fetchPublicAssets() async throws -> [Asset] {
        return assets.filter { $0.isPublic }
    }
    
    public func createAsset(_ asset: Asset) async throws -> Asset {
        assets.append(asset)
        return asset
    }
    
    public func updateAsset(_ asset: Asset) async throws -> Asset {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
        }
        return asset
    }
    
    public func deleteAsset(id: String) async throws {
        assets.removeAll { $0.id == id }
    }
    
    public func uploadAsset(data: Data, name: String, type: AssetType, metadata: AssetMetadata?) async throws -> Asset {
        let asset = Asset(
            name: name,
            type: type,
            uploadedBy: "mock_user",
            storagePath: "/mock/path",
            fileSize: Int64(data.count),
            mimeType: "application/octet-stream",
            metadata: metadata ?? AssetMetadata()
        )
        return try await createAsset(asset)
    }
    
    public func downloadAsset(id: String) async throws -> Data? {
        guard assets.contains(where: { $0.id == id }) else {
            throw AssetManagementServiceError.assetNotFound
        }
        return Data()
    }
    
    public func generateThumbnail(for assetId: String) async throws -> Data? {
        return Data()
    }
    
    public func trackAssetUsage(_ log: AssetUsageLog) async throws {
        // Mock implementation
    }
    
    public func searchAssets(query: String) async throws -> [Asset] {
        return assets.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.category?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    public func getAssetUsageStats(assetId: String) async throws -> AssetUsageStats {
        return AssetUsageStats(totalViews: 0, totalDownloads: 0, totalShares: 0, uniqueUsers: 0, lastAccessed: nil)
    }
}
