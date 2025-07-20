import Foundation
import CloudKit
import Combine

// MARK: - Report Models

public struct Report: Identifiable, Codable, Hashable {
    public let id: UUID
    public var reportName: String
    public var reportDescription: String?
    public var reportType: ReportType
    public var category: ReportCategory
    public var dataSource: DataSource
    public var filters: ReportFilters
    public var visualizations: [ReportVisualization]
    public var schedule: ReportSchedule?
    public var permissions: ReportPermissions
    public var metadata: ReportMetadata
    public var createdBy: UUID // User ID
    public var sharedWith: [UUID] // User IDs
    public var isPublic: Bool
    public var isActive: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        reportName: String,
        reportDescription: String? = nil,
        reportType: ReportType,
        category: ReportCategory,
        dataSource: DataSource,
        filters: ReportFilters = ReportFilters(),
        visualizations: [ReportVisualization] = [],
        schedule: ReportSchedule? = nil,
        permissions: ReportPermissions = ReportPermissions(),
        metadata: ReportMetadata = ReportMetadata(),
        createdBy: UUID,
        sharedWith: [UUID] = [],
        isPublic: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.reportName = reportName
        self.reportDescription = reportDescription
        self.reportType = reportType
        self.category = category
        self.dataSource = dataSource
        self.filters = filters
        self.visualizations = visualizations
        self.schedule = schedule
        self.permissions = permissions
        self.metadata = metadata
        self.createdBy = createdBy
        self.sharedWith = sharedWith
        self.isPublic = isPublic
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ReportType: String, CaseIterable, Codable {
    case dashboard = "dashboard"
    case tabular = "tabular"
    case chart = "chart"
    case pivot = "pivot"
    case crosstab = "crosstab"
    case summary = "summary"
    case detailed = "detailed"
    case comparison = "comparison"
    case trend = "trend"
    case kpi = "kpi"
    
    public var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .tabular: return "Tabular Report"
        case .chart: return "Chart Report"
        case .pivot: return "Pivot Table"
        case .crosstab: return "Cross-Tab"
        case .summary: return "Summary Report"
        case .detailed: return "Detailed Report"
        case .comparison: return "Comparison Report"
        case .trend: return "Trend Analysis"
        case .kpi: return "KPI Report"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .dashboard: return "rectangle.3.group"
        case .tabular: return "tablecells"
        case .chart: return "chart.bar"
        case .pivot: return "table"
        case .crosstab: return "grid"
        case .summary: return "doc.text"
        case .detailed: return "list.bullet"
        case .comparison: return "arrow.left.arrow.right"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .kpi: return "speedometer"
        }
    }
}

public enum ReportCategory: String, CaseIterable, Codable {
    case financial = "financial"
    case operational = "operational"
    case sales = "sales"
    case hr = "hr"
    case inventory = "inventory"
    case customer = "customer"
    case vendor = "vendor"
    case project = "project"
    case compliance = "compliance"
    case executive = "executive"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .financial: return "Financial"
        case .operational: return "Operational"
        case .sales: return "Sales"
        case .hr: return "Human Resources"
        case .inventory: return "Inventory"
        case .customer: return "Customer"
        case .vendor: return "Vendor"
        case .project: return "Project"
        case .compliance: return "Compliance"
        case .executive: return "Executive"
        case .custom: return "Custom"
        }
    }
    
    public var color: String {
        switch self {
        case .financial: return "green"
        case .operational: return "blue"
        case .sales: return "orange"
        case .hr: return "purple"
        case .inventory: return "brown"
        case .customer: return "pink"
        case .vendor: return "indigo"
        case .project: return "cyan"
        case .compliance: return "red"
        case .executive: return "gold"
        case .custom: return "gray"
        }
    }
}

public enum DataSource: String, CaseIterable, Codable {
    case invoices = "invoices"
    case payments = "payments"
    case clients = "clients"
    case vendors = "vendors"
    case employees = "employees"
    case documents = "documents"
    case tasks = "tasks"
    case tickets = "tickets"
    case kpis = "kpis"
    case storeReports = "store_reports"
    case combined = "combined"
    case external = "external"
    
