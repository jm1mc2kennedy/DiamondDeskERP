import Foundation
import CloudKit

// MARK: - User Interface Preferences Model
public struct UserInterfacePreferences: Identifiable, Codable, Hashable {
    public let id: String
    public var userId: String
    public var themeConfiguration: ThemeConfiguration
    public var navigationConfiguration: NavigationConfiguration
    public var layoutPreferences: LayoutPreferences
    public var accessibilitySettings: AccessibilitySettings
    public var moduleVisibility: ModuleVisibilitySettings
    public var personalizations: [PersonalizationSetting]
    public var isSystemDefault: Bool
    public var lastModified: Date
    public var syncAcrossDevices: Bool
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        themeConfiguration: ThemeConfiguration = ThemeConfiguration(),
        navigationConfiguration: NavigationConfiguration = NavigationConfiguration(),
        layoutPreferences: LayoutPreferences = LayoutPreferences(),
        accessibilitySettings: AccessibilitySettings = AccessibilitySettings(),
        moduleVisibility: ModuleVisibilitySettings = ModuleVisibilitySettings(),
        personalizations: [PersonalizationSetting] = [],
        isSystemDefault: Bool = false,
        lastModified: Date = Date(),
        syncAcrossDevices: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.themeConfiguration = themeConfiguration
        self.navigationConfiguration = navigationConfiguration
        self.layoutPreferences = layoutPreferences
        self.accessibilitySettings = accessibilitySettings
        self.moduleVisibility = moduleVisibility
        self.personalizations = personalizations
        self.isSystemDefault = isSystemDefault
        self.lastModified = lastModified
        self.syncAcrossDevices = syncAcrossDevices
    }
}

// MARK: - Theme Configuration
public struct ThemeConfiguration: Codable, Hashable {
    public var themeId: String
    public var colorScheme: ColorScheme
    public var darkModePreference: DarkModePreference
    public var accentColor: String
    public var backgroundStyle: BackgroundStyle
    public var iconStyle: IconStyle
    public var fontConfiguration: FontConfiguration
    public var customColorOverrides: [String: String]
    
    public init(
        themeId: String = "default",
        colorScheme: ColorScheme = .system,
        darkModePreference: DarkModePreference = .system,
        accentColor: String = "#007AFF",
        backgroundStyle: BackgroundStyle = .standard,
        iconStyle: IconStyle = .filled,
        fontConfiguration: FontConfiguration = FontConfiguration(),
        customColorOverrides: [String: String] = [:]
    ) {
        self.themeId = themeId
        self.colorScheme = colorScheme
        self.darkModePreference = darkModePreference
        self.accentColor = accentColor
        self.backgroundStyle = backgroundStyle
        self.iconStyle = iconStyle
        self.fontConfiguration = fontConfiguration
        self.customColorOverrides = customColorOverrides
    }
}

public enum ColorScheme: String, CaseIterable, Codable, Identifiable {
    case light = "LIGHT"
    case dark = "DARK"
    case system = "SYSTEM"
    case highContrast = "HIGH_CONTRAST"
    case custom = "CUSTOM"
    
    public var id: String { rawValue }
}

public enum DarkModePreference: String, CaseIterable, Codable, Identifiable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
    case auto = "AUTO"
    
    public var id: String { rawValue }
}

public enum BackgroundStyle: String, CaseIterable, Codable, Identifiable {
    case standard = "STANDARD"
    case gradient = "GRADIENT"
    case pattern = "PATTERN"
    case image = "IMAGE"
    case solid = "SOLID"
    
    public var id: String { rawValue }
}

public enum IconStyle: String, CaseIterable, Codable, Identifiable {
    case filled = "FILLED"
    case outlined = "OUTLINED"
    case duotone = "DUOTONE"
    case minimal = "MINIMAL"
    
    public var id: String { rawValue }
}

public struct FontConfiguration: Codable, Hashable {
    public var primaryFont: String
    public var secondaryFont: String
    public var fontSize: FontSize
    public var fontWeight: FontWeight
    public var useSystemFont: Bool
    
    public init(
        primaryFont: String = "SF Pro",
        secondaryFont: String = "SF Pro",
        fontSize: FontSize = .medium,
        fontWeight: FontWeight = .regular,
        useSystemFont: Bool = true
    ) {
        self.primaryFont = primaryFont
        self.secondaryFont = secondaryFont
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.useSystemFont = useSystemFont
    }
}

public enum FontSize: String, CaseIterable, Codable, Identifiable {
    case small = "SMALL"
    case medium = "MEDIUM"
    case large = "LARGE"
    case extraLarge = "EXTRA_LARGE"
    
