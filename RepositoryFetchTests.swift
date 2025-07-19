// RepositoryFetchTests.swift
// Diamond Desk ERP
// Basic async tests for Task, Ticket, Client, KPI repository fetches

import XCTest
@testable import DiamondDeskERP

final class RepositoryFetchTests: XCTestCase {
    func testTaskFetch() async throws {
        let repo = CloudKitTaskRepository()
        let tasks = try await repo.fetchAssigned(to: "demo-user-id")
        XCTAssertNotNil(tasks)
    }

    func testTicketFetch() async throws {
        let repo = CloudKitTicketRepository()
        let tickets = try await repo.fetchAssigned(to: "demo-user-id")
        XCTAssertNotNil(tickets)
    }

    func testClientFetch() async throws {
        let repo = CloudKitClientRepository()
        let clients = try await repo.fetchAssigned(to: "demo-user-id")
        XCTAssertNotNil(clients)
    }

    func testKPIFetch() async throws {
        let repo = CloudKitKPIRepository()
        let kpis = try await repo.fetchForStore("demo-store")
        XCTAssertNotNil(kpis)
    }
}
