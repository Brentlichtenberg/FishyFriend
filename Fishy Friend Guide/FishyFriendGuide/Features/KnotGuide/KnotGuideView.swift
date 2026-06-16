import SwiftUI

// MARK: - Main View

struct KnotGuideView: View {
    @State private var selectedCategory: KnotCategory = .terminalKnots
    @State private var selectedKnotId: String? = "improved-clinch"
    @State private var showQuickRef = false

    private var knotsInCategory: [FlyFishingKnot] {
        KnotGuideData.knots.filter { $0.category == selectedCategory }
    }

    private var selectedKnot: FlyFishingKnot? {
        KnotGuideData.knots.first { $0.id == selectedKnotId }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Category + Knot List
            leftPanel

            Divider().background(Color.outlineVariant)

            // Right: Detail
            if selectedCategory == .fundamentals {
                KnotFundamentalsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let knot = selectedKnot {
                KnotDetailView(knot: knot)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedCategory == .rigging {
                RiggingListView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("Select a Knot", systemImage: "link",
                    description: Text("Choose a knot from the list to see instructions and diagrams."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showQuickRef) {
            QuickReferenceView()
        }
    }

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Knot Guide")
                        .font(.headlineSm)
                        .foregroundStyle(Color.onSurface)
                    Text("Fly Fishing Knots & Rigging")
                        .font(.labelMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
                Button {
                    showQuickRef = true
                } label: {
                    Label("Quick Ref", systemImage: "list.bullet.rectangle")
                        .font(.labelMd)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.appSecondary)
            }
            .padding(16)

            Divider().background(Color.outlineVariant)

            ScrollView {
                VStack(spacing: 2) {
                    // Terminology & Tips (always visible)
                    categoryRow(.fundamentals)

                    ForEach(KnotCategory.allCases.filter { $0 != .fundamentals }) { cat in
                        categoryRow(cat)
                        if selectedCategory == cat && cat != .rigging {
                            ForEach(KnotGuideData.knots.filter { $0.category == cat }) { knot in
                                knotRow(knot)
                            }
                        }
                        if selectedCategory == cat && cat == .rigging {
                            ForEach(KnotGuideData.rigging) { rig in
                                riggingRow(rig)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 240)
        .background(Color.surfaceContainerLow)
    }

    private func categoryRow(_ cat: KnotCategory) -> some View {
        Button {
            selectedCategory = cat
            if cat == .fundamentals {
                selectedKnotId = nil
            } else if cat == .rigging {
                selectedKnotId = nil
            } else {
                selectedKnotId = KnotGuideData.knots.first(where: { $0.category == cat })?.id
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: cat.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selectedCategory == cat ? Color.appPrimary : Color.onSurfaceVariant)
                    .frame(width: 18)
                Text(cat.rawValue)
                    .font(.labelLg)
                    .foregroundStyle(selectedCategory == cat ? Color.appPrimary : Color.onSurface)
                Spacer()
                if cat != .fundamentals {
                    let count = cat == .rigging
                        ? KnotGuideData.rigging.count
                        : KnotGuideData.knots.filter { $0.category == cat }.count
                    Text("\(count)")
                        .font(.labelMd)
                        .foregroundStyle(Color.appOutline)
                }
                if selectedCategory == cat && cat != .fundamentals {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                selectedCategory == cat ? Color.appPrimary.opacity(0.08) : Color.clear,
                in: RoundedRectangle(cornerRadius: AppRadius.md)
            )
        }
        .buttonStyle(.plain)
    }

    private func knotRow(_ knot: FlyFishingKnot) -> some View {
        Button {
            selectedKnotId = knot.id
        } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(selectedKnotId == knot.id ? Color.appPrimary : Color.outlineVariant)
                    .frame(width: 2, height: 28)
                    .clipShape(Capsule())
                VStack(alignment: .leading, spacing: 1) {
                    Text(knot.name)
                        .font(.bodyMd)
                        .foregroundStyle(selectedKnotId == knot.id ? Color.appPrimary : Color.onSurface)
                    Text(knot.connection)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.vertical, 5)
            .background(
                selectedKnotId == knot.id ? Color.appPrimary.opacity(0.05) : Color.clear,
                in: RoundedRectangle(cornerRadius: AppRadius.sm)
            )
        }
        .buttonStyle(.plain)
    }

    private func riggingRow(_ rig: RiggingSetup) -> some View {
        Button {
            // handled in RiggingListView
        } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.outlineVariant)
                    .frame(width: 2, height: 28)
                    .clipShape(Capsule())
                Text(rig.name)
                    .font(.bodyMd)
                    .foregroundStyle(Color.onSurface)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Knot Detail View

struct KnotDetailView: View {
    let knot: FlyFishingKnot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                headerCard

                // Illustrations full-width above steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("ILLUSTRATIONS")
                        .font(.labelMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                    KnotDiagramView(diagram: knot.diagram)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(Color.outlineVariant, lineWidth: 1)
                        )
                        .appCardShadow()
                }

                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("STEP-BY-STEP")
                        .font(.labelMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                    stepsView
                }

                // Tips
                if !knot.proTips.isEmpty {
                    proTipsView
                }
            }
            .padding(32)
        }
        .background(Color.appBackground)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TagChip(label: knot.category.rawValue.uppercased(),
                                color: Color.appPrimary.opacity(0.1),
                                textColor: .appPrimary)
                        if !knot.altNames.isEmpty {
                            TagChip(label: "aka: " + knot.altNames.joined(separator: ", "),
                                    color: Color.surfaceContainerHigh,
                                    textColor: .onSurfaceVariant)
                        }
                    }
                    Text(knot.name)
                        .font(.headlineLg)
                        .foregroundStyle(Color.onSurface)
                    Text(knot.description)
                        .font(.bodyLg)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
                // Stats card
                VStack(spacing: 8) {
                    statBox(label: "CONNECTS", value: knot.connection)
                    if let strength = knot.strength {
                        statBox(label: "STRENGTH", value: strength)
                    }
                    statBox(label: "BEST FOR", value: knot.bestFor)
                }
                .frame(width: 240)
                .padding(14)
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
            }
        }
    }

