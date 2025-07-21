import SwiftUI

struct KPIListView: View {
    @StateObject private var viewModel = KPIViewModel()
    @Environment(\.currentUser) private var currentUser
    @State private var selectedTimePeriod: TimePeriod = .mtd
    @State private var navigationPath = NavigationPath()

    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            VStack {
                Picker("Time Period", selection: $selectedTimePeriod) {
                    ForEach(TimePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if viewModel.isLoading {
                    ProgressView("Loading KPIs...")
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error loading KPIs")
                        Text(error.localizedDescription).font(.caption)
                    }
                } else {
                    KPIGrid(kpiData: viewModel.kpiData)
                }
                Spacer()
            }
            .navigationTitle("KPIs")
            .onAppear {
                if let user = currentUser, let storeCode = user.storeCodes.first {
                    viewModel.fetchKPIs(for: storeCode, timePeriod: selectedTimePeriod)
                }
            }
            .onChange(of: selectedTimePeriod) { newPeriod in
                if let user = currentUser, let storeCode = user.storeCodes.first {
                    viewModel.fetchKPIs(for: storeCode, timePeriod: newPeriod)
                }
            }
        }
    }
}

struct KPIGrid: View {
    let kpiData: KPIData

    var body: some View {
        VStack {
            HStack {
                KPICard(title: "Total Sales", value: kpiData.totalSales, format: .currency)
                KPICard(title: "Transactions", value: Double(kpiData.totalTransactions), format: .number)
            }
            HStack {
                KPICard(title: "ADS", value: kpiData.averageADS, format: .currency)
                KPICard(title: "UPT", value: kpiData.averageUPT, format: .decimal)
            }
        }
        .padding()
    }
}

struct KPICard: View {
    let title: String
    let value: Double
    let format: NumberFormat
    
    enum NumberFormat {
        case currency, number, decimal
    }

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(formattedValue)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var formattedValue: String {
        switch format {
        case .currency:
            return String(format: "$%.2f", value)
        case .number:
            return String(format: "%.0f", value)
        case .decimal:
            return String(format: "%.2f", value)
        }
    }
}

struct KPIListView_Previews: PreviewProvider {
    static var previews: some View {
        KPIListView()
    }
}
