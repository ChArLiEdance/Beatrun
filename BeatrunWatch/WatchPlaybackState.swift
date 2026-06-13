import Foundation
import Observation
import WatchKit

@Observable
@MainActor
final class WatchPlaybackState {
    var targetCadence = WatchSyncPayload.fallback.targetCadence
    var isPlaying = WatchSyncPayload.fallback.isPlaying
    var playbackStatus = WatchSyncPayload.fallback.playbackStatus
    var syncStatus = WatchSyncPayload.fallback.syncStatus
    var currentTrack = WatchSyncPayload.fallback.currentTrack
    var nextTrack = WatchSyncPayload.fallback.nextTrack
    var transitionStatus = WatchSyncPayload.fallback.transitionStatus
    var beatsRemaining = WatchSyncPayload.fallback.beatsRemaining
    var isCrossfading = WatchSyncPayload.fallback.isCrossfading
    var beatCount = WatchSyncPayload.fallback.beatCount
    var originalBPM = WatchSyncPayload.fallback.originalBPM
    var adjustedBPM = WatchSyncPayload.fallback.adjustedBPM
    var speedChangeLabel = WatchSyncPayload.fallback.speedChangeLabel
    var rightsStatus = WatchSyncPayload.fallback.rightsStatus
    var connectionStatus = "Standalone Mode"
    var lastUpdated = WatchSyncPayload.fallback.updatedAt

    @ObservationIgnored private let connectivity = WatchConnectivityController()

    init() {
        connectivity.onPayload = { [weak self] payload in
            self?.apply(payload)
        }
        connectivity.onStatusChange = { [weak self] status in
            self?.applyConnectionStatus(status)
        }
    }

    var playPauseTitle: String {
        isPlaying ? "Pause" : "Play"
    }

    var playPauseSymbol: String {
        isPlaying ? "pause.fill" : "play.fill"
    }

    var crossfadeStatus: String {
        isCrossfading ? "Crossfade active" : "Crossfade idle"
    }

    var standaloneStatus: String {
        if connectionStatus == "iPhone connected" {
            "iPhone connected"
        } else {
            "Standalone workout active"
        }
    }

    func togglePlayback() {
        isPlaying.toggle()
        syncStatus = isPlaying ? "Metronome clock running" : "Paused"
        playbackStatus = isPlaying ? "Playing" : "Paused"
        playHaptic()
        connectivity.send(.playPause())
    }

    func startWorkout() {
        isPlaying = true
        playbackStatus = "Workout"
        syncStatus = standaloneStatus
        transitionStatus = "Local workout clock running"
        playHaptic()
        connectivity.send(.start())
    }

    func pauseOrResumeWorkout(isRunning: Bool) {
        isPlaying = isRunning
        playbackStatus = isRunning ? "Workout" : "Paused"
        syncStatus = isRunning ? standaloneStatus : "Workout paused"
        playHaptic()
        connectivity.send(.playPause())
    }

    func endWorkout() {
        isPlaying = false
        playbackStatus = "Ended"
        syncStatus = connectionStatus == "iPhone connected" ? "Workout ended" : "Standalone ended"
        transitionStatus = "Local workout ended"
        playHaptic()
        connectivity.send(.stop())
    }

    func stopPlayback() {
        isPlaying = false
        playbackStatus = "Stopped"
        syncStatus = "Ready to sync"
        playHaptic()
        connectivity.send(.stop())
    }

    func adjustCadence(by delta: Int) {
        targetCadence = min(max(targetCadence + delta, 140), 200)
        transitionStatus = "Cadence update sent"
        playHaptic()
        connectivity.send(.cadenceDelta(delta))
    }

    private func apply(_ payload: WatchSyncPayload) {
        targetCadence = payload.targetCadence
        isPlaying = payload.isPlaying
        playbackStatus = payload.playbackStatus
        syncStatus = payload.syncStatus
        currentTrack = payload.currentTrack
        nextTrack = payload.nextTrack
        transitionStatus = payload.transitionStatus
        beatsRemaining = payload.beatsRemaining
        isCrossfading = payload.isCrossfading
        beatCount = payload.beatCount
        originalBPM = payload.originalBPM
        adjustedBPM = payload.adjustedBPM
        speedChangeLabel = payload.speedChangeLabel
        rightsStatus = payload.rightsStatus
        lastUpdated = payload.updatedAt
    }

    private func applyConnectionStatus(_ status: String) {
        if status == "Waiting for iPhone" || status == "iPhone not reachable" || status == "Control queued" {
            connectionStatus = "Standalone Mode"
            syncStatus = isPlaying ? "Standalone workout active" : "Standalone ready"
        } else {
            connectionStatus = status
        }
    }

    private func playHaptic() {
        WKInterfaceDevice.current().play(.click)
    }
}
