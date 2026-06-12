import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DashboardView()
        }
    }
}

struct SidebarView: View {
    var body: some View {
        List {
            NavigationLink(destination: DashboardView()) {
                Label("Today's Picks", systemImage: "fish.fill")
            }
            NavigationLink(destination: RiverListView()) {
                Label("River Browser", systemImage: "map")
            }
            NavigationLink(destination: CatchLogView()) {
                Label("My Catch Log", systemImage: "note.text")
            }
            NavigationLink(destination: RegulationListView()) {
                Label("Regulations", systemImage: "doc.text")
            }
        }
        .navigationTitle("Fishy Friend Guide")
        .listStyle(.sidebar)
    }
}
