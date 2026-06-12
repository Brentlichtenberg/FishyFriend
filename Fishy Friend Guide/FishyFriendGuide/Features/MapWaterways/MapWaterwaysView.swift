import SwiftUI
import MapKit

// MARK: - Catch Intensity Color Scale

extension Color {
    /// Perceptual color scale: transparent → green → amber → orange → deep red
    static func catchIntensity(_ score: Double) -> Color {
        switch score {
        case 0..<0.01:  return .clear
        case 0.01..<0.2: return Color(hex: "#2E7D32")   // dark green
        case 0.2..<0.4:  return Color(hex: "#F9A825")   // amber
        case 0.4..<0.65: return Color(hex: "#E64A19")   // deep orange
        default:          return Color(hex: "#B71C1C")   // deep red
        }
    }
}

// MARK: - ViewModel

@Observable
final class MapWaterwaysViewModel {
    var heatmapData: [CreelCatchSummary] = []
    var isLoading = false
    var showHeatmap = true
    var selectedDate: Date = Date()
    var windowWeeks: Int = 2
    var selectedSummary: CreelCatchSummary? = nil
    var errorMessage: String? = nil

    private let creel = WDFWCreelService()

    var weekLabel: String {
        let cal = Calendar(identifier: .gregorian)
        let week = cal.component(.weekOfYear, from: selectedDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = cal.date(from: DateComponents(
            weekOfYear: week, yearForWeekOfYear: cal.component(.yearForWeekOfYear, from: selectedDate)))!
        return "Wk \(week) — \(formatter.string(from: start))"
    }

    @MainActor
    func loadHeatmap() async {
        isLoading = true
        errorMessage = nil
        do {
            let results = try await creel.fetchWeeklyCatch(for: selectedDate, windowWeeks: windowWeeks)
            heatmapData = results
        } catch {
            errorMessage = "Could not load catch data: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Main View

struct MapWaterwaysView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var vm = MapWaterwaysViewModel()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.5, longitude: -122.8),
            span: MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
        )
    )
    private let streamflows = StreamflowReading.placeholders
    private var topSpots: [WaterwaySpot] { WaterwaySpot.placeholderSpots }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Map with waterway pins + heatmap overlays
            Map(position: $cameraPosition) {
                // Waterway center pins
                ForEach(env.waterwayRepo.allWaterways()) { w in
                    Annotation(w.name, coordinate: CLLocationCoordinate2D(latitude: w.latitude, longitude: w.longitude)) {
                        WaterwayPin(waterway: w, catchSummary: catchSummary(for: w))
                    }
                }

                // Heatmap circles
                if vm.showHeatmap {
                    ForEach(heatmapCircles) { circle in
                        MapCircle(center: circle.center, radius: circle.radius)
                            .foregroundStyle(Color.catchIntensity(circle.score).opacity(0.30))
                            .stroke(Color.catchIntensity(circle.score).opacity(0.65), lineWidth: 2)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .ignoresSafeArea()

            // Left: Streamflow panel
            VStack(alignment: .leading, spacing: 12) {
                heatmapControlPanel
                StreamflowPanel(readings: streamflows)
            }
            .padding(16)

            // Right: Spot cards
            VStack(alignment: .trailing) {
                SpotCardsPanel(spots: topSpots)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(16)

            // Bottom left: legend + map controls
            VStack(alignment: .leading, spacing: 8) {
                if vm.showHeatmap { HeatmapLegend() }
                MapControlsOverlay()
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.leading, 16)
            .padding(.bottom, 20)

            // Selected section detail
            if let sel = vm.selectedSummary {
                SectionDetailPopup(summary: sel) { vm.selectedSummary = nil }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 24)
            }
        }
        .task { await vm.loadHeatmap() }
        .onChange(of: vm.selectedDate) { Task { await vm.loadHeatmap() } }
        .onChange(of: vm.windowWeeks) { Task { await vm.loadHeatmap() } }
    }

    // MARK: - Heatmap Control Panel

    private var heatmapControlPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.conservationGold)
                Text("Historical Catch Heatmap")
                    .font(.labelLg)
                    .foregroundStyle(.onSurface)
                Spacer()
                Toggle("", isOn: $vm.showHeatmap)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }

            if vm.showHeatmap {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.onSurfaceVariant)
                    DatePicker("", selection: $vm.selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .controlSize(.small)
                    Text("±\(vm.windowWeeks)wk")
                        .font(.monoData)
                        .foregroundStyle(.onSurfaceVariant)
                    Stepper("", value: $vm.windowWeeks, in: 1...4)
                        .labelsHidden()
                        .controlSize(.small)
                }

                if vm.isLoading {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Loading \(vm.weekLabel) data…")
                            .font(.labelMd)
                            .foregroundStyle(.onSurfaceVariant)
                    }
                } else {
                    Text("\(vm.heatmapData.filter { $0.totalCatch > 0 }.count) active river sections · all prior years · \(vm.weekLabel)")
                        .font(.labelMd)
                        .foregroundStyle(.onSurfaceVariant)
                }

                if let err = vm.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.labelMd)
                        .foregroundStyle(.statusClosed)
                }
            }
        }
        .padding(14)
        .floatGlass(tint: Color.appPrimary.opacity(0.05))
        .frame(maxWidth: 300)
    }

    // MARK: - Helpers

    private var heatmapCircles: [HeatmapCircle] {
        vm.heatmapData.compactMap { summary -> HeatmapCircle? in
            guard let waterway = findWaterway(for: summary), summary.totalCatch > 0 else { return nil }
            let radius: CLLocationDistance = 6_000 + summary.normalizedScore * 22_000
            return HeatmapCircle(
                id: summary.id,
                center: CLLocationCoordinate2D(latitude: waterway.latitude, longitude: waterway.longitude),
                radius: radius,
                score: summary.normalizedScore
            )
        }
    }

    private func findWaterway(for summary: CreelCatchSummary) -> Waterway? {
        env.waterwayRepo.allWaterways().first { w in
            w.wdfwCRCCode == summary.catchAreaCode ||
            w.name.localizedCaseInsensitiveContains(summary.waterBody.components(separatedBy: " - ").first ?? summary.waterBody)
        }
    }

    private func catchSummary(for waterway: Waterway) -> CreelCatchSummary? {
        vm.heatmapData.first { $0.catchAreaCode == waterway.wdfwCRCCode }
    }
}

