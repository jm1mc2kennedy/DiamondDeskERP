//
//  DocumentCollaborationService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine

/// Enterprise Document Collaboration Service
/// Manages real-time collaboration, sharing, and team workflows for documents
@MainActor
final class DocumentCollaborationService: ObservableObject {
    
    static let shared = DocumentCollaborationService()
    
    // MARK: - Published Properties
    
    @Published var activeCollaborations: [DocumentCollaboration] = []
    @Published var collaborationRequests: [CollaborationRequest] = []
    @Published var sharedDocuments: [SharedDocument] = []
    @Published var isLoading = false
    @Published var error: DocumentCollaborationError?
    
    // MARK: - Private Properties
    
    private let container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
    private var database: CKDatabase { container.privateCloudDatabase }
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - Real-time Collaboration Properties
    
    @Published var activeUsers: [CollaborationUser] = []
    @Published var documentPresence: [String: [CollaborationUser]] = [:]
    @Published var liveComments: [String: [DocumentComment]] = [:]
    @Published var documentLocks: [String: DocumentLock] = [:]
    
    // MARK: - Collaboration Metrics
    
    @Published var collaborationMetrics: CollaborationMetrics?
    
    // MARK: - Initialization
    
    private init() {
        setupSubscriptions()
        loadActiveCollaborations()
    }
    
    // MARK: - Document Sharing
    
