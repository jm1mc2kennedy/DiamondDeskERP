import SwiftUI
import Combine

// MARK: - Financial Dashboard View

public struct FinancialDashboardView: View {
    @StateObject private var viewModel = FinancialViewModel()
    @State private var showingRefreshAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            TabView(selection: $viewModel.selectedTab) {
                InvoiceListView(viewModel: viewModel)
                    .tabItem {
                        Label("Invoices", systemImage: "doc.text")
                    }
                    .tag(FinancialTab.invoices)
                
                PaymentListView(viewModel: viewModel)
                    .tabItem {
                        Label("Payments", systemImage: "creditcard")
                    }
                    .tag(FinancialTab.payments)
                
                BankAccountListView(viewModel: viewModel)
                    .tabItem {
                        Label("Accounts", systemImage: "building.columns")
                    }
                    .tag(FinancialTab.accounts)
                
                FinancialAnalyticsView(viewModel: viewModel)
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(FinancialTab.analytics)
            }
            .navigationTitle("Financial Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task {
                                await viewModel.refreshData()
                            }
                        }) {
                            Label("Refresh Data", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            viewModel.showingExportOptions = true
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingExportOptions) {
            ExportOptionsView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .task {
            await viewModel.loadData()
            await viewModel.loadAnalytics()
        }
    }
}

// MARK: - Invoice List View

