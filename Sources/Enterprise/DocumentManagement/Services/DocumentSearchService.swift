//
//  DocumentSearchService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine
import NaturalLanguage

/// Advanced Document Search Service
/// Provides full-text search, content indexing, and intelligent search capabilities
@MainActor
final class DocumentSearchService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchResults: [DocumentSearchResult] = []
    @Published var isSearching = false
    @Published var searchSuggestions: [String] = []
    @Published var recentSearches: [String] = []
    @Published var popularTags: [String] = []
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    private let searchIndex = DocumentSearchIndex()
    private let nlProcessor = NLLanguageRecognizer()
    
    // Search Configuration
    private let maxSearchResults = 50
    private let maxRecentSearches = 20
    private let searchDebounceTime: TimeInterval = 0.3
    
    // MARK: - Singleton
    
    static let shared = DocumentSearchService()
    
    // MARK: - Initialization
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.hannoush.DiamondDeskERP")
        self.privateDatabase = container.privateCloudDatabase
        
        loadRecentSearches()
        loadPopularTags()
    }
    
    // MARK: - Search Operations
    
    /// Performs comprehensive document search with multiple search strategies
    func searchDocuments(
        query: String,
        filters: DocumentSearchFilters = DocumentSearchFilters(),
        sortBy: DocumentSearchSortOption = .relevance
    ) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            // Add to recent searches
            addToRecentSearches(query)
            
            // Perform multi-strategy search
            let results = await performMultiStrategySearch(query: query, filters: filters)
            
            // Sort results
            let sortedResults = sortSearchResults(results, by: sortBy)
            
            // Update UI
            searchResults = sortedResults
            
            // Generate suggestions for next searches
            generateSearchSuggestions(from: query)
            
        } catch {
            print("❌ Search failed: \(error)")
            searchResults = []
        }
        
        isSearching = false
    }
    
    /// Performs advanced full-text search with natural language processing
    private func performMultiStrategySearch(
        query: String,
        filters: DocumentSearchFilters
    ) async -> [DocumentSearchResult] {
        
        var allResults: [DocumentSearchResult] = []
        
        // Strategy 1: Exact title/filename match (highest priority)
        let exactMatches = await performExactSearch(query: query, filters: filters)
        allResults.append(contentsOf: exactMatches)
        
        // Strategy 2: Full-text content search
        let contentMatches = await performContentSearch(query: query, filters: filters)
        allResults.append(contentsOf: contentMatches)
        
        // Strategy 3: Tag and metadata search
        let tagMatches = await performTagSearch(query: query, filters: filters)
        allResults.append(contentsOf: tagMatches)
        
        // Strategy 4: Semantic/fuzzy search
        let semanticMatches = await performSemanticSearch(query: query, filters: filters)
        allResults.append(contentsOf: semanticMatches)
        
        // Deduplicate and merge results
        return deduplicateResults(allResults)
    }
    
    // MARK: - Search Strategies
    
    private func performExactSearch(
        query: String,
        filters: DocumentSearchFilters
    ) async -> [DocumentSearchResult] {
        
        let predicate = buildSearchPredicate(
            titleQuery: query,
            filenameQuery: query,
            filters: filters,
            exactMatch: true
        )
        
        return await executeCloudKitSearch(predicate: predicate, searchType: .exact)
    }
    
    private func performContentSearch(
        query: String,
        filters: DocumentSearchFilters
    ) async -> [DocumentSearchResult] {
        
        let predicate = buildSearchPredicate(
            contentQuery: query,
            filters: filters,
            exactMatch: false
        )
        
        return await executeCloudKitSearch(predicate: predicate, searchType: .content)
    }
    
    private func performTagSearch(
        query: String,
        filters: DocumentSearchFilters
    ) async -> [DocumentSearchResult] {
        
        let predicate = buildSearchPredicate(
            tagQuery: query,
            filters: filters,
            exactMatch: false
        )
        
        return await executeCloudKitSearch(predicate: predicate, searchType: .tags)
    }
    
    private func performSemanticSearch(
        query: String,
        filters: DocumentSearchFilters
    ) async -> [DocumentSearchResult] {
        
        // Generate semantic variations of the query
        let semanticQueries = generateSemanticQueries(from: query)
        var results: [DocumentSearchResult] = []
        
        for semanticQuery in semanticQueries {
            let predicate = buildSearchPredicate(
                contentQuery: semanticQuery,
                filters: filters,
                exactMatch: false
            )
            
            let semanticResults = await executeCloudKitSearch(
                predicate: predicate,
                searchType: .semantic
            )
            results.append(contentsOf: semanticResults)
        }
        
        return results
    }
    
    // MARK: - CloudKit Search Execution
    
    private func executeCloudKitSearch(
        predicate: NSPredicate,
        searchType: DocumentSearchType
    ) async -> [DocumentSearchResult] {
        
        do {
            let query = CKQuery(recordType: DocumentModel.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
            
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = maxSearchResults
            
            var results: [DocumentSearchResult] = []
            
            return await withCheckedContinuation { continuation in
                operation.recordMatchedBlock = { recordID, result in
                    switch result {
                    case .success(let record):
                        do {
                            let document = try DocumentModel.fromCKRecord(record)
                            let searchResult = DocumentSearchResult(
                                document: document,
                                searchType: searchType,
                                relevanceScore: self.calculateRelevanceScore(
                                    document: document,
                                    searchType: searchType
                                ),
                                matchedFields: self.identifyMatchedFields(
                                    document: document,
                                    searchType: searchType
                                )
                            )
                            results.append(searchResult)
                        } catch {
                            print("❌ Failed to parse search result: \(error)")
                        }
                    case .failure(let error):
                        print("❌ Failed to fetch search result: \(error)")
                    }
                }
                
                operation.queryResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: results)
                    case .failure(let error):
                        print("❌ Search query failed: \(error)")
                        continuation.resume(returning: [])
                    }
                }
                
                privateDatabase.add(operation)
            }
            
        } catch {
            print("❌ Search execution failed: \(error)")
            return []
        }
    }
    
    // MARK: - Search Predicate Building
    
    private func buildSearchPredicate(
        titleQuery: String? = nil,
        filenameQuery: String? = nil,
        contentQuery: String? = nil,
        tagQuery: String? = nil,
        filters: DocumentSearchFilters,
        exactMatch: Bool = false
    ) -> NSPredicate {
        
        var predicates: [NSPredicate] = []
        
        // Base filter: only active documents
        predicates.append(NSPredicate(format: "status == %@", DocumentStatus.active.rawValue))
        
        // Search query predicates
        if let titleQuery = titleQuery {
            let titlePredicate = exactMatch ?
                NSPredicate(format: "title == %@", titleQuery) :
                NSPredicate(format: "title CONTAINS[cd] %@", titleQuery)
            predicates.append(titlePredicate)
        }
        
        if let filenameQuery = filenameQuery {
            let filenamePredicate = exactMatch ?
                NSPredicate(format: "fileName == %@", filenameQuery) :
                NSPredicate(format: "fileName CONTAINS[cd] %@", filenameQuery)
            predicates.append(filenamePredicate)
        }
        
        if let contentQuery = contentQuery {
            let contentPredicate = NSPredicate(
                format: "searchableContent CONTAINS[cd] %@",
                contentQuery
            )
            predicates.append(contentPredicate)
        }
        
        if let tagQuery = tagQuery {
            let tagPredicate = NSPredicate(format: "tags CONTAINS[cd] %@", tagQuery)
            predicates.append(tagPredicate)
        }
        
        // Apply filters
        if let category = filters.category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        
        if let accessLevel = filters.accessLevel {
            predicates.append(NSPredicate(format: "accessLevel == %@", accessLevel.rawValue))
        }
        
        if let fileType = filters.fileType {
            predicates.append(NSPredicate(format: "fileType == %@", fileType.rawValue))
        }
        
        if let dateRange = filters.dateRange {
            predicates.append(NSPredicate(
                format: "modifiedAt >= %@ AND modifiedAt <= %@",
                dateRange.start as NSDate,
                dateRange.end as NSDate
            ))
        }
        
        if let sizeRange = filters.sizeRange {
            predicates.append(NSPredicate(
                format: "fileSize >= %@ AND fileSize <= %@",
                NSNumber(value: sizeRange.min),
                NSNumber(value: sizeRange.max)
            ))
        }
        
        // Combine all predicates with OR for search terms, AND for filters
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    // MARK: - Natural Language Processing
    
    private func generateSemanticQueries(from query: String) -> [String] {
        var semanticQueries: [String] = []
        
        // Language detection
        nlProcessor.processString(query)
        let language = nlProcessor.dominantLanguage
        
        // Generate synonyms and related terms
        let tagger = NLTagger(tagSchemes: [.lemma, .nameType])
        tagger.string = query
        
        tagger.enumerateTags(in: query.startIndex..<query.endIndex, unit: .word, scheme: .lemma) { tag, tokenRange in
            if let lemma = tag?.rawValue {
                semanticQueries.append(lemma)
                
                // Add common business document terms
                let businessSynonyms = generateBusinessSynonyms(for: lemma)
                semanticQueries.append(contentsOf: businessSynonyms)
            }
            return true
        }
        
        return Array(Set(semanticQueries)).filter { !$0.isEmpty }
    }
    
    private func generateBusinessSynonyms(for term: String) -> [String] {
        let synonymsMap: [String: [String]] = [
            "contract": ["agreement", "deal", "terms", "legal"],
            "invoice": ["bill", "payment", "receipt", "financial"],
            "report": ["analysis", "summary", "document", "findings"],
            "proposal": ["plan", "suggestion", "offer", "bid"],
            "presentation": ["slides", "demo", "pitch", "display"],
            "manual": ["guide", "handbook", "instructions", "documentation"],
            "policy": ["procedure", "rules", "guidelines", "standards"],
            "schedule": ["timeline", "calendar", "agenda", "plan"],
            "budget": ["financial", "cost", "expense", "money"],
            "employee": ["staff", "personnel", "worker", "team"]
        ]
        
        return synonymsMap[term.lowercased()] ?? []
    }
    
    // MARK: - Relevance Scoring
    
    private func calculateRelevanceScore(
        document: DocumentModel,
        searchType: DocumentSearchType
    ) -> Double {
        var score: Double = 0.0
        
        // Base score by search type
        switch searchType {
        case .exact:
            score = 100.0
        case .content:
            score = 75.0
        case .tags:
            score = 60.0
        case .semantic:
            score = 40.0
        }
        
        // Boost score based on document properties
        
        // Recent documents get higher scores
        let daysSinceModified = Calendar.current.dateComponents([.day], from: document.modifiedAt, to: Date()).day ?? 0
        if daysSinceModified <= 7 {
            score += 10.0
        } else if daysSinceModified <= 30 {
            score += 5.0
        }
        
        // Frequently accessed documents get higher scores
        if document.lastAccessedAt != nil {
            score += 5.0
        }
        
        // Important categories get priority
        switch document.category {
        case .legal, .financial:
            score += 15.0
        case .hr, .operations:
            score += 10.0
        default:
            score += 5.0
        }
        
        // Access level consideration
        switch document.accessLevel {
        case .public, .internal:
            score += 5.0
        default:
            break // No bonus for restricted documents
        }
        
        return min(score, 100.0) // Cap at 100
    }
    
    private func identifyMatchedFields(
        document: DocumentModel,
        searchType: DocumentSearchType
    ) -> [DocumentSearchMatchField] {
        var matchedFields: [DocumentSearchMatchField] = []
        
        switch searchType {
        case .exact:
            matchedFields.append(.title)
            matchedFields.append(.fileName)
        case .content:
            matchedFields.append(.content)
            matchedFields.append(.description)
        case .tags:
            matchedFields.append(.tags)
        case .semantic:
            matchedFields.append(.content)
        }
        
        return matchedFields
    }
    
    // MARK: - Result Processing
    
    private func deduplicateResults(_ results: [DocumentSearchResult]) -> [DocumentSearchResult] {
        var uniqueResults: [String: DocumentSearchResult] = [:]
        
        for result in results {
            let documentId = result.document.id.uuidString
            
            if let existingResult = uniqueResults[documentId] {
                // Keep the result with higher relevance score
                if result.relevanceScore > existingResult.relevanceScore {
                    uniqueResults[documentId] = result
                }
            } else {
                uniqueResults[documentId] = result
            }
        }
        
        return Array(uniqueResults.values)
    }
    
    private func sortSearchResults(
        _ results: [DocumentSearchResult],
        by sortOption: DocumentSearchSortOption
    ) -> [DocumentSearchResult] {
        
        return results.sorted { result1, result2 in
            switch sortOption {
            case .relevance:
                return result1.relevanceScore > result2.relevanceScore
            case .dateModified:
                return result1.document.modifiedAt > result2.document.modifiedAt
            case .dateCreated:
                return result1.document.createdAt > result2.document.createdAt
            case .title:
                return result1.document.title < result2.document.title
            case .fileSize:
                return result1.document.fileSize > result2.document.fileSize
            }
        }
    }
    
    // MARK: - Search Suggestions
    
    private func generateSearchSuggestions(from query: String) {
        let suggestions = searchIndex.generateSuggestions(for: query)
        searchSuggestions = Array(suggestions.prefix(10))
    }
    
    func getSearchSuggestions(for partialQuery: String) -> [String] {
        return searchIndex.generateSuggestions(for: partialQuery)
    }
    
    // MARK: - Recent Searches Management
    
    private func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
        
        // Add to beginning
        recentSearches.insert(trimmedQuery, at: 0)
        
        // Limit size
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "DocumentRecentSearches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "DocumentRecentSearches")
        }
    }
    
    private func loadPopularTags() {
        // Load from analytics and document usage statistics
        Task {
            // Get all documents and count tag frequency
            let allDocuments = await DocumentService.shared.getAllDocuments()
            let tagFrequency = Dictionary(
                allDocuments
                    .flatMap { $0.tags }
                    .map { ($0, 1) },
                uniquingKeysWith: +
            )
            
            // Sort by frequency and take top tags
            let sortedTags = tagFrequency
                .sorted { $0.value > $1.value }
                .prefix(10)
                .map { $0.key }
            
            await MainActor.run {
                popularTags = Array(sortedTags)
            }
        }
    }
    
    // MARK: - Search Index Management
    
    func indexDocument(_ document: DocumentModel) {
        searchIndex.addDocument(document)
    }
    
    func removeDocumentFromIndex(_ documentId: UUID) {
        searchIndex.removeDocument(documentId)
    }
    
    func updateDocumentIndex(_ document: DocumentModel) {
        searchIndex.updateDocument(document)
    }
    
    func rebuildSearchIndex() async {
        await searchIndex.rebuildIndex()
    }
    
    // MARK: - Cleanup
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    func clearSearchResults() {
        searchResults.removeAll()
        searchSuggestions.removeAll()
    }
}

