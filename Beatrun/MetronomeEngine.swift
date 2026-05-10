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
            beginSyncedClickLoop()
        }
    }

    private(set) var isRunning = false
    private(set) var beatCount = 0
    private(set) var lastBeatDate: Date?
    private(set) var audioStatus = "Ready"
    private(set) var audioError: String?
    private(set) var volume = 0.75
    private(set) var musicStatus = "Generated loop ready"
    private(set) var musicVolume = 0.45
    private(set) var selectedTrackTitle = "No track"
    private(set) var syncStatus = "Ready to sync"
    private(set) var syncOffsetMilliseconds = 0
    private(set) var syncMode = "Direct"

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var syncStartTask: Task<Void, Never>?
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private let clickNode = AVAudioPlayerNode()
    @ObservationIgnored private let backingNode = AVAudioPlayerNode()
    @ObservationIgnored private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    @ObservationIgnored private var clickBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var backingBuffer: AVAudioPCMBuffer?
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
            audioStatus = "Syncing"
            musicStatus = backingBuffer == nil ? "No backing loop" : "Backing loop playing"
            syncStatus = syncOffsetMilliseconds == 0 ? "Locked on start" : "Waiting \(syncOffsetMilliseconds) ms for beat alignment"
            startBackingLoop()
            beginSyncedClickLoop()
        } catch {
            audioError = error.localizedDescription
            audioStatus = "Audio unavailable"
            stop()
        }
    }

    func stop() {
        isRunning = false
        audioStatus = audioError == nil ? "Ready" : "Audio unavailable"
        musicStatus = backingBuffer == nil ? "No backing loop" : "Generated loop ready"
        syncStatus = "Ready to sync"
        syncStartTask?.cancel()
        syncStartTask = nil
        timer?.invalidate()
        timer = nil
        clickNode.stop()
        backingNode.stop()
    }

    func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0), 1)
        clickNode.volume = Float(volume)
    }

    func setMusicVolume(_ newValue: Double) {
        musicVolume = min(max(newValue, 0), 1)
        backingNode.volume = Float(musicVolume)
    }

    func setBackingTrack(_ match: TrackMatch) {
        selectedTrackTitle = match.track.title
        syncOffsetMilliseconds = match.alignment.phaseOffsetMilliseconds
        syncMode = match.alignment.mode.title
        backingBuffer = Self.makeBackingLoopBuffer(
            track: match.track,
            alignment: match.alignment,
            format: audioFormat
        )
        musicStatus = isRunning ? "Backing loop playing" : "Generated loop ready"

        if isRunning {
            startBackingLoop()
            beginSyncedClickLoop()
        }
    }

    private func beginSyncedClickLoop() {
        syncStartTask?.cancel()
        timer?.invalidate()
        timer = nil

        syncStartTask = Task { [syncOffsetMilliseconds] in
            if syncOffsetMilliseconds > 0 {
                try? await Task.sleep(for: .milliseconds(syncOffsetMilliseconds))
            }
            guard !Task.isCancelled else { return }
            playClick()
            audioStatus = "Playing"
            syncStatus = "Locked with \(syncMode) alignment"
            restartTimer()
        }
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
        clickNode.scheduleBuffer(clickBuffer, at: nil, options: .interrupts, completionHandler: nil)
        if !clickNode.isPlaying {
            clickNode.play()
        }
    }

    private func startBackingLoop() {
        guard isAudioConfigured, let backingBuffer else { return }
        backingNode.stop()
        backingNode.scheduleBuffer(backingBuffer, at: nil, options: .loops, completionHandler: nil)
        backingNode.play()
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

        clickBuffer = Self.makeClickBuffer(format: audioFormat)

        audioEngine.attach(clickNode)
        audioEngine.attach(backingNode)
        audioEngine.connect(clickNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(backingNode, to: audioEngine.mainMixerNode, format: audioFormat)
        clickNode.volume = Float(volume)
        backingNode.volume = Float(musicVolume)

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

    private static func makeBackingLoopBuffer(
        track: RunningTrack,
        alignment: BeatAlignment,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer {
        let beatsPerLoop = 8
        let beatInterval = 60.0 / Double(track.bpm)
        let duration = beatInterval * Double(beatsPerLoop)
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let frames = Int(frameCount)
        let channel = buffer.floatChannelData![0]
        let energy = min(max(Double(track.energy) / 100.0, 0.35), 1.0)
        let bassFrequency = track.preference == .instrumental ? 82.0 : 110.0
        let padFrequency = 220.0 + Double(track.title.count % 5) * 18.0

        for frame in 0..<frames {
            let time = Double(frame) / sampleRate
            let beatPosition = time / beatInterval
            let beatIndex = Int(beatPosition.rounded(.down))
            let beatPhase = beatPosition - Double(beatIndex)

            let kick = percussionEnvelope(phase: beatPhase, width: 0.14, power: 9.0) * (beatIndex % 2 == 0 ? 0.72 : 0.36)
            let snarePhase = abs(beatPhase - 0.5)
            let snare = percussionEnvelope(phase: snarePhase, width: 0.08, power: 7.0) * (beatIndex % 4 == 2 ? 0.38 : 0.16)
            let hatPhase = abs((beatPhase * 2.0).truncatingRemainder(dividingBy: 1.0))
            let hat = percussionEnvelope(phase: hatPhase, width: 0.05, power: 12.0) * 0.16

            let bassEnvelope = max(0, 1.0 - beatPhase * 1.6)
            let bass = sin(2.0 * .pi * bassFrequency * time) * bassEnvelope * 0.2
            let pad = sin(2.0 * .pi * padFrequency * time) * 0.055
            let syncPulse = alignment.mode == .doubleTime ? sin(2.0 * .pi * Double(alignment.effectiveBPM) / 60.0 * time) * 0.035 : 0

            let sample = (kick + snare + hat + bass + pad + syncPulse) * energy
            channel[frame] = Float(max(-0.95, min(0.95, sample)))
        }

        return buffer
    }

    private static func percussionEnvelope(phase: Double, width: Double, power: Double) -> Double {
        guard phase >= 0, phase < width else { return 0 }
        let normalized = 1.0 - phase / width
        return pow(normalized, power)
    }
}
