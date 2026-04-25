import SwiftUI

// MARK: - Start Screen
struct StartScreenView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("playerName") private var savedName = ""
    @Binding var screen: AppScreen

    private var hasCompletedSetup: Bool {
        hasSeenIntro && !savedName.isEmpty
    }

    var body: some View {
        ZStack {
            Image("startScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()

                Button {
                    if hasCompletedSetup {
                        screen = .game
                    } else {
                        screen = .intro
                    }
                } label: {
                    Image(hasCompletedSetup ? "continueButton" : "startButton")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }
}

// MARK: - Intro Screen
struct IntroScreenView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @Binding var screen: AppScreen

    @State private var currentPage = 0
    @State private var displayedText = ""
    @State private var isTyping = false
    @State private var showContinue = false
    @State private var typingTask: Task<Void, Never>?

    private let pages: [String] = [
        "2:00 AM — Tuesday, October 5th\n\nA sharp gasp cuts through the hospital corridor.\n\nWayne Michaels is found unresponsive.\n\nMinutes later, he is pronounced dead.",

        "Wayne was a prison inmate serving a life sentence for attempted murder.\n\nOne week ago, he was transferred to the prison hospital following a violent altercation.\n\nHis condition was stable.\nHe was scheduled for a routine surgical procedure in the morning.",

        "The attending surgeon: Dr. Viktor Kazimir\nThe nurse on duty: Kathy Alvarez\n\nAccording to the official report,\nWayne suffered a sudden heart attack.\n\nCase closed.",

        "But something doesn't add up.\n\nYou've been hired  to find out what really happened."
    ]

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Image("storyBackground")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 750, maxHeight: 550)

            VStack(spacing: 0) {
                Text("YOU'RE HIRED")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .tracking(4)
                    .padding(.top, 60)

                Spacer()

                Text(displayedText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 60)
                    .frame(maxWidth: 800)

                Spacer()

                if showContinue {
                    Button {
                        advancePage()
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Begin Investigation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                    .padding(.bottom, 60)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isTyping {
                    skipTyping()
                }
            }
        }
        .onAppear {
            startTyping()
        }
        .onDisappear {
            typingTask?.cancel()
        }
    }

    private func startTyping() {
        let text = pages[currentPage]
        displayedText = ""
        isTyping = true
        showContinue = false

        typingTask?.cancel()
        typingTask = Task {
            for character in text {
                guard !Task.isCancelled else { return }
                displayedText.append(character)
                let delay: UInt64 = character == "\n" ? 80_000_000 : 30_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            isTyping = false
            withAnimation(.easeIn(duration: 0.5)) {
                showContinue = true
            }
        }
    }

    private func skipTyping() {
        typingTask?.cancel()
        displayedText = pages[currentPage]
        isTyping = false
        withAnimation(.easeIn(duration: 0.5)) {
            showContinue = true
        }
    }

    private func advancePage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            startTyping()
        } else {
            hasSeenIntro = true
            screen = .characterSelect
        }
    }
}

// MARK: - Character Selection Screen
struct CharacterSelectView: View {
    @EnvironmentObject var gameState: GameState
    @Binding var screen: AppScreen
    @State private var selectedDetective: String? = nil
    @State private var playerName = ""
    @State private var showNameField = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("CHOOSE YOUR DETECTIVE")
                    .font(.custom("Times New Roman", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(4)
                    .padding(.top, 40)

                HStack(spacing: 60) {
                    detectiveOption("detectiveOne")
                    detectiveOption("detectiveTwo")
                }

                if showNameField {
                    VStack(spacing: 16) {
                        Text("ENTER YOUR NAME")
                            .font(.custom("Times New Roman", size: 20))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(2)

                        TextField("", text: $playerName)
                            .textFieldStyle(.plain)
                            .font(.custom("Times New Roman", size: 24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(width: 300)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )

                        if !playerName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                let name = playerName.trimmingCharacters(in: .whitespaces)
                                let detective = selectedDetective ?? "detectiveOne"
                                gameState.playerName = name
                                gameState.selectedDetective = detective
                                UserDefaults.standard.set(name, forKey: "playerName")
                                UserDefaults.standard.set(detective, forKey: "selectedDetective")
                                screen = .game
                            } label: {
                                Text("BEGIN")
                                    .font(.custom("Times New Roman", size: 22))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .tracking(4)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
        }
    }

    private func detectiveOption(_ name: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDetective = name
                showNameField = true
            }
        } label: {
            VStack {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedDetective == name ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: selectedDetective == name ? .white.opacity(0.4) : .clear, radius: 10)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Screen Enum
enum AppScreen {
    case start
    case intro
    case characterSelect
    case game
}