    public var displayName: String {
        switch self {
        case .invoices: return "Invoices"
        case .payments: return "Payments"
        case .clients: return "Clients"
        case .vendors: return "Vendors"
        case .employees: return "Employees"
        case .documents: return "Documents"
        case .tasks: return "Tasks"
        case .tickets: return "Tickets"
        case .kpis: return "KPIs"
        case .storeReports: return "Store Reports"
        case .combined: return "Combined Data"
        case .external: return "External Data"
        }
    }
    
    public var fields: [String] {
        switch self {
        case .invoices:
            return ["invoiceNumber", "clientName", "totalAmount", "status", "dueDate", "issueDate"]
        case .payments:
            return ["paymentNumber", "amount", "paymentMethod", "status", "paymentDate"]
        case .clients:
            return ["name", "email", "phone", "address", "industry", "size"]
        case .vendors:
            return ["name", "contactInfo", "category", "rating", "status"]
        case .employees:
            return ["name", "department", "position", "salary", "hireDate", "status"]
        case .documents:
            return ["title", "type", "size", "category", "uploadDate", "permissions"]
        case .tasks:
            return ["title", "description", "status", "priority", "assignee", "dueDate"]
        case .tickets:
            return ["ticketNumber", "title", "status", "priority", "assignee", "createdDate"]
        case .kpis:
            return ["metric", "value", "target", "period", "category"]
        case .storeReports:
            return ["storeName", "revenue", "expenses", "profit", "date"]
        case .combined:
            return ["entityType", "identifier", "value", "date", "category"]
        case .external:
            return ["source", "data", "timestamp", "format"]
        }
    }
}

public struct ReportFilters: Codable, Hashable {
    public var dateRange: DateRange?
    public var statusFilters: [String]?
    public var categoryFilters: [String]?
    public var amountRange: AmountRange?
    public var customFilters: [CustomFilter]?
    public var groupBy: [String]?
    public var sortBy: [SortCriteria]?
    
    public init(
        dateRange: DateRange? = nil,
        statusFilters: [String]? = nil,
        categoryFilters: [String]? = nil,
        amountRange: AmountRange? = nil,
        customFilters: [CustomFilter]? = nil,
        groupBy: [String]? = nil,
        sortBy: [SortCriteria]? = nil
    ) {
        self.dateRange = dateRange
        self.statusFilters = statusFilters
        self.categoryFilters = categoryFilters
        self.amountRange = amountRange
        self.customFilters = customFilters
        self.groupBy = groupBy
        self.sortBy = sortBy
    }
}

public struct DateRange: Codable, Hashable {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public struct AmountRange: Codable, Hashable {
    public let min: Decimal?
    public let max: Decimal?
    
    public init(min: Decimal? = nil, max: Decimal? = nil) {
        self.min = min
        self.max = max
    }
}

public struct CustomFilter: Identifiable, Codable, Hashable {
    public let id: UUID
    public var field: String
    public var operator: FilterOperator
    public var value: String
    public var dataType: FilterDataType
    
    public init(
        id: UUID = UUID(),
        field: String,
        operator: FilterOperator,
        value: String,
        dataType: FilterDataType
    ) {
        self.id = id
        self.field = field
        self.operator = `operator`
        self.value = value
        self.dataType = dataType
    }
}

public enum FilterOperator: String, CaseIterable, Codable {
    case equals = "equals"
    case notEquals = "not_equals"
    case contains = "contains"
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case greaterThanOrEqual = "greater_than_or_equal"
    case lessThanOrEqual = "less_than_or_equal"
    case isNull = "is_null"
    case isNotNull = "is_not_null"
    case inList = "in_list"
    case notInList = "not_in_list"
    
    public var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .notEquals: return "Not Equals"
        case .contains: return "Contains"
        case .startsWith: return "Starts With"
        case .endsWith: return "Ends With"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .greaterThanOrEqual: return "Greater Than or Equal"
        case .lessThanOrEqual: return "Less Than or Equal"
        case .isNull: return "Is Null"
        case .isNotNull: return "Is Not Null"
        case .inList: return "In List"
        case .notInList: return "Not In List"
        }
    }
}

