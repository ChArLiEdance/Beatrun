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
        BeatAlignment.analyze(track: self, cadence: cadence).bpmDelta
    }

    func matchScore(for cadence: Int) -> Int {
        BeatAlignment.analyze(track: self, cadence: cadence).score
    }

    func alignmentOffsetMilliseconds(for cadence: Int) -> Int {
        BeatAlignment.analyze(track: self, cadence: cadence).phaseOffsetMilliseconds
    }
}

enum TempoMatchMode: String {
    case direct
    case doubleTime
    case halfTime

    var title: String {
        switch self {
        case .direct:
            "Direct"
        case .doubleTime:
            "Double-time"
        case .halfTime:
            "Half-time"
        }
    }

    var description: String {
        switch self {
        case .direct:
            "Metronome clicks follow the song beat."
        case .doubleTime:
            "Two running steps fit inside each song beat."
        case .halfTime:
            "One running step spans two fast song beats."
        }
    }
}

struct BeatAlignment: Hashable {
    let mode: TempoMatchMode
    let effectiveBPM: Int
    let bpmDelta: Int
    let phaseOffsetMilliseconds: Int
    let confidence: Double

    var score: Int {
        let tempoScore = max(0, 100 - bpmDelta * 4)
        let confidenceScore = Int(confidence * 100)
        return min(100, Int(Double(tempoScore) * 0.65 + Double(confidenceScore) * 0.35))
    }

    var qualityLabel: String {
        if bpmDelta <= 2 {
            "Locked"
        } else if bpmDelta <= 6 {
            "Close"
        } else {
            "Needs analysis"
        }
    }

    var metronomeIntervalMilliseconds: Int {
        Int((60.0 / Double(effectiveBPM) * 1_000).rounded())
    }

    var songBeatIntervalMilliseconds: Int {
        Int((60.0 / Double(max(1, effectiveBPM)) * 1_000).rounded())
    }

    static func analyze(track: RunningTrack, cadence: Int) -> BeatAlignment {
        let candidates: [(TempoMatchMode, Int)] = [
            (.direct, track.bpm),
            (.doubleTime, track.bpm * 2),
            (.halfTime, max(1, track.bpm / 2))
        ]

        let best = candidates.min { first, second in
            abs(first.1 - cadence) < abs(second.1 - cadence)
        } ?? (.direct, track.bpm)

        let bpmDelta = abs(best.1 - cadence)
        let confidencePenalty = min(0.45, Double(bpmDelta) * 0.035)
        let adjustedConfidence = min(0.99, max(0.1, track.beatConfidence - confidencePenalty))
        let titleSeed = track.title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let phaseOffset = min(96, max(4, (titleSeed % 42) + bpmDelta * 5))

        return BeatAlignment(
            mode: best.0,
            effectiveBPM: best.1,
            bpmDelta: bpmDelta,
            phaseOffsetMilliseconds: phaseOffset,
            confidence: adjustedConfidence
        )
    }
}

struct TrackMatch: Identifiable {
    let track: RunningTrack
    let cadence: Int

    var id: UUID { track.id }
    var alignment: BeatAlignment { BeatAlignment.analyze(track: track, cadence: cadence) }
    var score: Int { alignment.score }
    var offsetMilliseconds: Int { alignment.phaseOffsetMilliseconds }
    var tempoDistance: Int { alignment.bpmDelta }

    var syncLabel: String {
        alignment.qualityLabel
    }
}

struct MockMusicCatalog {
    static let tracks: [RunningTrack] = [
        RunningTrack(title: "Night Circuit", artist: "Pulse Atlas", bpm: 160, preference: .instrumental, genre: "Electronic", energy: 82, beatConfidence: 0.94),
        RunningTrack(title: "Forward Motion", artist: "Lane Echo", bpm: 166, preference: .instrumental, genre: "Synth", energy: 78, beatConfidence: 0.91),
        RunningTrack(title: "Ground Pulse", artist: "Lowline", bpm: 90, preference: .instrumental, genre: "Downtempo", energy: 76, beatConfidence: 0.93),
        RunningTrack(title: "Steel Horizon", artist: "Metric Drift", bpm: 172, preference: .instrumental, genre: "Breakbeat", energy: 88, beatConfidence: 0.89),
        RunningTrack(title: "Clean Stride", artist: "Northline", bpm: 180, preference: .instrumental, genre: "House", energy: 90, beatConfidence: 0.97),
        RunningTrack(title: "Blue Relay", artist: "Aster Beat", bpm: 186, preference: .instrumental, genre: "Dance", energy: 86, beatConfidence: 0.9),
        RunningTrack(title: "Step Into Light", artist: "Mira Lane", bpm: 158, preference: .vocal, genre: "Pop", energy: 74, beatConfidence: 0.86),
        RunningTrack(title: "Hold the Pace", artist: "The Split Times", bpm: 168, preference: .vocal, genre: "Indie Pop", energy: 79, beatConfidence: 0.88),
        RunningTrack(title: "Keep Breathing", artist: "Cora Vale", bpm: 176, preference: .vocal, genre: "Pop Rock", energy: 84, beatConfidence: 0.87),
        RunningTrack(title: "Every Other Step", artist: "Vera North", bpm: 90, preference: .vocal, genre: "Alt Pop", energy: 73, beatConfidence: 0.9),
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
