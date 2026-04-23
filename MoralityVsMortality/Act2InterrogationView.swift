import SwiftUI
import Combine

// MARK: - Act 2: Wrapper View
struct Act2InterrogationView: View {
    var body: some View {
        Act3InterrogationView()
    }
}

// MARK: - Act 3: Interrogation View Model
@MainActor
class Act3ViewModel: ObservableObject {
    @Published var availableQuestions: [DialogueNode] = []
    @Published var conversationHistory: [ConversationEntry] = []
    @Published var selectedSuspect: Suspect?
    @Published var showingQuestionDetail: DialogueNode?
    
    var gameState: GameState
    
    // Whether the player is stuck (no unlocked questions left, but can't progress)
    var isStuck: Bool {
        let unlockableCount = availableQuestions.filter(\.isUnlocked).count
        return unlockableCount == 0 && !gameState.canProgressToNextAct
    }
    
    // Hints about what evidence is missing and where to find it
    var hints: [(message: String, targetAct: GameAct)] {
        var result: [(String, GameAct)] = []
        
        let lockedQuestions = availableQuestions.filter { !$0.isUnlocked }
        for question in lockedQuestions {
            for evidenceName in question.requiredEvidence {
                if !gameState.hasEvidence(named: evidenceName) {
                    switch evidenceName {
                    case "Hospital ID Badge", "Syringe":
                        result.append(("Search the hospital room for \"\(evidenceName)\"", .investigation))
                    default:
                        result.append(("Find \"\(evidenceName)\" in earlier acts", .investigation))
                    }
                }
            }
        }
        
        return result
    }
    
    init(gameState: GameState) {
        self.gameState = gameState
        setupDialogueNodes()
        selectedSuspect = gameState.suspects.first { $0.isUnlocked }
        startConversation()
    }
    
    private func setupDialogueNodes() {
        availableQuestions = [
            DialogueNode(
                questionText: "Where were you at 10:45 PM last night?",
                responses: [
                    DialogueResponse(
                        text: "I was in Surgery Room 3, performing an emergency procedure.",
                        suspectReaction: "Confident and direct",
                        revealsEvidence: nil,
                        changesRelationship: 1
                    )
                ],
                requiredEvidence: [],
                isUnlocked: true
            ),
            
            DialogueNode(
                questionText: "Do you recognize this hospital ID badge?",
                responses: [
                    DialogueResponse(
                        text: "That's mine! I must have dropped it. I was wondering where it went.",
                        suspectReaction: "Surprised but relieved",
                        revealsEvidence: "Dr. Kazmir's Alibi",
                        changesRelationship: 2
                    )
                ],
                requiredEvidence: ["Hospital ID Badge"],
                isUnlocked: false
            ),
            
            DialogueNode(
                questionText: "What can you tell me about the victim's organ transplant status?",
                responses: [
                    DialogueResponse(
                        text: "He was on the waiting list, but not high priority. Why do you ask?",
                        suspectReaction: "Becoming defensive",
                        revealsEvidence: "Transplant List Access",
                        changesRelationship: -1
                    )
                ],
                requiredEvidence: [],
                isUnlocked: true
            ),
            
            DialogueNode(
                questionText: "This syringe was found in the room. Any idea what it contained?",
                responses: [
                    DialogueResponse(
                        text: "It looks like it could be a paralytic agent. That's very concerning.",
                        suspectReaction: "Visibly shaken",
                        revealsEvidence: "Paralytic Knowledge",
                        changesRelationship: -2
                    )
                ],
                requiredEvidence: ["Syringe"],
                isUnlocked: false
            ),
            
        ]
        
        updateUnlockedQuestions()
    }
    
    private func updateUnlockedQuestions() {
        for i in availableQuestions.indices {
            let question = availableQuestions[i]
            let hasRequiredEvidence = question.requiredEvidence.allSatisfy { evidenceName in
                gameState.hasEvidence(named: evidenceName)
            }
            
            if hasRequiredEvidence && !question.isUnlocked {
                availableQuestions[i].isUnlocked = true
                gameState.unlockDialogueNode(availableQuestions[i])
            }
        }
    }
    
    private func startConversation() {
        if let suspect = selectedSuspect {
            conversationHistory.append(
                ConversationEntry(
                    speaker: .suspect,
                    text: "I understand you want to speak with me about what happened last night. I'm willing to cooperate.",
                    timestamp: Date()
                )
            )
        }
    }
    