    /// Creates a new document share with specified permissions
    func createDocumentShare(
        documentId: String,
        recipients: [CollaborationUser],
        permissions: SharePermissions,
        expirationDate: Date? = nil,
        message: String? = nil
    ) async throws -> SharedDocument {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create CloudKit share record
            let shareRecord = try await createCloudKitShare(
                documentId: documentId,
                permissions: permissions,
                expirationDate: expirationDate
            )
            
            // Create shared document model
            let sharedDocument = SharedDocument(
                id: UUID().uuidString,
                documentId: documentId,
                shareId: shareRecord.recordID.recordName,
                shareURL: shareRecord.url?.absoluteString,
                ownerId: getCurrentUserId(),
                recipients: recipients,
                permissions: permissions,
                createdAt: Date(),
                expirationDate: expirationDate,
                message: message,
                status: .active
            )
            
            // Save to CloudKit
            try await saveSharedDocument(sharedDocument)
            
            // Send notifications to recipients
            try await sendCollaborationInvitations(
                sharedDocument: sharedDocument,
                message: message
            )
            
            // Update local state
            sharedDocuments.append(sharedDocument)
            
            // Track analytics
            await trackCollaborationEvent(.documentShared, documentId: documentId)
            
            return sharedDocument
            
        } catch {
            await handleError(DocumentCollaborationError.sharingFailed(error))
            throw error
        }
    }
    
    /// Accepts a collaboration invitation
    func acceptCollaborationInvitation(_ invitation: CollaborationRequest) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Accept CloudKit share
            try await acceptCloudKitShare(shareURL: invitation.shareURL)
            
            // Update invitation status
            invitation.status = .accepted
            invitation.respondedAt = Date()
            
            // Save updated invitation
            try await saveCollaborationRequest(invitation)
            
            // Create collaboration record
            let collaboration = DocumentCollaboration(
                id: UUID().uuidString,
                documentId: invitation.documentId,
                userId: getCurrentUserId(),
                role: invitation.proposedRole,
                permissions: invitation.permissions,
                joinedAt: Date(),
                status: .active
            )
            
            try await saveDocumentCollaboration(collaboration)
            
            // Update local state
            activeCollaborations.append(collaboration)
            
            // Remove from requests
            collaborationRequests.removeAll { $0.id == invitation.id }
            
            // Notify other collaborators
            try await notifyCollaborators(
                documentId: invitation.documentId,
                event: .userJoined,
                userId: getCurrentUserId()
            )
            
            // Track analytics
            await trackCollaborationEvent(.invitationAccepted, documentId: invitation.documentId)
            
        } catch {
            await handleError(DocumentCollaborationError.invitationFailed(error))
            throw error
        }
    }
    
    /// Updates collaboration permissions for a user
    func updateCollaborationPermissions(
        documentId: String,
        userId: String,
        newPermissions: SharePermissions
    ) async throws {
        guard let collaboration = activeCollaborations.first(where: { 
            $0.documentId == documentId && $0.userId == userId 
        }) else {
            throw DocumentCollaborationError.collaborationNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update CloudKit share permissions
            try await updateCloudKitSharePermissions(
                documentId: documentId,
                userId: userId,
                permissions: newPermissions
            )
            
            // Update collaboration record
            collaboration.permissions = newPermissions
            collaboration.modifiedAt = Date()
            
            try await saveDocumentCollaboration(collaboration)
            
            // Notify user of permission change
            try await notifyCollaborators(
                documentId: documentId,
                event: .permissionsChanged,
                userId: userId
            )
            
            // Track analytics
            await trackCollaborationEvent(.permissionsUpdated, documentId: documentId)
            
        } catch {
            await handleError(DocumentCollaborationError.permissionUpdateFailed(error))
            throw error
        }
    }
    
    // MARK: - Real-time Collaboration
    
    /// Joins a document collaboration session
    func joinDocumentSession(documentId: String) async throws {
        let userId = getCurrentUserId()
        
        // Check if user has access
        guard hasCollaborationAccess(documentId: documentId, userId: userId) else {
            throw DocumentCollaborationError.accessDenied
        }
        
        do {
            // Create presence record
            let presence = CollaborationUser(
                id: userId,
                name: getCurrentUserName(),
                email: getCurrentUserEmail(),
                avatar: getCurrentUserAvatar(),
                isOnline: true,
                lastSeen: Date(),
                currentDocument: documentId,
                cursorPosition: nil
            )
            
            // Update presence in CloudKit
            try await updateUserPresence(presence)
            
            // Add to document presence
            if documentPresence[documentId] == nil {
                documentPresence[documentId] = []
            }
            documentPresence[documentId]?.append(presence)
            
            // Load existing comments for document
            try await loadDocumentComments(documentId: documentId)
            
            // Subscribe to real-time updates
            subscribeToDocumentUpdates(documentId: documentId)
            
            // Notify other users
            try await notifyCollaborators(
                documentId: documentId,
                event: .userJoined,
                userId: userId
            )
            
        } catch {
            await handleError(DocumentCollaborationError.sessionJoinFailed(error))
            throw error
        }
    }
    
    /// Leaves a document collaboration session
    func leaveDocumentSession(documentId: String) async throws {
        let userId = getCurrentUserId()
        
        do {
            // Update presence to offline
            try await updateUserPresence(CollaborationUser(
                id: userId,
                name: getCurrentUserName(),
                email: getCurrentUserEmail(),
                avatar: getCurrentUserAvatar(),
                isOnline: false,
                lastSeen: Date(),
                currentDocument: nil,
                cursorPosition: nil
            ))
            
            // Remove from document presence
            documentPresence[documentId]?.removeAll { $0.id == userId }
            
            // Unsubscribe from updates
            unsubscribeFromDocumentUpdates(documentId: documentId)
            
            // Notify other users
            try await notifyCollaborators(
                documentId: documentId,
                event: .userLeft,
                userId: userId
            )
            
        } catch {
            await handleError(DocumentCollaborationError.sessionLeaveFailed(error))
            throw error
        }
    }
    
    // MARK: - Document Comments
    
    /// Adds a comment to a document
    func addDocumentComment(
        documentId: String,
        content: String,
        replyToId: String? = nil,
        mentionedUsers: [String] = []
    ) async throws -> DocumentComment {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let comment = DocumentComment(
                id: UUID().uuidString,
                documentId: documentId,
                authorId: getCurrentUserId(),
                authorName: getCurrentUserName(),
                content: content,
                createdAt: Date(),
                replyToId: replyToId,
                mentionedUsers: mentionedUsers,
                status: .active
            )
            
            // Save to CloudKit
            try await saveDocumentComment(comment)
            
            // Update local state
            if liveComments[documentId] == nil {
                liveComments[documentId] = []
            }
            liveComments[documentId]?.append(comment)
            
            // Send notifications to mentioned users
            if !mentionedUsers.isEmpty {
                try await sendMentionNotifications(
                    comment: comment,
                    mentionedUsers: mentionedUsers
                )
            }
            
            // Notify collaborators of new comment
            try await notifyCollaborators(
                documentId: documentId,
                event: .commentAdded,
                userId: getCurrentUserId()
            )
            
            // Track analytics
            await trackCollaborationEvent(.commentAdded, documentId: documentId)
            
            return comment
            
        } catch {
            await handleError(DocumentCollaborationError.commentFailed(error))
            throw error
        }
    }
    
    /// Updates an existing comment
    func updateDocumentComment(
        commentId: String,
        newContent: String
    ) async throws {
        guard let documentId = liveComments.first(where: { 
            $0.value.contains { $0.id == commentId }
        })?.key else {
            throw DocumentCollaborationError.commentNotFound
        }
        
        guard let commentIndex = liveComments[documentId]?.firstIndex(where: { $0.id == commentId }) else {
            throw DocumentCollaborationError.commentNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let comment = liveComments[documentId]![commentIndex]
            
            // Check if user can edit comment
            guard comment.authorId == getCurrentUserId() else {
                throw DocumentCollaborationError.accessDenied
            }
            
            // Update comment
            comment.content = newContent
            comment.modifiedAt = Date()
            comment.isEdited = true
            
            // Save to CloudKit
            try await saveDocumentComment(comment)
            
            // Update local state
            liveComments[documentId]![commentIndex] = comment
            
            // Notify collaborators
            try await notifyCollaborators(
                documentId: documentId,
                event: .commentUpdated,
                userId: getCurrentUserId()
            )
            
        } catch {
            await handleError(DocumentCollaborationError.commentUpdateFailed(error))
            throw error
        }
    }
    
    // MARK: - Document Locking
    
    /// Acquires a lock on a document section
    func acquireDocumentLock(
        documentId: String,
        sectionId: String,
        lockType: DocumentLockType = .editing
    ) async throws -> DocumentLock {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check for existing locks
            let existingLock = documentLocks["\(documentId):\(sectionId)"]
            if let lock = existingLock, lock.isActive {
                throw DocumentCollaborationError.sectionLocked
            }
            
            let lock = DocumentLock(
                id: UUID().uuidString,
                documentId: documentId,
                sectionId: sectionId,
                userId: getCurrentUserId(),
                userName: getCurrentUserName(),
                lockType: lockType,
                acquiredAt: Date(),
                expiresAt: Date().addingTimeInterval(300), // 5 minutes
                isActive: true
            )
            
            // Save to CloudKit
            try await saveDocumentLock(lock)
            
            // Update local state
            documentLocks["\(documentId):\(sectionId)"] = lock
            
            // Notify collaborators
            try await notifyCollaborators(
                documentId: documentId,
                event: .sectionLocked,
                userId: getCurrentUserId()
            )
            
            // Schedule auto-release
            scheduleAutoReleaseLock(lock)
            
            return lock
            
        } catch {
            await handleError(DocumentCollaborationError.lockFailed(error))
            throw error
        }
    }
    
    /// Releases a document lock
    func releaseDocumentLock(
        documentId: String,
        sectionId: String
    ) async throws {
        let lockKey = "\(documentId):\(sectionId)"
        guard let lock = documentLocks[lockKey] else {
            throw DocumentCollaborationError.lockNotFound
        }
        
        // Check if user owns the lock
        guard lock.userId == getCurrentUserId() else {
            throw DocumentCollaborationError.accessDenied
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update lock status
            lock.isActive = false
            lock.releasedAt = Date()
            
            // Save to CloudKit
            try await saveDocumentLock(lock)
            
            // Remove from local state
            documentLocks.removeValue(forKey: lockKey)
            
            // Notify collaborators
            try await notifyCollaborators(
                documentId: documentId,
                event: .sectionUnlocked,
                userId: getCurrentUserId()
            )
            
        } catch {
            await handleError(DocumentCollaborationError.lockReleaseFailed(error))
            throw error
        }
    }
    
    // MARK: - Collaboration Analytics
    
    /// Loads collaboration metrics for analytics
    func loadCollaborationMetrics(timeRange: TimeRange = .lastMonth) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let metrics = try await fetchCollaborationMetrics(timeRange: timeRange)
            self.collaborationMetrics = metrics
            
        } catch {
            await handleError(DocumentCollaborationError.metricsFailed(error))
            throw error
        }
    }
    
    // MARK: - Private CloudKit Methods
    
    private func createCloudKitShare(
        documentId: String,
        permissions: SharePermissions,
        expirationDate: Date?
    ) async throws -> CKShare {
        // Implementation for creating CloudKit share
        let shareRecord = CKShare(rootRecord: CKRecord(recordType: "Document", recordID: CKRecord.ID(recordName: documentId)))
        
        // Configure share permissions
        shareRecord[CKShare.SystemFieldKey.publicPermission] = permissions.toCloudKitPermission()
        
        if let expiration = expirationDate {
            shareRecord.expirationDate = expiration
        }
        
        let (savedRecords, _) = try await database.modifyRecords(saving: [shareRecord], deleting: [])
        
        guard let share = savedRecords.first as? CKShare else {
            throw DocumentCollaborationError.cloudKitError
        }
        
        return share
    }
    
    private func acceptCloudKitShare(shareURL: String) async throws {
        guard let url = URL(string: shareURL) else {
            throw DocumentCollaborationError.invalidShareURL
        }
        
        let shareMetadata = try await container.fetchShareMetadata(with: url)
        let acceptResult = try await container.accept(shareMetadata)
        
        // Handle acceptance result
        print("Share accepted: \(acceptResult)")
    }
    
    private func updateCloudKitSharePermissions(
        documentId: String,
        userId: String,
        permissions: SharePermissions
    ) async throws {
        // Implementation for updating CloudKit share permissions
        // This would involve fetching the share record and updating participant permissions
    }
    
    // MARK: - Private Data Methods
    
    private func saveSharedDocument(_ sharedDocument: SharedDocument) async throws {
        let record = sharedDocument.toCKRecord()
        try await database.save(record)
    }
    
    private func saveCollaborationRequest(_ request: CollaborationRequest) async throws {
        let record = request.toCKRecord()
        try await database.save(record)
    }
    
    private func saveDocumentCollaboration(_ collaboration: DocumentCollaboration) async throws {
        let record = collaboration.toCKRecord()
        try await database.save(record)
    }
    
    private func saveDocumentComment(_ comment: DocumentComment) async throws {
        let record = comment.toCKRecord()
        try await database.save(record)
    }
    
    private func saveDocumentLock(_ lock: DocumentLock) async throws {
        let record = lock.toCKRecord()
        try await database.save(record)
    }
    
    // MARK: - Private Utility Methods
    
    private func setupSubscriptions() {
        // Setup CloudKit subscriptions for real-time updates
    }
    
    private func loadActiveCollaborations() {
        Task {
            do {
                // Load user's active collaborations
                let collaborations = try await fetchUserCollaborations()
                await MainActor.run {
                    self.activeCollaborations = collaborations
                }
            } catch {
                await handleError(DocumentCollaborationError.loadFailed(error))
            }
        }
    }
    
    private func fetchUserCollaborations() async throws -> [DocumentCollaboration] {
        // Implementation for fetching user collaborations from CloudKit
        return []
    }
    
    private func hasCollaborationAccess(documentId: String, userId: String) -> Bool {
        return activeCollaborations.contains { 
            $0.documentId == documentId && $0.userId == userId && $0.status == .active
        }
    }
    
    private func getCurrentUserId() -> String {
        // Return current user ID from user session
        return "current-user-id"
    }
    
    private func getCurrentUserName() -> String {
        // Return current user name from user session
        return "Current User"
    }
    
    private func getCurrentUserEmail() -> String {
        // Return current user email from user session
        return "user@example.com"
    }
    
    private func getCurrentUserAvatar() -> String? {
        // Return current user avatar URL from user session
        return nil
    }
    
    private func sendCollaborationInvitations(
        sharedDocument: SharedDocument,
        message: String?
    ) async throws {
        // Implementation for sending invitation notifications
    }
    
    private func notifyCollaborators(
        documentId: String,
        event: CollaborationEvent,
        userId: String
    ) async throws {
        // Implementation for notifying collaborators of events
    }
    
    private func updateUserPresence(_ user: CollaborationUser) async throws {
        // Implementation for updating user presence in CloudKit
    }
    
    private func loadDocumentComments(documentId: String) async throws {
        // Implementation for loading document comments
    }
    
    private func subscribeToDocumentUpdates(documentId: String) {
        // Implementation for subscribing to real-time document updates
    }
    
    private func unsubscribeFromDocumentUpdates(documentId: String) {
        // Implementation for unsubscribing from document updates
    }
    
    private func sendMentionNotifications(
        comment: DocumentComment,
        mentionedUsers: [String]
    ) async throws {
        // Implementation for sending mention notifications
    }
    
    private func scheduleAutoReleaseLock(_ lock: DocumentLock) {
        // Implementation for auto-releasing expired locks
    }
    
    private func fetchCollaborationMetrics(timeRange: TimeRange) async throws -> CollaborationMetrics {
        // Implementation for fetching collaboration analytics
        return CollaborationMetrics(
            totalCollaborations: 0,
            activeUsers: 0,
            documentsShared: 0,
            commentsAdded: 0,
            averageSessionDuration: 0,
            topCollaborators: [],
            activityTimeline: []
        )
    }
    
    private func trackCollaborationEvent(_ event: CollaborationEvent, documentId: String) async {
        // Implementation for tracking collaboration analytics
    }
    
    private func handleError(_ error: DocumentCollaborationError) async {
        await MainActor.run {
            self.error = error
        }
    }
}

