import SwiftUI

// MARK: - Start Screen
struct StartScreenView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @Binding var screen: AppScreen

    var body: some View {
        ZStack {
            Image("startScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()

                Button {
                    screen = .intro
                } label: {
                    Image(hasSeenIntro ? "continueButton" : "startButton")
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
        "As a private investigator, your job is to investigate Wayne's death. Wayne is a patient in the prison hospital, he was convicted 5 years ago for attempted murder. He was scheduled for a very simple surgery with Dr. Viktor Kazimir, the head surgeon in the hospital.\n\nBut just hours before his surgery Wayne was found unconscious by his nurse Kathy. He was pronounced dead by the doctor, the cause being a heart attack.\n\nYou were hired as a private investigator by Wayne's best friend to find out Wayne's cause of death.",

        "2:00 AM Tuesday October 5th.....\n\nWayne is found dead.",

        "Wayne is a patient in the prison hospital, he was convicted 5 years ago for attempted murder. He got into a violent gang fight and was admitted into the prison hospital 1 week ago. He was scheduled for a very simple surgery with Dr. Viktor Kazimir, the head surgeon in the hospital. But just hours before his surgery Wayne was found unconscious by his nurse Kathy.\n\nHe was later pronounced dead by Dr. Kazimir, the cause being a heart attack."
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
            screen = .game
        }
    }
}

// MARK: - App Screen Enum
enum AppScreen {
    case start
    case intro
    case game
}