public struct InvoiceListView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @State private var sortOrder = InvoiceSortOrder.dateCreated
    @State private var sortAscending = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            searchAndFilterBar
            
            // Content
            if viewModel.isLoading && viewModel.filteredInvoices.isEmpty {
                loadingView
            } else if viewModel.filteredInvoices.isEmpty {
                emptyStateView
            } else {
                invoiceList
            }
        }
        .navigationTitle("Invoices")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.selectedInvoiceIds.isEmpty {
                    Button("Actions") {
                        viewModel.showingBulkActions = true
                    }
                }
                
                Button {
                    viewModel.showingCreateInvoice = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreateInvoice) {
            CreateInvoiceView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingInvoiceFilters) {
            InvoiceFiltersView(viewModel: viewModel)
        }
        .confirmationDialog("Bulk Actions", isPresented: $viewModel.showingBulkActions) {
            ForEach(BulkActionType.allCases, id: \.self) { actionType in
                Button(actionType.displayName, role: actionType.isDestructive ? .destructive : nil) {
                    Task {
                        await viewModel.performBulkAction(actionType)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack {
                SearchBar(text: $viewModel.searchText)
                
                Button {
                    viewModel.showingInvoiceFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.accentColor)
                }
            }
            
            if !viewModel.selectedInvoiceIds.isEmpty {
                HStack {
                    Text("\(viewModel.selectedInvoiceIds.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Select All") {
                        viewModel.selectAllInvoices()
                    }
                    .font(.caption)
                    
                    Button("Deselect All") {
                        viewModel.deselectAllInvoices()
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading invoices...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Invoices")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first invoice to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.showingCreateInvoice = true
            } label: {
                Label("Create Invoice", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var invoiceList: some View {
        List {
            ForEach(sortedInvoices) { invoice in
                InvoiceRowView(
                    invoice: invoice,
                    isSelected: viewModel.selectedInvoiceIds.contains(invoice.id),
                    onTap: {
                        if !viewModel.selectedInvoiceIds.isEmpty {
                            viewModel.toggleInvoiceSelection(invoice.id)
                        } else {
                            viewModel.selectInvoice(invoice)
                        }
                    },
                    onLongPress: {
                        viewModel.toggleInvoiceSelection(invoice.id)
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var sortedInvoices: [Invoice] {
        let invoices = viewModel.filteredInvoices
        
        switch sortOrder {
        case .dateCreated:
            return sortAscending ? invoices.sorted { $0.createdAt < $1.createdAt } : invoices.sorted { $0.createdAt > $1.createdAt }
        case .dueDate:
            return sortAscending ? invoices.sorted { $0.dueDate < $1.dueDate } : invoices.sorted { $0.dueDate > $1.dueDate }
        case .amount:
            return sortAscending ? invoices.sorted { $0.totalAmount < $1.totalAmount } : invoices.sorted { $0.totalAmount > $1.totalAmount }
        case .status:
            return sortAscending ? invoices.sorted { $0.status.rawValue < $1.status.rawValue } : invoices.sorted { $0.status.rawValue > $1.status.rawValue }
        }
    }
}

// MARK: - Invoice Row View

public struct InvoiceRowView: View {
    let invoice: Invoice
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    public var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(invoice.invoiceNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formatCurrency(invoice.totalAmount))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text(invoice.clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    InvoiceStatusBadge(status: invoice.status)
                }
                
                HStack {
                    Text("Due: \(formatDate(invoice.dueDate))")
                        .font(.caption)
                        .foregroundColor(invoice.isOverdue ? .red : .secondary)
                    
                    Spacer()
                    
                    if invoice.isOverdue {
                        Text("OVERDUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Invoice Status Badge

public struct InvoiceStatusBadge: View {
    let status: InvoiceStatus
    
    public var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status {
        case .draft: return .gray.opacity(0.2)
        case .sent: return .blue.opacity(0.2)
        case .paid: return .green.opacity(0.2)
        case .overdue: return .red.opacity(0.2)
        case .cancelled: return .orange.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .orange
        }
    }
}

// MARK: - Payment List View

public struct PaymentListView: View {
    @ObservedObject var viewModel: FinancialViewModel
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Content
            if viewModel.isLoading && viewModel.filteredPayments.isEmpty {
                loadingView
            } else if viewModel.filteredPayments.isEmpty {
                emptyStateView
            } else {
                paymentList
            }
        }
        .navigationTitle("Payments")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingCreatePayment = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreatePayment) {
            CreatePaymentView(viewModel: viewModel)
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading payments...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Payments")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Record your first payment to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.showingCreatePayment = true
            } label: {
                Label("Record Payment", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var paymentList: some View {
        List(viewModel.filteredPayments) { payment in
            PaymentRowView(payment: payment) {
                viewModel.selectPayment(payment)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

// MARK: - Payment Row View

public struct PaymentRowView: View {
    let payment: PaymentRecord
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payment.paymentNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formatCurrency(payment.amount))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text(payment.paymentMethod.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    PaymentStatusBadge(status: payment.status)
                }
                
                Text("Date: \(formatDate(payment.paymentDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Payment Status Badge

public struct PaymentStatusBadge: View {
    let status: PaymentStatus
    
    public var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange.opacity(0.2)
        case .processing: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .failed: return .red.opacity(0.2)
        case .cancelled: return .gray.opacity(0.2)
        case .refunded: return .purple.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .refunded: return .purple
        }
    }
}

// MARK: - Bank Account List View

public struct BankAccountListView: View {
    @ObservedObject var viewModel: FinancialViewModel
    
    public var body: some View {
        VStack {
            if viewModel.bankAccounts.isEmpty {
                emptyStateView
            } else {
                accountList
            }
        }
        .navigationTitle("Bank Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingCreateBankAccount = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreateBankAccount) {
            CreateBankAccountView(viewModel: viewModel)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Bank Accounts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first bank account to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.showingCreateBankAccount = true
            } label: {
                Label("Add Account", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var accountList: some View {
        List(viewModel.bankAccounts) { account in
            BankAccountRowView(account: account) {
                viewModel.selectBankAccount(account)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

// MARK: - Bank Account Row View

public struct BankAccountRowView: View {
    let account: BankAccount
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.accountName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(account.bankName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("••••\(String(account.accountNumber.suffix(4)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(account.balance))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(account.accountType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Search Bar

public struct SearchBar: View {
    @Binding var text: String
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Supporting Types

public enum InvoiceSortOrder: String, CaseIterable {
    case dateCreated = "date_created"
    case dueDate = "due_date"
    case amount = "amount"
    case status = "status"
    
    public var displayName: String {
        switch self {
        case .dateCreated: return "Date Created"
        case .dueDate: return "Due Date"
        case .amount: return "Amount"
        case .status: return "Status"
        }
    }
}
