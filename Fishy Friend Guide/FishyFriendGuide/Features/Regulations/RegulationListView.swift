import SwiftUI

struct RegulationListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selectedDate = Date()
    @State private var filterSpecies: String = "All"

    private let speciesOptions = ["All", "Steelhead", "Salmon", "Trout", "Sturgeon"]

    private var regulations: [Regulation] {
        let regs = filterSpecies == "All"
            ? env.regulationRepo.openRegulations(on: selectedDate)
            : env.regulationRepo.openRegulations(on: selectedDate).filter { $0.species == filterSpecies }
        return regs.sorted { $0.waterwayId < $1.waterwayId }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            List(regulations) { reg in
                RegulationDetailRow(regulation: reg, waterwayName: waterwayName(for: reg.waterwayId))
            }
            .overlay {
                if regulations.isEmpty {
                    ContentUnavailableView("No Open Regulations", systemImage: "doc.text.slash",
                        description: Text("No open regulations for the selected filters."))
                }
            }
        }
        .navigationTitle("Regulations")
    }

    private var toolbar: some View {
        HStack {
            DatePicker("Check Date", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
            Spacer()
            Picker("Species", selection: $filterSpecies) {
                ForEach(speciesOptions, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
        }
        .padding()
    }

    private func waterwayName(for id: String) -> String {
        env.waterwayRepo.waterway(id: id)?.name ?? id
    }
}

struct RegulationDetailRow: View {
    let regulation: Regulation
    let waterwayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(waterwayName)
                    .font(.headline)
                Text("–")
                Text(regulation.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Limit: \(regulation.bagLimit)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            if !regulation.gearRestrictions.isEmpty {
                Text(regulation.gearRestrictions.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let notes = regulation.notes {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
