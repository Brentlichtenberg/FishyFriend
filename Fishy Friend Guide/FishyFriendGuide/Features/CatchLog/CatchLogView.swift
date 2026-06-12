import SwiftUI
import SwiftData

struct CatchLogView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]
    @State private var showingAddSheet = false

    var body: some View {
        VStack {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Catch Records",
                    systemImage: "note.text.badge.plus",
                    description: Text("Log your first catch to start building your history.")
                )
            } else {
                List {
                    ForEach(records) { record in
                        CatchRecordRow(record: record, waterwayName: waterwayName(for: record.waterwayId))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(records[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("My Catch Log")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Log Catch", systemImage: "plus") {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CatchEntryView()
        }
    }

    private func waterwayName(for id: String) -> String {
        env.waterwayRepo.waterway(id: id)?.name ?? id
    }
}

struct CatchRecordRow: View {
    let record: CatchRecord
    let waterwayName: String

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(waterwayName)
                    .font(.headline)
                Spacer()
                Text(Self.dateFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label("\(record.species)", systemImage: "fish.fill")
                Text("Caught: \(record.count)")
                if record.kept > 0 { Text("Kept: \(record.kept)") }
                if record.released > 0 { Text("Released: \(record.released)") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