// MARK: - Supporting Models

/// Document Collaboration Model
class DocumentCollaboration: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let userId: String
    let role: CollaborationRole
    @Published var permissions: SharePermissions
    let joinedAt: Date
    @Published var lastActiveAt: Date
    @Published var status: CollaborationStatus
    @Published var modifiedAt: Date?
    
    init(
        id: String,
        documentId: String,
        userId: String,
        role: CollaborationRole,
        permissions: SharePermissions,
        joinedAt: Date,
        status: CollaborationStatus
    ) {
        self.id = id
        self.documentId = documentId
        self.userId = userId
        self.role = role
        self.permissions = permissions
        self.joinedAt = joinedAt
        self.lastActiveAt = joinedAt
        self.status = status
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "DocumentCollaboration", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["userId"] = userId
        record["role"] = role.rawValue
        record["permissions"] = try? JSONEncoder().encode(permissions)
        record["joinedAt"] = joinedAt
        record["lastActiveAt"] = lastActiveAt
        record["status"] = status.rawValue
        record["modifiedAt"] = modifiedAt
        return record
    }
}

/// Collaboration Request Model
class CollaborationRequest: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let senderId: String
    let recipientId: String
    let shareURL: String
    let proposedRole: CollaborationRole
    let permissions: SharePermissions
    let message: String?
    let sentAt: Date
    @Published var status: RequestStatus
    @Published var respondedAt: Date?
    
    init(
        id: String,
        documentId: String,
        senderId: String,
        recipientId: String,
        shareURL: String,
        proposedRole: CollaborationRole,
        permissions: SharePermissions,
        message: String?,
        sentAt: Date,
        status: RequestStatus
    ) {
        self.id = id
        self.documentId = documentId
        self.senderId = senderId
        self.recipientId = recipientId
        self.shareURL = shareURL
        self.proposedRole = proposedRole
        self.permissions = permissions
        self.message = message
        self.sentAt = sentAt
        self.status = status
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "CollaborationRequest", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["senderId"] = senderId
        record["recipientId"] = recipientId
        record["shareURL"] = shareURL
        record["proposedRole"] = proposedRole.rawValue
        record["permissions"] = try? JSONEncoder().encode(permissions)
        record["message"] = message
        record["sentAt"] = sentAt
        record["status"] = status.rawValue
        record["respondedAt"] = respondedAt
        return record
    }
}