    private func statBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.labelMd)
                .foregroundStyle(Color.appSecondary)
            Text(value)
                .font(.bodyMd)
                .foregroundStyle(Color.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(knot.steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 12) {
                    // Step number circle
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 26, height: 26)
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(step)
                        .font(.bodyMd)
                        .foregroundStyle(Color.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(12)
                .background(idx % 2 == 0 ? Color.surfaceContainerLow : Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    private var proTipsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.conservationGold)
                Text("PRO TIPS")
                    .font(.labelLg)
                    .foregroundStyle(Color.conservationGold)
            }
            ForEach(Array(knot.proTips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 14))
                        .padding(.top, 2)
                    Text(tip)
                        .font(.bodyMd)
                        .foregroundStyle(Color.onSurface)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.conservationGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.conservationGold.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Knot Diagram View (PDF illustrations)

struct KnotDiagramView: View {
    let diagram: KnotDiagramType

    var body: some View {
        switch diagram {
        case .pages(let filenames):
            KnotPageImagesView(filenames: filenames)
        case .conceptText(let text):
            ConceptTextDiagram(text: text)
        }
    }
}

/// Displays one or more rendered PDF page images stacked vertically.
/// Each image is the full PDF page — we clip the top header area (FFI logo/title bar)
/// and let the illustrations fill the panel naturally.
struct KnotPageImagesView: View {
    let filenames: [String]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(filenames, id: \.self) { filename in
                if let nsImage = NSImage(named: filename) ?? loadBundleImage(filename) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .clipped()
                        .padding(.top, -24)
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.statusRestricted)
                        Text("Illustration not found: \(filename)")
                            .font(.labelMd)
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                }

                if filenames.count > 1 && filename != filenames.last {
                    Divider()
                        .background(Color.outlineVariant)
                        .padding(.horizontal, 16)
                }
            }

            // Attribution
            Text("Illustrations courtesy of Fly Fishers International · flyfishersinternational.org")
                .font(.system(size: 10))
                .foregroundStyle(Color.appOutline)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
    }

    private func loadBundleImage(_ filename: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: (filename as NSString).deletingPathExtension,
                                        withExtension: (filename as NSString).pathExtension),
              let img = NSImage(contentsOf: url) else { return nil }
        return img
    }
}

