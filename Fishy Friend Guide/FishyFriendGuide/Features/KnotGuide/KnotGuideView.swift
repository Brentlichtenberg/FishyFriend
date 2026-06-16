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

                // Diagram + Steps side by side
                HStack(alignment: .top, spacing: 24) {
                    // Left: Diagram
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIAGRAM")
                            .font(.labelMd)
                            .foregroundStyle(Color.onSurfaceVariant)
                        KnotDiagramView(diagram: knot.diagram)
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .background(Color.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(Color.outlineVariant, lineWidth: 1)
                            )
                    }
                    .frame(maxWidth: .infinity)

                    // Right: Steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STEP-BY-STEP")
                            .font(.labelMd)
                            .foregroundStyle(Color.onSurfaceVariant)
                        stepsView
                    }
                    .frame(maxWidth: .infinity)
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

// MARK: - Knot Diagrams (SwiftUI Canvas)

struct KnotDiagramView: View {
    let diagram: KnotDiagramType

    var body: some View {
        ZStack {
            switch diagram {
            case .improvedClinch:  ImprovedClinchDiagram()
            case .doubleDavy:      DoubleDavyDiagram()
            case .uniKnot:         UniKnotDiagram()
            case .palomar:         PalomarDiagram()
            case .nonSlipLoop:     NonSlipLoopDiagram()
            case .perfectionLoop:  PerfectionLoopDiagram()
            case .surgeonsLoop:    SurgeonsLoopDiagram()
            case .doubleSurgeons:  DoubleSurgeonsDiagram()
            case .bloodKnot:       BloodKnotDiagram()
            case .loopToLoop:      LoopToLoopDiagram()
            case .nailKnot:        NailKnotDiagram()
            case .albright:        AlbrightDiagram()
            case .arbor:           ArborDiagram()
            case .snell:           SnellDiagram()
            case .dropperRig:      DropperRigDiagram()
            case .nymphRig:        NymphRigDiagram()
            case .skagitRig:       SkagitRigDiagram()
            case .conceptText(let text):
                ConceptTextDiagram(text: text)
            }
        }
    }
}

// MARK: - Individual Diagrams

private struct ImprovedClinchDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw: CGFloat = 2.5
            let lineColor = GraphicsContext.Shading.color(Color.appSecondary)
            let hookColor = GraphicsContext.Shading.color(Color.charcoalBark)

            // Hook
            var hook = Path()
            hook.move(to: CGPoint(x: w*0.18, y: h*0.28))
            hook.addLine(to: CGPoint(x: w*0.18, y: h*0.68))
            hook.addArc(center: CGPoint(x: w*0.25, y: h*0.68), radius: w*0.07, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            hook.addLine(to: CGPoint(x: w*0.35, y: h*0.52))
            ctx.stroke(hook, with: hookColor, lineWidth: 3)

            // Hook eye circle
            var eye = Path()
            eye.addEllipse(in: CGRect(x: w*0.14, y: h*0.20, width: w*0.08, height: w*0.08))
            ctx.stroke(eye, with: hookColor, lineWidth: 2)

            // Standing line
            var standing = Path()
            standing.move(to: CGPoint(x: w*0.18, y: h*0.24))
            standing.addLine(to: CGPoint(x: w*0.9, y: h*0.40))
            ctx.stroke(standing, with: lineColor, lineWidth: lw)

            // 5 coil wraps around standing line
            for i in 0..<5 {
                let cx = w * (0.42 + Double(i) * 0.078)
                let cy = h * 0.40
                var coil = Path()
                coil.addEllipse(in: CGRect(x: cx - w*0.018, y: cy - h*0.10, width: w*0.036, height: h*0.20))
                ctx.stroke(coil, with: lineColor, lineWidth: 1.5)
            }

            // Tag end going back through
            var tag = Path()
            tag.move(to: CGPoint(x: w*0.75, y: h*0.38))
            tag.addQuadCurve(to: CGPoint(x: w*0.30, y: h*0.44),
                             control: CGPoint(x: w*0.52, y: h*0.60))
            tag.addQuadCurve(to: CGPoint(x: w*0.22, y: h*0.30),
                             control: CGPoint(x: w*0.18, y: h*0.42))
            ctx.stroke(tag, with: GraphicsContext.Shading.color(Color.conservationGold), lineWidth: 2)

            // Labels
            ctx.draw(Text("Standing Line").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.75, y: h*0.30))
            ctx.draw(Text("5 wraps").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.58, y: h*0.25))
            ctx.draw(Text("Tag end back through").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.52, y: h*0.72))
        }
    }
}

