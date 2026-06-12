# Beatrun Development Log

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