/// Shared Document Model
class SharedDocument: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let shareId: String
    let shareURL: String?
    let ownerId: String
    let recipients: [CollaborationUser]
    let permissions: SharePermissions
    let createdAt: Date
    let expirationDate: Date?
    let message: String?
    @Published var status: ShareStatus
    @Published var accessCount: Int = 0
    @Published var lastAccessedAt: Date?
    
    init(
        id: String,
        documentId: String,
        shareId: String,
        shareURL: String?,
        ownerId: String,
        recipients: [CollaborationUser],
        permissions: SharePermissions,
        createdAt: Date,
        expirationDate: Date?,
        message: String?,
        status: ShareStatus
    ) {
        self.id = id
        self.documentId = documentId
        self.shareId = shareId
        self.shareURL = shareURL
        self.ownerId = ownerId
        self.recipients = recipients
        self.permissions = permissions
        self.createdAt = createdAt
        self.expirationDate = expirationDate
        self.message = message
        self.status = status
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "SharedDocument", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["shareId"] = shareId
        record["shareURL"] = shareURL
        record["ownerId"] = ownerId
        record["recipients"] = try? JSONEncoder().encode(recipients)
        record["permissions"] = try? JSONEncoder().encode(permissions)
        record["createdAt"] = createdAt
        record["expirationDate"] = expirationDate
        record["message"] = message
        record["status"] = status.rawValue
        record["accessCount"] = accessCount
        record["lastAccessedAt"] = lastAccessedAt
        return record
    }
}

