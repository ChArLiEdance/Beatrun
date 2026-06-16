import Foundation

private struct ImportedAudioDescriptor: Hashable {
    let title: String
    let artist: String
    let resourceName: String
    let fileName: String
    let genre: String
    let energy: Int
    let downbeatOffsetMilliseconds: Int
}

actor ImportedAudioLibrary {
    static let shared = ImportedAudioLibrary()

    private var cachedTracks: [RunningTrack]?

    func tracks() async -> [RunningTrack] {
        if let cachedTracks {
            return cachedTracks
        }

        var analyzedTracks: [RunningTrack] = []
        analyzedTracks.reserveCapacity(Self.descriptors.count)
        for descriptor in Self.descriptors {
            if let track = await Self.makeTrack(descriptor) {
                analyzedTracks.append(track)
            }
        }
        cachedTracks = analyzedTracks
        return analyzedTracks
    }

    private static let descriptors: [ImportedAudioDescriptor] = [
        ImportedAudioDescriptor(title: "Nastelbom Instrumental", artist: "Nastelbom", resourceName: "nastelbom-instrumental-495889", fileName: "nastelbom-instrumental-495889.mp3", genre: "User import / Instrumental", energy: 82, downbeatOffsetMilliseconds: 20),
        ImportedAudioDescriptor(title: "Nastelbom Instrumental Music", artist: "Nastelbom", resourceName: "nastelbom-instrumental-instrumental-music-501717", fileName: "nastelbom-instrumental-instrumental-music-501717.mp3", genre: "User import / Instrumental", energy: 78, downbeatOffsetMilliseconds: 24),
        ImportedAudioDescriptor(title: "The Mountain", artist: "The Mountain", resourceName: "the_mountain-instrumental-513154", fileName: "the_mountain-instrumental-513154.mp3", genre: "User import / Instrumental", energy: 72, downbeatOffsetMilliseconds: 32),
        ImportedAudioDescriptor(title: "The Mountain 508025", artist: "The Mountain", resourceName: "the_mountain-instrumental-508025", fileName: "the_mountain-instrumental-508025.mp3", genre: "User import / Instrumental", energy: 76, downbeatOffsetMilliseconds: 28),
        ImportedAudioDescriptor(title: "Leberch Piano Instrumental", artist: "Leberch", resourceName: "leberch-instrumental-instrumental-piano-music-522790", fileName: "leberch-instrumental-instrumental-piano-music-522790.mp3", genre: "User import / Piano", energy: 65, downbeatOffsetMilliseconds: 36),
        ImportedAudioDescriptor(title: "Leberch Instrumental", artist: "Leberch", resourceName: "leberch-instrumental-516791", fileName: "leberch-instrumental-516791.mp3", genre: "User import / Instrumental", energy: 74, downbeatOffsetMilliseconds: 30),
        ImportedAudioDescriptor(title: "AtlasAudio Instrumental", artist: "AtlasAudio", resourceName: "atlasaudio-instrumental-519455", fileName: "atlasaudio-instrumental-519455.mp3", genre: "User import / Instrumental", energy: 84, downbeatOffsetMilliseconds: 22)
    ]

    private static func makeTrack(_ descriptor: ImportedAudioDescriptor) async -> RunningTrack? {
        guard let url = Bundle.main.url(forResource: descriptor.resourceName, withExtension: "mp3") else {
            return nil
        }

        guard let analysis = try? await AudioBPMAnalyzer.analyze(url: url) else {
            return nil
        }

        let rights = AudioRights(
            status: .importedFile,
            licenseName: "User-provided local import",
            attribution: "Imported by the Beatrun user.",
            sourceDescription: "User-provided MP3 copied into Beatrun as a local music-library test file.",
            sourceLink: "Beatrun/Audio/UserLibrary/\(descriptor.fileName)",
            allowsTempoAdjustment: true
        )

        return RunningTrack(
            title: descriptor.title,
            artist: descriptor.artist,
            bpm: analysis.bpm,
            preference: .instrumental,
            genre: descriptor.genre,
            energy: descriptor.energy,
            beatConfidence: analysis.confidence,
            downbeatOffsetMilliseconds: descriptor.downbeatOffsetMilliseconds,
            beatGridSource: analysis.source,
            rights: rights,
            source: .importedFile,
            playbackAssetURL: url,
            hasBPMMetadata: true,
            waveformAnalysisAvailable: true,
            isDRMProtected: false,
            requiresManualBPM: false
        )
    }
}