// MARK: - Heatmap Circle Model

struct HeatmapCircle: Identifiable {
    let id: String
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let score: Double
}

// MARK: - Waterway Pin (updated with catch data)

struct WaterwayPin: View {
    let waterway: Waterway
    let catchSummary: CreelCatchSummary?

    var body: some View {
        let score = catchSummary?.normalizedScore ?? 0
        ZStack {
            Circle()
                .fill(score > 0.01 ? Color.catchIntensity(score) : Color.appPrimary)
                .frame(width: score > 0.5 ? 16 : 11, height: score > 0.5 ? 16 : 11)
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: score > 0.5 ? 16 : 11, height: score > 0.5 ? 16 : 11)
        }
        .appSubtleShadow()
    }
}

// MARK: - Heatmap Legend

struct HeatmapLegend: View {
    private let steps: [(String, Color)] = [
        ("Low", Color.catchIntensity(0.1)),
        ("Medium", Color.catchIntensity(0.35)),
        ("High", Color.catchIntensity(0.6)),
        ("Very High", Color.catchIntensity(0.85)),
    ]

    var body: some View {
        HStack(spacing: 10) {
            Text("CATCH").font(.labelMd).foregroundStyle(.onSurfaceVariant)
            ForEach(steps, id: \.0) { label, color in
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(.onSurface)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .floatGlass()
    }
}

// MARK: - Section Detail Popup

struct SectionDetailPopup: View {
    let summary: CreelCatchSummary
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.waterBody)
                    .font(.headlineSm)
                    .foregroundStyle(.onSurface)
                Text("Section \(summary.catchAreaCode)")
                    .font(.labelMd)
                    .foregroundStyle(.onSurfaceVariant)
            }

            Divider().frame(height: 40)

            statBlock(label: "TOTAL CATCH", value: "\(summary.totalCatch)")
            statBlock(label: "HARVESTED",   value: "\(summary.totalHarvest)")
            statBlock(label: "RELEASED",    value: "\(summary.totalCatch - summary.totalHarvest)")
            statBlock(label: "ANGLERS",     value: "\(summary.totalAnglers)")

            Spacer()

