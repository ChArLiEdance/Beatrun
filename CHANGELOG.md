# Changelog

All notable Beatrun uploads are recorded here.

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

- Added prototype beat-alignment analysis for direct, double-time, and half-time matching.
- Added alignment details to the playback preview, including match mode, confidence, phase offset, BPM delta, and beat grid visualization.
- Added mock 90 BPM tracks to test double-time cadence matching.
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
