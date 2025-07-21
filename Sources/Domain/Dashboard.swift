import Foundation
#if canImport(CloudKit)
import CloudKit
#endif

// MARK: - Dashboard Models (Phase 4.12+ Implementation)
public struct DashboardModel: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var ownerId: String
    public var layoutConfiguration: DashboardLayout
    public var widgets: [DashboardWidgetInstance]
    public var refreshInterval: TimeInterval
    public var isPublic: Bool
    public var sharedWith: [String]
    public var roleRestrictions: [String]
    public var isTemplate: Bool
    public var templateCategory: String?
    public var viewCount: Int
    public var lastAccessed: Date
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        ownerId: String,
        layoutConfiguration: DashboardLayout = DashboardLayout(),
        widgets: [DashboardWidgetInstance] = [],
        refreshInterval: TimeInterval = 300, // 5 minutes
        isPublic: Bool = false,
        sharedWith: [String] = [],
        roleRestrictions: [String] = [],
        isTemplate: Bool = false,
        templateCategory: String? = nil,
        viewCount: Int = 0,
        lastAccessed: Date = Date(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.layoutConfiguration = layoutConfiguration
        self.widgets = widgets
        self.refreshInterval = refreshInterval
        self.isPublic = isPublic
        self.sharedWith = sharedWith
        self.roleRestrictions = roleRestrictions
        self.isTemplate = isTemplate
        self.templateCategory = templateCategory
        self.viewCount = viewCount
        self.lastAccessed = lastAccessed
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Dashboard Widget Instance
public struct DashboardWidgetInstance: Identifiable, Codable, Hashable {
    public let id: String
    public var widgetTypeId: String
    public var position: WidgetPosition
    public var size: WidgetSize
    public var configuration: WidgetConfiguration
    public var dataConnections: [DataConnection]
    public var refreshSettings: RefreshSettings
    public var conditionalDisplay: ConditionalDisplayRule?
    public var accessPermissions: [String]
    public var isEnabled: Bool
    public var customStyling: WidgetStyling?
    
    public init(
        id: String = UUID().uuidString,
        widgetTypeId: String,
        position: WidgetPosition = WidgetPosition(),
        size: WidgetSize = WidgetSize(),
        configuration: WidgetConfiguration = WidgetConfiguration(),
        dataConnections: [DataConnection] = [],
        refreshSettings: RefreshSettings = RefreshSettings(),
        conditionalDisplay: ConditionalDisplayRule? = nil,
        accessPermissions: [String] = [],
        isEnabled: Bool = true,
        customStyling: WidgetStyling? = nil
    ) {
        self.id = id
        self.widgetTypeId = widgetTypeId
        self.position = position
        self.size = size
        self.configuration = configuration
        self.dataConnections = dataConnections
        self.refreshSettings = refreshSettings
        self.conditionalDisplay = conditionalDisplay
        self.accessPermissions = accessPermissions
        self.isEnabled = isEnabled
        self.customStyling = customStyling
    }
}

// MARK: - Widget Type Definition
public struct WidgetTypeDefinition: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String
    public var category: WidgetCategory
    public var supportedDataSources: [String]
    public var configurationSchema: WidgetConfigSchema
    public var defaultConfiguration: WidgetConfiguration
    public var minimumSize: WidgetSize
    public var maximumSize: WidgetSize
    public var requiredPermissions: [String]
    public var previewImage: String
    public var documentation: String
    public var version: String
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: WidgetCategory,
        supportedDataSources: [String] = [],
        configurationSchema: WidgetConfigSchema = WidgetConfigSchema(),
        defaultConfiguration: WidgetConfiguration = WidgetConfiguration(),
        minimumSize: WidgetSize = WidgetSize(width: 1, height: 1),
        maximumSize: WidgetSize = WidgetSize(width: 12, height: 12),
        requiredPermissions: [String] = [],
        previewImage: String = "",
        documentation: String = "",
        version: String = "1.0.0",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.supportedDataSources = supportedDataSources
        self.configurationSchema = configurationSchema
        self.defaultConfiguration = defaultConfiguration
        self.minimumSize = minimumSize
        self.maximumSize = maximumSize
        self.requiredPermissions = requiredPermissions
        self.previewImage = previewImage
        self.documentation = documentation
        self.version = version
        self.isActive = isActive
    }
}

