//
//  AdvancedDocumentSearchView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Advanced Document Search View
/// Provides sophisticated search interface with filters, suggestions, and real-time results
struct AdvancedDocumentSearchView: View {
    
    // MARK: - Properties
    
    @StateObject private var searchService = DocumentSearchService.shared
    @StateObject private var documentViewModel = DocumentViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var searchQuery = ""
    @State private var showingFilters = false
    @State private var searchFilters = DocumentSearchFilters()
    @State private var sortOption: DocumentSearchSortOption = .relevance
    @State private var selectedResult: DocumentSearchResult?
    @State private var showingDocumentDetail = false
    
    // MARK: - Computed Properties
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    private var hasActiveFilters: Bool {
        searchFilters.category != nil ||
        searchFilters.accessLevel != nil ||
        searchFilters.fileType != nil ||
        searchFilters.dateRange != nil ||
        searchFilters.sizeRange != nil ||
        !searchFilters.tags.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Header
                searchHeaderSection
                
                // Search Results or Suggestions
                if searchQuery.isEmpty {
                    searchSuggestionsView
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .accentColor : .primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            AdvancedSearchFiltersView(
                filters: $searchFilters,
                sortOption: $sortOption
            )
        }
        .sheet(isPresented: $showingDocumentDetail) {
            if let result = selectedResult {
                DocumentDetailView(document: result.document, viewModel: documentViewModel)
            }
        }
        .onChange(of: searchQuery) { _ in
            performSearch()
        }
        .onChange(of: searchFilters) { _ in
            if !searchQuery.isEmpty {
                performSearch()
            }
        }
        .onChange(of: sortOption) { _ in
            if !searchQuery.isEmpty {
                performSearch()
            }
        }
    }
    
    // MARK: - Search Header Section
    
