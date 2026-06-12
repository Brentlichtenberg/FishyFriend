import Foundation
import os

final class RegulationRepository: RegulationRepositoryProtocol {
    private let logger = Logger(subsystem: "com.appsonapps.fishyfriendguide", category: "RegulationRepository")
    private let regulations: [Regulation]

    init() {
        guard let url = Bundle.main.url(forResource: "regulations_2025", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode([Regulation].self, from: data) else {
            logger.error("Failed to load regulations_2025.json")
            regulations = []
            return
        }
        regulations = loaded
        logger.debug("Loaded \(loaded.count) regulations")
    }

    func regulations(for waterwayId: String) -> [Regulation] {
        regulations.filter { $0.waterwayId == waterwayId }
    }

    func regulation(id: String) -> Regulation? {
        regulations.first { $0.id == id }
    }

    func openRegulations(on date: Date = Date()) -> [Regulation] {
        regulations.filter { $0.isOpen(on: date) }
    }

    func status(for waterwayId: String, species: String, on date: Date = Date()) -> RegulationStatus {
        let regs = regulations.filter { $0.waterwayId == waterwayId && $0.species == species }
        if regs.isEmpty { return .checkRegulations }
        return regs.contains { $0.isOpen(on: date) } ? .open : .closed
    }
}
