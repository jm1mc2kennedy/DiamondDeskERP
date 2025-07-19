// KPIListView.swift
// Diamond Desk ERP

import SwiftUI

struct KPIListView: View {
    @StateObject private var viewModel: KPIViewModel
    
    // --- Advanced Filtering & Search ---
    @State private var searchText: String = ""
    @State private var selectedMetric: String? = nil
    @State private var selectedDate: Date? = nil
    @State private var showFilters: Bool = false

    init(storeCode: String) {
        _viewModel = StateObject(wrappedValue: KPIViewModel(storeCode: storeCode))
    }

    var body: some View {
        NavigationView {
            List {
                // Filter KPIs based on searchText, selectedMetric, and selectedDate
                ForEach(filteredKPIs) { kpi in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Store: \(kpi.storeCode)")
                            .font(.headline)
                        Text("Date: \(kpi.date, formatter: itemFormatter)")
                            .font(.subheadline)
                        // Filter metrics by selectedMetric if set, else show all sorted metrics
                        ForEach(filteredMetrics(for: kpi).sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            Text("\(key): \(value, specifier: "%.2f")")
                                .font(.caption)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .accessibilityLabel("Search KPIs")
            .accessibilityHint("Search KPIs by metric name or value")
            .navigationTitle("KPIs")
            .refreshable {
                await viewModel.fetchKPIs()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            // Toolbar with Filters menu
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Metric picker
                        Picker("Metric", selection: $selectedMetric) {
                            Text("All").tag(String?.none)
                            ForEach(allMetricKeys, id: \.self) { metric in
                                Text(metric).tag(String?.some(metric))
                            }
                        }
                        .accessibilityLabel("Filter by metric")
                        .accessibilityHint("Select a metric to filter the KPI list")

                        // Date picker (single date)
                        DatePicker(
                            "Select Date",
                            selection: Binding(
                                get: { selectedDate ?? Date() },
                                set: { newDate in
                                    // If selecting date same as current, clear filter
                                    if let oldDate = selectedDate, Calendar.current.isDate(oldDate, inSameDayAs: newDate) {
                                        selectedDate = nil
                                    } else {
                                        selectedDate = newDate
                                    }
                                }),
                            displayedComponents: [.date]
                        )
                        .accessibilityLabel("Filter by date")
                        .accessibilityHint("Select a date to filter KPIs")

                        // Clear filters button
                        Button("Clear Filters") {
                            selectedMetric = nil
                            selectedDate = nil
                            searchText = ""
                        }
                        .accessibilityLabel("Clear filters")
                        .accessibilityHint("Clear all search and filter selections")
                    } label: {
                        Label("Filters", systemImage: "line.horizontal.3.decrease.circle")
                            .background(
                                // Background with ultraThinMaterial and rounded corners, fallback for accessibility
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemUltraThinMaterial))
                                    .opacity(UIAccessibility.isReduceTransparencyEnabled ? 0 : 1)
                            )
                    }
                    .accessibilityLabel("Filters menu")
                    .accessibilityHint("Open filters menu to refine KPI list")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    // All unique metric keys across all KPIs
    private var allMetricKeys: [String] {
        let keys = viewModel.kpis.flatMap { $0.metrics.keys }
        return Array(Set(keys)).sorted()
    }
    
    // Filter KPIs by searchText, selectedMetric, selectedDate
    private var filteredKPIs: [KPI] {
        viewModel.kpis.filter { kpi in
            // Filter by selectedDate if set
            if let selectedDate = selectedDate {
                if !Calendar.current.isDate(kpi.date, inSameDayAs: selectedDate) {
                    return false
                }
            }
            // Filter by selectedMetric if set
            if let selectedMetric = selectedMetric {
                guard kpi.metrics.keys.contains(selectedMetric) else { return false }
            }
            // Filter by searchText: check if searchText is in any metric key or value string
            if !searchText.isEmpty {
                let lowerSearch = searchText.lowercased()
                let matchesMetric = kpi.metrics.contains { key, value in
                    key.lowercased().contains(lowerSearch) || String(format: "%.2f", value).contains(lowerSearch)
                }
                if !matchesMetric {
                    return false
                }
            }
            return true
        }
    }
    
    // Filter metrics for a specific KPI by selectedMetric if set
    private func filteredMetrics(for kpi: KPI) -> [String: Double] {
        if let selectedMetric = selectedMetric {
            if let value = kpi.metrics[selectedMetric] {
                return [selectedMetric: value]
            } else {
                return [:]
            }
        } else {
            return kpi.metrics
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    KPIListView(storeCode: "demo-store")
}
