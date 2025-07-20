import Foundation
import Combine
import SwiftUI

// MARK: - Financial View Model

@MainActor
public final class FinancialViewModel: ObservableObject {
    // MARK: - Dependencies
    private let financialService: FinancialService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published public var selectedTab: FinancialTab = .invoices
    @Published public var searchText = ""
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // MARK: - Invoice Properties
    @Published public var invoices: [Invoice] = []
    @Published public var filteredInvoices: [Invoice] = []
    @Published public var selectedInvoice: Invoice?
    @Published public var invoiceFilter = InvoiceFilter()
    @Published public var showingCreateInvoice = false
    @Published public var showingInvoiceFilters = false
    
    // MARK: - Payment Properties
    @Published public var payments: [PaymentRecord] = []
    @Published public var filteredPayments: [PaymentRecord] = []
    @Published public var selectedPayment: PaymentRecord?
    @Published public var showingCreatePayment = false
    @Published public var showingPaymentFilters = false
    
    // MARK: - Analytics Properties
    @Published public var analytics: FinancialAnalytics?
    @Published public var showingAnalyticsFilters = false
    
    // MARK: - Bank Account Properties
    @Published public var bankAccounts: [BankAccount] = []
    @Published public var selectedBankAccount: BankAccount?
    @Published public var showingCreateBankAccount = false
    
    // MARK: - UI State
    @Published public var showingExportOptions = false
    @Published public var showingBulkActions = false
    @Published public var selectedInvoiceIds: Set<UUID> = []
    @Published public var bulkActionType: BulkActionType?
    
    // MARK: - Initialization
    
    public init(financialService: FinancialService = FinancialService.shared) {
        self.financialService = financialService
        setupBindings()
        setupSearchAndFiltering()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind service properties to view model
        financialService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        financialService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$error)
        
        financialService.$invoices
            .receive(on: DispatchQueue.main)
            .assign(to: &$invoices)
        
        financialService.$payments
            .receive(on: DispatchQueue.main)
            .assign(to: &$payments)
        
