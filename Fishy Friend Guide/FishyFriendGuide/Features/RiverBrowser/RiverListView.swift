import SwiftUI

struct RiverListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var searchText = ""
    @State private var selectedRegion: String? = nil
    @State private var selectedWaterway: Waterway? = nil

    private var waterways: [Waterway] {
        env.waterwayRepo.allWaterways()
            .filter { w in
                (searchText.isEmpty || w.name.localizedCaseInsensitiveContains(searchText))
                && (selectedRegion == nil || w.region == selectedRegion)
            }
            .sorted { $0.name < $1.name }
    }

    private var regions: [String] {
        env.waterwayRepo.allRegions
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                regionPicker
                Divider()
                List(waterways, selection: $selectedWaterway) { waterway in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(waterway.name)
                            .font(.body)
                        Text(waterway.region)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(waterway)
                }
                .searchable(text: $searchText, prompt: "Search rivers…")
            }
            .navigationTitle("River Browser")
        } detail: {
            if let waterway = selectedWaterway {
                RiverDetailView(waterway: waterway)
            } else {
                ContentUnavailableView("Select a River", systemImage: "map")
            }
        }
    }

    private var regionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") { selectedRegion = nil }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(selectedRegion == nil ? .accentColor : nil)

                ForEach(regions, id: \.self) { region in
                    Button(region) { selectedRegion = region }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(selectedRegion == region ? .accentColor : nil)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
