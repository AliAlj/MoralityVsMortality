import SwiftUI

@main
struct MoralityVsMortalityApp: App {
    @StateObject private var gameState = GameState()
    @State private var currentScreen: AppScreen = .start

    var body: some Scene {
        WindowGroup {
            switch currentScreen {
            case .start:
                StartScreenView(screen: $currentScreen)
            case .intro:
                IntroScreenView(screen: $currentScreen)
            case .game:
                ContentView()
                    .environmentObject(gameState)
            }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif
    }
}
