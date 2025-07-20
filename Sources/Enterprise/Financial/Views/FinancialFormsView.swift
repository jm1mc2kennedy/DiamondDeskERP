import SwiftUI
import Combine

// MARK: - Create Invoice View

public struct CreateInvoiceView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var invoice = Invoice.empty
    @State private var lineItems: [InvoiceLineItem] = []
    @State private var showingLineItemForm = false
    @State private var editingLineItem: InvoiceLineItem?
    @State private var isGeneratingNumber = false
    
    public var body: some View {
        NavigationView {
            Form {
                invoiceDetailsSection
                clientSection
                lineItemsSection
                paymentTermsSection
                notesSection
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            let finalInvoice = invoice.with(lineItems: lineItems)
                            await viewModel.createInvoice(finalInvoice)
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingLineItemForm) {
                LineItemFormView(
                    lineItem: editingLineItem ?? InvoiceLineItem.empty,
                    onSave: { lineItem in
                        if let editingLineItem = editingLineItem,
                           let index = lineItems.firstIndex(where: { $0.id == editingLineItem.id }) {
                            lineItems[index] = lineItem
                        } else {
                            lineItems.append(lineItem)
                        }
                        editingLineItem = nil
                        showingLineItemForm = false
                    },
                    onCancel: {
                        editingLineItem = nil
                        showingLineItemForm = false
                    }
                )
            }
            .task {
                await generateInvoiceNumber()
            }
        }
    }
    
    private var invoiceDetailsSection: some View {
        Section("Invoice Details") {
            HStack {
                Text("Invoice Number")
                Spacer()
                if isGeneratingNumber {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(invoice.invoiceNumber)
                        .foregroundColor(.secondary)
                }
            }
            
            DatePicker("Issue Date", selection: $invoice.issueDate, displayedComponents: .date)
            
            DatePicker("Due Date", selection: $invoice.dueDate, displayedComponents: .date)
            
            Picker("Currency", selection: $invoice.currency) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text(currency.displayName).tag(currency)
                }
            }
            
            Picker("Status", selection: $invoice.status) {
                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
        }
    }
    
    private var clientSection: some View {
        Section("Client Information") {
            TextField("Client Name", text: $invoice.clientName)
            TextField("Client Email", text: $invoice.clientEmail)
            TextField("Client Address", text: $invoice.clientAddress, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var lineItemsSection: some View {
        Section("Line Items") {
            ForEach(lineItems) { lineItem in
                LineItemRowView(lineItem: lineItem) {
                    editingLineItem = lineItem
                    showingLineItemForm = true
                } onDelete: {
                    if let index = lineItems.firstIndex(where: { $0.id == lineItem.id }) {
                        lineItems.remove(at: index)
                    }
                }
            }
            
            Button {
                showingLineItemForm = true
            } label: {
                Label("Add Line Item", systemImage: "plus")
            }
            
            if !lineItems.isEmpty {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(formatCurrency(subtotal))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Tax")
                    Spacer()
                    Text(formatCurrency(totalTax))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatCurrency(total))
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var paymentTermsSection: some View {
        Section("Payment Terms") {
            TextField("Payment Terms", text: $invoice.paymentTerms, axis: .vertical)
                .lineLimit(2...4)
                .placeholder(when: invoice.paymentTerms.isEmpty) {
                    Text("Net 30, 2% discount if paid within 10 days")
                        .foregroundColor(.secondary)
                }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextField("Additional notes...", text: Binding(
                get: { invoice.notes ?? "" },
                set: { invoice.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
        }
    }
    
    private var isValid: Bool {
        !invoice.clientName.isEmpty &&
        !invoice.clientEmail.isEmpty &&
        !lineItems.isEmpty &&
        total > 0
    }
    
    private var subtotal: Decimal {
        lineItems.reduce(0) { $0 + $1.totalAmount }
    }
    
    private var totalTax: Decimal {
        lineItems.reduce(0) { $0 + $1.taxAmount }
    }
    
    private var total: Decimal {
        subtotal + totalTax
    }
    
    private func generateInvoiceNumber() async {
        isGeneratingNumber = true
        let number = await viewModel.generateInvoiceNumber()
        invoice.invoiceNumber = number
        isGeneratingNumber = false
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Line Item Form View

public struct LineItemFormView: View {
    @State private var lineItem: InvoiceLineItem
    let onSave: (InvoiceLineItem) -> Void
    let onCancel: () -> Void
    
    public init(lineItem: InvoiceLineItem, onSave: @escaping (InvoiceLineItem) -> Void, onCancel: @escaping () -> Void) {
        self._lineItem = State(initialValue: lineItem)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Description", text: $lineItem.description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Quantity", value: $lineItem.quantity, formatter: NumberFormatter.decimal)
                        .keyboardType(.decimalPad)
                    
                    TextField("Unit Price", value: $lineItem.unitPrice, formatter: NumberFormatter.currency)
                        .keyboardType(.decimalPad)
                    
                    if lineItem.taxRate > 0 {
                        TextField("Tax Rate (%)", value: $lineItem.taxRate, formatter: NumberFormatter.percentage)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Calculated Amounts") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatCurrency(lineItem.subtotalAmount))
                            .fontWeight(.medium)
                    }
                    
                    if lineItem.taxAmount > 0 {
                        HStack {
                            Text("Tax")
                            Spacer()
                            Text(formatCurrency(lineItem.taxAmount))
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(lineItem.totalAmount))
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Line Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(lineItem)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !lineItem.description.isEmpty &&
        lineItem.quantity > 0 &&
        lineItem.unitPrice > 0
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Line Item Row View

public struct LineItemRowView: View {
    let lineItem: InvoiceLineItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(lineItem.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Edit") {
                    onEdit()
                }
                .font(.caption)
                
                Button("Delete") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack {
                Text("\(formatDecimal(lineItem.quantity)) × \(formatCurrency(lineItem.unitPrice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(lineItem.totalAmount))
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Create Payment View

public struct CreatePaymentView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var payment = PaymentRecord.empty
    @State private var selectedInvoice: Invoice?
    @State private var isGeneratingNumber = false
    
    public var body: some View {
        NavigationView {
            Form {
                paymentDetailsSection
                amountSection
                methodSection
                notesSection
            }
            .navigationTitle("New Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await viewModel.createPayment(payment)
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .task {
                await generatePaymentNumber()
            }
        }
    }
    
    private var paymentDetailsSection: some View {
        Section("Payment Details") {
            HStack {
                Text("Payment Number")
                Spacer()
                if isGeneratingNumber {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(payment.paymentNumber)
                        .foregroundColor(.secondary)
                }
            }
            
            DatePicker("Payment Date", selection: $payment.paymentDate, displayedComponents: .date)
            
            Picker("Status", selection: $payment.status) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            
            if !viewModel.invoices.isEmpty {
                Picker("Related Invoice", selection: $selectedInvoice) {
                    Text("None").tag(nil as Invoice?)
                    ForEach(viewModel.invoices) { invoice in
                        Text("Invoice \(invoice.invoiceNumber)").tag(invoice as Invoice?)
                    }
                }
                .onChange(of: selectedInvoice) { _, newValue in
                    if let invoice = newValue {
                        payment.invoiceId = invoice.id
                        payment.amount = invoice.totalAmount
                    } else {
                        payment.invoiceId = nil
                    }
                }
            }
        }
    }
    
    private var amountSection: some View {
        Section("Amount") {
            TextField("Amount", value: $payment.amount, formatter: NumberFormatter.currency)
                .keyboardType(.decimalPad)
            
            Picker("Currency", selection: $payment.currency) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text(currency.displayName).tag(currency)
                }
            }
        }
    }
    
    private var methodSection: some View {
        Section("Payment Method") {
            Picker("Method", selection: $payment.paymentMethod) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    Text(method.displayName).tag(method)
                }
            }
            
            if payment.paymentMethod.requiresReference {
                TextField("Reference Number", text: Binding(
                    get: { payment.reference ?? "" },
                    set: { payment.reference = $0.isEmpty ? nil : $0 }
                ))
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextField("Payment notes...", text: Binding(
                get: { payment.notes ?? "" },
                set: { payment.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
        }
    }
    
    private var isValid: Bool {
        !payment.paymentNumber.isEmpty &&
        payment.amount > 0
    }
    
    private func generatePaymentNumber() async {
        isGeneratingNumber = true
        let number = await viewModel.generatePaymentNumber()
        payment.paymentNumber = number
        isGeneratingNumber = false
    }
}

// MARK: - Create Bank Account View

public struct CreateBankAccountView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var account = BankAccount.empty
    
    public var body: some View {
        NavigationView {
            Form {
                accountDetailsSection
                bankDetailsSection
                balanceSection
            }
            .navigationTitle("New Bank Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await viewModel.createBankAccount(account)
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var accountDetailsSection: some View {
        Section("Account Details") {
            TextField("Account Name", text: $account.accountName)
            
            Picker("Account Type", selection: $account.accountType) {
                ForEach(BankAccountType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            TextField("Account Number", text: $account.accountNumber)
                .keyboardType(.numberPad)
        }
    }
    
    private var bankDetailsSection: some View {
        Section("Bank Details") {
            TextField("Bank Name", text: $account.bankName)
            
            TextField("Routing Number", text: Binding(
                get: { account.routingNumber ?? "" },
                set: { account.routingNumber = $0.isEmpty ? nil : $0 }
            ))
            .keyboardType(.numberPad)
            
            TextField("SWIFT Code", text: Binding(
                get: { account.swiftCode ?? "" },
                set: { account.swiftCode = $0.isEmpty ? nil : $0 }
            ))
        }
    }
    
    private var balanceSection: some View {
        Section("Initial Balance") {
            TextField("Balance", value: $account.balance, formatter: NumberFormatter.currency)
                .keyboardType(.decimalPad)
            
            Picker("Currency", selection: $account.currency) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text(currency.displayName).tag(currency)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !account.accountName.isEmpty &&
        !account.bankName.isEmpty &&
        !account.accountNumber.isEmpty
    }
}

// MARK: - Invoice Filters View

public struct InvoiceFiltersView: View {
    @ObservedObject var viewModel: FinancialViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var filter: InvoiceFilter
    
    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
        self._filter = State(initialValue: viewModel.invoiceFilter)
    }
    
    public var body: some View {
        NavigationView {
            Form {
                statusSection
                dateRangeSection
                amountRangeSection
                currencySection
            }
            .navigationTitle("Filter Invoices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        filter = InvoiceFilter()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.updateInvoiceFilter(filter)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        Section("Status") {
            ForEach(InvoiceStatus.allCases, id: \.self) { status in
                HStack {
                    Text(status.displayName)
                    Spacer()
                    if filter.statuses?.contains(status) == true {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if filter.statuses == nil {
                        filter.statuses = Set()
                    }
                    
                    if filter.statuses!.contains(status) {
                        filter.statuses!.remove(status)
                        if filter.statuses!.isEmpty {
                            filter.statuses = nil
                        }
                    } else {
                        filter.statuses!.insert(status)
                    }
                }
            }
        }
    }
    
    private var dateRangeSection: some View {
        Section("Date Range") {
            if let dateRange = filter.dateRange {
                DatePicker("From", selection: Binding(
                    get: { dateRange.start },
                    set: { filter.dateRange = DateRange(start: $0, end: dateRange.end) }
                ), displayedComponents: .date)
                
                DatePicker("To", selection: Binding(
                    get: { dateRange.end },
                    set: { filter.dateRange = DateRange(start: dateRange.start, end: $0) }
                ), displayedComponents: .date)
                
                Button("Clear Date Range") {
                    filter.dateRange = nil
                }
                .foregroundColor(.red)
            } else {
                Button("Set Date Range") {
                    filter.dateRange = DateRange(start: Date(), end: Date())
                }
            }
        }
    }
    
    private var amountRangeSection: some View {
        Section("Amount Range") {
            TextField("Minimum Amount", value: $filter.minAmount, formatter: NumberFormatter.currency)
                .keyboardType(.decimalPad)
            
            TextField("Maximum Amount", value: $filter.maxAmount, formatter: NumberFormatter.currency)
                .keyboardType(.decimalPad)
        }
    }
    
    private var currencySection: some View {
        Section("Currency") {
            ForEach(Currency.allCases, id: \.self) { currency in
                HStack {
                    Text(currency.displayName)
                    Spacer()
                    if filter.currencies?.contains(currency) == true {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if filter.currencies == nil {
                        filter.currencies = Set()
                    }
                    
                    if filter.currencies!.contains(currency) {
                        filter.currencies!.remove(currency)
                        if filter.currencies!.isEmpty {
                            filter.currencies = nil
                        }
                    } else {
                        filter.currencies!.insert(currency)
                    }
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - NumberFormatter Extensions

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// MARK: - Empty State Extensions

extension Invoice {
    static var empty: Invoice {
        return Invoice(
            id: UUID(),
            invoiceNumber: "",
            clientName: "",
            clientEmail: "",
            clientAddress: "",
            issueDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            lineItems: [],
            subtotal: 0,
            taxAmount: 0,
            totalAmount: 0,
            currency: .usd,
            status: .draft,
            paymentTerms: "",
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func with(lineItems: [InvoiceLineItem]) -> Invoice {
        let subtotal = lineItems.reduce(0) { $0 + $1.subtotalAmount }
        let taxAmount = lineItems.reduce(0) { $0 + $1.taxAmount }
        let totalAmount = subtotal + taxAmount
        
        return Invoice(
            id: self.id,
            invoiceNumber: self.invoiceNumber,
            clientName: self.clientName,
            clientEmail: self.clientEmail,
            clientAddress: self.clientAddress,
            issueDate: self.issueDate,
            dueDate: self.dueDate,
            lineItems: lineItems,
            subtotal: subtotal,
            taxAmount: taxAmount,
            totalAmount: totalAmount,
            currency: self.currency,
            status: self.status,
            paymentTerms: self.paymentTerms,
            notes: self.notes,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
}

extension InvoiceLineItem {
    static var empty: InvoiceLineItem {
        return InvoiceLineItem(
            id: UUID(),
            description: "",
            quantity: 1,
            unitPrice: 0,
            taxRate: 0
        )
    }
}

extension PaymentRecord {
    static var empty: PaymentRecord {
        return PaymentRecord(
            id: UUID(),
            paymentNumber: "",
            amount: 0,
            currency: .usd,
            paymentDate: Date(),
            paymentMethod: .bankTransfer,
            status: .pending,
            invoiceId: nil,
            reference: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension BankAccount {
    static var empty: BankAccount {
        return BankAccount(
            id: UUID(),
            accountName: "",
            bankName: "",
            accountNumber: "",
            accountType: .checking,
            routingNumber: nil,
            swiftCode: nil,
            balance: 0,
            currency: .usd,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Payment Method Extensions

extension PaymentMethod {
    var requiresReference: Bool {
        switch self {
        case .check, .wireTransfer, .other:
            return true
        default:
            return false
        }
    }
}
