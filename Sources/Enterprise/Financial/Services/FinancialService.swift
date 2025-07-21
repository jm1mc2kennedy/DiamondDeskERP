import Foundation
import CloudKit
import Combine

// MARK: - Financial Service

@MainActor
public final class FinancialService: ObservableObject {
    public static let shared = FinancialService()
    
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // MARK: - Publishers
    @Published public var invoices: [Invoice] = []
    @Published public var payments: [PaymentRecord] = []
    @Published public var bankAccounts: [BankAccount] = []
    @Published public var paymentGateways: [PaymentGateway] = []
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
        self.database = container.privateCloudDatabase
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Setup CloudKit subscriptions for real-time updates
        Task {
            await setupCloudKitSubscriptions()
        }
    }
    
    private func setupCloudKitSubscriptions() async {
        do {
            // Invoice subscription
            let invoiceSubscription = CKQuerySubscription(
                recordType: "Invoice",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            invoiceSubscription.notificationInfo = CKSubscription.NotificationInfo()
            invoiceSubscription.notificationInfo?.shouldSendContentAvailable = true
            
            // Payment subscription
            let paymentSubscription = CKQuerySubscription(
                recordType: "PaymentRecord",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            paymentSubscription.notificationInfo = CKSubscription.NotificationInfo()
            paymentSubscription.notificationInfo?.shouldSendContentAvailable = true
            
            try await database.save(invoiceSubscription)
            try await database.save(paymentSubscription)
            
            print("✅ Financial CloudKit subscriptions setup successfully")
        } catch {
            print("❌ Failed to setup CloudKit subscriptions: \(error)")
            self.error = error
        }
    }
    
    // MARK: - Invoice Operations
    
    public func fetchInvoices() async throws -> [Invoice] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let query = CKQuery(recordType: "Invoice", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "issueDate", ascending: false)]
            
            let (results, _) = try await database.records(matching: query)
            
            let invoices = results.compactMap { (_, result) -> Invoice? in
                switch result {
                case .success(let record):
                    return Invoice(record: record)
                case .failure(let error):
                    print("❌ Failed to process invoice record: \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.invoices = invoices
            }
            
            return invoices
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func createInvoice(_ invoice: Invoice) async throws -> Invoice {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let record = invoice.toCKRecord()
            let savedRecord = try await database.save(record)
            
            guard let savedInvoice = Invoice(record: savedRecord) else {
                throw FinancialError.invalidData
            }
            
            await MainActor.run {
                self.invoices.append(savedInvoice)
                self.invoices.sort { $0.issueDate > $1.issueDate }
            }
            
            return savedInvoice
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func updateInvoice(_ invoice: Invoice) async throws -> Invoice {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let record = invoice.toCKRecord()
            let savedRecord = try await database.save(record)
            
            guard let updatedInvoice = Invoice(record: savedRecord) else {
                throw FinancialError.invalidData
            }
            
            await MainActor.run {
                if let index = self.invoices.firstIndex(where: { $0.id == invoice.id }) {
                    self.invoices[index] = updatedInvoice
                }
            }
            
            return updatedInvoice
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func deleteInvoice(_ invoice: Invoice) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let recordID = CKRecord.ID(recordName: invoice.id.uuidString)
            try await database.deleteRecord(withID: recordID)
            
            await MainActor.run {
                self.invoices.removeAll { $0.id == invoice.id }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func searchInvoices(query: String) async throws -> [Invoice] {
        let searchTerms = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerms.isEmpty else { return invoices }
        
        return invoices.filter { invoice in
            invoice.invoiceNumber.lowercased().contains(searchTerms) ||
            invoice.clientName.lowercased().contains(searchTerms) ||
            invoice.status.displayName.lowercased().contains(searchTerms) ||
            (invoice.notes?.lowercased().contains(searchTerms) ?? false)
        }
    }
    
    public func filterInvoices(filter: InvoiceFilter) async throws -> [Invoice] {
        return invoices.filter { invoice in
            var matches = true
            
            if let statuses = filter.statuses, !statuses.isEmpty {
                matches = matches && statuses.contains(invoice.status)
            }
            
            if let dateRange = filter.dateRange {
                matches = matches && (dateRange.start...dateRange.end).contains(invoice.issueDate)
            }
            
            if let minAmount = filter.minAmount {
                matches = matches && invoice.totalAmount >= minAmount
            }
            
            if let maxAmount = filter.maxAmount {
                matches = matches && invoice.totalAmount <= maxAmount
            }
            
            if let currencies = filter.currencies, !currencies.isEmpty {
                matches = matches && currencies.contains(invoice.currency)
            }
            
            if let clientIds = filter.clientIds, !clientIds.isEmpty {
                matches = matches && clientIds.contains(invoice.clientId)
            }
            
            return matches
        }
    }
    
    public func generateInvoiceNumber() async -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let invoiceCount = invoices.filter { invoice in
            Calendar.current.component(.year, from: invoice.issueDate) == currentYear
        }.count
        
        return String(format: "INV-%04d-%04d", currentYear, invoiceCount + 1)
    }
    
    public func duplicateInvoice(_ invoice: Invoice) async throws -> Invoice {
        let newInvoice = Invoice(
            invoiceNumber: await generateInvoiceNumber(),
            clientId: invoice.clientId,
            clientName: invoice.clientName,
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            subtotal: invoice.subtotal,
            taxAmount: invoice.taxAmount,
            discountAmount: invoice.discountAmount,
            totalAmount: invoice.totalAmount,
            currency: invoice.currency,
            lineItems: invoice.lineItems,
            paymentTerms: invoice.paymentTerms,
            notes: invoice.notes,
            billingAddress: invoice.billingAddress,
            shippingAddress: invoice.shippingAddress,
            taxDetails: invoice.taxDetails,
            createdBy: invoice.createdBy,
            lastModifiedBy: invoice.lastModifiedBy
        )
        
        return try await createInvoice(newInvoice)
    }
    
    public func sendInvoice(_ invoice: Invoice) async throws -> Invoice {
        var updatedInvoice = invoice
        updatedInvoice = Invoice(
            id: invoice.id,
            invoiceNumber: invoice.invoiceNumber,
            clientId: invoice.clientId,
            clientName: invoice.clientName,
            issueDate: invoice.issueDate,
            dueDate: invoice.dueDate,
            status: .sent,
            subtotal: invoice.subtotal,
            taxAmount: invoice.taxAmount,
            discountAmount: invoice.discountAmount,
            totalAmount: invoice.totalAmount,
            currency: invoice.currency,
            lineItems: invoice.lineItems,
            paymentTerms: invoice.paymentTerms,
            notes: invoice.notes,
            attachments: invoice.attachments,
            billingAddress: invoice.billingAddress,
            shippingAddress: invoice.shippingAddress,
            taxDetails: invoice.taxDetails,
            paymentHistory: invoice.paymentHistory,
            recurringSettings: invoice.recurringSettings,
            createdBy: invoice.createdBy,
            createdAt: invoice.createdAt,
            lastModified: Date(),
            lastModifiedBy: invoice.lastModifiedBy
        )
        
        return try await updateInvoice(updatedInvoice)
    }
    
    // MARK: - Payment Operations
    
    public func fetchPayments() async throws -> [PaymentRecord] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let query = CKQuery(recordType: "PaymentRecord", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "paymentDate", ascending: false)]
            
            let (results, _) = try await database.records(matching: query)
            
            let payments = results.compactMap { (_, result) -> PaymentRecord? in
                switch result {
                case .success(let record):
                    return PaymentRecord(record: record)
                case .failure(let error):
                    print("❌ Failed to process payment record: \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.payments = payments
            }
            
            return payments
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func createPayment(_ payment: PaymentRecord) async throws -> PaymentRecord {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let record = payment.toCKRecord()
            let savedRecord = try await database.save(record)
            
            guard let savedPayment = PaymentRecord(record: savedRecord) else {
                throw FinancialError.invalidData
            }
            
            await MainActor.run {
                self.payments.append(savedPayment)
                self.payments.sort { $0.paymentDate > $1.paymentDate }
            }
            
            // Update associated invoice
            try await updateInvoicePaymentStatus(for: payment.invoiceId)
            
            return savedPayment
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func updatePayment(_ payment: PaymentRecord) async throws -> PaymentRecord {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let record = payment.toCKRecord()
            let savedRecord = try await database.save(record)
            
            guard let updatedPayment = PaymentRecord(record: savedRecord) else {
                throw FinancialError.invalidData
            }
            
            await MainActor.run {
                if let index = self.payments.firstIndex(where: { $0.id == payment.id }) {
                    self.payments[index] = updatedPayment
                }
            }
            
            // Update associated invoice
            try await updateInvoicePaymentStatus(for: payment.invoiceId)
            
            return updatedPayment
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    public func deletePayment(_ payment: PaymentRecord) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let recordID = CKRecord.ID(recordName: payment.id.uuidString)
            try await database.deleteRecord(withID: recordID)
            
            await MainActor.run {
                self.payments.removeAll { $0.id == payment.id }
            }
            
            // Update associated invoice
            try await updateInvoicePaymentStatus(for: payment.invoiceId)
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    private func updateInvoicePaymentStatus(for invoiceId: UUID) async throws {
        guard let invoice = invoices.first(where: { $0.id == invoiceId }) else { return }
        
        let relatedPayments = payments.filter { $0.invoiceId == invoiceId && $0.status == .completed }
        let totalPaid = relatedPayments.reduce(Decimal.zero) { $0 + $1.amount }
        
        let newStatus: InvoiceStatus
        if totalPaid >= invoice.totalAmount {
            newStatus = .paid
        } else if totalPaid > 0 {
            newStatus = .partiallyPaid
        } else if invoice.isOverdue {
            newStatus = .overdue
        } else {
            newStatus = invoice.status
        }
        
        if newStatus != invoice.status {
            let updatedInvoice = Invoice(
                id: invoice.id,
                invoiceNumber: invoice.invoiceNumber,
                clientId: invoice.clientId,
                clientName: invoice.clientName,
                issueDate: invoice.issueDate,
                dueDate: invoice.dueDate,
                status: newStatus,
                subtotal: invoice.subtotal,
                taxAmount: invoice.taxAmount,
                discountAmount: invoice.discountAmount,
                totalAmount: invoice.totalAmount,
                currency: invoice.currency,
                lineItems: invoice.lineItems,
                paymentTerms: invoice.paymentTerms,
                notes: invoice.notes,
                attachments: invoice.attachments,
                billingAddress: invoice.billingAddress,
                shippingAddress: invoice.shippingAddress,
                taxDetails: invoice.taxDetails,
                paymentHistory: relatedPayments,
                recurringSettings: invoice.recurringSettings,
                createdBy: invoice.createdBy,
                createdAt: invoice.createdAt,
                lastModified: Date(),
                lastModifiedBy: invoice.lastModifiedBy
            )
            
            _ = try await updateInvoice(updatedInvoice)
        }
    }
    
    public func generatePaymentNumber() async -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let paymentCount = payments.filter { payment in
            Calendar.current.component(.year, from: payment.paymentDate) == currentYear
        }.count
        
        return String(format: "PAY-%04d-%04d", currentYear, paymentCount + 1)
    }
    
    // MARK: - Bank Account Operations
    
    public func fetchBankAccounts() async throws -> [BankAccount] {
        // For now, return local data - in production, this would sync with banking APIs
        return bankAccounts
    }
    
    public func createBankAccount(_ account: BankAccount) async throws -> BankAccount {
        bankAccounts.append(account)
        return account
    }
    
    public func updateBankAccount(_ account: BankAccount) async throws -> BankAccount {
        if let index = bankAccounts.firstIndex(where: { $0.id == account.id }) {
            bankAccounts[index] = account
        }
        return account
    }
    
    public func deleteBankAccount(_ account: BankAccount) async throws {
        bankAccounts.removeAll { $0.id == account.id }
    }
    
    // MARK: - Analytics and Reporting
    
    public func generateFinancialAnalytics() async throws -> FinancialAnalytics {
        let allInvoices = invoices
        let allPayments = payments
        
        let totalRevenue = allInvoices
            .filter { $0.status == .paid }
            .reduce(Decimal.zero) { $0 + $1.totalAmount }
        
        let outstandingAmount = allInvoices
            .filter { $0.status != .paid && $0.status != .cancelled }
            .reduce(Decimal.zero) { $0 + $1.remainingAmount }
        
        let overdueAmount = allInvoices
            .filter { $0.isOverdue }
            .reduce(Decimal.zero) { $0 + $1.remainingAmount }
        
        let totalInvoicesCount = allInvoices.count
        let paidInvoicesCount = allInvoices.filter { $0.status == .paid }.count
        let overdueInvoicesCount = allInvoices.filter { $0.isOverdue }.count
        
        let averageInvoiceAmount = totalInvoicesCount > 0 ?
            allInvoices.reduce(Decimal.zero) { $0 + $1.totalAmount } / Decimal(totalInvoicesCount) : 0
        
        let averageDaysToPayment = calculateAverageDaysToPayment()
        
        let monthlyRevenue = calculateMonthlyRevenue()
        let revenueByClient = calculateRevenueByClient()
        let paymentMethodBreakdown = calculatePaymentMethodBreakdown()
        
        return FinancialAnalytics(
            totalRevenue: totalRevenue,
            outstandingAmount: outstandingAmount,
            overdueAmount: overdueAmount,
            totalInvoices: totalInvoicesCount,
            paidInvoices: paidInvoicesCount,
            overdueInvoices: overdueInvoicesCount,
            averageInvoiceAmount: averageInvoiceAmount,
            averageDaysToPayment: averageDaysToPayment,
            monthlyRevenue: monthlyRevenue,
            revenueByClient: revenueByClient,
            paymentMethodBreakdown: paymentMethodBreakdown
        )
    }
    
    private func calculateAverageDaysToPayment() -> Double {
        let paidInvoices = invoices.filter { $0.status == .paid }
        guard !paidInvoices.isEmpty else { return 0 }
        
        let totalDays = paidInvoices.compactMap { invoice -> Int? in
            guard let lastPayment = invoice.paymentHistory.last else { return nil }
            return Calendar.current.dateComponents([.day], from: invoice.issueDate, to: lastPayment.paymentDate).day
        }.reduce(0, +)
        
        return Double(totalDays) / Double(paidInvoices.count)
    }
    
    private func calculateMonthlyRevenue() -> [String: Decimal] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        var monthlyRevenue: [String: Decimal] = [:]
        
        for invoice in invoices.filter({ $0.status == .paid }) {
            let monthKey = dateFormatter.string(from: invoice.issueDate)
            monthlyRevenue[monthKey, default: 0] += invoice.totalAmount
        }
        
        return monthlyRevenue
    }
    
    private func calculateRevenueByClient() -> [String: Decimal] {
        var revenueByClient: [String: Decimal] = [:]
        
        for invoice in invoices.filter({ $0.status == .paid }) {
            revenueByClient[invoice.clientName, default: 0] += invoice.totalAmount
        }
        
        return revenueByClient
    }
    
    private func calculatePaymentMethodBreakdown() -> [String: Int] {
        var methodBreakdown: [String: Int] = [:]
        
        for payment in payments.filter({ $0.status == .completed }) {
            methodBreakdown[payment.paymentMethod.displayName, default: 0] += 1
        }
        
        return methodBreakdown
    }
    
    // MARK: - Export Operations
    
    public func exportInvoicesToCSV() async throws -> URL {
        let csvContent = generateInvoicesCSV()
        let fileName = "invoices_\(DateFormatter.fileNameFormat.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    public func exportPaymentsToCSV() async throws -> URL {
        let csvContent = generatePaymentsCSV()
        let fileName = "payments_\(DateFormatter.fileNameFormat.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    private func generateInvoicesCSV() -> String {
        var csv = "Invoice Number,Client Name,Issue Date,Due Date,Status,Subtotal,Tax Amount,Total Amount,Currency\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for invoice in invoices {
            let row = [
                invoice.invoiceNumber,
                invoice.clientName,
                dateFormatter.string(from: invoice.issueDate),
                dateFormatter.string(from: invoice.dueDate),
                invoice.status.displayName,
                invoice.subtotal.description,
                invoice.taxAmount.description,
                invoice.totalAmount.description,
                invoice.currency.displayName
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func generatePaymentsCSV() -> String {
        var csv = "Payment Number,Invoice ID,Amount,Currency,Payment Date,Payment Method,Status\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for payment in payments {
            let row = [
                payment.paymentNumber,
                payment.invoiceId.uuidString,
                payment.amount.description,
                payment.currency.displayName,
                dateFormatter.string(from: payment.paymentDate),
                payment.paymentMethod.displayName,
                payment.status.displayName
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    // MARK: - Bulk Operations
    
    public func bulkUpdateInvoiceStatus(_ invoiceIds: [UUID], status: InvoiceStatus) async throws {
        isLoading = true
        defer { isLoading = false }
        
        for invoiceId in invoiceIds {
            guard let invoice = invoices.first(where: { $0.id == invoiceId }) else { continue }
            
            let updatedInvoice = Invoice(
                id: invoice.id,
                invoiceNumber: invoice.invoiceNumber,
                clientId: invoice.clientId,
                clientName: invoice.clientName,
                issueDate: invoice.issueDate,
                dueDate: invoice.dueDate,
                status: status,
                subtotal: invoice.subtotal,
                taxAmount: invoice.taxAmount,
                discountAmount: invoice.discountAmount,
                totalAmount: invoice.totalAmount,
                currency: invoice.currency,
                lineItems: invoice.lineItems,
                paymentTerms: invoice.paymentTerms,
                notes: invoice.notes,
                attachments: invoice.attachments,
                billingAddress: invoice.billingAddress,
                shippingAddress: invoice.shippingAddress,
                taxDetails: invoice.taxDetails,
                paymentHistory: invoice.paymentHistory,
                recurringSettings: invoice.recurringSettings,
                createdBy: invoice.createdBy,
                createdAt: invoice.createdAt,
                lastModified: Date(),
                lastModifiedBy: invoice.lastModifiedBy
            )
            
            _ = try await updateInvoice(updatedInvoice)
        }
    }
    
    public func bulkDeleteInvoices(_ invoiceIds: [UUID]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        for invoiceId in invoiceIds {
            guard let invoice = invoices.first(where: { $0.id == invoiceId }) else { continue }
            try await deleteInvoice(invoice)
        }
    }
}

// MARK: - Financial Analytics

public struct FinancialAnalytics {
    public let totalRevenue: Decimal
    public let outstandingAmount: Decimal
    public let overdueAmount: Decimal
    public let totalInvoices: Int
    public let paidInvoices: Int
    public let overdueInvoices: Int
    public let averageInvoiceAmount: Decimal
    public let averageDaysToPayment: Double
    public let monthlyRevenue: [String: Decimal]
    public let revenueByClient: [String: Decimal]
    public let paymentMethodBreakdown: [String: Int]
    
    public init(
        totalRevenue: Decimal,
        outstandingAmount: Decimal,
        overdueAmount: Decimal,
        totalInvoices: Int,
        paidInvoices: Int,
        overdueInvoices: Int,
        averageInvoiceAmount: Decimal,
        averageDaysToPayment: Double,
        monthlyRevenue: [String: Decimal],
        revenueByClient: [String: Decimal],
        paymentMethodBreakdown: [String: Int]
    ) {
        self.totalRevenue = totalRevenue
        self.outstandingAmount = outstandingAmount
        self.overdueAmount = overdueAmount
        self.totalInvoices = totalInvoices
        self.paidInvoices = paidInvoices
        self.overdueInvoices = overdueInvoices
        self.averageInvoiceAmount = averageInvoiceAmount
        self.averageDaysToPayment = averageDaysToPayment
        self.monthlyRevenue = monthlyRevenue
        self.revenueByClient = revenueByClient
        self.paymentMethodBreakdown = paymentMethodBreakdown
    }
}

// MARK: - Filter Models

public struct InvoiceFilter {
    public let statuses: [InvoiceStatus]?
    public let dateRange: DateRange?
    public let minAmount: Decimal?
    public let maxAmount: Decimal?
    public let currencies: [Currency]?
    public let clientIds: [UUID]?
    
    public init(
        statuses: [InvoiceStatus]? = nil,
        dateRange: DateRange? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil,
        currencies: [Currency]? = nil,
        clientIds: [UUID]? = nil
    ) {
        self.statuses = statuses
        self.dateRange = dateRange
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.currencies = currencies
        self.clientIds = clientIds
    }
}

public struct DateRange {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

// MARK: - Error Types

public enum FinancialError: Error, LocalizedError {
    case invalidData
    case networkError
    case unauthorized
    case invoiceNotFound
    case paymentNotFound
    case invalidAmount
    case duplicateInvoiceNumber
    case gatewayError(String)
    case bankingProviderError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        case .invoiceNotFound:
            return "Invoice not found"
        case .paymentNotFound:
            return "Payment not found"
        case .invalidAmount:
            return "Invalid amount provided"
        case .duplicateInvoiceNumber:
            return "Invoice number already exists"
        case .gatewayError(let message):
            return "Payment gateway error: \(message)"
        case .bankingProviderError(let message):
            return "Banking provider error: \(message)"
        }
    }
}

// MARK: - Date Formatter Extension

private extension DateFormatter {
    static let fileNameFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
