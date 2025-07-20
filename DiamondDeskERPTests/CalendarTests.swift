import XCTest
@testable import DiamondDeskERP

// MARK: - Mock Service

final class MockCalendarService: CalendarServiceProtocol {
    var events: [UUID: CalendarEvent] = [:]
    var shouldThrow = false

    func fetchEvents(start: Date?, end: Date?) async throws -> [CalendarEvent] {
        if shouldThrow { throw TestError.mockFailure }
        return Array(events.values)
    }
    
    func createEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        if shouldThrow { throw TestError.mockFailure }
        events[event.id] = event
        return event
    }
    
    func updateEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        if shouldThrow { throw TestError.mockFailure }
        events[event.id] = event
        return event
    }
    
    func deleteEvent(_ eventID: UUID) async throws {
        if shouldThrow { throw TestError.mockFailure }
        events.removeValue(forKey: eventID)
    }
    
    func fetchEventChanges(since date: Date) async throws -> [CalendarEvent] {
        if shouldThrow { throw TestError.mockFailure }
        return Array(events.values)
    }
}

enum TestError: Error {
    case mockFailure
}

// MARK: - Service Tests

final class CalendarServiceTests: XCTestCase {
    func testCreateAndFetch() async throws {
        let mock = MockCalendarService()
        let vmService: CalendarServiceProtocol = mock
        let event = CalendarEvent(
            title: "Test",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        let created = try await vmService.createEvent(event)
        XCTAssertEqual(created.title, "Test")
        let fetched = try await vmService.fetchEvents(start: nil, end: nil)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, created.id)
    }

    func testUpdateEvent() async throws {
        let mock = MockCalendarService()
        let service: CalendarServiceProtocol = mock
        var event = CalendarEvent(
            title: "Old",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        _ = try await service.createEvent(event)
        event.title = "New"
        let updated = try await service.updateEvent(event)
        XCTAssertEqual(updated.title, "New")
    }

    func testDeleteEvent() async throws {
        let mock = MockCalendarService()
        let service: CalendarServiceProtocol = mock
        let event = CalendarEvent(
            title: "ToDelete",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        _ = try await service.createEvent(event)
        try await service.deleteEvent(event.id)
        let fetched = try await service.fetchEvents(start: nil, end: nil)
        XCTAssertTrue(fetched.isEmpty)
    }
}

// MARK: - ViewModel Tests

final class CalendarViewModelTests: XCTestCase {
    var mock: MockCalendarService!
    var viewModel: CalendarViewModel!

    override func setUp() {
        super.setUp()
        mock = MockCalendarService()
        viewModel = CalendarViewModel(service: mock)
    }

    override func tearDown() {
        mock = nil
        viewModel = nil
        super.tearDown()
    }

    func testLoadEvents() async throws {
        let event = CalendarEvent(
            title: "Load",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        mock.events[event.id] = event
        await viewModel.loadEvents()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.events.first?.title, "Load")
    }

    func testCreateEventVM() async throws {
        let event = CalendarEvent(
            title: "VMCreate",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        await viewModel.createEvent(event)
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertEqual(viewModel.events.first?.title, "VMCreate")
    }

    func testUpdateEventVM() async throws {
        let event = CalendarEvent(
            title: "VMOld",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        await viewModel.createEvent(event)
        var e2 = event
        e2.title = "VMNew"
        await viewModel.updateEvent(e2)
        XCTAssertEqual(viewModel.events.first?.title, "VMNew")
    }

    func testDeleteEventVM() async throws {
        let event = CalendarEvent(
            title: "VMDel",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            createdBy: "tester"
        )
        await viewModel.createEvent(event)
        await viewModel.deleteEvent(event.id)
        XCTAssertTrue(viewModel.events.isEmpty)
    }
}
