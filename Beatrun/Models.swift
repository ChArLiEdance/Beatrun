import Foundation

enum VocalPreference: String, CaseIterable, Identifiable {
    case instrumental
    case vocal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instrumental:
            "Instrumental"
        case .vocal:
            "Vocal-style"
        }
    }

    var description: String {
        switch self {
        case .instrumental:
            "Instrumental demo loops with a clear 1:1 beat."
        case .vocal:
            "Vocal-style demo metadata with generated safe playback."
        }
    }
}

enum MusicSource: String, Hashable {
    case generatedPreview

    var title: String {
        switch self {
        case .generatedPreview:
            "Offline Demo"
        }
    }

    var usageNote: String {
        switch self {
        case .generatedPreview:
            "Only local generated demo audio is used. No commercial music is downloaded, scraped, or redistributed."
        }
    }
}

enum AudioRightsStatus: String, Hashable {
    case originalGenerated

    var title: String {
        switch self {
        case .originalGenerated:
            "Generated in app"
        }
    }

    var note: String {
        switch self {
        case .originalGenerated:
            "Safe for demo playback because the loop is synthesized locally from metadata."
        }
    }
}

enum DiscoveryPhase: Equatable {
    case ready
    case searching
    case analyzing
    case failed(String)

    var title: String {
        switch self {
        case .ready:
            "Ready"
        case .searching:
            "Searching"
        case .analyzing:
            "Checking tempo fit"
        case .failed:
            "Search failed"
        }
    }

    var systemImage: String {
        switch self {
        case .ready:
            "checkmark.circle.fill"
        case .searching:
            "magnifyingglass"
        case .analyzing:
            "speedometer"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }
}

struct AudioRights: Hashable {
    let status: AudioRightsStatus
    let licenseName: String
    let attribution: String
    let sourceDescription: String
    let sourceLink: String
    let allowsTempoAdjustment: Bool

    var tempoAdjustmentLabel: String {
        allowsTempoAdjustment ? "Tempo change allowed" : "Tempo change not allowed"
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
    let downbeatOffsetMilliseconds: Int
    let beatGridSource: String
    let rights: AudioRights
    let source: MusicSource = .generatedPreview

    func tempoDistance(to cadence: Int) -> Int {
        TempoAdjustment.analyze(track: self, cadence: cadence)?.bpmDelta ?? Int.max
    }

    func matchScore(for cadence: Int) -> Int {
        TempoAdjustment.analyze(track: self, cadence: cadence)?.score ?? 0
    }

    func alignmentOffsetMilliseconds(for cadence: Int) -> Int {
        TempoAdjustment.analyze(track: self, cadence: cadence)?.phaseOffsetMilliseconds ?? 0
    }
}

struct TempoAdjustment: Hashable {
    static let maximumAdjustmentPercent = 10.0

    let originalBPM: Int
    let adjustedBPM: Int
    let targetCadence: Int
    let speedRatio: Double
    let speedChangePercent: Double
    let bpmDelta: Int
    let phaseOffsetMilliseconds: Int
    let confidence: Double

    var score: Int {
        let tempoScore = max(0, 100 - Int(abs(speedChangePercent) * 4.5))
        let confidenceScore = Int(confidence * 100)
        return min(100, Int(Double(tempoScore) * 0.65 + Double(confidenceScore) * 0.35))
    }

    var qualityLabel: String {
        if abs(speedChangePercent) <= 2 {
            "Native fit"
        } else if abs(speedChangePercent) <= 6 {
            "Clean retime"
        } else {
            "Edge retime"
        }
    }

    var speedChangeLabel: String {
        let sign = speedChangePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", speedChangePercent))%"
    }

    var metronomeIntervalMilliseconds: Int {
        Int((60.0 / Double(max(1, targetCadence)) * 1_000).rounded())
    }

    var songBeatIntervalMilliseconds: Int {
        Int((60.0 / Double(max(1, adjustedBPM)) * 1_000).rounded())
    }

    var isAllowed: Bool {
        abs(speedChangePercent) <= Self.maximumAdjustmentPercent
    }

    static func analyze(track: RunningTrack, cadence: Int) -> TempoAdjustment? {
        guard track.rights.allowsTempoAdjustment else { return nil }
        let ratio = Double(cadence) / Double(track.bpm)
        let percent = (ratio - 1.0) * 100.0
        guard abs(percent) <= maximumAdjustmentPercent else { return nil }

        let adjustedBPM = Int((Double(track.bpm) * ratio).rounded())
        let bpmDelta = abs(adjustedBPM - cadence)
        let adjustmentPenalty = min(0.38, abs(percent) / maximumAdjustmentPercent * 0.18)
        let adjustedConfidence = min(0.99, max(0.1, track.beatConfidence - adjustmentPenalty))
        let phaseCorrection = Int((abs(percent) * 1.8).rounded())
        let phaseOffset = min(140, max(0, track.downbeatOffsetMilliseconds + phaseCorrection))

        return TempoAdjustment(
            originalBPM: track.bpm,
            adjustedBPM: adjustedBPM,
            targetCadence: cadence,
            speedRatio: ratio,
            speedChangePercent: percent,
            bpmDelta: bpmDelta,
            phaseOffsetMilliseconds: phaseOffset,
            confidence: adjustedConfidence
        )
    }
}

struct TrackMatch: Identifiable {
    let track: RunningTrack
    let cadence: Int
    let adjustment: TempoAdjustment

