import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            Group {
                switch gameState.currentAct {
                case .investigation:  Act1InvestigationView()
                case .interrogation:  Act2InterrogationView()
                case .analysis:       Act3AnalysisView()
                case .confrontation:  Act4ConfrontationView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            BottomNavigationView()
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

            Text("Evidence: \(gameState.realEvidenceCount)  ·  Score: \(gameState.caseScore)")
                .font(.caption).foregroundColor(.secondary)

            #if DEBUG
            Menu("Debug") {
                ForEach(GameAct.allCases, id: \.rawValue) { act in
                    Button("Jump to \(act.title)") { gameState.jumpToAct(act) }
                }
                Divider()
                Button("Reset") { gameState.resetGame() }
            }
            .menuStyle(.borderlessButton)
            #endif
        }
        .padding()
        .background(Color.primary.opacity(0.04))
    }
}

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

            if gameState.canProgressToNextAct {
                Button("Continue →") { gameState.progressToNextAct() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            } else if !gameState.gameCompleted {
                Text(progressHint)
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var progressHint: String {
        switch gameState.currentAct {
        case .investigation:
            return "Find \(max(0, 3 - gameState.realEvidenceCount)) more evidence pieces"
        case .interrogation:
            return "Unlock \(max(0, 2 - gameState.unlockedDialogue.count)) more dialogue branches"
        case .analysis:
            return "Complete analyses and make connections"
        case .confrontation:
            return ""
        }
    }
}

#Preview {
    ContentView().environmentObject(GameState())
}
