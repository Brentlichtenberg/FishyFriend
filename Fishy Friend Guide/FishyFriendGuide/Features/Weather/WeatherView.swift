import SwiftUI

struct WeatherView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cloud.sun.rain.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.appSecondary)
            Text("Weather Integration")
                .font(.headlineLg)
                .foregroundStyle(Color.onSurface)
            Text("Live weather data from NOAA and regional USGS gauges\ncoming in a future update.")
                .font(.bodyLg)
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
            TagChip(label: "FIELD EDITION FEATURE", color: .conservationGold.opacity(0.15), textColor: .conservationGold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
