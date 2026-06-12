import Foundation

final class WaterwayRepository: WaterwayRepositoryProtocol {
    private let waterways: [Waterway]

    init() {
        guard let url = Bundle.main.url(forResource: "western_wa_waterways", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([WaterwayDTO].self, from: data) else {
            os_log(.error, "WaterwayRepository: failed to load western_wa_waterways.json")
            waterways = []
            return
        }
        waterways = dtos.map { $0.toModel() }
        os_log(.debug, "WaterwayRepository: loaded %d waterways", waterways.count)
    }

    func allWaterways() -> [Waterway] { waterways }

    func waterway(id: String) -> Waterway? {
        waterways.first { $0.id == id }
    }

    func waterways(in region: String) -> [Waterway] {
        waterways.filter { $0.region == region }
    }

    var allRegions: [String] {
        Array(Set(waterways.map(\.region))).sorted()
    }
}

import os
