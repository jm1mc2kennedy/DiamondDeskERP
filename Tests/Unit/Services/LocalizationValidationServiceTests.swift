import XCTest
@testable import DiamondDeskERP

// MARK: - Localization Validation Service Tests
final class LocalizationValidationServiceTests: XCTestCase {
    
    var validationService: LocalizationValidationService!
    
    override func setUp() {
        super.setUp()
        validationService = LocalizationValidationService.shared
    }
    
    override func tearDown() {
        validationService = nil
        super.tearDown()
    }
    
    // MARK: - Service Initialization Tests
    
    func testServiceInitialization() {
        XCTAssertNotNil(validationService)
        XCTAssertFalse(validationService.isValidating)
        XCTAssertNil(validationService.lastValidationDate)
    }
    
    // MARK: - String Format Validation Tests
    
    func testValidStringFormat() {
        let result = validationService.validateStringFormat("test.key", value: "Valid test string")
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.key, "test.key")
        XCTAssertEqual(result.value, "Valid test string")
        XCTAssertTrue(result.issues.isEmpty)
    }
    
    func testEmptyStringValidation() {
        let result = validationService.validateStringFormat("test.empty", value: "")
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.issues.count, 1)
        
        if case .emptyString(let key) = result.issues.first {
            XCTAssertEqual(key, "test.empty")
        } else {
            XCTFail("Expected emptyString issue")
        }
    }
    
    func testWhitespaceOnlyStringValidation() {
        let result = validationService.validateStringFormat("test.whitespace", value: "   \n  ")
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.issues.count, 1)
        
        if case .emptyString(let key) = result.issues.first {
            XCTAssertEqual(key, "test.whitespace")
        } else {
            XCTFail("Expected emptyString issue")
        }
    }
    
    func testExcessiveLengthValidation() {
        let longString = String(repeating: "a", count: 250)
        let result = validationService.validateStringFormat("test.long", value: longString)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.issues.count, 1)
        
        if case .excessiveLength(let key, let length) = result.issues.first {
            XCTAssertEqual(key, "test.long")
            XCTAssertEqual(length, 250)
        } else {
            XCTFail("Expected excessiveLength issue")
        }
    }
    
    func testLegacyFormatSpecifierDetection() {
        let result = validationService.validateStringFormat("test.legacy", value: "Hello %@, you have %d messages")
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.issues.count, 1)
        
        if case .invalidPlaceholder(let key, let format) = result.issues.first {
            XCTAssertEqual(key, "test.legacy")
            XCTAssertEqual(format, "Legacy format specifier")
        } else {
            XCTFail("Expected invalidPlaceholder issue")
        }
    }
    
    // MARK: - Localized String Tests
    
    func testLocalizedStringRetrieval() {
        // Test existing key (should be in Localizable.strings)
        let result = validationService.localizedString(for: "nav.dashboard")
        XCTAssertNotEqual(result, "nav.dashboard") // Should be localized
        XCTAssertEqual(result, "Dashboard")
    }
    
    func testLocalizedStringWithDefaultValue() {
        let result = validationService.localizedString(for: "nonexistent.key", defaultValue: "Default Value")
        XCTAssertEqual(result, "Default Value")
    }
    
    func testLocalizedStringWithoutDefaultValue() {
        let result = validationService.localizedString(for: "nonexistent.key")
        XCTAssertEqual(result, "nonexistent.key") // Should return key when no default provided
    }
    
    // MARK: - Validation Execution Tests
    
    func testValidationExecution() async {
        let expectation = XCTestExpectation(description: "Validation completed")
        
        // Monitor validation state
        let cancellable = validationService.$isValidating
            .dropFirst() // Skip initial false value
            .sink { isValidating in
                if !isValidating {
                    expectation.fulfill()
                }
            }
        
        await validationService.validateLocalization()
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Check results
        XCTAssertFalse(validationService.isValidating)
        XCTAssertNotNil(validationService.lastValidationDate)
        XCTAssertGreaterThan(validationService.validationResults.overallScore, 0)
        
        cancellable.cancel()
    }
    
    // MARK: - Validation Results Tests
    
    func testValidationResultsStructure() async {
        await validationService.validateLocalization()
        
        let results = validationService.validationResults
        
        // Check base language results
        XCTAssertEqual(results.baseLanguageResults.languageCode, "en")
        XCTAssertGreaterThanOrEqual(results.baseLanguageResults.completionPercentage, 0)
        XCTAssertLessThanOrEqual(results.baseLanguageResults.completionPercentage, 100)
        
        // Check coverage results
        XCTAssertGreaterThan(results.coverageResults.requiredKeys.count, 0)
        XCTAssertGreaterThanOrEqual(results.coverageResults.coveragePercentage, 0)
        XCTAssertLessThanOrEqual(results.coverageResults.coveragePercentage, 100)
        
        // Check accessibility results
        XCTAssertGreaterThanOrEqual(results.accessibilityResults.complianceScore, 0)
        XCTAssertLessThanOrEqual(results.accessibilityResults.complianceScore, 100)
        
        // Check overall score
        XCTAssertGreaterThanOrEqual(results.overallScore, 0)
        XCTAssertLessThanOrEqual(results.overallScore, 100)
    }
    
    // MARK: - Report Generation Tests
    
    func testReportGeneration() async {
        await validationService.validateLocalization()
        
        let report = validationService.generateValidationReport()
        
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("Localization Validation Report"))
        XCTAssertTrue(report.contains("Overall Score"))
        XCTAssertTrue(report.contains("Base Language"))
        XCTAssertTrue(report.contains("Key Coverage"))
        XCTAssertTrue(report.contains("Accessibility Compliance"))
    }
    
    func testReportGenerationWithoutValidation() {
        let report = validationService.generateValidationReport()
        
        XCTAssertTrue(report.contains("No validation results available"))
    }
    
    // MARK: - Export Data Tests
    
    func testExportDataGeneration() async {
        await validationService.validateLocalization()
        
        let exportData = validationService.exportValidationData()
        
        XCTAssertNotNil(exportData)
        
        // Verify JSON structure
        if let data = exportData {
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)
                XCTAssertNotNil(json?["validationDate"])
                XCTAssertNotNil(json?["overallScore"])
                XCTAssertNotNil(json?["baseLanguage"])
                XCTAssertNotNil(json?["coverage"])
                XCTAssertNotNil(json?["accessibility"])
            } catch {
                XCTFail("Failed to parse exported JSON: \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Validation performance")
            
            Task {
                await validationService.validateLocalization()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testStringFormatValidationPerformance() {
        let testString = "This is a test string with reasonable length for performance testing"
        
        measure {
            for i in 0..<1000 {
                _ = validationService.validateStringFormat("test.key.\(i)", value: testString)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testUnicodeStringValidation() {
        let unicodeString = "Unicode test: 🎯 📊 ✅ 🔍 ⚠️"
        let result = validationService.validateStringFormat("test.unicode", value: unicodeString)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.value, unicodeString)
    }
    
    func testSpecialCharacterValidation() {
        let specialChars = "Special chars: @#$%^&*()[]{}|\\:;\"'<>,.?/`~"
        let result = validationService.validateStringFormat("test.special", value: specialChars)
        
        XCTAssertTrue(result.isValid)
    }
    
    func testNewlineAndTabValidation() {
        let multilineString = "Line 1\nLine 2\tTabbed content\r\nWindows newline"
        let result = validationService.validateStringFormat("test.multiline", value: multilineString)
        
        XCTAssertTrue(result.isValid)
    }
}
