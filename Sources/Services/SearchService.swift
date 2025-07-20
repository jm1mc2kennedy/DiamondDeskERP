import Foundation
import CloudKit
import Combine

@MainActor
class SearchService: ObservableObject {
    @Published var searchResults: SearchResults = SearchResults()
    @Published var isSearching = false
    @Published var searchHistory: [String] = []
    @Published var recentSearches: [SearchQuery] = []
    
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryItems = 20
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
        loadSearchHistory()
    }
    
    // MARK: - Universal Search
    
    func search(query: String, filters: SearchFilters = SearchFilters()) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = SearchResults()
            return
        }
        
        isSearching = true
        saveToHistory(query)
        
        do {
            async let taskResults = searchTasks(query: query, filters: filters)
            async let ticketResults = searchTickets(query: query, filters: filters)
            async let clientResults = searchClients(query: query, filters: filters)
            async let documentResults = searchDocuments(query: query, filters: filters)
            
            let (tasks, tickets, clients, documents) = await (
                try taskResults,
                try ticketResults,
                try clientResults,
                try documentResults
            )
            
            searchResults = SearchResults(
                tasks: tasks,
                tickets: tickets,
                clients: clients,
                documents: documents,
                query: query,
                totalResults: tasks.count + tickets.count + clients.count + documents.count
            )
            
        } catch {
            print("Search failed: \(error)")
            searchResults = SearchResults()
        }
        
        isSearching = false
    }
    
    // MARK: - Entity-Specific Search
    
    private func searchTasks(query: String, filters: SearchFilters) async throws -> [TaskModel] {
        var predicates: [NSPredicate] = []
        
        // Text search
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let descriptionPredicate = NSPredicate(format: "description CONTAINS[cd] %@", query)
        let textPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, descriptionPredicate])
        predicates.append(textPredicate)
        
        // Apply filters
        if let status = filters.taskStatus {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }
        
        if let priority = filters.taskPriority {
            predicates.append(NSPredicate(format: "priority == %@", priority.rawValue))
        }
        
        if let category = filters.category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if !filters.tags.isEmpty {
            let tagPredicates = filters.tags.map { NSPredicate(format: "tags CONTAINS %@", $0) }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates))
        }
        
        if let assignee = filters.assignedTo {
            predicates.append(NSPredicate(format: "assignee.id == %@", assignee))
        }
        
        if let dateRange = filters.dateRange {
            predicates.append(NSPredicate(format: "dueDate >= %@ AND dueDate <= %@", 
                                        dateRange.start as CVarArg, dateRange.end as CVarArg))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let ckQuery = CKQuery(recordType: "Task", predicate: compoundPredicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        
        let records = try await database.records(matching: ckQuery)
        return records.matchResults.compactMap { result in
            switch result.1 {
            case .success(let record):
                return TaskModel(record: record)
            case .failure(_):
                return nil
            }
        }
    }
    
    private func searchTickets(query: String, filters: SearchFilters) async throws -> [TicketModel] {
        var predicates: [NSPredicate] = []
        
        // Text search
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let descriptionPredicate = NSPredicate(format: "description CONTAINS[cd] %@", query)
        let textPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, descriptionPredicate])
        predicates.append(textPredicate)
        
        // Apply filters
        if let status = filters.ticketStatus {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }
        
        if let priority = filters.ticketPriority {
            predicates.append(NSPredicate(format: "priority == %@", priority.rawValue))
        }
        
        if let category = filters.category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if let assignee = filters.assignedTo {
            predicates.append(NSPredicate(format: "assignee.id == %@", assignee))
        }
        
        if let dateRange = filters.dateRange {
            predicates.append(NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                        dateRange.start as CVarArg, dateRange.end as CVarArg))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let ckQuery = CKQuery(recordType: "Ticket", predicate: compoundPredicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let records = try await database.records(matching: ckQuery)
        return records.matchResults.compactMap { result in
            switch result.1 {
            case .success(let record):
                return TicketModel(record: record)
            case .failure(_):
                return nil
            }
        }
    }
    
    private func searchClients(query: String, filters: SearchFilters) async throws -> [ClientModel] {
        var predicates: [NSPredicate] = []
        
        // Text search across multiple fields
        let firstNamePredicate = NSPredicate(format: "firstName CONTAINS[cd] %@", query)
        let lastNamePredicate = NSPredicate(format: "lastName CONTAINS[cd] %@", query)
        let emailPredicate = NSPredicate(format: "email CONTAINS[cd] %@", query)
        let phonePredicate = NSPredicate(format: "phone CONTAINS[cd] %@", query)
        let textPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            firstNamePredicate, lastNamePredicate, emailPredicate, phonePredicate
        ])
        predicates.append(textPredicate)
        
        // Apply filters
        if !filters.tags.isEmpty {
            let tagPredicates = filters.tags.map { NSPredicate(format: "tags CONTAINS %@", $0) }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates))
        }
        
        if let assignee = filters.assignedTo {
            predicates.append(NSPredicate(format: "assignedUserId == %@", assignee))
        }
        
        if let dateRange = filters.dateRange {
            predicates.append(NSPredicate(format: "nextReminderAt >= %@ AND nextReminderAt <= %@", 
                                        dateRange.start as CVarArg, dateRange.end as CVarArg))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let ckQuery = CKQuery(recordType: "Client", predicate: compoundPredicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        let records = try await database.records(matching: ckQuery)
        return records.matchResults.compactMap { result in
            switch result.1 {
            case .success(let record):
                return ClientModel(record: record)
            case .failure(_):
                return nil
            }
        }
    }
    
    private func searchDocuments(query: String, filters: SearchFilters) async throws -> [Document] {
        var predicates: [NSPredicate] = []
        
        // Text search
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let descriptionPredicate = NSPredicate(format: "description CONTAINS[cd] %@", query)
        let textPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, descriptionPredicate])
        predicates.append(textPredicate)
        
        // Only active documents
        predicates.append(NSPredicate(format: "isActive == %@", NSNumber(value: true)))
        
        // Apply filters
        if let category = filters.category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if !filters.tags.isEmpty {
            let tagPredicates = filters.tags.map { NSPredicate(format: "tags CONTAINS %@", $0) }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let ckQuery = CKQuery(recordType: "Document", predicate: compoundPredicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        let records = try await database.records(matching: ckQuery)
        return records.matchResults.compactMap { result in
            switch result.1 {
            case .success(let record):
                return Document(record: record)
            case .failure(_):
                return nil
            }
        }
    }
    
    // MARK: - Advanced Filtering
    
    func filterTasks(with filters: TaskFilters) async -> [TaskModel] {
        var predicates: [NSPredicate] = []
        
        // Status filter
        if !filters.statuses.isEmpty {
            let statusStrings = filters.statuses.map { $0.rawValue }
            predicates.append(NSPredicate(format: "status IN %@", statusStrings))
        }
        
        // Priority filter
        if !filters.priorities.isEmpty {
            let priorityStrings = filters.priorities.map { $0.rawValue }
            predicates.append(NSPredicate(format: "priority IN %@", priorityStrings))
        }
        
        // Category filter
        if !filters.categories.isEmpty {
            predicates.append(NSPredicate(format: "category IN %@", filters.categories))
        }
        
        // Assignment filter
        switch filters.assignmentFilter {
        case .assignedToMe:
            predicates.append(NSPredicate(format: "assignee.id == %@", getCurrentUserId()))
        case .assignedToOthers:
            predicates.append(NSPredicate(format: "assignee.id != %@ AND assignee.id != nil", getCurrentUserId()))
        case .unassigned:
            predicates.append(NSPredicate(format: "assignee == nil"))
        case .all:
            break
        }
        
        // Date range filter
        if let dateRange = filters.dateRange {
            predicates.append(NSPredicate(format: "dueDate >= %@ AND dueDate <= %@", 
                                        dateRange.start as CVarArg, dateRange.end as CVarArg))
        }
        
        // Overdue filter
        if filters.showOverdueOnly {
            predicates.append(NSPredicate(format: "dueDate < %@ AND status != %@", 
                                        Date() as CVarArg, TaskStatus.completed.rawValue))
        }
        
        // Tags filter
        if !filters.tags.isEmpty {
            let tagPredicates = filters.tags.map { NSPredicate(format: "tags CONTAINS %@", $0) }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let ckQuery = CKQuery(recordType: "Task", predicate: compoundPredicate)
        
        // Apply sorting
        switch filters.sortBy {
        case .dueDate:
            ckQuery.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: filters.sortOrder == .ascending)]
        case .priority:
            ckQuery.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: filters.sortOrder == .ascending)]
        case .title:
            ckQuery.sortDescriptors = [NSSortDescriptor(key: "title", ascending: filters.sortOrder == .ascending)]
        case .created:
            ckQuery.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: filters.sortOrder == .ascending)]
        }
        
        do {
            let records = try await database.records(matching: ckQuery)
            return records.matchResults.compactMap { result in
                switch result.1 {
                case .success(let record):
                    return TaskModel(record: record)
                case .failure(_):
                    return nil
                }
            }
        } catch {
            print("Failed to filter tasks: \(error)")
            return []
        }
    }
    
    // MARK: - Search History Management
    
    private func saveToHistory(_ query: String) {
        guard !query.isEmpty else { return }
        
        // Remove if already exists
        searchHistory.removeAll { $0 == query }
        
        // Add to beginning
        searchHistory.insert(query, at: 0)
        
        // Keep only max items
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }
        
        saveSearchHistory()
        
        // Save as recent search with timestamp
        let searchQuery = SearchQuery(
            id: UUID().uuidString,
            query: query,
            timestamp: Date(),
            resultCount: searchResults.totalResults
        )
        
        recentSearches.removeAll { $0.query == query }
        recentSearches.insert(searchQuery, at: 0)
        
        if recentSearches.count > maxHistoryItems {
            recentSearches = Array(recentSearches.prefix(maxHistoryItems))
        }
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "searchHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = history
        }
        
        if let data = UserDefaults.standard.data(forKey: "recentSearches"),
           let recent = try? JSONDecoder().decode([SearchQuery].self, from: data) {
            recentSearches = recent
        }
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "searchHistory")
        }
        
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "recentSearches")
        }
    }
    
    func clearSearchHistory() {
        searchHistory.removeAll()
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: "searchHistory")
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? ""
    }
}

