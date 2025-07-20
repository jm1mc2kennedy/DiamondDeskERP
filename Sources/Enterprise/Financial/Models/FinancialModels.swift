import Foundation
import CloudKit

// MARK: - Financial Management Models

// MARK: - Invoice Models

public struct Invoice: Identifiable, Codable, Hashable {
    public let id: UUID
    public let invoiceNumber: String
    public let clientId: UUID
    public let clientName: String
    public let issueDate: Date
    public let dueDate: Date
    public let status: InvoiceStatus
    public let subtotal: Decimal
    public let taxAmount: Decimal
    public let discountAmount: Decimal
    public let totalAmount: Decimal
    public let currency: Currency
    public let lineItems: [InvoiceLineItem]
    public let paymentTerms: InvoicePaymentTerms
    public let notes: String?
    public let attachments: [DocumentAttachment]
    public let billingAddress: Address
    public let shippingAddress: Address?
    public let taxDetails: TaxDetails
    public let paymentHistory: [PaymentRecord]
    public let recurringSettings: RecurringInvoiceSettings?
    public let createdBy: UUID
    public let createdAt: Date
    public let lastModified: Date
    public let lastModifiedBy: UUID
    
    public init(
        id: UUID = UUID(),
        invoiceNumber: String,
        clientId: UUID,
        clientName: String,
        issueDate: Date = Date(),
        dueDate: Date,
        status: InvoiceStatus = .draft,
        subtotal: Decimal,
        taxAmount: Decimal = 0,
        discountAmount: Decimal = 0,
        totalAmount: Decimal,
        currency: Currency = .usd,
        lineItems: [InvoiceLineItem] = [],
        paymentTerms: InvoicePaymentTerms,
        notes: String? = nil,
        attachments: [DocumentAttachment] = [],
        billingAddress: Address,
        shippingAddress: Address? = nil,
        taxDetails: TaxDetails,
        paymentHistory: [PaymentRecord] = [],
        recurringSettings: RecurringInvoiceSettings? = nil,
        createdBy: UUID,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        lastModifiedBy: UUID
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.clientId = clientId
        self.clientName = clientName
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.status = status
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.discountAmount = discountAmount
        self.totalAmount = totalAmount
        self.currency = currency
        self.lineItems = lineItems
        self.paymentTerms = paymentTerms
        self.notes = notes
        self.attachments = attachments
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
        self.taxDetails = taxDetails
        self.paymentHistory = paymentHistory
        self.recurringSettings = recurringSettings
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.lastModifiedBy = lastModifiedBy
    }
}

public enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case sent = "sent"
    case viewed = "viewed"
    case partiallyPaid = "partially_paid"
    case paid = "paid"
    case overdue = "overdue"
    case cancelled = "cancelled"
    case refunded = "refunded"
    
    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .viewed: return "Viewed"
        case .partiallyPaid: return "Partially Paid"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        }
    }
    
    public var color: String {
        switch self {
        case .draft: return "gray"
        case .sent: return "blue"
        case .viewed: return "orange"
        case .partiallyPaid: return "yellow"
        case .paid: return "green"
        case .overdue: return "red"
        case .cancelled: return "gray"
        case .refunded: return "purple"
        }
    }
}

public struct InvoiceLineItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public let description: String
    public let quantity: Decimal
    public let unitPrice: Decimal
    public let discountPercentage: Decimal
    public let taxRate: Decimal
    public let totalAmount: Decimal
    public let productId: UUID?
    public let serviceId: UUID?
    public let category: String
    public let notes: String?
    
    public init(
        id: UUID = UUID(),
        description: String,
        quantity: Decimal,
        unitPrice: Decimal,
        discountPercentage: Decimal = 0,
        taxRate: Decimal = 0,
        totalAmount: Decimal,
        productId: UUID? = nil,
        serviceId: UUID? = nil,
        category: String,
        notes: String? = nil
    ) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.discountPercentage = discountPercentage
        self.taxRate = taxRate
        self.totalAmount = totalAmount
        self.productId = productId
        self.serviceId = serviceId
        self.category = category
        self.notes = notes
    }
}

