import Foundation
import SwiftUI

@MainActor
class DocumentViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: DocumentService

    init(service: DocumentService = .shared) {
        self.service = service
    }

    /// Load all documents
    func loadDocuments() async {
        isLoading = true
        errorMessage = nil
        do {
            documents = try await service.fetchDocuments()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Save or update a document
    func saveDocument(_ document: Document) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await service.saveDocument(document)
            await loadDocuments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Delete a document
    func deleteDocument(_ document: Document) async {
        errorMessage = nil
        do {
            try await service.deleteDocument(document)
            await loadDocuments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
