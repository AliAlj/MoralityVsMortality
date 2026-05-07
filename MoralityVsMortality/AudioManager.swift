//
//  AudioManager.swift
//  MoralityVsMortality
//
//  Created by Anna Algobay on 5/4/26.
//

import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private var backgroundPlayer: AVAudioPlayer?
    private var typewriterPlayer: AVAudioPlayer?
    private var screamPlayer: AVAudioPlayer?
    private var detectiveRoomPlayer: AVAudioPlayer?

    private init() {}

    func playBackgroundMusic() {
        guard backgroundPlayer == nil else { return }

        guard let url = Bundle.main.url(forResource: "background", withExtension: "mp3") else {
            print("background.mp3 not found")
            return
        }

        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1
            backgroundPlayer?.volume = 0.35
            backgroundPlayer?.prepareToPlay()
            backgroundPlayer?.play()
        } catch {
            print("Background music error: \(error)")
        }
    }

    func playTypewriter() {
        guard typewriterPlayer == nil else { return }

        guard let url = Bundle.main.url(forResource: "typewriterTrim", withExtension: "mov") else {
            print("typewriterTrim.mov not found")
            return
        }

        do {
            typewriterPlayer = try AVAudioPlayer(contentsOf: url)
            typewriterPlayer?.numberOfLoops = -1
            typewriterPlayer?.volume = 0.6
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
            screamPlayer = try AVAudioPlayer(contentsOf: url)
            screamPlayer?.numberOfLoops = 0
            screamPlayer?.volume = 0.8
            screamPlayer?.prepareToPlay()
            screamPlayer?.play()
        } catch {
            print("Scream sound error: \(error)")
        }
    }
    
    func playDetectiveRoomSound() {
        guard detectiveRoomPlayer == nil else { return }

        guard let url = Bundle.main.url(forResource: "airconditioner", withExtension: "mov") else {
            print("airconditioner.mov not found")
            return
        }

        do {
            detectiveRoomPlayer = try AVAudioPlayer(contentsOf: url)
            detectiveRoomPlayer?.numberOfLoops = -1
            detectiveRoomPlayer?.volume = 0.45
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
}
