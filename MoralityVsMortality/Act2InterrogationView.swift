import SwiftUI
import Combine

// MARK: - Act 2: Wrapper View
struct Act2InterrogationView: View {
    var body: some View {
        Act2InterrogationMainView()
    }
}

// MARK: - Interrogation Order
enum InterrogationStage: Int, CaseIterable {
    case kathy = 0
    case receptionist = 1
    case morgueWorker = 2
    case surgeon = 3

    var suspectName: String {
        switch self {
        case .kathy: return "Kathy Alvarez"
        case .receptionist: return "Receptionist"
        case .morgueWorker: return "Peter Simmons"
        case .surgeon: return "Dr. Viktor Kazimir"
        }
    }

    var portraitImage: String {
        switch self {
        case .kathy: return "prisonNurse"
        case .receptionist: return "prisonReceptionist"
        case .morgueWorker: return "prisonMorgueWorker"
        case .surgeon: return "prisonSurgeon"
        }
    }

    var greeting: String {
        switch self {
        case .kathy: return "I understand you want to talk about what happened. I'll tell you what I know."
        case .receptionist: return "How can I help you? I manage the front desk and access logs."
        case .morgueWorker: return "I handled the body. That's my job. What do you want to know?"
        case .surgeon: return "I'm a busy man. Ask your questions."
        }
    }
}

// MARK: - Act 2: View Model
@MainActor
class Act2ViewModel: ObservableObject {
    @Published var currentStage: InterrogationStage = .kathy
    @Published var conversationHistory: [ConversationEntry] = []
    @Published var availableQuestions: [InterrogationQuestion] = []
    @Published var askedQuestions: Set<String> = []
    @Published var stageComplete = false
    @Published var completedStages: Set<Int> = []

    var gameState: GameState

    init(gameState: GameState) {
        self.gameState = gameState
        loadStage(.kathy)
    }

    func loadStage(_ stage: InterrogationStage) {
        currentStage = stage
        conversationHistory.removeAll()
        askedQuestions.removeAll()
        stageComplete = false
        loadQuestions(for: stage)

        conversationHistory.append(
            ConversationEntry(speaker: .suspect, text: stage.greeting)
        )
    }

    func advanceToNextStage() {
        completedStages.insert(currentStage.rawValue)
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

    func askQuestion(_ question: InterrogationQuestion) {
        guard !askedQuestions.contains(question.id) else { return }
        askedQuestions.insert(question.id)

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
                actDiscovered: 2,
                isRealEvidence: true,
                evidenceType: .document,
                metadata: ["source": "interrogation", "suspect": currentStage.suspectName]
            )
            gameState.addEvidence(evidence)
        }

        let node = DialogueNode(
            questionText: question.questionText,
            responses: [DialogueResponse(text: question.responseText, suspectReaction: "")],
            requiredEvidence: [],
            isUnlocked: true
        )
        gameState.unlockDialogueNode(node)
        gameState.updateSuspectCooperation(by: question.cooperationChange)

        // Check if all questions for this stage are done
        if unaskedQuestions.isEmpty {
            stageComplete = true
        }
    }

    var unaskedQuestions: [InterrogationQuestion] {
        availableQuestions.filter { q in
            !askedQuestions.contains(q.id) && meetsRequirements(q)
        }
    }

    private func meetsRequirements(_ question: InterrogationQuestion) -> Bool {
        question.requiredEvidence.allSatisfy { gameState.hasEvidence(named: $0) }
    }

    var isLastStage: Bool {
        currentStage == .surgeon
    }

    // MARK: - Kathy Alvarez Questions
    private func kathyQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "Why were you at the hospital at 2 AM?",
                responseText: "I came back to grab something I forgot... I checked on my patient while I was there.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "Why him specifically?",
                responseText: "He had surgery in the morning. I didn't want anything to go wrong.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "What did you find when you checked on him?",
                responseText: "He wasn't responding. I tried to wake him... nothing.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "What did you do next?",
                responseText: "I called Dr. Kazimir.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "Why not call emergency response?",
                responseText: "...I thought it was sedation-related. I didn't want to overreact.",
                cooperationChange: -1
            ),
            InterrogationQuestion(
                questionText: "And when the doctor arrived?",
                responseText: "He examined him... and said he was gone.",
                cooperationChange: 0
            )
        ]
    }

    // MARK: - Receptionist Questions
    private func receptionistQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "Do you track who enters patient rooms?",
                responseText: "Yes. Staff use badges. It's all logged in the system.",
                cooperationChange: 1
            ),
            InterrogationQuestion(
                questionText: "Can I access those logs?",
                responseText: "I'm not supposed to... but if this is an official investigation, I can pull them up.",
                unlocksEvidence: "Room Access Log",
                evidenceDescription: "Digital access log showing Kathy Alvarez entered at 2:00 AM. Dr. Kazimir entered shortly after. Confirms the timeline.",
                cooperationChange: 2
            )
        ]
    }

    // MARK: - Morgue Worker Questions
    private func morgueWorkerQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "What was the official cause of death?",
                responseText: "That's what the report says. Heart attack.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "Do you agree with that assessment?",
                responseText: "...It wasn't typical.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "Why not?",
                responseText: "No trauma. No stress signs. Nothing that usually points to cardiac arrest.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "Anything unusual about the body?",
                responseText: "...Injection marks. More than expected for a routine pre-op.",
                cooperationChange: -1
            )
        ]
    }

    // MARK: - Surgeon Initial Questions
    private func surgeonQuestions() -> [InterrogationQuestion] {
        [
            InterrogationQuestion(
                questionText: "You declared Wayne Michaels dead. Walk me through it.",
                responseText: "The nurse called me. I arrived, assessed the patient. No pulse, no response. I pronounced him at 2:47 AM.",
                cooperationChange: 0
            ),
            InterrogationQuestion(
                questionText: "The sedation levels seem unusually high for a routine procedure.",
                responseText: "I approved the sedation protocol. Every patient is different.",
                requiredEvidence: ["Sedation Chart"],
                cooperationChange: -1
            ),
            InterrogationQuestion(
                questionText: "His vital monitor shows he still had a heartbeat at 2:00 AM.",
                responseText: "You're misreading medical data. Residual electrical activity isn't the same as life.",
                requiredEvidence: ["Vital Monitor Printout"],
                cooperationChange: -1
            ),
            InterrogationQuestion(
                questionText: "His license says he's not an organ donor. But his intake form has a screenshot showing he is.",
                responseText: "Records get updated. Patients change their minds. It happens.",
                requiredEvidence: ["Wayne's License", "Prison Intake Form"],
                cooperationChange: -2
            )
        ]
    }
}

