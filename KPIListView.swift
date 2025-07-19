// KPIListView.swift
// Diamond Desk ERP

import SwiftUI

struct KPIListView: View {
    @StateObject private var viewModel: KPIViewModel
    
    init(storeCode: String) {
        _viewModel = StateObject(wrappedValue: KPIViewModel(storeCode: storeCode))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.kpis) { kpi in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Store: \(kpi.storeCode)")
                            .font(.headline)
                        Text("Date: \(kpi.date, formatter: itemFormatter)")
                            .font(.subheadline)
                        ForEach(kpi.metrics.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            Text("\(key): \(value, specifier: "%.2f")")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("KPIs")
            .refreshable {
                await viewModel.fetchKPIs()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
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
