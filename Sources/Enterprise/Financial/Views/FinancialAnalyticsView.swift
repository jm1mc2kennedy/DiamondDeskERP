import SwiftUI
import Charts

// MARK: - Financial Analytics View

public struct FinancialAnalyticsView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @State private var selectedTimeframe: AnalyticsTimeframe = .thisMonth
    @State private var showingTimeframePicker = false
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with timeframe selector
                analyticsHeader
                
                // Key metrics cards
                if let analytics = viewModel.analytics {
                    keyMetricsSection(analytics)
                    
                    // Charts section
                    chartsSection(analytics)
                    
                    // Status breakdown
                    statusBreakdownSection(analytics)
                    
                    // Recent activity
                    recentActivitySection
                } else {
                    loadingView
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingTimeframePicker = true
                } label: {
                    Text(selectedTimeframe.displayName)
                        .font(.caption)
                }
            }
        }
        .confirmationDialog("Select Timeframe", isPresented: $showingTimeframePicker) {
            ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                Button(timeframe.displayName) {
                    selectedTimeframe = timeframe
                    Task {
                        await viewModel.loadAnalytics()
                    }
                }
            }
        }
        .task {
            await viewModel.loadAnalytics()
        }
    }
    
    private var analyticsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Financial Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.loadAnalytics()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentColor)
                }
            }
            
            Text(selectedTimeframe.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading analytics...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func keyMetricsSection(_ analytics: FinancialAnalytics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Total Revenue",
                value: analytics.formattedTotalRevenue,
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            MetricCard(
                title: "Outstanding",
                value: analytics.formattedOutstandingAmount,
                icon: "clock.circle.fill",
                color: .orange
            )
            
            MetricCard(
                title: "Overdue",
                value: analytics.formattedOverdueAmount,
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            
            MetricCard(
                title: "Average Invoice",
                value: analytics.formattedAverageInvoiceAmount,
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }
    
    private func chartsSection(_ analytics: FinancialAnalytics) -> some View {
        VStack(spacing: 20) {
            // Revenue chart
            revenueChart(analytics)
            
            // Collection rate chart
            collectionRateChart(analytics)
        }
    }
    
    private func revenueChart(_ analytics: FinancialAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for chart - In a real implementation, you'd use Swift Charts
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        
                        Text("Revenue Trend Chart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func collectionRateChart(_ analytics: FinancialAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collection Rate")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(analytics.collectionRate))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Collection Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Circular progress indicator
                CircularProgressView(
                    progress: analytics.collectionRate / 100,
                    color: .green
                )
                .frame(width: 80, height: 80)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func statusBreakdownSection(_ analytics: FinancialAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Status Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatusBreakdownRow(
                    status: "Paid",
                    count: analytics.paidInvoices,
                    total: analytics.totalInvoices,
                    color: .green
                )
                
                StatusBreakdownRow(
                    status: "Sent",
                    count: analytics.sentInvoices,
                    total: analytics.totalInvoices,
                    color: .blue
                )
                
                StatusBreakdownRow(
                    status: "Overdue",
                    count: analytics.overdueInvoices,
                    total: analytics.totalInvoices,
                    color: .red
                )
                
                StatusBreakdownRow(
                    status: "Draft",
                    count: analytics.draftInvoices,
                    total: analytics.totalInvoices,
                    color: .gray
                )
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentInvoices.prefix(3), id: \.id) { invoice in
                    RecentActivityRow(
                        title: "Invoice \(invoice.invoiceNumber)",
                        subtitle: "Created for \(invoice.clientName)",
                        amount: formatCurrency(invoice.totalAmount),
                        date: invoice.createdAt,
                        icon: "doc.text",
                        color: .blue
                    )
                }
                
                ForEach(viewModel.recentPayments.prefix(3), id: \.id) { payment in
                    RecentActivityRow(
                        title: "Payment \(payment.paymentNumber)",
                        subtitle: payment.paymentMethod.displayName,
                        amount: formatCurrency(payment.amount),
                        date: payment.paymentDate,
                        icon: "creditcard",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Metric Card

public struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Circular Progress View

public struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
        }
    }
}

// MARK: - Status Breakdown Row

public struct StatusBreakdownRow: View {
    let status: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    public var body: some View {
        HStack {
            Text(status)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Recent Activity Row

public struct RecentActivityRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let date: Date
    let icon: String
    let color: Color
    
    public var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Export Options View

public struct ExportOptionsView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Financial Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    ExportOptionButton(
                        title: "Export Invoices",
                        subtitle: "Export all invoices to CSV",
                        icon: "doc.text",
                        action: {
                            Task {
                                await viewModel.exportInvoices()
                                dismiss()
                            }
                        }
                    )
                    
                    ExportOptionButton(
                        title: "Export Payments",
                        subtitle: "Export all payments to CSV",
                        icon: "creditcard",
                        action: {
                            Task {
                                await viewModel.exportPayments()
                                dismiss()
                            }
                        }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Export Option Button

public struct ExportOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Analytics Timeframe

public enum AnalyticsTimeframe: String, CaseIterable {
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisQuarter = "this_quarter"
    case thisYear = "this_year"
    case lastMonth = "last_month"
    case lastQuarter = "last_quarter"
    case lastYear = "last_year"
    
    public var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisQuarter: return "This Quarter"
        case .thisYear: return "This Year"
        case .lastMonth: return "Last Month"
        case .lastQuarter: return "Last Quarter"
        case .lastYear: return "Last Year"
        }
    }
    
    public var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            return (startOfWeek, endOfWeek)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (startOfMonth, endOfMonth)
            
        case .thisQuarter:
            let quarter = calendar.component(.quarter, from: now)
            let year = calendar.component(.year, from: now)
            let startOfQuarter = calendar.date(from: DateComponents(year: year, month: (quarter - 1) * 3 + 1, day: 1)) ?? now
            let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter) ?? now
            return (startOfQuarter, endOfQuarter)
            
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return (startOfYear, endOfYear)
            
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? now
            let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? now
            return (startOfLastMonth, endOfLastMonth)
            
        case .lastQuarter:
            let lastQuarter = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            let quarter = calendar.component(.quarter, from: lastQuarter)
            let year = calendar.component(.year, from: lastQuarter)
            let startOfQuarter = calendar.date(from: DateComponents(year: year, month: (quarter - 1) * 3 + 1, day: 1)) ?? now
            let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter) ?? now
            return (startOfQuarter, endOfQuarter)
            
        case .lastYear:
            let lastYear = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            let startOfLastYear = calendar.dateInterval(of: .year, for: lastYear)?.start ?? now
            let endOfLastYear = calendar.dateInterval(of: .year, for: lastYear)?.end ?? now
            return (startOfLastYear, endOfLastYear)
        }
    }
}
