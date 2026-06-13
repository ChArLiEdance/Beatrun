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
    private(set) var musicStatus = "Music library ready"
    private(set) var musicVolume = 0.45
    private(set) var selectedTrackTitle = "No track"
    private(set) var upcomingTrackTitle = "No upcoming track"
    private(set) var syncStatus = "Ready to sync"
    private(set) var syncOffsetMilliseconds = 0
    private(set) var syncMode = "1:1"
    private(set) var queueStatus = "Queue waiting for a legal 1:1 match"
    private(set) var transitionStatus = "No transition scheduled"
    private(set) var transitionBeatsRemaining = 0
    private(set) var transitionBoundaryBeats = 8
    private(set) var crossfadeBeats = 4
    private(set) var isCrossfading = false
    private(set) var nextTrackReady = false
    private(set) var currentMatch: TrackMatch?
    private(set) var upcomingMatch: TrackMatch?

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var syncStartTask: Task<Void, Never>?
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private let clickNode = AVAudioPlayerNode()
    @ObservationIgnored private var currentBackingNode = AVAudioPlayerNode()
    @ObservationIgnored private var nextBackingNode = AVAudioPlayerNode()
    @ObservationIgnored private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    @ObservationIgnored private var clickBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var currentBackingBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var nextBackingBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var queueCandidates: [TrackMatch] = []
    @ObservationIgnored private var transitionStartBeat: Int?
    @ObservationIgnored private var transitionEndBeat: Int?
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
            musicStatus = currentBackingBuffer == nil ? "Metronome only - authorized audio required" : "Authorized fallback audio playing"
            syncStatus = syncOffsetMilliseconds == 0 ? "Locked on start" : "Waiting \(syncOffsetMilliseconds) ms for tempo sync"
            startCurrentLoop()
            scheduleTransitionCycle(fromBeat: beatCount)
            beginInitialSyncedClickLoop()
        } catch {
            audioError = error.localizedDescription
            audioStatus = "Audio unavailable"
            stop()
        }
    }

    func stop() {
        isRunning = false
        audioStatus = audioError == nil ? "Ready" : "Audio unavailable"
        musicStatus = currentMatch == nil ? "No authorized music selected" : "Music library ready"
        syncStatus = "Ready to sync"
        isCrossfading = false
        transitionStatus = nextTrackReady ? "Next track metadata ready" : "No transition scheduled"
        transitionBeatsRemaining = 0
        transitionStartBeat = nil
        transitionEndBeat = nil
        syncStartTask?.cancel()
        syncStartTask = nil
        timer?.invalidate()
        timer = nil
        clickNode.stop()
        currentBackingNode.stop()
        nextBackingNode.stop()
        applyBackingVolumes(current: 1.0, next: 0.0)
    }

    func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0), 1)
        clickNode.volume = Float(volume)
    }

    func setMusicVolume(_ newValue: Double) {
        musicVolume = min(max(newValue, 0), 1)
        applyCurrentTransitionVolumes()
    }

    func setPlaybackQueue(current: TrackMatch?, candidates: [TrackMatch]) {
        queueCandidates = candidates
        currentMatch = current
        selectedTrackTitle = current?.track.title ?? "No legal match"
        syncOffsetMilliseconds = current?.adjustment.phaseOffsetMilliseconds ?? 0
        syncMode = current.map { "1:1 \($0.adjustment.speedChangeLabel)" } ?? "1:1"
        currentBackingBuffer = current.flatMap { backingBuffer(for: $0) }
        musicStatus = current.map { $0.track.canUseForTempoAdjustedPlayback ? "Local library track selected" : "Metadata match selected" } ?? "No authorized music selected"

        if let current {
            prepareUpcomingTrack(after: current)
            queueStatus = nextTrackReady ? "Current and next tracks are legal 1:1 metadata matches" : "No legal upcoming track"
        } else {
            upcomingMatch = nil
            upcomingTrackTitle = "No upcoming track"
            nextBackingBuffer = nil
            nextTrackReady = false
            queueStatus = "Queue waiting for a legal 1:1 match"
        }

        if isRunning {
            startCurrentLoop()
            scheduleTransitionCycle(fromBeat: beatCount)
        } else {
            transitionStatus = nextTrackReady ? "Next track metadata ready" : "No transition scheduled"
        }
    }

    func clearBackingTrack() {
        setPlaybackQueue(current: nil, candidates: [])
        musicStatus = "No authorized music selected"
        if isRunning {
            currentBackingNode.stop()
            nextBackingNode.stop()
        }
    }

    private func beginInitialSyncedClickLoop() {
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
            syncStatus = "Locked with \(syncMode) tempo match"
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

        guard let clickBuffer else {
            updateTransitionAfterBeat()
            return
        }

        clickNode.scheduleBuffer(clickBuffer, at: nil, options: .interrupts, completionHandler: nil)
        if !clickNode.isPlaying {
            clickNode.play()
        }

        updateTransitionAfterBeat()
    }

    private func prepareUpcomingTrack(after current: TrackMatch) {
        guard let next = nextCandidate(after: current) else {
            upcomingMatch = nil
            upcomingTrackTitle = "No upcoming track"
            nextBackingBuffer = nil
            nextTrackReady = false
            return
        }

        upcomingMatch = next
        upcomingTrackTitle = next.track.title
        nextBackingBuffer = backingBuffer(for: next)
        nextTrackReady = true
    }

    private func nextCandidate(after current: TrackMatch) -> TrackMatch? {
        let legalCandidates = queueCandidates.filter { candidate in
            candidate.id != current.id && candidate.adjustment.isAllowed
        }
        guard !legalCandidates.isEmpty else { return nil }

        if let currentIndex = queueCandidates.firstIndex(where: { $0.id == current.id }) {
            let tail = queueCandidates.dropFirst(currentIndex + 1)
            if let next = tail.first(where: { $0.id != current.id && $0.adjustment.isAllowed }) {
                return next
            }
        }

        return legalCandidates.first
    }

    private func scheduleTransitionCycle(fromBeat beat: Int) {
        guard nextTrackReady else {
            transitionStartBeat = nil
            transitionEndBeat = nil
            transitionBeatsRemaining = 0
            transitionStatus = "No legal next track"
            return
        }

        let nextBoundary = ((beat / transitionBoundaryBeats) + 2) * transitionBoundaryBeats
        transitionEndBeat = nextBoundary
        transitionStartBeat = max(beat + 1, nextBoundary - crossfadeBeats)
        transitionBeatsRemaining = max(0, (transitionStartBeat ?? nextBoundary) - beat)
        transitionStatus = "Next track synced in \(transitionBeatsRemaining) beats"
        isCrossfading = false
        applyBackingVolumes(current: 1.0, next: 0.0)
    }

    private func updateTransitionAfterBeat() {
        guard isRunning, nextTrackReady, let transitionStartBeat, let transitionEndBeat else { return }

        if beatCount < transitionStartBeat {
            transitionBeatsRemaining = transitionStartBeat - beatCount
            transitionStatus = "Next track synced in \(transitionBeatsRemaining) beats"
            return
        }

        if !isCrossfading {
            beginCrossfade()
        }

        let elapsed = max(0, beatCount - transitionStartBeat)
        let progress = min(1.0, Double(elapsed + 1) / Double(max(1, crossfadeBeats)))
        applyBackingVolumes(current: 1.0 - progress, next: progress)
        transitionBeatsRemaining = max(0, transitionEndBeat - beatCount)
        transitionStatus = "Crossfade active: \(transitionBeatsRemaining) beats to next track"

        if beatCount >= transitionEndBeat {
            completeCrossfade()
        }
    }

    private func beginCrossfade() {
        isCrossfading = true
        guard let nextBackingBuffer else {
            musicStatus = "Metadata transition in progress"
            return
        }
        nextBackingNode.stop()
        nextBackingNode.scheduleBuffer(nextBackingBuffer, at: nil, options: .loops, completionHandler: nil)
        nextBackingNode.play()
        applyBackingVolumes(current: 1.0, next: 0.0)
        musicStatus = "Crossfade in progress"
    }

    private func completeCrossfade() {
        currentBackingNode.stop()
        swap(&currentBackingNode, &nextBackingNode)
        currentBackingBuffer = nextBackingBuffer
        currentMatch = upcomingMatch
        selectedTrackTitle = currentMatch?.track.title ?? "No track"
        syncOffsetMilliseconds = currentMatch?.adjustment.phaseOffsetMilliseconds ?? 0
        syncMode = currentMatch.map { "1:1 \($0.adjustment.speedChangeLabel)" } ?? "1:1"
        applyBackingVolumes(current: 1.0, next: 0.0)
        nextBackingNode.stop()

        if let currentMatch {
            prepareUpcomingTrack(after: currentMatch)
        } else {
            upcomingMatch = nil
            nextBackingBuffer = nil
            nextTrackReady = false
        }

        isCrossfading = false
        musicStatus = currentBackingBuffer == nil ? "Music metadata locked" : "Authorized fallback audio playing"
        queueStatus = nextTrackReady ? "Next track metadata ready" : "No legal upcoming track"
        scheduleTransitionCycle(fromBeat: beatCount)
    }

    private func startCurrentLoop() {
        guard isAudioConfigured, let currentBackingBuffer else { return }
        currentBackingNode.stop()
        currentBackingNode.scheduleBuffer(currentBackingBuffer, at: nil, options: .loops, completionHandler: nil)
        currentBackingNode.play()
        nextBackingNode.stop()
        isCrossfading = false
        applyBackingVolumes(current: 1.0, next: 0.0)
    }

    private func applyCurrentTransitionVolumes() {
        if isCrossfading, let transitionStartBeat, let transitionEndBeat {
            let total = max(1, transitionEndBeat - transitionStartBeat)
            let progress = min(1.0, max(0.0, Double(beatCount - transitionStartBeat) / Double(total)))
            applyBackingVolumes(current: 1.0 - progress, next: progress)
        } else {
            applyBackingVolumes(current: 1.0, next: 0.0)
        }
    }

    private func applyBackingVolumes(current: Double, next: Double) {
        currentBackingNode.volume = Float(musicVolume * min(max(current, 0), 1))
        nextBackingNode.volume = Float(musicVolume * min(max(next, 0), 1))
    }

    private func backingBuffer(for match: TrackMatch) -> AVAudioPCMBuffer? {
        guard match.track.source == .generatedPreview else {
            return nil
        }

        return Self.makeBackingLoopBuffer(
            track: match.track,
            adjustment: match.adjustment,
            format: audioFormat
        )
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
        audioEngine.attach(currentBackingNode)
        audioEngine.attach(nextBackingNode)
        audioEngine.connect(clickNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(currentBackingNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(nextBackingNode, to: audioEngine.mainMixerNode, format: audioFormat)
        clickNode.volume = Float(volume)
        applyBackingVolumes(current: 1.0, next: 0.0)

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
        adjustment: TempoAdjustment,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer {
        let beatsPerLoop = 8
        let beatInterval = 60.0 / Double(adjustment.adjustedBPM)
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
            // Development fallback loops are pre-trimmed to the documented beat-grid offset,
            // so sample zero represents the corrected downbeat for beat-boundary starts.
            let beatPosition = time.truncatingRemainder(dividingBy: duration) / beatInterval
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
            let syncPulse = sin(2.0 * .pi * Double(adjustment.targetCadence) / 60.0 * time) * 0.025

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
