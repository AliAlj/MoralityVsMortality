import AVFoundation
import Combine

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var musicVolume: Float {
        didSet {
            let clampedVolume = max(0, min(musicVolume, 1))
            if clampedVolume != musicVolume {
                musicVolume = clampedVolume
                return
            }

            UserDefaults.standard.set(musicVolume, forKey: Self.musicVolumeKey)
            applyMusicVolume()
        }
    }

    @Published var soundEffectsVolume: Float {
        didSet {
            let clampedVolume = max(0, min(soundEffectsVolume, 1))
            if clampedVolume != soundEffectsVolume {
                soundEffectsVolume = clampedVolume
                return
            }

            UserDefaults.standard.set(soundEffectsVolume, forKey: Self.soundEffectsVolumeKey)
            applySoundEffectsVolume()
        }
    }
    
    private func configureAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS)
        do {
            // Use .playback to ensure audio is audible even if the device is muted.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
        #else
        // AVAudioSession is unavailable on macOS; no configuration needed.
        #endif
    }

    private var backgroundPlayer: AVAudioPlayer?
    private var typewriterPlayer: AVAudioPlayer?
    private var screamPlayer: AVAudioPlayer?
    private var detectiveRoomPlayer: AVAudioPlayer?

    private static let musicVolumeKey = "musicVolume"
    private static let soundEffectsVolumeKey = "soundEffectsVolume"
    private let backgroundBaseVolume: Float = 0.35
    private let typewriterBaseVolume: Float = 0.6
    private let screamBaseVolume: Float = 0.8
    private let detectiveRoomBaseVolume: Float = 0.45

    private init() {
        let defaults = UserDefaults.standard
        let storedMusicVolume = defaults.object(forKey: Self.musicVolumeKey) as? Float
        let storedEffectsVolume = defaults.object(forKey: Self.soundEffectsVolumeKey) as? Float
        musicVolume = storedMusicVolume ?? 1.0
        soundEffectsVolume = storedEffectsVolume ?? 1.0
        configureAudioSession()
    }

    func playBackgroundMusic() {
        guard backgroundPlayer == nil else { return }

        guard let url = Bundle.main.url(forResource: "background", withExtension: "mp3") else {
            print("background.mp3 not found")
            return
        }

        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1
            applyMusicVolume()
            backgroundPlayer?.prepareToPlay()
            backgroundPlayer?.play()
        } catch {
            print("Background music error: \(error)")
        }
    }

    func playTypewriter() {
        guard typewriterPlayer == nil else { return }

        guard let url = Bundle.main.url(forResource: "typewriterTrim", withExtension: "mp3") else {
            print("typewriterTrim.mov not found")
            return
        }

        do {
            #if os(iOS) || os(tvOS) || os(watchOS)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            typewriterPlayer = try AVAudioPlayer(contentsOf: url)
            typewriterPlayer?.numberOfLoops = -1
            typewriterPlayer?.volume = typewriterBaseVolume * soundEffectsVolume
            typewriterPlayer?.prepareToPlay()
            typewriterPlayer?.play()
        } catch {
            print("Typewriter sound error: \(error)")
        }
    }

    func stopTypewriter() {
        typewriterPlayer?.stop()
        typewriterPlayer = nil
    }
    func playScreamOnce() {
        guard let url = Bundle.main.url(forResource: "scream", withExtension: "mp3") else {
            print("scream.mp3 not found")
            return
        }

        do {
            #if os(iOS) || os(tvOS) || os(watchOS)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            screamPlayer = try AVAudioPlayer(contentsOf: url)
            screamPlayer?.numberOfLoops = 0
            screamPlayer?.volume = screamBaseVolume * soundEffectsVolume
            screamPlayer?.prepareToPlay()
            screamPlayer?.play()
        } catch {
            print("Scream sound error: \(error)")
        }
    }
    
    func playDetectiveRoomSound() {
        guard detectiveRoomPlayer == nil else { return }

        guard let url = Bundle.main.url(forResource: "airconditioner", withExtension: "mp3") else {
            print("airconditioner.mov not found")
            return
        }

        do {
            #if os(iOS) || os(tvOS) || os(watchOS)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            detectiveRoomPlayer = try AVAudioPlayer(contentsOf: url)
            detectiveRoomPlayer?.numberOfLoops = -1
            detectiveRoomPlayer?.volume = detectiveRoomBaseVolume * soundEffectsVolume
            detectiveRoomPlayer?.prepareToPlay()
            detectiveRoomPlayer?.play()
        } catch {
            print("Detective room sound error: \(error)")
        }
    }

    func stopDetectiveRoomSound() {
        detectiveRoomPlayer?.stop()
        detectiveRoomPlayer = nil
    }

    private func applyMusicVolume() {
        backgroundPlayer?.volume = backgroundBaseVolume * musicVolume
    }

    private func applySoundEffectsVolume() {
        typewriterPlayer?.volume = typewriterBaseVolume * soundEffectsVolume
        screamPlayer?.volume = screamBaseVolume * soundEffectsVolume
        detectiveRoomPlayer?.volume = detectiveRoomBaseVolume * soundEffectsVolume
        print("Sound effects volume applied. Effective typewriter: \(typewriterBaseVolume * soundEffectsVolume), scream: \(screamBaseVolume * soundEffectsVolume), detective: \(detectiveRoomBaseVolume * soundEffectsVolume)")
    }
}
