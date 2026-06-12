import XCTest
@testable import FishyFriendGuide

final class RecommendationEngineTests: XCTestCase {

    private var engine: RecommendationEngine!
    private var waterwayRepo: WaterwayRepository!
    private var regulationRepo: RegulationRepository!
    private var historicalRepo: HistoricalDataRepository!

    override func setUp() {
        super.setUp()
        waterwayRepo = WaterwayRepository()
        regulationRepo = RegulationRepository()
        historicalRepo = HistoricalDataRepository()
        engine = RecommendationEngine(
            waterwayRepo: waterwayRepo,
            regulationRepo: regulationRepo,
            historicalRepo: historicalRepo
        )
    }

    func testReturnsResultsForAnyDate() {
        // Given any date
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        // When
        let results = engine.recommendations(for: date)
        // Then — must return at least one recommendation in January (winter steelhead season)
        XCTAssertFalse(results.isEmpty, "Should have recommendations for January 15")
    }

    func testScoresNormalizedBetweenZeroAndOne() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 5))!
        let results = engine.recommendations(for: date, includeClosedFisheries: true)
        for rec in results {
            XCTAssertGreaterThanOrEqual(rec.score, 0.0, "Score must be >= 0")
            XCTAssertLessThanOrEqual(rec.score, 1.0, "Score must be <= 1")
        }
    }

    func testResultsSortedByScoreDescending() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 28))!
        let results = engine.recommendations(for: date, includeClosedFisheries: true)
        guard results.count > 1 else { return }
        for i in 0..<results.count - 1 {
            XCTAssertGreaterThanOrEqual(results[i].score, results[i+1].score,
                "Results should be sorted descending by score")
        }
    }

    func testClosedFisheriesExcludedByDefault() {
        // In June, most steelhead rivers are closed
        let june = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let results = engine.recommendations(for: june, includeClosedFisheries: false)
        for rec in results {
            XCTAssertNotEqual(rec.regulationStatus, .closed, "Closed fisheries should not appear in default results")
        }
    }

    func testCowlitzAppearsInWinterRecommendations() {
        // Cowlitz is one of the top winter steelhead rivers
        let january = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let results = engine.recommendations(for: january)
        let cowlitz = results.first { $0.waterway.id == "cowlitz-river" }
        XCTAssertNotNil(cowlitz, "Cowlitz River should appear in January recommendations")
    }
}
