import Foundation
import Observation

@MainActor
@Observable
final class BeatrunModel {
    private(set) var cadence = 180

    private(set) var vocalPreference: VocalPreference = .instrumental

    private(set) var recommendations: [TrackMatch] = []
    var selectedMatch: TrackMatch?
    let metronome = MetronomeEngine()

    init() {
        refreshRecommendations()
    }

    func select(_ match: TrackMatch) {
        selectedMatch = match
    }

    func setCadence(_ newValue: Int) {
        let clampedValue = min(max(newValue, 140), 200)
        guard cadence != clampedValue else { return }
        cadence = clampedValue
        metronome.cadence = clampedValue
        refreshRecommendations()
    }

    func setVocalPreference(_ preference: VocalPreference) {
        guard vocalPreference != preference else { return }
        vocalPreference = preference
        refreshRecommendations()
    }

    func refreshRecommendations() {
        recommendations = MockMusicCatalog.recommendations(cadence: cadence, preference: vocalPreference)

        if let selectedMatch,
           let updatedSelection = recommendations.first(where: { $0.track.title == selectedMatch.track.title }) {
            self.selectedMatch = updatedSelection
        } else {
            selectedMatch = recommendations.first
        }
    }
}