private struct ConceptTextDiagram: View {
    let text: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.appSecondary)
            Text(text)
                .font(.bodyMd)
                .foregroundStyle(Color.onSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("See animatedknots.com for video demonstrations")
                .font(.labelMd)
                .foregroundStyle(Color.appSecondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Fundamentals View (shown when Fundamentals category selected)

struct KnotFundamentalsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fundamentals")
                        .font(.headlineLg)
                        .foregroundStyle(Color.onSurface)
                    Text("Essential terminology, tips, and understanding of knot strength.")
                        .font(.bodyLg)
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                // Terminology
                SectionHeader(title: "Knot-Tying Terminology")
                VStack(spacing: 8) {
                    ForEach(KnotGuideData.terminology, id: \.term) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text(item.term)
                                .font(.labelLg)
                                .foregroundStyle(Color.appPrimary)
                                .frame(width: 120, alignment: .leading)
                            Text(item.definition)
                                .font(.bodyMd)
                                .foregroundStyle(Color.onSurface)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }

                // Tips
                SectionHeader(title: "Knot-Tying Tips")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(KnotGuideData.tips.enumerated()), id: \.offset) { _, tip in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appPrimary)
                                    .font(.system(size: 14))
                                Text(tip.title)
                                    .font(.labelLg)
                                    .foregroundStyle(Color.onSurface)
                            }
                            Text(tip.detail)
                                .font(.bodyMd)
                                .foregroundStyle(Color.onSurfaceVariant)
                        }
                        .padding(14)
                        .background(Color.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
                    }
                }

                // Knot strength note
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Knot Strength")
                        .font(.headlineSm)
                        .foregroundStyle(Color.onSurface)
                    Text("Knots reduce line strength by 20–60%. Common knots range 40–80% of original line strength. Knot efficiency = breaking strength of knotted line ÷ breaking strength of unknotted line.\n\nA line rated at 4 lbs with a knot strength of 3 lbs = 75% knot efficiency.\n\nThe worst knot is the simple overhand ('granny knot') — never use it for fishing.")
                        .font(.bodyMd)
                        .foregroundStyle(Color.onSurface)
                }
                .padding(20)
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .padding(32)
        }
        .background(Color.appBackground)
    }
}

// MARK: - Rigging List View

struct RiggingListView: View {
    @State private var selectedId: String? = "dropper-rig"

    private var selected: RiggingSetup? {
        KnotGuideData.rigging.first { $0.id == selectedId }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Rigging list
            VStack(alignment: .leading, spacing: 0) {
                Text("RIGGING SETUPS")
                    .font(.labelMd)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .padding(16)
                Divider().background(Color.outlineVariant)
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(KnotGuideData.rigging) { rig in
                            Button { selectedId = rig.id } label: {
                                HStack {
                                    Text(rig.name)
                                        .font(.bodyMd)
                                        .foregroundStyle(selectedId == rig.id ? Color.appPrimary : Color.onSurface)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedId == rig.id ? Color.appPrimary.opacity(0.08) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: AppRadius.md)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
            }
            .frame(width: 220)
            .background(Color.surfaceContainerLow)

            Divider().background(Color.outlineVariant)

            // Rigging detail
            if let rig = selected {
                RiggingDetailView(setup: rig)
            }
        }
    }
}

struct RiggingDetailView: View {
    let setup: RiggingSetup

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    TagChip(label: "RIGGING", color: Color.appSecondary.opacity(0.1), textColor: .appSecondary)
                    Text(setup.name)
                        .font(.headlineLg)
                        .foregroundStyle(Color.onSurface)
                    Text(setup.description)
                        .font(.bodyLg)
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                HStack(alignment: .top, spacing: 24) {
                    // Diagram
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DIAGRAM").font(.labelMd).foregroundStyle(Color.onSurfaceVariant)
                        KnotDiagramView(diagram: setup.diagram)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(Color.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
                    }
                    .frame(maxWidth: .infinity)

                    // Specs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SPECIFICATIONS").font(.labelMd).foregroundStyle(Color.onSurfaceVariant)
                        ForEach(setup.specs, id: \.label) { spec in
                            HStack(alignment: .top) {
                                Text(spec.label)
                                    .font(.labelLg)
                                    .foregroundStyle(Color.appSecondary)
                                    .frame(width: 130, alignment: .leading)
                                Text(spec.value)
                                    .font(.bodyMd)
                                    .foregroundStyle(Color.onSurface)
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Components
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPONENTS").font(.labelMd).foregroundStyle(Color.onSurfaceVariant)
                    FlowLayout(spacing: 8) {
                        ForEach(setup.components, id: \.self) { comp in
                            HStack(spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Color.appPrimary)
                                Text(comp)
                                    .font(.bodyMd)
                                    .foregroundStyle(Color.onSurface)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.full).stroke(Color.outlineVariant, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(32)
        }
        .background(Color.appBackground)
    }
}

// MARK: - Quick Reference View

struct QuickReferenceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(KnotGuideData.quickReference, id: \.useCase) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.useCase)
                                .font(.labelLg)
                                .foregroundStyle(Color.appSecondary)
                            ForEach(item.knots, id: \.self) { knot in
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.appPrimary)
                                    Text(knot)
                                        .font(.bodyMd)
                                        .foregroundStyle(Color.onSurface)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Quick Reference")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}
