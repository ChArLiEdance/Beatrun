import Foundation
import Observation

@Observable
final class WatchPlaybackState {
    // Scaffold state only; replace with WatchConnectivity, HealthKit, and Workout Session data later.
    var targetCadence = 180
    var isPlaying = false
    var syncStatus = "1:1 tempo match ready"
    var currentTrack = "Clean Stride"
    var nextTrack = "Blue Relay"
    var transitionStatus = "Next track synced in 4 beats"
    var crossfadeStatus = "Crossfade idle"

    func togglePlayback() {
        isPlaying.toggle()
        syncStatus = isPlaying ? "Metronome clock running" : "Paused"
        crossfadeStatus = isPlaying ? "Crossfade armed" : "Crossfade idle"
    }
}