public enum WidgetCategory: String, CaseIterable, Codable, Identifiable {
    case kpiMetrics = "KPI_METRICS"
    case chartVisualization = "CHART_VISUALIZATION"
    case dataTable = "DATA_TABLE"
    case activityFeed = "ACTIVITY_FEED"
    case statusIndicator = "STATUS_INDICATOR"
    case controlPanel = "CONTROL_PANEL"
    case textDisplay = "TEXT_DISPLAY"
    case mediaViewer = "MEDIA_VIEWER"
    case calendar = "CALENDAR"
    case map = "MAP"
    case form = "FORM"
    case notification = "NOTIFICATION"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .kpiMetrics: return "KPI Metrics"
        case .chartVisualization: return "Chart Visualization"
        case .dataTable: return "Data Table"
        case .activityFeed: return "Activity Feed"
        case .statusIndicator: return "Status Indicator"
        case .controlPanel: return "Control Panel"
        case .textDisplay: return "Text Display"
        case .mediaViewer: return "Media Viewer"
        case .calendar: return "Calendar"
        case .map: return "Map"
        case .form: return "Form"
        case .notification: return "Notification"
        }
    }
}

// MARK: - Supporting Structures
public struct DashboardLayout: Codable, Hashable {
    public var gridColumns: Int
    public var gridRows: Int
    public var responsiveBreakpoints: [ResponsiveBreakpoint]
    public var backgroundColor: String
    public var headerConfiguration: HeaderConfiguration
    public var sidebarConfiguration: SidebarConfiguration?
    public var footerConfiguration: FooterConfiguration?
    
    public init(
        gridColumns: Int = 12,
        gridRows: Int = 8,
        responsiveBreakpoints: [ResponsiveBreakpoint] = [],
        backgroundColor: String = "#FFFFFF",
        headerConfiguration: HeaderConfiguration = HeaderConfiguration(),
        sidebarConfiguration: SidebarConfiguration? = nil,
        footerConfiguration: FooterConfiguration? = nil
    ) {
        self.gridColumns = gridColumns
        self.gridRows = gridRows
        self.responsiveBreakpoints = responsiveBreakpoints
        self.backgroundColor = backgroundColor
        self.headerConfiguration = headerConfiguration
        self.sidebarConfiguration = sidebarConfiguration
        self.footerConfiguration = footerConfiguration
    }
}

public struct ResponsiveBreakpoint: Codable, Hashable {
    public var deviceType: DeviceType
    public var minWidth: Int
    public var maxWidth: Int
    public var gridColumns: Int
    public var gridRows: Int
    
    public init(
        deviceType: DeviceType,
        minWidth: Int,
        maxWidth: Int,
        gridColumns: Int,
        gridRows: Int
    ) {
        self.deviceType = deviceType
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.gridColumns = gridColumns
        self.gridRows = gridRows
    }
}

public enum DeviceType: String, CaseIterable, Codable, Identifiable {
    case mobile = "MOBILE"
    case tablet = "TABLET"
    case desktop = "DESKTOP"
    case largeScreen = "LARGE_SCREEN"
    
    public var id: String { rawValue }
}

public struct HeaderConfiguration: Codable, Hashable {
    public var isVisible: Bool
    public var height: Int
    public var backgroundColor: String
    public var title: String
    public var showLogo: Bool
    public var showNavigation: Bool
    
    public init(
        isVisible: Bool = true,
        height: Int = 60,
        backgroundColor: String = "#F8F9FA",
        title: String = "",
        showLogo: Bool = true,
        showNavigation: Bool = true
    ) {
        self.isVisible = isVisible
        self.height = height
        self.backgroundColor = backgroundColor
        self.title = title
        self.showLogo = showLogo
        self.showNavigation = showNavigation
    }
}

public struct SidebarConfiguration: Codable, Hashable {
    public var isVisible: Bool
    public var width: Int
    public var position: SidebarPosition
    public var backgroundColor: String
    public var isCollapsible: Bool
    
