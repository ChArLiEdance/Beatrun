# Changelog

All notable Beatrun uploads are recorded here.

## 2026-06-13 - Watch standalone workout and music library matching

### Added

- Added `MusicLibraryService` using MediaPlayer authorization and BPM-tagged local library scanning.
- Added source-aware track metadata for Local Library, Apple Music metadata, Imported File, CC Licensed, and development fallback sources.
- Added music-library permission, denial, BPM-missing, metadata-only, and retime-ready status UI on iOS.
- Added Watch `WatchWorkoutManager` with HealthKit authorization, `HKWorkoutSession`, `HKLiveWorkoutBuilder`, and CoreMotion cadence fallback.
- Added Watch HealthKit entitlements plus HealthKit, motion, and music-library usage descriptions.
- Added Watch standalone workout UI with Start Workout, Pause/Resume, End, elapsed time, current cadence, target delta, heart rate, energy, and distance fields.

### Changed

- Changed discovery to prefer user-authorized library tracks and use CC/manual-BPM starter metadata only as fallback.
- Removed generated-loop wording from the primary product path; the metronome remains active while authorized audio limitations are labeled honestly.
- Kept matching restricted to 1:1 BPM with a +/-10% tempo-change cap and no double-time/half-time implementation.
- Updated iOS status cards and recommendation rows to show source, analysis availability, DRM/metadata-only fallback, and tempo-adjustment capability.
- Updated WatchConnectivity behavior so the Watch shows Standalone Mode instead of waiting indefinitely when the iPhone is unreachable.

### Verified

- Built iOS successfully with `xcodebuild -quiet -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-library-ios build`.
- Built watchOS successfully with `xcodebuild -quiet -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-library-watch build`.
- Linted the Xcode project and Watch entitlements with `plutil -lint`.
- Installed and launched the iOS app on an iPhone 17 iOS 26.5 simulator.
- Installed and launched the Watch app on an Apple Watch Ultra 3 watchOS 26.5 simulator.
- Captured screenshots at `/private/tmp/beatrun-library-ios-main.png`, `/private/tmp/beatrun-library-ios-library.png`, `/private/tmp/beatrun-library-ios-workout-sync.png`, `/private/tmp/beatrun-library-watch-standalone.png`, and `/private/tmp/beatrun-library-watch-running.png`.
- Ran source audits for 1:1-only matching, +/-10% tempo limits, no double-time/half-time implementation, BPM-metadata rejection, and generated-loop wording removal from the primary product path.

### Risk

- Real HealthKit metrics and live cadence require a physical Apple Watch with permissions granted; simulator uses fallback cadence/elapsed-time behavior.
- Apple Music/cloud/DRM items are metadata-only unless Apple APIs expose legal local playback and analysis access.
- Local-file tempo-adjusted playback is still a limited MVP path; the UI avoids claiming universal Apple Music retiming.
- Watch simulator Health permission pregrant returned `Operation not permitted`; normal Start Workout reaches the Health prompt, while the DEBUG screenshot path uses local fallback metrics.

## 2026-06-12 - Watch companion polish and iOS demo UI

### Added

- Added shared Watch sync payloads for iOS and watchOS state exchange.
- Added iOS `WatchSyncCoordinator` using WatchConnectivity application context and control messages.
- Added Watch `WatchConnectivityController` to receive iOS playback state and send Play/Pause, Stop, and cadence +/-5 controls.
- Added lightweight Watch haptic feedback for local control taps.
- Added a more compact Watch UI for cadence, playback state, sync state, current track, next track, transition countdown, crossfade state, BPM, shift, and beat count.

### Changed

- Polished the iOS first screen with a clearer run-mix header, cadence safety chips, Now Playing hierarchy, stronger next-track transition card, and easier-to-scan recommendation rows.
- Routed iOS playback controls through `BeatrunModel` so Watch sync publishes state after local Play/Pause actions.
- Updated the competition readiness panel to show the Watch companion as sync-ready.

### Verified

- Built iOS successfully with `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-polish-ios build`.
- Built watchOS successfully with `xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-polish-watch build`.
- Installed and launched the iOS app on the paired iPhone 17 simulator.
- Installed and launched the Watch app on the paired Apple Watch Ultra 3 simulator.
- Captured final demo screenshots at `/private/tmp/beatrun-polish-ios-main.png`, `/private/tmp/beatrun-polish-ios-transition.png`, and `/private/tmp/beatrun-polish-watch-main.png`.
- Re-ran source audits for 1:1-only matching, +/-10% tempo limits, no double-time/half-time implementation, and preserved beat count across crossfade completion.

### Risk

- WatchConnectivity is implemented at the application-context/control-message layer, but live simulator state sync depends on having a paired, reachable iPhone/watchOS simulator pair.
- HealthKit and Workout Session are still reserved for a later implementation.
- There is still no XCTest coverage for WatchConnectivity commands or queue timing.

## 2026-06-12 - Synced queue transitions and Watch scaffold

### Added

- Added a beat-synced playback queue with current and upcoming 1:1 tempo-matched demo tracks.
- Added next-track preloading and queue status in the iOS UI.
- Added MVP-level 4-beat crossfade scheduled on 8-beat boundaries.
- Added transition UI showing next track, remaining beats, preload state, and crossfade state.
- Added a `BeatrunWatch` watchOS scaffold target with mock cadence, sync, queue, transition, and Play/Pause state.
- Added a shared `BeatrunWatch` Xcode scheme for watchOS simulator builds.

### Changed

- Kept the metronome click timer as the master clock during track transitions.
- Kept beat count running through queue transitions instead of resetting on crossfade.
- Declared the Watch app's companion bundle identifier so the scaffold can install on a watchOS simulator.

### Verified

- Linted the Xcode project file with `plutil -lint Beatrun.xcodeproj/project.pbxproj`.
- Built the iOS app successfully with `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-final-ios build`.
- Built the watchOS scaffold successfully with `xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-final-watch build`.
- Installed and launched the iOS app on an iPhone 17 iOS 26.5 simulator.
- Installed and launched the Watch scaffold on an Apple Watch Series 11 watchOS 26.5 simulator.
- Ran source audits for 1:1 tempo matching, +/-10% filtering, no double-time/half-time symbols, and no beat-count reset during crossfade completion.

### Risk

- Crossfade is an MVP-level generated-loop transition, not professional seamless mixing.
- Watch state is mocked and does not yet use WatchConnectivity, HealthKit, or Workout Session data.
- The Watch target is companion-aware for simulator install, but it is not yet embedded into the iOS app's full distribution flow.

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