public struct InvoicePaymentTerms: Codable, Hashable {
    public let terms: PaymentTermsType
    public let dueDays: Int
    public let lateFeePercentage: Decimal
    public let lateFeeAmount: Decimal?
    public let earlyPaymentDiscountPercentage: Decimal?
    public let earlyPaymentDiscountDays: Int?
    public let acceptedPaymentMethods: [PaymentMethod]
    
    public init(
        terms: PaymentTermsType,
        dueDays: Int,
        lateFeePercentage: Decimal = 0,
        lateFeeAmount: Decimal? = nil,
        earlyPaymentDiscountPercentage: Decimal? = nil,
        earlyPaymentDiscountDays: Int? = nil,
        acceptedPaymentMethods: [PaymentMethod] = [.check, .bankTransfer]
    ) {
        self.terms = terms
        self.dueDays = dueDays
        self.lateFeePercentage = lateFeePercentage
        self.lateFeeAmount = lateFeeAmount
        self.earlyPaymentDiscountPercentage = earlyPaymentDiscountPercentage
        self.earlyPaymentDiscountDays = earlyPaymentDiscountDays
        self.acceptedPaymentMethods = acceptedPaymentMethods
    }
}

public enum PaymentTermsType: String, Codable, CaseIterable {
    case net15 = "net15"
    case net30 = "net30"
    case net60 = "net60"
    case net90 = "net90"
    case dueOnReceipt = "due_on_receipt"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .net15: return "Net 15"
        case .net30: return "Net 30"
        case .net60: return "Net 60"
        case .net90: return "Net 90"
        case .dueOnReceipt: return "Due on Receipt"
        case .custom: return "Custom"
        }
    }
}

public struct RecurringInvoiceSettings: Codable, Hashable {
    public let isRecurring: Bool
    public let frequency: RecurringFrequency
    public let intervalCount: Int
    public let endDate: Date?
    public let remainingOccurrences: Int?
    public let nextInvoiceDate: Date
    public let autoSend: Bool
    public let template: String?
    
    public init(
        isRecurring: Bool = false,
        frequency: RecurringFrequency,
        intervalCount: Int = 1,
        endDate: Date? = nil,
        remainingOccurrences: Int? = nil,
        nextInvoiceDate: Date,
        autoSend: Bool = false,
        template: String? = nil
    ) {
        self.isRecurring = isRecurring
        self.frequency = frequency
        self.intervalCount = intervalCount
        self.endDate = endDate
        self.remainingOccurrences = remainingOccurrences
        self.nextInvoiceDate = nextInvoiceDate
        self.autoSend = autoSend
        self.template = template
    }
}

public enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annually = "annually"
    
    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annually: return "Annually"
        }
    }
}

// MARK: - Payment Models

public struct PaymentRecord: Identifiable, Codable, Hashable {
    public let id: UUID
    public let invoiceId: UUID
    public let paymentNumber: String
    public let amount: Decimal
    public let currency: Currency
    public let paymentDate: Date
    public let paymentMethod: PaymentMethod
    public let status: PaymentStatus
    public let transactionId: String?
    public let gatewayTransactionId: String?
    public let notes: String?
    public let fees: PaymentFees?
    public let refunds: [RefundRecord]
    public let paymentGateway: PaymentGateway?
    public let bankAccount: BankAccount?
    public let checkDetails: CheckDetails?
    public let processedBy: UUID
    public let processedAt: Date
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        invoiceId: UUID,
        paymentNumber: String,
        amount: Decimal,
        currency: Currency = .usd,
        paymentDate: Date = Date(),
        paymentMethod: PaymentMethod,
        status: PaymentStatus = .pending,
        transactionId: String? = nil,
        gatewayTransactionId: String? = nil,
        notes: String? = nil,
        fees: PaymentFees? = nil,
        refunds: [RefundRecord] = [],
        paymentGateway: PaymentGateway? = nil,
        bankAccount: BankAccount? = nil,
        checkDetails: CheckDetails? = nil,
        processedBy: UUID,
        processedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.invoiceId = invoiceId
        self.paymentNumber = paymentNumber
        self.amount = amount
        self.currency = currency
        self.paymentDate = paymentDate
        self.paymentMethod = paymentMethod
        self.status = status
        self.transactionId = transactionId
        self.gatewayTransactionId = gatewayTransactionId
        self.notes = notes
        self.fees = fees
        self.refunds = refunds
        self.paymentGateway = paymentGateway
        self.bankAccount = bankAccount
        self.checkDetails = checkDetails
        self.processedBy = processedBy
        self.processedAt = processedAt
        self.createdAt = createdAt
    }
}

public enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"
    case check = "check"
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case bankTransfer = "bank_transfer"
    case ach = "ach"
    case wire = "wire"
    case paypal = "paypal"
    case stripe = "stripe"
    case square = "square"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case cryptocurrency = "cryptocurrency"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .check: return "Check"
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .bankTransfer: return "Bank Transfer"
        case .ach: return "ACH"
        case .wire: return "Wire Transfer"
        case .paypal: return "PayPal"
        case .stripe: return "Stripe"
        case .square: return "Square"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .cryptocurrency: return "Cryptocurrency"
        case .other: return "Other"
        }
    }
}

public enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case refunded = "refunded"
    case partiallyRefunded = "partially_refunded"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        case .partiallyRefunded: return "Partially Refunded"
        }
    }
}

public struct PaymentFees: Codable, Hashable {
    public let processingFee: Decimal
    public let transactionFee: Decimal
    public let gatewayFee: Decimal
    public let otherFees: Decimal
    public let totalFees: Decimal
    public let feeDescription: String?
    
    public init(
        processingFee: Decimal = 0,
        transactionFee: Decimal = 0,
        gatewayFee: Decimal = 0,
        otherFees: Decimal = 0,
        totalFees: Decimal,
        feeDescription: String? = nil
    ) {
        self.processingFee = processingFee
        self.transactionFee = transactionFee
        self.gatewayFee = gatewayFee
        self.otherFees = otherFees
        self.totalFees = totalFees
        self.feeDescription = feeDescription
    }
}

public struct RefundRecord: Identifiable, Codable, Hashable {
    public let id: UUID
    public let amount: Decimal
    public let reason: String
    public let refundDate: Date
    public let status: RefundStatus
    public let gatewayRefundId: String?
    public let processedBy: UUID
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        reason: String,
        refundDate: Date = Date(),
        status: RefundStatus = .pending,
        gatewayRefundId: String? = nil,
        processedBy: UUID
    ) {
        self.id = id
        self.amount = amount
        self.reason = reason
        self.refundDate = refundDate
        self.status = status
        self.gatewayRefundId = gatewayRefundId
        self.processedBy = processedBy
    }
}

public enum RefundStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Payment Gateway Models

public struct PaymentGateway: Codable, Hashable {
    public let provider: PaymentGatewayProvider
    public let merchantId: String
    public let apiKey: String
    public let isTestMode: Bool
    public let supportedMethods: [PaymentMethod]
    public let fees: GatewayFeeStructure
    public let settings: [String: String]
    
    public init(
        provider: PaymentGatewayProvider,
        merchantId: String,
        apiKey: String,
        isTestMode: Bool = false,
        supportedMethods: [PaymentMethod],
        fees: GatewayFeeStructure,
        settings: [String: String] = [:]
    ) {
        self.provider = provider
        self.merchantId = merchantId
        self.apiKey = apiKey
        self.isTestMode = isTestMode
        self.supportedMethods = supportedMethods
        self.fees = fees
        self.settings = settings
    }
}

