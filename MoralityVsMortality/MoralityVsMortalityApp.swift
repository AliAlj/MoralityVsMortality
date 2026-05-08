import SwiftUI

@main
struct MoralityVsMortalityApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var audioManager = AudioManager.shared
    @State private var currentScreen: AppScreen = .start
    @State private var showingAudioSettings = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()

                switch currentScreen {
                case .start:
                    StartScreenView(screen: $currentScreen)
                        .environmentObject(gameState)
                case .intro:
                    IntroScreenView(screen: $currentScreen)
                        .environmentObject(gameState)
                case .characterSelect:
                    CharacterSelectView(screen: $currentScreen)
                        .environmentObject(gameState)
                case .game:
                    ContentView()
                        .environmentObject(gameState)
                }

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingAudioSettings = true
                            }
                        } label: {
                            Image("settingsIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                    }

                    Spacer()
                }

                if showingAudioSettings {
                    AudioSettingsOverlay(isPresented: $showingAudioSettings)
                        .environmentObject(audioManager)
                        .transition(.opacity)
                }
            }
            .onAppear {
                AudioManager.shared.playBackgroundMusic()
            }
        }
        .onChange(of: gameState.shouldReturnToStart) { _, shouldReturn in
            if shouldReturn {
                gameState.shouldReturnToStart = false
                currentScreen = .start
            }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif
    }
}
private struct AudioSettingsOverlay: View {
    @EnvironmentObject private var audioManager: AudioManager
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Audio Settings")
                        .font(.custom("Times New Roman", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }

                AudioSliderRow(
                    title: "Music",
                    value: Binding(
                        get: { Double(audioManager.musicVolume) },
                        set: { audioManager.musicVolume = Float($0) }
                    )
                )

                AudioSliderRow(
                    title: "Sound Effects",
                    value: Binding(
                        get: { Double(audioManager.soundEffectsVolume) },
                        set: { audioManager.soundEffectsVolume = Float($0) }
                    )
                )
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
            .padding(24)
        }
    }
}

private struct AudioSliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Slider(value: $value, in: 0...1)
                .tint(.white)
        }
    }
}

