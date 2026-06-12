import Foundation
import SwiftData

@Model
final class CatchRecord {
    var id: UUID
    var waterwayId: String
    var date: Date
    var species: String
    var count: Int
    var kept: Int
    var released: Int
    var gearUsed: String?
    var notes: String?
    var sourceReport: String?

    init(
        id: UUID = UUID(),
        waterwayId: String,
        date: Date,
        species: String,
        count: Int,
        kept: Int = 0,
        released: Int = 0,
        gearUsed: String? = nil,
        notes: String? = nil,
        sourceReport: String? = nil
    ) {
        self.id = id
        self.waterwayId = waterwayId
        self.date = date
        self.species = species
        self.count = count
        self.kept = kept
        self.released = released
        self.gearUsed = gearUsed
        self.notes = notes
        self.sourceReport = sourceReport
    }
}
