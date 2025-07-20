//
//  DocumentFilterView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Document Filter View
/// Advanced filtering interface for document management
struct DocumentFilterView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                filterContent
            }
            .navigationTitle("Filter Documents")
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
    }
    
    // MARK: - Filter Content
    
    @ViewBuilder
    private var filterContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Actions
                quickActionsSection
                
                // Category Filter
                categoryFilterSection
                
                // Access Level Filter
                accessLevelFilterSection
                
                // Status Filter
                statusFilterSection
                
                // Sort Options
                sortOptionsSection
                
                // Filter Summary
                filterSummarySection
            }
            .padding()
        }
    }
    
    // MARK: - Quick Actions Section
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Clear All",
                    icon: "xmark.circle",
                    color: .red
                ) {
                    viewModel.clearFilters()
                }
                
                QuickActionButton(
                    title: "My Documents",
                    icon: "person.circle",
                    color: .blue
                ) {
                    Task {
                        _ = await viewModel.getMyDocuments()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Category Filter Section
    
    @ViewBuilder
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.selectedCategory != nil {
                    Button("Clear") {
                        viewModel.setCategoryFilter(nil)
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DocumentCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        count: viewModel.categoryCounts[category] ?? 0
                    ) {
                        if viewModel.selectedCategory == category {
                            viewModel.setCategoryFilter(nil)
                        } else {
                            viewModel.setCategoryFilter(category)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Access Level Filter Section
    
    @ViewBuilder
    private var accessLevelFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Access Level")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.selectedAccessLevel != nil {
                    Button("Clear") {
                        viewModel.setAccessLevelFilter(nil)
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(DocumentAccessLevel.allCases, id: \.self) { level in
                    AccessLevelFilterButton(
                        accessLevel: level,
                        isSelected: viewModel.selectedAccessLevel == level,
                        count: viewModel.accessLevelCounts[level] ?? 0
                    ) {
                        if viewModel.selectedAccessLevel == level {
                            viewModel.setAccessLevelFilter(nil)
                        } else {
                            viewModel.setAccessLevelFilter(level)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Status Filter Section
    
    @ViewBuilder
    private var statusFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Status", selection: $viewModel.selectedStatus) {
                ForEach(DocumentStatus.allCases, id: \.self) { status in
                    HStack {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                        Text(status.displayName)
                    }
                    .tag(status)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Sort Options Section
    
    @ViewBuilder
    private var sortOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sort By")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(DocumentSortOrder.allCases, id: \.self) { sortOrder in
                    SortOptionButton(
                        sortOrder: sortOrder,
                        isSelected: viewModel.sortOrder == sortOrder
                    ) {
                        viewModel.setSortOrder(sortOrder)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Filter Summary Section
    
    @ViewBuilder
    private var filterSummarySection: some View {
        if viewModel.activeFiltersCount > 0 {
            VStack(alignment: .leading, spacing: 16) {
                Text("Active Filters")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let category = viewModel.selectedCategory {
                        FilterChip(
                            text: "Category: \(category.displayName)",
                            color: category.color
                        ) {
                            viewModel.setCategoryFilter(nil)
                        }
                    }
                    
                    if let accessLevel = viewModel.selectedAccessLevel {
                        FilterChip(
                            text: "Access: \(accessLevel.displayName)",
                            color: accessLevel.color
                        ) {
                            viewModel.setAccessLevelFilter(nil)
                        }
                    }
                    
                    if !viewModel.searchText.isEmpty {
                        FilterChip(
                            text: "Search: \"\(viewModel.searchText)\"",
                            color: .blue
                        ) {
                            viewModel.searchText = ""
                        }
                    }
                    
                    if viewModel.selectedStatus != .active {
                        FilterChip(
                            text: "Status: \(viewModel.selectedStatus.displayName)",
                            color: viewModel.selectedStatus.color
                        ) {
                            viewModel.setStatusFilter(.active)
                        }
                    }
                }
                
                Text("\(viewModel.filteredDocuments.count) documents match your filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryFilterButton: View {
    let category: DocumentCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(isSelected ? .white : .secondary)
                    }
                }
                
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(isSelected ? category.color : Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : category.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AccessLevelFilterButton: View {
    let accessLevel: DocumentAccessLevel
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(accessLevel.color)
                    .frame(width: 12, height: 12)
                
                Text(accessLevel.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? accessLevel.color : Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SortOptionButton: View {
    let sortOrder: DocumentSortOrder
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: sortOrder.systemImage)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                
                Text(sortOrder.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(color)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Extensions

extension DocumentStatus {
    var color: Color {
        switch self {
        case .active:
            return .green
        case .archived:
            return .blue
        case .deleted:
            return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .archived:
            return "Archived"
        case .deleted:
            return "Deleted"
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentFilterView(viewModel: DocumentViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    DocumentFilterView(viewModel: DocumentViewModel())
        .preferredColorScheme(.dark)
}
