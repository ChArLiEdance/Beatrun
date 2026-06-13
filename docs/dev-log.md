# Beatrun Development Log

## 2026-06-13 - Watch Standalone Workout and Music Library Matching

### Stage 1: Goal Review and Scope Lock

Completed:

- Read `docs/goal-watch-workout-music-library.md`.
- Confirmed current code still had generated-loop-first music wording and no HealthKit workout manager.
- Kept the existing 1:1 BPM, +/-10% tempo limit, queue timing, crossfade state, and WatchConnectivity structures as constraints.

Files reviewed:

- `Beatrun/Models.swift`
- `Beatrun/BeatrunModel.swift`
- `Beatrun/MetronomeEngine.swift`
- `Beatrun/ContentView.swift`
- `BeatrunWatch/WatchContentView.swift`
- `BeatrunWatch/WatchPlaybackState.swift`
- `Beatrun.xcodeproj/project.pbxproj`

Verification:

- `git status --short --branch`
- `plutil -lint Beatrun.xcodeproj/project.pbxproj`

Remaining risk:

- The goal includes real device behaviors that simulator screenshots cannot fully prove.

Next step:

- Verify on a physical Apple Watch with HealthKit permissions and real Music Library content.

### Stage 2: Music Library Matching

Completed:

- Added source-aware track metadata for Local Library, Apple Music metadata, Imported File, CC Licensed, and development fallback sources.
- Added `MusicLibraryService` using MediaPlayer permission and `MPMediaQuery.songs()` scanning.
- Recommendations now prefer authorized library tracks with BPM metadata and local non-DRM asset URLs.
- Tracks without BPM metadata are counted as Needs BPM and are not recommended.
- Apple Music/cloud/DRM tracks are treated as metadata-only when no local asset URL is available.
- Added a DEBUG-only denied-library launch path to verify fallback UI without changing Release behavior.

Files changed:

- `Beatrun/Models.swift`
- `Beatrun/MusicLibraryService.swift`
- `Beatrun/BeatrunModel.swift`
- `Beatrun/ContentView.swift`
- `Beatrun/MetronomeEngine.swift`
- `Beatrun.xcodeproj/project.pbxproj`

Verification:

- iOS build succeeded with `/private/tmp/beatrun-library-ios`.

Remaining risk:

- Real user libraries vary; Apple Music DRM/cloud tracks may expose metadata without legal waveform/retiming access.
- User-imported document picker flow is not yet built; current fallback is CC/manual-BPM starter metadata.

Next step:

- Add user-imported local audio file selection and BPM tagging UI.

### Stage 3: Watch Standalone Workout

Completed:

- Added `WatchWorkoutManager` with HealthKit authorization, `HKWorkoutSession`, `HKLiveWorkoutBuilder`, and CoreMotion cadence updates.
- Added simulator fallback cadence/elapsed-time behavior when HealthKit or live sensors are unavailable.
- Added Watch HealthKit entitlements and Info.plist usage descriptions for health read/update and motion cadence.
- Reworked Watch UI around standalone workout status, target/current cadence, elapsed time, heart rate, active energy, distance, Start/Pause/Resume/End controls, and small connection status.
- WatchConnectivity status now maps iPhone-unreachable states to Standalone Mode instead of blocking the Watch UI.

Files changed:

- `BeatrunWatch/WatchWorkoutManager.swift`
- `BeatrunWatch/WatchContentView.swift`
- `BeatrunWatch/WatchPlaybackState.swift`
- `BeatrunWatch/BeatrunWatch.entitlements`
- `Beatrun.xcodeproj/project.pbxproj`

Verification:

- watchOS build succeeded with `/private/tmp/beatrun-library-watch`.
- `plutil -lint BeatrunWatch/BeatrunWatch.entitlements`

Remaining risk:

- Heart rate, distance, active energy, and live cadence need real Apple Watch validation.
- Simulator HealthKit authorization/session behavior is not equivalent to a real workout.

Next step:

- Run on a physical Apple Watch, grant HealthKit permissions, start an outdoor running workout, and compare cadence/heart-rate updates.

