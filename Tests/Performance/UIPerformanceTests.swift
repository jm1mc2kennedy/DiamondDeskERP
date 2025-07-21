import SwiftUI
import XCTest

final class UIPerformanceTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }
    
    // MARK: - Employee UI Performance Tests
    
    func testEmployeeListViewPerformance() {
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Navigate to employee list
            let employeeTab = app.tabBars.buttons["Employees"]
            XCTAssertTrue(employeeTab.waitForExistence(timeout: 5))
            employeeTab.tap()
            
            // Wait for list to load
            let employeeList = app.collectionViews.firstMatch
            XCTAssertTrue(employeeList.waitForExistence(timeout: 10))
            
            // Perform scrolling performance test
            for _ in 0..<5 {
                employeeList.swipeUp()
                usleep(100000) // 100ms delay
                employeeList.swipeDown()
                usleep(100000)
            }
        }
    }
    
    func testEmployeeSearchPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to employee list
            let employeeTab = app.tabBars.buttons["Employees"]
            XCTAssertTrue(employeeTab.waitForExistence(timeout: 5))
            employeeTab.tap()
            
            // Access search field
            let searchField = app.searchFields.firstMatch
            XCTAssertTrue(searchField.waitForExistence(timeout: 5))
            
            // Test search performance
            searchField.tap()
            searchField.typeText("John")
            
            // Wait for search results
            let searchResults = app.collectionViews.firstMatch
            XCTAssertTrue(searchResults.waitForExistence(timeout: 3))
            
            // Clear search
            searchField.buttons["Clear text"].tap()
            
            // Test another search
            searchField.typeText("Engineering")
            XCTAssertTrue(searchResults.waitForExistence(timeout: 3))
        }
    }
    
    func testEmployeeDetailViewLoadingPerformance() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to employee list
            let employeeTab = app.tabBars.buttons["Employees"]
            XCTAssertTrue(employeeTab.waitForExistence(timeout: 5))
            employeeTab.tap()
            
            // Wait for list and tap first employee
            let employeeList = app.collectionViews.firstMatch
            XCTAssertTrue(employeeList.waitForExistence(timeout: 10))
            
            let firstEmployee = employeeList.cells.firstMatch
            XCTAssertTrue(firstEmployee.waitForExistence(timeout: 5))
            firstEmployee.tap()
            
            // Wait for detail view to load
            let detailView = app.scrollViews.firstMatch
            XCTAssertTrue(detailView.waitForExistence(timeout: 5))
            
            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    func testEmployeeCreationFormPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to employee list
            let employeeTab = app.tabBars.buttons["Employees"]
            XCTAssertTrue(employeeTab.waitForExistence(timeout: 5))
            employeeTab.tap()
            
            // Tap add button
            let addButton = app.buttons["Add Employee"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 5))
            addButton.tap()
            
            // Fill out form fields
            let firstNameField = app.textFields["First Name"]
            XCTAssertTrue(firstNameField.waitForExistence(timeout: 5))
            firstNameField.tap()
            firstNameField.typeText("Performance")
            
            let lastNameField = app.textFields["Last Name"]
            lastNameField.tap()
            lastNameField.typeText("Test")
            
            let emailField = app.textFields["Email"]
            emailField.tap()
            emailField.typeText("performance.test@company.com")
            
            // Navigate through form steps
            let nextButton = app.buttons["Next"]
            if nextButton.exists {
                nextButton.tap()
                
                // Fill address information
                let streetField = app.textFields["Street Address"]
                if streetField.exists {
                    streetField.tap()
                    streetField.typeText("123 Performance St")
                }
            }
            
            // Cancel form
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }
    
    // MARK: - Workflow UI Performance Tests
    
    func testWorkflowListViewPerformance() {
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Navigate to workflow list
            let workflowTab = app.tabBars.buttons["Workflows"]
            XCTAssertTrue(workflowTab.waitForExistence(timeout: 5))
            workflowTab.tap()
            
            // Wait for list to load
            let workflowList = app.collectionViews.firstMatch
            XCTAssertTrue(workflowList.waitForExistence(timeout: 10))
            
            // Test scrolling performance
            for _ in 0..<5 {
                workflowList.swipeUp()
                usleep(100000)
                workflowList.swipeDown()
                usleep(100000)
            }
        }
    }
    
    func testWorkflowFilteringPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to workflow list
            let workflowTab = app.tabBars.buttons["Workflows"]
            XCTAssertTrue(workflowTab.waitForExistence(timeout: 5))
            workflowTab.tap()
            
            // Access filter options
            let filterButton = app.buttons["Filter"]
            if filterButton.exists {
                filterButton.tap()
                
                // Test different filter options
                let statusFilter = app.buttons["Status"]
                if statusFilter.exists {
                    statusFilter.tap()
                    
                    let inProgressOption = app.buttons["In Progress"]
                    if inProgressOption.exists {
                        inProgressOption.tap()
                    }
                }
                
                // Apply filters
                let applyButton = app.buttons["Apply"]
                if applyButton.exists {
                    applyButton.tap()
                }
                
                // Clear filters
                let clearButton = app.buttons["Clear"]
                if clearButton.exists {
                    clearButton.tap()
                }
            }
        }
    }
    
    // MARK: - Asset Management UI Performance Tests
    
    func testAssetListViewPerformance() {
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Navigate to asset list
            let assetTab = app.tabBars.buttons["Assets"]
            XCTAssertTrue(assetTab.waitForExistence(timeout: 5))
            assetTab.tap()
            
            // Wait for list to load
            let assetList = app.collectionViews.firstMatch
            XCTAssertTrue(assetList.waitForExistence(timeout: 10))
            
            // Test scrolling performance
            for _ in 0..<5 {
                assetList.swipeUp()
                usleep(100000)
                assetList.swipeDown()
                usleep(100000)
            }
        }
    }
    
    func testAssetUploadPerformance() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to asset list
            let assetTab = app.tabBars.buttons["Assets"]
            XCTAssertTrue(assetTab.waitForExistence(timeout: 5))
            assetTab.tap()
            
            // Tap upload button
            let uploadButton = app.buttons["Upload Asset"]
            if uploadButton.exists {
                uploadButton.tap()
                
                // Test upload form performance
                let nameField = app.textFields["Asset Name"]
                if nameField.exists {
                    nameField.tap()
                    nameField.typeText("Performance Test Asset")
                }
                
                // Cancel upload
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Navigation Performance Tests
    
    func testTabNavigationPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            let tabs = ["Employees", "Workflows", "Assets", "Dashboard"]
            
            for tab in tabs {
                let tabButton = app.tabBars.buttons[tab]
                if tabButton.exists {
                    tabButton.tap()
                    usleep(500000) // 500ms delay to simulate user behavior
                }
            }
        }
    }
    
    func testDeepNavigationPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to employee detail
            let employeeTab = app.tabBars.buttons["Employees"]
            XCTAssertTrue(employeeTab.waitForExistence(timeout: 5))
            employeeTab.tap()
            
            let employeeList = app.collectionViews.firstMatch
            XCTAssertTrue(employeeList.waitForExistence(timeout: 10))
            
            let firstEmployee = employeeList.cells.firstMatch
            if firstEmployee.exists {
                firstEmployee.tap()
                
                // Wait for detail view
                let detailView = app.scrollViews.firstMatch
                XCTAssertTrue(detailView.waitForExistence(timeout: 5))
                
                // Navigate to edit view if available
                let editButton = app.buttons["Edit"]
                if editButton.exists {
                    editButton.tap()
                    
                    // Wait for edit form
                    let editForm = app.scrollViews.firstMatch
                    XCTAssertTrue(editForm.waitForExistence(timeout: 5))
                    
                    // Cancel edit
                    let cancelButton = app.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    }
                }
                
                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }
    
    // MARK: - Memory and Resource Tests
    
    func testMemoryUsageDuringHeavyNavigation() {
        measure(metrics: [XCTMemoryMetric()]) {
            // Perform heavy navigation sequence
            for _ in 0..<10 {
                // Navigate between all main tabs
                let tabs = ["Employees", "Workflows", "Assets", "Dashboard"]
                
                for tab in tabs {
                    let tabButton = app.tabBars.buttons[tab]
                    if tabButton.exists {
                        tabButton.tap()
                        usleep(200000) // 200ms delay
                        
                        // Interact with content
                        let mainContent = app.collectionViews.firstMatch
                        if mainContent.exists {
                            mainContent.swipeUp()
                            mainContent.swipeDown()
                        }
                    }
                }
            }
        }
    }
    
    func testAppLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.terminate()
            app.launch()
        }
    }
    
    // MARK: - Data Loading Performance Tests
    
    func testInitialDataLoadingPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Test initial loading of each main view
            let sections = [
                ("Employees", "Employee list should load"),
                ("Workflows", "Workflow list should load"),
                ("Assets", "Asset list should load")
            ]
            
            for (tabName, description) in sections {
                let tabButton = app.tabBars.buttons[tabName]
                if tabButton.exists {
                    tabButton.tap()
                    
                    // Wait for content to load
                    let content = app.collectionViews.firstMatch
                    XCTAssertTrue(content.waitForExistence(timeout: 5), description)
                    
                    // Verify loading is complete (look for loading indicators)
                    let loadingIndicator = app.activityIndicators.firstMatch
                    if loadingIndicator.exists {
                        // Wait for loading to finish
                        let expectation = XCTestExpectation(description: "Loading should complete")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            expectation.fulfill()
                        }
                        
                        wait(for: [expectation], timeout: 5)
                    }
                }
            }
        }
    }
    
    // MARK: - Form Performance Tests
    
    func testFormValidationPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to employee creation form
            let employeeTab = app.tabBars.buttons["Employees"]
            XCTAssertTrue(employeeTab.waitForExistence(timeout: 5))
            employeeTab.tap()
            
            let addButton = app.buttons["Add Employee"]
            if addButton.exists {
                addButton.tap()
                
                // Test form validation performance
                let nextButton = app.buttons["Next"]
                if nextButton.exists {
                    // Try to proceed without filling required fields
                    nextButton.tap()
                    
                    // Validation should prevent progression
                    let errorAlert = app.alerts.firstMatch
                    if errorAlert.exists {
                        let okButton = errorAlert.buttons["OK"]
                        if okButton.exists {
                            okButton.tap()
                        }
                    }
                    
                    // Fill required fields and test validation
                    let firstNameField = app.textFields["First Name"]
                    if firstNameField.exists {
                        firstNameField.tap()
                        firstNameField.typeText("Test")
                    }
                    
                    let lastNameField = app.textFields["Last Name"]
                    if lastNameField.exists {
                        lastNameField.tap()
                        lastNameField.typeText("User")
                    }
                    
                    let emailField = app.textFields["Email"]
                    if emailField.exists {
                        emailField.tap()
                        emailField.typeText("test.user@company.com")
                    }
                    
                    // Now validation should pass
                    if nextButton.exists {
                        nextButton.tap()
                    }
                }
                
                // Cancel form
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Search Performance Tests
    
    func testGlobalSearchPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            // Test search across different modules
            let searchTerms = ["John", "Test", "Engineering", "Document"]
            let modules = ["Employees", "Workflows", "Assets"]
            
            for module in modules {
                let tabButton = app.tabBars.buttons[module]
                if tabButton.exists {
                    tabButton.tap()
                    
                    let searchField = app.searchFields.firstMatch
                    if searchField.exists {
                        for term in searchTerms {
                            searchField.tap()
                            searchField.typeText(term)
                            
                            // Wait for search results
                            usleep(500000) // 500ms
                            
                            // Clear search
                            let clearButton = searchField.buttons["Clear text"]
                            if clearButton.exists {
                                clearButton.tap()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UI Performance Monitoring Extension

extension XCTestCase {
    func measureUIPerformance<T>(
        operation: String,
        timeout: TimeInterval = 10,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(timeElapsed, timeout, "\(operation) should complete within \(timeout) seconds")
        
        print("🎨 UI Performance - \(operation): \(String(format: "%.3f", timeElapsed))s")
        
        return result
    }
}
