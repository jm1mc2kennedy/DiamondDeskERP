import Foundation
import CloudKit
import Combine
import UniformTypeIdentifiers

// MARK: - Asset Management Service Implementation
@MainActor
public class AssetManagementService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var assets: [Asset] = []
    @Published public var categories: [AssetCategory] = []
    @Published public var tags: [AssetTag] = []
    @Published public var collections: [AssetCollection] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var uploadProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    public init(container: CKContainer = .default()) {
        self.container = container
        self.database = container.publicCloudDatabase
        setupDirectories()
    }
    
    // MARK: - Asset Management
    
    /// Fetches all assets with optional filtering
    public func fetchAssets(filter: AssetSearchFilter? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let predicate = buildPredicate(from: filter)
            let query = CKQuery(recordType: "Asset", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
            
            let (matchResults, _) = try await database.records(matching: query)
            
            var fetchedAssets: [Asset] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let asset = Asset.from(record: record) {
                        fetchedAssets.append(asset)
                    }
                case .failure(let error):
                    print("Error fetching asset record: \(error)")
                }
            }
            
            assets = fetchedAssets
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch assets: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Uploads a new asset
    public func uploadAsset(
        from url: URL,
        name: String,
        type: AssetType,
        category: String? = nil,
        tags: [String] = [],
        uploadedBy: String,
        isPublic: Bool = false
    ) async throws -> Asset {
        isLoading = true
        errorMessage = nil
        uploadProgress = 0.0
        
        do {
            // Validate file
            let fileAttributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            // Determine MIME type
            let mimeType = getMimeType(for: url)
            
            // Validate file type against asset type
            if !type.allowedMimeTypes.isEmpty && !type.allowedMimeTypes.contains(mimeType) {
                throw AssetManagementError.invalidFileType(mimeType, type)
            }
            
            uploadProgress = 0.1
            
            // Create storage path
            let storagePath = generateStoragePath(for: name, type: type)
            
            // Copy file to storage location
            let storageURL = getStorageURL(for: storagePath)
            try fileManager.copyItem(at: url, to: storageURL)
            
            uploadProgress = 0.4
            
            // Generate thumbnail if applicable
            let thumbnailPath = try await generateThumbnail(for: storageURL, type: type)
            
            uploadProgress = 0.6
            
            // Extract metadata
            let metadata = try await extractMetadata(from: storageURL, type: type)
            
            uploadProgress = 0.8
            
            // Calculate checksum
            let checksumHash = try calculateChecksum(for: storageURL)
            
            // Create asset record
            let asset = Asset(
                name: name,
                type: type,
                category: category,
                tags: tags,
                uploadedBy: uploadedBy,
                storagePath: storagePath,
                fileSize: fileSize,
                mimeType: mimeType,
                metadata: metadata,
                thumbnailPath: thumbnailPath,
                isPublic: isPublic,
                checksumHash: checksumHash
            )
            
            // Save to CloudKit
            let record = asset.toCKRecord()
            let savedRecord = try await database.save(record)
            
            guard let savedAsset = Asset.from(record: savedRecord) else {
                throw AssetManagementError.saveFailed
            }
            
            uploadProgress = 1.0
            
            // Add to local array
            assets.insert(savedAsset, at: 0)
            
            // Log usage
            try await logAssetUsage(assetId: savedAsset.id, userId: uploadedBy, action: .uploaded)
            
            isLoading = false
            return savedAsset
            
        } catch {
            errorMessage = "Failed to upload asset: \(error.localizedDescription)"
            isLoading = false
            uploadProgress = 0.0
            throw error
        }
    }
    
    /// Downloads an asset
    public func downloadAsset(_ asset: Asset, to destinationURL: URL? = nil) async throws -> URL {
        let storageURL = getStorageURL(for: asset.storagePath)
        
        guard fileManager.fileExists(atPath: storageURL.path) else {
            throw AssetManagementError.fileNotFound
        }
        
        let destination = destinationURL ?? getDownloadsURL().appendingPathComponent(asset.name)
        
        try fileManager.copyItem(at: storageURL, to: destination)
        
        // Update usage count and log access
        var updatedAsset = asset
        updatedAsset.usageCount += 1
        updatedAsset.lastAccessed = Date()
        
        try await updateAsset(updatedAsset)
        try await logAssetUsage(assetId: asset.id, userId: "current_user", action: .downloaded)
        
        return destination
    }
    
    /// Updates an existing asset
    public func updateAsset(_ asset: Asset) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let record = asset.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let updatedAsset = Asset.from(record: savedRecord),
               let index = assets.firstIndex(where: { $0.id == asset.id }) {
                assets[index] = updatedAsset
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to update asset: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Deletes an asset
    public func deleteAsset(id: String) async throws {
        guard let asset = assets.first(where: { $0.id == id }) else {
            throw AssetManagementError.assetNotFound
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete from CloudKit
            let recordID = CKRecord.ID(recordName: id)
            _ = try await database.deleteRecord(withID: recordID)
            
            // Delete physical files
            let storageURL = getStorageURL(for: asset.storagePath)
            if fileManager.fileExists(atPath: storageURL.path) {
                try fileManager.removeItem(at: storageURL)
            }
            
            // Delete thumbnail if exists
            if let thumbnailPath = asset.thumbnailPath {
                let thumbnailURL = getStorageURL(for: thumbnailPath)
                if fileManager.fileExists(atPath: thumbnailURL.path) {
                    try fileManager.removeItem(at: thumbnailURL)
                }
            }
            
            // Remove from local array
            assets.removeAll { $0.id == id }
            
            // Log deletion
            try await logAssetUsage(assetId: id, userId: "current_user", action: .deleted)
            
            isLoading = false
        } catch {
            errorMessage = "Failed to delete asset: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Creates a new version of an asset
    public func createAssetVersion(
        assetId: String,
        from url: URL,
        uploadedBy: String,
        changeDescription: String? = nil
    ) async throws -> Asset {
        guard var asset = assets.first(where: { $0.id == assetId }) else {
            throw AssetManagementError.assetNotFound
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get file info
            let fileAttributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            // Create new version
            let newVersionNumber = (asset.versions.map { $0.version }.max() ?? 0) + 1
            let versionStoragePath = generateVersionStoragePath(for: asset.storagePath, version: newVersionNumber)
            
            // Copy new file
            let versionStorageURL = getStorageURL(for: versionStoragePath)
            try fileManager.copyItem(at: url, to: versionStorageURL)
            
            // Calculate checksum
            let checksumHash = try calculateChecksum(for: versionStorageURL)
            
            // Create version record
            let version = AssetVersion(
                version: newVersionNumber,
                uploadedBy: uploadedBy,
                fileSize: fileSize,
                storagePath: versionStoragePath,
                changeDescription: changeDescription,
                checksumHash: checksumHash
            )
            
            // Add version to asset
            asset.versions.append(version)
            
            // Update current asset to point to new version
            asset.storagePath = versionStoragePath
            asset.fileSize = fileSize
            asset.checksumHash = checksumHash
            
            // Save updated asset
            try await updateAsset(asset)
            
            // Log version creation
            try await logAssetUsage(assetId: assetId, userId: uploadedBy, action: .versionCreated)
            
            isLoading = false
            return asset
            
        } catch {
            errorMessage = "Failed to create asset version: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Category Management
    
    /// Fetches all asset categories
    public func fetchCategories() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "AssetCategory", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            
            let (matchResults, _) = try await database.records(matching: query)
            
            var fetchedCategories: [AssetCategory] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let category = AssetCategory.from(record: record) {
                        fetchedCategories.append(category)
                    }
                case .failure(let error):
                    print("Error fetching category record: \(error)")
                }
            }
            
            categories = fetchedCategories
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Creates a new asset category
    public func createCategory(_ category: AssetCategory) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let record = category.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let savedCategory = AssetCategory.from(record: savedRecord) {
                categories.append(savedCategory)
                categories.sort { $0.sortOrder < $1.sortOrder }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to create category: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Tag Management
    
    /// Fetches all asset tags
    public func fetchTags() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "AssetTag", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let (matchResults, _) = try await database.records(matching: query)
            
            var fetchedTags: [AssetTag] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let tag = AssetTag.from(record: record) {
                        fetchedTags.append(tag)
                    }
                case .failure(let error):
                    print("Error fetching tag record: \(error)")
                }
            }
            
            tags = fetchedTags
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch tags: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Creates a new tag
    public func createTag(_ tag: AssetTag) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let record = tag.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let savedTag = AssetTag.from(record: savedRecord) {
                tags.append(savedTag)
                tags.sort { $0.name < $1.name }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to create tag: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Collection Management
    
    /// Creates an asset collection
    public func createCollection(_ collection: AssetCollection) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let record = collection.toCKRecord()
            let savedRecord = try await database.save(record)
            
            if let savedCollection = AssetCollection.from(record: savedRecord) {
                collections.append(savedCollection)
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to create collection: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Adds an asset to a collection
    public func addAssetToCollection(assetId: String, collectionId: String) async throws {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            throw AssetManagementError.collectionNotFound
        }
        
        if !collection.assetIds.contains(assetId) {
            collection.assetIds.append(assetId)
            collection.modifiedAt = Date()
            
            try await updateCollection(collection)
        }
    }
    
    /// Updates a collection
    private func updateCollection(_ collection: AssetCollection) async throws {
        let record = collection.toCKRecord()
        let savedRecord = try await database.save(record)
        
        if let updatedCollection = AssetCollection.from(record: savedRecord),
           let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = updatedCollection
        }
    }
    
    // MARK: - Search and Analytics
    
    /// Searches assets based on criteria
    public func searchAssets(query: String, filter: AssetSearchFilter? = nil) async throws -> [Asset] {
        let searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        let filterPredicate = buildPredicate(from: filter)
        
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [searchPredicate, filterPredicate])
        
        let ckQuery = CKQuery(recordType: "Asset", predicate: combinedPredicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let (matchResults, _) = try await database.records(matching: ckQuery)
        
        var searchResults: [Asset] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let asset = Asset.from(record: record) {
                    searchResults.append(asset)
                }
            case .failure(let error):
                print("Error in search result: \(error)")
            }
        }
        
        return searchResults
    }
    
    /// Gets usage analytics for an asset
    public func getAssetAnalytics(assetId: String) async throws -> AssetAnalytics {
        let predicate = NSPredicate(format: "assetId == %@", assetId)
        let query = CKQuery(recordType: "AssetUsageLog", predicate: predicate)
        
        let (matchResults, _) = try await database.records(matching: query)
        
        var usageLogs: [AssetUsageLog] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let log = AssetUsageLog.from(record: record) {
                    usageLogs.append(log)
                }
            case .failure(let error):
                print("Error fetching usage log: \(error)")
            }
        }
        
        return AssetAnalytics(assetId: assetId, usageLogs: usageLogs)
    }
    
    // MARK: - Private Helper Methods
    
    private func setupDirectories() {
        let storageURL = getStorageBaseURL()
        let thumbnailURL = getThumbnailBaseURL()
        let downloadsURL = getDownloadsURL()
        
        for url in [storageURL, thumbnailURL, downloadsURL] {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    private func buildPredicate(from filter: AssetSearchFilter?) -> NSPredicate {
        guard let filter = filter else {
            return NSPredicate(value: true)
        }
        
        var predicates: [NSPredicate] = []
        
        if let name = filter.name {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", name))
        }
        
        if let type = filter.type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }
        
        if let category = filter.category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if !filter.tags.isEmpty {
            for tag in filter.tags {
                predicates.append(NSPredicate(format: "tags CONTAINS %@", tag))
            }
        }
        
        if let uploadedBy = filter.uploadedBy {
            predicates.append(NSPredicate(format: "uploadedBy == %@", uploadedBy))
        }
        
        if let isPublic = filter.isPublic {
            predicates.append(NSPredicate(format: "isPublic == %@", NSNumber(value: isPublic)))
        }
        
        return predicates.isEmpty ? NSPredicate(value: true) : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    private func generateStoragePath(for name: String, type: AssetType) -> String {
        let sanitizedName = name.replacingOccurrences(of: " ", with: "_")
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "\(type.rawValue.lowercased())/\(timestamp)_\(uuid)_\(sanitizedName)"
    }
    
    private func generateVersionStoragePath(for originalPath: String, version: Int) -> String {
        let pathComponents = originalPath.split(separator: "/")
        guard let fileName = pathComponents.last else { return originalPath }
        
        let directory = pathComponents.dropLast().joined(separator: "/")
        return "\(directory)/v\(version)_\(fileName)"
    }
    
    private func getStorageBaseURL() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AssetStorage")
    }
    
    private func getThumbnailBaseURL() -> URL {
        return getStorageBaseURL().appendingPathComponent("Thumbnails")
    }
    
    private func getDownloadsURL() -> URL {
        return fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DiamondDeskAssets")
    }
    
    private func getStorageURL(for path: String) -> URL {
        return getStorageBaseURL().appendingPathComponent(path)
    }
    
    private func getMimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
    
    private func generateThumbnail(for url: URL, type: AssetType) async throws -> String? {
        guard type == .image || type == .video else { return nil }
        
        // Placeholder implementation - would generate actual thumbnails
        let thumbnailPath = "thumbnails/\(url.lastPathComponent)_thumb.jpg"
        return thumbnailPath
    }
    
    private func extractMetadata(from url: URL, type: AssetType) async throws -> AssetMetadata {
        var metadata = AssetMetadata()
        
        // Extract metadata based on file type
        switch type {
        case .image:
            // Extract image metadata (dimensions, color space, etc.)
            metadata.customProperties["extracted"] = "true"
        case .video:
            // Extract video metadata (duration, frame rate, etc.)
            metadata.customProperties["extracted"] = "true"
        case .audio:
            // Extract audio metadata (duration, bit rate, etc.)
            metadata.customProperties["extracted"] = "true"
        default:
            break
        }
        
        return metadata
    }
    
    private func calculateChecksum(for url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.sha256
    }
    
    private func logAssetUsage(assetId: String, userId: String, action: AssetAction) async throws {
        let usageLog = AssetUsageLog(
            assetId: assetId,
            userId: userId,
            action: action
        )
        
        let record = usageLog.toCKRecord()
        _ = try await database.save(record)
    }
}

