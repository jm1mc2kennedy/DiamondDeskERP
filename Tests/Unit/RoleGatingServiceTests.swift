import XCTest
@testable import DiamondDeskERP

class RoleGatingServiceTests: XCTestCase {

    func testAdminPermissions() {
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .manageUsers))
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .assignStores))
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .createTasksAllStores))
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .closeTickets))
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .viewAllSalesKPIs))
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .uploadTraining))
        XCTAssertTrue(RoleGatingService.hasPermission(for: .admin, to: .approveMarketingContent))
    }

    func testAssociatePermissions() {
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .manageUsers))
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .assignStores))
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .createTasksAllStores))
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .closeTickets))
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .viewAllSalesKPIs))
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .uploadTraining))
        XCTAssertFalse(RoleGatingService.hasPermission(for: .associate, to: .approveMarketingContent))
    }
}