### Stage 4: Documentation

Completed:

- Updated README with Watch standalone mode, HealthKit/Workout Session scope, music-library permission, DRM limitations, and real-device validation advice.
- Updated demo catalog from generated-audio wording to CC/manual-BPM starter metadata.
- Added this log section and CHANGELOG notes.

Files changed:

- `README.md`
- `CHANGELOG.md`
- `docs/dev-log.md`
- `docs/demo-catalog.md`

Verification:

- Documentation reviewed to avoid claiming universal Apple Music retiming, real workout metrics on simulator, or unauthorized commercial music access.

Remaining risk:

- Real HealthKit metrics, live cadence, and Music Library contents still require physical devices and user-granted permissions.

Next step:

- Run a physical Apple Watch workout and a real iPhone music-library scan before public demo recording.

### Stage 5: Final Simulator Verification

Completed:

- Rebuilt the iOS and Watch targets after the final UI/layout changes.
- Installed and launched the iOS app on an iPhone 17 iOS 26.5 simulator.
- Installed and launched the Watch app on an Apple Watch Ultra 3 watchOS 26.5 simulator.
- Captured the requested screenshots:
  - `/private/tmp/beatrun-library-ios-main.png`
  - `/private/tmp/beatrun-library-ios-library.png`
  - `/private/tmp/beatrun-library-ios-workout-sync.png`
  - `/private/tmp/beatrun-library-watch-standalone.png`
  - `/private/tmp/beatrun-library-watch-running.png`
- Verified the Watch standalone screen opens without relying on live iPhone reachability.
- Verified the normal Watch Start Workout path reaches the Health data permission prompt without crashing.
- Verified the DEBUG workout demo uses simulator fallback metrics for a running-state screenshot because simulator Health permission pregrant returned `Operation not permitted`.

Verification:

- `xcodebuild -quiet -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-library-ios build`
- `xcodebuild -quiet -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-library-watch build`
- `plutil -lint Beatrun.xcodeproj/project.pbxproj BeatrunWatch/BeatrunWatch.entitlements`
- `git diff --check`

Remaining risk:

- The Watch simulator cannot prove real heart-rate, energy, distance, or live cadence sensor data.
- The iOS simulator cannot prove a user's actual Apple Music/cloud/DRM library behavior.
- The current user-imported-file and manual-BPM editing flows remain future work; the app labels unsupported cases instead of overclaiming.

Next step:

- Validate HealthKit permissions, `HKWorkoutSession`, CoreMotion cadence, and local-library BPM scanning on physical iPhone and Apple Watch hardware.

## 2026-06-12 - Watch Companion Polish and iOS Demo UI

### Stage 1: Current State Review

Completed:

- Confirmed the repository started clean on `main`.
- Reviewed iOS UI, app model, metronome engine, Watch UI, Watch state, and Xcode target wiring.
- Confirmed the existing queue, preloading, crossfade, and 1:1 matching constraints were already in place before UI work.

Files reviewed:

- `Beatrun/ContentView.swift`
- `Beatrun/BeatrunModel.swift`
- `Beatrun/MetronomeEngine.swift`
- `BeatrunWatch/WatchContentView.swift`
- `BeatrunWatch/WatchPlaybackState.swift`
- `Beatrun.xcodeproj/project.pbxproj`

Verification:

- `git status --short --branch`
- `plutil -lint Beatrun.xcodeproj/project.pbxproj`
- `xcodebuild -project Beatrun.xcodeproj -list`

Remaining risk:

- There is still no automated UI snapshot test target.

Next step:

- Add screenshot-based visual regression checks after the competition demo screens settle.

### Stage 2: WatchConnectivity State Path

Completed:

- Added a shared `WatchSyncPayload` model for iOS-to-Watch state.
- Added `WatchControlMessage` for Watch-to-iOS Play/Pause, Stop, and cadence delta commands.
- Added iOS `WatchSyncCoordinator` using WatchConnectivity application context and reachable messages.
- Added Watch `WatchConnectivityController` to receive iOS state and send controls back.
- Routed iOS playback actions through `BeatrunModel` so local controls publish Watch state after changes.