public enum FilterDataType: String, CaseIterable, Codable {
    case text = "text"
    case number = "number"
    case date = "date"
    case boolean = "boolean"
    case list = "list"
    
    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .date: return "Date"
        case .boolean: return "Boolean"
        case .list: return "List"
        }
    }
}

public struct SortCriteria: Identifiable, Codable, Hashable {
    public let id: UUID
    public var field: String
    public var direction: SortDirection
    
    public init(id: UUID = UUID(), field: String, direction: SortDirection) {
        self.id = id
        self.field = field
        self.direction = direction
    }
}

public enum SortDirection: String, CaseIterable, Codable {
    case ascending = "ascending"
    case descending = "descending"
    
    public var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

// MARK: - Report Visualization Models

public struct ReportVisualization: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var type: VisualizationType
    public var dataConfig: VisualizationDataConfig
    public var styleConfig: VisualizationStyleConfig
    public var position: VisualizationPosition
    public var size: VisualizationSize
    public var isVisible: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        type: VisualizationType,
        dataConfig: VisualizationDataConfig,
        styleConfig: VisualizationStyleConfig = VisualizationStyleConfig(),
        position: VisualizationPosition = VisualizationPosition(),
        size: VisualizationSize = VisualizationSize(),
        isVisible: Bool = true
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.dataConfig = dataConfig
        self.styleConfig = styleConfig
        self.position = position
        self.size = size
        self.isVisible = isVisible
    }
}

public enum VisualizationType: String, CaseIterable, Codable {
    case barChart = "bar_chart"
    case lineChart = "line_chart"
    case pieChart = "pie_chart"
    case areaChart = "area_chart"
    case scatterPlot = "scatter_plot"
    case heatmap = "heatmap"
    case gauge = "gauge"
    case table = "table"
    case card = "card"
    case sparkline = "sparkline"
    case histogram = "histogram"
    case boxPlot = "box_plot"
    
    public var displayName: String {
        switch self {
        case .barChart: return "Bar Chart"
        case .lineChart: return "Line Chart"
        case .pieChart: return "Pie Chart"
        case .areaChart: return "Area Chart"
        case .scatterPlot: return "Scatter Plot"
        case .heatmap: return "Heatmap"
        case .gauge: return "Gauge"
        case .table: return "Table"
        case .card: return "Card"
        case .sparkline: return "Sparkline"
        case .histogram: return "Histogram"
        case .boxPlot: return "Box Plot"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .barChart: return "chart.bar"
        case .lineChart: return "chart.line.uptrend.xyaxis"
        case .pieChart: return "chart.pie"
        case .areaChart: return "chart.bar.xaxis"
        case .scatterPlot: return "chart.dots.scatter"
        case .heatmap: return "grid"
        case .gauge: return "speedometer"
        case .table: return "tablecells"
        case .card: return "rectangle"
        case .sparkline: return "chart.line.flattrend.xyaxis"
        case .histogram: return "chart.bar.fill"
        case .boxPlot: return "chart.bar.doc.horizontal"
        }
    }
}

public struct VisualizationDataConfig: Codable, Hashable {
    public var xAxis: String?
    public var yAxis: [String]?
    public var groupBy: String?
    public var aggregation: AggregationType?
    public var timeGranularity: TimeGranularity?
    public var maxDataPoints: Int?
    
    public init(
        xAxis: String? = nil,
        yAxis: [String]? = nil,
        groupBy: String? = nil,
        aggregation: AggregationType? = nil,
        timeGranularity: TimeGranularity? = nil,
        maxDataPoints: Int? = nil
    ) {
        self.xAxis = xAxis
        self.yAxis = yAxis
        self.groupBy = groupBy
        self.aggregation = aggregation
        self.timeGranularity = timeGranularity
        self.maxDataPoints = maxDataPoints
    }
}