private struct BloodKnotDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw: CGFloat = 2.5
            let line1 = GraphicsContext.Shading.color(Color.appSecondary)
            let line2 = GraphicsContext.Shading.color(Color.conservationGold)

            // Left line (leader)
            var left = Path()
            left.move(to: CGPoint(x: w*0.05, y: h*0.45))
            left.addLine(to: CGPoint(x: w*0.38, y: h*0.45))
            ctx.stroke(left, with: line1, lineWidth: lw)

            // Right line (tippet)
            var right = Path()
            right.move(to: CGPoint(x: w*0.62, y: h*0.55))
            right.addLine(to: CGPoint(x: w*0.95, y: h*0.55))
            ctx.stroke(right, with: line2, lineWidth: lw)

            // Left wraps (5 coils, leader wrapping around tippet)
            for i in 0..<5 {
                let cx = w * (0.35 - Double(i) * 0.052)
                var coil = Path()
                coil.addEllipse(in: CGRect(x: cx - w*0.016, y: h*0.30, width: w*0.032, height: h*0.25))
                ctx.stroke(coil, with: line1, lineWidth: 1.5)
            }

            // Right wraps (5 coils, tippet wrapping around leader)
            for i in 0..<5 {
                let cx = w * (0.65 + Double(i) * 0.052)
                var coil = Path()
                coil.addEllipse(in: CGRect(x: cx - w*0.016, y: h*0.45, width: w*0.032, height: h*0.25))
                ctx.stroke(coil, with: line2, lineWidth: 1.5)
            }

            // Center crossing point
            var center = Path()
            center.addEllipse(in: CGRect(x: w*0.46, y: h*0.40, width: w*0.08, height: h*0.20))
            ctx.fill(center, with: GraphicsContext.Shading.color(Color.appPrimary.opacity(0.2)))
            ctx.stroke(center, with: GraphicsContext.Shading.color(Color.appPrimary), lineWidth: 1.5)

            // Labels
            ctx.draw(Text("Leader / Tippet 1").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.16, y: h*0.30))
            ctx.draw(Text("Tippet 2").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.82, y: h*0.70))
            ctx.draw(Text("5 wraps each side").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.50, y: h*0.82))
            ctx.draw(Text("← Pull apart to tighten →").font(.system(size: 10)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.50, y: h*0.92))
        }
    }
}

private struct LoopToLoopDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let flyLine = GraphicsContext.Shading.color(Color.conservationGold)
            let leader  = GraphicsContext.Shading.color(Color.appSecondary)

            // Fly line (thick, left)
            var fl = Path()
            fl.move(to: CGPoint(x: w*0.05, y: h*0.45))
            fl.addLine(to: CGPoint(x: w*0.35, y: h*0.45))
            fl.addCurve(to: CGPoint(x: w*0.35, y: h*0.65),
                        control1: CGPoint(x: w*0.50, y: h*0.45),
                        control2: CGPoint(x: w*0.50, y: h*0.65))
            fl.addLine(to: CGPoint(x: w*0.30, y: h*0.65))
            ctx.stroke(fl, with: flyLine, lineWidth: 4)

            // Leader (thinner, right)
            var ld = Path()
            ld.move(to: CGPoint(x: w*0.95, y: h*0.55))
            ld.addLine(to: CGPoint(x: w*0.65, y: h*0.55))
            ld.addCurve(to: CGPoint(x: w*0.65, y: h*0.35),
                        control1: CGPoint(x: w*0.50, y: h*0.55),
                        control2: CGPoint(x: w*0.50, y: h*0.35))
            ld.addLine(to: CGPoint(x: w*0.70, y: h*0.35))
            ctx.stroke(ld, with: leader, lineWidth: 2.5)

            // Interlocked zone
            var chain = Path()
            chain.addRoundedRect(in: CGRect(x: w*0.38, y: h*0.38, width: w*0.24, height: h*0.28), cornerSize: CGSize(width: 8, height: 8))
            ctx.stroke(chain, with: GraphicsContext.Shading.color(Color.appPrimary.opacity(0.4)), lineWidth: 1.5)

            ctx.draw(Text("Fly Line Loop").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.20, y: h*0.32))
            ctx.draw(Text("Leader Loop").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.80, y: h*0.70))
            ctx.draw(Text("✓ Chain link shape — not a girth hitch").font(.system(size: 10)).foregroundStyle(Color.appPrimary),
                     at: CGPoint(x: w*0.50, y: h*0.88))
        }
    }
}

private struct DoubleSurgeonsDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let line1 = GraphicsContext.Shading.color(Color.appSecondary)
            let line2 = GraphicsContext.Shading.color(Color.conservationGold)

            // Two overlapping lines
            var l1 = Path()
            l1.move(to: CGPoint(x: w*0.05, y: h*0.42))
            l1.addLine(to: CGPoint(x: w*0.65, y: h*0.42))
            ctx.stroke(l1, with: line1, lineWidth: 2.5)

            var l2 = Path()
            l2.move(to: CGPoint(x: w*0.35, y: h*0.58))
            l2.addLine(to: CGPoint(x: w*0.95, y: h*0.58))
            ctx.stroke(l2, with: line2, lineWidth: 2.5)

            // Double loop overhand representation
            var loop = Path()
            loop.move(to: CGPoint(x: w*0.50, y: h*0.38))
            loop.addCurve(to: CGPoint(x: w*0.50, y: h*0.62),
                          control1: CGPoint(x: w*0.75, y: h*0.25),
                          control2: CGPoint(x: w*0.75, y: h*0.75))
            ctx.stroke(loop, with: GraphicsContext.Shading.color(Color.appPrimary.opacity(0.5)), lineWidth: 1.5)

            var loop2 = Path()
            loop2.move(to: CGPoint(x: w*0.50, y: h*0.38))
            loop2.addCurve(to: CGPoint(x: w*0.50, y: h*0.62),
                           control1: CGPoint(x: w*0.25, y: h*0.25),
                           control2: CGPoint(x: w*0.25, y: h*0.75))
            ctx.stroke(loop2, with: GraphicsContext.Shading.color(Color.appPrimary.opacity(0.5)), lineWidth: 1.5)

            ctx.draw(Text("Leader").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.22, y: h*0.32))
            ctx.draw(Text("Tippet").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.80, y: h*0.70))
            ctx.draw(Text("Pull ALL 4 ends to tighten").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.50, y: h*0.88))
        }
    }
}

