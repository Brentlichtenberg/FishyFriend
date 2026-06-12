import Foundation
import os

/// Central dependency container. Inject via @EnvironmentObject.
@MainActor
final class AppEnvironment: ObservableObject {
    let waterwayRepo: WaterwayRepository
    let regulationRepo: RegulationRepository
    let historicalRepo: HistoricalDataRepository
    let engine: RecommendationEngine

    init() {
        let wRepo = WaterwayRepository()
        let rRepo = RegulationRepository()
        let hRepo = HistoricalDataRepository()
        waterwayRepo = wRepo
        regulationRepo = rRepo
        historicalRepo = hRepo
        engine = RecommendationEngine(
            waterwayRepo: wRepo,
            regulationRepo: rRepo,
            historicalRepo: hRepo
        )
    }
}