public enum PaymentGatewayProvider: String, Codable, CaseIterable {
    case stripe = "stripe"
    case square = "square"
    case paypal = "paypal"
    case authorize = "authorize"
    case braintree = "braintree"
    case worldpay = "worldpay"
    case adyen = "adyen"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .stripe: return "Stripe"
        case .square: return "Square"
        case .paypal: return "PayPal"
        case .authorize: return "Authorize.Net"
        case .braintree: return "Braintree"
        case .worldpay: return "Worldpay"
        case .adyen: return "Adyen"
        case .other: return "Other"
        }
    }
}

public struct GatewayFeeStructure: Codable, Hashable {
    public let percentageFee: Decimal
    public let fixedFee: Decimal
    public let monthlyFee: Decimal?
    public let chargebackFee: Decimal?
    public let refundFee: Decimal?
    
    public init(
        percentageFee: Decimal,
        fixedFee: Decimal,
        monthlyFee: Decimal? = nil,
        chargebackFee: Decimal? = nil,
        refundFee: Decimal? = nil
    ) {
        self.percentageFee = percentageFee
        self.fixedFee = fixedFee
        self.monthlyFee = monthlyFee
        self.chargebackFee = chargebackFee
        self.refundFee = refundFee
    }
}

// MARK: - Bank Account Models

public struct BankAccount: Identifiable, Codable, Hashable {
    public let id: UUID
    public let accountName: String
    public let accountNumber: String
    public let routingNumber: String
    public let bankName: String
    public let accountType: BankAccountType
    public let currency: Currency
    public let isActive: Bool
    public let isPrimary: Bool
    public let balance: Decimal?
    public let lastSyncDate: Date?
    public let bankingProvider: BankingProvider?
    
    public init(
        id: UUID = UUID(),
        accountName: String,
        accountNumber: String,
        routingNumber: String,
        bankName: String,
        accountType: BankAccountType,
        currency: Currency = .usd,
        isActive: Bool = true,
        isPrimary: Bool = false,
        balance: Decimal? = nil,
        lastSyncDate: Date? = nil,
        bankingProvider: BankingProvider? = nil
    ) {
        self.id = id
        self.accountName = accountName
        self.accountNumber = accountNumber
        self.routingNumber = routingNumber
        self.bankName = bankName
        self.accountType = accountType
        self.currency = currency
        self.isActive = isActive
        self.isPrimary = isPrimary
        self.balance = balance
        self.lastSyncDate = lastSyncDate
        self.bankingProvider = bankingProvider
    }
}

public enum BankAccountType: String, Codable, CaseIterable {
    case checking = "checking"
    case savings = "savings"
    case business = "business"
    case moneyMarket = "money_market"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .business: return "Business"
        case .moneyMarket: return "Money Market"
        case .other: return "Other"
        }
    }
}

public enum BankingProvider: String, Codable, CaseIterable {
    case plaid = "plaid"
    case yodlee = "yodlee"
    case saltEdge = "salt_edge"
    case open = "open"
    case manual = "manual"
    
    public var displayName: String {
        switch self {
        case .plaid: return "Plaid"
        case .yodlee: return "Yodlee"
        case .saltEdge: return "Salt Edge"
        case .open: return "Open Banking"
        case .manual: return "Manual Entry"
        }
    }
}

public struct CheckDetails: Codable, Hashable {
    public let checkNumber: String
    public let bankName: String
    public let accountNumber: String?
    public let routingNumber: String?
    public let memo: String?
    public let checkDate: Date
    public let depositDate: Date?
    public let clearanceDate: Date?
    public let status: CheckStatus
    
    public init(
        checkNumber: String,
        bankName: String,
        accountNumber: String? = nil,
        routingNumber: String? = nil,
        memo: String? = nil,
        checkDate: Date,
        depositDate: Date? = nil,
        clearanceDate: Date? = nil,
        status: CheckStatus = .received
    ) {
        self.checkNumber = checkNumber
        self.bankName = bankName
        self.accountNumber = accountNumber
        self.routingNumber = routingNumber
        self.memo = memo
        self.checkDate = checkDate
        self.depositDate = depositDate
        self.clearanceDate = clearanceDate
        self.status = status
    }
}

