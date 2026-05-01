import SwiftUI
import Combine

// wrapper view
struct Act1InterrogationView: View {
    var body: some View {
        Act1InterrogationMainView()
    }
}

// interoggation view
enum InterrogationStage: Int, CaseIterable {
    case kathy = 0
    case receptionist = 1
    case morgueWorker = 2
    case surgeon = 3

    var suspectName: String {
        switch self {
        case .kathy: return "Kathy Williams"
        case .receptionist: return "Hilarie Jones"
        case .morgueWorker: return "Peter Simmons"
        case .surgeon: return "Dr. Victor Smith"
        }
    }

    var jobTitle: String {
        switch self {
        case .kathy: return "Nurse"
        case .receptionist: return "Receptionist"
        case .morgueWorker: return "Morgue Technician"
        case .surgeon: return "Attending Surgeon"
        }
    }

    var portraitImage: String {
        switch self {
        case .kathy: return "prisonNurse"
        case .receptionist: return "hospitalReceptionist"
        case .morgueWorker: return "morgueTechnician"
        case .surgeon: return "prisonSurgeon"
        }
    }

    var greeting: String {
        switch self {
        case .kathy: return "I understand you want to talk about what happened. I'll tell you what I know."
        case .receptionist: return "How can I help you? I manage the front desk and the room access logs."
        case .morgueWorker: return "I handled the body. That's my job. What do you want to know?"
        case .surgeon: return "I'm a busy man. Ask your questions."
        }
    }
}

