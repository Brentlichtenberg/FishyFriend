import SwiftUI

struct RegulationListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selectedDate = Date()
    @State private var filterCategory: RegulationCategory = .inland
    @State private var searchText = ""
    @State private var emergencyRules: [EmergencyRule] = []
    @State private var emergencyLoadError: String? = nil
    @State private var isLoadingEmergency = false

    enum RegulationCategory: String, CaseIterable {
        case inland = "Inland"
        case marine = "Marine"
        case shellfish = "Shellfish"
    }

    private var openRegs: [Regulation] {
        env.regulationRepo.openRegulations(on: selectedDate)
            .filter { reg in
                searchText.isEmpty ||
                reg.species.localizedCaseInsensitiveContains(searchText) ||
                (env.waterwayRepo.waterway(id: reg.waterwayId)?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Official badge + header
                headerSection

                // Live WDFW emergency rules
                EmergencyRulesBannerSection(
                    rules: emergencyRules,
                    isLoading: isLoadingEmergency,
                    error: emergencyLoadError
                ) {
                    Task { await loadEmergencyRules(forceRefresh: true) }
                }

                // Two-column: regulation table + license quick check
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Regional Waterway Rules")
                                .font(.headlineSm)
                                .foregroundStyle(.onSurface)
                            Spacer()
                            categoryPicker
                        }
                        RegulationTable(regulations: openRegs, env: env)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        LicenseQuickCheck()
                        SelectiveGearCard()
                        ReportViolationsCard()
                    }
                    .frame(width: 280)
                }

                Divider().background(Color.outlineVariant)
                RegulationsFooter()
            }
            .padding(32)
        }
        .background(Color.appBackground)
        .task { await loadEmergencyRules() }
    }

    // MARK: - Emergency rules loading

    @MainActor
    private func loadEmergencyRules(forceRefresh: Bool = false) async {
        // Auto-refresh if today is Saturday or force requested
        let shouldRefresh = forceRefresh || EmergencyRulesService.isSaturday()
        isLoadingEmergency = true
        emergencyLoadError = nil
        do {
            emergencyRules = try await env.emergencyRulesService.fetchRules(forceRefresh: shouldRefresh)
        } catch {
            emergencyLoadError = "Could not load emergency rules. Tap refresh to retry."
        }
        isLoadingEmergency = false
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.appPrimary)
                    .font(.labelLg)
                Text("OFFICIAL STATE DATA")
                    .font(.labelLg)
                    .foregroundStyle(.appPrimary)
            }
            Text("Washington State Fishing Regulations")
                .font(.headlineLg)
                .foregroundStyle(.onSurface)
            Text("Comprehensive legal requirements for inland and marine waters. Last updated: July 2025.\nAll regulations are subject to emergency changes by the WDFW.")
                .font(.bodyMd)
                .foregroundStyle(.onSurfaceVariant)
        }
    }

    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(RegulationCategory.allCases, id: \.self) { cat in
                Button(cat.rawValue) {
                    filterCategory = cat
                }
                .buttonStyle(.plain)
                .font(.labelLg)
                .foregroundStyle(filterCategory == cat ? .white : .onSurfaceVariant)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(filterCategory == cat ? Color.appPrimary : Color.clear)
            }
        }
        .background(Color.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.outlineVariant, lineWidth: 1))
    }
}

// MARK: - Emergency Rules Banner Section

struct EmergencyRulesBannerSection: View {
    let rules: [EmergencyRule]
    let isLoading: Bool
    let error: String?
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.statusRestricted)
                    .font(.system(size: 16))
                Text("WDFW Emergency Rules")
                    .font(.headlineSm)
                    .foregroundStyle(Color.onSurface)
                Spacer()
                if isLoading {
                    ProgressView().controlSize(.small)
                    Text("Refreshing…")
                        .font(.labelMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                } else {
                    Button {
                        onRefresh()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text("Refresh")
                                .font(.labelMd)
                        }
                        .foregroundStyle(Color.appSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(Color.statusClosed)
                    Text(error)
                        .font(.bodyMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.statusClosed.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            } else if rules.isEmpty && !isLoading {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.statusOpen)
                    Text("No active emergency rules at this time.")
                        .font(.bodyMd)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.statusOpen.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(rules) { rule in
                        EmergencyRuleBanner(rule: rule)
                    }
                }
            }

            // Attribution note
            if !rules.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appOutline)
                    Text("Live from wdfw.wa.gov · Refreshes automatically every Saturday")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appOutline)
                }
            }
        }
    }
}

struct EmergencyRuleBanner: View {
    let rule: EmergencyRule
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(Color.statusRestricted.opacity(isHovered ? 0.14 : 0.10))
                .overlay(
                    ZStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.statusRestricted.opacity(0.06))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                    }
                )

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    TagChip(label: "EMERGENCY RULE", color: .statusRestricted, textColor: .white)
                    Text(rule.title)
                        .font(.headlineSm)
                        .foregroundStyle(Color.onSurface)
                    Button("View Full Rule on WDFW →") {
                        if let url = URL(string: rule.url) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.labelLg)
                    .foregroundStyle(Color.appSecondary)
                    .padding(.top, 2)
                }
            }
            .padding(18)
        }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Regulation Table