public enum CheckStatus: String, Codable, CaseIterable {
    case received = "received"
    case deposited = "deposited"
    case cleared = "cleared"
    case bounced = "bounced"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .received: return "Received"
        case .deposited: return "Deposited"
        case .cleared: return "Cleared"
        case .bounced: return "Bounced"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Tax Models

public struct TaxDetails: Codable, Hashable {
    public let taxRegion: String
    public let taxRates: [TaxRate]
    public let exemptions: [TaxExemption]
    public let totalTaxAmount: Decimal
    public let isTaxInclusive: Bool
    public let taxNumber: String?
    
    public init(
        taxRegion: String,
        taxRates: [TaxRate] = [],
        exemptions: [TaxExemption] = [],
        totalTaxAmount: Decimal,
        isTaxInclusive: Bool = false,
        taxNumber: String? = nil
    ) {
        self.taxRegion = taxRegion
        self.taxRates = taxRates
        self.exemptions = exemptions
        self.totalTaxAmount = totalTaxAmount
        self.isTaxInclusive = isTaxInclusive
        self.taxNumber = taxNumber
    }
}

public struct TaxRate: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let rate: Decimal
    public let type: TaxType
    public let region: String
    public let applicableAmount: Decimal
    public let taxAmount: Decimal
    
    public init(
        id: UUID = UUID(),
        name: String,
        rate: Decimal,
        type: TaxType,
        region: String,
        applicableAmount: Decimal,
        taxAmount: Decimal
    ) {
        self.id = id
        self.name = name
        self.rate = rate
        self.type = type
        self.region = region
        self.applicableAmount = applicableAmount
        self.taxAmount = taxAmount
    }
}

public enum TaxType: String, Codable, CaseIterable {
    case sales = "sales"
    case vat = "vat"
    case gst = "gst"
    case excise = "excise"
    case service = "service"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .sales: return "Sales Tax"
        case .vat: return "VAT"
        case .gst: return "GST"
        case .excise: return "Excise Tax"
        case .service: return "Service Tax"
        case .other: return "Other"
        }
    }
}

public struct TaxExemption: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: TaxExemptionType
    public let exemptionNumber: String
    public let description: String
    public let validFrom: Date
    public let validTo: Date?
    public let exemptAmount: Decimal
    
    public init(
        id: UUID = UUID(),
        type: TaxExemptionType,
        exemptionNumber: String,
        description: String,
        validFrom: Date,
        validTo: Date? = nil,
        exemptAmount: Decimal
    ) {
        self.id = id
        self.type = type
        self.exemptionNumber = exemptionNumber
        self.description = description
        self.validFrom = validFrom
        self.validTo = validTo
        self.exemptAmount = exemptAmount
    }
}

public enum TaxExemptionType: String, Codable, CaseIterable {
    case nonprofit = "nonprofit"
    case government = "government"
    case resale = "resale"
    case export = "export"
    case education = "education"
    case religious = "religious"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .nonprofit: return "Non-Profit"
        case .government: return "Government"
        case .resale: return "Resale"
        case .export: return "Export"
        case .education: return "Education"
        case .religious: return "Religious"
        case .other: return "Other"
        }
    }
}

// MARK: - Currency Support

public enum Currency: String, Codable, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    case jpy = "JPY"
    case chf = "CHF"
    case cny = "CNY"
    case inr = "INR"
    case brl = "BRL"
    
    public var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .jpy: return "Japanese Yen"
        case .chf: return "Swiss Franc"
        case .cny: return "Chinese Yuan"
        case .inr: return "Indian Rupee"
        case .brl: return "Brazilian Real"
        }
    }
    
    public var symbol: String {
        switch self {
        case .usd, .cad, .aud, .brl: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy, .cny: return "¥"
        case .chf: return "CHF"
        case .inr: return "₹"
        }
    }
}

// MARK: - Document Attachment