// MARK: - Supporting Types

public struct AssetAnalytics {
    public let assetId: String
    public let totalViews: Int
    public let totalDownloads: Int
    public let uniqueUsers: Int
    public let lastAccessed: Date?
    public let usageByDay: [Date: Int]
    
    public init(assetId: String, usageLogs: [AssetUsageLog]) {
        self.assetId = assetId
        self.totalViews = usageLogs.filter { $0.action == .viewed }.count
        self.totalDownloads = usageLogs.filter { $0.action == .downloaded }.count
        self.uniqueUsers = Set(usageLogs.map { $0.userId }).count
        self.lastAccessed = usageLogs.map { $0.timestamp }.max()
        
        // Group usage by day
        let calendar = Calendar.current
        var usageByDay: [Date: Int] = [:]
        for log in usageLogs {
            let day = calendar.startOfDay(for: log.timestamp)
            usageByDay[day, default: 0] += 1
        }
        self.usageByDay = usageByDay
    }
}

public enum AssetManagementError: LocalizedError {
    case invalidFileType(String, AssetType)
    case fileNotFound
    case assetNotFound
    case collectionNotFound
    case saveFailed
    case uploadFailed(String)
    case thumbnailGenerationFailed
    case metadataExtractionFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidFileType(let mimeType, let assetType):
            return "Invalid file type '\(mimeType)' for asset type '\(assetType.displayName)'"
        case .fileNotFound:
            return "File not found"
        case .assetNotFound:
            return "Asset not found"
        case .collectionNotFound:
            return "Collection not found"
        case .saveFailed:
            return "Failed to save asset"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .metadataExtractionFailed:
            return "Failed to extract metadata"
        }
    }
}

