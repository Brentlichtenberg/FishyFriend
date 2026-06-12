import SwiftUI

struct HatchGuideView: View {
    @State private var searchText = ""
    private let insects = HatchInsect.washingtonInsects

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Washington Hatch Guide")
                                    .font(.labelLg)
                                    .foregroundStyle(.appSecondary)
                            }
                            Text("Comprehensive monitoring of insect life cycles across\nWashington's watersheds.")
                                .font(.bodyMd)
                                .foregroundStyle(.onSurfaceVariant)
                        }
                        Spacer()
                        TagChip(label: "REGION: PNW-WA", color: .surfaceContainerHigh, textColor: .onSurfaceVariant)
                    }
                }

                // Insect cards grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(insects) { insect in
                        InsectCard(insect: insect)
                    }
                }

                // Compliance Checklist
                ComplianceChecklist()

                // Upcoming Peak Hatches table
                UpcomingHatchesTable()

                // Footer
                ConservationFooter()
            }
            .padding(32)
        }
        .background(Color.appBackground)
    }
}

// MARK: - Insect Card

struct InsectCard: View {
    let insect: HatchInsect

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(insect.color.opacity(0.15))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: insect.systemIcon)
                            .font(.system(size: 40))
                            .foregroundStyle(insect.color.opacity(0.5))
                    )
                HStack {
                    TagChip(label: insect.category.uppercased(), color: insect.color.opacity(0.85), textColor: .white)
                    Spacer()
                    Text(insect.species)
                        .font(.labelMd)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.trailing, 8)
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(insect.commonName)
                    .font(.headlineSm)
                    .foregroundStyle(.onSurface)

                // Timeline bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("HATCH TIMELINE")
                        .font(.labelMd)
                        .foregroundStyle(.onSurfaceVariant)
                    HatchTimelineBar(activeMonths: insect.activeMonths)
                    HStack {
                        Text("JAN").font(.system(size: 9)).foregroundStyle(.appOutline)
                        Spacer()
                        Text("JUN").font(.system(size: 9)).foregroundStyle(.appOutline)
                        Spacer()
                        Text("DEC").font(.system(size: 9)).foregroundStyle(.appOutline)
                    }
                }

                // Patterns
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECOMMENDED PATTERNS")
                        .font(.labelMd)
                        .foregroundStyle(.onSurfaceVariant)
                    FlowLayout(spacing: 6) {
                        ForEach(insect.patterns, id: \.self) { pattern in
                            TagChip(label: pattern)
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
        .appCardShadow()
    }
}

struct HatchTimelineBar: View {
    let activeMonths: Set<Int>  // 1-based months

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...12, id: \.self) { month in
                RoundedRectangle(cornerRadius: 1)
                    .fill(activeMonths.contains(month) ? Color.appPrimary : Color.outlineVariant)
                    .frame(height: 6)
            }
        }
    }
}

// MARK: - Compliance Checklist

struct ComplianceChecklist: View {
    @State private var barblessChecked = true
    @State private var aisChecked = false

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Regional Compliance Checklist")
                    .font(.labelLg)
                    .foregroundStyle(.appSecondary)

                ChecklistItem(isChecked: $barblessChecked,
                              title: "Barbless Hook Verification",
                              detail: "Mandatory for all WDFW designated selective gear waters in the Olympic Peninsula.")

                ChecklistItem(isChecked: $aisChecked,
                              title: "Aquatic Invasive Species (AIS) Check",
                              detail: "Inspect waders for New Zealand Mudsnails before moving between watersheds.")
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))

            // Pro tip card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.appSecondary)
                    Text("PRO TIP: LOW WATER TACTICS")
                        .font(.labelLg)
                        .foregroundStyle(.appSecondary)
                }
                Text("During the late-summer Caddis hatches, focus on high-oxygenated riffles and pocket water. Use lighter 5X tippet to minimize drag in clear, slow-moving pools.")
                    .font(.bodyMd)
                    .foregroundStyle(.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.appSecondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.appSecondary.opacity(0.2), lineWidth: 1))
        }
    }
}

