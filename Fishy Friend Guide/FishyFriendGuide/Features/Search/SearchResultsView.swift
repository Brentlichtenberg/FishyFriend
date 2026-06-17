import SwiftUI

// MARK: - Main Search Results View

struct SearchResultsView: View {
    let query: String
    let onDismiss: () -> Void

    @EnvironmentObject private var env: AppEnvironment
    @State private var selectedWaterway: Waterway? = nil
    @State private var creelData: [CreelCatchSummary] = []
    @State private var isLoadingCreel = false

    private var matchedWaterways: [Waterway] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return env.waterwayRepo.allWaterways()
            .filter {
                $0.name.lowercased().contains(q) ||
                $0.region.lowercased().contains(q) ||
                $0.county.lowercased().contains(q)
            }
            .sorted { a, b in
                // Exact prefix matches first
                let aPrefix = a.name.lowercased().hasPrefix(q)
                let bPrefix = b.name.lowercased().hasPrefix(q)
                if aPrefix != bPrefix { return aPrefix }
                return a.name < b.name
            }
    }

    var body: some View {
        NavigationSplitView {
            // Left: matching waterways list
            VStack(spacing: 0) {
                searchHeader
                Divider().background(Color.outlineVariant)
                if matchedWaterways.isEmpty {
                    emptyState
                } else {
                    List(matchedWaterways, selection: $selectedWaterway) { w in
                        WaterwaySearchRow(waterway: w)
                            .tag(w)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            .background(Color.surfaceContainerLow)
        } detail: {
            if let waterway = selectedWaterway {
                WaterwaySearchDetailView(
                    waterway: waterway,
                    creelSummary: creelData.first {
                        $0.catchAreaCode == waterway.wdfwCRCCode ||
                        waterway.name.lowercased().contains($0.waterBody.lowercased().components(separatedBy: " ").first?.lowercased() ?? "")
                    }
                )
            } else if !matchedWaterways.isEmpty {
                ContentUnavailableView("Select a River", systemImage: "map",
                    description: Text("Choose a river from the list to see fishing conditions."))
                    .background(Color.appBackground)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            selectedWaterway = matchedWaterways.first
            await loadCreelData()
        }
        .onChange(of: query) {
            Task { await loadCreelData() }
        }
    }

    private var searchHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Search Results")
                    .font(.headlineSm)
                    .foregroundStyle(Color.onSurface)
                Text("\"\(query)\" · \(matchedWaterways.count) river\(matchedWaterways.count == 1 ? "" : "s") found")
                    .font(.labelMd)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appOutline)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.outlineVariant)
            Text("No rivers found for \"\(query)\"")
                .font(.headlineSm)
                .foregroundStyle(Color.onSurfaceVariant)
            Text("Try searching by river name, region, or county.")
                .font(.bodyMd)
                .foregroundStyle(Color.appOutline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    @MainActor
    private func loadCreelData() async {
        isLoadingCreel = true
        creelData = (try? await env.creelService.fetchWeeklyCatch(for: Date(), windowWeeks: 1)) ?? []
        isLoadingCreel = false
    }
}

// MARK: - Waterway List Row

struct WaterwaySearchRow: View {
    let waterway: Waterway

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(waterway.name)
                .font(.bodyMd.bold())
                .foregroundStyle(Color.onSurface)
            Text(waterway.region)
                .font(.labelMd)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct WaterwaySearchDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let waterway: Waterway
    let creelSummary: CreelCatchSummary?

    private var regulations: [Regulation] { env.regulationRepo.regulations(for: waterway.id) }
    private var patterns: [MonthlyPattern] { env.historicalRepo.patterns(for: waterway.id) }
    private var recommendations: [FishingRecommendation] {
        env.engine.recommendations(for: Date(), includeClosedFisheries: true)
            .filter { $0.waterway.id == waterway.id }
    }

    private let weekDays: [Date] = {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: Date()) }
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Hero header
                heroHeader

                HStack(alignment: .top, spacing: 24) {
                    // Left column: 7-day forecast + regulations
                    VStack(alignment: .leading, spacing: 20) {
                        sevenDayForecast
                        if !regulations.isEmpty { regulationsCard }
                    }
                    .frame(maxWidth: .infinity)

                    // Right column: live creel + historical activity
                    VStack(alignment: .leading, spacing: 20) {
                        if let creel = creelSummary { liveCreelCard(creel) }
                        if !patterns.isEmpty { historicalActivityCard }
                    }
                    .frame(maxWidth: 300)
                }
            }
            .padding(32)
        }
        .background(Color.appBackground)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TagChip(label: waterway.region.uppercased(),
                            color: Color.appPrimary.opacity(0.10),
                            textColor: .appPrimary)
                    TagChip(label: waterway.county,
                            color: Color.surfaceContainerHigh,
                            textColor: .onSurfaceVariant)
                }
                Text(waterway.name)
                    .font(.headlineLg)
                    .foregroundStyle(Color.onSurface)
                if !waterway.waterwayDescription.isEmpty {
                    Text(waterway.waterwayDescription)
                        .font(.bodyLg)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }

            Spacer()

            // Overall score badge
            if let rec = recommendations.first {
                VStack(spacing: 6) {
                    Text(rec.scoreLabel)
                        .font(.headlineMd)
                    Text("This week")
                        .font(.labelMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                    StatusBadge(status: rec.regulationStatus)
                }
                .padding(16)
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
            }
        }
    }

    // MARK: - 7-Day Forecast

    private var sevenDayForecast: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "7-Day Fishing Forecast",
                          subtitle: "Historical catch activity by day · all prior years")

            let dateFormatter: DateFormatter = {
                let f = DateFormatter(); f.dateFormat = "EEE\nMMM d"; return f
            }()

            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    let dayRecs = env.engine.recommendations(for: day, includeClosedFisheries: true)
                        .filter { $0.waterway.id == waterway.id }
                    let topRec = dayRecs.first
                    let score = topRec?.score ?? 0
                    let isOpen = topRec?.regulationStatus == .open
                    let isToday = Calendar.current.isDateInToday(day)

                    VStack(spacing: 6) {
                        // Day label
                        Text(dateFormatter.string(from: day))
                            .font(.system(size: 10, weight: isToday ? .bold : .regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(isToday ? Color.appPrimary : Color.onSurfaceVariant)

                        // Activity bar
                        VStack(spacing: 0) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isOpen ? Color.catchIntensity(score) : Color.outlineVariant)
                                .frame(height: max(8, score * 80))
                        }
                        .frame(height: 80)

                        // Score %
                        Text(score > 0.01 ? "\(Int(score * 100))%" : "–")
                            .font(.monoData)
                            .foregroundStyle(score > 0.01 ? Color.onSurface : Color.appOutline)

                        // Open/closed dot
                        Circle()
                            .fill(isOpen ? Color.statusOpen : Color.statusClosed)
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isToday ? Color.appPrimary.opacity(0.05) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
            }
            .padding(16)
            .background(Color.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Color.statusOpen).frame(width: 8, height: 8)
                    Text("Open season").font(.system(size: 11)).foregroundStyle(Color.onSurfaceVariant)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.statusClosed).frame(width: 8, height: 8)
                    Text("Closed season").font(.system(size: 11)).foregroundStyle(Color.onSurfaceVariant)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.catchIntensity(0.8)).frame(width: 12, height: 8)
                    Text("Bar height = relative historical catch rate").font(.system(size: 11)).foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
    }

    // MARK: - Regulations Card

    private var regulationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "2025–2026 Regulations")
            ForEach(regulations) { reg in
                let status: RegulationStatus = reg.isOpen() ? .open : .closed
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reg.species)
                            .font(.labelLg)
                            .foregroundStyle(Color.onSurface)
                        if !reg.gearRestrictions.isEmpty {
                            Text(reg.gearRestrictions.joined(separator: " · "))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                        if let notes = reg.notes {
                            Text(notes)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appOutline)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        StatusBadge(status: status, compact: true)
                        Text("Limit: \(reg.bagLimit)")
                            .font(.monoData)
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }
                .padding(12)
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.outlineVariant, lineWidth: 1))
            }
        }
    }

    // MARK: - Live Creel Card

    private func liveCreelCard(_ creel: CreelCatchSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.appSecondary)
                Text("Historical Catch Data")
                    .font(.headlineSm)
                    .foregroundStyle(Color.onSurface)
            }

            Text("Same week · all prior years · WDFW creel surveys")
                .font(.labelMd)
                .foregroundStyle(Color.onSurfaceVariant)

            VStack(spacing: 8) {
                creelStat("Total Catch", value: "\(creel.totalCatch)", color: .appPrimary)
                creelStat("Harvested",   value: "\(creel.totalHarvest)", color: .statusClosed)
                creelStat("Released",    value: "\(creel.totalCatch - creel.totalHarvest)", color: .statusOpen)
                creelStat("Anglers",     value: "\(creel.totalAnglers)", color: .appSecondary)
            }

            // Activity intensity bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Relative Activity").font(.labelMd).foregroundStyle(Color.onSurfaceVariant)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.outlineVariant).frame(height: 10)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.catchIntensity(creel.normalizedScore))
                            .frame(width: geo.size.width * creel.normalizedScore, height: 10)
                    }
                }
                .frame(height: 10)
                Text("\(Int(creel.normalizedScore * 100))% relative to all monitored rivers this week")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appOutline)
            }

            if let desc = creel.sectionDescription {
                Text("Section: \(desc)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appOutline)
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }

    private func creelStat(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label).font(.bodyMd).foregroundStyle(Color.onSurface)
            Spacer()
            Text(value).font(.monoData.bold()).foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }

    // MARK: - Historical Activity Card

    private var historicalActivityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Monthly Activity",
                          subtitle: "Avg guide trips · all species")

            ForEach(patterns, id: \.waterwayId) { pattern in
                VStack(alignment: .leading, spacing: 6) {
                    Text(pattern.species)
                        .font(.labelLg)
                        .foregroundStyle(Color.onSurface)
                    ActivityBarChart(monthlyIndex: pattern.monthlyIndex)

                    HStack {
                        Text(pattern.notes ?? "")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appOutline)
                            .lineLimit(2)
                        Spacer()
                        if pattern.totalEncounters2021 > 0 {
                            Text("\(pattern.totalEncounters2021) encounters (2021)")
                                .font(.monoData)
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                    }
                }
                .padding(12)
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.outlineVariant, lineWidth: 1))
            }
        }
    }
}
