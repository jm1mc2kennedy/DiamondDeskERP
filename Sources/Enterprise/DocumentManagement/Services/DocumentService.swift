//
//  DocumentService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine
import UniformTypeIdentifiers

/// Enterprise Document Management Service
/// Provides comprehensive document lifecycle management with CloudKit integration
@MainActor
final class DocumentService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var documents: [DocumentModel] = []
    @Published var isLoading = false
    @Published var error: DocumentError?
    @Published var uploadProgress: Double = 0.0
    @Published var searchResults: [DocumentModel] = []
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    private let documentsZone = CKRecordZone(zoneName: "DocumentsZone")
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let supportedMimeTypes: Set<String> = [
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "text/plain",
        "text/markdown",
        "image/jpeg",
        "image/png",
        "image/heic"
    ]
    
    // MARK: - Singleton
    
    static let shared = DocumentService()
    
    // MARK: - Initialization
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.hannoush.DiamondDeskERP")
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        setupCloudKitZones()
        setupSubscriptions()
    }
    
    // MARK: - CloudKit Setup
    
    private func setupCloudKitZones() {
        Task {
            do {
                // Create custom zone for documents in private database
                try await privateDatabase.save(documentsZone)
                print("✅ Documents zone created successfully")
            } catch {
                if let ckError = error as? CKError,
                   ckError.code == .zoneNotEmpty || ckError.code == .serverRecordChanged {
                    // Zone already exists, this is fine
                    print("📝 Documents zone already exists")
                } else {
                    print("❌ Failed to create documents zone: \(error)")
                }
            }
        }
    }
    
    private func setupSubscriptions() {
        Task {
            do {
                // Subscribe to document changes in private database
                let subscription = CKQuerySubscription(
                    recordType: DocumentModel.recordType,
                    predicate: NSPredicate(value: true),
                    subscriptionID: "document-changes",
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
                )
                
                subscription.zoneID = documentsZone.zoneID
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                try await privateDatabase.save(subscription)
                print("✅ Document subscription created successfully")
            } catch {
                if let ckError = error as? CKError,
                   ckError.code == .duplicateSubscription {
                    print("📝 Document subscription already exists")
                } else {
                    print("❌ Failed to create document subscription: \(error)")
                }
            }
        }
    }
    
    // MARK: - Document Operations
    
    /// Fetches all documents accessible to the current user
    func fetchDocuments() async {
        isLoading = true
        error = nil
        
        do {
            let query = CKQuery(
                recordType: DocumentModel.recordType,
                predicate: NSPredicate(format: "status != %@", DocumentStatus.deleted.rawValue)
            )
            query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
            
            let operation = CKQueryOperation(query: query)
            operation.zoneID = documentsZone.zoneID
            operation.resultsLimit = 100
            
            var fetchedDocuments: [DocumentModel] = []
            
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    do {
                        let document = try DocumentModel.fromCKRecord(record)
                        fetchedDocuments.append(document)
                    } catch {
                        print("❌ Failed to parse document record: \(error)")
                    }
                case .failure(let error):
                    print("❌ Failed to fetch document record \(recordID): \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        self.documents = fetchedDocuments
                        print("✅ Fetched \(fetchedDocuments.count) documents")
                    case .failure(let error):
                        self.error = .invalidRecord(error.localizedDescription)
                        print("❌ Failed to fetch documents: \(error)")
                    }
                    self.isLoading = false
                }
            }
            
            privateDatabase.add(operation)
            
        } catch {
            self.error = .invalidRecord(error.localizedDescription)
            self.isLoading = false
        }
    }
    
    /// Uploads a new document to CloudKit
    func uploadDocument(
        title: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        category: DocumentCategory = .general,
        accessLevel: DocumentAccessLevel = .internal,
        tags: [String] = [],
        description: String? = nil
    ) async throws -> DocumentModel {
        
        // Validate file size
        guard fileData.count <= maxFileSize else {
            throw DocumentError.quotaExceeded
        }
        
        // Validate file type
        guard supportedMimeTypes.contains(mimeType) else {
            throw DocumentError.invalidFileType
        }
        
        isLoading = true
        uploadProgress = 0.0
        
        do {
            // Create document model
            let currentUser = await getCurrentUser()
            let fileType = DocumentFileType.from(mimeType: mimeType)
            
            var document = DocumentModel(
                title: title,
                fileName: fileName,
                fileType: fileType,
                fileSize: Int64(fileData.count),
                mimeType: mimeType,
                category: category,
                accessLevel: accessLevel,
                ownerUserId: currentUser,
                createdBy: currentUser
            )
            
            document.tags = tags
            document.description = description
            document.documentHash = calculateFileHash(data: fileData)
            
            // Create CloudKit record
            let record = try document.toCKRecord()
            record.setObject(documentsZone.zoneID, forKey: "recordZone")
            
            // Create and upload document asset
            let tempURL = createTemporaryFile(data: fileData, fileName: fileName)
            let documentAsset = CKAsset(fileURL: tempURL)
            record["documentAsset"] = documentAsset
            
            // Generate thumbnail if applicable
            if fileType == .image {
                if let thumbnailData = generateThumbnail(from: fileData, mimeType: mimeType) {
                    let thumbnailURL = createTemporaryFile(data: thumbnailData, fileName: "thumb_\(fileName)")
                    let thumbnailAsset = CKAsset(fileURL: thumbnailURL)
                    record["thumbnailAsset"] = thumbnailAsset
                }
            }
            
            // Save to CloudKit
            let savedRecord = try await privateDatabase.save(record)
            document.documentAssetRecordName = savedRecord.recordID.recordName
            
            // Update document with asset references
            if let documentAsset = savedRecord["documentAsset"] as? CKAsset {
                document.documentPath = documentAsset.fileURL?.path ?? ""
            }
            if let thumbnailAsset = savedRecord["thumbnailAsset"] as? CKAsset {
                document.thumbnailPath = thumbnailAsset.fileURL?.path
                document.thumbnailAssetRecordName = savedRecord.recordID.recordName + "_thumb"
            }
            
            // Clean up temporary files
            cleanupTemporaryFile(url: tempURL)
            
            // Update local cache
            documents.insert(document, at: 0)
            
            uploadProgress = 1.0
            isLoading = false
            
            print("✅ Document uploaded successfully: \(title)")
            return document
            
        } catch {
            isLoading = false
            uploadProgress = 0.0
            throw DocumentError.invalidRecord(error.localizedDescription)
        }
    }
    
    /// Updates an existing document
    func updateDocument(_ document: DocumentModel) async throws -> DocumentModel {
        isLoading = true
        
        do {
            var updatedDocument = document
            updatedDocument.modifiedAt = Date()
            updatedDocument.modifiedBy = await getCurrentUser()
            
            let record = try updatedDocument.toCKRecord()
            let savedRecord = try await privateDatabase.save(record)
            
            let finalDocument = try DocumentModel.fromCKRecord(savedRecord)
            
            // Update local cache
            if let index = documents.firstIndex(where: { $0.id == finalDocument.id }) {
                documents[index] = finalDocument
            }
            
            isLoading = false
            print("✅ Document updated successfully: \(finalDocument.title)")
            return finalDocument
            
        } catch {
            isLoading = false
            throw DocumentError.invalidRecord(error.localizedDescription)
        }
    }
    
    /// Deletes a document (soft delete)
    func deleteDocument(_ document: DocumentModel) async throws {
        isLoading = true
        
        do {
            var deletedDocument = document
            deletedDocument.status = .deleted
            deletedDocument.modifiedAt = Date()
            deletedDocument.modifiedBy = await getCurrentUser()
            
            let record = try deletedDocument.toCKRecord()
            try await privateDatabase.save(record)
            
            // Remove from local cache
            documents.removeAll { $0.id == document.id }
            
            isLoading = false
            print("✅ Document deleted successfully: \(document.title)")
            
        } catch {
            isLoading = false
            throw DocumentError.invalidRecord(error.localizedDescription)
        }
    }
    
    /// Downloads document content
    func downloadDocument(_ document: DocumentModel) async throws -> Data {
        guard let assetRecordName = document.documentAssetRecordName else {
            throw DocumentError.invalidRecord("No asset reference found")
        }
        
        do {
            let recordID = CKRecord.ID(recordName: assetRecordName)
            let record = try await privateDatabase.record(for: recordID)
            
            guard let asset = record["documentAsset"] as? CKAsset,
                  let fileURL = asset.fileURL else {
                throw DocumentError.invalidRecord("No asset file found")
            }
            
            let data = try Data(contentsOf: fileURL)
            
            // Update last accessed tracking
            var accessedDocument = document
            accessedDocument.lastAccessedAt = Date()
            accessedDocument.lastAccessedBy = await getCurrentUser()
            
            Task {
                try? await updateDocument(accessedDocument)
            }
            
            return data
            
        } catch {
            throw DocumentError.invalidRecord(error.localizedDescription)
        }
    }
    
    // MARK: - Search Operations
    
    /// Searches documents by title, content, and tags
    func searchDocuments(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        do {
            let predicate = NSPredicate(format: 
                "title CONTAINS[cd] %@ OR searchableContent CONTAINS[cd] %@ OR tags CONTAINS[cd] %@",
                query, query, query
            )
            
            let ckQuery = CKQuery(recordType: DocumentModel.recordType, predicate: predicate)
            ckQuery.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
            
            let operation = CKQueryOperation(query: ckQuery)
            operation.zoneID = documentsZone.zoneID
            operation.resultsLimit = 50
            
            var results: [DocumentModel] = []
            
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    do {
                        let document = try DocumentModel.fromCKRecord(record)
                        results.append(document)
                    } catch {
                        print("❌ Failed to parse search result: \(error)")
                    }
                case .failure(let error):
                    print("❌ Failed to fetch search result \(recordID): \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        self.searchResults = results
                        print("✅ Found \(results.count) documents matching '\(query)'")
                    case .failure(let error):
                        self.error = .invalidRecord(error.localizedDescription)
                        print("❌ Search failed: \(error)")
                    }
                    self.isLoading = false
                }
            }
            
            privateDatabase.add(operation)
            
        } catch {
            self.error = .invalidRecord(error.localizedDescription)
            self.isLoading = false
        }
    }
    
    /// Filters documents by category and access level
    func filterDocuments(
        category: DocumentCategory? = nil,
        accessLevel: DocumentAccessLevel? = nil,
        status: DocumentStatus? = nil
    ) -> [DocumentModel] {
        return documents.filter { document in
            if let category = category, document.category != category {
                return false
            }
            if let accessLevel = accessLevel, document.accessLevel != accessLevel {
                return false
            }
            if let status = status, document.status != status {
                return false
            }
            return true
        }
    }
    
    // MARK: - Document Checkout Operations
    
    /// Checks out a document for exclusive editing
    func checkoutDocument(_ document: DocumentModel) async throws -> DocumentModel {
        guard document.checkedOutBy == nil || document.lockExpiration ?? Date() < Date() else {
            throw DocumentError.documentLocked
        }
        
        var checkedOutDocument = document
        checkedOutDocument.checkedOutBy = await getCurrentUser()
        checkedOutDocument.checkedOutAt = Date()
        checkedOutDocument.lockExpiration = Date().addingTimeInterval(3600) // 1 hour lock
        
        return try await updateDocument(checkedOutDocument)
    }
    
    /// Checks in a document, releasing the lock
    func checkinDocument(_ document: DocumentModel) async throws -> DocumentModel {
        var checkedInDocument = document
        checkedInDocument.checkedOutBy = nil
        checkedInDocument.checkedOutAt = nil
        checkedInDocument.lockExpiration = nil
        
        return try await updateDocument(checkedInDocument)
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentUser() async -> String {
        // Integrate with UserProvisioningService to get current user ID
        return await UserProvisioningService.shared.getCurrentUserID() ?? "anonymous-user"
    }
    
    private func calculateFileHash(data: Data) -> String {
        return data.sha256
    }
    
    private func createTemporaryFile(data: Data, fileName: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + fileName)
        
        do {
            try data.write(to: tempURL)
        } catch {
            print("❌ Failed to write temporary file: \(error)")
        }
        
        return tempURL
    }
    
    private func cleanupTemporaryFile(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    private func generateThumbnail(from imageData: Data, mimeType: String) -> Data? {
        // Implement thumbnail generation using ImageIO and CoreImage
        guard mimeType.hasPrefix("image/") else { return nil }
        
        // Create image source from data
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        
        // Create thumbnail with max dimension of 200px
        let maxThumbnailSize: CGFloat = 200
        let imageSize = CGSize(width: image.width, height: image.height)
        let aspectRatio = imageSize.width / imageSize.height
        
        let thumbnailSize: CGSize
        if aspectRatio > 1 {
            thumbnailSize = CGSize(width: maxThumbnailSize, height: maxThumbnailSize / aspectRatio)
        } else {
            thumbnailSize = CGSize(width: maxThumbnailSize * aspectRatio, height: maxThumbnailSize)
        }
        
        // Create thumbnail using Core Graphics
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let thumbnailImage = renderer.image { _ in
            UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
        
        return thumbnailImage.jpegData(compressionQuality: 0.8)
    }
    
    /// Clears error state
    func clearError() {
        error = nil
    }
    
    /// Refreshes the document list
    func refresh() {
        Task {
            await fetchDocuments()
        }
    }
}

// MARK: - Data Extensions

extension Data {
    var sha256: String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

import CryptoKit

// MARK: - Document Access Control

extension DocumentService {
    
    /// Checks if the current user has access to a document
    func hasAccess(to document: DocumentModel, operation: DocumentOperation) async -> Bool {
        let currentUser = await getCurrentUser()
        
        // Owner has full access
        if document.ownerUserId == currentUser {
            return true
        }
        
        // Check collaborator access
        if document.collaboratorUserIds.contains(currentUser) {
            return operation != .delete // Collaborators can't delete
        }
        
        // Implement role-based access control
        // This integrates with user roles and permissions
        let userRole = await getUserRole(currentUser)
        
        switch document.accessLevel {
        case .public:
            return true
        case .internal:
            return userRole != .guest
        case .confidential:
            return userRole == .admin || userRole == .manager
        case .restricted:
            return userRole == .admin
        case .topSecret:
            return userRole == .admin && operation == .read
        }
    }
    
    private func getUserRole(_ userId: String) async -> UserRole {
        // This would integrate with UserProvisioningService
        // For now, return a default role based on user ID patterns
        if userId.contains("admin") { return .admin }
        if userId.contains("manager") { return .manager }
        return .user
    }
    
    enum UserRole {
        case guest, user, manager, admin
    }
    }
    
    /// Gets documents accessible to current user with permission filtering
    func getAccessibleDocuments() async -> [DocumentModel] {
        let currentUser = await getCurrentUser()
        
        return documents.filter { document in
            // Apply access level filtering based on user role
            switch document.accessLevel {
            case .public:
                return true
            case .internal:
                return true // All internal users can access
            case .confidential:
                return document.ownerUserId == currentUser || 
                       document.collaboratorUserIds.contains(currentUser)
            case .restricted, .topSecret:
                return document.ownerUserId == currentUser
            }
        }
    }
}

// MARK: - Document Operations Enum

enum DocumentOperation {
    case read
    case write
    case delete
    case share
    case approve
}