public struct DocumentAttachment: Identifiable, Codable, Hashable {
    public let id: UUID
    public let fileName: String
    public let fileURL: URL
    public let fileSize: Int64
    public let mimeType: String
    public let uploadedBy: UUID
    public let uploadedAt: Date
    public let description: String?
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        fileURL: URL,
        fileSize: Int64,
        mimeType: String,
        uploadedBy: UUID,
        uploadedAt: Date = Date(),
        description: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.uploadedBy = uploadedBy
        self.uploadedAt = uploadedAt
        self.description = description
    }
}

// MARK: - CloudKit Extensions

extension Invoice {
    public init?(record: CKRecord) {
        guard
            let invoiceNumber = record["invoiceNumber"] as? String,
            let clientIdString = record["clientId"] as? String,
            let clientId = UUID(uuidString: clientIdString),
            let clientName = record["clientName"] as? String,
            let issueDate = record["issueDate"] as? Date,
            let dueDate = record["dueDate"] as? Date,
            let statusString = record["status"] as? String,
            let status = InvoiceStatus(rawValue: statusString),
            let subtotalString = record["subtotal"] as? String,
            let subtotal = Decimal(string: subtotalString),
            let totalAmountString = record["totalAmount"] as? String,
            let totalAmount = Decimal(string: totalAmountString),
            let createdByString = record["createdBy"] as? String,
            let createdBy = UUID(uuidString: createdByString),
            let createdAt = record["createdAt"] as? Date,
            let lastModified = record["lastModified"] as? Date,
            let lastModifiedByString = record["lastModifiedBy"] as? String,
            let lastModifiedBy = UUID(uuidString: lastModifiedByString)
        else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let taxAmountString = record["taxAmount"] as? String ?? "0"
        let taxAmount = Decimal(string: taxAmountString) ?? 0
        let discountAmountString = record["discountAmount"] as? String ?? "0"
        let discountAmount = Decimal(string: discountAmountString) ?? 0
        let currencyString = record["currency"] as? String ?? "USD"
        let currency = Currency(rawValue: currencyString) ?? .usd
        
        // Decode complex nested objects from JSON
        let lineItems: [InvoiceLineItem] = {
            guard let data = record["lineItems"] as? Data else { return [] }
            return (try? JSONDecoder().decode([InvoiceLineItem].self, from: data)) ?? []
        }()
        
        let paymentTerms: InvoicePaymentTerms = {
            guard let data = record["paymentTerms"] as? Data else {
                return InvoicePaymentTerms(terms: .net30, dueDays: 30)
            }
            return (try? JSONDecoder().decode(InvoicePaymentTerms.self, from: data)) ?? InvoicePaymentTerms(terms: .net30, dueDays: 30)
        }()
        
        let billingAddress: Address = {
            guard let data = record["billingAddress"] as? Data else {
                return Address(street: "", city: "", state: "", zipCode: "")
            }
            return (try? JSONDecoder().decode(Address.self, from: data)) ?? Address(street: "", city: "", state: "", zipCode: "")
        }()
        
        let shippingAddress: Address? = {
            guard let data = record["shippingAddress"] as? Data else { return nil }
            return try? JSONDecoder().decode(Address.self, from: data)
        }()
        
        let taxDetails: TaxDetails = {
            guard let data = record["taxDetails"] as? Data else {
                return TaxDetails(taxRegion: "US", totalTaxAmount: taxAmount)
            }
            return (try? JSONDecoder().decode(TaxDetails.self, from: data)) ?? TaxDetails(taxRegion: "US", totalTaxAmount: taxAmount)
        }()
        
        let attachments: [DocumentAttachment] = {
            guard let data = record["attachments"] as? Data else { return [] }
            return (try? JSONDecoder().decode([DocumentAttachment].self, from: data)) ?? []
        }()
        
        let paymentHistory: [PaymentRecord] = {
            guard let data = record["paymentHistory"] as? Data else { return [] }
            return (try? JSONDecoder().decode([PaymentRecord].self, from: data)) ?? []
        }()
        
        let recurringSettings: RecurringInvoiceSettings? = {
            guard let data = record["recurringSettings"] as? Data else { return nil }
            return try? JSONDecoder().decode(RecurringInvoiceSettings.self, from: data)
        }()
        
        self.init(
            id: id,
            invoiceNumber: invoiceNumber,
            clientId: clientId,
            clientName: clientName,
            issueDate: issueDate,
            dueDate: dueDate,
            status: status,
            subtotal: subtotal,
            taxAmount: taxAmount,
            discountAmount: discountAmount,
            totalAmount: totalAmount,
            currency: currency,
            lineItems: lineItems,
            paymentTerms: paymentTerms,
            notes: record["notes"] as? String,
            attachments: attachments,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress,
            taxDetails: taxDetails,
            paymentHistory: paymentHistory,
            recurringSettings: recurringSettings,
            createdBy: createdBy,
            createdAt: createdAt,
            lastModified: lastModified,
            lastModifiedBy: lastModifiedBy
        )
    }
    
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Invoice", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["invoiceNumber"] = invoiceNumber
        record["clientId"] = clientId.uuidString
        record["clientName"] = clientName
        record["issueDate"] = issueDate
        record["dueDate"] = dueDate
        record["status"] = status.rawValue
        record["subtotal"] = subtotal.description
        record["taxAmount"] = taxAmount.description
        record["discountAmount"] = discountAmount.description
        record["totalAmount"] = totalAmount.description
        record["currency"] = currency.rawValue
        record["notes"] = notes
        record["createdBy"] = createdBy.uuidString
        record["createdAt"] = createdAt
        record["lastModified"] = lastModified
        record["lastModifiedBy"] = lastModifiedBy.uuidString
        
