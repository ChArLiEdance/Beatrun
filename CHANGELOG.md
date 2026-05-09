# Changelog

All notable Beatrun uploads are recorded here.

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
