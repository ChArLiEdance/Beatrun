import Foundation
import Observation

@MainActor
@Observable
final class BeatrunModel {
    private(set) var cadence = 180

    private(set) var vocalPreference: VocalPreference = .instrumental

    private(set) var recommendations: [TrackMatch] = []
    private(set) var discoveryPhase: DiscoveryPhase = .ready
    private(set) var discoveryMessage = "Music library matching ready."
    private(set) var autoMatchMessage = "Best match updates when cadence, music type, or library access changes."
    private(set) var watchSyncStatus = "Watch sync starting"
    private(set) var musicLibraryState: MusicLibraryAccessState = .notDetermined
    private(set) var musicLibraryMessage = MusicLibraryAccessState.notDetermined.detail
    private(set) var scannedLibraryTrackCount = 0
    private(set) var tracksNeedingBPMCount = 0
    private(set) var metadataOnlyTrackCount = 0
    private(set) var retimeReadyTrackCount = 0
    private(set) var usingStarterFallback = true
    private(set) var searchCount = 0
    var selectedMatch: TrackMatch?
    let metronome = MetronomeEngine()

    var nowPlayingMatch: TrackMatch? {
        metronome.currentMatch ?? selectedMatch
    }

    var upcomingMatch: TrackMatch? {
        metronome.upcomingMatch
    }

    var musicLibraryActionTitle: String {
        switch musicLibraryState {
        case .notDetermined:
            "Authorize"
        case .authorized:
            "Rescan"
        case .denied, .restricted:
            "Settings"
        case .unavailable:
            "Retry"
        }
    }

    var musicLibraryActionSystemImage: String {
        switch musicLibraryState {
        case .notDetermined:
            "person.crop.circle.badge.checkmark"
        case .authorized:
            "arrow.clockwise"
        case .denied, .restricted:
            "gearshape"
        case .unavailable:
            "wifi.exclamationmark"
        }
    }

    var shouldOpenSettingsForMusicLibrary: Bool {
        musicLibraryState == .denied || musicLibraryState == .restricted
    }

    @ObservationIgnored private let discoveryService = MusicDiscoveryService()
    @ObservationIgnored private let musicLibraryService = MusicLibraryService()
    @ObservationIgnored private let watchSyncCoordinator = WatchSyncCoordinator()
    @ObservationIgnored private var discoveryTask: Task<Void, Never>?
    @ObservationIgnored private var scheduledDiscoveryTask: Task<Void, Never>?
    @ObservationIgnored private var watchStateTimer: Timer?
    @ObservationIgnored private var authorizedLibraryTracks: [RunningTrack] = []
    @ObservationIgnored private var didRunLaunchMusicLibraryFlow = false
    @ObservationIgnored private var shouldStartPlaybackAfterDiscovery = false

    init() {
        configureWatchSync()
        refreshRecommendations()
        publishWatchState()
    }

    func select(_ match: TrackMatch) {
        selectedMatch = match
        autoMatchMessage = "Manual selection: \(match.track.title)."
        metronome.setPlaybackQueue(current: match, candidates: recommendations)
        publishWatchState()
    }

