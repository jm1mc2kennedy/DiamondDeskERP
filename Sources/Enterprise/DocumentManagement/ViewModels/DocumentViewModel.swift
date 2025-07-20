//
//  DocumentViewModel.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

/// Enterprise Document Management ViewModel
/// Provides presentation logic and state management for document operations
@MainActor
final class DocumentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var documents: [DocumentModel] = []
    @Published var filteredDocuments: [DocumentModel] = []
    @Published var selectedDocument: DocumentModel?
    @Published var isLoading = false
    @Published var error: DocumentError?
    @Published var showingError = false
    
    // MARK: - Filter and Search Properties
    
    @Published var searchText = ""
    @Published var selectedCategory: DocumentCategory?
    @Published var selectedAccessLevel: DocumentAccessLevel?
    @Published var selectedStatus: DocumentStatus = .active
    @Published var sortOrder: DocumentSortOrder = .modifiedDateDesc
    
    // MARK: - UI State Properties
    
    @Published var showingDocumentPicker = false
    @Published var showingCreateSheet = false
    @Published var showingDetailView = false
    @Published var showingDeleteConfirmation = false
    @Published var showingFilterSheet = false
    @Published var showingAdvancedSearchSheet = false
    @Published var showingUploadProgress = false
    @Published var uploadProgress: Double = 0.0
    @Published var showingShareSheet = false
    @Published var shareURL: URL?
    
    // MARK: - Form Properties
    
    @Published var newDocumentTitle = ""
    @Published var newDocumentDescription = ""
    @Published var newDocumentCategory: DocumentCategory = .general
    @Published var newDocumentAccessLevel: DocumentAccessLevel = .internal
    @Published var newDocumentTags = ""
    @Published var selectedFileURL: URL?
    
    // MARK: - Analytics Properties
    
    @Published var documentStatistics: DocumentStatistics?
    @Published var userActivityMetrics: UserActivityMetrics?
    
    // MARK: - Private Properties
    
    private let repository = DocumentRepository()
    private var cancellables = Set<AnyCancellable>()
    private let debouncer = PassthroughSubject<String, Never>()
    
    // MARK: - Computed Properties
    
    var hasDocuments: Bool {
        !filteredDocuments.isEmpty
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if selectedAccessLevel != nil { count += 1 }
        if !searchText.isEmpty { count += 1 }
        if selectedStatus != .active { count += 1 }
        return count
    }
    
    var isFormValid: Bool {
        !newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedFileURL != nil
    }
    
    var categoryCounts: [DocumentCategory: Int] {
        Dictionary(grouping: documents.filter { $0.status == selectedStatus }) { $0.category }
            .mapValues { $0.count }
    }
    
    var accessLevelCounts: [DocumentAccessLevel: Int] {
        Dictionary(grouping: documents.filter { $0.status == selectedStatus }) { $0.accessLevel }
            .mapValues { $0.count }
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        setupSearch()
        loadDocuments()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind repository properties
        repository.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: \.documents, on: self)
            .store(in: &cancellables)
        
        repository.$filteredDocuments
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredDocuments, on: self)
            .store(in: &cancellables)
        
        repository.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        repository.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
                self?.showingError = error != nil
            }
            .store(in: &cancellables)
        
        // Bind filter properties to repository
        $selectedCategory
            .sink { [weak self] category in
                self?.repository.setCategoryFilter(category)
            }
            .store(in: &cancellables)
        
        $selectedAccessLevel
            .sink { [weak self] accessLevel in
                self?.repository.setAccessLevelFilter(accessLevel)
            }
            .store(in: &cancellables)
        
        $selectedStatus
            .sink { [weak self] status in
                self?.repository.setStatusFilter(status)
            }
            .store(in: &cancellables)
    }
    
    private func setupSearch() {
        // Debounced search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.repository.searchDocuments(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads documents from repository
    func loadDocuments() {
        Task {
            await repository.loadDocuments()
            await loadStatistics()
        }
    }
    
    /// Refreshes document data
    func refresh() {
        Task {
            await repository.loadDocuments(forceRefresh: true)
            await loadStatistics()
        }
    }
    
    /// Creates a new document
    func createDocument() {
        guard let fileURL = selectedFileURL else { return }
        
        Task {
            do {
                showingUploadProgress = true
                
                let fileData = try Data(contentsOf: fileURL)
                let fileName = fileURL.lastPathComponent
                let mimeType = fileURL.mimeType
                
                let tags = newDocumentTags
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                let document = try await repository.createDocument(
                    title: newDocumentTitle,
                    fileData: fileData,
                    fileName: fileName,
                    mimeType: mimeType,
                    category: newDocumentCategory,
                    accessLevel: newDocumentAccessLevel,
                    tags: tags,
                    description: newDocumentDescription.isEmpty ? nil : newDocumentDescription
                )
                
                // Reset form
                resetForm()
                showingCreateSheet = false
                showingUploadProgress = false
                
                // Select the new document
                selectedDocument = document
                showingDetailView = true
                
            } catch {
                showingUploadProgress = false
                handleError(error)
            }
        }
    }
    
    /// Updates an existing document
    func updateDocument(_ document: DocumentModel) {
        Task {
            do {
                let updatedDocument = try await repository.updateDocument(document)
                selectedDocument = updatedDocument
            } catch {
                handleError(error)
            }
        }
    }
    
    /// Deletes a document
    func deleteDocument(_ document: DocumentModel) {
        Task {
            do {
                try await repository.deleteDocument(document)
                if selectedDocument?.id == document.id {
                    selectedDocument = nil
                    showingDetailView = false
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    /// Downloads document content
    func downloadDocument(_ document: DocumentModel) async throws -> Data {
        return try await repository.downloadDocument(document)
    }
    
    /// Checks out a document for editing
    func checkoutDocument(_ document: DocumentModel) {
        Task {
            do {
                let checkedOutDocument = try await repository.checkoutDocument(document)
                selectedDocument = checkedOutDocument
            } catch {
                handleError(error)
            }
        }
    }
    
    /// Checks in a document
    func checkinDocument(_ document: DocumentModel) {
        Task {
            do {
                let checkedInDocument = try await repository.checkinDocument(document)
                selectedDocument = checkedInDocument
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Document Selection and Navigation
    
    /// Selects a document and shows detail view
    func selectDocument(_ document: DocumentModel) {
        selectedDocument = document
        showingDetailView = true
    }
    
    /// Deselects current document
    func deselectDocument() {
        selectedDocument = nil
        showingDetailView = false
    }
    
    // MARK: - Filtering and Sorting
    
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
    
    /// Sets sort order
    func setSortOrder(_ sortOrder: DocumentSortOrder) {
        self.sortOrder = sortOrder
        applySorting()
    }
    
    /// Clears all filters
    func clearFilters() {
        selectedCategory = nil
        selectedAccessLevel = nil
        searchText = ""
        selectedStatus = .active
        repository.clearFilters()
    }
    
    private func applySorting() {
        filteredDocuments.sort { doc1, doc2 in
            switch sortOrder {
            case .titleAsc:
                return doc1.title < doc2.title
            case .titleDesc:
                return doc1.title > doc2.title
            case .modifiedDateAsc:
                return doc1.modifiedAt < doc2.modifiedAt
            case .modifiedDateDesc:
                return doc1.modifiedAt > doc2.modifiedAt
            case .createdDateAsc:
                return doc1.createdAt < doc2.createdAt
            case .createdDateDesc:
                return doc1.createdAt > doc2.createdAt
            case .fileSizeAsc:
                return doc1.fileSize < doc2.fileSize
            case .fileSizeDesc:
                return doc1.fileSize > doc2.fileSize
            case .categoryAsc:
                return doc1.category.rawValue < doc2.category.rawValue
            case .categoryDesc:
                return doc1.category.rawValue > doc2.category.rawValue
            }
        }
    }
    
    // MARK: - Statistics and Analytics
    
    private func loadStatistics() async {
        documentStatistics = repository.getDocumentStatistics()
        userActivityMetrics = await repository.getUserActivityMetrics()
    }
    
    /// Gets recent documents
    func getRecentDocuments(limit: Int = 10) -> [DocumentModel] {
        return repository.getRecentDocuments(limit: limit)
    }
    
    /// Gets documents by category
    func getDocuments(for category: DocumentCategory) -> [DocumentModel] {
        return repository.getDocuments(for: category)
    }
    
    /// Gets my documents
    func getMyDocuments() async -> [DocumentModel] {
        return await repository.getMyDocuments()
    }
    
    /// Gets shared documents
    func getSharedDocuments() async -> [DocumentModel] {
        return await repository.getSharedDocuments()
    }
    
    // MARK: - Form Management
    
    /// Shows create document sheet
    func showCreateSheet() {
        resetForm()
        showingCreateSheet = true
    }
    
    /// Resets the create form
    func resetForm() {
        newDocumentTitle = ""
        newDocumentDescription = ""
        newDocumentCategory = .general
        newDocumentAccessLevel = .internal
        newDocumentTags = ""
        selectedFileURL = nil
    }
    
    /// Handles file selection from document picker
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFileURL = url
                
                // Auto-populate title from filename if empty
                if newDocumentTitle.isEmpty {
                    newDocumentTitle = url.deletingPathExtension().lastPathComponent
                }
            }
        case .failure(let error):
            handleError(error)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let documentError = error as? DocumentError {
            self.error = documentError
        } else {
            self.error = .invalidRecord(error.localizedDescription)
        }
        showingError = true
    }
    
    /// Clears current error
    func clearError() {
        error = nil
        showingError = false
        repository.clearError()
    }
    
    // MARK: - UI Actions
    
    /// Shows document picker
    func showDocumentPicker() {
        showingDocumentPicker = true
    }
    
    /// Shows filter sheet
    func showFilterSheet() {
        showingFilterSheet = true
    }
    
    /// Shows advanced search sheet
    func showAdvancedSearch() {
        showingAdvancedSearchSheet = true
    }
    
    /// Confirms document deletion
    func confirmDeleteDocument(_ document: DocumentModel) {
        selectedDocument = document
        showingDeleteConfirmation = true
    }
    
    /// Shares a document
    func shareDocument(_ document: DocumentModel) {
        Task {
            do {
                let data = try await downloadDocument(document)
                
                // Create temporary file for sharing
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(document.fileName)
                
                try data.write(to: tempURL)
                
                // Show share sheet
                await MainActor.run {
                    shareURL = tempURL
                    showingShareSheet = true
                }
                
            } catch {
                handleError(error)
            }
        }
    }
    
    /// Exports document to Files app
    func exportDocument(_ document: DocumentModel) {
        Task {
            do {
                let data = try await downloadDocument(document)
                
                // Export to Files app via document picker
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(document.fileName)
                
                try data.write(to: tempURL)
                
                await MainActor.run {
                    shareURL = tempURL
                    showingShareSheet = true
                }
                
            } catch {
                handleError(error)
            }
        }
    }
}

// MARK: - Document Sort Order

enum DocumentSortOrder: String, CaseIterable {
    case titleAsc = "Title A-Z"
    case titleDesc = "Title Z-A"
    case modifiedDateAsc = "Modified (Oldest)"
    case modifiedDateDesc = "Modified (Newest)"
    case createdDateAsc = "Created (Oldest)"
    case createdDateDesc = "Created (Newest)"
    case fileSizeAsc = "Size (Smallest)"
    case fileSizeDesc = "Size (Largest)"
    case categoryAsc = "Category A-Z"
    case categoryDesc = "Category Z-A"
    
    var displayName: String {
        return self.rawValue
    }
    
    var systemImage: String {
        switch self {
        case .titleAsc, .titleDesc:
            return "textformat"
        case .modifiedDateAsc, .modifiedDateDesc:
            return "clock"
        case .createdDateAsc, .createdDateDesc:
            return "calendar"
        case .fileSizeAsc, .fileSizeDesc:
            return "doc.badge.gearshape"
        case .categoryAsc, .categoryDesc:
            return "folder"
        }
    }
}

// MARK: - URL Extensions

extension URL {
    var mimeType: String {
        if let typeID = try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let mimeType = UTType(typeID)?.preferredMIMEType {
            return mimeType
        }
        
        // Fallback based on file extension
        switch pathExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "txt":
            return "text/plain"
        case "md":
            return "text/markdown"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - View Model Factory

extension DocumentViewModel {
    
    /// Creates a view model for a specific document category
    static func forCategory(_ category: DocumentCategory) -> DocumentViewModel {
        let viewModel = DocumentViewModel()
        viewModel.selectedCategory = category
        return viewModel
    }
    
    /// Creates a view model for a specific access level
    static func forAccessLevel(_ accessLevel: DocumentAccessLevel) -> DocumentViewModel {
        let viewModel = DocumentViewModel()
        viewModel.selectedAccessLevel = accessLevel
        return viewModel
    }
    
    /// Creates a view model with predefined filters
    static func withFilters(
        category: DocumentCategory? = nil,
        accessLevel: DocumentAccessLevel? = nil,
        status: DocumentStatus = .active
    ) -> DocumentViewModel {
        let viewModel = DocumentViewModel()
        viewModel.selectedCategory = category
        viewModel.selectedAccessLevel = accessLevel
        viewModel.selectedStatus = status
        return viewModel
    }
}
