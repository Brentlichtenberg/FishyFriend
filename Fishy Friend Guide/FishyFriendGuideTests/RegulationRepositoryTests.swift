import XCTest
@testable import FishyFriendGuide

final class RegulationRepositoryTests: XCTestCase {

    private var repo: RegulationRepository!

    override func setUp() {
        super.setUp()
        repo = RegulationRepository()
    }

    func testRegulationsLoadSuccessfully() {
        XCTAssertFalse(repo.regulations(for: "cowlitz-river").isEmpty, "Cowlitz should have regulations")
    }

    func testCowlitzOpenInOctober() {
        let october = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 15))!
        let status = repo.status(for: "cowlitz-river", species: "Steelhead", on: october)
        XCTAssertEqual(status, .open, "Cowlitz should be open for steelhead in October")
    }

    func testDateRangeWrapsYearBoundary() {
        // Cowlitz steelhead season: Memorial Day (late May) through Apr 30 — wraps year boundary
        let february = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let status = repo.status(for: "cowlitz-river", species: "Steelhead", on: february)
        XCTAssertEqual(status, .open, "Cowlitz steelhead should be open in February")
    }

    func testDateRangeContainment_WrapAround() {
        // Test DateRange.contains wrapping logic
        let range = DateRange(startMonth: 10, startDay: 1, endMonth: 3, endDay: 31)
        XCTAssertTrue(range.contains(month: 10, day: 15), "Oct 15 should be in Oct–Mar range")
        XCTAssertTrue(range.contains(month: 1, day: 15), "Jan 15 should be in Oct–Mar range")
        XCTAssertTrue(range.contains(month: 3, day: 31), "Mar 31 should be in Oct–Mar range")
        XCTAssertFalse(range.contains(month: 6, day: 15), "Jun 15 should NOT be in Oct–Mar range")
    }

    func testDateRangeContainment_NonWrapping() {
        let range = DateRange(startMonth: 6, startDay: 1, endMonth: 9, endDay: 30)
        XCTAssertTrue(range.contains(month: 7, day: 4))
        XCTAssertFalse(range.contains(month: 10, day: 1))
        XCTAssertFalse(range.contains(month: 5, day: 31))
    }
}