/// Collaboration User Model
struct CollaborationUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let avatar: String?
    var isOnline: Bool
    var lastSeen: Date
    var currentDocument: String?
    var cursorPosition: CursorPosition?
}

/// Document Comment Model
class DocumentComment: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let authorId: String
    let authorName: String
    @Published var content: String
    let createdAt: Date
    @Published var modifiedAt: Date?
    let replyToId: String?
    let mentionedUsers: [String]
    @Published var status: CommentStatus
    @Published var isEdited: Bool = false
    @Published var reactions: [CommentReaction] = []
    
    init(
        id: String,
        documentId: String,
        authorId: String,
        authorName: String,
        content: String,
        createdAt: Date,
        replyToId: String? = nil,
        mentionedUsers: [String] = [],
        status: CommentStatus
    ) {
        self.id = id
        self.documentId = documentId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
        self.replyToId = replyToId
        self.mentionedUsers = mentionedUsers
        self.status = status
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "DocumentComment", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["authorId"] = authorId
        record["authorName"] = authorName
        record["content"] = content
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["replyToId"] = replyToId
        record["mentionedUsers"] = mentionedUsers
        record["status"] = status.rawValue
        record["isEdited"] = isEdited
        record["reactions"] = try? JSONEncoder().encode(reactions)
        return record
    }
}