Files changed:

- `Shared/WatchSyncPayload.swift`
- `Beatrun/WatchSyncCoordinator.swift`
- `Beatrun/BeatrunModel.swift`
- `BeatrunWatch/WatchConnectivityController.swift`
- `Beatrun.xcodeproj/project.pbxproj`

Verification:

- iOS and watchOS builds succeeded after the WatchConnectivity files were added.

Remaining risk:

- Live state sync depends on a paired, reachable simulator or physical device pair.
- The current implementation uses basic application context and control messages, not a full session reliability layer.

Next step:

- Verify on a paired iPhone/watchOS simulator pair or real devices and record reachable-state behavior.

### Stage 3: Watch Demo UI

Completed:

- Reworked the Watch interface around large cadence, playback state, sync status, transition countdown, current track, next track, adjusted BPM, tempo shift, and beat count.
- Added Play/Pause, Stop, and cadence +/-5 controls.
- Added lightweight local haptic feedback for Watch controls.
- Kept local fallback state so the Watch screen remains usable when iPhone reachability is unavailable.

Files changed:

- `BeatrunWatch/WatchContentView.swift`
- `BeatrunWatch/WatchPlaybackState.swift`

Verification:

- `xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-polish-watch build`

Remaining risk:

- The Watch screen still does not use HealthKit or Workout Session data.
- Control delivery cannot be considered verified until a reachable paired simulator/device is used.

Next step:

- Pair simulators or use devices, then verify Play/Pause and cadence deltas update the iOS app.

### Stage 4: iOS Demo Interface Polish

Completed:

- Added a run-mix header and Watch sync status chip.
- Added cadence safety chips for 1:1 BPM, +/-10% adjustment, and offline audio.
- Reworked the Now Playing header to surface current track, original-to-adjusted BPM, tempo shift, and playback control.
- Made the next-track transition card more prominent with preload/crossfade state, remaining beats, and current/next tiles.
- Updated recommendation rows with clear BPM, speed-shift, and rights pills.

Files changed:

- `Beatrun/ContentView.swift`

Verification:

- `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-polish-ios build`

Remaining risk:

- Final visual validation still requires simulator screenshots across the main and playback/transition states.

Next step:

- Launch the iOS app, capture the main screen, start playback, and capture the transition state.

### Stage 5: Documentation

Completed:

- Updated README with the polished iOS demo UI, WatchConnectivity scope, Watch fallback behavior, and HealthKit/Workout Session limitations.
- Added this stage-by-stage development log.
- Updated CHANGELOG with Watch companion polish, iOS UI polish, verification, and risks.

Files changed:

- `README.md`
- `CHANGELOG.md`
- `docs/dev-log.md`

Verification:

- Documentation reviewed for honest competition wording and no claim of real Apple Watch workout data.

Remaining risk:

- Final screenshot paths and final push commit are still pending.

Next step:

- Run final verification, capture screenshots, commit, and push.

### Stage 6: Final Verification and Upload Prep

Completed:

- Rebuilt the final iOS app after UI layout polish.
- Rebuilt the final Watch app after compacting the main screen around cadence, current/next track, beats remaining, and crossfade state.
- Installed and launched both apps on the paired simulator set.
- Captured the final iOS main, iOS playback/transition, and Watch main screenshots.
- Re-ran source audits for matching rules and queue transition safety before staging.

Files changed:

- `Beatrun/ContentView.swift`
- `BeatrunWatch/WatchContentView.swift`
- `CHANGELOG.md`
- `docs/dev-log.md`

Verification:

- `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-polish-ios build`
- `xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-polish-watch build`
- `xcrun simctl launch 416591F8-0225-4495-81A0-B108D5B7EE51 com.charlie.Beatrun`
- `xcrun simctl launch 416591F8-0225-4495-81A0-B108D5B7EE51 com.charlie.Beatrun -BeatrunDemoAutoplay`
- `xcrun simctl launch FB9127E4-D22F-401E-AC24-2CD4CDDE8603 com.charlie.Beatrun.watch`
- iOS main screenshot: `/private/tmp/beatrun-polish-ios-main.png`
- iOS playback/transition screenshot: `/private/tmp/beatrun-polish-ios-transition.png`
- Watch main screenshot: `/private/tmp/beatrun-polish-watch-main.png`

