import SwiftUI
import Combine

// MARK: - Act 4: Wrapper View
struct Act4ConfrontationView: View {
    var body: some View {
        Act6ConfrontationView()
    }
}

// MARK: - Act 6: Confrontation View Model
@MainActor
class Act6ViewModel: ObservableObject {
    @Published var confrontationDialogue: [ConversationEntry] = []
    @Published var availableAccusations: [AccusationOption] = []
    @Published var selectedAccusation: AccusationOption?
    @Published var confrontationComplete: Bool = false
    @Published var suspectResponse: String = ""
    @Published var evidencePresented: [Evidence] = []
    
    var gameState: GameState
    
    init(gameState: GameState) {
        self.gameState = gameState
        setupConfrontation()
    }
    
    private func setupConfrontation() {
        // Opening dialogue based on evidence strength
        let openingText = generateOpeningDialogue()
        confrontationDialogue.append(
            ConversationEntry(
                speaker: .investigator,
                text: openingText
            )
        )
        
        // Suspect's initial response based on cooperation level
        let suspectReaction = generateSuspectReaction()
        confrontationDialogue.append(
            ConversationEntry(
                speaker: .suspect,
                text: suspectReaction
            )
        )
        
        setupAccusationOptions()
    }
    
    private func generateOpeningDialogue() -> String {
        let score = gameState.caseScore
        let correctConnections = gameState.correctConnectionsCount
        
        switch (score, correctConnections) {
        case (80..., 4...):
            return "Dr. Chen, I have substantial evidence linking you to the attack on the patient in Room 342. Multiple pieces of evidence point to your involvement in what appears to be an illegal organ harvesting operation."
            
        case (60..<80, 3):
            return "Dr. Chen, I have several concerning pieces of evidence that suggest your involvement in the incident. I'd like to give you a chance to explain before we proceed."
            
        case (40..<60, 2):
            return "Dr. Chen, I have some evidence that raises questions about your whereabouts and actions last night. Can you help me understand what happened?"
            
        default:
            return "Dr. Chen, thank you for meeting with me again. I have a few more questions based on my investigation. I'm still trying to piece together what happened."
        }
    }
    
    private func generateSuspectReaction() -> String {
        let cooperationLevel = gameState.suspectCooperationLevel
        let evidenceStrength = gameState.caseScore
        
        switch (cooperationLevel, evidenceStrength) {
        case (8..., 80...):
            return "I... I can see you've been very thorough. I suppose there's no point in denying it anymore. Yes, I was involved, but not in the way you might think."
            
        case (6...7, 60..<80):
            return "Those are serious allegations. I admit some of the evidence looks bad, but I can explain everything. I was trying to help the patient, not harm him."
            
        case (4...5, _):
            return "I don't appreciate these accusations. Yes, I was in the hospital that night - I work here. But I had nothing to do with any attack."
            
        case (...3, _):
            return "This is ridiculous. I've already told you everything I know. I think this conversation is over unless you have something concrete."
            
        default:
            return "I'm willing to listen to your concerns, Detective. What exactly are you suggesting happened?"
        }
    }
    
