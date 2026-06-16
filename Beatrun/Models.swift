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
            "Instrumental library tracks with clear BPM metadata."
        case .vocal:
            "Vocal-style library tracks with legal playback metadata."
        }
    }
}

enum MusicSource: String, Hashable {
    case localLibrary
    case appleMusic
    case importedFile
    case ccLicensed
    case generatedPreview

    var title: String {
        switch self {
        case .localLibrary:
            "Local Library"
        case .appleMusic:
            "Apple Music"
        case .importedFile:
            "Imported File"
        case .ccLicensed:
            "CC Licensed"
        case .generatedPreview:
            "Generated Fallback"
        }
    }

    var usageNote: String {
        switch self {
        case .localLibrary:
            "Uses the user's authorized MediaPlayer library metadata and local, non-DRM asset URLs when available."
        case .appleMusic:
            "Apple Music catalog or cloud tracks may provide metadata, but DRM/cloud assets are not waveform-analyzed or retimed by this MVP."
        case .importedFile:
            "User-imported audio can be analyzed or manually tagged when the user provides a legal local file."
        case .ccLicensed:
            "Explicitly licensed CC/royalty-free audio or metadata for competition fallback, with source and license recorded per track."
        case .generatedPreview:
            "Generated synthesis is kept only as a development fallback, not the primary product music path."
        }
    }
}

enum AudioRightsStatus: String, Hashable {
    case localLibrary
    case appleMusicMetadata
    case importedFile
    case ccLicensed
    case originalGenerated

    var title: String {
        switch self {
        case .localLibrary:
            "User library"
        case .appleMusicMetadata:
            "Metadata only"
        case .importedFile:
            "User import"
        case .ccLicensed:
            "CC licensed"
        case .originalGenerated:
            "Generated in app"
        }
    }