            HStack(spacing: 4) {
                Circle().fill(Color.catchIntensity(summary.normalizedScore)).frame(width: 10)
                Text(String(format: "%.0f%%", summary.normalizedScore * 100) + " relative activity")
                    .font(.labelMd)
                    .foregroundStyle(.onSurfaceVariant)
            }

            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.onSurfaceVariant)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .floatGlass()
        .padding(.horizontal, 60)
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.monoData.bold())
                .foregroundStyle(.appPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.onSurfaceVariant)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Streamflow + Spot reused types (unchanged)

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
                ForEach(readings) { reading in StreamflowRow(reading: reading) }
            }
        }
        .padding(16)
        .floatGlass()
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

struct MapControlsOverlay: View {
    var body: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 4) {
                VStack(spacing: 4) {
                    mapControlButton(icon: "plus")
                    mapControlButton(icon: "minus")
                    Divider().frame(width: 28).padding(.vertical, 2)
                    mapControlButton(icon: "location.fill")
                    mapControlButton(icon: "square.3.layers.3d")
                }
                .padding(6)
            }
            .appCardShadow()
        } else {
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
    }

    private func mapControlButton(icon: String) -> some View {
        Button { } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.onSurface)
                .frame(width: 36, height: 36)
        }
        .modifier(MapControlButtonModifier())
    }
}

private struct MapControlButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.plain)
        }
    }
}

struct SpotCardsPanel: View {
    let spots: [WaterwaySpot]

    var body: some View {
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
                    ForEach(spots) { spot in SpotCard(spot: spot) }
                }
                .padding(12)
            }
            .frame(maxHeight: 560)

            Divider().background(Color.outlineVariant)
            Button { } label: {
                HStack {
                    Text("View All Spot Data").font(.labelLg).foregroundStyle(.appSecondary)
                    Image(systemName: "arrow.forward").font(.caption.bold()).foregroundStyle(.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
            }
            .buttonStyle(.plain)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .modifier(SpotPanelGlassModifier())
        .appCardShadow()
        .frame(width: 280)
    }
}

struct SpotCard: View {
    let spot: WaterwaySpot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(height: 100)
                    .overlay(Image(systemName: "water.waves").font(.system(size: 32)).foregroundStyle(Color.appPrimary.opacity(0.3)))
                TagChip(label: spot.category, color: Color.charcoalBark.opacity(0.75), textColor: .white).padding(8)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(spot.name).font(.bodyMd.bold()).foregroundStyle(.onSurface)
                    Spacer()
                    Text(spot.condition.rawValue.uppercased()).font(.labelMd).foregroundStyle(spot.condition.color)
                }
                HStack(spacing: 6) { ForEach(spot.patterns, id: \.self) { p in TagChip(label: p) } }
                HStack(spacing: 16) {
                    Label("\(spot.tempF)°F", systemImage: "thermometer.medium").font(.labelMd).foregroundStyle(.onSurfaceVariant)
                    Label("\(String(format: "%.1f", spot.visibilityFt))ft", systemImage: "eye").font(.labelMd).foregroundStyle(.onSurfaceVariant)
                }
            }
            .padding(10)
        }
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }
}


// MARK: - Supporting Data Models

struct StreamflowReading: Identifiable {
    let id = UUID()
    let stationName: String
    let cfs: Int
    let normalizedLevel: Double
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
        .init(stationName: "Snoqualmie nr Falls",    cfs: 820,   normalizedLevel: 0.25),
    ]
}

enum SpotCondition: String {
    case favorable = "Favorable", moderate = "Moderate", stable = "Stable", poor = "Poor"
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
        .init(name: "Skykomish River", category: "Steelhead",  condition: .favorable, patterns: ["Intruder","Egg"],          tempF: 48, visibilityFt: 2.0),
        .init(name: "Sol Duc River",   category: "Fly Fishing", condition: .favorable, patterns: ["#8 Stimulator","WD-40"],  tempF: 52, visibilityFt: 4.5),
        .init(name: "Cowlitz River",   category: "Steelhead",  condition: .moderate,  patterns: ["Prom Queen","Flashabou"], tempF: 51, visibilityFt: 3.0),
    ]
}

private struct SpotPanelGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: AppRadius.lg))
        } else {
            content
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
        }
    }
}
