import SwiftUI

struct RecommendationCard: View {
    let recommendation: FishingRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.waterway.name)
                        .font(.headline)
                    Text(recommendation.waterway.region)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(recommendation.scoreLabel)
                        .font(.subheadline.bold())
                    statusBadge
                }
            }

            Divider()

            // Info grid
            HStack(spacing: 20) {
                infoItem(label: "Species", value: recommendation.species)
                infoItem(label: "Bag Limit", value: "\(recommendation.bagLimit)")
                infoItem(label: "Punch Card", value: recommendation.punchCardRequired ? "Required" : "Not required")
                infoItem(label: "Activity", value: recommendation.peakDateDescription)
            }

            if !recommendation.gearRestrictions.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(recommendation.gearRestrictions.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let notes = recommendation.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .cardGlass()
    }

    private var statusBadge: some View {
        let status = recommendation.regulationStatus
        let color: Color = switch status {
        case .open: .green
        case .closed: .red
        case .checkRegulations: .orange
        }
        return Text(status.rawValue)
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
