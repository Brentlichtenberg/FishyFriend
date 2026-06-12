import Foundation

// Regulation is not persisted in SwiftData — loaded from JSON bundle at startup.
struct Regulation: Codable, Identifiable {
    var id: String
    var waterwayId: String
    var species: String
    var openDateRanges: [DateRange]
    var bagLimit: Int
    var punchCardRequired: Bool
    var gearRestrictions: [String]
    var minimumSize: Int?
    var notes: String?

    /// Determines if this regulation is open on the given date.
    func isOpen(on date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return openDateRanges.contains { range in
            range.contains(month: month, day: day)
        }
    }
}

struct DateRange: Codable {
    var startMonth: Int
    var startDay: Int
    var endMonth: Int
    var endDay: Int

    /// Year-agnostic check. Handles ranges that wrap around year boundary (e.g. Oct–Mar).
    func contains(month: Int, day: Int) -> Bool {
        let current = month * 100 + day
        let start = startMonth * 100 + startDay
        let end = endMonth * 100 + endDay

        if start <= end {
            return current >= start && current <= end
        } else {
            // Wraps year boundary (e.g. Oct 1 – Mar 31)
            return current >= start || current <= end
        }
    }
}

enum RegulationStatus: String {
    case open = "Open"
    case closed = "Closed"
    case checkRegulations = "Check Regulations"

    var color: String {
        switch self {
        case .open: return "green"
        case .closed: return "red"
        case .checkRegulations: return "orange"
        }
    }
}