private struct NonSlipLoopDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)
            let hookC = GraphicsContext.Shading.color(Color.charcoalBark)

            // Hook
            var hook = Path()
            hook.move(to: CGPoint(x: w*0.75, y: h*0.30))
            hook.addLine(to: CGPoint(x: w*0.75, y: h*0.65))
            hook.addArc(center: CGPoint(x: w*0.82, y: h*0.65), radius: w*0.07,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            hook.addLine(to: CGPoint(x: w*0.88, y: h*0.52))
            ctx.stroke(hook, with: hookC, lineWidth: 3)

            var eye = Path()
            eye.addEllipse(in: CGRect(x: w*0.71, y: h*0.22, width: w*0.08, height: h*0.10))
            ctx.stroke(eye, with: hookC, lineWidth: 2)

            // Non-slip loop (the loop stays open)
            var loop = Path()
            loop.move(to: CGPoint(x: w*0.10, y: h*0.50))
            loop.addLine(to: CGPoint(x: w*0.35, y: h*0.50))
            loop.addCurve(to: CGPoint(x: w*0.60, y: h*0.50),
                          control1: CGPoint(x: w*0.40, y: h*0.18),
                          control2: CGPoint(x: w*0.55, y: h*0.18))
            loop.addLine(to: CGPoint(x: w*0.74, y: h*0.27))
            ctx.stroke(loop, with: lc, lineWidth: 2.5)

            // Overhand knot indicator
            var knot = Path()
            knot.addEllipse(in: CGRect(x: w*0.28, y: h*0.42, width: w*0.12, height: h*0.16))
            ctx.fill(knot, with: GraphicsContext.Shading.color(Color.appPrimary.opacity(0.15)))
            ctx.stroke(knot, with: GraphicsContext.Shading.color(Color.appPrimary), lineWidth: 1.5)

            ctx.draw(Text("Overhand knot").font(.system(size: 10)).foregroundStyle(Color.appPrimary),
                     at: CGPoint(x: w*0.22, y: h*0.32))
            ctx.draw(Text("Fixed open loop").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.45, y: h*0.20))
            ctx.draw(Text("Loop stays open — fly swims freely").font(.system(size: 10)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.45, y: h*0.88))
        }
    }
}

private struct PerfectionLoopDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)

            // Standing line
            var standing = Path()
            standing.move(to: CGPoint(x: w*0.8, y: h*0.50))
            standing.addLine(to: CGPoint(x: w*0.95, y: h*0.50))
            ctx.stroke(standing, with: lc, lineWidth: 2.5)

            // Loop A (outer)
            var loopA = Path()
            loopA.move(to: CGPoint(x: w*0.80, y: h*0.50))
            loopA.addCurve(to: CGPoint(x: w*0.80, y: h*0.50),
                           control1: CGPoint(x: w*0.45, y: h*0.10),
                           control2: CGPoint(x: w*0.45, y: h*0.90))
            ctx.stroke(loopA, with: lc, lineWidth: 2.5)

            // Loop B (inner)
            var loopB = Path()
            loopB.move(to: CGPoint(x: w*0.73, y: h*0.50))
            loopB.addCurve(to: CGPoint(x: w*0.73, y: h*0.50),
                           control1: CGPoint(x: w*0.52, y: h*0.22),
                           control2: CGPoint(x: w*0.52, y: h*0.78))
            ctx.stroke(loopB, with: GraphicsContext.Shading.color(Color.conservationGold), lineWidth: 2)

            // Result loop at left
            var result = Path()
            result.move(to: CGPoint(x: w*0.20, y: h*0.50))
            result.addCurve(to: CGPoint(x: w*0.20, y: h*0.50),
                            control1: CGPoint(x: w*0.03, y: h*0.30),
                            control2: CGPoint(x: w*0.03, y: h*0.70))
            ctx.stroke(result, with: lc, lineWidth: 3)

            ctx.draw(Text("Loop A").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.38, y: h*0.15))
            ctx.draw(Text("Loop B").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.52, y: h*0.88))
            ctx.draw(Text("Finished loop").font(.system(size: 10)).foregroundStyle(Color.appPrimary),
                     at: CGPoint(x: w*0.20, y: h*0.78))
            ctx.draw(Text("B drops through A → pull tight").font(.system(size: 10)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.55, y: h*0.94))
        }
    }
}

