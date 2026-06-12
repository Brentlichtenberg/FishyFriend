import Foundation
import os

/// Core logic for ranking western WA rivers by fishing quality for a given date.
/// 
/// Algorithm:
/// 1. Look up the monthly activity index for the current month (from guide logbook data).
/// 2. Interpolate a ±7-day window around today to smooth the index.
/// 3. Weight by regulation status (open = 1.0, closed = 0.0, unknown = 0.5).
/// 4. Normalize scores 0–1 across all results.
/// 5. Sort descending.
final class RecommendationEngine {
    private let logger = Logger(subsystem: "com.appsonapps.fishyfriendguide", category: "RecommendationEngine")
    private let waterwayRepo: WaterwayRepositoryProtocol
    private let regulationRepo: RegulationRepository
    private let historicalRepo: HistoricalDataRepositoryProtocol

    init(
        waterwayRepo: WaterwayRepositoryProtocol,
        regulationRepo: RegulationRepository,
        historicalRepo: HistoricalDataRepositoryProtocol
    ) {
        self.waterwayRepo = waterwayRepo
        self.regulationRepo = regulationRepo
        self.historicalRepo = historicalRepo
    }

    /// Returns recommendations sorted by score, filtered to open or unknown-status fisheries.
    func recommendations(for date: Date = Date(), includeClosedFisheries: Bool = false) -> [FishingRecommendation] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date) // 1-based
        let day = calendar.component(.day, from: date)

        var results: [FishingRecommendation] = []

        for pattern in historicalRepo.allPatterns() {
            guard let waterway = waterwayRepo.waterway(id: pattern.waterwayId) else { continue }

            let monthIdx = month - 1 // 0-based
            guard pattern.monthlyIndex.count == 12 else { continue }

            // Smooth: interpolate between current and neighboring months based on day of month
            let rawIndex = interpolatedIndex(pattern.monthlyIndex, month: monthIdx, day: day)

            // Regulation status
            let status = regulationRepo.status(for: pattern.waterwayId, species: pattern.species, on: date)
            let regulationWeight: Double
            switch status {
            case .open: regulationWeight = 1.0
            case .closed: regulationWeight = 0.0
            case .checkRegulations: regulationWeight = 0.5
            }

            guard includeClosedFisheries || status != .closed else { continue }

            let rawScore = rawIndex * regulationWeight

            // Fetch regulation detail for the recommendation card
            let reg = regulationRepo.regulations(for: pattern.waterwayId)
                .first { $0.species == pattern.species }

            let peakDesc = peakDescription(month: pattern.peakMonth, day: pattern.peakDay)

            results.append(FishingRecommendation(
                id: "\(pattern.waterwayId)-\(pattern.species)",
                waterway: waterway,
                species: pattern.species,
                score: rawScore,
                historicalActivity: Double(pattern.avgTripsPerYear) / 365.0,
                peakDateDescription: peakDesc,
                regulationStatus: status,
                gearRestrictions: reg?.gearRestrictions ?? [],
                bagLimit: reg?.bagLimit ?? 0,
                punchCardRequired: reg?.punchCardRequired ?? false,
                notes: reg?.notes
            ))
        }

        // Normalize scores to 0–1
        let maxScore = results.map(\.score).max() ?? 1.0
        if maxScore > 0 {
            results = results.map { rec in
                FishingRecommendation(
                    id: rec.id,
                    waterway: rec.waterway,
                    species: rec.species,
                    score: rec.score / maxScore,
                    historicalActivity: rec.historicalActivity,
                    peakDateDescription: rec.peakDateDescription,
                    regulationStatus: rec.regulationStatus,
                    gearRestrictions: rec.gearRestrictions,
                    bagLimit: rec.bagLimit,
                    punchCardRequired: rec.punchCardRequired,
                    notes: rec.notes
                )
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    // MARK: - Private

    /// Linearly interpolates the monthly index using day of month to smooth transitions.
    private func interpolatedIndex(_ indices: [Double], month: Int, day: Int) -> Double {
        let current = indices[month]
        if day <= 15 {
            // First half of month: blend with previous month
            let prev = indices[(month - 1 + 12) % 12]
            let t = Double(day) / 15.0
            return prev + (current - prev) * t
        } else {
            // Second half: blend toward next month
            let next = indices[(month + 1) % 12]
            let t = Double(day - 15) / 15.0
            return current + (next - current) * t
        }
    }

    private func peakDescription(month: Int, day: Int) -> String {
        let monthNames = ["", "January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
        guard month >= 1, month <= 12 else { return "Unknown" }
        let weekLabel: String
        switch day {
        case 1...7: weekLabel = "early"
        case 8...20: weekLabel = "mid"
        default: weekLabel = "late"
        }
        return "Peaks \(weekLabel) \(monthNames[month])"
    }
}