    func askQuestion(_ question: DialogueNode) {
        // Add question to conversation
        conversationHistory.append(
            ConversationEntry(
                speaker: .investigator,
                text: question.questionText,
                timestamp: Date()
            )
        )
        
        // Get response (in a real game, this might involve choice selection)
        if let response = question.responses.first {
            // Add response to conversation
            conversationHistory.append(
                ConversationEntry(
                    speaker: .suspect,
                    text: response.text,
                    timestamp: Date()
                )
            )
            
            // Update game state
            gameState.updateSuspectCooperation(by: response.changesRelationship)
            
            // Add revealed evidence
            if let evidenceName = response.revealsEvidence {
                let evidence = Evidence(
                    name: evidenceName,
                    description: "Information revealed during interrogation",
                    actDiscovered: 3,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["source": "interrogation", "suspect": selectedSuspect?.name ?? "Unknown"]
                )
                gameState.addEvidence(evidence)
            }
        }
        
        // Remove used question
        availableQuestions.removeAll { $0.id == question.id }
        updateUnlockedQuestions()
    }
}


// MARK: - Act 3: Interrogation View
struct Act3InterrogationView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act3ViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: Act3ViewModel(gameState: GameState()))
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Conversation area
            VStack {
                // Header
                HStack {
                    Text("🗣️ **Interrogation Room**")
                        .font(.headline)
                    
                    Spacer()
                    
                    if let suspect = viewModel.selectedSuspect {
                        Text("Interviewing: \(suspect.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Suspect cooperation meter
                CooperationMeterView()
                
                // Conversation history
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.conversationHistory) { entry in
                                ConversationBubbleView(
                                    entry: entry,
                                    playerImage: gameState.selectedDetective,
                                    suspectImage: viewModel.selectedSuspect?.portraitImage ?? "prisonSurgeon",
                                    suspectName: viewModel.selectedSuspect?.name ?? "Suspect"
                                )
                                .id(entry.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .onChange(of: viewModel.conversationHistory.count) { _ in
                        if let lastEntry = viewModel.conversationHistory.last {
                            withAnimation {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Questions sidebar
            VStack(alignment: .leading) {
                Text("Available Questions")
                    .font(.headline)
                    .padding(.bottom)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.availableQuestions) { question in
                            QuestionCardView(
                                question: question,
                                onAsk: {
                                    viewModel.askQuestion(question)
                                }
                            )
                        }
                        
                        if viewModel.isStuck {
                            StuckHintView(hints: viewModel.hints, onGoBack: { act in
                                gameState.jumpToAct(act)
                            })
                        } else if viewModel.availableQuestions.isEmpty {
                            Text("No more questions available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
            }
            .frame(width: 300)
        }
        .padding()
        .onAppear {
            viewModel.gameState = gameState
        }
    }
}

struct CooperationMeterView: View {
    @EnvironmentObject private var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Suspect Cooperation:")
                    .font(.caption)
                Spacer()
                Text("\(gameState.suspectCooperationLevel)/10")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            ProgressView(value: Double(gameState.suspectCooperationLevel), total: 10.0)
                .progressViewStyle(LinearProgressViewStyle(tint: cooperationColor))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var cooperationColor: Color {
        switch gameState.suspectCooperationLevel {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .yellow
        default: return .green
        }
    }
}

struct ConversationBubbleView: View {
    let entry: ConversationEntry
    let playerImage: String
    let suspectImage: String
    var suspectName: String = "Suspect"

    private var isPlayer: Bool { entry.speaker == .investigator }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isPlayer {
                Spacer(minLength: 50)
            } else {
                portraitView(suspectImage)
            }

            VStack(alignment: isPlayer ? .trailing : .leading) {
                Text(entry.text)
                    .padding()
                    .background(isPlayer ? Color.blue.opacity(0.7) : Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(isPlayer ? .white : .primary)

                Text(isPlayer ? "You" : suspectName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if isPlayer {
                portraitView(playerImage)
            } else {
                Spacer(minLength: 50)
            }
        }
    }

    private func portraitView(_ imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 55, height: 55)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

struct QuestionCardView: View {
    let question: DialogueNode
    let onAsk: () -> Void
    
    var body: some View {
        Button(action: onAsk) {
            VStack(alignment: .leading, spacing: 8) {
                Text(question.questionText)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                if !question.requiredEvidence.isEmpty {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("Requires: \(question.requiredEvidence.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(question.isUnlocked ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(question.isUnlocked ? Color.blue : Color.gray, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!question.isUnlocked)
    }
}

// MARK: - Stuck Hint View
struct StuckHintView: View {
    let hints: [(message: String, targetAct: GameAct)]
    let onGoBack: (GameAct) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Need More Evidence")
                    .font(.headline)
            }
            
            Text("You've run out of questions to ask. Collect more evidence to unlock new lines of questioning.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            ForEach(Array(hints.enumerated()), id: \.offset) { _, hint in
                Button(action: { onGoBack(hint.targetAct) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hint.message)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                            Text("Return to Act \(hint.targetAct.rawValue): \(hint.targetAct.title)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

// TODO: Expand this view with:
// - Multiple suspects to choose from
// - Dynamic response trees based on evidence
// - Emotional state tracking
// - Voice stress analysis mini-game
// - Note-taking functionality
// - Response timing mechanics

#Preview {
    Act3InterrogationView()
        .environmentObject(GameState())
}