    public var id: String { rawValue }
}

public enum FontWeight: String, CaseIterable, Codable, Identifiable {
    case light = "LIGHT"
    case regular = "REGULAR"
    case medium = "MEDIUM"
    case semibold = "SEMIBOLD"
    case bold = "BOLD"
    
    public var id: String { rawValue }
}

// MARK: - Navigation Configuration
public struct NavigationConfiguration: Codable, Hashable {
    public var sidebarStyle: SidebarStyle
    public var menuItems: [NavigationMenuItem]
    public var collapsedByDefault: Bool
    public var showModuleIcons: Bool
    public var groupingPreference: NavigationGrouping
    public var customShortcuts: [CustomShortcut]
    public var breadcrumbsEnabled: Bool
    public var searchInNavigation: Bool
    
    public init(
        sidebarStyle: SidebarStyle = .standard,
        menuItems: [NavigationMenuItem] = [],
        collapsedByDefault: Bool = false,
        showModuleIcons: Bool = true,
        groupingPreference: NavigationGrouping = .byCategory,
        customShortcuts: [CustomShortcut] = [],
        breadcrumbsEnabled: Bool = true,
        searchInNavigation: Bool = true
    ) {
        self.sidebarStyle = sidebarStyle
        self.menuItems = menuItems
        self.collapsedByDefault = collapsedByDefault
        self.showModuleIcons = showModuleIcons
        self.groupingPreference = groupingPreference
        self.customShortcuts = customShortcuts
        self.breadcrumbsEnabled = breadcrumbsEnabled
        self.searchInNavigation = searchInNavigation
    }
}

public enum SidebarStyle: String, CaseIterable, Codable, Identifiable {
    case standard = "STANDARD"
    case compact = "COMPACT"
    case minimal = "MINIMAL"
    case expanded = "EXPANDED"
    
    public var id: String { rawValue }
}

public enum NavigationGrouping: String, CaseIterable, Codable, Identifiable {
    case byCategory = "BY_CATEGORY"
    case byFrequency = "BY_FREQUENCY"
    case alphabetical = "ALPHABETICAL"
    case custom = "CUSTOM"
    
    public var id: String { rawValue }
}

public struct NavigationMenuItem: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var icon: String
    public var destination: String
    public var order: Int
    public var isVisible: Bool
    public var parentId: String?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        icon: String,
        destination: String,
        order: Int,
        isVisible: Bool = true,
        parentId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.destination = destination
        self.order = order
        self.isVisible = isVisible
        self.parentId = parentId
    }
}

public struct CustomShortcut: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var keyboardShortcut: String
    public var action: String
    public var isEnabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        keyboardShortcut: String,
        action: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.keyboardShortcut = keyboardShortcut
        self.action = action
        self.isEnabled = isEnabled
    }
}

// MARK: - Layout Preferences
public struct LayoutPreferences: Codable, Hashable {
    public var informationDensity: InformationDensity
    public var cardSizing: CardSizing
    public var listViewStyle: ListViewStyle
    public var defaultViewModes: [String: ViewMode]
    public var gridColumnPreferences: [String: Int]
    public var pageSizePreferences: [String: Int]
    public var sortingPreferences: [String: SortConfiguration]
    
    public init(
        informationDensity: InformationDensity = .standard,
        cardSizing: CardSizing = .medium,
        listViewStyle: ListViewStyle = .standard,
        defaultViewModes: [String: ViewMode] = [:],
        gridColumnPreferences: [String: Int] = [:],
        pageSizePreferences: [String: Int] = [:],
        sortingPreferences: [String: SortConfiguration] = [:]
    ) {
        self.informationDensity = informationDensity
        self.cardSizing = cardSizing
        self.listViewStyle = listViewStyle
        self.defaultViewModes = defaultViewModes
        self.gridColumnPreferences = gridColumnPreferences
        self.pageSizePreferences = pageSizePreferences
        self.sortingPreferences = sortingPreferences
    }
}

public enum InformationDensity: String, CaseIterable, Codable, Identifiable {
    case compact = "COMPACT"
    case standard = "STANDARD"
    case comfortable = "COMFORTABLE"
    case spacious = "SPACIOUS"
    
    public var id: String { rawValue }
}

public enum CardSizing: String, CaseIterable, Codable, Identifiable {
    case small = "SMALL"
    case medium = "MEDIUM"
    case large = "LARGE"
    case extraLarge = "EXTRA_LARGE"
    
    public var id: String { rawValue }
}