    var note: String {
        switch self {
        case .localLibrary:
            "Playback depends on user authorization and a local non-DRM asset URL."
        case .appleMusicMetadata:
            "Can be used for BPM matching metadata, but not for waveform analysis or tempo-adjusted playback unless Apple APIs allow it."
        case .importedFile:
            "The user supplied the file, so Beatrun can analyze or retime it when the format is supported."
        case .ccLicensed:
            "Allowed for demo matching when the bundled or imported file license permits tempo changes."
        case .originalGenerated:
            "Development-only fallback. It is not the primary music library path."
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
    let source: MusicSource
    let playbackAssetURL: URL?
    let hasBPMMetadata: Bool
    let waveformAnalysisAvailable: Bool
    let isDRMProtected: Bool
    let requiresManualBPM: Bool

    var canUseForTempoAdjustedPlayback: Bool {
        rights.allowsTempoAdjustment && playbackAssetURL != nil && !isDRMProtected
    }

    var playbackCapabilityLabel: String {
        if requiresManualBPM {
            "Needs BPM"
        } else if canUseForTempoAdjustedPlayback {
            "Retiming ready"
        } else if source == .appleMusic {
            "Metadata only"
        } else {
            "Import audio"
        }
    }

    var analysisLabel: String {
        waveformAnalysisAvailable ? "Waveform OK" : "BPM metadata"
    }

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
        guard track.hasBPMMetadata, !track.requiresManualBPM else { return nil }
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

struct AuthorizedMusicCatalog {
    private static func bundledAudioURL(_ resourceName: String) -> URL? {
        Bundle.main.url(forResource: resourceName, withExtension: "m4a")
    }

    private static func cc0Rights(
        attribution: String,
        sourceLink: String,
        sourceDescription: String
    ) -> AudioRights {
        AudioRights(
            status: .ccLicensed,
            licenseName: "CC0 1.0 Public Domain Dedication",
            attribution: attribution,
            sourceDescription: sourceDescription,
            sourceLink: sourceLink,
            allowsTempoAdjustment: true
        )
    }

    private static let metadataFallbackRights = AudioRights(
        status: .ccLicensed,
        licenseName: "Competition starter metadata",
        attribution: "Beatrun starter metadata for CC or user-imported files.",
        sourceDescription: "No commercial recording is bundled. Replace each entry with a user-authorized local file or CC licensed asset before distribution.",
        sourceLink: "docs/demo-catalog.md",
        allowsTempoAdjustment: true
    )

    static let tracks: [RunningTrack] = [
        RunningTrack(
            title: "Go to the Picnic",
            artist: "Loyalty Freak Music",
            bpm: 147,
            preference: .instrumental,
            genre: "Folk / Soundtrack",
            energy: 72,
            beatConfidence: 0.72,
            downbeatOffsetMilliseconds: 34,
            beatGridSource: "Estimated from local onset analysis of bundled CC0 audio",
            rights: cc0Rights(
                attribution: "Go to the Picnic by Loyalty Freak Music",
                sourceLink: "https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_01_-_Go_to_the_Picnic.ogg",
                sourceDescription: "Downloaded from Wikimedia Commons; metadata reports CC0/Public Domain Dedication."
            ),
            source: .ccLicensed,
            playbackAssetURL: bundledAudioURL("go_to_the_picnic"),
            hasBPMMetadata: true,
            waveformAnalysisAvailable: true,
            isDRMProtected: false,
            requiresManualBPM: false
        ),
        RunningTrack(
            title: "High Technologic Beat Explosion",
            artist: "Loyalty Freak Music",
            bpm: 147,
            preference: .instrumental,
            genre: "Electronic / Techno",
            energy: 88,
            beatConfidence: 0.72,
            downbeatOffsetMilliseconds: 28,
            beatGridSource: "Estimated from local onset analysis of bundled CC0 audio",
            rights: cc0Rights(
                attribution: "High Technologic Beat Explosion by Loyalty Freak Music",
                sourceLink: "https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_02_-_High_Technologic_Beat_Explosion.ogg",
                sourceDescription: "Downloaded from Wikimedia Commons; metadata reports CC0/Public Domain Dedication."
            ),
            source: .ccLicensed,
            playbackAssetURL: bundledAudioURL("high_technologic_beat_explosion"),
            hasBPMMetadata: true,
            waveformAnalysisAvailable: true,
            isDRMProtected: false,
            requiresManualBPM: false
        ),
        RunningTrack(
            title: "Waiting TTTT",
            artist: "Loyalty Freak Music",
            bpm: 166,
            preference: .instrumental,
            genre: "Electronic",
            energy: 80,
            beatConfidence: 0.66,
            downbeatOffsetMilliseconds: 36,
            beatGridSource: "Estimated from local onset analysis of bundled CC0 audio",
            rights: cc0Rights(
                attribution: "Waiting TTTT by Loyalty Freak Music",
                sourceLink: "https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_05_-_Waiting_TTTT.ogg",
                sourceDescription: "Downloaded from Wikimedia Commons; metadata reports CC0/Public Domain Dedication."
            ),
            source: .ccLicensed,
            playbackAssetURL: bundledAudioURL("waiting_tttt"),
            hasBPMMetadata: true,
            waveformAnalysisAvailable: true,
            isDRMProtected: false,
            requiresManualBPM: false
        ),
        RunningTrack(
            title: "Level 1",
            artist: "Monplaisir",
            bpm: 178,
            preference: .instrumental,
            genre: "Rock / Game soundtrack",
            energy: 90,
            beatConfidence: 0.86,
            downbeatOffsetMilliseconds: 18,
            beatGridSource: "Estimated from local onset analysis of bundled CC0 audio",
            rights: cc0Rights(
                attribution: "Level 1 by Monplaisir",
                sourceLink: "https://commons.wikimedia.org/wiki/File:Monplaisir_-_04_-_Level_1.ogg",
                sourceDescription: "Downloaded from Wikimedia Commons; metadata reports CC0/Public Domain Dedication."
            ),
            source: .ccLicensed,
            playbackAssetURL: bundledAudioURL("level_1"),
            hasBPMMetadata: true,
            waveformAnalysisAvailable: true,
            isDRMProtected: false,
            requiresManualBPM: false
        ),
        RunningTrack(
            title: "Level 3",
            artist: "Monplaisir",
            bpm: 206,
            preference: .instrumental,
            genre: "Electronic / Game soundtrack",
            energy: 92,
            beatConfidence: 0.82,
            downbeatOffsetMilliseconds: 20,
            beatGridSource: "Estimated from local onset analysis of bundled CC0 audio",
            rights: cc0Rights(
                attribution: "Level 3 by Monplaisir",
                sourceLink: "https://commons.wikimedia.org/wiki/File:Monplaisir_-_06_-_Level_3.ogg",
                sourceDescription: "Downloaded from Wikimedia Commons; metadata reports CC0/Public Domain Dedication."
            ),
            source: .ccLicensed,
            playbackAssetURL: bundledAudioURL("level_3"),
            hasBPMMetadata: true,
            waveformAnalysisAvailable: true,
            isDRMProtected: false,
            requiresManualBPM: false
        ),
        RunningTrack(title: "Step Into Light", artist: "CC Starter Pack", bpm: 146, preference: .vocal, genre: "Pop", energy: 72, beatConfidence: 0.86, downbeatOffsetMilliseconds: 44, beatGridSource: "Vocal-style 1:1 starter grid", rights: metadataFallbackRights, source: .ccLicensed, playbackAssetURL: nil, hasBPMMetadata: true, waveformAnalysisAvailable: false, isDRMProtected: false, requiresManualBPM: false),
        RunningTrack(title: "Hold the Pace", artist: "CC Starter Pack", bpm: 158, preference: .vocal, genre: "Indie Pop", energy: 79, beatConfidence: 0.88, downbeatOffsetMilliseconds: 27, beatGridSource: "Vocal-style 1:1 starter grid", rights: metadataFallbackRights, source: .ccLicensed, playbackAssetURL: nil, hasBPMMetadata: true, waveformAnalysisAvailable: false, isDRMProtected: false, requiresManualBPM: false),
        RunningTrack(title: "Keep Breathing", artist: "CC Starter Pack", bpm: 168, preference: .vocal, genre: "Pop Rock", energy: 84, beatConfidence: 0.87, downbeatOffsetMilliseconds: 35, beatGridSource: "Vocal-style 1:1 starter grid", rights: metadataFallbackRights, source: .ccLicensed, playbackAssetURL: nil, hasBPMMetadata: true, waveformAnalysisAvailable: false, isDRMProtected: false, requiresManualBPM: false),
        RunningTrack(title: "Run the Line", artist: "CC Starter Pack", bpm: 180, preference: .vocal, genre: "Dance Pop", energy: 91, beatConfidence: 0.92, downbeatOffsetMilliseconds: 12, beatGridSource: "Vocal-style 1:1 starter grid", rights: metadataFallbackRights, source: .ccLicensed, playbackAssetURL: nil, hasBPMMetadata: true, waveformAnalysisAvailable: false, isDRMProtected: false, requiresManualBPM: false),
        RunningTrack(title: "After the Turn", artist: "CC Starter Pack", bpm: 190, preference: .vocal, genre: "Alternative", energy: 83, beatConfidence: 0.85, downbeatOffsetMilliseconds: 52, beatGridSource: "Vocal-style 1:1 starter grid", rights: metadataFallbackRights, source: .ccLicensed, playbackAssetURL: nil, hasBPMMetadata: true, waveformAnalysisAvailable: false, isDRMProtected: false, requiresManualBPM: false),
        RunningTrack(title: "Finish Lights", artist: "CC Starter Pack", bpm: 198, preference: .vocal, genre: "Dance Pop", energy: 89, beatConfidence: 0.86, downbeatOffsetMilliseconds: 39, beatGridSource: "Vocal-style 1:1 starter grid", rights: metadataFallbackRights, source: .ccLicensed, playbackAssetURL: nil, hasBPMMetadata: true, waveformAnalysisAvailable: false, isDRMProtected: false, requiresManualBPM: false)
    ]

    static func recommendations(cadence: Int, preference: VocalPreference) -> [TrackMatch] {
        recommendations(from: tracks, cadence: cadence, preference: preference)
    }

    static func recommendations(
        from tracks: [RunningTrack],
        cadence: Int,
        preference: VocalPreference
    ) -> [TrackMatch] {
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
    func discover(
        cadence: Int,
        preference: VocalPreference,
        libraryTracks: [RunningTrack],
        allowStarterFallback: Bool
    ) async throws -> [TrackMatch] {
        try await Task.sleep(for: .milliseconds(450))
        try Task.checkCancellation()
        let libraryMatches = AuthorizedMusicCatalog.recommendations(
            from: libraryTracks,
            cadence: cadence,
            preference: preference
        )
        let matches = libraryMatches.isEmpty && allowStarterFallback
            ? AuthorizedMusicCatalog.recommendations(cadence: cadence, preference: preference)
            : libraryMatches
        try await Task.sleep(for: .milliseconds(350))
        try Task.checkCancellation()
        return matches
    }
}