/// Document Lock Model
class DocumentLock: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let sectionId: String
    let userId: String
    let userName: String
    let lockType: DocumentLockType
    let acquiredAt: Date
    let expiresAt: Date
    @Published var isActive: Bool
    @Published var releasedAt: Date?
    
    init(
        id: String,
        documentId: String,
        sectionId: String,
        userId: String,
        userName: String,
        lockType: DocumentLockType,
        acquiredAt: Date,
        expiresAt: Date,
        isActive: Bool
    ) {
        self.id = id
        self.documentId = documentId
        self.sectionId = sectionId
        self.userId = userId
        self.userName = userName
        self.lockType = lockType
        self.acquiredAt = acquiredAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "DocumentLock", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["sectionId"] = sectionId
        record["userId"] = userId
        record["userName"] = userName
        record["lockType"] = lockType.rawValue
        record["acquiredAt"] = acquiredAt
        record["expiresAt"] = expiresAt
        record["isActive"] = isActive
        record["releasedAt"] = releasedAt
        return record
    }
}

/// Collaboration Metrics Model
struct CollaborationMetrics: Codable {
    let totalCollaborations: Int
    let activeUsers: Int
    let documentsShared: Int
    let commentsAdded: Int
    let averageSessionDuration: TimeInterval
    let topCollaborators: [CollaboratorMetric]
    let activityTimeline: [ActivityPoint]
}

