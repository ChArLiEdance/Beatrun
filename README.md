# Beatrun

Beatrun is an iOS running cadence app for competition demos. The user chooses a target cadence, Beatrun recommends copyright-safe demo music, then plays a tempo-adjusted backing loop with a synchronized metronome click.

Current MVP scope: 1:1 BPM matching only. Beatrun does not use double-time or half-time matching in this version, so a 90 BPM track is never used to match 180 SPM.

## What Works Now

- Target cadence selection from 140 to 200 steps per minute.
- Instrumental and vocal-style demo music preferences.
- Offline demo catalog with generated, legal-for-demo playback.
- 1:1 BPM matching with tempo adjustment capped at +/-10%.
- Automatic rediscovery and best-match selection after cadence or music type changes.
- Generated backing loop plus metronome click using AVFoundation.
- Beat-boundary playback queue with current/upcoming demo tracks.
- MVP-level 4-beat crossfade between generated loops while the metronome clock keeps running.
- Polished iOS demo interface with a run-mix header, current track, next track, transition countdown, beat count, target cadence, adjusted BPM, tempo shift, and rights status.
- WatchConnectivity-based companion state path for cadence, playback, sync, queue, transition, and basic Watch controls.
- watchOS companion UI with Play/Pause, Stop, cadence +/-5 controls, transition state, crossfade state, BPM, shift, and beat count.
- CHANGELOG and dev-log tracking for each upload phase.

## Legal Audio Strategy

The MVP uses local generated demo audio only. Beatrun does not scrape, download, stream, redistribute, or package unauthorized commercial music.

Each demo track records:

- Original BPM
- Target-adjusted BPM
- Whether tempo adjustment is allowed
- License/source type
- Attribution
- Source link or source explanation
- Beat-grid source and confidence

The current demo catalog is documented in [docs/demo-catalog.md](docs/demo-catalog.md). The generated audio source is the local synthesis code in [Beatrun/MetronomeEngine.swift](Beatrun/MetronomeEngine.swift).

## Matching Rules

For each track:

1. Beatrun compares the track's original BPM with the selected cadence.
2. It calculates the speed ratio needed to make the track match the cadence.
3. It rejects the track if the required speed change is outside +/-10%.
4. It rejects the track if its rights metadata does not allow tempo adjustment.
5. It ranks remaining tracks by tempo adjustment size and beat confidence.

No double-time or half-time matching is performed in this MVP.

## Demo Flow

1. Open the `Beatrun` scheme in Xcode.
2. Select an iPhone simulator.
3. Run the app.
4. Choose a target cadence such as 160, 170, 180, or 190 SPM.
5. Switch between Instrumental and Vocal-style.
6. Review recommended demo tracks and their original/adjusted BPM.
7. Press play to hear the generated backing loop and synchronized metronome click.
8. Watch the queue panel show the upcoming track and beat countdown to the next transition.
9. Open the `BeatrunWatch` scheme to show the Watch companion view with cadence, queue, transition, and control state.
10. Change cadence and watch Beatrun automatically rediscover the best legal 1:1 match.

## Queue Transition MVP

The iOS app keeps the metronome click as the master clock. Demo music follows that clock:

- The queue keeps a current track and a preloaded next track.
- The next track is chosen from the same legal 1:1 recommendation list.
- The next track's adjusted BPM matches the target cadence.
- Transitions are scheduled on 8-beat boundaries.
- The generated backing loops use a basic 4-beat crossfade.
- Beat count is not reset during track transitions.

This is an MVP-level transition prototype for judging and screen recording. It is not presented as professional-grade seamless DJ mixing.

## Apple Watch Companion

The project includes a `BeatrunWatch` watchOS target. The iOS app and Watch app now share a lightweight WatchConnectivity payload model.

The Watch companion shows:

- Target cadence
- Playback and sync status
- Current track
- Next track
- Transition / crossfade status
- Beat count, adjusted BPM, and tempo shift
- Play/Pause and Stop controls
- Cadence +/-5 controls
- Lightweight haptic feedback for local control taps

Current WatchConnectivity scope:

- iOS publishes playback state through `updateApplicationContext`.
- iOS can send reachable Watch updates through `sendMessage`.
- Watch controls send Play/Pause, Stop, and cadence delta commands back to iOS when the simulator/device pair is reachable.
- If the iPhone is not reachable, the Watch UI keeps a local fallback state so the competition demo screen remains usable.

Limitations:

- Live sync requires a paired, reachable iPhone/watchOS simulator or device pair.
- HealthKit and Workout Session are not implemented yet.
- The Watch UI does not claim real workout metrics or real-time heart-rate/cadence sensing.

## Project Files

- [Beatrun/Models.swift](Beatrun/Models.swift): demo catalog, rights metadata, 1:1 tempo-adjustment scoring.
- [Beatrun/BeatrunModel.swift](Beatrun/BeatrunModel.swift): app state, debounced rediscovery, best-match selection, Watch state publishing.
- [Beatrun/MetronomeEngine.swift](Beatrun/MetronomeEngine.swift): generated audio loop and metronome playback.
- [Beatrun/ContentView.swift](Beatrun/ContentView.swift): competition MVP UI.
- [Beatrun/WatchSyncCoordinator.swift](Beatrun/WatchSyncCoordinator.swift): iOS WatchConnectivity state publisher and command receiver.
- [Shared/WatchSyncPayload.swift](Shared/WatchSyncPayload.swift): shared iOS/watchOS state and control message model.
- [BeatrunWatch](BeatrunWatch): watchOS companion UI, local fallback state, and WatchConnectivity controller.
- [CHANGELOG.md](CHANGELOG.md): upload history.
- [docs/dev-log.md](docs/dev-log.md): detailed development log with verification and risks.
- [docs/competition-roadmap.md](docs/competition-roadmap.md): competition preparation plan.
- [docs/submission-checklist.md](docs/submission-checklist.md): submission checklist.

## Requirements

- Xcode 26.4.1 or later recommended
- iOS 18 or later
- SwiftUI
- AVFoundation
- WatchConnectivity

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
