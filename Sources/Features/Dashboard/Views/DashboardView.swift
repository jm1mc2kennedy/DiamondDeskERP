// DashboardView.swift
// Diamond Desk ERP
// Advanced dashboard with KPIs and analytics

import SwiftUI

struct DashboardView: View {
    // For demo, use one store (could iterate stores for multi-store users)
    @State private var reports: [StoreReportModel] = []
    @State private var isLoading = true
    @State private var error: Error?
    var storeCode: String

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)").foregroundColor(.red)
                } else {
                    // KPI Cards
                    HStack(spacing: 12) {
                        KPICard(title: "Sales WTD", value: sales(for: .weekOfYear))
                        KPICard(title: "Sales MTD", value: sales(for: .month))
                        KPICard(title: "Sales YTD", value: sales(for: .year))
                    }
                    .padding(.horizontal)

                    // More KPI Cards (UPT, ADS, etc)
                    HStack(spacing: 12) {
                        KPICard(title: "UPT (MTD)", value: avg(\.upt, .month))
                        KPICard(title: "ADS (MTD)", value: avg(\.ads, .month))
                        KPICard(title: "GP% (MTD)", value: avg(\.gpPct, .month, percent: true))
                    }
                    .padding(.horizontal)

                    // Add charts/trends as needed
                    Spacer()
                }
            }
            .navigationTitle("Dashboard")
            .onAppear { loadReports() }
        }
    }
    // Aggregators for cards
    private func sales(for period: Calendar.Component) -> String {
        let total = AnalyticsService.shared.aggregateSales(reports, for: period)
        return "$\(total, specifier: "%.0f")"
    }
    private func avg(_ key: KeyPath<StoreReportModel, Double>, _ period: Calendar.Component, percent: Bool = false) -> String {
        let value = AnalyticsService.shared.averageKPI(reports, keyPath: key, for: period)
        return percent ? String(format: "%.1f%%", value * 100) : String(format: "%.2f", value)
    }
    private func loadReports() {
        isLoading = true
        Task {
            do {
                let repo = CloudKitStoreReportRepository()
                let allReports = try await repo.fetchForStore(storeCode, in: nil)
                DispatchQueue.main.async {
                    self.reports = allReports
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

// Simple KPI Card
private struct KPICard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).opacity(0.7)
            Text(value).font(.title2).fontWeight(.semibold)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }
}

#Preview {
    DashboardView(storeCode: "Store 01")
}
