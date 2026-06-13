import Foundation
import MediaPlayer

enum MusicLibraryAccessState: Hashable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable

    var title: String {
        switch self {
        case .notDetermined:
            "Library not requested"
        case .authorized:
            "Music library authorized"
        case .denied:
            "Music library denied"
        case .restricted:
            "Music library restricted"
        case .unavailable:
            "Music library unavailable"
        }
    }

    var detail: String {
        switch self {
        case .notDetermined:
            "Tap Scan Library to request access and match tracks with BPM metadata."
        case .authorized:
            "Using local, non-DRM MediaPlayer tracks when BPM metadata is available."
        case .denied:
            "Permission was denied. Beatrun will use CC/manual-BPM fallback metadata and will not scan the system library."
        case .restricted:
            "Library access is restricted by system policy."
        case .unavailable:
            "MediaPlayer library access is unavailable in this environment."
        }
    }

    var systemImage: String {
        switch self {
        case .authorized:
            "checkmark.circle.fill"
        case .denied, .restricted, .unavailable:
            "exclamationmark.triangle.fill"
        case .notDetermined:
            "music.note.list"
        }
    }
}

struct MusicLibrarySnapshot: Hashable {
    let accessState: MusicLibraryAccessState
    let tracks: [RunningTrack]
    let scannedCount: Int
    let tracksNeedingBPM: Int
    let metadataOnlyCount: Int
    let retimeReadyCount: Int

    static let notRequested = MusicLibrarySnapshot(
        accessState: .notDetermined,
        tracks: [],
        scannedCount: 0,
        tracksNeedingBPM: 0,
        metadataOnlyCount: 0,
        retimeReadyCount: 0
    )
}

struct MusicLibraryService {
    func authorizationState() -> MusicLibraryAccessState {
        map(MPMediaLibrary.authorizationStatus())
    }

    func requestSnapshot(preference: VocalPreference) async -> MusicLibrarySnapshot {
        let status = await requestAuthorization()
        guard status == .authorized else {
            return MusicLibrarySnapshot(
                accessState: status,
                tracks: [],
                scannedCount: 0,
                tracksNeedingBPM: 0,
                metadataOnlyCount: 0,
                retimeReadyCount: 0
            )
        }

        return makeSnapshot(preference: preference)
    }

    func currentSnapshot(preference: VocalPreference) -> MusicLibrarySnapshot {
        guard authorizationState() == .authorized else {
            return .notRequested
        }

        return makeSnapshot(preference: preference)
    }

    private func requestAuthorization() async -> MusicLibraryAccessState {
        let current = MPMediaLibrary.authorizationStatus()
        if current != .notDetermined {
            return map(current)
        }

        return await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: map(status))
            }
        }
    }

    private func makeSnapshot(preference: VocalPreference) -> MusicLibrarySnapshot {
        let items = MPMediaQuery.songs().items ?? []
        var tracks: [RunningTrack] = []
        var needsBPM = 0
        var metadataOnly = 0
        var retimeReady = 0

        for item in items {
            let bpm = item.beatsPerMinute
            let assetURL = item.assetURL
            let hasBPM = bpm > 0
            let isLocalAsset = assetURL != nil
            let source: MusicSource = isLocalAsset ? .localLibrary : .appleMusic

            if !hasBPM {
                needsBPM += 1
                continue
            }

            if !isLocalAsset {
                metadataOnly += 1
            } else {
                retimeReady += 1
            }

            let rights = AudioRights(
                status: isLocalAsset ? .localLibrary : .appleMusicMetadata,
                licenseName: isLocalAsset ? "User library local asset" : "Apple Music metadata",
                attribution: item.artist ?? "User library",
                sourceDescription: isLocalAsset
                    ? "User-authorized MediaPlayer local asset."
                    : "Cloud or DRM-protected catalog item; use metadata only unless Apple APIs provide playable local access.",
                sourceLink: "MPMediaLibrary",
                allowsTempoAdjustment: isLocalAsset
            )

            tracks.append(
                RunningTrack(
                    title: item.title ?? "Untitled Track",
                    artist: item.artist ?? "Unknown Artist",
                    bpm: bpm,
                    preference: preferenceForItem(item, fallback: preference),
                    genre: item.genre ?? "Library",
                    energy: 75,
                    beatConfidence: isLocalAsset ? 0.78 : 0.62,
                    downbeatOffsetMilliseconds: 0,
                    beatGridSource: isLocalAsset ? "MediaPlayer BPM metadata" : "Apple Music metadata only",
                    rights: rights,
                    source: source,
                    playbackAssetURL: assetURL,
                    hasBPMMetadata: hasBPM,
                    waveformAnalysisAvailable: isLocalAsset,
                    isDRMProtected: !isLocalAsset,
                    requiresManualBPM: false
                )
            )
        }

        return MusicLibrarySnapshot(
            accessState: .authorized,
            tracks: tracks,
            scannedCount: items.count,
            tracksNeedingBPM: needsBPM,
            metadataOnlyCount: metadataOnly,
            retimeReadyCount: retimeReady
        )
    }

    private func preferenceForItem(_ item: MPMediaItem, fallback: VocalPreference) -> VocalPreference {
        let genre = (item.genre ?? "").lowercased()
        if genre.contains("instrumental") || genre.contains("electronic") || genre.contains("house") {
            return .instrumental
        }
        if genre.contains("podcast") || genre.contains("speech") {
            return fallback
        }
        return .vocal
    }

    private func map(_ status: MPMediaLibraryAuthorizationStatus) -> MusicLibraryAccessState {
        switch status {
        case .authorized:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        @unknown default:
            .unavailable
        }
    }
}
