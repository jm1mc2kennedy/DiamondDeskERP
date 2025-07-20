import Foundation
import CloudKit

@MainActor
class DocumentService {
    static let shared = DocumentService()
    init() {}

    /// Fetch all documents
    func fetchDocuments() async throws -> [Document] {
        let repo = DocumentRepository()
        return try await repo.fetchAllDocuments()
    }

    /// Save or update a document
    func saveDocument(_ document: Document) async throws {
        let repo = DocumentRepository()
        try await repo.saveDocumentRecord(document)
    }

    /// Delete a document
    func deleteDocument(_ document: Document) async throws {
        let repo = DocumentRepository()
        let recordID = CKRecord.ID(recordName: document.id.uuidString)
        try await repo.deleteDocumentRecord(id: recordID)
    }
}
