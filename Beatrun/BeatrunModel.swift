import Foundation
import Observation

@MainActor
@Observable
final class BeatrunModel {
    private(set) var cadence = 180

    private(set) var vocalPreference: VocalPreference = .instrumental

    private(set) var recommendations: [TrackMatch] = []
    private(set) var discoveryPhase: DiscoveryPhase = .ready
    private(set) var discoveryMessage = "Offline demo catalog ready."
    private(set) var autoMatchMessage = "Best match updates when cadence or music type changes."
    private(set) var searchCount = 0
    var selectedMatch: TrackMatch?
    let metronome = MetronomeEngine()

    var nowPlayingMatch: TrackMatch? {
        metronome.currentMatch ?? selectedMatch
    }

    var upcomingMatch: TrackMatch? {
        metronome.upcomingMatch
    }

    @ObservationIgnored private let discoveryService = MusicDiscoveryService()
    @ObservationIgnored private var discoveryTask: Task<Void, Never>?
    @ObservationIgnored private var scheduledDiscoveryTask: Task<Void, Never>?

    init() {
        refreshRecommendations()
    }

    func select(_ match: TrackMatch) {
        selectedMatch = match
        autoMatchMessage = "Manual selection: \(match.track.title)."
        metronome.setPlaybackQueue(current: match, candidates: recommendations)
    }

    func setCadence(_ newValue: Int) {
        let clampedValue = min(max(newValue, 140), 200)
        guard cadence != clampedValue else { return }
        cadence = clampedValue
        metronome.cadence = clampedValue
        scheduleDiscovery(
            reason: "Cadence changed to \(clampedValue) SPM.",
            delayMilliseconds: 350
        )
    }

    func setVocalPreference(_ preference: VocalPreference) {
        guard vocalPreference != preference else { return }
        vocalPreference = preference
        scheduleDiscovery(
            reason: "Music type changed to \(preference.title.lowercased()).",
            delayMilliseconds: 150
        )
    }

    func discoverMusic() {
        scheduledDiscoveryTask?.cancel()
        scheduledDiscoveryTask = nil
        startDiscovery(reason: "Manual search requested.", preferBestMatch: true)
    }

    func refreshRecommendations() {
        recommendations = DemoMusicCatalog.recommendations(cadence: cadence, preference: vocalPreference)
        applySelectionAfterDiscovery(preferBestMatch: true)
    }

    private func scheduleDiscovery(reason: String, delayMilliseconds: Int) {
        scheduledDiscoveryTask?.cancel()
        discoveryTask?.cancel()
        discoveryPhase = .searching
        discoveryMessage = "\(reason) Waiting for input to settle."
        autoMatchMessage = "Auto rematch queued for \(cadence) SPM."

        scheduledDiscoveryTask = Task { [delayMilliseconds, reason] in
            if delayMilliseconds > 0 {
                try? await Task.sleep(for: .milliseconds(delayMilliseconds))
            }
            guard !Task.isCancelled else { return }
            startDiscovery(reason: reason, preferBestMatch: true)
        }
    }

    private func startDiscovery(reason: String, preferBestMatch: Bool) {
        discoveryTask?.cancel()
        let cadence = cadence
        let preference = vocalPreference
        searchCount += 1

        discoveryTask = Task {
            discoveryPhase = .searching
            discoveryMessage = "\(reason) Finding \(preference.title.lowercased()) tracks near \(cadence) SPM."

            do {
                let matches = try await discoveryService.discover(cadence: cadence, preference: preference)
                guard !Task.isCancelled else { return }
                discoveryPhase = .analyzing
                discoveryMessage = "Checking 1:1 BPM fit and tempo adjustment limits."

                try await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                recommendations = matches
                applySelectionAfterDiscovery(preferBestMatch: preferBestMatch)
                discoveryPhase = .ready
                discoveryMessage = "Found \(matches.count) offline demo tracks."
            } catch is CancellationError {
                return
            } catch {
                discoveryPhase = .failed(error.localizedDescription)
                discoveryMessage = error.localizedDescription
            }
        }
    }

    private func applySelectionAfterDiscovery(preferBestMatch: Bool) {
        if preferBestMatch, let bestMatch = recommendations.first {
            selectedMatch = bestMatch
            autoMatchMessage = "Auto-selected \(bestMatch.track.title) for \(cadence) SPM."
            metronome.setPlaybackQueue(current: bestMatch, candidates: recommendations)
        } else if let selectedMatch,
           let updatedSelection = recommendations.first(where: { $0.track.title == selectedMatch.track.title }) {
            self.selectedMatch = updatedSelection
            autoMatchMessage = "Kept \(updatedSelection.track.title) for \(cadence) SPM."
            metronome.setPlaybackQueue(current: updatedSelection, candidates: recommendations)
        } else {
            selectedMatch = recommendations.first
            if let selectedMatch {
                autoMatchMessage = "Auto-selected \(selectedMatch.track.title) for \(cadence) SPM."
                metronome.setPlaybackQueue(current: selectedMatch, candidates: recommendations)
            } else {
                autoMatchMessage = "No legal 1:1 match found within \(Int(TempoAdjustment.maximumAdjustmentPercent))% speed change."
                metronome.clearBackingTrack()
            }
        }
    }
}