// MARK: - Search Models

struct SearchResults {
    var tasks: [TaskModel] = []
    var tickets: [TicketModel] = []
    var clients: [ClientModel] = []
    var documents: [Document] = []
    var query: String = ""
    var totalResults: Int = 0
    
    var isEmpty: Bool {
        return totalResults == 0
    }
}

struct SearchFilters {
    var taskStatus: TaskStatus?
    var ticketStatus: TicketStatus?
    var taskPriority: TaskPriority?
    var ticketPriority: TicketPriority?
    var category: String?
    var tags: [String] = []
    var assignedTo: String?
    var dateRange: DateRange?
}

struct TaskFilters {
    var statuses: [TaskStatus] = []
    var priorities: [TaskPriority] = []
    var categories: [String] = []
    var assignmentFilter: AssignmentFilter = .all
    var dateRange: DateRange?
    var showOverdueOnly = false
    var tags: [String] = []
    var sortBy: TaskSortOption = .dueDate
    var sortOrder: SortOrder = .ascending
}

struct DateRange {
    let start: Date
    let end: Date
}

enum AssignmentFilter {
    case all
    case assignedToMe
    case assignedToOthers
    case unassigned
}

enum TaskSortOption {
    case dueDate
    case priority
    case title
    case created
}

enum SortOrder {
    case ascending
    case descending
}

struct SearchQuery: Identifiable, Codable {
    let id: String
    let query: String
    let timestamp: Date
    let resultCount: Int
}