// MARK: - Supporting Models

struct DocumentSearchResult: Identifiable, Hashable {
    let id = UUID()
    let document: DocumentModel
    let searchType: DocumentSearchType
    let relevanceScore: Double
    let matchedFields: [DocumentSearchMatchField]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(document.id)
        hasher.combine(searchType)
    }
    
    static func == (lhs: DocumentSearchResult, rhs: DocumentSearchResult) -> Bool {
        lhs.document.id == rhs.document.id && lhs.searchType == rhs.searchType
    }
}

enum DocumentSearchType: String, CaseIterable {
    case exact = "exact"
    case content = "content"
    case tags = "tags"
    case semantic = "semantic"
    
    var displayName: String {
        switch self {
        case .exact: return "Exact Match"
        case .content: return "Content Match"
        case .tags: return "Tag Match"
        case .semantic: return "Related Content"
        }
    }
    
    var priority: Int {
        switch self {
        case .exact: return 4
        case .content: return 3
        case .tags: return 2
        case .semantic: return 1
        }
    }
}

enum DocumentSearchMatchField: String, CaseIterable {
    case title = "title"
    case fileName = "fileName"
    case content = "content"
    case description = "description"
    case tags = "tags"
    
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .fileName: return "File Name"
        case .content: return "Content"
        case .description: return "Description"
        case .tags: return "Tags"
        }
    }
}

