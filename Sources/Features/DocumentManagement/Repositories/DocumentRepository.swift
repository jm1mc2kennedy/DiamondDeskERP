//
//  DocumentRepository.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

/// Enterprise Document Repository
/// Provides data layer abstraction for document operations with caching and offline support
@MainActor
final class DocumentRepository: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var documents: [DocumentModel] = []
    @Published var filteredDocuments: [DocumentModel] = []
    @Published var isLoading = false
    @Published var error: DocumentError?
    @Published var searchQuery = ""
    @Published var selectedCategory: DocumentCategory?
    @Published var selectedAccessLevel: DocumentAccessLevel?
    @Published var selectedStatus: DocumentStatus = .active
    
    // MARK: - Private Properties
    
    private let documentService = DocumentService.shared
    private var cancellables = Set<AnyCancellable>()
    private let cache = DocumentCache()
    
    // MARK: - Cache Configuration
    
    private struct CacheConfig {
        static let maxCacheSize = 50 * 1024 * 1024 // 50MB
        static let cacheExpiration: TimeInterval = 3600 // 1 hour
        static let maxCachedDocuments = 100
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        setupFiltering()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind to document service
        documentService.$documents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] documents in
                self?.documents = documents
                self?.updateFilteredDocuments()
                self?.cache.cacheDocuments(documents)
            }
            .store(in: &cancellables)
        
        documentService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        documentService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    private func setupFiltering() {
        // Reactive filtering based on search and filter criteria
        Publishers.CombineLatest4(
            $documents,
            $searchQuery,
            $selectedCategory,
            $selectedAccessLevel
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] documents, searchQuery, category, accessLevel in
            self?.updateFilteredDocuments()
        }
        .store(in: &cancellables)
        
        $selectedStatus
            .sink { [weak self] _ in
                self?.updateFilteredDocuments()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads documents with caching support
    func loadDocuments(forceRefresh: Bool = false) async {
        if !forceRefresh, let cachedDocuments = cache.getCachedDocuments() {
            self.documents = cachedDocuments
            updateFilteredDocuments()
            
            // Still fetch fresh data in background
            Task {
                await documentService.fetchDocuments()
            }
        } else {
            await documentService.fetchDocuments()
        }
    }
    
    /// Creates a new document with validation and optimization
    func createDocument(
        title: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        category: DocumentCategory = .general,
        accessLevel: DocumentAccessLevel = .internal,
        tags: [String] = [],
        description: String? = nil
    ) async throws -> DocumentModel {
        
        // Validate input
        try validateDocumentInput(title: title, fileData: fileData, fileName: fileName, mimeType: mimeType)
        
        // Create document through service
        let document = try await documentService.uploadDocument(
            title: title,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            category: category,
            accessLevel: accessLevel,
            tags: tags,
            description: description
        )
        
        // Cache the new document
        cache.cacheDocument(document)
        
        return document
    }
    
    /// Updates an existing document
    func updateDocument(_ document: DocumentModel) async throws -> DocumentModel {
        let updatedDocument = try await documentService.updateDocument(document)
        
        // Update cache
        cache.updateDocument(updatedDocument)
        
        return updatedDocument
    }
    
    /// Deletes a document
    func deleteDocument(_ document: DocumentModel) async throws {
        try await documentService.deleteDocument(document)
        
        // Remove from cache
        cache.removeDocument(document.id)
        
        // Update filtered results
        updateFilteredDocuments()
    }
    
    /// Downloads document content with caching
    func downloadDocument(_ document: DocumentModel) async throws -> Data {
        // Check cache first
        if let cachedData = cache.getCachedDocumentData(document.id) {
            return cachedData
        }
        
        // Download from service
        let data = try await documentService.downloadDocument(document)
        
        // Cache the data
        cache.cacheDocumentData(document.id, data: data)
        
        return data
    }
    
    /// Searches documents with caching and optimization
    func searchDocuments(query: String) async {
        searchQuery = query
        
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updateFilteredDocuments()
            return
        }
        
        // Check cache for recent searches
        if let cachedResults = cache.getCachedSearchResults(query) {
            documentService.searchResults = cachedResults
            updateFilteredDocuments()
            return
        }
        
        // Perform search through service
        await documentService.searchDocuments(query: query)
        
        // Cache search results
        cache.cacheSearchResults(query, results: documentService.searchResults)
        
        updateFilteredDocuments()
    }
    
    // MARK: - Document Operations
    
    /// Checks out a document for editing
    func checkoutDocument(_ document: DocumentModel) async throws -> DocumentModel {
        let checkedOutDocument = try await documentService.checkoutDocument(document)
        cache.updateDocument(checkedOutDocument)
        return checkedOutDocument
    }
    
    /// Checks in a document
    func checkinDocument(_ document: DocumentModel) async throws -> DocumentModel {
        let checkedInDocument = try await documentService.checkinDocument(document)
        cache.updateDocument(checkedInDocument)
        return checkedInDocument
    }
    
    /// Gets document by ID with caching
    func getDocument(id: UUID) -> DocumentModel? {
        return documents.first { $0.id == id } ?? cache.getCachedDocument(id)
    }
    
    /// Gets documents by category
    func getDocuments(for category: DocumentCategory) -> [DocumentModel] {
        return documents.filter { $0.category == category && $0.status == selectedStatus }
    }
    
    /// Gets recent documents
    func getRecentDocuments(limit: Int = 10) -> [DocumentModel] {
        return documents
            .filter { $0.status == .active }
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Gets documents owned by current user
    func getMyDocuments() async -> [DocumentModel] {
        let currentUser = await getCurrentUser()
        return documents.filter { $0.ownerUserId == currentUser && $0.status == selectedStatus }
    }
    
    /// Gets shared documents
    func getSharedDocuments() async -> [DocumentModel] {
        let currentUser = await getCurrentUser()
        return documents.filter { 
            $0.ownerUserId != currentUser && 
            $0.collaboratorUserIds.contains(currentUser) && 
            $0.status == selectedStatus 
        }
    }
    
    // MARK: - Filtering and Sorting
    
    private func updateFilteredDocuments() {
        var filtered = documents
        
        // Apply status filter
        filtered = filtered.filter { $0.status == selectedStatus }
        
        // Apply search query
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = filtered.filter { document in
                document.title.localizedCaseInsensitiveContains(searchQuery) ||
                document.description?.localizedCaseInsensitiveContains(searchQuery) == true ||
                document.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) } ||
                document.searchableContent.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply access level filter
        if let accessLevel = selectedAccessLevel {
            filtered = filtered.filter { $0.accessLevel == accessLevel }
        }
        
        // Sort by modified date (most recent first)
        filtered.sort { $0.modifiedAt > $1.modifiedAt }
        
        self.filteredDocuments = filtered
    }
    
    /// Sets category filter
    func setCategoryFilter(_ category: DocumentCategory?) {
        selectedCategory = category
    }
    
    /// Sets access level filter
    func setAccessLevelFilter(_ accessLevel: DocumentAccessLevel?) {
        selectedAccessLevel = accessLevel
    }
    
    /// Sets status filter
    func setStatusFilter(_ status: DocumentStatus) {
        selectedStatus = status
    }
    
    /// Clears all filters
    func clearFilters() {
        selectedCategory = nil
        selectedAccessLevel = nil
        searchQuery = ""
        selectedStatus = .active
    }
    
    // MARK: - Analytics and Metrics
    
    /// Gets document statistics
    func getDocumentStatistics() -> DocumentStatistics {
        let activeDocuments = documents.filter { $0.status == .active }
        
        return DocumentStatistics(
            totalDocuments: activeDocuments.count,
            documentsByCategory: Dictionary(grouping: activeDocuments) { $0.category }
                .mapValues { $0.count },
            documentsByAccessLevel: Dictionary(grouping: activeDocuments) { $0.accessLevel }
                .mapValues { $0.count },
            totalFileSize: activeDocuments.reduce(0) { $0 + $1.fileSize },
            averageFileSize: activeDocuments.isEmpty ? 0 : 
                activeDocuments.reduce(0) { $0 + $1.fileSize } / Int64(activeDocuments.count),
            recentlyModified: activeDocuments.filter { 
                $0.modifiedAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            }.count
        )
    }
    
    /// Gets user activity metrics
    func getUserActivityMetrics() async -> UserActivityMetrics {
        let currentUser = await getCurrentUser()
        let userDocuments = documents.filter { $0.ownerUserId == currentUser }
        
        return UserActivityMetrics(
            documentsCreated: userDocuments.count,
            documentsModified: userDocuments.filter { 
                $0.modifiedBy == currentUser && $0.createdBy != currentUser 
            }.count,
            lastActivity: userDocuments.compactMap { $0.modifiedAt }.max(),
            storageUsed: userDocuments.reduce(0) { $0 + $1.fileSize }
        )
    }
    
    // MARK: - Utility Methods
    
    private func validateDocumentInput(
        title: String,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) throws {
        // Validate title
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.invalidData("Document title cannot be empty")
        }
        
        // Validate file name
        guard !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.invalidData("File name cannot be empty")
        }
        
        // Validate file size
        guard fileData.count > 0 else {
            throw DocumentError.invalidData("File cannot be empty")
        }
        
        // Validate MIME type
        guard !mimeType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.invalidFileType
        }
    }
    
    private func getCurrentUser() async -> String {
        // TODO: Integrate with UserProvisioningService
        return "current-user-id"
    }
    
    /// Clears error state
    func clearError() {
        error = nil
        documentService.clearError()
    }
    
    /// Refreshes data
    func refresh() {
        Task {
            await loadDocuments(forceRefresh: true)
        }
    }
    
    /// Clears cache
    func clearCache() {
        cache.clearAll()
    }
}