        // Encode complex objects as JSON Data
        if let lineItemsData = try? JSONEncoder().encode(lineItems) {
            record["lineItems"] = lineItemsData
        }
        
        if let paymentTermsData = try? JSONEncoder().encode(paymentTerms) {
            record["paymentTerms"] = paymentTermsData
        }
        
        if let billingAddressData = try? JSONEncoder().encode(billingAddress) {
            record["billingAddress"] = billingAddressData
        }
        
        if let shippingAddress = shippingAddress,
           let shippingAddressData = try? JSONEncoder().encode(shippingAddress) {
            record["shippingAddress"] = shippingAddressData
        }
        
        if let taxDetailsData = try? JSONEncoder().encode(taxDetails) {
            record["taxDetails"] = taxDetailsData
        }
        
        if !attachments.isEmpty,
           let attachmentsData = try? JSONEncoder().encode(attachments) {
            record["attachments"] = attachmentsData
        }
        
        if !paymentHistory.isEmpty,
           let paymentHistoryData = try? JSONEncoder().encode(paymentHistory) {
            record["paymentHistory"] = paymentHistoryData
        }
        
        if let recurringSettings = recurringSettings,
           let recurringSettingsData = try? JSONEncoder().encode(recurringSettings) {
            record["recurringSettings"] = recurringSettingsData
        }
        
        return record
    }
}

