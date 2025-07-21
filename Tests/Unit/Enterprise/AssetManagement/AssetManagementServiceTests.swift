#if canImport(XCTest)
import CloudKit
import XCTest

final class AssetManagementServiceTests: XCTestCase {
    
    var mockService: MockAssetManagementService!
    var sampleAsset: Asset!
    var sampleData: Data!
    
    override func setUp() {
        super.setUp()
        mockService = MockAssetManagementService()
        sampleAsset = Asset(
            name: "test-document.pdf",
            type: .document,
            uploadedBy: "test_user",
            storagePath: "/mock/path/test-document.pdf",
            fileSize: 1024,
            mimeType: "application/pdf"
        )
        sampleData = "Test file content".data(using: .utf8)!
    }
    
    override func tearDown() {
        mockService = nil
        sampleAsset = nil
        sampleData = nil
        super.tearDown()
    }
    
    // MARK: - Create Asset Tests
    
    func testCreateAsset() async throws {
        // Given
        let initialCount = try await mockService.fetchAssets().count
        
        // When
        let createdAsset = try await mockService.createAsset(sampleAsset)
        
        // Then
        XCTAssertEqual(createdAsset.name, sampleAsset.name)
        XCTAssertEqual(createdAsset.type, sampleAsset.type)
        XCTAssertEqual(createdAsset.uploadedBy, sampleAsset.uploadedBy)
        XCTAssertEqual(createdAsset.fileSize, sampleAsset.fileSize)
        XCTAssertEqual(createdAsset.mimeType, sampleAsset.mimeType)
        
        let finalCount = try await mockService.fetchAssets().count
        XCTAssertEqual(finalCount, initialCount + 1)
    }
    
    func testUploadAsset() async throws {
        // Given
        let fileName = "test-upload.txt"
        let assetType = AssetType.document
        let metadata = AssetMetadata()
        
        // When
        let uploadedAsset = try await mockService.uploadAsset(
            data: sampleData,
            name: fileName,
            type: assetType,
            metadata: metadata
        )
        
        // Then
        XCTAssertEqual(uploadedAsset.name, fileName)
        XCTAssertEqual(uploadedAsset.type, assetType)
        XCTAssertEqual(uploadedAsset.fileSize, Int64(sampleData.count))
        XCTAssertEqual(uploadedAsset.uploadedBy, "mock_user")
    }
    
    // MARK: - Fetch Asset Tests
    
    func testFetchAssets() async throws {
        // Given
        _ = try await mockService.createAsset(sampleAsset)
        
        // When
        let assets = try await mockService.fetchAssets()
        
        // Then
        XCTAssertFalse(assets.isEmpty)
        XCTAssertTrue(assets.contains { $0.name == sampleAsset.name })
    }
    