public enum AggregationType: String, CaseIterable, Codable {
    case sum = "sum"
    case average = "average"
    case count = "count"
    case min = "min"
    case max = "max"
    case median = "median"
    case standardDeviation = "standard_deviation"
    case variance = "variance"
    case percentile = "percentile"
    
    public var displayName: String {
        switch self {
        case .sum: return "Sum"
        case .average: return "Average"
        case .count: return "Count"
        case .min: return "Minimum"
        case .max: return "Maximum"
        case .median: return "Median"
        case .standardDeviation: return "Standard Deviation"
        case .variance: return "Variance"
        case .percentile: return "Percentile"
        }
    }
}

public enum TimeGranularity: String, CaseIterable, Codable {
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    public var displayName: String {
        switch self {
        case .hour: return "Hourly"
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .quarter: return "Quarterly"
        case .year: return "Yearly"
        }
    }
}

public struct VisualizationStyleConfig: Codable, Hashable {
    public var colors: [String]?
    public var showLegend: Bool
    public var showGrid: Bool
    public var showLabels: Bool
    public var fontSize: Int?
    public var opacity: Double?
    public var borderWidth: Double?
    
    public init(
        colors: [String]? = nil,
        showLegend: Bool = true,
        showGrid: Bool = true,
        showLabels: Bool = true,
        fontSize: Int? = nil,
        opacity: Double? = nil,
        borderWidth: Double? = nil
    ) {
        self.colors = colors
        self.showLegend = showLegend
        self.showGrid = showGrid
        self.showLabels = showLabels
        self.fontSize = fontSize
        self.opacity = opacity
        self.borderWidth = borderWidth
    }
}

public struct VisualizationPosition: Codable, Hashable {
    public var x: Int
    public var y: Int
    
    public init(x: Int = 0, y: Int = 0) {
        self.x = x
        self.y = y
    }
}

public struct VisualizationSize: Codable, Hashable {
    public var width: Int
    public var height: Int
    
    public init(width: Int = 400, height: Int = 300) {
        self.width = width
        self.height = height
    }
}

// MARK: - Report Schedule Models

public struct ReportSchedule: Codable, Hashable {
    public var frequency: ScheduleFrequency
    public var time: ScheduleTime?
    public var dayOfWeek: DayOfWeek?
    public var dayOfMonth: Int?
    public var recipients: [String] // Email addresses
    public var format: ExportFormat
    public var isActive: Bool
    public var lastRun: Date?
    public var nextRun: Date?
    
    public init(
        frequency: ScheduleFrequency,
        time: ScheduleTime? = nil,
        dayOfWeek: DayOfWeek? = nil,
        dayOfMonth: Int? = nil,
        recipients: [String] = [],
        format: ExportFormat = .pdf,
        isActive: Bool = true,
        lastRun: Date? = nil,
        nextRun: Date? = nil
    ) {
        self.frequency = frequency
        self.time = time
        self.dayOfWeek = dayOfWeek
        self.dayOfMonth = dayOfMonth
        self.recipients = recipients
        self.format = format
        self.isActive = isActive
        self.lastRun = lastRun
        self.nextRun = nextRun
    }
}

