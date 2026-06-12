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
- Visible target cadence, original BPM, adjusted BPM, speed change, match score, beat-grid confidence, and rights status.
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
8. Change cadence and watch Beatrun automatically rediscover the best legal 1:1 match.

## Project Files

- [Beatrun/Models.swift](Beatrun/Models.swift): demo catalog, rights metadata, 1:1 tempo-adjustment scoring.
- [Beatrun/BeatrunModel.swift](Beatrun/BeatrunModel.swift): app state, debounced rediscovery, best-match selection.
- [Beatrun/MetronomeEngine.swift](Beatrun/MetronomeEngine.swift): generated audio loop and metronome playback.
- [Beatrun/ContentView.swift](Beatrun/ContentView.swift): competition MVP UI.
- [CHANGELOG.md](CHANGELOG.md): upload history.
- [docs/dev-log.md](docs/dev-log.md): detailed development log with verification and risks.
- [docs/competition-roadmap.md](docs/competition-roadmap.md): competition preparation plan.
- [docs/submission-checklist.md](docs/submission-checklist.md): submission checklist.

## Requirements

- Xcode 26.4.1 or later recommended
- iOS 18 or later
- SwiftUI
- AVFoundation

## Build

```zsh
xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

## License

This project is released under the MIT License. Anyone using, copying, modifying, or distributing this software must keep the copyright notice and license text.
