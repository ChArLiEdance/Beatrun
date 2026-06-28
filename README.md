# Beatrun

Beatrun is an iOS and watchOS running cadence app for competition demos. The user chooses a target cadence, Beatrun recommends user-authorized music-library tracks or bundled CC0/manual-BPM fallback tracks, and the Watch can run a standalone workout with a synchronized metronome state.

Current MVP scope: 1:1 BPM matching only. Beatrun does not use double-time or half-time matching in this version, so a 90 BPM track is never used to match 180 SPM.

## What Works Now

- Target cadence selection from 140 to 200 steps per minute.
- Instrumental and vocal-style demo music preferences.
- MediaPlayer music-library permission flow with denial fallback.
- User-library matching for BPM-tagged local tracks, plus bundled CC0 instrumental starter tracks when no library tracks are available.
- 1:1 BPM matching with tempo adjustment capped at +/-10%.
- Automatic rediscovery and best-match selection after cadence or music type changes.
- Metronome click using AVFoundation while authorized music playback remains clearly labeled.
- Beat-boundary queue metadata with current/upcoming legal 1:1 matches.
- MVP-level transition countdown/crossfade state while the metronome clock keeps running.
- Polished iOS demo interface with a core home screen for target cadence, library state, playback controls, queue status, and a short recommendation preview.
- iOS Settings with English/Chinese language switching, default cadence, local preference reset, music-library summary, cadence rules, Watch sync status, HealthKit notes, and rights/source guidance.
- Dedicated iOS recommendation and tempo-detail screens for full track lists, sync grids, adjusted BPM, tempo shift, and rights/source status.
- WatchConnectivity-based companion state path for cadence, playback, sync, queue, transition, and basic Watch controls.
- watchOS standalone workout home UI with Start, Pause/Resume, End, target/current cadence, elapsed time, cadence +/-5 controls, and a compact playback status.
- watchOS Settings and Playback Details screens for language, Watch haptics, HealthKit status, iPhone sync state, HealthKit metrics, transition state, crossfade state, BPM, shift, and beat count.
- HealthKit `HKWorkoutSession` / `HKLiveWorkoutBuilder` path with CoreMotion cadence fallback on Watch.
- CHANGELOG and dev-log tracking for each upload phase.

## Legal Audio Strategy

The current product path uses user-authorized music sources. Beatrun does not scrape, download, decrypt, copy, stream, redistribute, or package unauthorized commercial music.

Supported source categories:

- Local MediaPlayer library tracks with BPM metadata and a local, non-DRM asset URL.
- Apple Music or cloud-library metadata when available, treated as metadata-only if DRM/cloud access prevents waveform analysis or tempo-adjusted playback.
- User-imported local files in future UI iterations.
- Explicit CC/royalty-free tracks or manually BPM-tagged starter metadata for competition fallback.

The current bundled instrumental starter tracks are CC0 files from Wikimedia Commons, transcoded from source Ogg to AAC `.m4a` for iOS playback. See [docs/audio-sources.md](docs/audio-sources.md) for source URLs, license metadata, BPM seed estimates, and processing notes.

Each track records:

- Original BPM
- Target-adjusted BPM
- Whether tempo adjustment is allowed
- License/source type
- Attribution
- Source link or source explanation
- Beat-grid source and confidence
- Whether waveform analysis is available
- Whether BPM is metadata-sourced or needs manual tagging
- Whether the item is metadata-only due to DRM/cloud limitations

The current starter catalog is documented in [docs/demo-catalog.md](docs/demo-catalog.md). The music-library access layer is [Beatrun/MusicLibraryService.swift](Beatrun/MusicLibraryService.swift).

## Matching Rules

For each track:

1. Beatrun compares the track's original BPM with the selected cadence.
2. It calculates the speed ratio needed to make the track match the cadence.
3. It rejects the track if the required speed change is outside +/-10%.
4. It rejects the track if its rights metadata does not allow tempo adjustment.
5. It rejects tracks without BPM metadata unless they have been manually tagged in a supported flow.
6. It ranks remaining tracks by tempo adjustment size and beat confidence.

No double-time or half-time matching is performed in this MVP.

## Demo Flow

1. Open the `Beatrun` scheme in Xcode.
2. Select an iPhone simulator.
3. Run the app.
4. Choose a target cadence such as 160, 170, 180, or 190 SPM.
5. Switch between Instrumental and Vocal-style.
6. Tap Scan in the Music Library card to request library permission.
7. Review authorized matches and their original/adjusted BPM, source, analysis mode, and tempo-shift percentage.
8. If permission is denied or the simulator has no library, review the bundled CC0 instrumental fallback state.
9. Press play to hear the synchronized metronome click and inspect the queue metadata countdown.
10. Open Settings from the gear button to switch between English, Chinese, or system language.
11. Open Recommendations or Tempo Details when judging needs the full match list, sync grid, and rights details.
12. Open the `BeatrunWatch` scheme to show the standalone Watch workout home, then open Watch Settings or Playback Details for HealthKit, queue, transition, and sync state.
13. Change cadence and watch Beatrun automatically rediscover the best legal 1:1 match.

