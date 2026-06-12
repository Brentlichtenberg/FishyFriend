import Foundation
import os

final class HistoricalDataRepository: HistoricalDataRepositoryProtocol {
    private let logger = Logger(subsystem: "com.appsonapps.fishyfriendguide", category: "HistoricalDataRepository")
    private let patterns: [MonthlyPattern]

    init() {
        guard let url = Bundle.main.url(forResource: "historical_catch_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? JSONDecoder().decode(HistoricalCatchDatabase.self, from: data) else {
            logger.error("Failed to load historical_catch_data.json")
            patterns = []
            return
        }
        patterns = db.monthlyPatterns
        logger.debug("Loaded \(db.monthlyPatterns.count) historical patterns")
    }

    func patterns(for waterwayId: String) -> [MonthlyPattern] {
        patterns.filter { $0.waterwayId == waterwayId }
    }

    func pattern(waterwayId: String, species: String) -> MonthlyPattern? {
        patterns.first { $0.waterwayId == waterwayId && $0.species == species }
    }

    func allPatterns() -> [MonthlyPattern] { patterns }
}
