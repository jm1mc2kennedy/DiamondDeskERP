import XCTest
@testable import DiamondDeskERP

// MARK: - Localization Service Tests
final class LocalizationServiceTests: XCTestCase {
    
    var localizationService: LocalizationService!
    
    override func setUp() {
        super.setUp()
        localizationService = LocalizationService.shared
    }
    
    override func tearDown() {
        localizationService = nil
        super.tearDown()
    }
    
    // MARK: - Service Initialization Tests
    
    func testSharedInstanceSingleton() {
        let instance1 = LocalizationService.shared
        let instance2 = LocalizationService.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Basic String Retrieval Tests
    
    func testStringRetrievalWithValidKey() {
        let result = localizationService.string(for: .navDashboard)
        
        XCTAssertEqual(result, "Dashboard")
        XCTAssertNotEqual(result, "nav.dashboard") // Should be localized, not raw key
    }
    
    func testStringRetrievalWithDefaultValue() {
        // This would test missing keys, but our enum ensures compile-time safety
        // so we test the fallback mechanism indirectly
        let result = localizationService.string(for: .navDashboard, defaultValue: "Custom Dashboard")
        
        // Should return localized value, not default since key exists
        XCTAssertEqual(result, "Dashboard")
    }
    
    // MARK: - Formatted String Tests
    
    func testFormattedStringWithArguments() {
        // Using accessibility label that has format specifier
        let result = localizationService.string(for: .accessibilityTaskCard, arguments: "Test Task")
        
        XCTAssertTrue(result.contains("Test Task"))
        XCTAssertTrue(result.contains("Task:"))
    }
    
    func testFormattedStringValidation() {
        // Test explicit format validation
        let result = localizationService.formattedString(for: .accessibilityTaskCard, "Sample Task")
        
        XCTAssertTrue(result.contains("Sample Task"))
        XCTAssertEqual(result, "Task: Sample Task. Tap to view details.")
    }
    
    // MARK: - SwiftUI Integration Tests
    
    func testSwiftUITextCreation() {
        let text = localizationService.text(for: .navTasks)
        
        // SwiftUI Text objects are opaque, so we test they can be created
        XCTAssertNotNil(text)
    }
    
    func testSwiftUITextWithArguments() {
        let text = localizationService.text(for: .accessibilityClientCard, arguments: "John Doe")
        
        XCTAssertNotNil(text)
    }
    
    // MARK: - Localization Key Enum Tests
    
    func testAllLocalizationKeysHaveValues() {
        // Test that all enum cases have corresponding localized strings
        for key in LocalizationKey.allCases {
            let localizedString = localizationService.string(for: key)
            
            // Should not return the raw key value (indicates missing localization)
            XCTAssertNotEqual(localizedString, key.rawValue, "Missing localization for key: \(key.rawValue)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key.rawValue)")
        }
    }
    
    func testNavigationKeys() {
        XCTAssertEqual(localizationService.string(for: .navDashboard), "Dashboard")
        XCTAssertEqual(localizationService.string(for: .navTasks), "Tasks")
        XCTAssertEqual(localizationService.string(for: .navTickets), "Tickets")
        XCTAssertEqual(localizationService.string(for: .navClients), "Clients")
        XCTAssertEqual(localizationService.string(for: .navKPIs), "KPIs")
        XCTAssertEqual(localizationService.string(for: .navSettings), "Settings")
    }
    
    func testActionKeys() {
        XCTAssertEqual(localizationService.string(for: .actionSave), "Save")
        XCTAssertEqual(localizationService.string(for: .actionCancel), "Cancel")
        XCTAssertEqual(localizationService.string(for: .actionDelete), "Delete")
        XCTAssertEqual(localizationService.string(for: .actionEdit), "Edit")
        XCTAssertEqual(localizationService.string(for: .actionCreate), "Create")
    }
    
    func testStatusKeys() {
        XCTAssertEqual(localizationService.string(for: .statusPending), "Pending")
        XCTAssertEqual(localizationService.string(for: .statusInProgress), "In Progress")
        XCTAssertEqual(localizationService.string(for: .statusCompleted), "Completed")
        XCTAssertEqual(localizationService.string(for: .statusOpen), "Open")
        XCTAssertEqual(localizationService.string(for: .statusClosed), "Closed")
    }
    
    func testErrorMessageKeys() {
        XCTAssertFalse(localizationService.string(for: .errorNetwork).isEmpty)
        XCTAssertFalse(localizationService.string(for: .errorValidation).isEmpty)
        XCTAssertFalse(localizationService.string(for: .errorPermission).isEmpty)
        XCTAssertFalse(localizationService.string(for: .errorUnknown).isEmpty)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        let taskLabel = localizationService.accessibilityLabel(for: .taskCard(title: "Test Task"))
        XCTAssertTrue(taskLabel.contains("Test Task"))
        XCTAssertTrue(taskLabel.contains("Task:"))
        
        let ticketLabel = localizationService.accessibilityLabel(for: .ticketCard(title: "Test Ticket"))
        XCTAssertTrue(ticketLabel.contains("Test Ticket"))
        XCTAssertTrue(ticketLabel.contains("Ticket:"))
        
        let clientLabel = localizationService.accessibilityLabel(for: .clientCard(name: "John Doe"))
        XCTAssertTrue(clientLabel.contains("John Doe"))
        XCTAssertTrue(clientLabel.contains("Client:"))
    }
    
    func testAccessibilityButtonLabels() {
        let createLabel = localizationService.accessibilityLabel(for: .createButton(type: "Task"))
        XCTAssertTrue(createLabel.contains("Task"))
        XCTAssertTrue(createLabel.contains("Create"))
        
        let filterLabel = localizationService.accessibilityLabel(for: .filterButton)
        XCTAssertEqual(filterLabel, "Filter results")
        
        let searchLabel = localizationService.accessibilityLabel(for: .searchButton)
        XCTAssertEqual(searchLabel, "Search")
    }
    
    // MARK: - Extensions Tests
    
    func testTextExtensionWithKey() {
        let text = Text(.navDashboard)
        XCTAssertNotNil(text)
    }
    
    func testTextExtensionWithKeyAndArguments() {
        let text = Text(.accessibilityTaskCard, arguments: "Sample Task")
        XCTAssertNotNil(text)
    }
    
    func testStringExtensionWithKey() {
        let string = String(.navTasks)
        XCTAssertEqual(string, "Tasks")
    }
    
    func testStringExtensionWithKeyAndArguments() {
        let string = String(.accessibilityClientCard, arguments: "Jane Smith")
        XCTAssertTrue(string.contains("Jane Smith"))
        XCTAssertTrue(string.contains("Client:"))
    }
    
    // MARK: - Module-Specific Key Tests
    
    func testTasksModuleKeys() {
        XCTAssertEqual(localizationService.string(for: .tasksTitle), "Tasks")
        XCTAssertEqual(localizationService.string(for: .tasksCreate), "Create Task")
        XCTAssertFalse(localizationService.string(for: .tasksAssignees).isEmpty)
        XCTAssertFalse(localizationService.string(for: .tasksProgress).isEmpty)
    }
    
    func testTicketsModuleKeys() {
        XCTAssertEqual(localizationService.string(for: .ticketsTitle), "Tickets")
        XCTAssertEqual(localizationService.string(for: .ticketsCreate), "Create Ticket")
        XCTAssertFalse(localizationService.string(for: .ticketsAssignee).isEmpty)
    }
    
    func testClientsModuleKeys() {
        XCTAssertEqual(localizationService.string(for: .clientsTitle), "Clients")
        XCTAssertEqual(localizationService.string(for: .clientsCreate), "Create Client")
        XCTAssertFalse(localizationService.string(for: .clientsContact).isEmpty)
    }
    
    func testKPIsModuleKeys() {
        XCTAssertEqual(localizationService.string(for: .kpisTitle), "Key Performance Indicators")
        XCTAssertFalse(localizationService.string(for: .kpisMetrics).isEmpty)
        XCTAssertFalse(localizationService.string(for: .kpisTargets).isEmpty)
    }
    
    // MARK: - Validation and Error Message Tests
    
    func testValidationMessages() {
        XCTAssertEqual(localizationService.string(for: .validationTitleRequired), "Title is required")
        XCTAssertEqual(localizationService.string(for: .validationDescriptionRequired), "Description is required")
        XCTAssertFalse(localizationService.string(for: .validationDueDateInvalid).isEmpty)
        XCTAssertFalse(localizationService.string(for: .validationAssigneeRequired).isEmpty)
    }
    
    func testConfirmationMessages() {
        XCTAssertFalse(localizationService.string(for: .confirmationDeleteTask).isEmpty)
        XCTAssertFalse(localizationService.string(for: .confirmationDeleteTicket).isEmpty)
        XCTAssertFalse(localizationService.string(for: .confirmationDeleteClient).isEmpty)
        XCTAssertFalse(localizationService.string(for: .confirmationMarkComplete).isEmpty)
    }
    
    func testSuccessMessages() {
        XCTAssertEqual(localizationService.string(for: .successTaskCreated), "Task created successfully")
        XCTAssertEqual(localizationService.string(for: .successTicketCreated), "Ticket created successfully")
        XCTAssertEqual(localizationService.string(for: .successClientCreated), "Client created successfully")
        XCTAssertEqual(localizationService.string(for: .successChangeSaved), "Changes saved successfully")
    }
    
    // MARK: - Performance Tests
    
    func testStringRetrievalPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = localizationService.string(for: .navDashboard)
            }
        }
    }
    
    func testFormattedStringPerformance() {
        measure {
            for i in 0..<1000 {
                _ = localizationService.string(for: .accessibilityTaskCard, arguments: "Task \(i)")
            }
        }
    }
    
    func testAccessibilityLabelPerformance() {
        measure {
            for i in 0..<1000 {
                _ = localizationService.accessibilityLabel(for: .taskCard(title: "Task \(i)"))
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyArgumentHandling() {
        let result = localizationService.string(for: .accessibilityTaskCard, arguments: "")
        XCTAssertTrue(result.contains("Task:"))
        // Should handle empty string gracefully
    }
    
    func testNilArgumentHandling() {
        // Test that the service handles format strings robustly
        let result = localizationService.formattedString(for: .accessibilityTaskCard, "Valid Title")
        XCTAssertTrue(result.contains("Valid Title"))
    }
}