struct DocumentSearchFilters {
    var category: DocumentCategory?
    var accessLevel: DocumentAccessLevel?
    var fileType: DocumentFileType?
    var dateRange: DateRange?
    var sizeRange: SizeRange?
    var owner: String?
    var tags: [String] = []
    
    struct DateRange {
        let start: Date
        let end: Date
    }
    
    struct SizeRange {
        let min: Int64
        let max: Int64
    }
}

enum DocumentSearchSortOption: String, CaseIterable {
    case relevance = "relevance"
    case dateModified = "dateModified"
    case dateCreated = "dateCreated"
    case title = "title"
    case fileSize = "fileSize"
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .dateModified: return "Date Modified"
        case .dateCreated: return "Date Created"
        case .title: return "Title"
        case .fileSize: return "File Size"
        }
    }
}

// MARK: - Document Search Index

private class DocumentSearchIndex {
    private var documentIndex: [UUID: DocumentIndexEntry] = [:]
    private var termIndex: [String: Set<UUID>] = [:]
    private let indexQueue = DispatchQueue(label: "com.diamonddesk.search.index", qos: .utility)
    
    private struct DocumentIndexEntry {
        let document: DocumentModel
        let indexedTerms: Set<String>
        let indexedAt: Date
    }
    
    func addDocument(_ document: DocumentModel) {
        indexQueue.async {
            let terms = self.extractSearchTerms(from: document)
            let entry = DocumentIndexEntry(
                document: document,
                indexedTerms: terms,
                indexedAt: Date()
            )
            
            self.documentIndex[document.id] = entry
            
            // Update term index
            for term in terms {
                if self.termIndex[term] != nil {
                    self.termIndex[term]?.insert(document.id)
                } else {
                    self.termIndex[term] = Set([document.id])
                }
            }
        }
    }
    
