import Foundation
import Observation

@MainActor
@Observable
final class BeatrunModel {
    private(set) var cadence = 180

    private(set) var vocalPreference: VocalPreference = .instrumental

    private(set) var recommendations: [TrackMatch] = []
    private(set) var discoveryPhase: DiscoveryPhase = .ready
    private(set) var discoveryMessage = "Generated preview catalog ready."
    private(set) var searchCount = 0
    var selectedMatch: TrackMatch?
    let metronome = MetronomeEngine()

    @ObservationIgnored private let discoveryService = MusicDiscoveryService()
    @ObservationIgnored private var discoveryTask: Task<Void, Never>?

    init() {
        refreshRecommendations()
    }

    func select(_ match: TrackMatch) {
        selectedMatch = match
        metronome.setBackingTrack(match)
    }

    func setCadence(_ newValue: Int) {
        let clampedValue = min(max(newValue, 140), 200)
        guard cadence != clampedValue else { return }
        cadence = clampedValue
        metronome.cadence = clampedValue
        discoverMusic()
    }

    func setVocalPreference(_ preference: VocalPreference) {
        guard vocalPreference != preference else { return }
        vocalPreference = preference
        discoverMusic()
    }

    func discoverMusic() {
        discoveryTask?.cancel()
        let cadence = cadence
        let preference = vocalPreference
        searchCount += 1

        discoveryTask = Task {
            discoveryPhase = .searching
            discoveryMessage = "Finding \(preference.title.lowercased()) tracks near \(cadence) SPM."

            do {
                let matches = try await discoveryService.discover(cadence: cadence, preference: preference)
                guard !Task.isCancelled else { return }
                discoveryPhase = .analyzing
                discoveryMessage = "Estimating beat grids and match modes."

                try await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                recommendations = matches
                applySelectionAfterDiscovery()
                discoveryPhase = .ready
                discoveryMessage = "Found \(matches.count) generated preview tracks."
            } catch is CancellationError {
                return
            } catch {
                discoveryPhase = .failed(error.localizedDescription)
                discoveryMessage = error.localizedDescription
            }
        }
    }

    func refreshRecommendations() {
        recommendations = MockMusicCatalog.recommendations(cadence: cadence, preference: vocalPreference)
        applySelectionAfterDiscovery()
    }

    private func applySelectionAfterDiscovery() {
        if let selectedMatch,
           let updatedSelection = recommendations.first(where: { $0.track.title == selectedMatch.track.title }) {
            self.selectedMatch = updatedSelection
            metronome.setBackingTrack(updatedSelection)
        } else {
            selectedMatch = recommendations.first
            if let selectedMatch {
                metronome.setBackingTrack(selectedMatch)
            }
        }
    }
}