    private func setupAccusationOptions() {
        // Generate accusation options based on collected evidence
        var options: [AccusationOption] = []
        
        // Base accusations always available
        options.append(
            AccusationOption(
                title: "Accuse of assault",
                description: "Charge Dr. Chen with assault on the patient",
                requiredEvidence: ["Bloody Glove", "Syringe"],
                outcome: .partialTruth,
                response: "Yes, I did sedate him, but it was to save his life, not harm him."
            )
        )
        
        if gameState.hasEvidence(named: "Hospital ID Badge") {
            options.append(
                AccusationOption(
                    title: "Accuse of illegal entry",
                    description: "Charge Dr. Chen with unauthorized access using stolen credentials",
                    requiredEvidence: ["Hospital ID Badge"],
                    outcome: .falseAccusation,
                    response: "That's my own ID badge. I had every right to be there - I'm the attending physician."
                )
            )
        }
        
        if gameState.correctConnectionsCount >= 3 {
            options.append(
                AccusationOption(
                    title: "Accuse of organ trafficking",
                    description: "Present evidence of illegal organ harvesting operation",
                    requiredEvidence: ["Transplant List Access", "Paralytic Knowledge"],
                    outcome: .fullTruth,
                    response: "You don't understand. Yes, I was involved in the organ program, but I was trying to expose it, not participate in it. The patient was going to be the next victim, so I had to sedate him to keep him safe until I could get help."
                )
            )
        }
        
        if gameState.caseScore < 50 {
            options.append(
                AccusationOption(
                    title: "Request explanation",
                    description: "Ask for Dr. Chen's version of events",
                    requiredEvidence: [],
                    outcome: .needMoreEvidence,
                    response: "I can see you're still gathering information. Perhaps you should investigate more thoroughly before making accusations."
                )
            )
        }
        
        availableAccusations = options.filter { option in
            option.requiredEvidence.allSatisfy { evidenceName in
                gameState.hasEvidence(named: evidenceName)
            }
        }
    }
    
    func presentAccusation(_ accusation: AccusationOption) {
        selectedAccusation = accusation
        
        // Add accusation to dialogue
        confrontationDialogue.append(
            ConversationEntry(
                speaker: .investigator,
                text: accusation.description
            )
        )
        
        // Present evidence
        evidencePresented = accusation.requiredEvidence.compactMap { evidenceName in
            gameState.collectedEvidence.first { $0.name == evidenceName }
        }
        
        // Add suspect response
        confrontationDialogue.append(
            ConversationEntry(
                speaker: .suspect,
                text: accusation.response
            )
        )
        
        suspectResponse = accusation.response
        confrontationComplete = true
        
        // Update game state based on outcome
        updateGameStateForOutcome(accusation.outcome)
    }
    
    private func updateGameStateForOutcome(_ outcome: AccusationOutcome) {
        switch outcome {
        case .fullTruth:
            gameState.caseScore += 20
        case .partialTruth:
            gameState.caseScore += 10
        case .falseAccusation:
            gameState.caseScore -= 10
            gameState.updateSuspectCooperation(by: -2)
        case .needMoreEvidence:
            // No score change
            break
        }
    }
}

// MARK: - Act 6: Confrontation View
struct Act6ConfrontationView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act6ViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: Act6ViewModel(gameState: GameState()))
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Conversation area
            VStack {
                // Header
                HStack {
                    Text("⚖️ **Confrontation**")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Present your case")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Character portraits
                CharacterPortraitsView()
                
                // Conversation display
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.confrontationDialogue) { entry in
                                ConversationBubbleView(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .onChange(of: viewModel.confrontationDialogue.count) { _ in
                        if let lastEntry = viewModel.confrontationDialogue.last {
                            withAnimation {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Accusation options
            VStack(alignment: .leading) {
                Text("Your Move")
                    .font(.headline)
                    .padding(.bottom)
                
                if !viewModel.confrontationComplete {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.availableAccusations) { accusation in
                                AccusationOptionView(
                                    accusation: accusation,
                                    onSelect: {
                                        viewModel.presentAccusation(accusation)
                                    }
                                )
                            }
                        }
                    }
                } else {
                    // Show outcome and evidence presented
                    ConfrontationOutcomeView(
                        accusation: viewModel.selectedAccusation,
                        evidencePresented: viewModel.evidencePresented
                    )
                }
            }
            .frame(width: 350)
        }
        .padding()
        .onAppear {
            viewModel.gameState = gameState
        }
    }
}