public enum ScheduleFrequency: String, CaseIterable, Codable {
    case realTime = "real_time"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    public var displayName: String {
        switch self {
        case .realTime: return "Real-time"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

public struct ScheduleTime: Codable, Hashable {
    public var hour: Int // 0-23
    public var minute: Int // 0-59
    
    public init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }
    
    public var displayString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

public enum DayOfWeek: Int, CaseIterable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    public var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    public var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - Report Permissions Models

public struct ReportPermissions: Codable, Hashable {
    public var canView: [UUID] // User IDs
    public var canEdit: [UUID] // User IDs
    public var canDelete: [UUID] // User IDs
    public var canShare: [UUID] // User IDs
    public var canExport: [UUID] // User IDs
    public var canSchedule: [UUID] // User IDs
    public var isPublicView: Bool
    public var requiresAuthentication: Bool
    
    public init(
        canView: [UUID] = [],
        canEdit: [UUID] = [],
        canDelete: [UUID] = [],
        canShare: [UUID] = [],
        canExport: [UUID] = [],
        canSchedule: [UUID] = [],
        isPublicView: Bool = false,
        requiresAuthentication: Bool = true
    ) {
        self.canView = canView
        self.canEdit = canEdit
        self.canDelete = canDelete
        self.canShare = canShare
        self.canExport = canExport
        self.canSchedule = canSchedule
        self.isPublicView = isPublicView
        self.requiresAuthentication = requiresAuthentication
    }
}

// MARK: - Report Metadata Models

public struct ReportMetadata: Codable, Hashable {
    public var tags: [String]
    public var version: String
    public var lastGenerated: Date?
    public var generationTime: TimeInterval?
    public var dataRowCount: Int?
    public var fileSize: Int?
    public var executionLog: [ExecutionLogEntry]
    public var customMetadata: [String: String]
    
    public init(
        tags: [String] = [],
        version: String = "1.0",
        lastGenerated: Date? = nil,
        generationTime: TimeInterval? = nil,
        dataRowCount: Int? = nil,
        fileSize: Int? = nil,
        executionLog: [ExecutionLogEntry] = [],
        customMetadata: [String: String] = [:]
    ) {
        self.tags = tags
        self.version = version
        self.lastGenerated = lastGenerated
        self.generationTime = generationTime
        self.dataRowCount = dataRowCount
        self.fileSize = fileSize
        self.executionLog = executionLog
        self.customMetadata = customMetadata
    }
}

public struct ExecutionLogEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let action: String
    public let duration: TimeInterval?
    public let status: ExecutionStatus
    public let message: String?
    public let userId: UUID?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: String,
        duration: TimeInterval? = nil,
        status: ExecutionStatus,
        message: String? = nil,
        userId: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.duration = duration
        self.status = status
        self.message = message
        self.userId = userId
    }
}

public enum ExecutionStatus: String, CaseIterable, Codable {
    case started = "started"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case warning = "warning"
    
    public var displayName: String {
        switch self {
        case .started: return "Started"
        case .running: return "Running"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .warning: return "Warning"
        }
    }
    
    public var color: String {
        switch self {
        case .started: return "blue"
        case .running: return "orange"
        case .completed: return "green"
        case .failed: return "red"
        case .cancelled: return "gray"
        case .warning: return "yellow"
        }
    }
}

// MARK: - Export Models

public enum ExportFormat: String, CaseIterable, Codable {
    case pdf = "pdf"
    case excel = "excel"
    case csv = "csv"
    case json = "json"
    case xml = "xml"
    case html = "html"
    case powerpoint = "powerpoint"
    case image = "image"
    
    public var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .excel: return "Excel (.xlsx)"
        case .csv: return "CSV"
        case .json: return "JSON"
        case .xml: return "XML"
        case .html: return "HTML"
        case .powerpoint: return "PowerPoint (.pptx)"
        case .image: return "Image (.png)"
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .excel: return "xlsx"
        case .csv: return "csv"
        case .json: return "json"
        case .xml: return "xml"
        case .html: return "html"
        case .powerpoint: return "pptx"
        case .image: return "png"
        }
    }
    
    public var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .excel: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .xml: return "application/xml"
        case .html: return "text/html"
        case .powerpoint: return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case .image: return "image/png"
        }
    }
}

// MARK: - Dashboard Models