// act 1: view model
@MainActor
class Act1ViewModel: ObservableObject {
    @Published var currentStage: InterrogationStage = .kathy
    @Published var conversationHistory: [ConversationEntry] = []
    @Published var availableQuestions: [InterrogationQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var stageComplete = false
    @Published var completedStages: Set<Int> = []

    var gameState: GameState
    private var hasSetRealGameState = false

    init(gameState: GameState) {
        self.gameState = gameState
        loadStage(.kathy)
    }

    func setGameState(_ state: GameState) {
        guard !hasSetRealGameState else { return }
        hasSetRealGameState = true
        gameState = state

        // Restore progress from GameState
        completedStages = state.completedInterrogationStages
        if !completedStages.isEmpty {
            // Find the first incomplete stage, or stay on the last if all done
            let nextIncomplete = InterrogationStage.allCases.first { !completedStages.contains($0.rawValue) }
            if let stage = nextIncomplete {
                loadStage(stage)
            } else {
                // All stages completed — show the last stage as complete
                loadStage(.surgeon)
                stageComplete = true
            }
        }
    }

    func loadStage(_ stage: InterrogationStage) {
        currentStage = stage
        conversationHistory.removeAll()
        currentQuestionIndex = 0
        stageComplete = false
        loadQuestions(for: stage)

        conversationHistory.append(
            ConversationEntry(speaker: .suspect, text: stage.greeting)
        )
    }

    func advanceToNextStage() {
        completedStages.insert(currentStage.rawValue)
        gameState.completedInterrogationStages = completedStages
        gameState.saveGame()
        if let next = InterrogationStage(rawValue: currentStage.rawValue + 1) {
            loadStage(next)
        }
    }

    private func loadQuestions(for stage: InterrogationStage) {
        switch stage {
        case .kathy: availableQuestions = kathyQuestions()
        case .receptionist: availableQuestions = receptionistQuestions()
        case .morgueWorker: availableQuestions = morgueWorkerQuestions()
        case .surgeon: availableQuestions = surgeonQuestions()
        }
    }

    var currentQuestion: InterrogationQuestion? {
        guard currentQuestionIndex < availableQuestions.count else { return nil }
        return availableQuestions[currentQuestionIndex]
    }

    func askCurrentQuestion() {
        guard let question = currentQuestion else { return }

        conversationHistory.append(
            ConversationEntry(speaker: .investigator, text: question.questionText)
        )
        conversationHistory.append(
            ConversationEntry(speaker: .suspect, text: question.responseText)
        )

        if let evidenceName = question.unlocksEvidence {
            let evidence = Evidence(
                name: evidenceName,
                description: question.evidenceDescription ?? "Information from interrogation.",
                actDiscovered: 1,
                isRealEvidence: true,
                evidenceType: .document,
                metadata: ["source": "interrogation", "suspect": currentStage.suspectName]
            )
            gameState.addEvidence(evidence)
        }

        let node = DialogueNode(
            questionText: question.questionText,
            responses: [DialogueResponse(text: question.responseText)]
        )
        gameState.unlockDialogueNode(node)

        currentQuestionIndex += 1
        if currentQuestionIndex >= availableQuestions.count {
            stageComplete = true
            completedStages.insert(currentStage.rawValue)
            gameState.completedInterrogationStages = completedStages
            gameState.saveGame()
        }
    }

    var isLastStage: Bool {
        currentStage == .surgeon
    }

    // kathy williams questions that are asked
    
    private func kathyQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "Why were you at the hospital at 3 AM?",
                responseText: "I came back to grab something I forgot... I checked on my patient while I was there."
            ),
            InterrogationQuestion(
                questionText: "Why him specifically?",
                responseText: "He had surgery in the morning. I didn't want anything to go wrong."
            ),
            InterrogationQuestion(
                questionText: "What did you find when you checked on him?",
                responseText: "He wasn't responding. I tried to wake him... nothing."
            ),
            InterrogationQuestion(
                questionText: "What did you do next?",
                responseText: "I called Dr. Smith."
            ),
            InterrogationQuestion(
                questionText: "Why not call emergency response?",
                responseText: "...I thought it was sedation related. I didn't want to overreact."
            ),
            InterrogationQuestion(
                questionText: "And when the doctor arrived?",
                responseText: "He examined him... and said he was gone."
            )
        ]
    }

    // receptionist questions
    
    private func receptionistQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "Do you track who enters patient rooms?",
                responseText: "Yes. Staff use badges. It's all logged in the system. There's a time log posted by every room door."
            ),
            InterrogationQuestion(
                questionText: "Can I get a copy of the room access log for Wayne's room?",
                responseText: "I'm not supposed to... but if this is an official investigation, I can pull it up for you.",
                unlocksEvidence: "Time Log",
                evidenceDescription: "Room access log showing all entries into Wayne's hospital room. You'll need to examine this more closely later."
            ),
            InterrogationQuestion(
                questionText: "Is there anything else you can tell me about that night?",
                responseText: "Not really... it was a normal shift. I just manage the desk and the logs. You should talk to the people who were actually in the room."
            )
        ]
    }

    // morgue worker questions
    
    private func morgueWorkerQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "What was the official cause of death?",
                responseText: "That's what the report says. Cardiac arrest."
            ),
            InterrogationQuestion(
                questionText: "Do you agree with that assessment?",
                responseText: "...It wasn't typical."
            ),
            InterrogationQuestion(
                questionText: "Why not?",
                responseText: "No trauma. No stress signs. Nothing that usually points to cardiac arrest."
            ),
            InterrogationQuestion(
                questionText: "Anything unusual about the body?",
                responseText: "...Injection marks. More than expected for a routine preop."
            )
        ]
    }

    // surgeon initial questions
    private func surgeonQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "You declared Wayne Michaels dead. Walk me through it.",
                responseText: "The nurse called me. I arrived, assessed the patient. No pulse, no response. I pronounced him at 3:10 AM."
            ),
            InterrogationQuestion(
                questionText: "What was the cause of death?",
                responseText: "Cardiac arrest. It happens. Especially with patients under sedation before major procedures."
            ),
            InterrogationQuestion(
                questionText: "Was there anything unusual about his condition?",
                responseText: "No. He was a standard preoperative patient. Nothing out of the ordinary."
            ),
            InterrogationQuestion(
                questionText: "Who authorized the sedation?",
                responseText: "I did. I approve all sedation protocols for my patients. It was routine."
            )
        ]
    }
}

// interrogation questions view
struct InterrogationQuestion: Identifiable {
    let id: String
    let questionText: String
    let responseText: String
    var requiredEvidence: [String]
    var unlocksEvidence: String?
    var evidenceDescription: String?

