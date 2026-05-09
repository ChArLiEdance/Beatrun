import Foundation

enum VocalPreference: String, CaseIterable, Identifiable {
    case instrumental
    case vocal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instrumental:
            "Pure"
        case .vocal:
            "Vocal"
        }
    }

    var description: String {
        switch self {
        case .instrumental:
            "Instrumental tracks with a clear beat."
        case .vocal:
            "Songs with lyrics and stable rhythm."
        }
    }
}

struct RunningTrack: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let bpm: Int
    let preference: VocalPreference
    let genre: String
    let energy: Int
    let beatConfidence: Double

    func tempoDistance(to cadence: Int) -> Int {
        let direct = abs(bpm - cadence)
        let doubleTime = abs((bpm * 2) - cadence)
        let halfTime = abs((bpm / 2) - cadence)
        return min(direct, doubleTime, halfTime)
    }

    func matchScore(for cadence: Int) -> Int {
        let tempoScore = max(0, 100 - tempoDistance(to: cadence) * 4)
        let confidenceScore = Int(beatConfidence * 100)
        return min(100, Int(Double(tempoScore) * 0.65 + Double(confidenceScore) * 0.35))
    }

    func alignmentOffsetMilliseconds(for cadence: Int) -> Int {
        let distance = tempoDistance(to: cadence)
        return min(80, max(6, distance * 6))
    }
}

struct TrackMatch: Identifiable {
    let track: RunningTrack
    let cadence: Int

    var id: UUID { track.id }
    var score: Int { track.matchScore(for: cadence) }
    var offsetMilliseconds: Int { track.alignmentOffsetMilliseconds(for: cadence) }
    var tempoDistance: Int { track.tempoDistance(to: cadence) }

    var syncLabel: String {
        if tempoDistance <= 2 {
            "Locked"
        } else if tempoDistance <= 6 {
            "Close"
        } else {
            "Needs analysis"
        }
    }
}

struct MockMusicCatalog {
    static let tracks: [RunningTrack] = [
        RunningTrack(title: "Night Circuit", artist: "Pulse Atlas", bpm: 160, preference: .instrumental, genre: "Electronic", energy: 82, beatConfidence: 0.94),
        RunningTrack(title: "Forward Motion", artist: "Lane Echo", bpm: 166, preference: .instrumental, genre: "Synth", energy: 78, beatConfidence: 0.91),
        RunningTrack(title: "Steel Horizon", artist: "Metric Drift", bpm: 172, preference: .instrumental, genre: "Breakbeat", energy: 88, beatConfidence: 0.89),
        RunningTrack(title: "Clean Stride", artist: "Northline", bpm: 180, preference: .instrumental, genre: "House", energy: 90, beatConfidence: 0.97),
        RunningTrack(title: "Blue Relay", artist: "Aster Beat", bpm: 186, preference: .instrumental, genre: "Dance", energy: 86, beatConfidence: 0.9),
        RunningTrack(title: "Step Into Light", artist: "Mira Lane", bpm: 158, preference: .vocal, genre: "Pop", energy: 74, beatConfidence: 0.86),
        RunningTrack(title: "Hold the Pace", artist: "The Split Times", bpm: 168, preference: .vocal, genre: "Indie Pop", energy: 79, beatConfidence: 0.88),
        RunningTrack(title: "Keep Breathing", artist: "Cora Vale", bpm: 176, preference: .vocal, genre: "Pop Rock", energy: 84, beatConfidence: 0.87),
        RunningTrack(title: "Run the Line", artist: "Bright Signal", bpm: 180, preference: .vocal, genre: "Dance Pop", energy: 91, beatConfidence: 0.92),
        RunningTrack(title: "After the Turn", artist: "City Frame", bpm: 188, preference: .vocal, genre: "Alternative", energy: 83, beatConfidence: 0.85)
    ]

    static func recommendations(cadence: Int, preference: VocalPreference) -> [TrackMatch] {
        tracks
            .filter { $0.preference == preference }
            .map { TrackMatch(track: $0, cadence: cadence) }
            .sorted {
                if $0.score == $1.score {
                    return $0.tempoDistance < $1.tempoDistance
                }
                return $0.score > $1.score
            }
    }
}