private struct SurgeonsLoopDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)

            // Doubled line
            var d1 = Path()
            d1.move(to: CGPoint(x: w*0.50, y: h*0.35))
            d1.addLine(to: CGPoint(x: w*0.90, y: h*0.40))
            ctx.stroke(d1, with: lc, lineWidth: 2.5)

            var d2 = Path()
            d2.move(to: CGPoint(x: w*0.50, y: h*0.45))
            d2.addLine(to: CGPoint(x: w*0.90, y: h*0.50))
            ctx.stroke(d2, with: GraphicsContext.Shading.color(Color.appSecondary.opacity(0.5)), lineWidth: 2)

            // Two overhand loops
            var loop1 = Path()
            loop1.move(to: CGPoint(x: w*0.50, y: h*0.40))
            loop1.addCurve(to: CGPoint(x: w*0.50, y: h*0.40),
                           control1: CGPoint(x: w*0.15, y: h*0.10),
                           control2: CGPoint(x: w*0.15, y: h*0.70))
            ctx.stroke(loop1, with: lc, lineWidth: 2)

            // Resulting loop
            var result = Path()
            result.addEllipse(in: CGRect(x: w*0.06, y: h*0.35, width: w*0.18, height: h*0.30))
            ctx.stroke(result, with: GraphicsContext.Shading.color(Color.appPrimary), lineWidth: 3)

            ctx.draw(Text("Doubled line").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.72, y: h*0.30))
            ctx.draw(Text("Result loop").font(.system(size: 10)).foregroundStyle(Color.appPrimary),
                     at: CGPoint(x: w*0.14, y: h*0.22))
            ctx.draw(Text("Pass doubled end through loop TWICE").font(.system(size: 10)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.52, y: h*0.82))
            ctx.draw(Text("Pull loop + standing line to tighten").font(.system(size: 10)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.52, y: h*0.92))
        }
    }
}

private struct DoubleDavyDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)
            let hc = GraphicsContext.Shading.color(Color.charcoalBark)

            // Hook
            var hook = Path()
            hook.move(to: CGPoint(x: w*0.62, y: h*0.25))
            hook.addLine(to: CGPoint(x: w*0.62, y: h*0.65))
            hook.addArc(center: CGPoint(x: w*0.70, y: h*0.65), radius: w*0.08,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            hook.addLine(to: CGPoint(x: w*0.80, y: h*0.50))
            ctx.stroke(hook, with: hc, lineWidth: 3)

            // Eye
            var eye = Path()
            eye.addEllipse(in: CGRect(x: w*0.57, y: h*0.17, width: w*0.09, height: h*0.10))
            ctx.stroke(eye, with: hc, lineWidth: 2)

            // Compact knot body
            var knotBody = Path()
            knotBody.addRoundedRect(in: CGRect(x: w*0.35, y: h*0.28, width: w*0.22, height: h*0.25),
                                     cornerSize: CGSize(width: 10, height: 10))
            ctx.fill(knotBody, with: GraphicsContext.Shading.color(Color.appSecondary.opacity(0.10)))
            ctx.stroke(knotBody, with: lc, lineWidth: 2)

            // Tippet
            var tippet = Path()
            tippet.move(to: CGPoint(x: w*0.08, y: h*0.40))
            tippet.addLine(to: CGPoint(x: w*0.35, y: h*0.40))
            ctx.stroke(tippet, with: lc, lineWidth: 2.5)

            ctx.draw(Text("Compact knot at eye").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.45, y: h*0.20))
            ctx.draw(Text("90–100% strength").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.statusOpen),
                     at: CGPoint(x: w*0.50, y: h*0.82))
            ctx.draw(Text("Ideal for small flies").font(.system(size: 10)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.50, y: h*0.92))
        }
    }
}

private struct UniKnotDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)
            let hc = GraphicsContext.Shading.color(Color.charcoalBark)

            // Hook
            var hook = Path()
            hook.move(to: CGPoint(x: w*0.72, y: h*0.25))
            hook.addLine(to: CGPoint(x: w*0.72, y: h*0.62))
            hook.addArc(center: CGPoint(x: w*0.80, y: h*0.62), radius: w*0.08,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            ctx.stroke(hook, with: hc, lineWidth: 3)

            var eye = Path()
            eye.addEllipse(in: CGRect(x: w*0.67, y: h*0.16, width: w*0.09, height: h*0.10))
            ctx.stroke(eye, with: hc, lineWidth: 2)

            // Doubled-back loop
            var doubled = Path()
            doubled.move(to: CGPoint(x: w*0.08, y: h*0.40))
            doubled.addLine(to: CGPoint(x: w*0.68, y: h*0.40))
            doubled.addQuadCurve(to: CGPoint(x: w*0.42, y: h*0.55),
                                  control: CGPoint(x: w*0.65, y: h*0.65))
            ctx.stroke(doubled, with: lc, lineWidth: 2.5)

            // Tag end loop
            var tagLoop = Path()
            tagLoop.move(to: CGPoint(x: w*0.42, y: h*0.40))
            tagLoop.addCurve(to: CGPoint(x: w*0.42, y: h*0.55),
                              control1: CGPoint(x: w*0.22, y: h*0.35),
                              control2: CGPoint(x: w*0.22, y: h*0.60))
            ctx.stroke(tagLoop, with: GraphicsContext.Shading.color(Color.conservationGold), lineWidth: 1.5)

            // 5 coil wraps
            for i in 0..<5 {
                let cx = w * (0.48 + Double(i) * 0.038)
                var coil = Path()
                coil.addEllipse(in: CGRect(x: cx, y: h*0.36, width: w*0.022, height: h*0.22))
                ctx.stroke(coil, with: lc, lineWidth: 1.5)
            }

            ctx.draw(Text("4–6 wraps inside loop").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.60, y: h*0.25))
            ctx.draw(Text("Slide to eye or leave loop open").font(.system(size: 10)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.50, y: h*0.85))
        }
    }
}