        financialService.$bankAccounts
            .receive(on: DispatchQueue.main)
            .assign(to: &$bankAccounts)
    }
    
    private func setupSearchAndFiltering() {
        // Setup reactive search and filtering for invoices
        Publishers.CombineLatest3($invoices, $searchText, $invoiceFilter)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] invoices, searchText, filter in
                Task { @MainActor in
                    await self?.updateFilteredInvoices(invoices: invoices, searchText: searchText, filter: filter)
                }
            }
            .store(in: &cancellables)
        
        // Setup reactive search for payments
        Publishers.CombineLatest($payments, $searchText)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] payments, searchText in
                Task { @MainActor in
                    await self?.updateFilteredPayments(payments: payments, searchText: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredInvoices(invoices: [Invoice], searchText: String, filter: InvoiceFilter) async {
        var filtered = invoices
        
        // Apply search filter
        if !searchText.isEmpty {
            do {
                filtered = try await financialService.searchInvoices(query: searchText)
            } catch {
                print("❌ Search error: \(error)")
            }
        }
        
        // Apply additional filters
        do {
            filtered = try await financialService.filterInvoices(filter: filter)
        } catch {
            print("❌ Filter error: \(error)")
        }
        
        filteredInvoices = filtered
    }
    
    private func updateFilteredPayments(payments: [PaymentRecord], searchText: String) async {
        var filtered = payments
        
        // Apply search filter for payments
        if !searchText.isEmpty {
            let searchTerms = searchText.lowercased()
            filtered = payments.filter { payment in
                payment.paymentNumber.lowercased().contains(searchTerms) ||
                payment.paymentMethod.displayName.lowercased().contains(searchTerms) ||
                payment.status.displayName.lowercased().contains(searchTerms) ||
                (payment.notes?.lowercased().contains(searchTerms) ?? false)
            }
        }
        
        filteredPayments = filtered
    }
    
    // MARK: - Data Loading
    
    public func loadData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.loadInvoices()
            }
            
            group.addTask { [weak self] in
                await self?.loadPayments()
            }
            
            group.addTask { [weak self] in
                await self?.loadBankAccounts()
            }
        }
    }
    
    public func refreshData() async {
        await loadData()
        await loadAnalytics()
    }
    
    private func loadInvoices() async {
        do {
            _ = try await financialService.fetchInvoices()
        } catch {
            self.error = error
        }
    }
    
    private func loadPayments() async {
        do {
            _ = try await financialService.fetchPayments()
        } catch {
            self.error = error
        }
    }
    
    private func loadBankAccounts() async {
        do {
            _ = try await financialService.fetchBankAccounts()
        } catch {
            self.error = error
        }
    }
    
    public func loadAnalytics() async {
        do {
            analytics = try await financialService.generateFinancialAnalytics()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Invoice Operations
    
    public func createInvoice(_ invoice: Invoice) async {
        do {
            _ = try await financialService.createInvoice(invoice)
            showingCreateInvoice = false
        } catch {
            self.error = error
        }
    }
    
    public func updateInvoice(_ invoice: Invoice) async {
        do {
            _ = try await financialService.updateInvoice(invoice)
        } catch {
            self.error = error
        }
    }
    
    public func deleteInvoice(_ invoice: Invoice) async {
        do {
            try await financialService.deleteInvoice(invoice)
            selectedInvoice = nil
        } catch {
            self.error = error
        }
    }
    
    public func duplicateInvoice(_ invoice: Invoice) async {
        do {
            let duplicatedInvoice = try await financialService.duplicateInvoice(invoice)
            selectedInvoice = duplicatedInvoice
        } catch {
            self.error = error
        }
    }
    
    public func sendInvoice(_ invoice: Invoice) async {
        do {
            let sentInvoice = try await financialService.sendInvoice(invoice)
            selectedInvoice = sentInvoice
        } catch {
            self.error = error
        }
    }
    
    public func selectInvoice(_ invoice: Invoice) {
        selectedInvoice = invoice
    }
    
    // MARK: - Payment Operations
    
    public func createPayment(_ payment: PaymentRecord) async {
        do {
            _ = try await financialService.createPayment(payment)
            showingCreatePayment = false
        } catch {
            self.error = error
        }
    }
    
    public func updatePayment(_ payment: PaymentRecord) async {
        do {
            _ = try await financialService.updatePayment(payment)
        } catch {
            self.error = error
        }
    }
    
    public func deletePayment(_ payment: PaymentRecord) async {
        do {
            try await financialService.deletePayment(payment)
            selectedPayment = nil
        } catch {
            self.error = error
        }
    }
    
    public func selectPayment(_ payment: PaymentRecord) {
        selectedPayment = payment
    }
    
    // MARK: - Bank Account Operations
    
    public func createBankAccount(_ account: BankAccount) async {
        do {
            _ = try await financialService.createBankAccount(account)
            showingCreateBankAccount = false
        } catch {
            self.error = error
        }
    }
    
    public func updateBankAccount(_ account: BankAccount) async {
        do {
            _ = try await financialService.updateBankAccount(account)
        } catch {
            self.error = error
        }
    }
    
    public func deleteBankAccount(_ account: BankAccount) async {
        do {
            try await financialService.deleteBankAccount(account)
            selectedBankAccount = nil
        } catch {
            self.error = error
        }
    }
    
    public func selectBankAccount(_ account: BankAccount) {
        selectedBankAccount = account
    }
    
    // MARK: - Bulk Operations
    
    public func performBulkAction(_ actionType: BulkActionType) async {
        guard !selectedInvoiceIds.isEmpty else { return }
        
        switch actionType {
        case .markAsSent:
            do {
                try await financialService.bulkUpdateInvoiceStatus(Array(selectedInvoiceIds), status: .sent)
                selectedInvoiceIds.removeAll()
                showingBulkActions = false
            } catch {
                self.error = error
            }
            
        case .markAsPaid:
            do {
                try await financialService.bulkUpdateInvoiceStatus(Array(selectedInvoiceIds), status: .paid)
                selectedInvoiceIds.removeAll()
                showingBulkActions = false
            } catch {
                self.error = error
            }
            
        case .delete:
            do {
                try await financialService.bulkDeleteInvoices(Array(selectedInvoiceIds))
                selectedInvoiceIds.removeAll()
                showingBulkActions = false
            } catch {
                self.error = error
            }
        }
    }
    
    public func toggleInvoiceSelection(_ invoiceId: UUID) {
        if selectedInvoiceIds.contains(invoiceId) {
            selectedInvoiceIds.remove(invoiceId)
        } else {
            selectedInvoiceIds.insert(invoiceId)
        }
    }
    
    public func selectAllInvoices() {
        selectedInvoiceIds = Set(filteredInvoices.map { $0.id })
    }
    
    public func deselectAllInvoices() {
        selectedInvoiceIds.removeAll()
    }
    
    // MARK: - Export Operations
    
    public func exportInvoices() async {
        do {
            let url = try await financialService.exportInvoicesToCSV()
            // Handle file sharing - in a real app, this would present a share sheet
            print("✅ Invoices exported to: \(url)")
        } catch {
            self.error = error
        }
    }
    
    public func exportPayments() async {
        do {
            let url = try await financialService.exportPaymentsToCSV()
            // Handle file sharing - in a real app, this would present a share sheet
            print("✅ Payments exported to: \(url)")
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Filter Management
    
    public func updateInvoiceFilter(_ filter: InvoiceFilter) {
        invoiceFilter = filter
    }
    
    public func clearInvoiceFilter() {
        invoiceFilter = InvoiceFilter()
    }
    
    // MARK: - Number Generation
    
    public func generateInvoiceNumber() async -> String {
        return await financialService.generateInvoiceNumber()
    }
    
    public func generatePaymentNumber() async -> String {
        return await financialService.generatePaymentNumber()
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
    
    // MARK: - Computed Properties
    
    public var totalRevenue: Decimal {
        analytics?.totalRevenue ?? 0
    }
    
    public var outstandingAmount: Decimal {
        analytics?.outstandingAmount ?? 0
    }
    
    public var overdueAmount: Decimal {
        analytics?.overdueAmount ?? 0
    }
    
    public var invoiceStatusCounts: [InvoiceStatus: Int] {
        var counts: [InvoiceStatus: Int] = [:]
        for invoice in invoices {
            counts[invoice.status, default: 0] += 1
        }
        return counts
    }
    
    public var paymentStatusCounts: [PaymentStatus: Int] {
        var counts: [PaymentStatus: Int] = [:]
        for payment in payments {
            counts[payment.status, default: 0] += 1
        }
        return counts
    }
    
    public var recentInvoices: [Invoice] {
        return Array(invoices.prefix(5))
    }
    
    public var recentPayments: [PaymentRecord] {
        return Array(payments.prefix(5))
    }
    
    public var overdueInvoices: [Invoice] {
        return invoices.filter { $0.isOverdue }
    }
    
    public var upcomingInvoices: [Invoice] {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return invoices.filter { invoice in
            invoice.status == .sent && invoice.dueDate <= nextWeek && !invoice.isOverdue
        }
    }
}

// MARK: - Supporting Types

public enum FinancialTab: String, CaseIterable {
    case invoices = "invoices"
    case payments = "payments"
    case accounts = "accounts"
    case analytics = "analytics"
    
    public var displayName: String {
        switch self {
        case .invoices: return "Invoices"
        case .payments: return "Payments"
        case .accounts: return "Accounts"
        case .analytics: return "Analytics"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .invoices: return "doc.text"
        case .payments: return "creditcard"
        case .accounts: return "building.columns"
        case .analytics: return "chart.bar"
        }
    }
}

public enum BulkActionType: String, CaseIterable {
    case markAsSent = "mark_as_sent"
    case markAsPaid = "mark_as_paid"
    case delete = "delete"
    
    public var displayName: String {
        switch self {
        case .markAsSent: return "Mark as Sent"
        case .markAsPaid: return "Mark as Paid"
        case .delete: return "Delete"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .markAsSent: return "paperplane"
        case .markAsPaid: return "checkmark.circle"
        case .delete: return "trash"
        }
    }
    
    public var isDestructive: Bool {
        return self == .delete
    }
}

// MARK: - Filter Extensions

extension InvoiceFilter {
    public func isEmpty: Bool {
        return statuses?.isEmpty != false &&
               dateRange == nil &&
               minAmount == nil &&
               maxAmount == nil &&
               currencies?.isEmpty != false &&
               clientIds?.isEmpty != false
    }
}

// MARK: - Analytics Extensions

extension FinancialAnalytics {
    public var formattedTotalRevenue: String {
        return formatCurrency(totalRevenue)
    }
    
    public var formattedOutstandingAmount: String {
        return formatCurrency(outstandingAmount)
    }
    
    public var formattedOverdueAmount: String {
        return formatCurrency(overdueAmount)
    }
    
    public var formattedAverageInvoiceAmount: String {
        return formatCurrency(averageInvoiceAmount)
    }
    
    public var collectionRate: Double {
        guard totalInvoices > 0 else { return 0 }
        return Double(paidInvoices) / Double(totalInvoices) * 100
    }
    
    public var overdueRate: Double {
        guard totalInvoices > 0 else { return 0 }
        return Double(overdueInvoices) / Double(totalInvoices) * 100
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Date Helper Extensions

public extension Date {
    static var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    static var endOfMonth: Date {
        let calendar = Calendar.current
        let startOfMonth = Date.startOfMonth
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? Date()
    }
    
    static var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    static var endOfYear: Date {
        let calendar = Calendar.current
        let startOfYear = Date.startOfYear
        return calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) ?? Date()
    }
}