struct CollaboratorMetric: Codable {
    let userId: String
    let userName: String
    let collaborationCount: Int
    let commentsCount: Int
    let lastActive: Date
}

struct ActivityPoint: Codable {
    let date: Date
    let activeUsers: Int
    let documentsShared: Int
    let comments: Int
}

// MARK: - Enums and Supporting Types

enum CollaborationRole: String, CaseIterable, Codable {
    case viewer
    case commenter
    case editor
    case admin
    
    var displayName: String {
        switch self {
        case .viewer: return "Viewer"
        case .commenter: return "Commenter"
        case .editor: return "Editor"
        case .admin: return "Admin"
        }
    }
    
    var permissions: SharePermissions {
        switch self {
        case .viewer: return SharePermissions(canRead: true, canWrite: false, canShare: false, canDelete: false)
        case .commenter: return SharePermissions(canRead: true, canWrite: false, canShare: false, canDelete: false, canComment: true)
        case .editor: return SharePermissions(canRead: true, canWrite: true, canShare: false, canDelete: false, canComment: true)
        case .admin: return SharePermissions(canRead: true, canWrite: true, canShare: true, canDelete: true, canComment: true)
        }
    }
}

struct SharePermissions: Codable {
    let canRead: Bool
    let canWrite: Bool
    let canShare: Bool
    let canDelete: Bool
    let canComment: Bool
    
    init(canRead: Bool, canWrite: Bool, canShare: Bool, canDelete: Bool, canComment: Bool = true) {
        self.canRead = canRead
        self.canWrite = canWrite
        self.canShare = canShare
        self.canDelete = canDelete
        self.canComment = canComment
    }
    
    func toCloudKitPermission() -> CKShare.ParticipantPermission {
        if canWrite { return .readWrite }
        return .readOnly
    }
}

enum CollaborationStatus: String, CaseIterable, Codable {
    case active
    case paused
    case ended
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .ended: return "Ended"
        }
    }
}

enum RequestStatus: String, CaseIterable, Codable {
    case pending
    case accepted
    case declined
    case expired
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }
}

enum ShareStatus: String, CaseIterable, Codable {
    case active
    case expired
    case revoked
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .expired: return "Expired"
        case .revoked: return "Revoked"
        }
    }
}

enum CommentStatus: String, CaseIterable, Codable {
    case active
    case hidden
    case deleted
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .hidden: return "Hidden"
        case .deleted: return "Deleted"
        }
    }
}