private struct PalomarDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)
            let hc = GraphicsContext.Shading.color(Color.charcoalBark)

            // Hook
            var hook = Path()
            hook.move(to: CGPoint(x: w*0.50, y: h*0.50))
            hook.addLine(to: CGPoint(x: w*0.50, y: h*0.78))
            hook.addArc(center: CGPoint(x: w*0.60, y: h*0.78), radius: w*0.10,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            hook.addLine(to: CGPoint(x: w*0.72, y: h*0.62))
            ctx.stroke(hook, with: hc, lineWidth: 4)

            // Eye
            var eye = Path()
            eye.addEllipse(in: CGRect(x: w*0.45, y: h*0.40, width: w*0.10, height: h*0.12))
            ctx.stroke(eye, with: hc, lineWidth: 2.5)

            // Doubled line through eye
            var d1 = Path()
            d1.move(to: CGPoint(x: w*0.10, y: h*0.35))
            d1.addLine(to: CGPoint(x: w*0.50, y: h*0.44))
            ctx.stroke(d1, with: lc, lineWidth: 2.5)

            var d2 = Path()
            d2.move(to: CGPoint(x: w*0.10, y: h*0.45))
            d2.addLine(to: CGPoint(x: w*0.50, y: h*0.50))
            ctx.stroke(d2, with: GraphicsContext.Shading.color(Color.appSecondary.opacity(0.5)), lineWidth: 2)

            // Overhand knot
            var knot = Path()
            knot.move(to: CGPoint(x: w*0.22, y: h*0.40))
            knot.addCurve(to: CGPoint(x: w*0.22, y: h*0.40),
                          control1: CGPoint(x: w*0.05, y: h*0.20),
                          control2: CGPoint(x: w*0.05, y: h*0.60))
            ctx.stroke(knot, with: lc, lineWidth: 2)

            ctx.draw(Text("1. Double line through eye").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.28, y: h*0.22))
            ctx.draw(Text("2. Overhand knot").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.18, y: h*0.72))
            ctx.draw(Text("3. Pass loop OVER entire hook").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.50, y: h*0.88))
        }
    }
}

private struct NailKnotDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let tippet = GraphicsContext.Shading.color(Color.appSecondary)
            let flyLine = GraphicsContext.Shading.color(Color.conservationGold)

            // Fly line (thick)
            var fl = Path()
            fl.move(to: CGPoint(x: w*0.55, y: h*0.50))
            fl.addLine(to: CGPoint(x: w*0.95, y: h*0.50))
            ctx.stroke(fl, with: flyLine, lineWidth: 6)

            // Nail/tool
            var tool = Path()
            tool.move(to: CGPoint(x: w*0.25, y: h*0.42))
            tool.addLine(to: CGPoint(x: w*0.70, y: h*0.42))
            ctx.stroke(tool, with: GraphicsContext.Shading.color(Color.appPrimary.opacity(0.4)), lineWidth: 2)

            // Leader alongside fly line
            var leader = Path()
            leader.move(to: CGPoint(x: w*0.05, y: h*0.44))
            leader.addLine(to: CGPoint(x: w*0.60, y: h*0.44))
            ctx.stroke(leader, with: tippet, lineWidth: 2)

            // 5 tight wraps around fly line
            for i in 0..<5 {
                let cx = w * (0.57 + Double(i) * 0.058)
                var wrap = Path()
                wrap.addEllipse(in: CGRect(x: cx - w*0.018, y: h*0.32, width: w*0.036, height: h*0.24))
                ctx.stroke(wrap, with: tippet, lineWidth: 1.5)
            }

            // Tag end
            var tag = Path()
            tag.move(to: CGPoint(x: w*0.56, y: h*0.44))
            tag.addQuadCurve(to: CGPoint(x: w*0.60, y: h*0.62),
                              control: CGPoint(x: w*0.40, y: h*0.62))
            ctx.stroke(tag, with: GraphicsContext.Shading.color(Color.conservationGold.opacity(0.5)), lineWidth: 1.5)

            ctx.draw(Text("Leader").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.20, y: h*0.30))
            ctx.draw(Text("Fly Line").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.80, y: h*0.36))
            ctx.draw(Text("4–5 tight wraps · tug to slide off tool").font(.system(size: 10)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.50, y: h*0.88))
        }
    }
}