// MARK: - Interrogation Question Model
struct InterrogationQuestion: Identifiable {
    let id: String
    let questionText: String
    let responseText: String
    var requiredEvidence: [String]
    var unlocksEvidence: String?
    var evidenceDescription: String?
    var cooperationChange: Int

    init(questionText: String, responseText: String,
         requiredEvidence: [String] = [], unlocksEvidence: String? = nil,
         evidenceDescription: String? = nil, cooperationChange: Int = 0) {
        self.id = questionText
        self.questionText = questionText
        self.responseText = responseText
        self.requiredEvidence = requiredEvidence
        self.unlocksEvidence = unlocksEvidence
        self.evidenceDescription = evidenceDescription
        self.cooperationChange = cooperationChange
    }
}

// MARK: - Act 2: Main View
struct Act2InterrogationMainView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act2ViewModel

    init() {
        self._viewModel = StateObject(wrappedValue: Act2ViewModel(gameState: GameState()))
    }

    var body: some View {
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
                            .foregroundColor(stage == viewModel.currentStage ? .primary : .secondary)
                            .fontWeight(stage == viewModel.currentStage ? .bold : .regular)
                    }
                    .padding(.horizontal, 8)

                    if stage.rawValue < InterrogationStage.allCases.count - 1 {
                        Rectangle()
                            .fill(viewModel.completedStages.contains(stage.rawValue) ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.05))

            Divider()

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
                    Text("Interrogation \(viewModel.currentStage.rawValue + 1) of 4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CooperationMeterView()
                    .frame(width: 180)
            }
            .padding()
            .background(Color.gray.opacity(0.05))

            // Conversation
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.conversationHistory) { entry in
                            ConversationBubbleView(
                                entry: entry,
                                playerImage: gameState.selectedDetective,
                                suspectImage: viewModel.currentStage.portraitImage,
                                suspectName: viewModel.currentStage.suspectName
                            )
                            .id(entry.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.conversationHistory.count) { _ in
                    if let last = viewModel.conversationHistory.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Questions or next button
            if viewModel.stageComplete {
                HStack {
                    Spacer()
                    if viewModel.isLastStage {
                        Text("Interrogations complete.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                    }
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.unaskedQuestions) { question in
                            Button {
                                viewModel.askQuestion(question)
                            } label: {
                                Text(question.questionText)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .frame(height: 60)
                .background(Color.gray.opacity(0.05))
            }
        }
        .onAppear {
            viewModel.gameState = gameState
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

// MARK: - Cooperation Meter
struct CooperationMeterView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Cooperation:")
                    .font(.caption2)
                Spacer()
                Text("\(gameState.suspectCooperationLevel)/10")
                    .font(.caption2)
                    .fontWeight(.bold)
            }

            ProgressView(value: Double(gameState.suspectCooperationLevel), total: 10.0)
                .progressViewStyle(LinearProgressViewStyle(tint: cooperationColor))
        }
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

// MARK: - Conversation Bubble
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

#Preview {
    Act2InterrogationMainView()
        .environmentObject(GameState())
}