struct ChecklistItem: View {
    @Binding var isChecked: Bool
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                isChecked.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(isChecked ? Color.appSecondary : Color.outlineVariant, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.appSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.labelLg)
                    .foregroundStyle(.onSurface)
                Text(detail)
                    .font(.bodyMd)
                    .foregroundStyle(.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Upcoming Hatches Table

struct UpcomingHatchesTable: View {
    let rows = UpcomingHatch.sampleData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Peak Hatches")
                    .font(.headlineSm)
                    .foregroundStyle(.onSurface)
                Spacer()
                Button { } label: {
                    HStack(spacing: 4) {
                        Text("View Full Season Calendar")
                            .font(.labelLg)
                            .foregroundStyle(.appSecondary)
                        Image(systemName: "arrow.forward")
                            .font(.caption.bold())
                            .foregroundStyle(.appSecondary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Table
            VStack(spacing: 0) {
                // Header
                HStack {
                    columnHeader("SPECIES", width: nil)
                    columnHeader("STATUS", width: 100)
                    columnHeader("PEAK WINDOW", width: 160)
                    columnHeader("KEY RIVER SYSTEMS", width: nil)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.surfaceContainerHigh)

                ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                    HStack {
                        Text(row.species)
                            .font(.bodyMd)
                            .foregroundStyle(.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(row.status.color)
                                .frame(width: 8, height: 8)
                            Text(row.status.rawValue)
                                .font(.labelLg)
                                .foregroundStyle(row.status.color)
                        }
                        .frame(width: 100, alignment: .leading)
                        Text(row.peakWindow)
                            .font(.monoData)
                            .foregroundStyle(.onSurfaceVariant)
                            .frame(width: 160, alignment: .leading)
                        Text(row.keyRivers)
                            .font(.bodyMd)
                            .foregroundStyle(.onSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(idx % 2 == 0 ? Color.appBackground : Color.surfaceContainerLow)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
        }
    }

    private func columnHeader(_ text: String, width: CGFloat?) -> some View {
        Text(text)
            .font(.labelMd)
            .foregroundStyle(.onSurfaceVariant)
            .frame(minWidth: 0, maxWidth: width ?? .infinity, alignment: .leading)
    }
}

struct ConservationFooter: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conservation First")
                    .font(.headlineSm)
                    .foregroundStyle(.onSurface)
                Text("By understanding the lifecycle of our local insects, we better appreciate the fragile health of Washington's waterways. Catch and release with care.")
                    .font(.bodyMd)
                    .foregroundStyle(.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("RESOURCES").font(.labelLg).foregroundStyle(.onSurfaceVariant)
                Button("WDFW Regulations") { }
                    .buttonStyle(.plain)
                    .font(.bodyMd)
                    .foregroundStyle(.appSecondary)
                Button("Flow Data (USGS)") { }
                    .buttonStyle(.plain)
                    .font(.bodyMd)
                    .foregroundStyle(.appSecondary)
                Button("Local Shops") { }
                    .buttonStyle(.plain)
                    .font(.bodyMd)
                    .foregroundStyle(.appSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DATA SOURCE").font(.labelLg).foregroundStyle(.onSurfaceVariant)
                Text("WDFW Regulations").font(.bodyMd).foregroundStyle(.onSurfaceVariant)
                Text("Flow Data (USGS)").font(.bodyMd).foregroundStyle(.onSurfaceVariant)
                Text("User Reports").font(.bodyMd).foregroundStyle(.onSurfaceVariant)
            }
        }
        .padding(24)
        .background(Color.charcoalBark)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for size in sizes {
            if rowWidth + size.width + (rowWidth > 0 ? spacing : 0) > maxWidth {
                width = max(width, rowWidth)
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        return CGSize(width: max(width, rowWidth), height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Data Models

struct HatchInsect: Identifiable {
    let id = UUID()
    let category: String
    let commonName: String
    let species: String
    let activeMonths: Set<Int>
    let patterns: [String]
    let systemIcon: String
    let color: Color

    static let washingtonInsects: [HatchInsect] = [
        .init(category: "Mayflies", commonName: "Blue Winged Olive", species: "Baetis Spp.",
              activeMonths: [3,4,5,9,10,11], patterns: ["Parachute Adams", "RS2 Nymph", "WD-40"],
              systemIcon: "leaf.fill", color: .appPrimary),
        .init(category: "Caddisflies", commonName: "October Caddis", species: "Dicosmoecus",
              activeMonths: [9,10,11], patterns: ["Orange Stimulator", "Pecka's Pupa"],
              systemIcon: "ant.fill", color: .conservationGold),
        .init(category: "Stoneflies", commonName: "Golden Stone", species: "Hesperoperla",
              activeMonths: [4,5,6,7], patterns: ["Pats Rubber Legs", "Golden Chubby", "20 Incher"],
              systemIcon: "sparkle", color: .appSecondary),
        .init(category: "Mayflies", commonName: "Pale Morning Dun", species: "Ephemerella",
              activeMonths: [5,6,7,8], patterns: ["Sparkle Dun", "CDC Dun", "Pheasant Tail"],
              systemIcon: "sun.min.fill", color: Color(hex: "#8B7355")),
        .init(category: "Midges", commonName: "Chironomid", species: "Chironomidae",
              activeMonths: [1,2,3,10,11,12], patterns: ["Zebra Midge", "Red Zebra", "Mercury Midge"],
              systemIcon: "circle.dotted", color: .statusClosed),
        .init(category: "Stoneflies", commonName: "Salmonfly", species: "Pteronarcys",
              activeMonths: [5,6], patterns: ["Chubby Chernobyl", "Kaufmann Stone", "Stimulator"],
              systemIcon: "flame.fill", color: Color(hex: "#C55A28")),
    ]
}

enum HatchStatus: String {
    case active   = "Active"
    case emerging = "Emerging"
    case dormant  = "Dormant"

    var color: Color {
        switch self {
        case .active:   return .statusOpen
        case .emerging: return .conservationGold
        case .dormant:  return .appOutline
        }
    }
}

struct UpcomingHatch: Identifiable {
    let id = UUID()
    let species: String
    let status: HatchStatus
    let peakWindow: String
    let keyRivers: String

    static let sampleData: [UpcomingHatch] = [
        .init(species: "Salmonfly",       status: .active,   peakWindow: "May 15 – Jun 20",  keyRivers: "Yakima, Klickitat"),
        .init(species: "Pale Morning Dun", status: .emerging, peakWindow: "Jun 01 – Jul 15",  keyRivers: "Yakima, Methow"),
        .init(species: "October Caddis",   status: .dormant,  peakWindow: "Sep 15 – Nov 01",  keyRivers: "Cowlitz, Sol Duc, Hoh"),
        .init(species: "Trico",           status: .dormant,  peakWindow: "Aug 15 – Sep 30",  keyRivers: "Lower Yakima"),
    ]
}