public struct Dashboard: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var widgets: [DashboardWidget]
    public var layout: DashboardLayout
    public var refreshInterval: TimeInterval?
    public var permissions: ReportPermissions
    public var isDefault: Bool
    public var createdBy: UUID
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        widgets: [DashboardWidget] = [],
        layout: DashboardLayout = DashboardLayout(),
        refreshInterval: TimeInterval? = nil,
        permissions: ReportPermissions = ReportPermissions(),
        isDefault: Bool = false,
        createdBy: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.widgets = widgets
        self.layout = layout
        self.refreshInterval = refreshInterval
        self.permissions = permissions
        self.isDefault = isDefault
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct DashboardWidget: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var type: WidgetType
    public var reportId: UUID?
    public var dataSource: DataSource?
    public var configuration: WidgetConfiguration
    public var position: WidgetPosition
    public var size: WidgetSize
    public var isVisible: Bool
    public var refreshInterval: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        title: String,
        type: WidgetType,
        reportId: UUID? = nil,
        dataSource: DataSource? = nil,
        configuration: WidgetConfiguration = WidgetConfiguration(),
        position: WidgetPosition = WidgetPosition(),
        size: WidgetSize = WidgetSize(),
        isVisible: Bool = true,
        refreshInterval: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.reportId = reportId
        self.dataSource = dataSource
        self.configuration = configuration
        self.position = position
        self.size = size
        self.isVisible = isVisible
        self.refreshInterval = refreshInterval
    }
}

public enum WidgetType: String, CaseIterable, Codable {
    case kpi = "kpi"
    case chart = "chart"
    case table = "table"
    case gauge = "gauge"
    case sparkline = "sparkline"
    case text = "text"
    case image = "image"
    case report = "report"
    case calendar = "calendar"
    case map = "map"
    
    public var displayName: String {
        switch self {
        case .kpi: return "KPI"
        case .chart: return "Chart"
        case .table: return "Table"
        case .gauge: return "Gauge"
        case .sparkline: return "Sparkline"
        case .text: return "Text"
        case .image: return "Image"
        case .report: return "Report"
        case .calendar: return "Calendar"
        case .map: return "Map"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .kpi: return "speedometer"
        case .chart: return "chart.bar"
        case .table: return "tablecells"
        case .gauge: return "gauge"
        case .sparkline: return "chart.line.flattrend.xyaxis"
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .report: return "doc.text"
        case .calendar: return "calendar"
        case .map: return "map"
        }
    }
}

public struct WidgetConfiguration: Codable, Hashable {
    public var title: String?
    public var subtitle: String?
    public var showTitle: Bool
    public var showBorder: Bool
    public var backgroundColor: String?
    public var textColor: String?
    public var customCss: String?
    public var autoRefresh: Bool
    public var clickAction: WidgetClickAction?
    public var customSettings: [String: String]
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        showTitle: Bool = true,
        showBorder: Bool = true,
        backgroundColor: String? = nil,
        textColor: String? = nil,
        customCss: String? = nil,
        autoRefresh: Bool = true,
        clickAction: WidgetClickAction? = nil,
        customSettings: [String: String] = [:]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showTitle = showTitle
        self.showBorder = showBorder
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.customCss = customCss
        self.autoRefresh = autoRefresh
        self.clickAction = clickAction
        self.customSettings = customSettings
    }
}

public enum WidgetClickAction: String, CaseIterable, Codable {
    case none = "none"
    case drillDown = "drill_down"
    case openReport = "open_report"
    case openUrl = "open_url"
    case showDetails = "show_details"
    case refresh = "refresh"
    
    public var displayName: String {
        switch self {
        case .none: return "No Action"
        case .drillDown: return "Drill Down"
        case .openReport: return "Open Report"
        case .openUrl: return "Open URL"
        case .showDetails: return "Show Details"
        case .refresh: return "Refresh"
        }
    }
}

public struct WidgetPosition: Codable, Hashable {
    public var row: Int
    public var column: Int
    
    public init(row: Int = 0, column: Int = 0) {
        self.row = row
        self.column = column
    }
}

public struct WidgetSize: Codable, Hashable {
    public var rows: Int
    public var columns: Int
    
    public init(rows: Int = 1, columns: Int = 1) {
        self.rows = rows
        self.columns = columns
    }
}

public struct DashboardLayout: Codable, Hashable {
    public var gridColumns: Int
    public var gridRows: Int
    public var marginX: Int
    public var marginY: Int
    public var spacing: Int
    
