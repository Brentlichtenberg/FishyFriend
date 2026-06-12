import Foundation
import SwiftData

@Model
final class Waterway {
    var id: String
    var name: String
    var region: String
    var county: String
    var tributaryOf: String?
    var latitude: Double
    var longitude: Double
    var wdfwCRCCode: String?
    var waterwayDescription: String

    init(
        id: String,
        name: String,
        region: String,
        county: String,
        tributaryOf: String? = nil,
        latitude: Double,
        longitude: Double,
        wdfwCRCCode: String? = nil,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.county = county
        self.tributaryOf = tributaryOf
        self.latitude = latitude
        self.longitude = longitude
        self.wdfwCRCCode = wdfwCRCCode
        self.waterwayDescription = description
    }
}

// MARK: - Seed DTO
struct WaterwayDTO: Codable {
    let id: String
    let name: String
    let region: String
    let county: String
    let tributaryOf: String?
    let latitude: Double
    let longitude: Double
    let wdfwCRCCode: String?
    let description: String

    func toModel() -> Waterway {
        Waterway(
            id: id,
            name: name,
            region: region,
            county: county,
            tributaryOf: tributaryOf,
            latitude: latitude,
            longitude: longitude,
            wdfwCRCCode: wdfwCRCCode,
            description: description
        )
    }
}
