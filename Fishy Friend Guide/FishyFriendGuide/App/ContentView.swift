import SwiftUI

struct ContentView: View {
    @State private var nav = NavigationState()
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(nav: nav)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            VStack(spacing: 0) {
                TopToolbarView(nav: nav)
                Divider()
                    .background(Color.outlineVariant)
                detailContent
            }
            .background(Color.appBackground)
        }
        .sheet(isPresented: $nav.showingNewCatch) {
            CatchEntryView()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch nav.selectedSection {
        case .map:               MapWaterwaysView()
        case .hatchGuide:        HatchGuideView()
        case .regulations:       RegulationListView()
        case .historicalCatches: HistoricalCatchesView()
        case .weather:           WeatherView()
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    let nav: NavigationState

    var body: some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                Image(systemName: "fish.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.appPrimary)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Fishy Friend")
                        .font(.headlineSm)
                        .foregroundStyle(.appPrimary)
                    Text("Guide")
                        .font(.headlineSm)
                        .foregroundStyle(.appPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            // Nav items
            VStack(spacing: 2) {
                ForEach(AppSection.allCases) { section in
                    SidebarNavItem(section: section, isSelected: nav.selectedSection == section) {
                        nav.selectedSection = section
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Field Edition promo
            FieldEditionCard()
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            Divider().background(Color.outlineVariant)

            // Settings + Support
            VStack(spacing: 2) {
                SidebarUtilityItem(icon: "gearshape", label: "Settings")
                SidebarUtilityItem(icon: "questionmark.circle", label: "Support")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color.surfaceContainerLow)
    }
}

struct SidebarNavItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.onSurfaceVariant)
                Text(section.rawValue)
                    .font(.labelLg)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.onSurfaceVariant)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .sidebarItemGlass(isSelected: isSelected)
    }
}

struct SidebarUtilityItem: View {
    let icon: String
    let label: String

    var body: some View {
        Button {  } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(.onSurfaceVariant)
                Text(label)
                    .font(.labelLg)
                    .foregroundStyle(.onSurfaceVariant)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct FieldEditionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FIELD EDITION")
                .font(.labelMd)
                .foregroundStyle(Color.appPrimary)
            Text("Get topographic maps and live hatch alerts.")
                .font(.system(size: 12))
                .foregroundStyle(Color.onSurfaceVariant)
            upgradeButton
        }
        .padding(12)
        .floatGlass(tint: Color.appPrimary.opacity(0.08))
    }

    @ViewBuilder
    private var upgradeButton: some View {
        if #available(macOS 26, *) {
            Button("Upgrade to Field Edition") { }
                .buttonStyle(.glassProminent)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
        } else {
            Button("Upgrade to Field Edition") { }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Top Toolbar

struct TopToolbarView: View {
    let nav: NavigationState

    var body: some View {
        HStack(spacing: 16) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.appOutline)
                Text("Search rivers, species, or regulations…")
                    .font(.bodyMd)
                    .foregroundStyle(.appOutline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .floatGlass(cornerRadius: AppRadius.full)
            .frame(maxWidth: 360)

            Spacer()

            // Dashboard tab
            Text("Dashboard")
                .font(.labelLg)
                .foregroundStyle(.appPrimary)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.appPrimary).frame(height: 2)
                }

            Text("Favorites")
                .font(.labelLg)
                .foregroundStyle(.onSurfaceVariant)

            Button { } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Button { } label: {
                Image(systemName: "bell")
                    .foregroundStyle(.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            // New Catch CTA
            newCatchButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    @ViewBuilder
    private var newCatchButton: some View {
        if #available(macOS 26, *) {
            Button {
                nav.showingNewCatch = true
            } label: {
                Label("New Catch", systemImage: "plus").font(.labelLg)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button {
                nav.showingNewCatch = true
            } label: {
                Label("New Catch", systemImage: "plus").font(.labelLg)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPrimary)
        }
    }
}
