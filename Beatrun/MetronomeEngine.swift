import AVFoundation
import Darwin
import Foundation
import Observation

@MainActor
@Observable
final class MetronomeEngine {
    var cadence: Int = 180 {
        didSet {
            guard cadence != oldValue, isRunning else { return }
            restartTimer()
        }
    }

    private(set) var isRunning = false
    private(set) var beatCount = 0
    private(set) var lastBeatDate: Date?
    private(set) var audioStatus = "Ready"
    private(set) var audioError: String?
    private(set) var volume = 0.75

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private let playerNode = AVAudioPlayerNode()
    @ObservationIgnored private var clickBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var isAudioConfigured = false

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }
        do {
            try prepareAudioIfNeeded()
            isRunning = true
            beatCount = 0
            audioError = nil
            audioStatus = "Playing"
            playClick()
            restartTimer()
        } catch {
            audioError = error.localizedDescription
            audioStatus = "Audio unavailable"
            stop()
        }
    }

    func stop() {
        isRunning = false
        audioStatus = audioError == nil ? "Ready" : "Audio unavailable"
        timer?.invalidate()
        timer = nil
        playerNode.stop()
    }

    func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0), 1)
        playerNode.volume = Float(volume)
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = 60.0 / Double(cadence)
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playClick()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func playClick() {
        beatCount += 1
        lastBeatDate = Date()

        guard let clickBuffer else { return }
        playerNode.scheduleBuffer(clickBuffer, at: nil, options: .interrupts, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func prepareAudioIfNeeded() throws {
        guard !isAudioConfigured else {
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        clickBuffer = Self.makeClickBuffer(format: format)

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        playerNode.volume = Float(volume)

        try audioEngine.start()
        isAudioConfigured = true
    }

    private static func makeClickBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer {
        let duration = 0.045
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let frequency = 1_650.0
        let attackFrames = max(1, Int(0.003 * sampleRate))
        let frames = Int(frameCount)
        let channel = buffer.floatChannelData![0]

        for frame in 0..<frames {
            let progress = Double(frame) / Double(frames)
            let attack = min(1.0, Double(frame) / Double(attackFrames))
            let decay = pow(1.0 - progress, 6.0)
            let envelope = attack * decay
            let sample = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
            channel[frame] = Float(sample * envelope * 0.85)
        }

        return buffer
    }
}
