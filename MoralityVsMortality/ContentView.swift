import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showingActCard = true
    @State private var lastAct: GameAct = .interrogation

    var body: some View {
        ZStack {
            Group {
                #if DEBUG
                activeActView
                #else
                standardBody
                #endif
            }
            .opacity(showingActCard ? 0 : 1)

            #if DEBUG
            if !showingActCard {
                DebugMenuView()
                    .padding(.top, 64)
                    .padding(.trailing, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .zIndex(1000)
            }
            #endif

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

    private var standardBody: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider()
            activeActView
            Divider()
            BottomNavigationView()
        }
    }

}

// MARK: - Act Title Card
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

// MARK: - Header
struct HeaderView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Act \(gameState.currentAct.rawValue): \(gameState.currentAct.title)")
                    .font(.title2).fontWeight(.semibold)
                Text(gameState.currentAct.subtitle)
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            Text("Evidence: \(gameState.realEvidenceCount)")
                .font(.caption).foregroundColor(.secondary)

        }
        .padding()
        .background(Color.primary.opacity(0.04))
    }
}

#if DEBUG
struct DebugMenuView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        Menu {
            ForEach(GameAct.allCases, id: \.rawValue) { act in
                Button("Jump to \(act.title)") { gameState.jumpToAct(act) }
            }
            Divider()
            Button("Reset") { gameState.resetGame() }
            Button("Reset Onboarding") {
                UserDefaults.standard.removeObject(forKey: "playerName")
                UserDefaults.standard.removeObject(forKey: "selectedDetective")
                UserDefaults.standard.removeObject(forKey: "hasSeenIntro")
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "ladybug.fill")
                Text("Debug")
            }
            .font(.headline.weight(.bold))
            .foregroundColor(.white)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.blue)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
        )
        .cornerRadius(12)
        .shadow(color: .blue.opacity(0.35), radius: 8, x: 0, y: 2)
    }
}
#endif

// MARK: - Bottom Nav
struct BottomNavigationView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        HStack {
            if gameState.currentAct.rawValue > 1 && !gameState.gameCompleted {
                Button {
                    if let prev = GameAct(rawValue: gameState.currentAct.rawValue - 1) {
                        gameState.jumpToAct(prev)
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }

            Spacer()

            if !gameState.gameCompleted {
                ZStack(alignment: .trailing) {
                    Text(progressHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(gameState.canProgressToNextAct ? 0 : 1)

                    Button("Continue →") { gameState.progressToNextAct() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .opacity(gameState.canProgressToNextAct ? 1 : 0)
                        .disabled(!gameState.canProgressToNextAct)
                }
            }
        }
        .padding()
    }

    private var progressHint: String {
        switch gameState.currentAct {
        case .interrogation:
            return "Unlock \(max(0, 2 - gameState.unlockedDialogue.count)) more dialogue branches"
        case .investigation:
            return "Find \(max(0, 6 - gameState.realEvidenceCount)) more evidence pieces"
        case .analysis:
            return "Complete \(max(0, 3 - gameState.analysisResults.count)) more analyses"
        case .confrontation:
            return ""
        }
    }
}

#Preview {
    ContentView().environmentObject(GameState())
}