extension PaymentRecord {
    public init?(record: CKRecord) {
        guard
            let invoiceIdString = record["invoiceId"] as? String,
            let invoiceId = UUID(uuidString: invoiceIdString),
            let paymentNumber = record["paymentNumber"] as? String,
            let amountString = record["amount"] as? String,
            let amount = Decimal(string: amountString),
            let paymentDate = record["paymentDate"] as? Date,
            let paymentMethodString = record["paymentMethod"] as? String,
            let paymentMethod = PaymentMethod(rawValue: paymentMethodString),
            let statusString = record["status"] as? String,
            let status = PaymentStatus(rawValue: statusString),
            let processedByString = record["processedBy"] as? String,
            let processedBy = UUID(uuidString: processedByString),
            let processedAt = record["processedAt"] as? Date,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let currencyString = record["currency"] as? String ?? "USD"
        let currency = Currency(rawValue: currencyString) ?? .usd
        
        let fees: PaymentFees? = {
            guard let data = record["fees"] as? Data else { return nil }
            return try? JSONDecoder().decode(PaymentFees.self, from: data)
        }()
        
        let refunds: [RefundRecord] = {
            guard let data = record["refunds"] as? Data else { return [] }
            return (try? JSONDecoder().decode([RefundRecord].self, from: data)) ?? []
        }()
        
        let paymentGateway: PaymentGateway? = {
            guard let data = record["paymentGateway"] as? Data else { return nil }
            return try? JSONDecoder().decode(PaymentGateway.self, from: data)
        }()
        
        let bankAccount: BankAccount? = {
            guard let data = record["bankAccount"] as? Data else { return nil }
            return try? JSONDecoder().decode(BankAccount.self, from: data)
        }()
        
        let checkDetails: CheckDetails? = {
            guard let data = record["checkDetails"] as? Data else { return nil }
            return try? JSONDecoder().decode(CheckDetails.self, from: data)
        }()
        
        self.init(
            id: id,
            invoiceId: invoiceId,
            paymentNumber: paymentNumber,
            amount: amount,
            currency: currency,
            paymentDate: paymentDate,
            paymentMethod: paymentMethod,
            status: status,
            transactionId: record["transactionId"] as? String,
            gatewayTransactionId: record["gatewayTransactionId"] as? String,
            notes: record["notes"] as? String,
            fees: fees,
            refunds: refunds,
            paymentGateway: paymentGateway,
            bankAccount: bankAccount,
            checkDetails: checkDetails,
            processedBy: processedBy,
            processedAt: processedAt,
            createdAt: createdAt
        )
    }
    
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "PaymentRecord", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["invoiceId"] = invoiceId.uuidString
        record["paymentNumber"] = paymentNumber
        record["amount"] = amount.description
        record["currency"] = currency.rawValue
        record["paymentDate"] = paymentDate
        record["paymentMethod"] = paymentMethod.rawValue
        record["status"] = status.rawValue
        record["transactionId"] = transactionId
        record["gatewayTransactionId"] = gatewayTransactionId
        record["notes"] = notes
        record["processedBy"] = processedBy.uuidString
        record["processedAt"] = processedAt
        record["createdAt"] = createdAt
        
        if let fees = fees,
           let feesData = try? JSONEncoder().encode(fees) {
            record["fees"] = feesData
        }
        
        if !refunds.isEmpty,
           let refundsData = try? JSONEncoder().encode(refunds) {
            record["refunds"] = refundsData
        }
        
        if let paymentGateway = paymentGateway,
           let paymentGatewayData = try? JSONEncoder().encode(paymentGateway) {
            record["paymentGateway"] = paymentGatewayData
        }
        
        if let bankAccount = bankAccount,
           let bankAccountData = try? JSONEncoder().encode(bankAccount) {
            record["bankAccount"] = bankAccountData
        }
        
        if let checkDetails = checkDetails,
           let checkDetailsData = try? JSONEncoder().encode(checkDetails) {
            record["checkDetails"] = checkDetailsData
        }
        
        return record
    }
}

// MARK: - Computed Properties

extension Invoice {
    public var isOverdue: Bool {
        return status != .paid && status != .cancelled && dueDate < Date()
    }
    
    public var remainingAmount: Decimal {
        let totalPaid = paymentHistory
            .filter { $0.status == .completed }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return totalAmount - totalPaid
    }
    
    public var daysPastDue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    public var formattedTotal: String {
        return currency.symbol + NumberFormatter.currency.string(from: NSDecimalNumber(decimal: totalAmount)) ?? "0.00"
    }
}

extension PaymentRecord {
    public var formattedAmount: String {
        return currency.symbol + NumberFormatter.currency.string(from: NSDecimalNumber(decimal: amount)) ?? "0.00"
    }
    
    public var netAmount: Decimal {
        guard let fees = fees else { return amount }
        return amount - fees.totalFees
    }
}

// MARK: - Number Formatter Extension

private extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