// MARK: - Document Cache

private class DocumentCache {
    private var documentCache: [UUID: DocumentModel] = [:]
    private var dataCache: [UUID: (data: Data, timestamp: Date)] = [:]
    private var searchCache: [String: (results: [DocumentModel], timestamp: Date)] = [:]
    private var cacheTimestamps: [UUID: Date] = [:]
    
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    private let queue = DispatchQueue(label: "com.diamonddesk.document.cache", qos: .utility)
    
    func cacheDocuments(_ documents: [DocumentModel]) {
        queue.async {
            let timestamp = Date()
            for document in documents {
                self.documentCache[document.id] = document
                self.cacheTimestamps[document.id] = timestamp
            }
            self.cleanupExpiredCache()
        }
    }
    
    func cacheDocument(_ document: DocumentModel) {
        queue.async {
            self.documentCache[document.id] = document
            self.cacheTimestamps[document.id] = Date()
        }
    }
    
    func updateDocument(_ document: DocumentModel) {
        queue.async {
            self.documentCache[document.id] = document
            self.cacheTimestamps[document.id] = Date()
        }
    }
    
    func removeDocument(_ id: UUID) {
        queue.async {
            self.documentCache.removeValue(forKey: id)
            self.dataCache.removeValue(forKey: id)
            self.cacheTimestamps.removeValue(forKey: id)
        }
    }
    