    public init(
        gridColumns: Int = 12,
        gridRows: Int = 12,
        marginX: Int = 10,
        marginY: Int = 10,
        spacing: Int = 10
    ) {
        self.gridColumns = gridColumns
        self.gridRows = gridRows
        self.marginX = marginX
        self.marginY = marginY
        self.spacing = spacing
    }
}

// MARK: - CloudKit Extensions

extension Report {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Report", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["reportName"] = reportName as CKRecordValue
        record["reportDescription"] = reportDescription as CKRecordValue?
        record["reportType"] = reportType.rawValue as CKRecordValue
        record["category"] = category.rawValue as CKRecordValue
        record["dataSource"] = dataSource.rawValue as CKRecordValue
        record["createdBy"] = createdBy.uuidString as CKRecordValue
        record["isPublic"] = isPublic as CKRecordValue
        record["isActive"] = isActive as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        // Encode complex objects as JSON
        if let filtersData = try? JSONEncoder().encode(filters) {
            record["filters"] = String(data: filtersData, encoding: .utf8) as CKRecordValue?
        }
        
        if let visualizationsData = try? JSONEncoder().encode(visualizations) {
            record["visualizations"] = String(data: visualizationsData, encoding: .utf8) as CKRecordValue?
        }
        
        if let scheduleData = try? JSONEncoder().encode(schedule) {
            record["schedule"] = String(data: scheduleData, encoding: .utf8) as CKRecordValue?
        }
        
        if let permissionsData = try? JSONEncoder().encode(permissions) {
            record["permissions"] = String(data: permissionsData, encoding: .utf8) as CKRecordValue?
        }
        
        if let metadataData = try? JSONEncoder().encode(metadata) {
            record["metadata"] = String(data: metadataData, encoding: .utf8) as CKRecordValue?
        }
        
