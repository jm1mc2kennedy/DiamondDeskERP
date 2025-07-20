import XCTest
import Combine
@testable import DiamondDeskERP

// MARK: - Financial Service Tests

@MainActor
final class FinancialServiceTests: XCTestCase {
    private var financialService: FinancialService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        financialService = FinancialService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        financialService = nil
        super.tearDown()
    }
    
    // MARK: - Invoice Tests
    
    func testCreateInvoice() async throws {
        // Given
        let invoice = createTestInvoice()
        
        // When
        let createdInvoice = try await financialService.createInvoice(invoice)
        
        // Then
        XCTAssertEqual(createdInvoice.invoiceNumber, invoice.invoiceNumber)
        XCTAssertEqual(createdInvoice.clientName, invoice.clientName)
        XCTAssertEqual(createdInvoice.totalAmount, invoice.totalAmount)
        XCTAssertTrue(financialService.invoices.contains { $0.id == createdInvoice.id })
    }
    
    func testUpdateInvoice() async throws {
        // Given
        let invoice = createTestInvoice()
        let createdInvoice = try await financialService.createInvoice(invoice)
        
        // When
        var updatedInvoice = createdInvoice
        updatedInvoice.clientName = "Updated Client"
        updatedInvoice.status = .sent
        
        let result = try await financialService.updateInvoice(updatedInvoice)
        
        // Then
        XCTAssertEqual(result.clientName, "Updated Client")
        XCTAssertEqual(result.status, .sent)
        XCTAssertTrue(result.updatedAt > createdInvoice.updatedAt)
    }
    
    func testDeleteInvoice() async throws {
        // Given
        let invoice = createTestInvoice()
        let createdInvoice = try await financialService.createInvoice(invoice)
        
        // When
        try await financialService.deleteInvoice(createdInvoice)
        
        // Then
        XCTAssertFalse(financialService.invoices.contains { $0.id == createdInvoice.id })
    }
    
    func testFetchInvoices() async throws {
        // Given
        let invoice1 = createTestInvoice(clientName: "Client 1")
        let invoice2 = createTestInvoice(clientName: "Client 2")
        
        _ = try await financialService.createInvoice(invoice1)
        _ = try await financialService.createInvoice(invoice2)
        
        // When
        let fetchedInvoices = try await financialService.fetchInvoices()
        
        // Then
        XCTAssertGreaterThanOrEqual(fetchedInvoices.count, 2)
        XCTAssertTrue(fetchedInvoices.contains { $0.clientName == "Client 1" })
        XCTAssertTrue(fetchedInvoices.contains { $0.clientName == "Client 2" })
    }
    
    func testSearchInvoices() async throws {
        // Given
        let invoice1 = createTestInvoice(clientName: "Apple Inc.")
        let invoice2 = createTestInvoice(clientName: "Google LLC")
        
        _ = try await financialService.createInvoice(invoice1)
        _ = try await financialService.createInvoice(invoice2)
        
        // When
        let results = try await financialService.searchInvoices(query: "Apple")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.clientName, "Apple Inc.")
    }
    
    func testFilterInvoices() async throws {
        // Given
        let paidInvoice = createTestInvoice(status: .paid)
        let sentInvoice = createTestInvoice(status: .sent)
        let draftInvoice = createTestInvoice(status: .draft)
        
        _ = try await financialService.createInvoice(paidInvoice)
        _ = try await financialService.createInvoice(sentInvoice)
        _ = try await financialService.createInvoice(draftInvoice)
        
        // When
        let filter = InvoiceFilter(statuses: Set([.paid, .sent]))
        let results = try await financialService.filterInvoices(filter: filter)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.status == .paid || $0.status == .sent })
    }
    
    func testDuplicateInvoice() async throws {
        // Given
        let originalInvoice = createTestInvoice()
        let createdInvoice = try await financialService.createInvoice(originalInvoice)
        
        // When
        let duplicatedInvoice = try await financialService.duplicateInvoice(createdInvoice)
        
        // Then
        XCTAssertNotEqual(duplicatedInvoice.id, createdInvoice.id)
        XCTAssertNotEqual(duplicatedInvoice.invoiceNumber, createdInvoice.invoiceNumber)
        XCTAssertEqual(duplicatedInvoice.clientName, createdInvoice.clientName)
        XCTAssertEqual(duplicatedInvoice.totalAmount, createdInvoice.totalAmount)
        XCTAssertEqual(duplicatedInvoice.status, .draft)
    }
    
    func testSendInvoice() async throws {
        // Given
        let invoice = createTestInvoice(status: .draft)
        let createdInvoice = try await financialService.createInvoice(invoice)
        
        // When
        let sentInvoice = try await financialService.sendInvoice(createdInvoice)
        
        // Then
        XCTAssertEqual(sentInvoice.status, .sent)
        XCTAssertTrue(sentInvoice.updatedAt > createdInvoice.updatedAt)
    }
    
    // MARK: - Payment Tests
    
    func testCreatePayment() async throws {
        // Given
        let payment = createTestPayment()
        
        // When
        let createdPayment = try await financialService.createPayment(payment)
        
        // Then
        XCTAssertEqual(createdPayment.paymentNumber, payment.paymentNumber)
        XCTAssertEqual(createdPayment.amount, payment.amount)
        XCTAssertEqual(createdPayment.paymentMethod, payment.paymentMethod)
        XCTAssertTrue(financialService.payments.contains { $0.id == createdPayment.id })
    }
    
    func testUpdatePayment() async throws {
        // Given
        let payment = createTestPayment()
        let createdPayment = try await financialService.createPayment(payment)
        
        // When
        var updatedPayment = createdPayment
        updatedPayment.status = .completed
        updatedPayment.amount = 2000
        
        let result = try await financialService.updatePayment(updatedPayment)
        
        // Then
        XCTAssertEqual(result.status, .completed)
        XCTAssertEqual(result.amount, 2000)
        XCTAssertTrue(result.updatedAt > createdPayment.updatedAt)
    }
    
    func testDeletePayment() async throws {
        // Given
        let payment = createTestPayment()
        let createdPayment = try await financialService.createPayment(payment)
        
        // When
        try await financialService.deletePayment(createdPayment)
        
        // Then
        XCTAssertFalse(financialService.payments.contains { $0.id == createdPayment.id })
    }
    
    // MARK: - Bank Account Tests
    
    func testCreateBankAccount() async throws {
        // Given
        let account = createTestBankAccount()
        
        // When
        let createdAccount = try await financialService.createBankAccount(account)
        
        // Then
        XCTAssertEqual(createdAccount.accountName, account.accountName)
        XCTAssertEqual(createdAccount.bankName, account.bankName)
        XCTAssertEqual(createdAccount.balance, account.balance)
        XCTAssertTrue(financialService.bankAccounts.contains { $0.id == createdAccount.id })
    }
    
    func testUpdateBankAccount() async throws {
        // Given
        let account = createTestBankAccount()
        let createdAccount = try await financialService.createBankAccount(account)
        
        // When
        var updatedAccount = createdAccount
        updatedAccount.balance = 50000
        updatedAccount.accountName = "Updated Account"
        
        let result = try await financialService.updateBankAccount(updatedAccount)
        
        // Then
        XCTAssertEqual(result.balance, 50000)
        XCTAssertEqual(result.accountName, "Updated Account")
        XCTAssertTrue(result.updatedAt > createdAccount.updatedAt)
    }
    
    func testDeleteBankAccount() async throws {
        // Given
        let account = createTestBankAccount()
        let createdAccount = try await financialService.createBankAccount(account)
        
        // When
        try await financialService.deleteBankAccount(createdAccount)
        
        // Then
        XCTAssertFalse(financialService.bankAccounts.contains { $0.id == createdAccount.id })
    }
    
    // MARK: - Analytics Tests
    
    func testGenerateFinancialAnalytics() async throws {
        // Given
        let paidInvoice = createTestInvoice(status: .paid, totalAmount: 1000)
        let sentInvoice = createTestInvoice(status: .sent, totalAmount: 2000)
        let overdueInvoice = createTestInvoice(status: .overdue, totalAmount: 1500)
        
        _ = try await financialService.createInvoice(paidInvoice)
        _ = try await financialService.createInvoice(sentInvoice)
        _ = try await financialService.createInvoice(overdueInvoice)
        
        // When
        let analytics = try await financialService.generateFinancialAnalytics()
        
        // Then
        XCTAssertEqual(analytics.totalInvoices, 3)
        XCTAssertEqual(analytics.paidInvoices, 1)
        XCTAssertEqual(analytics.sentInvoices, 1)
        XCTAssertEqual(analytics.overdueInvoices, 1)
        XCTAssertEqual(analytics.totalRevenue, 1000) // Only paid invoices count as revenue
        XCTAssertEqual(analytics.outstandingAmount, 3500) // Sent + Overdue
        XCTAssertEqual(analytics.overdueAmount, 1500)
        XCTAssertEqual(analytics.averageInvoiceAmount, 1500) // (1000 + 2000 + 1500) / 3
    }
    
    // MARK: - Bulk Operations Tests
    
    func testBulkUpdateInvoiceStatus() async throws {
        // Given
        let invoice1 = createTestInvoice(status: .draft)
        let invoice2 = createTestInvoice(status: .draft)
        let createdInvoice1 = try await financialService.createInvoice(invoice1)
        let createdInvoice2 = try await financialService.createInvoice(invoice2)
        
        // When
        try await financialService.bulkUpdateInvoiceStatus([createdInvoice1.id, createdInvoice2.id], status: .sent)
        
        // Then
        let updatedInvoices = financialService.invoices.filter { $0.id == createdInvoice1.id || $0.id == createdInvoice2.id }
        XCTAssertTrue(updatedInvoices.allSatisfy { $0.status == .sent })
    }
    
    func testBulkDeleteInvoices() async throws {
        // Given
        let invoice1 = createTestInvoice()
        let invoice2 = createTestInvoice()
        let createdInvoice1 = try await financialService.createInvoice(invoice1)
        let createdInvoice2 = try await financialService.createInvoice(invoice2)
        
        // When
        try await financialService.bulkDeleteInvoices([createdInvoice1.id, createdInvoice2.id])
        
        // Then
        XCTAssertFalse(financialService.invoices.contains { $0.id == createdInvoice1.id })
        XCTAssertFalse(financialService.invoices.contains { $0.id == createdInvoice2.id })
    }
    
    // MARK: - Number Generation Tests
    
    func testGenerateInvoiceNumber() async {
        // When
        let number1 = await financialService.generateInvoiceNumber()
        let number2 = await financialService.generateInvoiceNumber()
        
        // Then
        XCTAssertNotEqual(number1, number2)
        XCTAssertTrue(number1.hasPrefix("INV-"))
        XCTAssertTrue(number2.hasPrefix("INV-"))
    }
    
    func testGeneratePaymentNumber() async {
        // When
        let number1 = await financialService.generatePaymentNumber()
        let number2 = await financialService.generatePaymentNumber()
        
        // Then
        XCTAssertNotEqual(number1, number2)
        XCTAssertTrue(number1.hasPrefix("PAY-"))
        XCTAssertTrue(number2.hasPrefix("PAY-"))
    }
    
    // MARK: - Export Tests
    
    func testExportInvoicesToCSV() async throws {
        // Given
        let invoice = createTestInvoice()
        _ = try await financialService.createInvoice(invoice)
        
        // When
        let url = try await financialService.exportInvoicesToCSV()
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.hasSuffix(".csv"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportPaymentsToCSV() async throws {
        // Given
        let payment = createTestPayment()
        _ = try await financialService.createPayment(payment)
        
        // When
        let url = try await financialService.exportPaymentsToCSV()
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.hasSuffix(".csv"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Helper Methods
    
    private func createTestInvoice(
        clientName: String = "Test Client",
        status: InvoiceStatus = .draft,
        totalAmount: Decimal = 1000
    ) -> Invoice {
        let lineItem = InvoiceLineItem(
            id: UUID(),
            description: "Test Service",
            quantity: 1,
            unitPrice: totalAmount,
            taxRate: 0
        )
        
        return Invoice(
            id: UUID(),
            invoiceNumber: "INV-TEST-\(UUID().uuidString.prefix(8))",
            clientName: clientName,
            clientEmail: "test@example.com",
            clientAddress: "123 Test St",
            issueDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            lineItems: [lineItem],
            subtotal: totalAmount,
            taxAmount: 0,
            totalAmount: totalAmount,
            currency: .usd,
            status: status,
            paymentTerms: "Net 30",
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestPayment() -> PaymentRecord {
        return PaymentRecord(
            id: UUID(),
            paymentNumber: "PAY-TEST-\(UUID().uuidString.prefix(8))",
            amount: 1000,
            currency: .usd,
            paymentDate: Date(),
            paymentMethod: .bankTransfer,
            status: .pending,
            invoiceId: nil,
            reference: "TEST-REF",
            notes: "Test payment",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestBankAccount() -> BankAccount {
        return BankAccount(
            id: UUID(),
            accountName: "Test Checking Account",
            bankName: "Test Bank",
            accountNumber: "1234567890",
            accountType: .checking,
            routingNumber: "123456789",
            swiftCode: "TESTUS33",
            balance: 10000,
            currency: .usd,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Financial View Model Tests

@MainActor
final class FinancialViewModelTests: XCTestCase {
    private var viewModel: FinancialViewModel!
    private var mockService: MockFinancialService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockService = MockFinancialService()
        viewModel = FinancialViewModel(financialService: mockService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.selectedTab, .invoices)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.invoices.isEmpty)
        XCTAssertTrue(viewModel.payments.isEmpty)
        XCTAssertTrue(viewModel.bankAccounts.isEmpty)
    }
    
    func testLoadData() async {
        // Given
        let testInvoice = createTestInvoice()
        let testPayment = createTestPayment()
        let testAccount = createTestBankAccount()
        
        mockService.invoicesData = [testInvoice]
        mockService.paymentsData = [testPayment]
        mockService.bankAccountsData = [testAccount]
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertEqual(viewModel.invoices.count, 1)
        XCTAssertEqual(viewModel.payments.count, 1)
        XCTAssertEqual(viewModel.bankAccounts.count, 1)
        XCTAssertEqual(viewModel.invoices.first?.id, testInvoice.id)
        XCTAssertEqual(viewModel.payments.first?.id, testPayment.id)
        XCTAssertEqual(viewModel.bankAccounts.first?.id, testAccount.id)
    }
    
    func testCreateInvoice() async {
        // Given
        let testInvoice = createTestInvoice()
        viewModel.showingCreateInvoice = true
        
        // When
        await viewModel.createInvoice(testInvoice)
        
        // Then
        XCTAssertFalse(viewModel.showingCreateInvoice)
        XCTAssertTrue(mockService.createInvoiceCalled)
        XCTAssertEqual(mockService.lastCreatedInvoice?.id, testInvoice.id)
    }
    
    func testUpdateInvoice() async {
        // Given
        let testInvoice = createTestInvoice()
        
        // When
        await viewModel.updateInvoice(testInvoice)
        
        // Then
        XCTAssertTrue(mockService.updateInvoiceCalled)
        XCTAssertEqual(mockService.lastUpdatedInvoice?.id, testInvoice.id)
    }
    
    func testDeleteInvoice() async {
        // Given
        let testInvoice = createTestInvoice()
        viewModel.selectedInvoice = testInvoice
        
        // When
        await viewModel.deleteInvoice(testInvoice)
        
        // Then
        XCTAssertNil(viewModel.selectedInvoice)
        XCTAssertTrue(mockService.deleteInvoiceCalled)
        XCTAssertEqual(mockService.lastDeletedInvoice?.id, testInvoice.id)
    }
    
    func testSelectInvoice() {
        // Given
        let testInvoice = createTestInvoice()
        
        // When
        viewModel.selectInvoice(testInvoice)
        
        // Then
        XCTAssertEqual(viewModel.selectedInvoice?.id, testInvoice.id)
    }
    
    func testBulkActions() async {
        // Given
        let invoice1 = createTestInvoice()
        let invoice2 = createTestInvoice()
        viewModel.selectedInvoiceIds = Set([invoice1.id, invoice2.id])
        viewModel.showingBulkActions = true
        
        // When
        await viewModel.performBulkAction(.markAsSent)
        
        // Then
        XCTAssertTrue(viewModel.selectedInvoiceIds.isEmpty)
        XCTAssertFalse(viewModel.showingBulkActions)
        XCTAssertTrue(mockService.bulkUpdateInvoiceStatusCalled)
    }
    
    func testToggleInvoiceSelection() {
        // Given
        let invoiceId = UUID()
        
        // When - First toggle (select)
        viewModel.toggleInvoiceSelection(invoiceId)
        
        // Then
        XCTAssertTrue(viewModel.selectedInvoiceIds.contains(invoiceId))
        
        // When - Second toggle (deselect)
        viewModel.toggleInvoiceSelection(invoiceId)
        
        // Then
        XCTAssertFalse(viewModel.selectedInvoiceIds.contains(invoiceId))
    }
    
    func testSelectAllInvoices() {
        // Given
        let invoice1 = createTestInvoice()
        let invoice2 = createTestInvoice()
        viewModel.filteredInvoices = [invoice1, invoice2]
        
        // When
        viewModel.selectAllInvoices()
        
        // Then
        XCTAssertEqual(viewModel.selectedInvoiceIds.count, 2)
        XCTAssertTrue(viewModel.selectedInvoiceIds.contains(invoice1.id))
        XCTAssertTrue(viewModel.selectedInvoiceIds.contains(invoice2.id))
    }
    
    func testDeselectAllInvoices() {
        // Given
        viewModel.selectedInvoiceIds = Set([UUID(), UUID()])
        
        // When
        viewModel.deselectAllInvoices()
        
        // Then
        XCTAssertTrue(viewModel.selectedInvoiceIds.isEmpty)
    }
    
    func testErrorHandling() async {
        // Given
        mockService.shouldThrowError = true
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertNotNil(viewModel.error)
    }
    
    func testClearError() {
        // Given
        viewModel.error = NSError(domain: "test", code: 1, userInfo: nil)
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Helper Methods
    
    private func createTestInvoice() -> Invoice {
        let lineItem = InvoiceLineItem(
            id: UUID(),
            description: "Test Service",
            quantity: 1,
            unitPrice: 1000,
            taxRate: 0
        )
        
        return Invoice(
            id: UUID(),
            invoiceNumber: "INV-TEST-001",
            clientName: "Test Client",
            clientEmail: "test@example.com",
            clientAddress: "123 Test St",
            issueDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            lineItems: [lineItem],
            subtotal: 1000,
            taxAmount: 0,
            totalAmount: 1000,
            currency: .usd,
            status: .draft,
            paymentTerms: "Net 30",
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestPayment() -> PaymentRecord {
        return PaymentRecord(
            id: UUID(),
            paymentNumber: "PAY-TEST-001",
            amount: 1000,
            currency: .usd,
            paymentDate: Date(),
            paymentMethod: .bankTransfer,
            status: .pending,
            invoiceId: nil,
            reference: "TEST-REF",
            notes: "Test payment",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestBankAccount() -> BankAccount {
        return BankAccount(
            id: UUID(),
            accountName: "Test Checking Account",
            bankName: "Test Bank",
            accountNumber: "1234567890",
            accountType: .checking,
            routingNumber: "123456789",
            swiftCode: "TESTUS33",
            balance: 10000,
            currency: .usd,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Financial Service

final class MockFinancialService: FinancialService {
    var invoicesData: [Invoice] = []
    var paymentsData: [PaymentRecord] = []
    var bankAccountsData: [BankAccount] = []
    var shouldThrowError = false
    
    // Tracking called methods
    var createInvoiceCalled = false
    var updateInvoiceCalled = false
    var deleteInvoiceCalled = false
    var bulkUpdateInvoiceStatusCalled = false
    
    var lastCreatedInvoice: Invoice?
    var lastUpdatedInvoice: Invoice?
    var lastDeletedInvoice: Invoice?
    
    override func fetchInvoices() async throws -> [Invoice] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        invoices = invoicesData
        return invoicesData
    }
    
    override func fetchPayments() async throws -> [PaymentRecord] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        payments = paymentsData
        return paymentsData
    }
    
    override func fetchBankAccounts() async throws -> [BankAccount] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        bankAccounts = bankAccountsData
        return bankAccountsData
    }
    
    override func createInvoice(_ invoice: Invoice) async throws -> Invoice {
        createInvoiceCalled = true
        lastCreatedInvoice = invoice
        
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        
        invoicesData.append(invoice)
        invoices = invoicesData
        return invoice
    }
    
    override func updateInvoice(_ invoice: Invoice) async throws -> Invoice {
        updateInvoiceCalled = true
        lastUpdatedInvoice = invoice
        
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        
        return invoice
    }
    
    override func deleteInvoice(_ invoice: Invoice) async throws {
        deleteInvoiceCalled = true
        lastDeletedInvoice = invoice
        
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        
        invoicesData.removeAll { $0.id == invoice.id }
        invoices = invoicesData
    }
    
    override func bulkUpdateInvoiceStatus(_ invoiceIds: [UUID], status: InvoiceStatus) async throws {
        bulkUpdateInvoiceStatusCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
}

// MARK: - Financial Models Tests

final class FinancialModelsTests: XCTestCase {
    
    func testInvoiceLineItemCalculations() {
        // Given
        let lineItem = InvoiceLineItem(
            id: UUID(),
            description: "Test Item",
            quantity: 2,
            unitPrice: 100,
            taxRate: 0.1 // 10%
        )
        
        // Then
        XCTAssertEqual(lineItem.subtotalAmount, 200) // 2 * 100
        XCTAssertEqual(lineItem.taxAmount, 20) // 200 * 0.1
        XCTAssertEqual(lineItem.totalAmount, 220) // 200 + 20
    }
    
    func testInvoiceIsOverdue() {
        // Given - Overdue invoice
        let overdueDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let overdueInvoice = Invoice(
            id: UUID(),
            invoiceNumber: "INV-001",
            clientName: "Test Client",
            clientEmail: "test@example.com",
            clientAddress: "123 Test St",
            issueDate: Date(),
            dueDate: overdueDate,
            lineItems: [],
            subtotal: 1000,
            taxAmount: 100,
            totalAmount: 1100,
            currency: .usd,
            status: .sent,
            paymentTerms: "Net 30",
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertTrue(overdueInvoice.isOverdue)
        
        // Given - Not overdue invoice
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let notOverdueInvoice = Invoice(
            id: UUID(),
            invoiceNumber: "INV-002",
            clientName: "Test Client",
            clientEmail: "test@example.com",
            clientAddress: "123 Test St",
            issueDate: Date(),
            dueDate: futureDate,
            lineItems: [],
            subtotal: 1000,
            taxAmount: 100,
            totalAmount: 1100,
            currency: .usd,
            status: .sent,
            paymentTerms: "Net 30",
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertFalse(notOverdueInvoice.isOverdue)
    }
    
    func testCurrencyDisplayName() {
        XCTAssertEqual(Currency.usd.displayName, "USD ($)")
        XCTAssertEqual(Currency.eur.displayName, "EUR (€)")
        XCTAssertEqual(Currency.gbp.displayName, "GBP (£)")
        XCTAssertEqual(Currency.jpy.displayName, "JPY (¥)")
        XCTAssertEqual(Currency.cad.displayName, "CAD (CA$)")
        XCTAssertEqual(Currency.aud.displayName, "AUD (AU$)")
    }
    
    func testInvoiceStatusDisplayName() {
        XCTAssertEqual(InvoiceStatus.draft.displayName, "Draft")
        XCTAssertEqual(InvoiceStatus.sent.displayName, "Sent")
        XCTAssertEqual(InvoiceStatus.paid.displayName, "Paid")
        XCTAssertEqual(InvoiceStatus.overdue.displayName, "Overdue")
        XCTAssertEqual(InvoiceStatus.cancelled.displayName, "Cancelled")
    }
    
    func testPaymentStatusDisplayName() {
        XCTAssertEqual(PaymentStatus.pending.displayName, "Pending")
        XCTAssertEqual(PaymentStatus.processing.displayName, "Processing")
        XCTAssertEqual(PaymentStatus.completed.displayName, "Completed")
        XCTAssertEqual(PaymentStatus.failed.displayName, "Failed")
        XCTAssertEqual(PaymentStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(PaymentStatus.refunded.displayName, "Refunded")
    }
    
    func testPaymentMethodDisplayName() {
        XCTAssertEqual(PaymentMethod.cash.displayName, "Cash")
        XCTAssertEqual(PaymentMethod.check.displayName, "Check")
        XCTAssertEqual(PaymentMethod.creditCard.displayName, "Credit Card")
        XCTAssertEqual(PaymentMethod.debitCard.displayName, "Debit Card")
        XCTAssertEqual(PaymentMethod.bankTransfer.displayName, "Bank Transfer")
        XCTAssertEqual(PaymentMethod.wireTransfer.displayName, "Wire Transfer")
        XCTAssertEqual(PaymentMethod.paypal.displayName, "PayPal")
        XCTAssertEqual(PaymentMethod.stripe.displayName, "Stripe")
        XCTAssertEqual(PaymentMethod.other.displayName, "Other")
    }
    
    func testBankAccountTypeDisplayName() {
        XCTAssertEqual(BankAccountType.checking.displayName, "Checking")
        XCTAssertEqual(BankAccountType.savings.displayName, "Savings")
        XCTAssertEqual(BankAccountType.business.displayName, "Business")
        XCTAssertEqual(BankAccountType.moneyMarket.displayName, "Money Market")
        XCTAssertEqual(BankAccountType.other.displayName, "Other")
    }
}

// MARK: - Integration Tests

final class FinancialIntegrationTests: XCTestCase {
    
    func testCompleteInvoiceWorkflow() async throws {
        // Given
        let service = FinancialService()
        
        // Create invoice
        let invoice = createTestInvoice()
        let createdInvoice = try await service.createInvoice(invoice)
        
        // Send invoice
        let sentInvoice = try await service.sendInvoice(createdInvoice)
        XCTAssertEqual(sentInvoice.status, .sent)
        
        // Create payment for the invoice
        var payment = createTestPayment()
        payment.invoiceId = sentInvoice.id
        payment.amount = sentInvoice.totalAmount
        let createdPayment = try await service.createPayment(payment)
        
        // Update payment to completed
        var completedPayment = createdPayment
        completedPayment.status = .completed
        let finalPayment = try await service.updatePayment(completedPayment)
        
        XCTAssertEqual(finalPayment.status, .completed)
        XCTAssertEqual(finalPayment.invoiceId, sentInvoice.id)
    }
    
    private func createTestInvoice() -> Invoice {
        let lineItem = InvoiceLineItem(
            id: UUID(),
            description: "Integration Test Service",
            quantity: 1,
            unitPrice: 1500,
            taxRate: 0.1
        )
        
        return Invoice(
            id: UUID(),
            invoiceNumber: "INV-INT-001",
            clientName: "Integration Test Client",
            clientEmail: "integration@test.com",
            clientAddress: "123 Integration St",
            issueDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            lineItems: [lineItem],
            subtotal: 1500,
            taxAmount: 150,
            totalAmount: 1650,
            currency: .usd,
            status: .draft,
            paymentTerms: "Net 30",
            notes: "Integration test invoice",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestPayment() -> PaymentRecord {
        return PaymentRecord(
            id: UUID(),
            paymentNumber: "PAY-INT-001",
            amount: 1650,
            currency: .usd,
            paymentDate: Date(),
            paymentMethod: .bankTransfer,
            status: .pending,
            invoiceId: nil,
            reference: "INT-TEST-REF",
            notes: "Integration test payment",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
