import SwiftUI
import SwiftData

struct CatchEntryView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedWaterwayId: String = ""
    @State private var date: Date = Date()
    @State private var species: String = "Steelhead"
    @State private var count: Int = 1
    @State private var kept: Int = 0
    @State private var released: Int = 1
    @State private var gearUsed: String = ""
    @State private var notes: String = ""

    private let speciesOptions = ["Steelhead", "Chinook", "Coho", "Chum", "Pink", "Sockeye", "Cutthroat", "Rainbow Trout", "Other"]

    private var waterways: [Waterway] {
        env.waterwayRepo.allWaterways().sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("River", selection: $selectedWaterwayId) {
                        Text("Select a river…").tag("")
                        ForEach(waterways) { w in
                            Text(w.name).tag(w.id)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Catch") {
                    Picker("Species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { Text($0) }
                    }
                    Stepper("Count: \(count)", value: $count, in: 1...99)
                    Stepper("Kept: \(kept)", value: $kept, in: 0...count)
                    Stepper("Released: \(released)", value: $released, in: 0...count)
                }

                Section("Details") {
                    TextField("Gear used", text: $gearUsed)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Log Catch")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedWaterwayId.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    private func save() {
        let record = CatchRecord(
            waterwayId: selectedWaterwayId,
            date: date,
            species: species,
            count: count,
            kept: kept,
            released: released,
            gearUsed: gearUsed.isEmpty ? nil : gearUsed,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(record)
        dismiss()
    }
}