    func setCadence(_ newValue: Int) {
        let clampedValue = min(max(newValue, 140), 200)
        guard cadence != clampedValue else { return }
        cadence = clampedValue
        metronome.cadence = clampedValue
        publishWatchState()
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

    func prepareMusicLibraryOnLaunch() {
        guard !didRunLaunchMusicLibraryFlow else { return }
        didRunLaunchMusicLibraryFlow = true
        refreshMusicLibraryAndDiscover(
            reason: "Connected to music library access flow.",
            requestAuthorizationIfNeeded: true,
            preferBestMatch: true
        )
    }

    func refreshMusicLibraryAfterSettingsReturn() {
        let currentState = musicLibraryService.authorizationState()
        guard currentState != musicLibraryState || currentState == .authorized else { return }
        refreshMusicLibraryAndDiscover(
            reason: "Music library permission changed.",
            requestAuthorizationIfNeeded: false,
            preferBestMatch: true
        )
    }

    func discoverMusic() {
        refreshMusicLibraryAndDiscover(
            reason: "Manual search requested.",
            requestAuthorizationIfNeeded: false,
            preferBestMatch: true
        )
    }

    func requestMusicLibraryAccess() {
        refreshMusicLibraryAndDiscover(
            reason: "Music library scan completed.",
            requestAuthorizationIfNeeded: true,
            preferBestMatch: true
        )
    }

    private func refreshMusicLibraryAndDiscover(
        reason: String,
        requestAuthorizationIfNeeded: Bool,
        preferBestMatch: Bool
    ) {
        discoveryTask?.cancel()
        scheduledDiscoveryTask?.cancel()
        scheduledDiscoveryTask = nil
        searchCount += 1
        discoveryPhase = .searching
        discoveryMessage = requestAuthorizationIfNeeded
            ? "Requesting system music library permission."
            : "Checking system music library authorization."
        autoMatchMessage = "Only tracks with BPM metadata and legal local playback are eligible."

        discoveryTask = Task {
            let snapshot = if requestAuthorizationIfNeeded {
                await musicLibraryService.requestSnapshot(preference: vocalPreference)
            } else {
                musicLibraryService.currentSnapshot(preference: vocalPreference)
            }
            guard !Task.isCancelled else { return }
            applyMusicLibrarySnapshot(snapshot)
            await runDiscovery(reason: reason, preferBestMatch: preferBestMatch)
        }
    }

    func togglePlayback() {
        metronome.toggle()
        updateWatchTicker()
        publishWatchState()
    }

    func startPlayback() {
        guard !discoveryPhase.isBusy else {
            shouldStartPlaybackAfterDiscovery = true
            autoMatchMessage = "Playback will start after music discovery finishes."
            publishWatchState()
            return
        }

        guard selectedMatch != nil else {
            shouldStartPlaybackAfterDiscovery = true
            discoverMusic()
            autoMatchMessage = "Playback will start after a legal match is selected."
            publishWatchState()
            return
        }

        guard !metronome.isRunning else {
            publishWatchState()
            return
        }
        shouldStartPlaybackAfterDiscovery = false
        metronome.start()
        updateWatchTicker()
        publishWatchState()
    }

    func stopPlayback() {
        guard metronome.isRunning else {
            publishWatchState()
            return
        }
        metronome.stop()
        updateWatchTicker()
        publishWatchState()
    }

    func refreshRecommendations() {
        recommendations = AuthorizedMusicCatalog.recommendations(cadence: cadence, preference: vocalPreference)
        applySelectionAfterDiscovery(preferBestMatch: true)
    }

#if DEBUG
    func simulateDeniedMusicLibraryForDemo() {
        let snapshot = MusicLibrarySnapshot(
            accessState: .denied,
            tracks: [],
            scannedCount: 0,
            tracksNeedingBPM: 0,
            metadataOnlyCount: 0,
            retimeReadyCount: 0
        )
        applyMusicLibrarySnapshot(snapshot)
        recommendations = AuthorizedMusicCatalog.recommendations(cadence: cadence, preference: vocalPreference)
        discoveryPhase = .ready
        discoveryMessage = "Music library permission denied. Showing imported/CC0 fallback matches."
        autoMatchMessage = "No system tracks are scanned until permission is granted."
        applySelectionAfterDiscovery(preferBestMatch: true)
        publishWatchState()
    }
#endif

    func publishWatchState() {
        let payload = makeWatchPayload()
        watchSyncCoordinator.publish(payload)
        watchSyncStatus = watchSyncCoordinator.connectionStatus
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
        searchCount += 1

        discoveryTask = Task {
            await runDiscovery(reason: reason, preferBestMatch: preferBestMatch)
        }
    }

    private func runDiscovery(reason: String, preferBestMatch: Bool) async {
        let cadence = cadence
        let preference = vocalPreference
        let libraryTracks = authorizedLibraryTracks
        let allowStarterFallback = usingStarterFallback
        discoveryPhase = .searching
        discoveryMessage = "\(reason) Finding authorized \(preference.title.lowercased()) tracks near \(cadence) SPM."

        do {
            let matches = try await discoveryService.discover(
                cadence: cadence,
                preference: preference,
                libraryTracks: libraryTracks,
                allowStarterFallback: allowStarterFallback
            )
            guard !Task.isCancelled else { return }
            discoveryPhase = .analyzing
            discoveryMessage = "Checking 1:1 BPM fit and tempo adjustment limits."

            try await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            recommendations = matches
            applySelectionAfterDiscovery(preferBestMatch: preferBestMatch)
            discoveryPhase = .ready
            discoveryMessage = discoveryReadyMessage(matchCount: matches.count)
            startPendingPlaybackIfNeeded()
            publishWatchState()
        } catch is CancellationError {
            return
        } catch {
            discoveryPhase = .failed(error.localizedDescription)
            discoveryMessage = error.localizedDescription
            publishWatchState()
        }
    }

    private func applyMusicLibrarySnapshot(_ snapshot: MusicLibrarySnapshot) {
        musicLibraryState = snapshot.accessState
        authorizedLibraryTracks = snapshot.tracks
        scannedLibraryTrackCount = snapshot.scannedCount
        tracksNeedingBPMCount = snapshot.tracksNeedingBPM
        metadataOnlyTrackCount = snapshot.metadataOnlyCount
        retimeReadyTrackCount = snapshot.retimeReadyCount
        usingStarterFallback = snapshot.tracks.isEmpty
        musicLibraryMessage = libraryMessage(for: snapshot)
    }

    private func libraryMessage(for snapshot: MusicLibrarySnapshot) -> String {
        switch snapshot.accessState {
        case .authorized:
            if snapshot.tracks.isEmpty {
                "Library authorized, but no BPM-tagged system tracks were found. Using imported MP3 and bundled CC0 instrumental tracks when available."
            } else {
                "\(snapshot.retimeReadyCount) retime-ready local tracks, \(snapshot.metadataOnlyCount) metadata-only tracks, \(snapshot.tracksNeedingBPM) need BPM."
            }
        case .denied:
            "Music library permission is off. Open Settings to scan system tracks; imported MP3 and bundled CC0 audio remain available."
        case .restricted:
            "Music library access is restricted by system policy. Imported MP3 and bundled CC0 audio remain available."
        default:
            snapshot.accessState.detail
        }
    }

    private func discoveryReadyMessage(matchCount: Int) -> String {
        if usingStarterFallback {
            return "Found \(matchCount) imported/CC0 fallback matches. Scan the library for user-authorized system tracks."
        }

        return "Found \(matchCount) user-authorized library matches."
    }

    private func applySelectionAfterDiscovery(preferBestMatch: Bool) {
        if preferBestMatch, let bestMatch = recommendations.first {
            selectedMatch = bestMatch
            autoMatchMessage = "Auto-selected \(bestMatch.track.title) for \(cadence) SPM."
            metronome.setPlaybackQueue(current: bestMatch, candidates: recommendations)
            publishWatchState()
        } else if let selectedMatch,
           let updatedSelection = recommendations.first(where: { $0.track.title == selectedMatch.track.title }) {
            self.selectedMatch = updatedSelection
            autoMatchMessage = "Kept \(updatedSelection.track.title) for \(cadence) SPM."
            metronome.setPlaybackQueue(current: updatedSelection, candidates: recommendations)
            publishWatchState()
        } else {
            selectedMatch = recommendations.first
            if let selectedMatch {
                autoMatchMessage = "Auto-selected \(selectedMatch.track.title) for \(cadence) SPM."
                metronome.setPlaybackQueue(current: selectedMatch, candidates: recommendations)
                publishWatchState()
            } else {
                autoMatchMessage = "No legal 1:1 match found within \(Int(TempoAdjustment.maximumAdjustmentPercent))% speed change."
                metronome.clearBackingTrack()
                publishWatchState()
            }
        }
    }

    private func startPendingPlaybackIfNeeded() {
        guard shouldStartPlaybackAfterDiscovery, selectedMatch != nil else { return }
        shouldStartPlaybackAfterDiscovery = false
        metronome.start()
        updateWatchTicker()
    }

    private func configureWatchSync() {
        watchSyncCoordinator.onCommand = { [weak self] command in
            Task { @MainActor in
                self?.handleWatchCommand(command)
            }
        }
        watchSyncCoordinator.onStatusChange = { [weak self] status in
            Task { @MainActor in
                self?.watchSyncStatus = status
            }
        }
    }

    private func handleWatchCommand(_ command: WatchControlMessage) {
        switch command.action {
        case .playPause:
            togglePlayback()
        case .start:
            startPlayback()
        case .stop:
            stopPlayback()
        case .cadenceDelta:
            setCadence(cadence + command.cadenceDelta)
        }
    }

    private func updateWatchTicker() {
        if metronome.isRunning {
            startWatchTicker()
        } else {
            watchStateTimer?.invalidate()
            watchStateTimer = nil
        }
    }

    private func startWatchTicker() {
        guard watchStateTimer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.publishWatchState()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        watchStateTimer = timer
    }

    private func makeWatchPayload() -> WatchSyncPayload {
        let current = nowPlayingMatch
        let upcoming = upcomingMatch
        return WatchSyncPayload(
            targetCadence: cadence,
            isPlaying: metronome.isRunning,
            playbackStatus: metronome.isRunning ? "Playing" : "Ready",
            syncStatus: metronome.syncStatus,
            currentTrack: current?.track.title ?? metronome.selectedTrackTitle,
            nextTrack: upcoming?.track.title ?? "No upcoming track",
            transitionStatus: metronome.transitionStatus,
            beatsRemaining: metronome.transitionBeatsRemaining,
            isCrossfading: metronome.isCrossfading,
            beatCount: metronome.beatCount,
            originalBPM: current?.adjustment.originalBPM ?? 0,
            adjustedBPM: current?.adjustment.adjustedBPM ?? cadence,
            speedChangeLabel: current?.adjustment.speedChangeLabel ?? "+0.0%",
            rightsStatus: current.map { "\($0.track.source.title) • \($0.track.rights.status.title)" } ?? "Music library",
            updatedAt: Date()
        )
    }
}