    func getCachedDocuments() -> [DocumentModel]? {
        return queue.sync {
            cleanupExpiredCache()
            return Array(documentCache.values)
        }
    }
    
    func getCachedDocument(_ id: UUID) -> DocumentModel? {
        return queue.sync {
            guard let timestamp = cacheTimestamps[id],
                  Date().timeIntervalSince(timestamp) < cacheExpiration else {
                return nil
            }
            return documentCache[id]
        }
    }
    
    func cacheDocumentData(_ id: UUID, data: Data) {
        queue.async {
            self.dataCache[id] = (data: data, timestamp: Date())
            self.cleanupDataCache()
        }
    }
    
    func getCachedDocumentData(_ id: UUID) -> Data? {
        return queue.sync {
            guard let cached = dataCache[id],
                  Date().timeIntervalSince(cached.timestamp) < cacheExpiration else {
                return nil
            }
            return cached.data
        }
    }
    
    func cacheSearchResults(_ query: String, results: [DocumentModel]) {
        queue.async {
            self.searchCache[query] = (results: results, timestamp: Date())
            self.cleanupSearchCache()
        }
    }
    
    func getCachedSearchResults(_ query: String) -> [DocumentModel]? {
        return queue.sync {
            guard let cached = searchCache[query],
                  Date().timeIntervalSince(cached.timestamp) < cacheExpiration else {
                return nil
            }
            return cached.results
        }
    }
    
    private func cleanupExpiredCache() {
        let now = Date()
        let expiredKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) > cacheExpiration ? key : nil
        }
        
        for key in expiredKeys {
            documentCache.removeValue(forKey: key)
            dataCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    private func cleanupDataCache() {
        let currentSize = dataCache.values.reduce(0) { $0 + $1.data.count }
        if currentSize > maxCacheSize {
            // Remove oldest entries until under limit
            let sortedEntries = dataCache.sorted { $0.value.timestamp < $1.value.timestamp }
            var sizeToRemove = currentSize - maxCacheSize
            
            for (key, value) in sortedEntries {
                if sizeToRemove <= 0 { break }
                dataCache.removeValue(forKey: key)
                sizeToRemove -= value.data.count
            }
        }
    }
    
    private func cleanupSearchCache() {
        let maxSearchCacheEntries = 20
        if searchCache.count > maxSearchCacheEntries {
            let sortedEntries = searchCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let entriesToRemove = searchCache.count - maxSearchCacheEntries
            
            for (key, _) in sortedEntries.prefix(entriesToRemove) {
                searchCache.removeValue(forKey: key)
            }
        }
    }
    
    func clearAll() {
        queue.async {
            self.documentCache.removeAll()
            self.dataCache.removeAll()
            self.searchCache.removeAll()
            self.cacheTimestamps.removeAll()
        }
    }
}

// MARK: - Statistics Models

struct DocumentStatistics {
    let totalDocuments: Int
    let documentsByCategory: [DocumentCategory: Int]
    let documentsByAccessLevel: [DocumentAccessLevel: Int]
    let totalFileSize: Int64
    let averageFileSize: Int64
    let recentlyModified: Int
}

struct UserActivityMetrics {
    let documentsCreated: Int
    let documentsModified: Int
    let lastActivity: Date?
    let storageUsed: Int64
}