    init(questionText: String, responseText: String,
         requiredEvidence: [String] = [], unlocksEvidence: String? = nil,
         evidenceDescription: String? = nil) {
        self.id = questionText
        self.questionText = questionText
        self.responseText = responseText
        self.requiredEvidence = requiredEvidence
        self.unlocksEvidence = unlocksEvidence
        self.evidenceDescription = evidenceDescription
    }
}

// main view
struct Act1InterrogationMainView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act1ViewModel

    init() {
        self._viewModel = StateObject(wrappedValue: Act1ViewModel(gameState: GameState()))
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar showing interrogation order
                HStack(spacing: 0) {
                    ForEach(InterrogationStage.allCases, id: \.rawValue) { stage in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(stageColor(stage))
                                .frame(width: 10, height: 10)
                            Text(stage.suspectName)
                                .font(.caption2)
                                .foregroundColor(stage == viewModel.currentStage ? .white : .white.opacity(0.6))
                                .fontWeight(stage == viewModel.currentStage ? .bold : .regular)
                        }
                        .padding(.horizontal, 8)

                        if stage.rawValue < InterrogationStage.allCases.count - 1 {
                            Rectangle()
                                .fill(viewModel.completedStages.contains(stage.rawValue) ? Color.green : Color.white.opacity(0.2))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))

                Divider()
                    .overlay(Color.white.opacity(0.12))

                // Header with current suspect
                HStack {
                    Image(viewModel.currentStage.portraitImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(viewModel.currentStage.suspectName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(viewModel.currentStage.jobTitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                        Text("Interrogation \(viewModel.currentStage.rawValue + 1) of 4")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.06))

                // Conversation
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.conversationHistory) { entry in
                                ConversationBubbleView(
                                    entry: entry,
                                    playerImage: gameState.selectedDetective,
                                    suspectImage: viewModel.currentStage.portraitImage,
                                    suspectName: viewModel.currentStage.suspectName,
                                    playerName: gameState.playerName.isEmpty ? "You" : gameState.playerName
                                )
                                .id(entry.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color.black)
                    .onChange(of: viewModel.conversationHistory.count) { _ in
                        if let last = viewModel.conversationHistory.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                .layoutPriority(0)

                Divider()
                    .overlay(Color.white.opacity(0.12))

                // Sequential question or next button
                VStack(spacing: 8) {
                    if viewModel.stageComplete {
                        if viewModel.isLastStage {
                            Text("Interrogations complete.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        } else {
                            Button {
                                viewModel.advanceToNextStage()
                            } label: {
                                HStack {
                                    Text("Next: \(InterrogationStage(rawValue: viewModel.currentStage.rawValue + 1)?.suspectName ?? "")")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                    } else if let question = viewModel.currentQuestion {
                        Button {
                            viewModel.askCurrentQuestion()
                        } label: {
                            Text(question.questionText)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .layoutPriority(1)
            }
        }
        .onAppear {
            viewModel.setGameState(gameState)
        }
    }

    private func stageColor(_ stage: InterrogationStage) -> Color {
        if viewModel.completedStages.contains(stage.rawValue) {
            return .green
        } else if stage == viewModel.currentStage {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// conversation bubble
struct ConversationBubbleView: View {
    let entry: ConversationEntry
    let playerImage: String
    let suspectImage: String
    var suspectName: String = "Suspect"
    var playerName: String = "You"

    private var isPlayer: Bool { entry.speaker == .investigator }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isPlayer {
                Spacer(minLength: 50)
            } else {
                portraitView(suspectImage)
            }

            VStack(alignment: isPlayer ? .trailing : .leading, spacing: 4) {
                Text(isPlayer ? playerName : suspectName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))

                Text(entry.text)
                    .font(.title3)
                    .padding(14)
                    .background(isPlayer ? Color.purple.opacity(0.8) : Color.cyan.opacity(0.4))
                    .cornerRadius(12)
                    .foregroundColor(.white)
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

#Preview {
    Act1InterrogationMainView()
        .environmentObject(GameState())
}