private struct AlbrightDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let light = GraphicsContext.Shading.color(Color.appSecondary)
            let heavy = GraphicsContext.Shading.color(Color.conservationGold)

            // Heavy line loop
            var loop = Path()
            loop.move(to: CGPoint(x: w*0.25, y: h*0.38))
            loop.addCurve(to: CGPoint(x: w*0.25, y: h*0.62),
                          control1: CGPoint(x: w*0.05, y: h*0.30),
                          control2: CGPoint(x: w*0.05, y: h*0.70))
            loop.addLine(to: CGPoint(x: w*0.55, y: h*0.62))
            loop.addLine(to: CGPoint(x: w*0.55, y: h*0.38))
            loop.closeSubpath()
            ctx.stroke(loop, with: heavy, lineWidth: 4)

            // Light line going through and wrapping (10 wraps)
            var light1 = Path()
            light1.move(to: CGPoint(x: w*0.90, y: h*0.42))
            light1.addLine(to: CGPoint(x: w*0.55, y: h*0.42))
            ctx.stroke(light1, with: light, lineWidth: 2.5)

            for i in 0..<10 {
                let cx = w * (0.57 + Double(i) * 0.025)
                var wrap = Path()
                wrap.addEllipse(in: CGRect(x: cx - w*0.010, y: h*0.35, width: w*0.020, height: h*0.30))
                ctx.stroke(wrap, with: light, lineWidth: 1.5)
            }

            ctx.draw(Text("Heavy line loop").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.23, y: h*0.22))
            ctx.draw(Text("10 wraps · exit same side").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.70, y: h*0.28))
            ctx.draw(Text("Joins lines of very different diameters").font(.system(size: 10)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.50, y: h*0.88))
        }
    }
}

private struct ArborDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)
            let reelC = GraphicsContext.Shading.color(Color.charcoalBark)

            // Reel spool (simplified as circle)
            var spool = Path()
            spool.addEllipse(in: CGRect(x: w*0.30, y: h*0.25, width: w*0.40, height: h*0.50))
            ctx.stroke(spool, with: reelC, lineWidth: 3)

            // Arbor (center post)
            var arbor = Path()
            arbor.addEllipse(in: CGRect(x: w*0.43, y: h*0.38, width: w*0.14, height: h*0.24))
            ctx.stroke(arbor, with: reelC, lineWidth: 2)

            // Line wrapping around arbor
            var line = Path()
            line.move(to: CGPoint(x: w*0.08, y: h*0.50))
            line.addLine(to: CGPoint(x: w*0.44, y: h*0.50))
            ctx.stroke(line, with: lc, lineWidth: 2.5)

            // First overhand knot
            var k1 = Path()
            k1.addEllipse(in: CGRect(x: w*0.12, y: h*0.42, width: w*0.10, height: h*0.16))
            ctx.stroke(k1, with: GraphicsContext.Shading.color(Color.appPrimary), lineWidth: 2)

            // Second jam knot
            var k2 = Path()
            k2.addEllipse(in: CGRect(x: w*0.04, y: h*0.44, width: w*0.07, height: h*0.12))
            ctx.stroke(k2, with: GraphicsContext.Shading.color(Color.conservationGold), lineWidth: 2)

            ctx.draw(Text("Reel arbor").font(.system(size: 10)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.50, y: h*0.25))
            ctx.draw(Text("Knot 1").font(.system(size: 9)).foregroundStyle(Color.appPrimary),
                     at: CGPoint(x: w*0.17, y: h*0.30))
            ctx.draw(Text("Knot 2 jams against knot 1").font(.system(size: 9)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.08, y: h*0.72))
        }
    }
}

private struct SnellDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lc = GraphicsContext.Shading.color(Color.appSecondary)
            let hc = GraphicsContext.Shading.color(Color.charcoalBark)

            // Hook (larger, for tube fly stinger context)
            var hook = Path()
            hook.move(to: CGPoint(x: w*0.60, y: h*0.20))
            hook.addLine(to: CGPoint(x: w*0.60, y: h*0.70))
            hook.addArc(center: CGPoint(x: w*0.70, y: h*0.70), radius: w*0.10,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            hook.addLine(to: CGPoint(x: w*0.82, y: h*0.55))
            ctx.stroke(hook, with: hc, lineWidth: 4)

            // Eye (at top)
            var eye = Path()
            eye.addEllipse(in: CGRect(x: w*0.54, y: h*0.10, width: w*0.12, height: h*0.12))
            ctx.stroke(eye, with: hc, lineWidth: 2.5)

            // 6 wraps along shank
            for i in 0..<6 {
                let cy = h * (0.25 + Double(i) * 0.07)
                var wrap = Path()
                wrap.addEllipse(in: CGRect(x: w*0.42, y: cy - h*0.04, width: w*0.14, height: h*0.08))
                ctx.stroke(wrap, with: lc, lineWidth: 1.5)
            }

            // Standing line
            var standing = Path()
            standing.move(to: CGPoint(x: w*0.08, y: h*0.42))
            standing.addLine(to: CGPoint(x: w*0.54, y: h*0.16))
            ctx.stroke(standing, with: lc, lineWidth: 2.5)

            ctx.draw(Text("6–7 wraps along shank").font(.system(size: 10)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.25, y: h*0.48))
            ctx.draw(Text("Pulls straight in line with shank").font(.system(size: 10)).foregroundStyle(Color.onSurface),
                     at: CGPoint(x: w*0.42, y: h*0.88))
            ctx.draw(Text("Use hemostat to set").font(.system(size: 10)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.42, y: h*0.95))
        }
    }
}

