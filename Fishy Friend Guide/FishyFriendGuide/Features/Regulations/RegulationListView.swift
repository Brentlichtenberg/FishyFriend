import SwiftUI

struct RegulationListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var selectedDate = Date()
    @State private var filterCategory: RegulationCategory = .inland
    @State private var searchText = ""

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

                // Critical alert banner
                CriticalAlertBanner()

                // Two-column: regulation table + license quick check
                HStack(alignment: .top, spacing: 24) {
                    // Main regulation table
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

                    // Right sidebar: license check + info cards
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

// MARK: - Critical Alert Banner

struct CriticalAlertBanner: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(Color.appPrimary.opacity(0.12))
                .frame(height: 160)
                .overlay(
                    ZStack {
                        Image(systemName: "water.waves.and.arrow.trianglehead.up.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.appPrimary.opacity(0.08))
                    }
                )

            VStack(alignment: .leading, spacing: 8) {
                TagChip(label: "CRITICAL SEASON", color: .conservationGold, textColor: .white)
                Text("Columbia River Salmon Run")
                    .font(.headlineMd)
                    .foregroundStyle(.onSurface)
                Text("New emergency rules in effect for the Lower Columbia. Please review the\nupdated retention limits for Chinook and Coho salmon before launching.")
                    .font(.bodyMd)
                    .foregroundStyle(.onSurfaceVariant)
                Button("View Specific Rules →") { }
                    .buttonStyle(.plain)
                    .font(.labelLg)
                    .foregroundStyle(.appSecondary)
                    .padding(.top, 4)
            }
            .padding(20)
        }
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