    func removeDocument(_ documentId: UUID) {
        indexQueue.async {
            guard let entry = self.documentIndex[documentId] else { return }
            
            // Remove from term index
            for term in entry.indexedTerms {
                self.termIndex[term]?.remove(documentId)
                if self.termIndex[term]?.isEmpty == true {
                    self.termIndex[term] = nil
                }
            }
            
            // Remove from document index
            self.documentIndex[documentId] = nil
        }
    }
    
    func updateDocument(_ document: DocumentModel) {
        removeDocument(document.id)
        addDocument(document)
    }
    
    func generateSuggestions(for query: String) -> [String] {
        return indexQueue.sync {
            let lowercaseQuery = query.lowercased()
            return termIndex.keys
                .filter { $0.hasPrefix(lowercaseQuery) }
                .sorted()
                .map { $0 }
        }
    }
    
    func rebuildIndex() async {
        // This would be called to rebuild the entire search index
        // Implementation would fetch all documents and reindex them
    }
    
    private func extractSearchTerms(from document: DocumentModel) -> Set<String> {
        var terms: Set<String> = []
        
        // Extract from title
        terms.formUnion(tokenize(document.title))
        
        // Extract from filename
        terms.formUnion(tokenize(document.fileName))
        
        // Extract from description
        if let description = document.description {
            terms.formUnion(tokenize(description))
        }
        
        // Extract from tags
        for tag in document.tags {
            terms.formUnion(tokenize(tag))
        }
        
        // Extract from searchable content
        terms.formUnion(tokenize(document.searchableContent))
        
        // Add category and other metadata as terms
        terms.insert(document.category.rawValue.lowercased())
        terms.insert(document.fileType.rawValue.lowercased())
        terms.insert(document.accessLevel.rawValue.lowercased())
        
        return terms
    }
    
    private func tokenize(_ text: String) -> Set<String> {
        let lowercaseText = text.lowercased()
        let words = lowercaseText.components(separatedBy: .whitespacesAndNewlines)
        
        var terms: Set<String> = []
        
        for word in words {
            let cleanedWord = word.components(separatedBy: .punctuationCharacters).joined()
            if cleanedWord.count >= 2 { // Minimum term length
                terms.insert(cleanedWord)
            }
        }
        
        return terms
    }
}