private struct DropperRigDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let leader = GraphicsContext.Shading.color(Color.appSecondary)
            let dropper = GraphicsContext.Shading.color(Color.conservationGold)
            let flyC = GraphicsContext.Shading.color(Color.charcoalBark)

            // Leader from left
            var l = Path()
            l.move(to: CGPoint(x: w*0.05, y: h*0.28))
            l.addLine(to: CGPoint(x: w*0.50, y: h*0.28))
            ctx.stroke(l, with: leader, lineWidth: 2.5)

            // Top fly (dry fly circle + hook)
            var fly1 = Path()
            fly1.addEllipse(in: CGRect(x: w*0.45, y: h*0.20, width: w*0.10, height: h*0.16))
            ctx.stroke(fly1, with: flyC, lineWidth: 2)
            ctx.draw(Text("Top fly").font(.system(size: 9)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.50, y: h*0.13))

            // Tippet continuing right
            var tippet = Path()
            tippet.move(to: CGPoint(x: w*0.55, y: h*0.28))
            tippet.addLine(to: CGPoint(x: w*0.95, y: h*0.28))
            ctx.stroke(tippet, with: leader, lineWidth: 2)

            // Dropper section (down from top fly hook bend)
            var drop = Path()
            drop.move(to: CGPoint(x: w*0.50, y: h*0.36))
            drop.addLine(to: CGPoint(x: w*0.50, y: h*0.72))
            ctx.stroke(drop, with: dropper, lineWidth: 1.5)

            // Bottom fly (nymph)
            var fly2 = Path()
            fly2.addRoundedRect(in: CGRect(x: w*0.43, y: h*0.72, width: w*0.14, height: h*0.14),
                                 cornerSize: CGSize(width: 4, height: 4))
            ctx.fill(fly2, with: GraphicsContext.Shading.color(Color.charcoalBark.opacity(0.15)))
            ctx.stroke(fly2, with: flyC, lineWidth: 2)
            ctx.draw(Text("Dropper fly").font(.system(size: 9)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.50, y: h*0.92))

            // Indicator
            var indicator = Path()
            indicator.addEllipse(in: CGRect(x: w*0.70, y: h*0.18, width: w*0.08, height: h*0.10))
            ctx.fill(indicator, with: GraphicsContext.Shading.color(Color.statusClosed.opacity(0.7)))
            ctx.draw(Text("indicator").font(.system(size: 8)).foregroundStyle(Color.statusClosed),
                     at: CGPoint(x: w*0.74, y: h*0.13))

            // Dimension annotation
            ctx.draw(Text("Dropper = depth × 1.5").font(.system(size: 10)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.20, y: h*0.55))
        }
    }
}

private struct NymphRigDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let rodColor  = GraphicsContext.Shading.color(Color.charcoalBark)
            let lineColor = GraphicsContext.Shading.color(Color.appSecondary)
            let tipColor  = GraphicsContext.Shading.color(Color.conservationGold)

            // Rod tip
            var rod = Path()
            rod.move(to: CGPoint(x: w*0.05, y: h*0.10))
            rod.addLine(to: CGPoint(x: w*0.20, y: h*0.28))
            ctx.stroke(rod, with: rodColor, lineWidth: 4)

            // Sighter section
            var sighter = Path()
            sighter.move(to: CGPoint(x: w*0.20, y: h*0.28))
            sighter.addLine(to: CGPoint(x: w*0.38, y: h*0.40))
            ctx.stroke(sighter, with: GraphicsContext.Shading.color(Color.statusClosed.opacity(0.8)), lineWidth: 2)

            // Tippet going down into water
            var tippet = Path()
            tippet.move(to: CGPoint(x: w*0.38, y: h*0.40))
            tippet.addLine(to: CGPoint(x: w*0.52, y: h*0.70))
            ctx.stroke(tippet, with: lineColor, lineWidth: 1.5)

            // Water surface
            var water = Path()
            water.move(to: CGPoint(x: w*0.30, y: h*0.58))
            for i in 0..<6 {
                let x = w * (0.30 + Double(i) * 0.12)
                water.addCurve(to: CGPoint(x: x + w*0.12, y: h*0.58),
                               control1: CGPoint(x: x + w*0.04, y: h*0.54),
                               control2: CGPoint(x: x + w*0.08, y: h*0.62))
            }
            ctx.stroke(water, with: GraphicsContext.Shading.color(Color.appSecondary.opacity(0.3)), lineWidth: 1.5)

            // Flies underwater
            var fly1 = Path()
            fly1.addEllipse(in: CGRect(x: w*0.48, y: h*0.68, width: w*0.08, height: h*0.10))
            ctx.fill(fly1, with: GraphicsContext.Shading.color(Color.charcoalBark.opacity(0.3)))
            ctx.stroke(fly1, with: rodColor, lineWidth: 1.5)

            var dropper = Path()
            dropper.move(to: CGPoint(x: w*0.52, y: h*0.78))
            dropper.addLine(to: CGPoint(x: w*0.55, y: h*0.88))
            ctx.stroke(dropper, with: lineColor, lineWidth: 1)

            var fly2 = Path()
            fly2.addEllipse(in: CGRect(x: w*0.51, y: h*0.87, width: w*0.08, height: h*0.10))
            ctx.fill(fly2, with: GraphicsContext.Shading.color(Color.charcoalBark.opacity(0.5)))
            ctx.stroke(fly2, with: rodColor, lineWidth: 1.5)

            // Labels
            ctx.draw(Text("Rod tip elevated").font(.system(size: 9)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.12, y: h*0.08))
            ctx.draw(Text("Sighter").font(.system(size: 9)).foregroundStyle(Color.statusClosed),
                     at: CGPoint(x: w*0.25, y: h*0.35))
            ctx.draw(Text("Anchor fly").font(.system(size: 9)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.68, y: h*0.72))
            ctx.draw(Text("Dropper").font(.system(size: 9)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.68, y: h*0.90))
        }
    }
}