Remaining risk:

- WatchConnectivity code is implemented, and both simulator apps launch, but live reachable state sync can still vary with simulator pairing/reachability.
- HealthKit and Workout Session are still intentionally not implemented.
- Queue crossfade remains an MVP generated-loop transition rather than sample-accurate production mixing.

Next step:

- Commit and push the verified competition demo polish.

## 2026-06-12 - Synced Queue Transitions and Watch Scaffold

### Stage 1: Current State Review

Completed:

- Confirmed the repository was clean at `fa73226`.
- Reviewed the iOS model, metronome engine, SwiftUI screen, and Xcode project file.
- Confirmed current matching rules were already 1:1 with +/-10% tempo adjustment.

Files reviewed:

- `Beatrun/Models.swift`
- `Beatrun/BeatrunModel.swift`
- `Beatrun/MetronomeEngine.swift`
- `Beatrun/ContentView.swift`
- `Beatrun.xcodeproj/project.pbxproj`

Verification:

- `git status --short --branch`
- `xcodebuild -project Beatrun.xcodeproj -list`

Remaining risk:

- There is still no automated XCTest target for queue transitions.

Next step:

- Add focused tests or a debug-only transition simulator.

### Stage 2: Beat-Synced Playback Queue

Completed:

- Added current and upcoming queue state to the audio engine.
- Added next-track selection from legal 1:1 recommendations only.
- Added next-track buffer preloading before transition.
- Added 8-beat transition boundaries and 4-beat crossfade.
- Kept the metronome click timer running as the master clock through transitions.
- Preserved beat count during track transitions.

Files changed:

- `Beatrun/MetronomeEngine.swift`
- `Beatrun/BeatrunModel.swift`

Verification:

- iOS simulator build succeeded after the queue implementation.
- Source inspection confirms queue candidates are `TrackMatch` values already filtered by `TempoAdjustment`.

Remaining risk:

- Crossfade quality is intentionally basic and generated-loop-only.
- Runtime audio was not objectively measured for sample-accurate phase alignment.

Next step:

- Add an audio timing test harness or visible debug counters for transition boundaries.

### Stage 3: iOS Queue UI

Completed:

- Added a queue panel showing current track, next track, queue/preload state, remaining beats, and crossfade state.
- Updated the roadmap panel to show queue transition and Watch scaffold status.
- Switched the now-playing detail panel to read the engine's active track after transitions.

Files changed:

- `Beatrun/ContentView.swift`

Verification:

- iOS simulator build succeeded after UI changes.

Remaining risk:

- UI transition states still need a recorded simulator demo for submission evidence.

Next step:

- Capture a short screen recording showing countdown and crossfade state.

### Stage 4: Apple Watch Scaffold

Completed:

- Added a new `BeatrunWatch` watchOS target.
- Added watchOS SwiftUI app, content view, and mock playback state.
- Watch UI shows target cadence, playback/sync status, current track, next track, transition status, crossfade status, and Play/Pause.
- Added a shared `BeatrunWatch` scheme.
- Declared `WKCompanionAppBundleIdentifier` as `com.charlie.Beatrun` so the scaffold can install on a watchOS simulator as a companion-aware app.
- Documented that Watch state is mock-only for now.

Files changed:

- `BeatrunWatch/BeatrunWatchApp.swift`
- `BeatrunWatch/WatchContentView.swift`
- `BeatrunWatch/WatchPlaybackState.swift`
- `Beatrun.xcodeproj/project.pbxproj`
- `Beatrun.xcodeproj/xcshareddata/xcschemes/BeatrunWatch.xcscheme`

Verification:

- `plutil -lint Beatrun.xcodeproj/project.pbxproj`
- `xcodebuild -project Beatrun.xcodeproj -list`
- `xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' build`
- Installed and launched on an Apple Watch Series 11 watchOS 26.5 simulator after the companion bundle id was added.

Remaining risk:

- Watch target is not yet embedded into a full paired iOS distribution flow.
- No WatchConnectivity, HealthKit, or Workout Session integration yet.

Next step:

- Add the iOS/watchOS communication layer and a real paired-watch run configuration.

### Stage 5: Documentation

Completed:

- Updated README with queue transition and Watch scaffold instructions.
- Updated CHANGELOG with queue, crossfade, Watch scaffold, verification, and risks.
- Updated this dev log with stage-by-stage completion notes.

Files changed:

- `README.md`
- `CHANGELOG.md`
- `docs/dev-log.md`

Verification:

- Documentation reviewed for MVP-level wording and current limitations.

Remaining risk:

- Final submission video and persistent repository screenshots still need to be recorded after final push.

Next step:

- Record the transition demo and include it in submission materials.

### Stage 6: Final Verification and Upload Prep

Completed:

- Re-ran project lint and scheme listing after the queue, Watch target, and companion bundle settings were added.
- Re-ran final iOS and watchOS simulator builds with DerivedData under `/private/tmp`.
- Installed and launched the iOS app on the booted iPhone 17 iOS 26.5 simulator.
- Installed and launched the Watch scaffold on an Apple Watch Series 11 watchOS 26.5 simulator.
- Captured temporary launch screenshots at `/private/tmp/beatrun-final-launch.png` and `/private/tmp/beatrun-final-watch-launch.png`.
- Kept the mock Watch architecture note in source and docs instead of showing it in the Watch UI.
- Audited app source for 1:1 matching only, +/-10% adjustment filtering, no double-time/half-time symbols, and no beat-count reset during crossfade completion.

Files changed:

- `Beatrun.xcodeproj/project.pbxproj`
- `BeatrunWatch/WatchContentView.swift`
- `BeatrunWatch/WatchPlaybackState.swift`
- `CHANGELOG.md`
- `docs/dev-log.md`

Verification:

- `plutil -lint Beatrun.xcodeproj/project.pbxproj`
- `xcodebuild -project Beatrun.xcodeproj -list`
- `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/beatrun-final-ios build`
- `xcodebuild -project Beatrun.xcodeproj -scheme BeatrunWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath /private/tmp/beatrun-final-watch build`
- `xcrun simctl install 416591F8-0225-4495-81A0-B108D5B7EE51 /private/tmp/beatrun-final-ios/Build/Products/Debug-iphonesimulator/Beatrun.app`
- `xcrun simctl launch 416591F8-0225-4495-81A0-B108D5B7EE51 com.charlie.Beatrun`
- `xcrun simctl install 14F43D8A-F299-4C53-B6A0-5CA93D530E51 /private/tmp/beatrun-final-watch/Build/Products/Debug-watchsimulator/BeatrunWatch.app`
- `xcrun simctl launch 14F43D8A-F299-4C53-B6A0-5CA93D530E51 com.charlie.Beatrun.watch`
- `git diff --check`

Remaining risk:

- There is still no XCTest coverage for queue timing or transition state.
- Runtime audio crossfade was verified by source and build checks, not by sample-accurate audio capture.
- Watch state remains mock-only until WatchConnectivity, HealthKit, and Workout Session are implemented.

Next step:

- Commit and push the verified changes, then record the final transition demo for submission evidence.

## 2026-06-12 - Competition MVP 1:1 Tempo Matching

### Stage 1: Current State Review

Completed:

- Reviewed the existing SwiftUI prototype, generated backing loop, metronome engine, discovery flow, and changelog.
- Identified that the previous prototype still allowed direct, double-time, and half-time matching.
- Identified stale README wording that described the project as setup-stage instead of MVP-stage.

Files reviewed:

- `Beatrun/Models.swift`
- `Beatrun/BeatrunModel.swift`
- `Beatrun/MetronomeEngine.swift`
- `Beatrun/ContentView.swift`
- `README.md`
- `CHANGELOG.md`
- `docs/competition-roadmap.md`
- `docs/submission-checklist.md`

Verification:

- Checked the worktree with `git status --short`.
- Searched for double-time, half-time, old match-mode wording, and rights metadata gaps with `rg`.

