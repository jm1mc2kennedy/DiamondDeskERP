// StoreReportListView.swift
// Diamond Desk ERP

import SwiftUI

struct StoreReportListView: View {
    @StateObject private var viewModel: StoreReportViewModel
    
    init(storeCode: String) {
        _viewModel = StateObject(wrappedValue: StoreReportViewModel(storeCode: storeCode))
    }

    var body: some View {
        NavigationView {
            VStack {
                if let error = viewModel.error {
                    Text("Error: \(error.underlying.localizedDescription)")
                        .foregroundColor(.red)
                }
                List {
                    ForEach(viewModel.reports) { report in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date: \(report.date, formatter: itemFormatter)").font(.caption).foregroundColor(.secondary)
                            Text("Sales: $\(report.totalSales, specifier: "%.2f")  Transactions: \(report.totalTransactions)")
                                .font(.body)
                            Text("UPT: \(report.upt, specifier: "%.2f")  ADS: $\(report.ads, specifier: "%.2f")  CCP%: \(report.ccpPct * 100, specifier: "%.1f")%  GP%: \(report.gpPct * 100, specifier: "%.1f")%")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .refreshable { await viewModel.fetchReports() }
                .navigationTitle("Store Reports")
                .overlay {
                    if viewModel.isLoading { ProgressView() }
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

#Preview {
    StoreReportListView(storeCode: "Store 01")
}
