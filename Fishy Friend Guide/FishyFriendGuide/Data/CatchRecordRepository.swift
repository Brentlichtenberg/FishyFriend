import Foundation
import SwiftData
import os

final class CatchRecordRepository: CatchRecordRepositoryProtocol {
    private let logger = Logger(subsystem: "com.appsonapps.fishyfriendguide", category: "CatchRecordRepository")
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allRecords() -> [CatchRecord] {
        let descriptor = FetchDescriptor<CatchRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func records(for waterwayId: String) -> [CatchRecord] {
        let descriptor = FetchDescriptor<CatchRecord>(
            predicate: #Predicate { $0.waterwayId == waterwayId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(_ record: CatchRecord) {
        context.insert(record)
        try? context.save()
    }

    func delete(_ record: CatchRecord) {
        context.delete(record)
        try? context.save()
    }
}