    public init(
        isVisible: Bool = false,
        width: Int = 250,
        position: SidebarPosition = .left,
        backgroundColor: String = "#F8F9FA",
        isCollapsible: Bool = true
    ) {
        self.isVisible = isVisible
        self.width = width
        self.position = position
        self.backgroundColor = backgroundColor
        self.isCollapsible = isCollapsible
    }
}

public enum SidebarPosition: String, CaseIterable, Codable, Identifiable {
    case left = "LEFT"
    case right = "RIGHT"
    
    public var id: String { rawValue }
}

public struct FooterConfiguration: Codable, Hashable {
    public var isVisible: Bool
    public var height: Int
    public var backgroundColor: String
    public var content: String
    
    public init(
        isVisible: Bool = false,
        height: Int = 40,
        backgroundColor: String = "#F8F9FA",
        content: String = ""
    ) {
        self.isVisible = isVisible
        self.height = height
        self.backgroundColor = backgroundColor
        self.content = content
    }
}

public struct WidgetPosition: Codable, Hashable {
    public var x: Int
    public var y: Int
    public var zIndex: Int
    
    public init(x: Int = 0, y: Int = 0, zIndex: Int = 0) {
        self.x = x
        self.y = y
        self.zIndex = zIndex
    }
}

public struct WidgetSize: Codable, Hashable {
    public var width: Int
    public var height: Int
    public var minWidth: Int?
    public var minHeight: Int?
    public var maxWidth: Int?
    public var maxHeight: Int?
    
    public init(
        width: Int = 2,
        height: Int = 2,
        minWidth: Int? = nil,
        minHeight: Int? = nil,
        maxWidth: Int? = nil,
        maxHeight: Int? = nil
    ) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
}

public struct WidgetConfiguration: Codable, Hashable {
    public var title: String
    public var showTitle: Bool
    public var showBorder: Bool
    public var borderColor: String
    public var backgroundColor: String
    public var textColor: String
    public var customSettings: [String: String]
    
    public init(
        title: String = "",
        showTitle: Bool = true,
        showBorder: Bool = true,
        borderColor: String = "#E1E5E9",
        backgroundColor: String = "#FFFFFF",
        textColor: String = "#212529",
        customSettings: [String: String] = [:]
    ) {
        self.title = title
        self.showTitle = showTitle
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.customSettings = customSettings
    }
}

public struct WidgetConfigSchema: Codable, Hashable {
    public var fields: [ConfigField]
    public var version: String
    
    public init(fields: [ConfigField] = [], version: String = "1.0") {
        self.fields = fields
        self.version = version
    }
}

public struct ConfigField: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var type: ConfigFieldType
    public var label: String
    public var description: String?
    public var isRequired: Bool
    public var defaultValue: String?
    public var options: [String]?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: ConfigFieldType,
        label: String,
        description: String? = nil,
        isRequired: Bool = false,
        defaultValue: String? = nil,
        options: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.label = label
        self.description = description
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.options = options
    }
}

public enum ConfigFieldType: String, CaseIterable, Codable, Identifiable {
    case text = "TEXT"
    case number = "NUMBER"
    case boolean = "BOOLEAN"
    case select = "SELECT"
    case multiSelect = "MULTI_SELECT"
    case color = "COLOR"
    case date = "DATE"
    case json = "JSON"
    
    public var id: String { rawValue }
}

public struct DataConnection: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var sourceType: DataSourceType
    public var query: String
    public var parameters: [String: String]
    public var refreshInterval: TimeInterval
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        sourceType: DataSourceType,
        query: String,
        parameters: [String: String] = [:],
        refreshInterval: TimeInterval = 300,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.sourceType = sourceType
        self.query = query
        self.parameters = parameters
        self.refreshInterval = refreshInterval
        self.isActive = isActive
    }
}

public struct RefreshSettings: Codable, Hashable {
    public var autoRefresh: Bool
    public var refreshInterval: TimeInterval
    public var lastRefresh: Date?
    public var nextRefresh: Date?
    