Remaining risk:

- No dedicated test target exists yet, so matching rules are currently verified through build checks and source inspection.

### Stage 2: Demo Music Rights Structure

Completed:

- Added `AudioRights` metadata to the demo catalog model.
- Recorded rights status, license/source type, attribution, source explanation, source link, and tempo-adjustment permission.
- Added `docs/demo-catalog.md` with one row per demo track.
- Kept the MVP on local generated demo audio only.

Files changed:

- `Beatrun/Models.swift`
- `docs/demo-catalog.md`

Verification:

- Confirmed every demo track is tied to the shared generated-audio rights profile.
- Confirmed docs state that no commercial music is downloaded, scraped, streamed, bundled, or redistributed.

Remaining risk:

- Real royalty-free or CC music import is still future work. The competition demo is intentionally limited to generated audio.

### Stage 3: 1:1 BPM Matching and +/-10% Tempo Adjustment

Completed:

- Replaced the old direct/double-time/half-time candidate model with `TempoAdjustment`.
- Added strict +/-10% filtering.
- Rejected tracks when rights metadata does not allow tempo adjustment.
- Removed 90 BPM double-time demo tracks from the catalog.
- Sorted accepted recommendations by match score and smaller speed adjustment.

Files changed:

- `Beatrun/Models.swift`
- `Beatrun/BeatrunModel.swift`

Verification:

- Source inspection confirms `TempoMatchMode`, double-time matching, and half-time matching are no longer present in app code.
- `xcodebuild` completed successfully after the model change.

Remaining risk:

- Matching quality still uses curated metadata and confidence values rather than live beat detection.

### Stage 4: UI for Tempo Adjustment and Copyright Status

Completed:

- Updated the main preview panel to show target SPM, original BPM, adjusted BPM, speed change, score, and rights status.
- Updated recommendation rows to show original-to-adjusted BPM and 1:1 tempo-adjustment reason.
- Added license, attribution, source, and tempo-change permission text in the detail panel.
- Changed wording from match mode to tempo fit where it affects current MVP behavior.

Files changed:

- `Beatrun/ContentView.swift`

Verification:

- Build succeeded after the UI update.

Remaining risk:

- UI was screenshot-verified on simulator, but audio output was not independently recorded in this turn.

### Stage 5: Project Documentation

Completed:

- Rewrote README for the current competition MVP.
- Added demo catalog documentation.
- Added this dev log.
- Updated the changelog with the 2026-06-12 competition MVP entry.

Files changed:

- `README.md`
- `CHANGELOG.md`
- `docs/demo-catalog.md`
- `docs/dev-log.md`

Verification:

- README now states that the MVP is 1:1 only and caps tempo changes at +/-10%.
- Demo catalog includes BPM, rights/source, tempo-adjustment permission, beat-grid source, and confidence.

Remaining risk:

- Submission materials still need screenshots, demo video, and official work-description document.

### Stage 6: Build and Upload

Completed:

- Build verification passed.
- iPhone 17 simulator install and launch verification passed.
- A simulator screenshot was captured at `/private/tmp/beatrun-mvp.png`.

Files changed:

- Pending final git commit and push.

Verification:

- `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -project Beatrun.xcodeproj -scheme Beatrun -configuration Debug -destination 'id=416591F8-0225-4495-81A0-B108D5B7EE51' -derivedDataPath /private/tmp/beatrun-derived build`
- `xcrun simctl boot 416591F8-0225-4495-81A0-B108D5B7EE51`
- `xcrun simctl install 416591F8-0225-4495-81A0-B108D5B7EE51 /private/tmp/beatrun-derived/Build/Products/Debug-iphonesimulator/Beatrun.app`
- `xcrun simctl launch 416591F8-0225-4495-81A0-B108D5B7EE51 com.charlie.Beatrun`
- `xcrun simctl io 416591F8-0225-4495-81A0-B108D5B7EE51 screenshot /private/tmp/beatrun-mvp.png`
- Result: build, install, launch, and screenshot succeeded.

Remaining risk:

- Final commit and GitHub push still need to complete.