// MARK: - Extensions

private extension Data {
    var sha256: String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

import CryptoKit

extension AssetCategory {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AssetCategory", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["parentId"] = parentId
        record["description"] = description
        record["color"] = color
        record["icon"] = icon
        record["sortOrder"] = sortOrder
        record["isSystemCategory"] = isSystemCategory
        return record
    }
    
    static func from(record: CKRecord) -> AssetCategory? {
        guard let name = record["name"] as? String,
              let color = record["color"] as? String,
              let sortOrder = record["sortOrder"] as? Int,
              let isSystemCategory = record["isSystemCategory"] as? Bool else {
            return nil
        }
        
        return AssetCategory(
            id: record.recordID.recordName,
            name: name,
            parentId: record["parentId"] as? String,
            description: record["description"] as? String,
            color: color,
            icon: record["icon"] as? String,
            sortOrder: sortOrder,
            isSystemCategory: isSystemCategory
        )
    }
}

extension AssetTag {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AssetTag", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["color"] = color
        record["description"] = description
        record["usageCount"] = usageCount
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        return record
    }
    
    static func from(record: CKRecord) -> AssetTag? {
        guard let name = record["name"] as? String,
              let color = record["color"] as? String,
              let usageCount = record["usageCount"] as? Int,
              let createdBy = record["createdBy"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        return AssetTag(
            id: record.recordID.recordName,
            name: name,
            color: color,
            description: record["description"] as? String,
            usageCount: usageCount,
            createdBy: createdBy,
            createdAt: createdAt
        )
    }
}

extension AssetCollection {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AssetCollection", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["ownerId"] = ownerId
        record["assetIds"] = assetIds
        record["isPublic"] = isPublic
        record["sharedWith"] = sharedWith
        record["tags"] = tags
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        return record
    }
    
    static func from(record: CKRecord) -> AssetCollection? {
        guard let name = record["name"] as? String,
              let ownerId = record["ownerId"] as? String,
              let assetIds = record["assetIds"] as? [String],
              let isPublic = record["isPublic"] as? Bool,
              let sharedWith = record["sharedWith"] as? [String],
              let tags = record["tags"] as? [String],
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        return AssetCollection(
            id: record.recordID.recordName,
            name: name,
            description: record["description"] as? String,
            ownerId: ownerId,
            assetIds: assetIds,
            isPublic: isPublic,
            sharedWith: sharedWith,
            tags: tags,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