private struct SkagitRigDiagram: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let running = GraphicsContext.Shading.color(Color.onSurfaceVariant)
            let head    = GraphicsContext.Shading.color(Color.conservationGold)
            let tip     = GraphicsContext.Shading.color(Color.appSecondary)
            let flyC    = GraphicsContext.Shading.color(Color.charcoalBark)

            // Running line
            var rl = Path()
            rl.move(to: CGPoint(x: w*0.04, y: h*0.42))
            rl.addLine(to: CGPoint(x: w*0.28, y: h*0.42))
            ctx.stroke(rl, with: running, lineWidth: 1.5)

            // Swivel dot
            var swivel = Path()
            swivel.addEllipse(in: CGRect(x: w*0.27, y: h*0.38, width: w*0.04, height: h*0.08))
            ctx.fill(swivel, with: GraphicsContext.Shading.color(Color.appPrimary))

            // Shooting head (thick, 20-26ft)
            var sh = Path()
            sh.move(to: CGPoint(x: w*0.31, y: h*0.42))
            sh.addLine(to: CGPoint(x: w*0.62, y: h*0.42))
            ctx.stroke(sh, with: head, lineWidth: 5)

            // Sink tip
            var st = Path()
            st.move(to: CGPoint(x: w*0.62, y: h*0.42))
            st.addLine(to: CGPoint(x: w*0.78, y: h*0.55))
            ctx.stroke(st, with: tip, lineWidth: 3)

            // Level mono tippet
            var lm = Path()
            lm.move(to: CGPoint(x: w*0.78, y: h*0.55))
            lm.addLine(to: CGPoint(x: w*0.88, y: h*0.65))
            ctx.stroke(lm, with: running, lineWidth: 1.5)

            // Fly (streamer/intruder)
            var fly = Path()
            fly.move(to: CGPoint(x: w*0.88, y: h*0.65))
            fly.addLine(to: CGPoint(x: w*0.96, y: h*0.72))
            fly.addCurve(to: CGPoint(x: w*0.94, y: h*0.62),
                         control1: CGPoint(x: w*0.98, y: h*0.68),
                         control2: CGPoint(x: w*0.97, y: h*0.64))
            ctx.stroke(fly, with: flyC, lineWidth: 2.5)

            // Labels
            ctx.draw(Text("Running line\n(mono)").font(.system(size: 8)).foregroundStyle(Color.onSurfaceVariant),
                     at: CGPoint(x: w*0.14, y: h*0.28))
            ctx.draw(Text("Shooting head\n(20–26 ft)").font(.system(size: 8)).foregroundStyle(Color.conservationGold),
                     at: CGPoint(x: w*0.46, y: h*0.25))
            ctx.draw(Text("Sink tip").font(.system(size: 8)).foregroundStyle(Color.appSecondary),
                     at: CGPoint(x: w*0.65, y: h*0.42))
            ctx.draw(Text("Tippet + fly").font(.system(size: 8)).foregroundStyle(Color.charcoalBark),
                     at: CGPoint(x: w*0.82, y: h*0.80))
            ctx.draw(Text("Developed on the Skagit River, WA").font(.system(size: 9)).foregroundStyle(Color.appPrimary),
                     at: CGPoint(x: w*0.50, y: h*0.92))
        }
    }
}

private struct ConceptTextDiagram: View {
    let text: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 32))
                .foregroundStyle(Color.appOutline)
            Text(text)
                .font(.bodyMd)
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Text("See animatedknots.com for video illustration")
                .font(.labelMd)
                .foregroundStyle(Color.appSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
