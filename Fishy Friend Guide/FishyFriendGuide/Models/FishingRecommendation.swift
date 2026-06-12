import Foundation

struct FishingRecommendation: Identifiable {
    let id: String
    let waterway: Waterway
    let species: String
    let score: Double                        // 0–1 normalized
    let historicalActivity: Double          // avg guide trips per day for this date window
    let peakDateDescription: String         // e.g. "Peaks late February"
    let regulationStatus: RegulationStatus
    let gearRestrictions: [String]
    let bagLimit: Int
    let punchCardRequired: Bool
    let notes: String?

    var scoreLabel: String {
        switch score {
        case 0.8...: return "🔥 Hot"
        case 0.6..<0.8: return "✅ Good"
        case 0.4..<0.6: return "🟡 Fair"
        default: return "⬇️ Slow"
        }
    }
}
