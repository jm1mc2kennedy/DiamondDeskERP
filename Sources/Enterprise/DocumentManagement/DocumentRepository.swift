import Foundation
import CloudKit

class DocumentRepository {
    private let database = CKContainer.default().privateCloudDatabase

    /// Fetch all documents from CloudKit
    func fetchAllDocuments() async throws -> [Document] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Document", predicate: predicate)
        let (matchResults, _) = try await database.records(matching: query)
        var docs: [Document] = []
        for result in matchResults {
            switch result {
            case .success(_, let record):
                if let doc = Document.fromCloudKitRecord(record) {
                    docs.append(doc)
                }
            case .failure(let error, _):
                throw error
            }
        }
        return docs
    }

    /// Save or update a document record
    func saveDocumentRecord(_ document: Document) async throws {
        let record = document.toCloudKitRecord()
        try await database.save(record)
    }

    /// Delete a document by record ID
    func deleteDocumentRecord(id: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: id)
    }
}
