import SwiftUI
import MapKit

struct MapWaterwaysView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.6, longitude: -121.8),
            span: MKCoordinateSpan(latitudeDelta: 2.5, longitudeDelta: 2.5)
        )
    )

    private var waterways: [Waterway] { env.waterwayRepo.allWaterways() }
    private var topSpots: [WaterwaySpot] { WaterwaySpot.placeholderSpots }
    private let streamflows = StreamflowReading.placeholders

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-bleed map
            Map(position: $cameraPosition) {
                ForEach(waterways) { w in
                    Annotation(w.name, coordinate: CLLocationCoordinate2D(latitude: w.latitude, longitude: w.longitude)) {
                        WaterwayPin(waterway: w)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Streamflow overlay
            StreamflowPanel(readings: streamflows)
                .padding(16)

            // Spot cards panel — right side
            VStack(alignment: .trailing) {
                SpotCardsPanel(spots: topSpots)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(16)

            // Map controls
            MapControlsOverlay()
                .padding(.leading, 16)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 80)
        }
    }
}

// MARK: - Waterway Pin

struct WaterwayPin: View {
    let waterway: Waterway

    var body: some View {
        Circle()
            .fill(Color.appPrimary)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .appSubtleShadow()
    }
}

// MARK: - Streamflow Panel

struct StreamflowPanel: View {
    let readings: [StreamflowReading]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.labelLg)
                    .foregroundStyle(.appSecondary)
                Text("Live Streamflow Data")
                    .font(.labelLg)
                    .foregroundStyle(.onSurface)
            }

            VStack(spacing: 10) {
                ForEach(readings) { reading in
                    StreamflowRow(reading: reading)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .appCardShadow()
        .frame(maxWidth: 260)
    }
}

struct StreamflowRow: View {
    let reading: StreamflowReading

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(reading.stationName)
                    .font(.bodyMd)
                    .foregroundStyle(.onSurface)
                Spacer()
                Text(reading.cfsFormatted)
                    .font(.monoData)
                    .foregroundStyle(reading.levelColor)
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(reading.levelColor)
                    .frame(width: geo.size.width * reading.normalizedLevel, height: 4)
            }
            .frame(height: 4)
            .background(Color.outlineVariant)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}

// MARK: - Spot Cards Panel

struct SpotCardsPanel: View {
    let spots: [WaterwaySpot]
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommended Spots")
                            .font(.headlineSm)
                            .foregroundStyle(.onSurface)
                        Text("Washington State • Today")
                            .font(.labelMd)
                            .foregroundStyle(.onSurfaceVariant)
                    }
                    Spacer()
                }
                .padding(16)

                Divider().background(Color.outlineVariant)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(spots) { spot in
                            SpotCard(spot: spot)
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 560)

                Divider().background(Color.outlineVariant)
                Button { } label: {
                    HStack {
                        Text("View All Spot Data")
                            .font(.labelLg)
                            .foregroundStyle(.appSecondary)
                        Image(systemName: "arrow.forward")
                            .font(.caption.bold())
                            .foregroundStyle(.appSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .appCardShadow()
            .frame(width: 280)
        }
    }
}

struct SpotCard: View {
    let spot: WaterwaySpot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image placeholder
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(height: 100)
                    .overlay(
                        Image(systemName: "water.waves")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.appPrimary.opacity(0.3))
                    )
                TagChip(label: spot.category, color: Color.charcoalBark.opacity(0.75), textColor: .white)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(spot.name)
                        .font(.bodyMd.bold())
                        .foregroundStyle(.onSurface)
                    Spacer()
                    Text(spot.condition.rawValue.uppercased())
                        .font(.labelMd)
                        .foregroundStyle(spot.condition.color)
                }

                // Pattern chips
                HStack(spacing: 6) {
                    ForEach(spot.patterns, id: \.self) { p in
                        TagChip(label: p)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(spot.tempF)°F", systemImage: "thermometer.medium")
                        .font(.labelMd)
                        .foregroundStyle(.onSurfaceVariant)
                    Label("\(String(format: "%.1f", spot.visibilityFt))ft", systemImage: "eye")
                        .font(.labelMd)
                        .foregroundStyle(.onSurfaceVariant)
                }
            }
            .padding(10)
        }
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }
}

// MARK: - Map Controls

struct MapControlsOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            mapControlButton(icon: "plus")
            mapControlButton(icon: "minus")
            Divider().frame(width: 36)
            mapControlButton(icon: "location.fill")
            mapControlButton(icon: "square.3.layers.3d")
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .appCardShadow()
    }

    private func mapControlButton(icon: String) -> some View {
        Button { } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.onSurface)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Models

struct StreamflowReading: Identifiable {
    let id = UUID()
    let stationName: String
    let cfs: Int
    let normalizedLevel: Double  // 0–1

    var cfsFormatted: String { "\(cfs.formatted())" }
    var levelColor: Color {
        switch normalizedLevel {
        case 0.7...: return .appSecondary
        case 0.4..<0.7: return .appPrimary
        default: return .conservationGold
        }
    }

    static let placeholders: [StreamflowReading] = [
        .init(stationName: "Skykomish at Gold Bar", cfs: 12_800, normalizedLevel: 0.85),
        .init(stationName: "Cowlitz at Castle Rock", cfs: 4_210, normalizedLevel: 0.55),
        .init(stationName: "Snoqualmie nr Falls", cfs: 820, normalizedLevel: 0.25),
    ]
}

enum SpotCondition: String {
    case favorable = "Favorable"
    case moderate  = "Moderate"
    case stable    = "Stable"
    case poor      = "Poor"

    var color: Color {
        switch self {
        case .favorable: return .statusOpen
        case .moderate:  return .conservationGold
        case .stable:    return .appSecondary
        case .poor:      return .statusClosed
        }
    }
}

struct WaterwaySpot: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let condition: SpotCondition
    let patterns: [String]
    let tempF: Int
    let visibilityFt: Double

    static let placeholderSpots: [WaterwaySpot] = [
        .init(name: "Skykomish River", category: "Steelhead", condition: .favorable, patterns: ["Intruder", "Egg"], tempF: 48, visibilityFt: 2.0),
        .init(name: "Sol Duc River", category: "Fly Fishing", condition: .favorable, patterns: ["#8 Stimulator", "WD-40"], tempF: 52, visibilityFt: 4.5),
        .init(name: "Cowlitz River", category: "Steelhead", condition: .moderate, patterns: ["Prom Queen", "Flashabou"], tempF: 51, visibilityFt: 3.0),
    ]
}