enum DocumentLockType: String, CaseIterable, Codable {
    case editing
    case reviewing
    case formatting
    
    var displayName: String {
        switch self {
        case .editing: return "Editing"
        case .reviewing: return "Reviewing"
        case .formatting: return "Formatting"
        }
    }
}

enum CollaborationEvent: String, CaseIterable, Codable {
    case documentShared
    case invitationAccepted
    case invitationDeclined
    case permissionsUpdated
    case userJoined
    case userLeft
    case commentAdded
    case commentUpdated
    case commentDeleted
    case sectionLocked
    case sectionUnlocked
    
    var displayName: String {
        switch self {
        case .documentShared: return "Document Shared"
        case .invitationAccepted: return "Invitation Accepted"
        case .invitationDeclined: return "Invitation Declined"
        case .permissionsUpdated: return "Permissions Updated"
        case .userJoined: return "User Joined"
        case .userLeft: return "User Left"
        case .commentAdded: return "Comment Added"
        case .commentUpdated: return "Comment Updated"
        case .commentDeleted: return "Comment Deleted"
        case .sectionLocked: return "Section Locked"
        case .sectionUnlocked: return "Section Unlocked"
        }
    }
}

struct CursorPosition: Codable {
    let line: Int
    let column: Int
    let selection: TextRange?
}

struct TextRange: Codable {
    let start: Int
    let end: Int
}

struct CommentReaction: Codable, Identifiable {
    let id: String
    let userId: String
    let reaction: String
    let createdAt: Date
}

enum TimeRange: String, CaseIterable {
    case lastWeek
    case lastMonth
    case lastQuarter
    case lastYear
    
    var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastQuarter: return "Last Quarter"
        case .lastYear: return "Last Year"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .lastWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastQuarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}

// MARK: - Error Types

enum DocumentCollaborationError: LocalizedError {
    case sharingFailed(Error)
    case invitationFailed(Error)
    case collaborationNotFound
    case permissionUpdateFailed(Error)
    case sessionJoinFailed(Error)
    case sessionLeaveFailed(Error)
    case commentFailed(Error)
    case commentNotFound
    case commentUpdateFailed(Error)
    case lockFailed(Error)
    case lockNotFound
    case lockReleaseFailed(Error)
    case sectionLocked
    case accessDenied
    case invalidShareURL
    case cloudKitError
    case loadFailed(Error)
    case metricsFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .sharingFailed(let error):
            return "Failed to share document: \(error.localizedDescription)"
        case .invitationFailed(let error):
            return "Failed to process invitation: \(error.localizedDescription)"
        case .collaborationNotFound:
            return "Collaboration not found"
        case .permissionUpdateFailed(let error):
            return "Failed to update permissions: \(error.localizedDescription)"
        case .sessionJoinFailed(let error):
            return "Failed to join collaboration session: \(error.localizedDescription)"
        case .sessionLeaveFailed(let error):
            return "Failed to leave collaboration session: \(error.localizedDescription)"
        case .commentFailed(let error):
            return "Failed to add comment: \(error.localizedDescription)"
        case .commentNotFound:
            return "Comment not found"
        case .commentUpdateFailed(let error):
            return "Failed to update comment: \(error.localizedDescription)"
        case .lockFailed(let error):
            return "Failed to acquire lock: \(error.localizedDescription)"
        case .lockNotFound:
            return "Document lock not found"
        case .lockReleaseFailed(let error):
            return "Failed to release lock: \(error.localizedDescription)"
        case .sectionLocked:
            return "Document section is currently locked by another user"
        case .accessDenied:
            return "Access denied"
        case .invalidShareURL:
            return "Invalid share URL"
        case .cloudKitError:
            return "CloudKit operation failed"
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .metricsFailed(let error):
            return "Failed to load metrics: \(error.localizedDescription)"
        }
    }
}
