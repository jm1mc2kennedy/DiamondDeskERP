@MainActor
class DocumentViewModelTests: XCTestCase {
    class MockSuccessService: DocumentService {
        override init() { super.init() }
        var savedDocument: Document?
        var deletedDocument: Document?

        override func fetchDocuments() async throws -> [Document] {
            return [Document(title: "Doc1", category: "Cat", version: 1, assetURL: nil, createdBy: "User")] 
        }
        override func saveDocument(_ document: Document) async throws {
            savedDocument = document
        }
        override func deleteDocument(_ document: Document) async throws {
            deletedDocument = document
        }
    }

    class MockFailService: DocumentService {
        override init() { super.init() }
        override func fetchDocuments() async throws -> [Document] {
            throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        }
    }

    func testLoadDocumentsSuccess() async {
        let service = MockSuccessService()
        let viewModel = DocumentViewModel(service: service)
        let task = Task { await viewModel.loadDocuments() }
        await task.value
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.documents.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadDocumentsFailure() async {
        let service = MockFailService()
        let viewModel = DocumentViewModel(service: service)
        await viewModel.loadDocuments()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.documents.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Fetch failed")
    }

    func testSaveDocumentCallsServiceAndReloads() async {
        let service = MockSuccessService()
        let viewModel = DocumentViewModel(service: service)
        let newDoc = Document(title: "NewDoc", category: nil, version: 2, assetURL: URL(string: "https://example.com"), createdBy: "User")
        await viewModel.saveDocument(newDoc)
        XCTAssertEqual(service.savedDocument, newDoc)
    }

    func testDeleteDocumentCallsServiceAndReloads() async {
        let service = MockSuccessService()
        let viewModel = DocumentViewModel(service: service)
        let doc = Document(title: "ToDelete", category: nil, version: 1, assetURL: nil, createdBy: "User")
        await viewModel.deleteDocument(doc)
        XCTAssertEqual(service.deletedDocument, doc)
    }
}