    func testFetchAssetById() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset)
        
        // When
        let fetchedAsset = try await mockService.fetchAsset(by: createdAsset.id)
        
        // Then
        XCTAssertNotNil(fetchedAsset)
        XCTAssertEqual(fetchedAsset?.id, createdAsset.id)
        XCTAssertEqual(fetchedAsset?.name, createdAsset.name)
    }
    
    func testFetchNonExistentAsset() async throws {
        // When
        let fetchedAsset = try await mockService.fetchAsset(by: "non-existent-id")
        
        // Then
        XCTAssertNil(fetchedAsset)
    }
    
    // MARK: - Update Asset Tests
    
    func testUpdateAsset() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset)
        var updatedAsset = createdAsset
        updatedAsset.name = "updated-document.pdf"
        updatedAsset.category = "Updated Category"
        
        // When
        let result = try await mockService.updateAsset(updatedAsset)
        
        // Then
        XCTAssertEqual(result.name, "updated-document.pdf")
        XCTAssertEqual(result.category, "Updated Category")
        
        let fetchedAsset = try await mockService.fetchAsset(by: createdAsset.id)
        XCTAssertEqual(fetchedAsset?.name, "updated-document.pdf")
    }
    
    // MARK: - Delete Asset Tests
    
    func testDeleteAsset() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset)
        let initialCount = try await mockService.fetchAssets().count
        
        // When
        try await mockService.deleteAsset(id: createdAsset.id)
        
        // Then
        let finalCount = try await mockService.fetchAssets().count
        XCTAssertEqual(finalCount, initialCount - 1)
        
        let fetchedAsset = try await mockService.fetchAsset(by: createdAsset.id)
        XCTAssertNil(fetchedAsset)
    }
    
    // MARK: - Filter Tests
    
    func testFetchAssetsByType() async throws {
        // Given
        let documentAsset = Asset(name: "Document", type: .document, uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "application/pdf")
        let imageAsset = Asset(name: "Image", type: .image, uploadedBy: "test", storagePath: "/path", fileSize: 200, mimeType: "image/jpeg")
        
        _ = try await mockService.createAsset(documentAsset)
        _ = try await mockService.createAsset(imageAsset)
        
        // When
        let documentAssets = try await mockService.fetchAssetsByType(.document)
        let imageAssets = try await mockService.fetchAssetsByType(.image)
        
        // Then
        XCTAssertTrue(documentAssets.contains { $0.name == "Document" })
        XCTAssertFalse(documentAssets.contains { $0.name == "Image" })
        XCTAssertTrue(imageAssets.contains { $0.name == "Image" })
        XCTAssertFalse(imageAssets.contains { $0.name == "Document" })
    }
    
    func testFetchAssetsByCategory() async throws {
        // Given
        let categoryAAsset = Asset(name: "Asset A", type: .document, category: "Category A", uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "application/pdf")
        let categoryBAsset = Asset(name: "Asset B", type: .document, category: "Category B", uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "application/pdf")
        
        _ = try await mockService.createAsset(categoryAAsset)
        _ = try await mockService.createAsset(categoryBAsset)
        
        // When
        let categoryAAssets = try await mockService.fetchAssetsByCategory("Category A")
        let categoryBAssets = try await mockService.fetchAssetsByCategory("Category B")
        
        // Then
        XCTAssertTrue(categoryAAssets.contains { $0.name == "Asset A" })
        XCTAssertFalse(categoryAAssets.contains { $0.name == "Asset B" })
        XCTAssertTrue(categoryBAssets.contains { $0.name == "Asset B" })
        XCTAssertFalse(categoryBAssets.contains { $0.name == "Asset A" })
    }
    
    func testFetchAssetsByUser() async throws {
        // Given
        let user1Asset = Asset(name: "User1 Asset", type: .document, uploadedBy: "user1", storagePath: "/path", fileSize: 100, mimeType: "application/pdf")
        let user2Asset = Asset(name: "User2 Asset", type: .document, uploadedBy: "user2", storagePath: "/path", fileSize: 100, mimeType: "application/pdf")
        
        _ = try await mockService.createAsset(user1Asset)
        _ = try await mockService.createAsset(user2Asset)
        
        // When
        let user1Assets = try await mockService.fetchAssetsByUser("user1")
        let user2Assets = try await mockService.fetchAssetsByUser("user2")
        
        // Then
        XCTAssertTrue(user1Assets.contains { $0.name == "User1 Asset" })
        XCTAssertFalse(user1Assets.contains { $0.name == "User2 Asset" })
        XCTAssertTrue(user2Assets.contains { $0.name == "User2 Asset" })
        XCTAssertFalse(user2Assets.contains { $0.name == "User1 Asset" })
    }
    
    func testFetchPublicAssets() async throws {
        // Given
        let publicAsset = Asset(name: "Public Asset", type: .document, uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "application/pdf", isPublic: true)
        let privateAsset = Asset(name: "Private Asset", type: .document, uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "application/pdf", isPublic: false)
        
        _ = try await mockService.createAsset(publicAsset)
        _ = try await mockService.createAsset(privateAsset)
        
        // When
        let publicAssets = try await mockService.fetchPublicAssets()
        
        // Then
        XCTAssertTrue(publicAssets.contains { $0.name == "Public Asset" })
        XCTAssertFalse(publicAssets.contains { $0.name == "Private Asset" })
    }
    
    // MARK: - Download Tests
    
    func testDownloadAsset() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset)
        
        // When
        let downloadedData = try await mockService.downloadAsset(id: createdAsset.id)
        
        // Then
        XCTAssertNotNil(downloadedData)
        XCTAssertEqual(downloadedData?.count, 0) // Mock returns empty data
    }
    
    func testDownloadNonExistentAsset() async throws {
        // When/Then
        do {
            _ = try await mockService.downloadAsset(id: "non-existent-id")
            XCTFail("Should have thrown an error for non-existent asset")
        } catch {
            XCTAssertTrue(error is AssetManagementServiceError)
        }
    }
    
    // MARK: - Thumbnail Tests
    
    func testGenerateThumbnail() async throws {
        // Given
        let imageAsset = Asset(name: "image.jpg", type: .image, uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "image/jpeg")
        let createdAsset = try await mockService.createAsset(imageAsset)
        
        // When
        let thumbnailData = try await mockService.generateThumbnail(for: createdAsset.id)
        
        // Then
        XCTAssertNotNil(thumbnailData)
    }
    
    func testGenerateThumbnailForNonImageAsset() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset) // PDF document
        
        // When
        let thumbnailData = try await mockService.generateThumbnail(for: createdAsset.id)
        
        // Then
        XCTAssertNotNil(thumbnailData) // Mock returns data for all types
    }
    
    // MARK: - Usage Tracking Tests
    
    func testTrackAssetUsage() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset)
        let usageLog = AssetUsageLog(
            assetId: createdAsset.id,
            userId: "test_user",
            action: .viewed,
            timestamp: Date()
        )
        
        // When/Then - Should not throw
        try await mockService.trackAssetUsage(usageLog)
    }
    
    func testGetAssetUsageStats() async throws {
        // Given
        let createdAsset = try await mockService.createAsset(sampleAsset)
        
        // When
        let stats = try await mockService.getAssetUsageStats(assetId: createdAsset.id)
        
        // Then
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats.totalViews, 0)
        XCTAssertEqual(stats.totalDownloads, 0)
        XCTAssertEqual(stats.totalShares, 0)
        XCTAssertEqual(stats.uniqueUsers, 0)
    }
    
    // MARK: - Search Tests
    
    func testSearchAssets() async throws {
        // Given
        let asset1 = Asset(name: "Customer Report.pdf", type: .document, uploadedBy: "test", storagePath: "/path", fileSize: 100, mimeType: "application/pdf")
        let asset2 = Asset(name: "Product Image.jpg", type: .image, uploadedBy: "test", storagePath: "/path", fileSize: 200, mimeType: "image/jpeg")
        
        _ = try await mockService.createAsset(asset1)
        _ = try await mockService.createAsset(asset2)
        
        // When
        let reportResults = try await mockService.searchAssets(query: "report")
        let customerResults = try await mockService.searchAssets(query: "customer")
        let imageResults = try await mockService.searchAssets(query: "image")
        
        // Then
        XCTAssertTrue(reportResults.contains { $0.name == "Customer Report.pdf" })
        XCTAssertFalse(reportResults.contains { $0.name == "Product Image.jpg" })
        
        XCTAssertTrue(customerResults.contains { $0.name == "Customer Report.pdf" })
        XCTAssertFalse(customerResults.contains { $0.name == "Product Image.jpg" })
        
        XCTAssertTrue(imageResults.contains { $0.name == "Product Image.jpg" })
        XCTAssertFalse(imageResults.contains { $0.name == "Customer Report.pdf" })
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceUploadMultipleAssets() {
        measure {
            Task {
                for i in 0..<50 {
                    let data = "Test content \(i)".data(using: .utf8)!
                    _ = try? await mockService.uploadAsset(
                        data: data,
                        name: "test-\(i).txt",
                        type: .document,
                        metadata: AssetMetadata()
                    )
                }
            }
        }
    }
    
    func testPerformanceFetchAssets() async throws {
        // Given - Create multiple assets
        for i in 0..<30 {
            let asset = Asset(
                name: "Asset \(i)",
                type: .document,
                uploadedBy: "test",
                storagePath: "/path/\(i)",
                fileSize: Int64(100 + i),
                mimeType: "application/pdf"
            )
            _ = try await mockService.createAsset(asset)
        }
        
        // When/Then
        measure {
            Task {
                _ = try? await mockService.fetchAssets()
            }
        }
    }
}