    var id: UUID { track.id }
    var score: Int { adjustment.score }
    var offsetMilliseconds: Int { adjustment.phaseOffsetMilliseconds }
    var tempoDistance: Int { adjustment.bpmDelta }

    var syncLabel: String {
        adjustment.qualityLabel
    }

    var matchReason: String {
        "1:1 retime \(adjustment.speedChangeLabel), \(Int(adjustment.confidence * 100))% beat confidence"
    }
}

struct DemoMusicCatalog {
    private static let generatedRights = AudioRights(
        status: .originalGenerated,
        licenseName: "Original generated demo audio",
        attribution: "Generated by Beatrun's local AVFoundation synthesis engine.",
        sourceDescription: "No external recording. Track metadata drives a local drum/bass loop in MetronomeEngine.swift.",
        sourceLink: "Beatrun/MetronomeEngine.swift",
        allowsTempoAdjustment: true
    )

    static let tracks: [RunningTrack] = [
        RunningTrack(title: "Easy Warmup", artist: "Beatrun Lab", bpm: 144, preference: .instrumental, genre: "Electronic", energy: 68, beatConfidence: 0.92, downbeatOffsetMilliseconds: 22, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Night Circuit", artist: "Beatrun Lab", bpm: 160, preference: .instrumental, genre: "Electronic", energy: 82, beatConfidence: 0.94, downbeatOffsetMilliseconds: 18, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Forward Motion", artist: "Beatrun Lab", bpm: 166, preference: .instrumental, genre: "Synth", energy: 78, beatConfidence: 0.91, downbeatOffsetMilliseconds: 32, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Steel Horizon", artist: "Beatrun Lab", bpm: 172, preference: .instrumental, genre: "Breakbeat", energy: 88, beatConfidence: 0.89, downbeatOffsetMilliseconds: 41, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Clean Stride", artist: "Beatrun Lab", bpm: 180, preference: .instrumental, genre: "House", energy: 90, beatConfidence: 0.97, downbeatOffsetMilliseconds: 8, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Blue Relay", artist: "Beatrun Lab", bpm: 188, preference: .instrumental, genre: "Dance", energy: 86, beatConfidence: 0.9, downbeatOffsetMilliseconds: 36, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Final Kick", artist: "Beatrun Lab", bpm: 198, preference: .instrumental, genre: "Dance", energy: 92, beatConfidence: 0.88, downbeatOffsetMilliseconds: 46, beatGridSource: "Curated 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Step Into Light", artist: "Beatrun Lab", bpm: 146, preference: .vocal, genre: "Pop", energy: 72, beatConfidence: 0.86, downbeatOffsetMilliseconds: 44, beatGridSource: "Vocal-style 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Hold the Pace", artist: "Beatrun Lab", bpm: 158, preference: .vocal, genre: "Indie Pop", energy: 79, beatConfidence: 0.88, downbeatOffsetMilliseconds: 27, beatGridSource: "Vocal-style 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Keep Breathing", artist: "Beatrun Lab", bpm: 168, preference: .vocal, genre: "Pop Rock", energy: 84, beatConfidence: 0.87, downbeatOffsetMilliseconds: 35, beatGridSource: "Vocal-style 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Run the Line", artist: "Beatrun Lab", bpm: 180, preference: .vocal, genre: "Dance Pop", energy: 91, beatConfidence: 0.92, downbeatOffsetMilliseconds: 12, beatGridSource: "Vocal-style 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "After the Turn", artist: "Beatrun Lab", bpm: 190, preference: .vocal, genre: "Alternative", energy: 83, beatConfidence: 0.85, downbeatOffsetMilliseconds: 52, beatGridSource: "Vocal-style 1:1 demo grid", rights: generatedRights),
        RunningTrack(title: "Finish Lights", artist: "Beatrun Lab", bpm: 198, preference: .vocal, genre: "Dance Pop", energy: 89, beatConfidence: 0.86, downbeatOffsetMilliseconds: 39, beatGridSource: "Vocal-style 1:1 demo grid", rights: generatedRights)
    ]

    static func recommendations(cadence: Int, preference: VocalPreference) -> [TrackMatch] {
        tracks
            .filter { $0.preference == preference }
            .compactMap { track in
                guard let adjustment = TempoAdjustment.analyze(track: track, cadence: cadence) else {
                    return nil
                }
                return TrackMatch(track: track, cadence: cadence, adjustment: adjustment)
            }
            .sorted {
                if $0.score == $1.score {
                    return abs($0.adjustment.speedChangePercent) < abs($1.adjustment.speedChangePercent)
                }
                return $0.score > $1.score
            }
    }
}

struct MusicDiscoveryService {
    func discover(cadence: Int, preference: VocalPreference) async throws -> [TrackMatch] {
        try await Task.sleep(for: .milliseconds(450))
        try Task.checkCancellation()
        let matches = DemoMusicCatalog.recommendations(cadence: cadence, preference: preference)
        try await Task.sleep(for: .milliseconds(350))
        try Task.checkCancellation()
        return matches
    }
}
