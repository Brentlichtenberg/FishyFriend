import SwiftUI
import SwiftData

@main
struct FishyFriendGuideApp: App {
    @StateObject private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
        }
        .modelContainer(for: [Waterway.self, CatchRecord.self])
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
