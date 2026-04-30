import SwiftUI

// MARK: - Act 4: Wrapper View
struct Act4ConfrontationView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var phase: Act4Phase = .receptionistConfrontation

    var body: some View {
        switch phase {
        case .receptionistConfrontation:
            ReceptionistConfrontationView(onComplete: {
                withAnimation { phase = .kathyFinal }
            })
            .environmentObject(gameState)
        case .kathyFinal:
            KathyFinalView(onComplete: {
                withAnimation { phase = .surgeonConfrontation }
            })
            .environmentObject(gameState)
        case .surgeonConfrontation:
            SurgeonConfrontationView(onComplete: {
                withAnimation { phase = .finalChoice }
            })
            .environmentObject(gameState)
        case .finalChoice:
            FinalChoiceView()
                .environmentObject(gameState)
        }
    }
}

enum Act4Phase {
    case receptionistConfrontation, kathyFinal, surgeonConfrontation, finalChoice
}

// MARK: - Receptionist Confrontation
struct ReceptionistConfrontationView: View {
    @EnvironmentObject private var gameState: GameState
    let onComplete: () -> Void

    @State private var conversationHistory: [ConversationEntry] = []
    @State private var currentQuestions: [ConfrontationQuestion] = []
    @State private var questionPhase = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image("prisonReceptionist")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text("Hilarie Jones, Second Interrogation")
                        .font(.headline)
                    Text("Confronting the Time Log entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))

            // Conversation
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversationHistory) { entry in
                            ConversationBubbleView(
                                entry: entry,
                                playerImage: gameState.selectedDetective,
                                suspectImage: "prisonReceptionist",
                                suspectName: "Hilarie Jones",
                                playerName: gameState.playerName.isEmpty ? "You" : gameState.playerName
                            )
                            .id(entry.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: conversationHistory.count) { _ in
                    if let last = conversationHistory.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Question choices
            VStack(spacing: 8) {
                if currentQuestions.isEmpty && questionPhase >= receptionistPhases.count {
                    Button("Proceed to Kathy Williams") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    ForEach(currentQuestions) { question in
                        Button {
                            askQuestion(question)
                        } label: {
                            Text(question.questionText)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            loadPhase()
        }
    }

    private func askQuestion(_ question: ConfrontationQuestion) {
        conversationHistory.append(ConversationEntry(speaker: .investigator, text: question.questionText))
        conversationHistory.append(ConversationEntry(speaker: .suspect, text: question.responseText))
        currentQuestions.removeAll()

        questionPhase += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadPhase()
        }
    }

    private func loadPhase() {
        guard questionPhase < receptionistPhases.count else {
            currentQuestions = []
            return
        }
        currentQuestions = receptionistPhases[questionPhase]
    }

    private var receptionistPhases: [[ConfrontationQuestion]] {
        [
            // Phase 0: Opening with Time Log
            [
                ConfrontationQuestion(
                    questionText: "I've looked at the time log you gave me. Your name appears at 2:14 AM. Unauthorized.",
                    responseText: "...I know what it says."
                )
            ],
            // Phase 1: Why
            [
                ConfrontationQuestion(
                    questionText: "Why were you in Wayne's room at 2:14 AM?",
                    responseText: "Something felt wrong that night. I was trying to find the on-call surgeon. I went to check on the patient myself."
                )
            ],
            // Phase 2: What she saw
            [
                ConfrontationQuestion(
                    questionText: "What did you see when you entered the room?",
                    responseText: "...Dr. Smith was already in there. He was standing by the IV line. He looked startled when I walked in."
                )
            ],
            // Phase 3: The syringe
            [
                ConfrontationQuestion(
                    questionText: "Did you see anything else?",
                    responseText: "He dropped something near the bed when he turned around... it looked like a syringe cap. He left quickly after that."
                )
            ],
            // Phase 4: Why she didn't report
            [
                ConfrontationQuestion(
                    questionText: "Why didn't you report what you saw?",
                    responseText: "He's a surgeon. I'm a receptionist. Who would believe me over him? I was scared. I just... left and tried to forget about it."
                )
            ],
            // Phase 5: Pressing
            [
                ConfrontationQuestion(
                    questionText: "A man is dead. You could have stopped it.",
                    responseText: "...I know. I think about that every day."
                )
            ]
        ]
    }
}

// MARK: - Kathy Final Interrogation
struct KathyFinalView: View {
    @EnvironmentObject private var gameState: GameState
    let onComplete: () -> Void

    @State private var dialogueIndex = 0
    @State private var conversationHistory: [ConversationEntry] = []

    private let dialogue: [(ConversationEntry.Speaker, String)] = [
        (.investigator, "You knew him. Why didn't you say that?"),
        (.suspect, "...It didn't matter."),
        (.investigator, "You went there for him. Not protocol. Him."),
        (.suspect, "...Yes."),
        (.investigator, "When you found him, was he already dead?"),
        (.suspect, "...No."),
        (.investigator, "Then why didn't you call emergency response?"),
        (.suspect, "...I thought he was over sedated."),
        (.investigator, "And you still called the surgeon?"),
        (.suspect, "...He told me not to escalate."),
        (.investigator, "You knew something was wrong."),
        (.suspect, "...I wasn't sure."),
        (.investigator, "You didn't want to be sure."),
        (.suspect, "...If I was wrong, I lose everything...\nand if I was right...")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image("prisonNurse")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text("Kathy Williams, Final Interrogation")
                        .font(.headline)
                    Text("Triggered by Love Letter and vital evidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))

            // Conversation
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversationHistory) { entry in
                            ConversationBubbleView(
                                entry: entry,
                                playerImage: gameState.selectedDetective,
                                suspectImage: "prisonNurse",
                                suspectName: "Kathy Williams",
                                playerName: gameState.playerName.isEmpty ? "You" : gameState.playerName
                            )
                            .id(entry.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: conversationHistory.count) { _ in
                    if let last = conversationHistory.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Advance button
            HStack {
                Spacer()
                if dialogueIndex < dialogue.count {
                    Button("Continue") {
                        advanceDialogue()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Proceed to Dr. Victor Smith") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            advanceDialogue()
        }
    }

    private func advanceDialogue() {
        guard dialogueIndex < dialogue.count else { return }
        let (speaker, text) = dialogue[dialogueIndex]
        conversationHistory.append(ConversationEntry(speaker: speaker, text: text))
        dialogueIndex += 1
    }
}

// MARK: - Surgeon Confrontation
struct SurgeonConfrontationView: View {
    @EnvironmentObject private var gameState: GameState
    let onComplete: () -> Void

    @State private var conversationHistory: [ConversationEntry] = []
    @State private var currentQuestions: [ConfrontationQuestion] = []
    @State private var questionPhase = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image("prisonSurgeon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text("Dr. Victor Smith, Confrontation")
                        .font(.headline)
                    Text("The truth comes out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))

            // Conversation
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversationHistory) { entry in
                            ConversationBubbleView(
                                entry: entry,
                                playerImage: gameState.selectedDetective,
                                suspectImage: "prisonSurgeon",
                                suspectName: "Dr. Victor Smith",
                                playerName: gameState.playerName.isEmpty ? "You" : gameState.playerName
                            )
                            .id(entry.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: conversationHistory.count) { _ in
                    if let last = conversationHistory.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Question choices
            VStack(spacing: 8) {
                if currentQuestions.isEmpty && questionPhase >= surgeonPhases.count {
                    Button("Make Your Final Decision") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    ForEach(currentQuestions) { question in
                        Button {
                            askSurgeonQuestion(question)
                        } label: {
                            Text(question.questionText)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            loadPhase()
        }
    }

    private func askSurgeonQuestion(_ question: ConfrontationQuestion) {
        conversationHistory.append(ConversationEntry(speaker: .investigator, text: question.questionText))
        conversationHistory.append(ConversationEntry(speaker: .suspect, text: question.responseText))
        currentQuestions.removeAll()

        questionPhase += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadPhase()
        }
    }

    private func loadPhase() {
        guard questionPhase < surgeonPhases.count else {
            currentQuestions = []
            return
        }
        currentQuestions = surgeonPhases[questionPhase]
    }

    private var surgeonPhases: [[ConfrontationQuestion]] {
        [
            // Phase 0: Opening
            [
                ConfrontationQuestion(
                    questionText: "You declared him dead.",
                    responseText: "Yes."
                )
            ],
            // Phase 1: Time Log confrontation
            [
                ConfrontationQuestion(
                    questionText: "The time log shows you entered Wayne's room at 2:00 AM. Unauthorized.",
                    responseText: "I check on patients before procedures. It's not unusual."
                )
            ],
            // Phase 2: Witness account
            [
                ConfrontationQuestion(
                    questionText: "A witness saw you at his IV line. You dropped a syringe cap.",
                    responseText: "...That's someone's word against mine."
                )
            ],
            // Phase 3: Evidence
            [
                ConfrontationQuestion(
                    questionText: "We found the syringe. Sedative levels far beyond what's normal.",
                    responseText: "I approved the sedation protocol. Every patient is different."
                ),
                ConfrontationQuestion(
                    questionText: "His vitals were still active at 3:00 AM. He was alive when the nurse found him.",
                    responseText: "You're misreading medical data."
                )
            ],
            // Phase 4: Contradiction
            [
                ConfrontationQuestion(
                    questionText: "His license says he was not an organ donor.",
                    responseText: "I'm aware."
                )
            ],
            // Phase 5: Pressing
            [
                ConfrontationQuestion(
                    questionText: "Then why does his intake form show a doctored license saying he was?",
                    responseText: "Because by the time he reached my table, he was."
                )
            ],
            // Phase 6: Accusation
            [
                ConfrontationQuestion(
                    questionText: "You changed it.",
                    responseText: "I corrected it."
                )
            ],
            // Phase 7: Moral conflict
            [
                ConfrontationQuestion(
                    questionText: "That's not your decision to make.",
                    responseText: "Then whose is it?"
                )
            ],
            // Phase 8
            [
                ConfrontationQuestion(
                    questionText: "The law's.",
                    responseText: "The law already made its decision."
                )
            ],
            // Phase 9
            [
                ConfrontationQuestion(
                    questionText: "What decision?",
                    responseText: "That his life was over."
                )
            ],
            // Phase 10
            [
                ConfrontationQuestion(
                    questionText: "He was serving a sentence. That doesn't make him expendable.",
                    responseText: "He was never leaving that place."
                )
            ],
            // Phase 11
            [
                ConfrontationQuestion(
                    questionText: "So you decided how he would die.",
                    responseText: "No. I decided his death would matter."
                )
            ],
            // Phase 12: Final push
            [
                ConfrontationQuestion(
                    questionText: "He wasn't even proven guilty beyond doubt.",
                    responseText: "That doesn't change the outcome."
                )
            ],
            // Phase 13
            [
                ConfrontationQuestion(
                    questionText: "You killed him.",
                    responseText: "I saved five."
                )
            ],
            // Phase 14: Final
            [
                ConfrontationQuestion(
                    questionText: "That wasn't your choice.",
                    responseText: "It became mine when no one else acted."
                )
            ]
        ]
    }
}

struct ConfrontationQuestion: Identifiable {
    let id = UUID()
    let questionText: String
    let responseText: String
}

// MARK: - Final Choice
struct FinalChoiceView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var selectedChoice: FinalPlayerChoice?
    @State private var showOutcome = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !showOutcome {
                VStack(spacing: 40) {
                    Text("WHAT DO YOU DO?")
                        .font(.custom("Times New Roman", size: 36))
                        .foregroundColor(.white)
                        .tracking(4)

                    HStack(spacing: 40) {
                        // Expose
                        Button {
                            selectedChoice = .expose
                            withAnimation(.easeIn(duration: 1.0)) {
                                showOutcome = true
                            }
                            gameState.completeGame()
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("EXPOSE THE SURGEON")
                                    .font(.custom("Times New Roman", size: 18))
                                    .foregroundColor(.white)
                                    .tracking(2)
                                Text("Justice for Wayne.\nThe truth comes out.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(30)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Protect
                        Button {
                            selectedChoice = .protect
                            withAnimation(.easeIn(duration: 1.0)) {
                                showOutcome = true
                            }
                            gameState.completeGame()
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("PROTECT THE SURGEON")
                                    .font(.custom("Times New Roman", size: 18))
                                    .foregroundColor(.white)
                                    .tracking(2)
                                Text("More lives saved.\nThe system continues.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(30)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Outcome
                VStack(spacing: 24) {
                    if selectedChoice == .expose {
                        Text("JUSTICE")
                            .font(.custom("Times New Roman", size: 48))
                            .foregroundColor(.white)
                            .tracking(8)

                        Text("Dr. Victor Smith is arrested.\nThe organ harvesting operation is exposed.\nKathy Williams testifies.\n\nWayne Michaels receives a proper investigation.\nThe truth is on the record.\n\nBut five patients on the transplant list\nwill not receive their organs.")
                            .font(.custom("Times New Roman", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                    } else {
                        Text("SILENCE")
                            .font(.custom("Times New Roman", size: 48))
                            .foregroundColor(.white)
                            .tracking(8)

                        Text("You walk away.\nThe report reads: heart attack.\n\nDr. Smith continues his work.\nMore prisoners are selected.\nMore lives are saved.\n\nWayne Michaels is buried\nwith a donor status he never chose.")
                            .font(.custom("Times New Roman", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                    }

                    Text("CASE CLOSED")
                        .font(.custom("Times New Roman", size: 24))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(6)
                        .padding(.top, 30)
                }
                .transition(.opacity)
            }
        }
    }
}

enum FinalPlayerChoice {
    case expose, protect
}

#Preview {
    Act4ConfrontationView()
        .environmentObject(GameState())
}
