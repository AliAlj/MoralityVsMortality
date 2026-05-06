import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showingActCard = true
    @State private var lastAct: GameAct = .interrogation

    var body: some View {
        ZStack {
            activeActView
                .opacity(showingActCard ? 0 : 1)

            if !showingActCard,
               shouldShowBottomContinue {
                BottomNavigationView()
                    .environmentObject(gameState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .zIndex(999)
            }

            if showingActCard {
                ActTitleCardView(act: gameState.currentAct) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        showingActCard = false
                    }
                }
            }
        }
        .onChange(of: gameState.currentAct) { _, newAct in
            if newAct != lastAct {
                lastAct = newAct
                showingActCard = true
            }
        }
        .onAppear {
            showingActCard = true
        }
    }

    private var activeActView: some View {
        Group {
            switch gameState.currentAct {
            case .interrogation:  Act1InterrogationView()
            case .investigation:  Act2InvestigationView()
            case .analysis:       Act3AnalysisView()
            case .confrontation:  Act4ConfrontationView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shouldShowBottomContinue: Bool {
        gameState.currentAct != .analysis
    }

}

// Act Title Card
struct ActTitleCardView: View {
    let act: GameAct
    let onFinished: () -> Void

    @State private var textOpacity: Double = 0
    @State private var displayedTitle = ""
    @State private var typingTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("ACT \(act.romanNumeral)")
                    .font(.custom("Times New Roman", size: 64))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(8)
                    .opacity(textOpacity)

                Text(displayedTitle)
                    .font(.custom("Times New Roman", size: 28))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(4)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                textOpacity = 1.0
            }

            typingTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                for character in act.title {
                    guard !Task.isCancelled else { return }
                    displayedTitle.append(character)
                    try? await Task.sleep(nanoseconds: 60_000_000)
                }
            }

            let totalTitle = act.title
            let typingDuration = 1.0 + Double(totalTitle.count) * 0.06 + 1.5

            DispatchQueue.main.asyncAfter(deadline: .now() + typingDuration) {
                withAnimation(.easeOut(duration: 1.0)) {
                    textOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onFinished()
                }
            }
        }
        .onDisappear {
            typingTask?.cancel()
        }
    }
}

struct BottomNavigationView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        HStack {
            Spacer()

            if !gameState.gameCompleted && gameState.canProgressToNextAct {
                Button("Continue →") {
                    gameState.progressToNextAct()
                }
                .actContinueButtonStyle()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    ContentView().environmentObject(GameState())
}
