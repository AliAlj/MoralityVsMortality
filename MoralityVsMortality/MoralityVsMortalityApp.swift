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
                    .environmentObject(gameState)
            case .intro:
                IntroScreenView(screen: $currentScreen)
                    .environmentObject(gameState)
            case .characterSelect:
                CharacterSelectView(screen: $currentScreen)
                    .environmentObject(gameState)
            case .game:
                ContentView()
                    .environmentObject(gameState)
            }
        }
        .onChange(of: gameState.shouldReturnToStart) { _, shouldReturn in
            if shouldReturn {
                gameState.shouldReturnToStart = false
                currentScreen = .start
            }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif
    }
}
