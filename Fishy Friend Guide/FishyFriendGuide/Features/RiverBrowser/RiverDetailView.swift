import SwiftUI

struct RiverDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let waterway: Waterway

    private var regulations: [Regulation] {
        env.regulationRepo.regulations(for: waterway.id)
    }

    private var patterns: [MonthlyPattern] {
        env.historicalRepo.patterns(for: waterway.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(waterway.name)
                        .font(.largeTitle.bold())
                    HStack {
                        Label(waterway.region, systemImage: "map.fill")
                        Spacer()
                        Label(waterway.county, systemImage: "building.2")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if !waterway.waterwayDescription.isEmpty {
                        Text(waterway.waterwayDescription)
                            .font(.body)
                            .padding(.top, 4)
                    }
                }

                Divider()

                // Regulations
                if !regulations.isEmpty {
                    regulationsSection
                }

                // Historical activity chart
                if !patterns.isEmpty {
                    historicalSection
                }
            }
            .padding()
        }
        .navigationTitle(waterway.name)
    }

    private var regulationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("2025–2026 Regulations")
                .font(.title2.bold())

            ForEach(regulations) { reg in
                RegulationRowView(regulation: reg)
            }
        }
    }

    private var historicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historical Activity")
                .font(.title2.bold())

            ForEach(patterns, id: \.waterwayId) { pattern in
                VStack(alignment: .leading, spacing: 6) {
                    Text(pattern.species)
                        .font(.headline)
                    ActivityBarChart(monthlyIndex: pattern.monthlyIndex)
                    Text(pattern.notes ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct RegulationRowView: View {
    @EnvironmentObject private var env: AppEnvironment
    let regulation: Regulation

    private var currentStatus: RegulationStatus {
        regulation.isOpen() ? .open : .closed
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(regulation.species)
                        .font(.headline)
                    Spacer()
                    statusBadge
                }

                HStack(spacing: 20) {
                    infoItem(label: "Bag Limit", value: "\(regulation.bagLimit)")
                    infoItem(label: "Punch Card", value: regulation.punchCardRequired ? "Yes" : "No")
                    if let minSize = regulation.minimumSize {
                        infoItem(label: "Min Size", value: "\(minSize)\"")
                    }
                }

                if !regulation.gearRestrictions.isEmpty {
                    Text("Restrictions: " + regulation.gearRestrictions.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let notes = regulation.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var statusBadge: some View {
        let color: Color = currentStatus == .open ? .green : .red
        return Text(currentStatus.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
    }
}

struct ActivityBarChart: View {
    let monthlyIndex: [Double]
    private let monthAbbr = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<12, id: \.self) { i in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(barColor(monthlyIndex[i]))
                        .frame(width: 20, height: max(4, monthlyIndex[i] * 60))
                    Text(monthAbbr[i])
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func barColor(_ value: Double) -> Color {
        switch value {
        case 0.7...: return .green
        case 0.4..<0.7: return .yellow
        default: return .gray.opacity(0.4)
        }
    }
}
