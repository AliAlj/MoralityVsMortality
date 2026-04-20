import SwiftUI

@main
struct MoralityVsMortalityApp: App {
    @StateObject private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif
    }
}