struct CharacterPortraitsView: View {
    var body: some View {
        HStack {
            // Investigator
            VStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("👨‍💼")
                            .font(.title)
                    )
                Text("Detective")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Text("VS")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Suspect
            VStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("👩‍⚕️")
                            .font(.title)
                    )
                Text("Dr. Chen")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AccusationOptionView: View {
    let accusation: AccusationOption
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Text(accusation.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(accusation.description)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                if !accusation.requiredEvidence.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Required Evidence:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ForEach(accusation.requiredEvidence, id: \.self) { evidence in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(evidence)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ConfrontationOutcomeView: View {
    let accusation: AccusationOption?
    let evidencePresented: [Evidence]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Case Presented")
                .font(.headline)
            
            if let accusation = accusation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accusation:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(accusation.title)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("Outcome:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    
                    HStack {
                        Image(systemName: outcomeIcon)
                            .foregroundColor(outcomeColor)
                        Text(outcomeDescription)
                            .font(.body)
                            .foregroundColor(outcomeColor)
                    }
                }
            }
            
            if !evidencePresented.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Evidence Presented:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(evidencePresented, id: \.id) { evidence in
                        Text("• \(evidence.name)")
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var outcomeIcon: String {
        guard let accusation = accusation else { return "questionmark.circle" }
        
        switch accusation.outcome {
        case .fullTruth: return "checkmark.circle.fill"
        case .partialTruth: return "checkmark.circle"
        case .falseAccusation: return "xmark.circle.fill"
        case .needMoreEvidence: return "magnifyingglass.circle"
        }
    }
    
    private var outcomeColor: Color {
        guard let accusation = accusation else { return .gray }
        
        switch accusation.outcome {
        case .fullTruth: return .green
        case .partialTruth: return .orange
        case .falseAccusation: return .red
        case .needMoreEvidence: return .blue
        }
    }
    
    private var outcomeDescription: String {
        guard let accusation = accusation else { return "Unknown" }
        
        switch accusation.outcome {
        case .fullTruth: return "Truth Revealed"
        case .partialTruth: return "Partial Truth"
        case .falseAccusation: return "Incorrect Accusation"
        case .needMoreEvidence: return "Insufficient Evidence"
        }
    }
}

// MARK: - Act 7: Final Choice View Model
@MainActor
class Act7ViewModel: ObservableObject {
    @Published var finalChoices: [FinalChoice] = []
    @Published var selectedChoice: FinalChoice?
    @Published var outcomeRevealed: Bool = false
    @Published var finalOutcome: GameOutcome?
    @Published var caseReviewData: CaseReviewData?
    
    var gameState: GameState
    
    init(gameState: GameState) {
        self.gameState = gameState
        setupFinalChoices()
        generateCaseReview()
    }
    
    private func setupFinalChoices() {
        let score = gameState.caseScore
        let correctConnections = gameState.correctConnectionsCount
        let evidenceCount = gameState.realEvidenceCount
        
        // Choice options vary based on player performance
        if score >= 80 && correctConnections >= 4 {
            // High performance - both options available
            finalChoices = [
                FinalChoice(
                    title: "Arrest Dr. Chen",
                    description: "You have sufficient evidence to arrest Dr. Chen for assault and involvement in the organ trafficking ring. She will face trial, but the larger network may go underground.",
                    outcome: .arrest,
                    requirements: "Strong evidence gathered",
                    consequences: "Justice served, but network may escape"
                ),
                FinalChoice(
                    title: "Work with Dr. Chen",
                    description: "Accept Dr. Chen's explanation that she was trying to expose the organ trafficking ring. Work together to take down the real perpetrators.",
                    outcome: .cooperation,
                    requirements: "High trust and evidence quality",
                    consequences: "Larger network exposed, but Dr. Chen goes free"
                )
            ]
        } else if score >= 60 {
            // Medium performance - limited options
            finalChoices = [
                FinalChoice(
                    title: "Arrest Dr. Chen",
                    description: "While the evidence isn't overwhelming, there's enough to charge Dr. Chen with assault. The case may not hold up in court without more evidence.",
                    outcome: .weakArrest,
                    requirements: "Moderate evidence",
                    consequences: "Weak case, may not result in conviction"
                ),
                FinalChoice(
                    title: "Continue Investigation",
                    description: "The evidence is inconclusive. Request more time to investigate before making an arrest. This may allow other perpetrators to escape.",
                    outcome: .continueInvestigation,
                    requirements: "Insufficient evidence",
                    consequences: "Case remains open, suspects may flee"
                )
            ]
        } else {
            // Low performance - forced outcomes
            finalChoices = [
                FinalChoice(
                    title: "Close Case - Insufficient Evidence",
                    description: "Without sufficient evidence, you cannot proceed with charges. The case will be closed pending new developments.",
                    outcome: .closedCase,
                    requirements: "Minimal evidence gathered",
                    consequences: "Case unsolved, perpetrators free"
                )
            ]
        }
    }
    
    private func generateCaseReview() {
        caseReviewData = CaseReviewData(
            totalScore: gameState.caseScore,
            evidenceCollected: gameState.totalEvidenceFound,
            realEvidenceFound: gameState.realEvidenceCount,
            correctConnections: gameState.correctConnectionsCount,
            suspectCooperation: gameState.suspectCooperationLevel,
            analysesPerformed: gameState.analysisResults.count,
            actsCompleted: gameState.currentAct.rawValue
        )
    }
    
    func makeChoice(_ choice: FinalChoice) {
        selectedChoice = choice
        finalOutcome = determineOutcome(choice.outcome)
        outcomeRevealed = true
        gameState.completeGame()
    }
    
    private func determineOutcome(_ choiceOutcome: ChoiceOutcome) -> GameOutcome {
        // Using only title, description, and endingType per shared model
        switch choiceOutcome {
        case .arrest:
            return GameOutcome(
                title: "Justice Served",
                description: "Dr. Chen is arrested and charged with assault and conspiracy. Your thorough investigation provided the evidence needed for a conviction. The organ trafficking ring is exposed, though some members escape.",
                endingType: .success
            )
            
        case .cooperation:
            return GameOutcome(
                title: "Network Exposed",
                description: "Working with Dr. Chen, you successfully expose the entire organ trafficking network. Five conspirators are arrested, including the ring leader. Dr. Chen's cooperation proves invaluable.",
                endingType: .success
            )
            
        case .weakArrest:
            return GameOutcome(
                title: "Pyrrhic Victory",
                description: "Dr. Chen is arrested, but the case falls apart in court due to insufficient evidence. She's released after six months, and the real perpetrators remain free.",
                endingType: .partialSuccess
            )
            
        case .continueInvestigation:
            return GameOutcome(
                title: "Case Pending",
                description: "You request more time to investigate, but the suspects disappear overnight. The trail goes cold, and the case remains officially open but inactive.",
                endingType: .neutral
            )
            
        case .closedCase:
            return GameOutcome(
                title: "Unsolved Mystery",
                description: "Without sufficient evidence, the case is closed. The victim's attack remains unsolved, and the organ trafficking continues in the shadows.",
                endingType: .failure
            )
        }
    }
}

// MARK: - Act 7: Final Choice View
struct Act7FinalChoiceView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act7ViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: Act7ViewModel(gameState: GameState()))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !viewModel.outcomeRevealed {
                // Decision phase
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Text("⚖️ **Final Decision**")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose how to conclude the case")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Case summary
                    if let reviewData = viewModel.caseReviewData {
                        CaseSummaryView(reviewData: reviewData)
                    }
                    
                    Divider()
                    
                    // Choice options
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.finalChoices.enumerated()), id: \.element.title) { index, choice in
                            FinalChoiceCardView(
                                choice: choice,
                                index: index,
                                onSelect: {
                                    viewModel.makeChoice(choice)
                                }
                            )
                        }
                    }
                }
            } else {
                // Outcome phase
                OutcomeRevealView(
                    outcome: viewModel.finalOutcome,
                    reviewData: viewModel.caseReviewData,
                    choice: viewModel.selectedChoice
                )
            }
        }
        .padding()
        .frame(maxWidth: 800)
        .onAppear {
            viewModel.gameState = gameState
        }
    }
}