// MARK: - CloudKit Extensions Tests

final class AssetCloudKitTests: XCTestCase {
    
    func testAssetCloudKitSerialization() {
        // Given
        let asset = Asset(
            id: "test-id",
            name: "test-document.pdf",
            type: .document,
            category: "Reports",
            tags: ["important", "quarterly"],
            uploadedBy: "test_user",
            uploadDate: Date(),
            storagePath: "/documents/test.pdf",
            fileSize: 2048,
            mimeType: "application/pdf",
            isPublic: false
        )
        
        // When
        let record = asset.toCKRecord()
        let deserializedAsset = Asset.from(record: record)
        
        // Then
        XCTAssertNotNil(deserializedAsset)
        XCTAssertEqual(deserializedAsset?.id, asset.id)
        XCTAssertEqual(deserializedAsset?.name, asset.name)
        XCTAssertEqual(deserializedAsset?.type, asset.type)
        XCTAssertEqual(deserializedAsset?.category, asset.category)
        XCTAssertEqual(deserializedAsset?.tags, asset.tags)
        XCTAssertEqual(deserializedAsset?.uploadedBy, asset.uploadedBy)
        XCTAssertEqual(deserializedAsset?.storagePath, asset.storagePath)
        XCTAssertEqual(deserializedAsset?.fileSize, asset.fileSize)
        XCTAssertEqual(deserializedAsset?.mimeType, asset.mimeType)
        XCTAssertEqual(deserializedAsset?.isPublic, asset.isPublic)
    }
    
    func testAssetUsageLogCloudKitSerialization() {
        // Given
        let usageLog = AssetUsageLog(
            id: "log-id",
            assetId: "asset-id",
            userId: "user-id",
            action: .downloaded,
            timestamp: Date(),
            context: "Test context",
            ipAddress: "192.168.1.1",
            userAgent: "TestAgent/1.0",
            sessionId: "session-123"
        )
        
        // When
        let record = usageLog.toCKRecord()
        let deserializedLog = AssetUsageLog.from(record: record)
        
        // Then
        XCTAssertNotNil(deserializedLog)
        XCTAssertEqual(deserializedLog?.id, usageLog.id)
        XCTAssertEqual(deserializedLog?.assetId, usageLog.assetId)
        XCTAssertEqual(deserializedLog?.userId, usageLog.userId)
        XCTAssertEqual(deserializedLog?.action, usageLog.action)
        XCTAssertEqual(deserializedLog?.context, usageLog.context)
        XCTAssertEqual(deserializedLog?.ipAddress, usageLog.ipAddress)
        XCTAssertEqual(deserializedLog?.userAgent, usageLog.userAgent)
        XCTAssertEqual(deserializedLog?.sessionId, usageLog.sessionId)
    }
}
#endif