public enum ListViewStyle: String, CaseIterable, Codable, Identifiable {
    case standard = "STANDARD"
    case card = "CARD"
    case table = "TABLE"
    case grid = "GRID"
    
    public var id: String { rawValue }
}

public enum ViewMode: String, CaseIterable, Codable, Identifiable {
    case list = "LIST"
    case card = "CARD"
    case table = "TABLE"
    case kanban = "KANBAN"
    case calendar = "CALENDAR"
    case timeline = "TIMELINE"
    
    public var id: String { rawValue }
}

public struct SortConfiguration: Codable, Hashable {
    public var field: String
    public var ascending: Bool
    public var secondaryField: String?
    public var secondaryAscending: Bool
    
    public init(
        field: String,
        ascending: Bool = true,
        secondaryField: String? = nil,
        secondaryAscending: Bool = true
    ) {
        self.field = field
        self.ascending = ascending
        self.secondaryField = secondaryField
        self.secondaryAscending = secondaryAscending
    }
}

// MARK: - Accessibility Settings
public struct AccessibilitySettings: Codable, Hashable {
    public var voiceOverEnabled: Bool
    public var highContrastEnabled: Bool
    public var largeTextEnabled: Bool
    public var reducedMotionEnabled: Bool
    public var colorBlindnessSupport: ColorBlindnessType
    public var keyboardNavigationEnabled: Bool
    public var screenReaderOptimized: Bool
    
    public init(
        voiceOverEnabled: Bool = false,
        highContrastEnabled: Bool = false,
        largeTextEnabled: Bool = false,
        reducedMotionEnabled: Bool = false,
        colorBlindnessSupport: ColorBlindnessType = .none,
        keyboardNavigationEnabled: Bool = false,
        screenReaderOptimized: Bool = false
    ) {
        self.voiceOverEnabled = voiceOverEnabled
        self.highContrastEnabled = highContrastEnabled
        self.largeTextEnabled = largeTextEnabled
        self.reducedMotionEnabled = reducedMotionEnabled
        self.colorBlindnessSupport = colorBlindnessSupport
        self.keyboardNavigationEnabled = keyboardNavigationEnabled
        self.screenReaderOptimized = screenReaderOptimized
    }
}

public enum ColorBlindnessType: String, CaseIterable, Codable, Identifiable {
    case none = "NONE"
    case deuteranopia = "DEUTERANOPIA"
    case protanopia = "PROTANOPIA"
    case tritanopia = "TRITANOPIA"
    case achromatopsia = "ACHROMATOPSIA"
    
    public var id: String { rawValue }
}

// MARK: - Module Visibility Settings
public struct ModuleVisibilitySettings: Codable, Hashable {
    public var visibleModules: [String]
    public var hiddenModules: [String]
    public var moduleOrder: [String]
    public var favoriteModules: [String]
    public var recentlyUsedModules: [String]
    
    public init(
        visibleModules: [String] = [],
        hiddenModules: [String] = [],
        moduleOrder: [String] = [],
        favoriteModules: [String] = [],
        recentlyUsedModules: [String] = []
    ) {
        self.visibleModules = visibleModules
        self.hiddenModules = hiddenModules
        self.moduleOrder = moduleOrder
        self.favoriteModules = favoriteModules
        self.recentlyUsedModules = recentlyUsedModules
    }
}

// MARK: - Personalization Setting
public struct PersonalizationSetting: Identifiable, Codable, Hashable {
    public let id: String
    public var key: String
    public var value: String
    public var category: PersonalizationCategory
    public var lastModified: Date
    
    public init(
        id: String = UUID().uuidString,
        key: String,
        value: String,
        category: PersonalizationCategory,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.category = category
        self.lastModified = lastModified
    }
}

public enum PersonalizationCategory: String, CaseIterable, Codable, Identifiable {
    case appearance = "APPEARANCE"
    case behavior = "BEHAVIOR"
    case notifications = "NOTIFICATIONS"
    case shortcuts = "SHORTCUTS"
    case widgets = "WIDGETS"
    case other = "OTHER"
    
    public var id: String { rawValue }
}

