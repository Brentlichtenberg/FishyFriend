import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var recommendations: [FishingRecommendation] = []
    @State private var selectedDate: Date = Date()
    @State private var showingClosed = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if recommendations.isEmpty {
                emptyState
            } else {
                recommendationList
            }
        }
        .navigationTitle("Today's Picks")
        .onAppear { reload() }
        .onChange(of: selectedDate) { reload() }
        .onChange(of: showingClosed) { reload() }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Best Rivers for")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(dateFormatter.string(from: selectedDate))
                    .font(.title2.bold())
            }
            Spacer()
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
            Toggle("Show Closed", isOn: $showingClosed)
                .toggleStyle(.button)
                .controlSize(.small)
        }
        .padding()
    }

    private var recommendationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(recommendations) { rec in
                    RecommendationCard(recommendation: rec)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Open Fisheries",
            systemImage: "fish",
            description: Text("No open fisheries found for the selected date. Try enabling 'Show Closed' or pick a different date.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logic

    private func reload() {
        recommendations = env.engine.recommendations(for: selectedDate, includeClosedFisheries: showingClosed)
    }
}
