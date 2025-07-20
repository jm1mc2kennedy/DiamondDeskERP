import XCTest
@testable import DiamondDeskERP

final class NewModelsTests: XCTestCase {
    
    // MARK: - Calendar Event Tests
    func testCalendarEventCreation() {
        let event = CalendarEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            organizerId: "user1",
            calendarId: "calendar1",
            createdBy: "user1"
        )
        
        XCTAssertEqual(event.title, "Team Meeting")
        XCTAssertEqual(event.eventType, .meeting)
        XCTAssertEqual(event.visibility, .private)
        XCTAssertEqual(event.status, .confirmed)
        XCTAssertFalse(event.isAllDay)
    }
    
    func testCalendarEventCloudKitConversion() {
        let originalEvent = CalendarEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            organizerId: "user1",
            calendarId: "calendar1",
            eventType: .appointment,
            visibility: .public,
            createdBy: "user1"
        )
        
        let record = originalEvent.toRecord()
        let convertedEvent = CalendarEvent.from(record: record)
        
        XCTAssertNotNil(convertedEvent)
        XCTAssertEqual(convertedEvent?.title, originalEvent.title)
        XCTAssertEqual(convertedEvent?.eventType, originalEvent.eventType)
        XCTAssertEqual(convertedEvent?.visibility, originalEvent.visibility)
    }
    
    // MARK: - Calendar Resource Tests
    func testCalendarResourceCreation() {
        let resource = CalendarResource(
            name: "Conference Room A",
            resourceType: .room,
            capacity: 10,
            managedBy: "admin1",
            createdBy: "admin1"
        )
        
        XCTAssertEqual(resource.name, "Conference Room A")
        XCTAssertEqual(resource.resourceType, .room)
        XCTAssertEqual(resource.capacity, 10)
        XCTAssertTrue(resource.isActive)
    }
    
    // MARK: - UI Preferences Tests
    func testUIPreferencesCreation() {
        let preferences = UserInterfacePreferences(
            userId: "user1"
        )
        
        XCTAssertEqual(preferences.userId, "user1")
        XCTAssertEqual(preferences.themeConfiguration.colorScheme, .system)
        XCTAssertEqual(preferences.layoutPreferences.informationDensity, .standard)
        XCTAssertTrue(preferences.syncAcrossDevices)
    }
    
    func testThemeConfiguration() {
        var theme = ThemeConfiguration()
        theme.darkModePreference = .dark
        theme.accentColor = "#FF0000"
        
        XCTAssertEqual(theme.darkModePreference, .dark)
        XCTAssertEqual(theme.accentColor, "#FF0000")
        XCTAssertEqual(theme.colorScheme, .system)
    }
    
    // MARK: - Custom Report Tests
    func testCustomReportCreation() {
        let report = CustomReport(
            name: "Sales Analysis",
            ownerId: "user1",
            parserTemplateId: "template1",
            reportType: .salesAnalysis
        )
        
        XCTAssertEqual(report.name, "Sales Analysis")
        XCTAssertEqual(report.reportType, .salesAnalysis)
        XCTAssertEqual(report.outputFormat, .pdf)
        XCTAssertTrue(report.isActive)
        XCTAssertEqual(report.executionCount, 0)
    }
    
    func testReportScheduleConfig() {
        var schedule = ReportScheduleConfig()
        schedule.isEnabled = true
        schedule.frequency = .weekly
        schedule.timeOfDay = "09:00"
        
        XCTAssertTrue(schedule.isEnabled)
        XCTAssertEqual(schedule.frequency, .weekly)
        XCTAssertEqual(schedule.timeOfDay, "09:00")
    }
    
    // MARK: - Dashboard Tests
    func testDashboardCreation() {
        let dashboard = Dashboard(
            name: "Executive Dashboard",
            ownerId: "user1"
        )
        
        XCTAssertEqual(dashboard.name, "Executive Dashboard")
        XCTAssertFalse(dashboard.isPublic)
        XCTAssertFalse(dashboard.isTemplate)
        XCTAssertEqual(dashboard.widgets.count, 0)
    }
    
    func testWidgetInstance() {
        let widget = DashboardWidgetInstance(
            widgetTypeId: "kpi-widget",
            position: WidgetPosition(x: 0, y: 0),
            size: WidgetSize(width: 2, height: 2)
        )
        
        XCTAssertEqual(widget.widgetTypeId, "kpi-widget")
        XCTAssertEqual(widget.position.x, 0)
        XCTAssertEqual(widget.size.width, 2)
        XCTAssertTrue(widget.isEnabled)
    }
    
    // MARK: - Record Linking Tests
    func testRecordLinkCreation() {
        let link = RecordLink(
            sourceModule: "Tasks",
            sourceRecordId: "task1",
            targetModule: "Tickets",
            targetRecordId: "ticket1",
            linkType: .relatedTo,
            relationshipCategory: .contextual,
            createdBy: "user1"
        )
        
        XCTAssertEqual(link.sourceModule, "Tasks")
        XCTAssertEqual(link.linkType, .relatedTo)
        XCTAssertEqual(link.relationshipCategory, .contextual)
        XCTAssertEqual(link.linkStrength, .moderate)
        XCTAssertTrue(link.isActive)
    }
    
    func testLinkSuggestion() {
        let suggestion = LinkSuggestion(
            sourceRecordId: "record1",
            targetRecordId: "record2",
            suggestionReason: .semanticSimilarity,
            confidenceScore: 0.85,
            suggestedLinkType: .relatedTo
        )
        
        XCTAssertEqual(suggestion.suggestionReason, .semanticSimilarity)
        XCTAssertEqual(suggestion.confidenceScore, 0.85)
        XCTAssertEqual(suggestion.status, .pending)
    }
    
    // MARK: - Office 365 Integration Tests
    func testOffice365Integration() {
        let integration = Office365Integration(
            userId: "user1",
            tenantId: "tenant1",
            applicationId: "app1"
        )
        
        XCTAssertEqual(integration.userId, "user1")
        XCTAssertEqual(integration.tenantId, "tenant1")
        XCTAssertTrue(integration.isActive)
        XCTAssertEqual(integration.enabledServices.count, 0)
    }
    
    func testSharePointResource() {
        let resource = SharePointResource(
            userId: "user1",
            siteId: "site1",
            driveId: "drive1",
            itemId: "item1",
            itemPath: "/documents/test.docx",
            itemName: "test.docx",
            itemType: .file,
            lastModifiedBy: "user1"
        )
        
        XCTAssertEqual(resource.itemName, "test.docx")
        XCTAssertEqual(resource.itemType, .file)
        XCTAssertEqual(resource.accessLevel, .read)
        XCTAssertFalse(resource.isShared)
    }
    
    // MARK: - Enum Tests
    func testAllEnumsHaveIds() {
        // Test that all our new enums properly implement Identifiable
        XCTAssertEqual(EventType.meeting.id, "MEETING")
        XCTAssertEqual(WidgetCategory.kpiMetrics.id, "KPI_METRICS")
        XCTAssertEqual(LinkType.relatedTo.id, "RELATED_TO")
        XCTAssertEqual(Office365Service.outlook.id, "OUTLOOK")
        XCTAssertEqual(SharePointItemType.file.id, "FILE")
    }
    
    func testEnumDisplayNames() {
        XCTAssertEqual(EventType.meeting.displayName, "Meeting")
        XCTAssertEqual(ReportType.salesAnalysis.displayName, "Sales Analysis")
        XCTAssertEqual(WidgetCategory.chartVisualization.displayName, "Chart Visualization")
        XCTAssertEqual(LinkType.dependsOn.displayName, "Depends On")
    }
    
    // MARK: - Repository Tests
    func testRepositoryInitialization() {
        let calendarRepo = CalendarRepository()
        let reportsRepo = CustomReportsRepository()
        let dashboardRepo = DashboardRepository()
        let linkingRepo = RecordLinkingRepository()
        let preferencesRepo = UIPreferencesRepository()
        let office365Repo = Office365Repository()
        
        // Test that repositories initialize properly
        XCTAssertEqual(calendarRepo.events.count, 0)
        XCTAssertEqual(reportsRepo.reports.count, 0)
        XCTAssertEqual(dashboardRepo.dashboards.count, 0)
        XCTAssertEqual(linkingRepo.links.count, 0)
        XCTAssertNil(preferencesRepo.preferences)
        XCTAssertEqual(office365Repo.integrations.count, 0)
        
        // Test that loading states are false initially
        XCTAssertFalse(calendarRepo.isLoading)
        XCTAssertFalse(reportsRepo.isLoading)
        XCTAssertFalse(dashboardRepo.isLoading)
        XCTAssertFalse(linkingRepo.isLoading)
        XCTAssertFalse(preferencesRepo.isLoading)
        XCTAssertFalse(office365Repo.isLoading)
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    func testJSONEncodingDecoding() throws {
        let originalEvent = CalendarEvent(
            title: "JSON Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            organizerId: "user1",
            calendarId: "calendar1",
            createdBy: "user1"
        )
        
        // Test encoding
        let encodedData = try JSONEncoder().encode(originalEvent)
        XCTAssertGreaterThan(encodedData.count, 0)
        
        // Test decoding
        let decodedEvent = try JSONDecoder().decode(CalendarEvent.self, from: encodedData)
        XCTAssertEqual(decodedEvent.title, originalEvent.title)
        XCTAssertEqual(decodedEvent.organizerId, originalEvent.organizerId)
    }
}

// MARK: - Performance Tests
extension NewModelsTests {
    func testPerformanceCalendarEventCreation() {
        measure {
            for _ in 0..<1000 {
                let _ = CalendarEvent(
                    title: "Performance Test",
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(3600),
                    organizerId: "user1",
                    calendarId: "calendar1",
                    createdBy: "user1"
                )
            }
        }
    }
    
    func testPerformanceCloudKitConversion() {
        let event = CalendarEvent(
            title: "Performance Test",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            organizerId: "user1",
            calendarId: "calendar1",
            createdBy: "user1"
        )
        
        measure {
            for _ in 0..<100 {
                let record = event.toRecord()
                let _ = CalendarEvent.from(record: record)
            }
        }
    }
}
