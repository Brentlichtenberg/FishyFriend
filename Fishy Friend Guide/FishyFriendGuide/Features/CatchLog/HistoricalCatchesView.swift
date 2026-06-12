import SwiftUI
import SwiftData

struct HistoricalCatchesView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    @State private var selectedRegion = "Olympic Peninsula"
    private let regions = ["Olympic Peninsula", "Central Cascades", "Columbia River Basin"]

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 24) {
                // Main: catch log
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Historical Log & Forecast")
                            .font(.headlineLg)
                            .foregroundStyle(.onSurface)
                        Text("Review your historical data and sync with the Washington regional weather models.")
                            .font(.bodyMd)
                            .foregroundStyle(.onSurfaceVariant)
                    }

                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.appSecondary)
                            Text("Recent Entries")
                                .font(.headlineSm)
                                .foregroundStyle(.onSurface)
                        }
                        Spacer()
                        Button {
                            // Export CSV action
                        } label: {
                            HStack(spacing: 4) {
                                Text("Export CSV")
                                    .font(.labelLg)
                                    .foregroundStyle(.appSecondary)
                                Image(systemName: "arrow.down.to.line")
                                    .font(.caption.bold())
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if records.isEmpty {
                        EmptyCatchState()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(records.prefix(10)) { record in
                                CatchRecordCard(record: record, waterwayName: waterwayName(for: record.waterwayId))
                            }
                        }

                        // Load more
                        Button {
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.appSecondary)
                                Text("Load More Historical Data")
                                    .font(.labelLg)
                                    .foregroundStyle(.appSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                    .foregroundStyle(Color.outlineVariant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)

                // Right sidebar: forecast
                VStack(spacing: 16) {
                    RegionalForecastCard(selectedRegion: $selectedRegion, regions: regions)
                    ConservationistInsightCard()
                    RegionalStationMapCard()
                }
                .frame(width: 300)
            }
            .padding(32)
        }
        .background(Color.appBackground)
    }

    private func waterwayName(for id: String) -> String {
        env.waterwayRepo.waterway(id: id)?.name ?? id
    }
}

// MARK: - Catch Record Card

struct CatchRecordCard: View {
    let record: CatchRecord
    let waterwayName: String

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Photo placeholder
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 120, height: 100)
                    .overlay(
                        Image(systemName: "fish.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.appPrimary.opacity(0.3))
                    )
                TagChip(
                    label: record.species.uppercased(),
                    color: Color.appPrimary.opacity(0.85),
                    textColor: .white
                )
                .padding(6)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(waterwayName)
                            .font(.headlineSm)
                            .foregroundStyle(.onSurface)
                    }
                    Spacer()
                    Text(Self.dateFormatter.string(from: record.date))
                        .font(.monoData)
                        .foregroundStyle(.onSurfaceVariant)
                        .padding(6)
                        .background(Color.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }

                HStack(spacing: 24) {
                    statItem(label: "COUNT", value: "\(record.count)")
                    statItem(label: "KEPT", value: "\(record.kept)")
                    statItem(label: "RELEASED", value: "\(record.released)")
                }

                if let notes = record.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.appOutline)
                        Text(notes)
                            .font(.system(size: 13))
                            .italic()
                            .foregroundStyle(.onSurfaceVariant)
                            .lineLimit(2)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
        }
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
        .appCardShadow()
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.labelMd)
                .foregroundStyle(.onSurfaceVariant)
            Text(value)
                .font(.monoData.bold())
                .foregroundStyle(.appPrimary)
        }
    }
}

struct EmptyCatchState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fish")
                .font(.system(size: 40))
                .foregroundStyle(.outlineVariant)
            Text("No catch records yet")
                .font(.headlineSm)
                .foregroundStyle(.onSurfaceVariant)
            Text("Log your first catch using the + New Catch button above.")
                .font(.bodyMd)
                .foregroundStyle(.appOutline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Regional Forecast Card

struct RegionalForecastCard: View {
    @Binding var selectedRegion: String
    let regions: [String]

    // Placeholder forecast data
    let forecast: [DayForecast] = [
        .init(day: "MON", icon: "sun.max.fill",     high: 48, low: 32, barProgress: 0.8),
        .init(day: "TUE", icon: "cloud.fill",        high: 45, low: 38, barProgress: 0.5),
        .init(day: "WED", icon: "cloud.rain.fill",   high: 42, low: 35, barProgress: 0.3),
        .init(day: "THU", icon: "cloud.rain.fill",   high: 40, low: 33, barProgress: 0.2),
        .init(day: "FRI", icon: "cloud.sun.fill",    high: 46, low: 31, barProgress: 0.6),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(.appSecondary)
                    Text("Regional Forecast")
                        .font(.headlineSm)
                        .foregroundStyle(.onSurface)
                }
                Spacer()
                Menu(selectedRegion) {
                    ForEach(regions, id: \.self) { region in
                        Button(region) { selectedRegion = region }
                    }
                }
                .font(.labelMd)
                .foregroundStyle(.onSurfaceVariant)
            }

            // Current conditions
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT: FORK, WA")
                        .font(.labelMd)
                        .foregroundStyle(.onSurfaceVariant)
                    Text("42°")
                        .font(.displayLg)
                        .foregroundStyle(.onSurface)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.onSurfaceVariant)
                    Text("Overcast")
                        .font(.labelLg)
                        .foregroundStyle(.onSurfaceVariant)
                }
            }

            Divider().background(Color.outlineVariant)

            // 5-day forecast
            VStack(spacing: 10) {
                ForEach(forecast) { day in
                    ForecastRow(day: day)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }
}

struct ForecastRow: View {
    let day: DayForecast

    var body: some View {
        HStack(spacing: 12) {
            Text(day.day)
                .font(.labelLg)
                .foregroundStyle(.onSurfaceVariant)
                .frame(width: 32, alignment: .leading)
            Image(systemName: day.icon)
                .foregroundStyle(.conservationGold)
                .frame(width: 20)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appSecondary)
                    .frame(width: geo.size.width * day.barProgress, height: 4)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 4)
            .background(Color.outlineVariant)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            Text("\(day.high)° / \(day.low)°")
                .font(.monoData)
                .foregroundStyle(.onSurface)
                .frame(width: 64, alignment: .trailing)
        }
    }
}

struct DayForecast: Identifiable {
    let id = UUID()
    let day: String
    let icon: String
    let high: Int
    let low: Int
    let barProgress: Double
}

struct ConservationistInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.appSecondary)
                Text("Conservationist Insight")
                    .font(.labelLg)
                    .foregroundStyle(.appSecondary)
            }
            Text("Pressure is dropping. Expect active feeding in the Sol Duc mainstem over the next 48 hours. River levels predicted to rise +0.8ft by Wednesday evening.")
                .font(.bodyMd)
                .foregroundStyle(.onSurface)
        }
        .padding(16)
        .background(Color.appSecondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.appSecondary.opacity(0.2), lineWidth: 1))
    }
}

struct RegionalStationMapCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(Color.surfaceContainerHighest)
                .frame(height: 130)
                .overlay(
                    Image(systemName: "map.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appOutline.opacity(0.2))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("Regional Station Map")
                    .font(.headlineSm)
                    .foregroundStyle(.onSurface)
                Text("Active USGS Gauges: 14")
                    .font(.labelMd)
                    .foregroundStyle(.onSurfaceVariant)
                Button { } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "map")
                            .font(.caption)
                        Text("Explore Stations")
                            .font(.labelLg)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
    }
}