## Queue Transition MVP

The iOS app keeps the metronome click as the master clock. Music-library metadata follows that clock:

- The queue keeps a current track and a next track.
- The next track is chosen from the same legal 1:1 recommendation list.
- The next track's adjusted BPM matches the target cadence.
- Transitions are scheduled on 8-beat boundaries.
- The UI shows a 4-beat crossfade/metadata transition state.
- Beat count is not reset during track transitions.

This is an MVP-level transition prototype for judging and screen recording. It is not presented as professional-grade seamless DJ mixing or as universal Apple Music retiming.

## Apple Watch Companion

The project includes a `BeatrunWatch` watchOS target. The iOS app and Watch app now share a lightweight WatchConnectivity payload model.

The Watch app can open without the iPhone and enter standalone workout mode. It shows:

- Target cadence
- Current cadence and target delta
- Workout elapsed time
- Compact playback and sync status on the home screen
- Start Workout, Pause/Resume, and End controls
- Cadence +/-5 controls
- Lightweight haptic feedback for local control taps
- Settings for language, target cadence rules, haptics, workout authorization, and iPhone sync state
- Playback Details for HealthKit metrics when available, current/next track, transition/crossfade status, beat count, adjusted BPM, and tempo shift

Current WatchConnectivity scope:

- iOS publishes playback state through `updateApplicationContext`.
- iOS can send reachable Watch updates through `sendMessage`.
- Watch controls send Play/Pause, Stop, and cadence delta commands back to iOS when the simulator/device pair is reachable.
- If the iPhone is not reachable, the Watch UI shows Standalone Mode / Standalone workout active and continues to run local workout state.

Current HealthKit / Workout Session scope:

- Watch requests HealthKit permission for running workouts plus heart rate, active energy, and walking/running distance reads.
- Watch starts an `HKWorkoutSession` and `HKLiveWorkoutBuilder` for running workouts.
- CoreMotion `CMPedometer` is used for live cadence when available.
- Simulator fallback keeps elapsed time, metronome state, and current cadence moving even when real sensors are unavailable.

Limitations:

- Live sync requires a paired, reachable iPhone/watchOS simulator or device pair.
- Real HealthKit metrics and live cadence are reliable only on a physical Apple Watch with permissions granted.
- Apple Music / cloud / DRM tracks may be metadata-only and are not waveform-analyzed or tempo-adjusted by this MVP.
- Bundled CC0 starter tracks are used only for the instrumental fallback path and should be re-checked against their source pages before public distribution.
- Tracks without BPM metadata are not recommended unless a supported manual-BPM flow supplies BPM.
- Local-file tempo-adjusted playback is still a limited MVP path; the UI labels metadata-only cases instead of pretending every Apple Music track can be retimed.

## Project Files

- [Beatrun/Models.swift](Beatrun/Models.swift): music source, rights metadata, BPM metadata, and 1:1 tempo-adjustment scoring.
- [Beatrun/MusicLibraryService.swift](Beatrun/MusicLibraryService.swift): MediaPlayer permission and BPM-tagged library track scanning.
- [Beatrun/Audio](Beatrun/Audio): bundled CC0 instrumental source Ogg files and iOS `.m4a` transcodes.
- [Beatrun/BeatrunModel.swift](Beatrun/BeatrunModel.swift): app state, debounced rediscovery, best-match selection, library fallback, Watch state publishing.
- [Beatrun/MetronomeEngine.swift](Beatrun/MetronomeEngine.swift): metronome clock, queue timing, and development fallback audio path.
- [Beatrun/ContentView.swift](Beatrun/ContentView.swift): competition MVP UI.
- [Beatrun/WatchSyncCoordinator.swift](Beatrun/WatchSyncCoordinator.swift): iOS WatchConnectivity state publisher and command receiver.
- [Shared/WatchSyncPayload.swift](Shared/WatchSyncPayload.swift): shared iOS/watchOS state and control message model.
- [Shared/AppLocalization.swift](Shared/AppLocalization.swift): shared language preference and English/Chinese interface copy table.
- [BeatrunWatch](BeatrunWatch): watchOS standalone workout UI, HealthKit/CoreMotion manager, local fallback state, and WatchConnectivity controller.
- [BeatrunWatch/BeatrunWatch.entitlements](BeatrunWatch/BeatrunWatch.entitlements): Watch HealthKit entitlement.
- [CHANGELOG.md](CHANGELOG.md): upload history.
- [docs/dev-log.md](docs/dev-log.md): detailed development log with verification and risks.
- [docs/competition-roadmap.md](docs/competition-roadmap.md): competition preparation plan.
- [docs/submission-checklist.md](docs/submission-checklist.md): submission checklist.

## Requirements

- Xcode 26.4.1 or later recommended
- iOS 18 or later
- SwiftUI
- AVFoundation
- MediaPlayer
- WatchConnectivity
- HealthKit
- CoreMotion

## Build

```zsh
xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

## Build Watch Companion

```zsh
xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' build
```

## License

This project is released under the MIT License. Anyone using, copying, modifying, or distributing this software must keep the copyright notice and license text.