    public init(
        autoRefresh: Bool = true,
        refreshInterval: TimeInterval = 300,
        lastRefresh: Date? = nil,
        nextRefresh: Date? = nil
    ) {
        self.autoRefresh = autoRefresh
        self.refreshInterval = refreshInterval
        self.lastRefresh = lastRefresh
        self.nextRefresh = nextRefresh
    }
}

public struct ConditionalDisplayRule: Codable, Hashable {
    public var condition: String
    public var Conditionaloperator: ConditionalOperator
    public var value: String
    public var isEnabled: Bool
    
    public init(
        condition: String,
        operator: ConditionalOperator,
        value: String,
        isEnabled: Bool = true
    ) {
        self.condition = condition
        self.operator = Conditionaloperator
        self.value = value
        self.isEnabled = isEnabled
    }
}

public enum ConditionalOperator: String, CaseIterable, Codable, Identifiable {
    case equals = "EQUALS"
    case notEquals = "NOT_EQUALS"
    case greaterThan = "GREATER_THAN"
    case lessThan = "LESS_THAN"
    case contains = "CONTAINS"
    case notContains = "NOT_CONTAINS"
    case isEmpty = "IS_EMPTY"
    case isNotEmpty = "IS_NOT_EMPTY"
    
    public var id: String { rawValue }
}

public struct WidgetStyling: Codable, Hashable {
    public var theme: String
    public var colorPalette: [String]
    public var customCSS: String?
    public var animations: [String]
    
    public init(
        theme: String = "default",
        colorPalette: [String] = [],
        customCSS: String? = nil,
        animations: [String] = []
    ) {
        self.theme = theme
        self.colorPalette = colorPalette
        self.customCSS = customCSS
        self.animations = animations
    }
}

// MARK: - CloudKit Extensions (Placeholder)
extension DashboardModel {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Dashboard", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["ownerId"] = ownerId
        record["refreshInterval"] = refreshInterval
        record["isPublic"] = isPublic ? 1 : 0
        record["sharedWith"] = sharedWith
        record["roleRestrictions"] = roleRestrictions
        record["isTemplate"] = isTemplate ? 1 : 0
        record["templateCategory"] = templateCategory
        record["viewCount"] = viewCount
        record["lastAccessed"] = lastAccessed
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        
        // Store complex objects as JSON
        if let data = try? JSONEncoder().encode(layoutConfiguration) {
            record["layoutConfiguration"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(widgets) {
            record["widgets"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> DashboardModel? {
        guard let name = record["name"] as? String,
              let ownerId = record["ownerId"] as? String else {
            return nil
        }
        
        let isPublic = (record["isPublic"] as? Int) == 1
        let isTemplate = (record["isTemplate"] as? Int) == 1
        
        var layoutConfiguration = DashboardLayout()
        if let layoutData = record["layoutConfiguration"] as? String,
           let data = layoutData.data(using: .utf8) {
            layoutConfiguration = (try? JSONDecoder().decode(DashboardLayout.self, from: data)) ?? DashboardLayout()
        }
        
        var widgets: [DashboardWidgetInstance] = []
        if let widgetsData = record["widgets"] as? String,
           let data = widgetsData.data(using: .utf8) {
            widgets = (try? JSONDecoder().decode([DashboardWidgetInstance].self, from: data)) ?? []
        }
        
        return DashboardModel(
            id: record.recordID.recordName,
            name: name,
            description: record["description"] as? String,
            ownerId: ownerId,
            layoutConfiguration: layoutConfiguration,
            widgets: widgets,
            refreshInterval: record["refreshInterval"] as? TimeInterval ?? 300,
            isPublic: isPublic,
            sharedWith: record["sharedWith"] as? [String] ?? [],
            roleRestrictions: record["roleRestrictions"] as? [String] ?? [],
            isTemplate: isTemplate,
            templateCategory: record["templateCategory"] as? String,
            viewCount: record["viewCount"] as? Int ?? 0,
            lastAccessed: record["lastAccessed"] as? Date ?? Date(),
            createdAt: record["createdAt"] as? Date ?? Date(),
            modifiedAt: record["modifiedAt"] as? Date ?? Date()
        )
    }
}

public typealias WidgetConfig = WidgetConfiguration

public typealias UserDashboard = DashboardModel
