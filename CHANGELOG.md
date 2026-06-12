# Changelog

All notable Beatrun uploads are recorded here.

## 2026-06-12 - Competition MVP 1:1 tempo matching

### Added

- Added debounced automatic music rediscovery when cadence or music type changes.
- Added automatic best-match selection after rediscovery so cadence changes switch to the most suitable preview track.
- Added an auto-match status line to the discovery panel.
- Added an offline demo catalog with explicit beat-grid offsets, grid confidence, and audio rights labels.
- Added match-reason and copyright-status details to the discovery and sync UI.
- Added README, demo-catalog, and dev-log documentation for the competition MVP.

### Changed

- Replaced the legacy alternate-tempo prototype with 1:1 BPM matching only.
- Added +/-10% tempo-adjustment filtering so recommendations only include legal 1:1 matches.
- Updated generated backing-loop playback to use the adjusted BPM for the selected target cadence.

### Verified

- Built successfully with `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' build`.
- Built, installed, launched, and screenshot-verified on the iPhone 17 iOS 26.5 simulator.

### Risk

- Demo audio is locally generated for competition safety; real royalty-free or CC audio import remains future work.

## 2026-05-10 - Synced playback start

### Added

- Added a synced playback-start prototype that delays the first metronome click by the selected track's beat-alignment offset.
- Added visible playback sync status and start-offset details to the preview panel.

### Verified

- Built successfully with `xcodebuild` for the iPhone 17 simulator.
- Launched in the iPhone 17 simulator and verified playback state, beat counting, and sync-status updates.

## 2026-05-10 - Music discovery prototype

### Added

- Added a music-discovery flow prototype with searching, beat-analysis, ready, and failure states.
- Added a manual search-again action in the recommendations panel.
- Added generated preview provider labels and usage notes so future licensed providers can fit the same UI.

### Verified

- Built successfully with `xcodebuild` for the iPhone 17 simulator.
- Installed and launched successfully in the iPhone 17 simulator.

## 2026-05-09 - Beat alignment and generated backing loop

### Added

- Added the original prototype beat-alignment analysis.
- Added alignment details to the playback preview, including confidence, phase offset, BPM delta, and beat grid visualization.
- Added early low-BPM test tracks for alternate-tempo experiments. These were removed from the competition MVP on 2026-06-12.
- Added a generated backing music loop so prototype playback includes both music and metronome audio.
- Added separate volume controls for generated music and metronome click.

### Verified

- Built successfully with `xcodebuild` for the iPhone 17 simulator.
- Installed and launched successfully in the iPhone 17 simulator.

## 2026-05-09 - Metronome audio

### Added

- Added an AVFoundation-based metronome click generator.
- Added metronome audio status and volume controls to the prototype UI.

### Changed

- Replaced silent beat counting with generated click audio for local prototype testing.

### Verified

- Built successfully with `xcodebuild` for the iPhone 17 simulator.
- Installed and launched successfully in the iPhone 17 simulator.

## 2026-05-09

### Added

- Built the first interactive SwiftUI prototype.
- Added cadence selection with a slider and 160 / 170 / 180 / 190 quick presets.
- Added instrumental and vocal music preference switching.
- Added a mock running music catalog with BPM, genre, energy, and beat-confidence metadata.
- Added cadence-based track recommendation scoring.
- Added a sync preview panel with selected track, match score, BPM delta, simulated offset, and beat count.
- Added a basic metronome state engine for prototype interaction.
- Added a shared Xcode scheme so the project runs more reliably from Xcode.

### Fixed

- Reworked cadence and music preference updates to avoid SwiftUI state-update issues during interaction.
- Removed the temporary system click sound from the prototype metronome to avoid simulator/runtime interaction errors.

### Verified

- Built successfully with `xcodebuild` for the iPhone 17 simulator.
- Installed and launched successfully in the iPhone 17 simulator.