struct RegulationTable: View {
    let regulations: [Regulation]
    let env: AppEnvironment

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                colHeader("SPECIES / CATEGORY")
                colHeader("DAILY LIMIT", width: 100)
                colHeader("SIZE REQUIREMENTS", width: 160)
                colHeader("GEAR RESTRICTIONS", width: 200)
                colHeader("STATUS", width: 90)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.surfaceContainerHigh)

            if regulations.isEmpty {
                Text("No open regulations for the selected date and category.")
                    .font(.bodyMd)
                    .foregroundStyle(.onSurfaceVariant)
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color.appBackground)
            } else {
                ForEach(Array(regulations.enumerated()), id: \.element.id) { idx, reg in
                    RegulationTableRow(
                        reg: reg,
                        waterwayName: env.waterwayRepo.waterway(id: reg.waterwayId)?.name ?? reg.waterwayId,
                        isEven: idx % 2 == 0
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }

    private func colHeader(_ title: String, width: CGFloat? = nil) -> some View {
        Text(title)
            .font(.labelMd)
            .foregroundStyle(.onSurfaceVariant)
            .frame(minWidth: 0, maxWidth: width ?? .infinity, alignment: .leading)
    }
}

struct RegulationTableRow: View {
    let reg: Regulation
    let waterwayName: String
    let isEven: Bool

    private var status: RegulationStatus { reg.isOpen() ? .open : .closed }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reg.species)
                    .font(.bodyMd.bold())
                    .foregroundStyle(.onSurface)
                Text(waterwayName)
                    .font(.labelMd)
                    .foregroundStyle(.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(reg.bagLimit == 0 ? "Catch & Release" : "\(reg.bagLimit) per day")
                .font(.bodyMd)
                .foregroundStyle(.onSurface)
                .frame(width: 100, alignment: .leading)

            Text(reg.minimumSize.map { "Min \($0)\" total length" } ?? "No min. size")
                .font(.bodyMd)
                .foregroundStyle(.onSurface)
                .frame(width: 160, alignment: .leading)

            Text(reg.gearRestrictions.isEmpty ? "Standard gear" : reg.gearRestrictions.first ?? "")
                .font(.bodyMd)
                .foregroundStyle(.onSurface)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)

            StatusBadge(status: status, compact: true)
                .frame(width: 90, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isEven ? Color.appBackground : Color.surfaceContainerLow)
    }
}

// MARK: - License Quick Check

struct LicenseQuickCheck: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "wallet.bifold")
                    .foregroundStyle(.appSecondary)
                    .font(.system(size: 18))
                Text("License Quick Check")
                    .font(.headlineSm)
                    .foregroundStyle(.onSurface)
            }
            Text("Verify your current endorsements for Puget Sound Crab and Razor Clams.")
                .font(.bodyMd)
                .foregroundStyle(.onSurfaceVariant)

            VStack(spacing: 8) {
                LicenseRow(name: "Annual Freshwater", status: "Active", isActive: true)
                LicenseRow(name: "Discovery Pass", status: "Expired", isActive: false)
            }

            Button("Renew Endorsements →") { }
                .buttonStyle(.plain)
                .font(.labelLg)
                .foregroundStyle(.appSecondary)
        }
        .padding(16)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }
}

struct LicenseRow: View {
    let name: String
    let status: String
    let isActive: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.bodyMd)
                .foregroundStyle(.onSurface)
            Spacer()
            Text(status.uppercased())
                .font(.labelMd)
                .foregroundStyle(isActive ? .statusOpen : .statusClosed)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((isActive ? Color.statusOpen : Color.statusClosed).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .padding(10)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

struct SelectiveGearCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 24))
                .foregroundStyle(.appSecondary)
                .frame(width: 48, height: 48)
                .background(Color.appSecondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            VStack(alignment: .leading, spacing: 4) {
                Text("Selective Gear Rules")
                    .font(.labelLg)
                    .foregroundStyle(.onSurface)
                Text("Unsure what 'Selective Gear' means for your local stream?")
                    .font(.system(size: 12))
                    .foregroundStyle(.onSurfaceVariant)
                Button("Read Definitions →") { }
                    .buttonStyle(.plain)
                    .font(.labelMd)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }
}

struct ReportViolationsCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.statusRestricted)
                .frame(width: 48, height: 48)
                .background(Color.statusRestricted.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            VStack(alignment: .leading, spacing: 4) {
                Text("Reporting Violations")
                    .font(.labelLg)
                    .foregroundStyle(.onSurface)
                Text("Help protect our waters. Report illegal fishing activity anonymously.")
                    .font(.system(size: 12))
                    .foregroundStyle(.onSurfaceVariant)
                Button("Submit a Report →") { }
                    .buttonStyle(.plain)
                    .font(.labelMd)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.outlineVariant, lineWidth: 1))
    }
}

struct RegulationsFooter: View {
    var body: some View {
        HStack {
            Text("© 2025 Fishy Friend Guide | In partnership with WDFW")
                .font(.labelMd)
                .foregroundStyle(.onSurfaceVariant)
            Spacer()
            Button("Privacy Policy") { }.buttonStyle(.plain).font(.labelMd).foregroundStyle(.appSecondary)
            Button("Terms of Service") { }.buttonStyle(.plain).font(.labelMd).foregroundStyle(.appSecondary)
            Button("Contact Enforcement") { }.buttonStyle(.plain).font(.labelMd).foregroundStyle(.appSecondary)
        }
    }
}