struct CaseSummaryView: View {
    let reviewData: CaseReviewData
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Investigation Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    StatRow(label: "Total Score", value: "\(reviewData.totalScore)/100")
                    StatRow(label: "Grade", value: reviewData.grade)
                    StatRow(label: "Evidence Found", value: "\(reviewData.realEvidenceFound)/\(reviewData.evidenceCollected)")
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    StatRow(label: "Connections", value: "\(reviewData.correctConnections)")
                    StatRow(label: "Cooperation", value: "\(reviewData.suspectCooperation)/10")
                    StatRow(label: "Analyses", value: "\(reviewData.analysesPerformed)")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct FinalChoiceCardView: View {
    let choice: FinalChoice
    let index: Int
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Option \(index + 1)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                Text(choice.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                Text(choice.description)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(choice.requirements)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(choice.consequences)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}

struct OutcomeRevealView: View {
    let outcome: GameOutcome?
    let reviewData: CaseReviewData?
    let choice: FinalChoice?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let outcome = outcome {
                    // Outcome header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: outcomeIcon)
                                .font(.largeTitle)
                                .foregroundColor(outcomeColor)
                            
                            Text(outcome.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Text(outcome.description)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                    
                    Divider()
                    
                    // Your choice
                    if let choice = choice {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Decision:")
                                .font(.headline)
                            
                            Text(choice.title)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Performance review
                    if let reviewData = reviewData {
                        PerformanceReviewView(reviewData: reviewData)
                    }
                    
                    // Epilogue text removed since not present in shared model
                    
                    // Game completion
                    VStack(spacing: 16) {
                        Text("🎉 Case Closed 🎉")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Button("Play Again") {
                            // Reset game state
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.top, 20)
                }
            }
            .padding()
        }
    }
    
    private var outcomeIcon: String {
        guard let outcome = outcome else { return "questionmark.circle" }
        
        switch outcome.endingType {
        case .success: return "checkmark.circle.fill"
        case .partialSuccess: return "checkmark.circle"
        case .neutral: return "questionmark.circle"
        case .failure: return "xmark.circle.fill"
        }
    }
    
    private var outcomeColor: Color {
        guard let outcome = outcome else { return .gray }
        
        switch outcome.endingType {
        case .success: return .green
        case .partialSuccess: return .orange
        case .neutral: return .blue
        case .failure: return .red
        }
    }
}

struct PerformanceReviewView: View {
    let reviewData: CaseReviewData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Investigation Performance")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                PerformanceMetricView(
                    title: "Evidence Collection",
                    value: reviewData.realEvidenceFound,
                    total: reviewData.evidenceCollected,
                    icon: "magnifyingglass"
                )
                
                PerformanceMetricView(
                    title: "Connections Made",
                    value: reviewData.correctConnections,
                    total: 5,
                    icon: "link"
                )
                
                PerformanceMetricView(
                    title: "Suspect Cooperation",
                    value: reviewData.suspectCooperation,
                    total: 10,
                    icon: "person.2"
                )
                
                PerformanceMetricView(
                    title: "Lab Analyses",
                    value: reviewData.analysesPerformed,
                    total: 6,
                    icon: "flask"
                )
            }
            
            HStack {
                Text("Final Grade:")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(reviewData.grade)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(gradeColor)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var gradeColor: Color {
        switch reviewData.grade {
        case "A+", "A": return .green
        case "B": return .blue
        case "C": return .orange
        default: return .red
        }
    }
}

struct PerformanceMetricView: View {
    let title: String
    let value: Int
    let total: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            Text("\(value)/\(total)")
                .font(.headline)
                .fontWeight(.bold)
            
            ProgressView(value: Double(value), total: Double(total))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var progressColor: Color {
        let percentage = Double(value) / Double(total)
        switch percentage {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// TODO: Expand this view with:
// - Multiple suspects to confront
// - Evidence presentation animations
// - Psychological pressure mechanics
// - Lie detection mini-game
// - Multiple conversation branches
// - Witness testimony integration
// - Legal advisor consultation
// - Recording and playback of confrontations
// - Multiple ending cinematics
// - Achievement system
// - Leaderboard for score comparison
// - Case file export functionality
// - New Game+ mode with harder evidence
// - Alternative storylines based on choices
// - Statistics tracking across multiple playthroughs

#Preview {
    Act6ConfrontationView()
        .environmentObject(GameState())
    
    Act7FinalChoiceView()
        .environmentObject(GameState())
}