// MARK: - App Icon Configuration
public struct AppIconConfiguration: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String
    public var iconSetPath: String
    public var category: IconCategory
    public var isDefault: Bool
    public var isSeasonalVariant: Bool
    public var availabilityPeriod: DateInterval?
    public var requiredRole: String?
    public var previewImage: String
    public var approvalStatus: ApprovalStatus
    public var downloadCount: Int
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        iconSetPath: String,
        category: IconCategory,
        isDefault: Bool = false,
        isSeasonalVariant: Bool = false,
        availabilityPeriod: DateInterval? = nil,
        requiredRole: String? = nil,
        previewImage: String,
        approvalStatus: ApprovalStatus = .pending,
        downloadCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconSetPath = iconSetPath
        self.category = category
        self.isDefault = isDefault
        self.isSeasonalVariant = isSeasonalVariant
        self.availabilityPeriod = availabilityPeriod
        self.requiredRole = requiredRole
        self.previewImage = previewImage
        self.approvalStatus = approvalStatus
        self.downloadCount = downloadCount
    }
}

public enum IconCategory: String, CaseIterable, Codable, Identifiable {
    case seasonal = "SEASONAL"
    case corporate = "CORPORATE"
    case minimal = "MINIMAL"
    case colorful = "COLORFUL"
    case themed = "THEMED"
    case branded = "BRANDED"
    
    public var id: String { rawValue }
}

public enum ApprovalStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case deprecated = "DEPRECATED"
    
    public var id: String { rawValue }
}

// MARK: - CloudKit Extensions
extension UserInterfacePreferences {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "UserInterfacePreferences", recordID: CKRecord.ID(recordName: id))
        record["userId"] = userId
        record["isSystemDefault"] = isSystemDefault ? 1 : 0
        record["lastModified"] = lastModified
        record["syncAcrossDevices"] = syncAcrossDevices ? 1 : 0
        
        // Store complex objects as JSON
        if let data = try? JSONEncoder().encode(themeConfiguration) {
            record["themeConfiguration"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(navigationConfiguration) {
            record["navigationConfiguration"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(layoutPreferences) {
            record["layoutPreferences"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(accessibilitySettings) {
            record["accessibilitySettings"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(moduleVisibility) {
            record["moduleVisibility"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(personalizations) {
            record["personalizations"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> UserInterfacePreferences? {
        guard let userId = record["userId"] as? String else {
            return nil
        }
        
        let isSystemDefault = (record["isSystemDefault"] as? Int) == 1
        let syncAcrossDevices = (record["syncAcrossDevices"] as? Int) == 1
        
        var themeConfiguration = ThemeConfiguration()
        if let themeData = record["themeConfiguration"] as? String,
           let data = themeData.data(using: .utf8) {
            themeConfiguration = (try? JSONDecoder().decode(ThemeConfiguration.self, from: data)) ?? ThemeConfiguration()
        }
        
        var navigationConfiguration = NavigationConfiguration()
        if let navData = record["navigationConfiguration"] as? String,
           let data = navData.data(using: .utf8) {
            navigationConfiguration = (try? JSONDecoder().decode(NavigationConfiguration.self, from: data)) ?? NavigationConfiguration()
        }
        
        var layoutPreferences = LayoutPreferences()
        if let layoutData = record["layoutPreferences"] as? String,
           let data = layoutData.data(using: .utf8) {
            layoutPreferences = (try? JSONDecoder().decode(LayoutPreferences.self, from: data)) ?? LayoutPreferences()
        }
        
        var accessibilitySettings = AccessibilitySettings()
        if let accessibilityData = record["accessibilitySettings"] as? String,
           let data = accessibilityData.data(using: .utf8) {
            accessibilitySettings = (try? JSONDecoder().decode(AccessibilitySettings.self, from: data)) ?? AccessibilitySettings()
        }
        
        var moduleVisibility = ModuleVisibilitySettings()
        if let moduleData = record["moduleVisibility"] as? String,
           let data = moduleData.data(using: .utf8) {
            moduleVisibility = (try? JSONDecoder().decode(ModuleVisibilitySettings.self, from: data)) ?? ModuleVisibilitySettings()
        }
        
        var personalizations: [PersonalizationSetting] = []
        if let personalizationsData = record["personalizations"] as? String,
           let data = personalizationsData.data(using: .utf8) {
            personalizations = (try? JSONDecoder().decode([PersonalizationSetting].self, from: data)) ?? []
        }
        
        return UserInterfacePreferences(
            id: record.recordID.recordName,
            userId: userId,
            themeConfiguration: themeConfiguration,
            navigationConfiguration: navigationConfiguration,
            layoutPreferences: layoutPreferences,
            accessibilitySettings: accessibilitySettings,
            moduleVisibility: moduleVisibility,
            personalizations: personalizations,
            isSystemDefault: isSystemDefault,
            lastModified: record["lastModified"] as? Date ?? Date(),
            syncAcrossDevices: syncAcrossDevices
        )
    }
}