        if let sharedWithData = try? JSONEncoder().encode(sharedWith) {
            record["sharedWith"] = String(data: sharedWithData, encoding: .utf8) as CKRecordValue?
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) throws -> Report {
        guard let reportName = record["reportName"] as? String,
              let reportTypeString = record["reportType"] as? String,
              let reportType = ReportType(rawValue: reportTypeString),
              let categoryString = record["category"] as? String,
              let category = ReportCategory(rawValue: categoryString),
              let dataSourceString = record["dataSource"] as? String,
              let dataSource = DataSource(rawValue: dataSourceString),
              let createdByString = record["createdBy"] as? String,
              let createdBy = UUID(uuidString: createdByString),
              let isPublic = record["isPublic"] as? Bool,
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let id = UUID(uuidString: record.recordID.recordName) else {
            throw ReportingError.invalidCloudKitRecord
        }
        
        let reportDescription = record["reportDescription"] as? String
        
        // Decode JSON objects
        var filters = ReportFilters()
        if let filtersString = record["filters"] as? String,
           let filtersData = filtersString.data(using: .utf8) {
            filters = (try? JSONDecoder().decode(ReportFilters.self, from: filtersData)) ?? ReportFilters()
        }
        
        var visualizations: [ReportVisualization] = []
        if let visualizationsString = record["visualizations"] as? String,
           let visualizationsData = visualizationsString.data(using: .utf8) {
            visualizations = (try? JSONDecoder().decode([ReportVisualization].self, from: visualizationsData)) ?? []
        }
        
        var schedule: ReportSchedule?
        if let scheduleString = record["schedule"] as? String,
           let scheduleData = scheduleString.data(using: .utf8) {
            schedule = try? JSONDecoder().decode(ReportSchedule.self, from: scheduleData)
        }
        
        var permissions = ReportPermissions()
        if let permissionsString = record["permissions"] as? String,
           let permissionsData = permissionsString.data(using: .utf8) {
            permissions = (try? JSONDecoder().decode(ReportPermissions.self, from: permissionsData)) ?? ReportPermissions()
        }
        
        var metadata = ReportMetadata()
        if let metadataString = record["metadata"] as? String,
           let metadataData = metadataString.data(using: .utf8) {
            metadata = (try? JSONDecoder().decode(ReportMetadata.self, from: metadataData)) ?? ReportMetadata()
        }
        
        var sharedWith: [UUID] = []
        if let sharedWithString = record["sharedWith"] as? String,
           let sharedWithData = sharedWithString.data(using: .utf8) {
            sharedWith = (try? JSONDecoder().decode([UUID].self, from: sharedWithData)) ?? []
        }
        
        return Report(
            id: id,
            reportName: reportName,
            reportDescription: reportDescription,
            reportType: reportType,
            category: category,
            dataSource: dataSource,
            filters: filters,
            visualizations: visualizations,
            schedule: schedule,
            permissions: permissions,
            metadata: metadata,
            createdBy: createdBy,
            sharedWith: sharedWith,
            isPublic: isPublic,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Dashboard {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Dashboard", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["name"] = name as CKRecordValue
        record["description"] = description as CKRecordValue?
        record["isDefault"] = isDefault as CKRecordValue
        record["createdBy"] = createdBy.uuidString as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["refreshInterval"] = refreshInterval as CKRecordValue?
        
        // Encode complex objects as JSON
        if let widgetsData = try? JSONEncoder().encode(widgets) {
            record["widgets"] = String(data: widgetsData, encoding: .utf8) as CKRecordValue?
        }
        
        if let layoutData = try? JSONEncoder().encode(layout) {
            record["layout"] = String(data: layoutData, encoding: .utf8) as CKRecordValue?
        }
        
        if let permissionsData = try? JSONEncoder().encode(permissions) {
            record["permissions"] = String(data: permissionsData, encoding: .utf8) as CKRecordValue?
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) throws -> Dashboard {
        guard let name = record["name"] as? String,
              let createdByString = record["createdBy"] as? String,
              let createdBy = UUID(uuidString: createdByString),
              let isDefault = record["isDefault"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let id = UUID(uuidString: record.recordID.recordName) else {
            throw ReportingError.invalidCloudKitRecord
        }
        
        let description = record["description"] as? String
        let refreshInterval = record["refreshInterval"] as? TimeInterval
        
        // Decode JSON objects
        var widgets: [DashboardWidget] = []
        if let widgetsString = record["widgets"] as? String,
           let widgetsData = widgetsString.data(using: .utf8) {
            widgets = (try? JSONDecoder().decode([DashboardWidget].self, from: widgetsData)) ?? []
        }
        
        var layout = DashboardLayout()
        if let layoutString = record["layout"] as? String,
           let layoutData = layoutString.data(using: .utf8) {
            layout = (try? JSONDecoder().decode(DashboardLayout.self, from: layoutData)) ?? DashboardLayout()
        }
        
        var permissions = ReportPermissions()
        if let permissionsString = record["permissions"] as? String,
           let permissionsData = permissionsString.data(using: .utf8) {
            permissions = (try? JSONDecoder().decode(ReportPermissions.self, from: permissionsData)) ?? ReportPermissions()
        }
        
        return Dashboard(
            id: id,
            name: name,
            description: description,
            widgets: widgets,
            layout: layout,
            refreshInterval: refreshInterval,
            permissions: permissions,
            isDefault: isDefault,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Error Types

public enum ReportingError: Error, LocalizedError {
    case invalidCloudKitRecord
    case dataSourceNotFound
    case reportNotFound
    case dashboardNotFound
    case permissionDenied
    case invalidFilter
    case exportFailed
    case schedulingFailed
    case dataProcessingFailed
    case visualizationError
    
    public var errorDescription: String? {
        switch self {
        case .invalidCloudKitRecord:
            return "Invalid CloudKit record format"
        case .dataSourceNotFound:
            return "Data source not found"
        case .reportNotFound:
            return "Report not found"
        case .dashboardNotFound:
            return "Dashboard not found"
        case .permissionDenied:
            return "Permission denied"
        case .invalidFilter:
            return "Invalid filter configuration"
        case .exportFailed:
            return "Export operation failed"
        case .schedulingFailed:
            return "Scheduling operation failed"
        case .dataProcessingFailed:
            return "Data processing failed"
        case .visualizationError:
            return "Visualization error"
        }
    }
}
