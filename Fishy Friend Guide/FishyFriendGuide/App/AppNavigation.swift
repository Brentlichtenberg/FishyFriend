import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case map           = "Map & Waterways"
    case hatchGuide    = "Hatch Guide"
    case regulations   = "Regulations"
    case historicalCatches = "Historical Catches"
    case weather       = "Weather"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .map:               return "map"
        case .hatchGuide:        return "ant"
        case .regulations:       return "scalemass"
        case .historicalCatches: return "clock.arrow.circlepath"
        case .weather:           return "thermometer.medium"
        }
    }
}

@Observable
final class NavigationState {
    var selectedSection: AppSection = .map
    var showingNewCatch = false
}