    @ViewBuilder
    private var searchHeaderSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search documents...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchService.clearSearchResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Search Status and Quick Filters
            HStack {
                if searchService.isSearching {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !searchQuery.isEmpty && !searchService.searchResults.isEmpty {
                    Text("\(searchService.searchResults.count) results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if hasActiveFilters {
                    Text("\(activeFiltersCount) filters")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                if !searchQuery.isEmpty {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(DocumentSearchSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Search Suggestions View
    
    @ViewBuilder
    private var searchSuggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !searchService.recentSearches.isEmpty {
                    recentSearchesSection
                }
                
                // Popular Tags
                if !searchService.popularTags.isEmpty {
                    popularTagsSection
                }
                
                // Search Tips
                searchTipsSection
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Clear") {
                    searchService.clearRecentSearches()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(searchService.recentSearches.prefix(8), id: \.self) { search in
                    Button {
                        searchQuery = search
                        performSearch()
                    } label: {
                        Text(search)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private var popularTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Tags")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(searchService.popularTags, id: \.self) { tag in
                    Button {
                        searchQuery = tag
                        performSearch()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                            Text(tag)
                                .font(.subheadline)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Tips")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                SearchTipRow(
                    icon: "magnifyingglass",
                    tip: "Use quotes for exact phrases",
                    example: "\"quarterly report\""
                )
                
                SearchTipRow(
                    icon: "tag",
                    tip: "Search by tags",
                    example: "tag:financial"
                )
                
                SearchTipRow(
                    icon: "calendar",
                    tip: "Filter by date ranges",
                    example: "Use filters for specific dates"
                )
                
                SearchTipRow(
                    icon: "person",
                    tip: "Find documents by owner",
                    example: "owner:john.doe"
                )
            }
        }
    }
    
    // MARK: - Search Results View
    
    @ViewBuilder
    private var searchResultsView: some View {
        if searchService.searchResults.isEmpty && !searchService.isSearching {
            emptyResultsView
        } else {
            List(searchService.searchResults) { result in
                SearchResultRow(result: result) {
                    selectedResult = result
                    showingDocumentDetail = true
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .refreshable {
                performSearch()
            }
        }
    }
    
    @ViewBuilder
    private var emptyResultsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title2.weight(.semibold))
                
                Text("Try adjusting your search terms or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Clear Filters") {
                    clearAllFilters()
                }
                .disabled(!hasActiveFilters)
                
                Button("Browse All Documents") {
                    // Navigate to document list
                    dismiss()
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Properties
    
    private var activeFiltersCount: Int {
        var count = 0
        if searchFilters.category != nil { count += 1 }
        if searchFilters.accessLevel != nil { count += 1 }
        if searchFilters.fileType != nil { count += 1 }
        if searchFilters.dateRange != nil { count += 1 }
        if searchFilters.sizeRange != nil { count += 1 }
        if !searchFilters.tags.isEmpty { count += 1 }
        return count
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchService.clearSearchResults()
            return
        }
        
        Task {
            await searchService.searchDocuments(
                query: searchQuery,
                filters: searchFilters,
                sortBy: sortOption
            )
        }
    }
    
    private func clearAllFilters() {
        searchFilters = DocumentSearchFilters()
        if !searchQuery.isEmpty {
            performSearch()
        }
    }
}

// MARK: - Supporting Views

struct SearchTipRow: View {
    let icon: String
    let tip: String
    let example: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(example)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SearchResultRow: View {
    let result: DocumentSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Document Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(result.document.fileType.color.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: result.document.fileType.systemImage)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(result.document.fileType.color)
                    }
                    
                    // Document Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.document.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(result.document.fileName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            // Search match type
                            Text(result.searchType.displayName)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                            
                            // Relevance score
                            Text("\(Int(result.relevanceScore))% match")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Modified date
                            Text(result.document.modifiedAt.formatted(.relative(presentation: .numeric)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Access level indicator
                    Circle()
                        .fill(result.document.accessLevel.color)
                        .frame(width: 8, height: 8)
                }
                
                // Matched fields
                if !result.matchedFields.isEmpty {
                    HStack {
                        Text("Matches in:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(result.matchedFields, id: \.self) { field in
                            Text(field.displayName)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Advanced Search Filters View

struct AdvancedSearchFiltersView: View {
    @Binding var filters: DocumentSearchFilters
    @Binding var sortOption: DocumentSearchSortOption
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDatePicker = false
    @State private var showingSizePicker = false
    @State private var customTags = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Category Filter
                Section("Category") {
                    Picker("Category", selection: $filters.category) {
                        Text("All Categories").tag(nil as DocumentCategory?)
                        ForEach(DocumentCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category as DocumentCategory?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Access Level Filter
                Section("Access Level") {
                    Picker("Access Level", selection: $filters.accessLevel) {
                        Text("All Access Levels").tag(nil as DocumentAccessLevel?)
                        ForEach(DocumentAccessLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as DocumentAccessLevel?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // File Type Filter
                Section("File Type") {
                    Picker("File Type", selection: $filters.fileType) {
                        Text("All File Types").tag(nil as DocumentFileType?)
                        ForEach(DocumentFileType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as DocumentFileType?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Date Range Filter
                Section("Date Range") {
                    Button {
                        showingDatePicker = true
                    } label: {
                        HStack {
                            Text("Modified Date")
                            Spacer()
                            if let dateRange = filters.dateRange {
                                Text("\(dateRange.start.formatted(.dateTime.month().day())) - \(dateRange.end.formatted(.dateTime.month().day()))")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Any Time")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // File Size Filter
                Section("File Size") {
                    Button {
                        showingSizePicker = true
                    } label: {
                        HStack {
                            Text("File Size")
                            Spacer()
                            if let sizeRange = filters.sizeRange {
                                Text("\(ByteCountFormatter.string(fromByteCount: sizeRange.min, countStyle: .file)) - \(ByteCountFormatter.string(fromByteCount: sizeRange.max, countStyle: .file))")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Any Size")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Tags Filter
                Section("Tags") {
                    TextField("Enter tags (comma separated)", text: $customTags)
                        .onChange(of: customTags) { newValue in
                            filters.tags = newValue
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                        }
                }
                
                // Sort Options
                Section("Sort Results By") {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(DocumentSearchSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Actions
                Section {
                    Button("Clear All Filters") {
                        clearAllFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Initialize custom tags field
            customTags = filters.tags.joined(separator: ", ")
        }
    }
    
    private func clearAllFilters() {
        filters = DocumentSearchFilters()
        customTags = ""
        sortOption = .relevance
    }
}

// MARK: - Preview

#Preview {
    AdvancedDocumentSearchView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AdvancedDocumentSearchView()
        .preferredColorScheme(.dark)
}
