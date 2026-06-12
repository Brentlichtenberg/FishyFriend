import Foundation

struct MonthlyPattern: Codable {
    let waterwayId: String
    let species: String
    /// 12 values, index 0 = January, 11 = December. 0.0–1.0 relative activity.
    let monthlyIndex: [Double]
    let peakMonth: Int
    let peakDay: Int
    let avgTripsPerYear: Int
    let totalEncounters2021: Int
    let notes: String?
}

struct HistoricalCatchDatabase: Codable {
    let metadata: Metadata
    let monthlyPatterns: [MonthlyPattern]

    struct Metadata: Codable {
        let sources: [String]
        let dataYears: [Int]
    }
}

// MARK: - Repository Protocol

protocol WaterwayRepositoryProtocol {
    func allWaterways() -> [Waterway]
    func waterway(id: String) -> Waterway?
    func waterways(in region: String) -> [Waterway]
}

protocol RegulationRepositoryProtocol {
    func regulations(for waterwayId: String) -> [Regulation]
    func regulation(id: String) -> Regulation?
    func openRegulations(on date: Date) -> [Regulation]
}

protocol CatchRecordRepositoryProtocol {
    func allRecords() -> [CatchRecord]
    func records(for waterwayId: String) -> [CatchRecord]
    func add(_ record: CatchRecord)
    func delete(_ record: CatchRecord)
}

protocol HistoricalDataRepositoryProtocol {
    func patterns(for waterwayId: String) -> [MonthlyPattern]
    func pattern(waterwayId: String, species: String) -> MonthlyPattern?
    func allPatterns() -> [MonthlyPattern]
}
